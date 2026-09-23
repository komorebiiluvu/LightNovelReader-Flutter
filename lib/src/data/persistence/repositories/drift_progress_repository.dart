import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../domain/identity/opaque_ids.dart';
import '../../../domain/identity/source_refs.dart';
import '../../../domain/legacy/legacy_chapter_locator.dart';
import '../../../domain/legacy/legacy_source_mapping.dart';
import '../../../domain/progress/reading_progress.dart';
import '../../../domain/progress/repositories.dart';
import '../../../domain/reconciliation/legacy_reconciliation.dart';
import '../../../domain/library/repository_failure.dart';
import '../database.dart' show AppDatabase;
import 'repository_access.dart';

final class DriftProgressRepository
    implements ProgressRepository, LegacyProgressReconciliationRepository {
  DriftProgressRepository(AppDatabase db) : _access = RepositoryAccess(db);
  final RepositoryAccess _access;

  @override
  Future<ReadingProgressV1?> get(SourceBookRef bookRef) =>
      _access.run(() async {
        final rows = await _access.rows(
          'SELECT * FROM reading_progress WHERE source_id=? AND book_id=?',
          RepositoryAccess.keys(bookRef),
        );
        return rows.isEmpty ? null : await _decode(rows.single);
      });

  @override
  Future<List<ReadingProgressV1>> list() => _access.run(() async {
    final rows = await _access.rows(
      'SELECT * FROM reading_progress '
      'ORDER BY source_id COLLATE BINARY, book_id COLLATE BINARY',
    );
    return [for (final row in rows) await _decode(row)];
  });

  @override
  Future<void> save(ReadingProgressV1 progress) =>
      _access.run(() => _saveWithinTransaction(progress));

  @override
  Future<LegacyReconciliationApplyDisposition> compareAndApply({
    required SourceBookRef bookRef,
    required ReadingProgressV1 expected,
    required ReadingProgressV1 replacement,
  }) => _access.run(() async {
    if (expected.bookRef != bookRef || replacement.bookRef != bookRef) {
      throw RepositoryFailure(RepositoryFailureReason.invalidInput);
    }
    final current = await _getWithinTransaction(bookRef);
    if (current == null) return LegacyReconciliationApplyDisposition.notFound;
    if (current == replacement) {
      return LegacyReconciliationApplyDisposition.unchanged;
    }
    if (current != expected) {
      return LegacyReconciliationApplyDisposition.conflict;
    }
    await _saveWithinTransaction(replacement);
    return LegacyReconciliationApplyDisposition.applied;
  });

  Future<void> _saveWithinTransaction(ReadingProgressV1 progress) async {
    await _access.requireBook(progress.bookRef);
    final locator = progress.legacyLocator;
    String? locatorId;
    if (locator != null) {
      await _access.requireRow(
        'SELECT 1 FROM migration_datasets WHERE dataset_id=?',
        [locator.datasetId.value],
        RepositoryFailureReason.invalidReference,
      );
      locatorId = _locatorId(locator);
      await _access.write(
        'INSERT INTO legacy_chapter_locators('
        'locator_id,version,dataset_id,source_id,book_id,legacy_book_id,'
        'chapter_index,raw_offset_key,fraction,remote_id_evidence,'
        'chapter_title_evidence,volume_title_evidence,catalog_digest) '
        'VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?) '
        'ON CONFLICT(locator_id) DO NOTHING',
        [
          locatorId,
          1,
          locator.datasetId.value,
          locator.bookRef.sourceId.value,
          locator.bookRef.bookId.value,
          locator.legacyBookId.value,
          locator.chapterIndex,
          locator.rawOffsetKey,
          locator.fraction,
          locator.remoteIdEvidence,
          locator.chapterTitleEvidence,
          locator.volumeTitleEvidence,
          locator.catalogDigest,
        ],
      );
    }
    await _access.write(
      'INSERT INTO reading_progress('
      'source_id,book_id,version,has_read,chapter_id,legacy_locator_id,last_read_at) '
      'VALUES (?,?,1,?,?,?,?) '
      'ON CONFLICT(source_id,book_id) DO UPDATE SET '
      'version=1,has_read=excluded.has_read,chapter_id=excluded.chapter_id,'
      'legacy_locator_id=excluded.legacy_locator_id,last_read_at=excluded.last_read_at',
      [
        progress.bookRef.sourceId.value,
        progress.bookRef.bookId.value,
        progress.hasRead ? 1 : 0,
        progress.chapterRef?.chapterId.value,
        locatorId,
        progress.lastReadAt == null
            ? null
            : encodeCanonicalUtc(progress.lastReadAt!),
      ],
    );
  }

  Future<ReadingProgressV1?> _getWithinTransaction(
    SourceBookRef bookRef,
  ) async {
    final rows = await _access.rows(
      'SELECT * FROM reading_progress WHERE source_id=? AND book_id=?',
      RepositoryAccess.keys(bookRef),
    );
    return rows.isEmpty ? null : await _decode(rows.single);
  }

  Future<ReadingProgressV1> _decode(QueryRow row) async {
    if (row.read<int>('version') != 1) {
      throw RepositoryFailure(RepositoryFailureReason.storage);
    }
    final bookRef = SourceBookRef(
      sourceId: SourceId(row.read<String>('source_id')),
      bookId: BookId(row.read<String>('book_id')),
    );
    final locatorId = row.readNullable<String>('legacy_locator_id');
    return ReadingProgressV1(
      bookRef: bookRef,
      hasRead: row.read<int>('has_read') == 1,
      chapterRef: switch (row.readNullable<String>('chapter_id')) {
        null => null,
        final chapterId => SourceChapterRef(
          sourceId: bookRef.sourceId,
          bookId: bookRef.bookId,
          chapterId: ChapterId(chapterId),
        ),
      },
      legacyLocator: locatorId == null
          ? null
          : await _locator(bookRef, locatorId),
      lastReadAt: switch (row.readNullable<String>('last_read_at')) {
        null => null,
        final value => decodeCanonicalUtc(value),
      },
    );
  }

  Future<LegacyChapterLocatorV1> _locator(
    SourceBookRef bookRef,
    String locatorId,
  ) async {
    final rows = await _access.rows(
      'SELECT * FROM legacy_chapter_locators '
      'WHERE source_id=? AND book_id=? AND locator_id=?',
      [...RepositoryAccess.keys(bookRef), locatorId],
    );
    if (rows.isEmpty) {
      throw RepositoryFailure(RepositoryFailureReason.storage);
    }
    final row = rows.single;
    if (row.read<int>('version') != 1) {
      throw RepositoryFailure(RepositoryFailureReason.storage);
    }
    final value = LegacyChapterLocatorV1(
      datasetId: LegacyDatasetId(row.read<String>('dataset_id')),
      bookRef: bookRef,
      legacyBookId: BookId(row.read<String>('legacy_book_id')),
      chapterIndex: row.read<int>('chapter_index'),
      rawOffsetKey: row.readNullable<String>('raw_offset_key'),
      fraction: row.readNullable<double>('fraction'),
      remoteIdEvidence: row.readNullable<String>('remote_id_evidence'),
      chapterTitleEvidence: row.readNullable<String>('chapter_title_evidence'),
      volumeTitleEvidence: row.readNullable<String>('volume_title_evidence'),
      catalogDigest: row.readNullable<String>('catalog_digest'),
    );
    if (_locatorId(value) != locatorId) {
      throw RepositoryFailure(RepositoryFailureReason.storage);
    }
    return value;
  }
}

String _locatorId(LegacyChapterLocatorV1 locator) {
  final bytes = utf8.encode(jsonEncode(locator.toJson()));
  return 'legacyLocator.v1.${base64Url.encode(bytes).replaceAll('=', '')}';
}
