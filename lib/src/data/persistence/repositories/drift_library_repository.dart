import 'package:drift/drift.dart';

import '../../../domain/identity/opaque_ids.dart';
import '../../../domain/identity/source_refs.dart';
import '../../../domain/library/library_models.dart';
import '../../../domain/library/repositories.dart';
import '../../../domain/library/repository_failure.dart';
import '../database.dart' show AppDatabase;
import 'repository_access.dart';

final class DriftLibraryRepository implements LibraryRepository {
  DriftLibraryRepository(AppDatabase db) : _access = RepositoryAccess(db);
  final RepositoryAccess _access;

  Future<LibraryEntry> _entry(QueryRow row) async {
    final ref = RepositoryAccess.ref(row);
    final tags = await _access.rows(
      'SELECT tag FROM book_tags WHERE source_id=? AND book_id=? ORDER BY ordinal',
      RepositoryAccess.keys(ref),
    );
    final asset = row.readNullable<String>('cover_asset_id');
    return LibraryEntry(
      bookRef: ref,
      saved: row.read<int>('saved') == 1,
      metadataState: MetadataState.values.byName(
        row.read<String>('metadata_state'),
      ),
      metadata: BookMetadataSnapshot(
        title: row.readNullable<String>('title'),
        author: row.readNullable<String>('author'),
        description: row.readNullable<String>('description'),
        coverAssetRef: asset == null
            ? null
            : SourceAssetRef(
                sourceId: ref.sourceId,
                bookId: ref.bookId,
                assetId: AssetId(asset),
              ),
        tags: tags.map((r) => r.read<String>('tag')).toList(),
        knownTotalChapters: row.readNullable<int>('known_total_chapters'),
        updateFlag: switch (row.readNullable<int>('update_flag')) {
          null => null,
          final value => value == 1,
        },
      ),
    );
  }

  @override
  Future<LibraryEntry?> get(SourceBookRef ref) => _access.run(() async {
    final rows = await _access.rows(
      'SELECT * FROM library_entries WHERE source_id=? AND book_id=?',
      RepositoryAccess.keys(ref),
    );
    return rows.isEmpty ? null : await _entry(rows.single);
  });

  @override
  Future<List<LibraryEntry>> list() => _access.run(() async {
    final rows = await _access.rows(
      'SELECT * FROM library_entries ORDER BY source_id COLLATE BINARY, book_id COLLATE BINARY',
    );
    return [for (final row in rows) await _entry(row)];
  });

  Future<void> _requireSource(SourceBookRef ref) => _access.requireRow(
    'SELECT 1 FROM source_registrations WHERE source_id=?',
    [ref.sourceId.value],
    RepositoryFailureReason.invalidReference,
  );

  Future<void> _stub(SourceBookRef ref) => _access.write(
    "INSERT INTO library_entries(source_id,book_id,metadata_state) VALUES (?,?,'stub') ON CONFLICT(source_id,book_id) DO NOTHING",
    RepositoryAccess.keys(ref),
  );

  @override
  Future<void> ensureStub(SourceBookRef ref) => _access.run(() async {
    await _requireSource(ref);
    await _stub(ref);
  });

  @override
  Future<void> saveMetadata(
    SourceBookRef ref,
    BookMetadataSnapshot metadata,
  ) => _access.run(() async {
    final cover = metadata.coverAssetRef;
    if (cover != null &&
        (cover.sourceId != ref.sourceId || cover.bookId != ref.bookId)) {
      throw RepositoryFailure(RepositoryFailureReason.invalidInput);
    }
    await _requireSource(ref);
    await _stub(ref);
    await _access.write(
      "UPDATE library_entries SET metadata_state='known',title=?,author=?,description=?,cover_asset_id=?,known_total_chapters=?,update_flag=? WHERE source_id=? AND book_id=?",
      [
        metadata.title,
        metadata.author,
        metadata.description,
        cover?.assetId.value,
        metadata.knownTotalChapters,
        metadata.updateFlag == null ? null : (metadata.updateFlag! ? 1 : 0),
        ...RepositoryAccess.keys(ref),
      ],
    );
    await _access.write(
      'DELETE FROM book_tags WHERE source_id=? AND book_id=?',
      RepositoryAccess.keys(ref),
    );
    for (var i = 0; i < metadata.tags.length; i++) {
      await _access.write(
        'INSERT INTO book_tags(source_id,book_id,ordinal,tag) VALUES (?,?,?,?)',
        [...RepositoryAccess.keys(ref), i, metadata.tags[i]],
      );
    }
  });

  @override
  Future<void> setSaved(SourceBookRef ref, bool saved) => _access.run(() async {
    await _requireSource(ref);
    await _access.requireRow(
      'SELECT 1 FROM library_entries WHERE source_id=? AND book_id=?',
      RepositoryAccess.keys(ref),
    );
    await _access.write(
      'UPDATE library_entries SET saved=? WHERE source_id=? AND book_id=?',
      [saved ? 1 : 0, ...RepositoryAccess.keys(ref)],
    );
  });
}
