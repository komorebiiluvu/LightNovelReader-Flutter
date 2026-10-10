import 'package:drift/drift.dart';

import '../../core/app_error.dart';

part 'database.g.dart';

final class PersistenceFailure extends AppFailure {
  const PersistenceFailure.open()
    : super(
        code: 'storage_open_failed',
        message: 'Stored data could not be opened.',
      );
  const PersistenceFailure.schema()
    : super(
        code: 'storage_schema_unsupported',
        message: 'This database version is not supported.',
      );
}

@DriftDatabase(include: {'schema.drift'})
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => _migrate(() => createSchema(m)),
    onUpgrade: (m, from, to) {
      if (from > to) throw const PersistenceFailure.schema();
      return _migrate(() => upgradeSchema(m, from, to));
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
      final enabled = await customSelect('PRAGMA foreign_keys').getSingle();
      if (enabled.read<int>('foreign_keys') != 1) {
        throw const PersistenceFailure.open();
      }
    },
  );

  Future<void> _migrate(Future<void> Function() apply) => transaction(() async {
    await apply();
    if ((await customSelect('PRAGMA foreign_key_check').get()).isNotEmpty) {
      throw const PersistenceFailure.schema();
    }
    // Commit the SQL version with its schema/data. Drift repeats this assignment
    // after beforeOpen; a crash between those steps must not leave version zero.
    await customStatement('PRAGMA user_version = $schemaVersion');
  });

  /// Refuse unversioned existing data. Test subclasses alone supply a synthetic
  /// pre-v1 migration; there is no historical production Flutter schema.
  Future<void> createSchema(Migrator migrator) async {
    final existing = await customSelect(
      "SELECT name FROM sqlite_schema WHERE type = 'table' AND name NOT LIKE 'sqlite_%'",
    ).get();
    if (existing.isNotEmpty) throw const PersistenceFailure.schema();
    await migrator.createAll();
  }

  Future<void> upgradeSchema(Migrator migrator, int from, int to) async {
    if (from == 1 && to == 2) {
      await customStatement('''
        CREATE TABLE chapter_reconciliation_receipts (
          receipt_id TEXT NOT NULL PRIMARY KEY COLLATE BINARY CHECK(length(receipt_id) > 0),
          dataset_id TEXT NOT NULL COLLATE BINARY REFERENCES migration_datasets(dataset_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
          source_id TEXT NOT NULL COLLATE BINARY,
          book_id TEXT NOT NULL COLLATE BINARY,
          original_locator_id TEXT NOT NULL COLLATE BINARY,
          chapter_id TEXT NOT NULL COLLATE BINARY CHECK(length(chapter_id) > 0 AND instr(chapter_id, char(0)) = 0),
          mapping_version INTEGER NOT NULL CHECK(mapping_version > 0),
          proof_kind TEXT NOT NULL CHECK(proof_kind IN ('recordedRemoteId', 'coCapturedCatalog')),
          artifact_digest TEXT NOT NULL CHECK(length(artifact_digest) = 64 AND artifact_digest NOT GLOB '*[^0-9a-f]*'),
          catalog_digest TEXT,
          co_capture_marker TEXT,
          UNIQUE(source_id, book_id, receipt_id),
          UNIQUE(source_id, book_id, original_locator_id),
          FOREIGN KEY(source_id, book_id, original_locator_id) REFERENCES legacy_chapter_locators(source_id, book_id, locator_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
          CHECK((proof_kind = 'recordedRemoteId' AND catalog_digest IS NULL AND co_capture_marker IS NULL) OR
            (proof_kind = 'coCapturedCatalog' AND catalog_digest IS NOT NULL AND co_capture_marker IS NOT NULL))
        )
      ''');
      await customStatement('''
        CREATE TABLE chapter_reconciliation_candidates (
          receipt_id TEXT NOT NULL COLLATE BINARY REFERENCES chapter_reconciliation_receipts(receipt_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
          ordinal INTEGER NOT NULL CHECK(ordinal >= 0),
          source_id TEXT NOT NULL COLLATE BINARY,
          book_id TEXT NOT NULL COLLATE BINARY,
          chapter_id TEXT NOT NULL COLLATE BINARY CHECK(length(chapter_id) > 0 AND instr(chapter_id, char(0)) = 0),
          chapter_index INTEGER NOT NULL CHECK(chapter_index >= 0),
          catalog_digest TEXT NOT NULL,
          mapping_version INTEGER NOT NULL CHECK(mapping_version > 0),
          PRIMARY KEY(receipt_id, ordinal),
          FOREIGN KEY(source_id, book_id) REFERENCES library_entries(source_id, book_id) ON DELETE RESTRICT ON UPDATE RESTRICT
        )
      ''');
      await customStatement('''
        CREATE TABLE reading_progress_v2 (
          source_id TEXT NOT NULL COLLATE BINARY,
          book_id TEXT NOT NULL COLLATE BINARY,
          version INTEGER NOT NULL DEFAULT 1 CHECK(version = 1),
          has_read INTEGER NOT NULL CHECK(has_read IN (0, 1)),
          chapter_id TEXT COLLATE BINARY CHECK(chapter_id IS NULL OR (length(chapter_id) > 0 AND instr(chapter_id, char(0)) = 0)),
          legacy_locator_id TEXT COLLATE BINARY,
          reconciliation_receipt_id TEXT COLLATE BINARY,
          last_read_at TEXT CHECK(last_read_at IS NULL OR (last_read_at GLOB '????-??-??T??:??:??.*Z' AND julianday(last_read_at) IS NOT NULL)),
          PRIMARY KEY(source_id, book_id),
          FOREIGN KEY(source_id, book_id) REFERENCES library_entries(source_id, book_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
          FOREIGN KEY(source_id, book_id, legacy_locator_id) REFERENCES legacy_chapter_locators(source_id, book_id, locator_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
          FOREIGN KEY(source_id, book_id, reconciliation_receipt_id) REFERENCES chapter_reconciliation_receipts(source_id, book_id, receipt_id) ON DELETE RESTRICT ON UPDATE RESTRICT
        )
      ''');
      await customStatement('''
        INSERT INTO reading_progress_v2(
          source_id,book_id,version,has_read,chapter_id,legacy_locator_id,last_read_at
        ) SELECT source_id,book_id,version,has_read,chapter_id,legacy_locator_id,last_read_at
          FROM reading_progress
      ''');
      await customStatement('DROP TABLE reading_progress');
      await customStatement(
        'ALTER TABLE reading_progress_v2 RENAME TO reading_progress',
      );
      return;
    }
    throw const PersistenceFailure.schema();
  }
}
