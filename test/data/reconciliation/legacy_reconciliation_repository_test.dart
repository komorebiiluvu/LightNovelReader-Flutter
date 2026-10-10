import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_reader/src/data/persistence/database.dart';
import 'package:light_novel_reader/src/data/persistence/repositories/drift_library_repository.dart';
import 'package:light_novel_reader/src/data/persistence/repositories/drift_progress_repository.dart';
import 'package:light_novel_reader/src/domain/identity/opaque_ids.dart';
import 'package:light_novel_reader/src/domain/identity/source_refs.dart';
import 'package:light_novel_reader/src/domain/legacy/legacy_chapter_locator.dart';
import 'package:light_novel_reader/src/domain/legacy/legacy_source_mapping.dart';
import 'package:light_novel_reader/src/domain/library/repository_failure.dart';
import 'package:light_novel_reader/src/domain/progress/reading_progress.dart';
import 'package:light_novel_reader/src/domain/reconciliation/legacy_reconciliation.dart';

void main() {
  late AppDatabase db;
  late DriftProgressRepository progress;
  late SourceBookRef book;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    progress = DriftProgressRepository(db);
    book = SourceBookRef(
      sourceId: SourceId('fake.alpha'),
      bookId: BookId('same-id'),
    );
    await db.customStatement(
      "INSERT INTO source_registrations(source_id, availability) VALUES ('fake.alpha', 'unresolved')",
    );
    await DriftLibraryRepository(db).ensureStub(book);
    await db.customStatement(
      "INSERT INTO migration_datasets(dataset_id) VALUES ('dataset-a')",
    );
  });

  tearDown(() => db.close());

  test(
    'Drift compare-and-apply updates only the expected current progress',
    () async {
      final chapter = SourceChapterRef(
        sourceId: book.sourceId,
        bookId: book.bookId,
        chapterId: ChapterId('remote|2'),
      );
      final locator = LegacyChapterLocatorV1(
        datasetId: LegacyDatasetId('dataset-a'),
        bookRef: book,
        legacyBookId: BookId('same-id'),
        chapterIndex: 2,
      );
      final expected = ReadingProgressV1(
        bookRef: book,
        hasRead: true,
        legacyLocator: locator,
      );
      await progress.save(expected);
      final captureBytes = utf8.encode(
        jsonEncode({
          'kind': 'legacyChapterCapture',
          'version': 1,
          'datasetId': locator.datasetId.value,
          'sourceId': book.sourceId.value,
          'bookId': book.bookId.value,
          'legacyBookId': locator.legacyBookId.value,
          'chapterIndex': locator.chapterIndex,
          'locatorDigest': sha256
              .convert(utf8.encode(jsonEncode(locator.toJson())))
              .toString(),
          'mappingVersion': 1,
          'captureId': 'captured-progress',
          'proofKind': 'coCapturedCatalog',
          'catalog': [
            {'chapterId': 'first|α', 'chapterIndex': 0},
            {'chapterId': chapter.chapterId.value, 'chapterIndex': 2},
            {'chapterId': 'last|终', 'chapterIndex': 4},
          ],
        }),
      );
      final capture = const LegacyChapterCaptureVerifier().verify(
        locator: locator,
        artifactBytes: captureBytes,
        trustedArtifactDigest: sha256.convert(captureBytes).toString(),
      )!;
      final plan = const LegacyChapterReconciliationPlanner().plan(
        locator: locator,
        candidates: capture.candidates,
        proof: capture.proof,
      );
      final replacement = ReadingProgressV1(
        bookRef: book,
        hasRead: true,
        chapterRef: chapter,
        legacyLocator: locator,
      );

      expect(
        await progress.compareAndApply(
          bookRef: book,
          expected: expected,
          replacement: replacement,
          plan: plan,
        ),
        LegacyReconciliationApplyDisposition.conflict,
      );
      expect(await progress.get(book), expected);
      await db.customStatement(
        'INSERT INTO migration_runs('
        'dataset_id,importer_version,input_digest,mapping_version,state) '
        'VALUES (?,?,?,?,?)',
        [
          locator.datasetId.value,
          1,
          capture.proof.artifactDigest,
          1,
          'complete',
        ],
      );
      await db.customStatement('''
        CREATE TRIGGER fail_reconciliation_progress
        BEFORE UPDATE ON reading_progress
        BEGIN SELECT RAISE(ABORT, 'injected'); END
      ''');
      await expectLater(
        progress.compareAndApply(
          bookRef: book,
          expected: expected,
          replacement: replacement,
          plan: plan,
        ),
        throwsA(isA<RepositoryFailure>()),
      );
      expect(await progress.get(book), expected);
      expect(
        (await db
                .customSelect(
                  'SELECT count(*) AS n FROM chapter_reconciliation_receipts',
                )
                .getSingle())
            .read<int>('n'),
        0,
      );
      await db.customStatement('DROP TRIGGER fail_reconciliation_progress');

      expect(
        await progress.compareAndApply(
          bookRef: book,
          expected: expected,
          replacement: replacement,
          plan: plan,
        ),
        LegacyReconciliationApplyDisposition.applied,
      );
      expect(await progress.get(book), replacement);
      final receipts = await db
          .customSelect(
            'SELECT chapter_id,mapping_version,proof_kind,artifact_digest '
            'FROM chapter_reconciliation_receipts',
          )
          .get();
      expect(receipts, hasLength(1));
      expect(
        receipts.single.read<String>('chapter_id'),
        chapter.chapterId.value,
      );
      expect(receipts.single.read<int>('mapping_version'), 1);
      expect(receipts.single.read<String>('proof_kind'), 'coCapturedCatalog');
      expect(receipts.single.read<String>('artifact_digest'), hasLength(64));
      final alternatives = await db
          .customSelect(
            'SELECT chapter_id,chapter_index FROM chapter_reconciliation_candidates '
            'ORDER BY ordinal',
          )
          .get();
      expect(alternatives.map((row) => row.read<String>('chapter_id')), [
        'first|α',
        chapter.chapterId.value,
        'last|终',
      ]);
      expect(alternatives.map((row) => row.read<int>('chapter_index')), [
        0,
        2,
        4,
      ]);
      expect(
        await progress.compareAndApply(
          bookRef: book,
          expected: expected,
          replacement: replacement,
          plan: plan,
        ),
        LegacyReconciliationApplyDisposition.unchanged,
      );
      await progress.save(expected);
      expect(
        await progress.compareAndApply(
          bookRef: book,
          expected: expected,
          replacement: replacement,
          plan: plan,
        ),
        LegacyReconciliationApplyDisposition.conflict,
      );
    },
  );
}
