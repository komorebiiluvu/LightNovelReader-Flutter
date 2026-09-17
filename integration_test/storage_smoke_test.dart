import 'dart:convert';

import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:light_novel_reader/src/data/source_runtime/flutter_secure_credential_store.dart';
import 'package:light_novel_reader/src/data/migration/legacy_state_import_service.dart';
import 'package:light_novel_reader/src/data/persistence/database.dart';
import 'package:light_novel_reader/src/data/persistence/database_open.dart';
import 'package:light_novel_reader/src/domain/migration/migration_models.dart';
import 'package:light_novel_reader/src/domain/identity/opaque_ids.dart';
import 'package:light_novel_reader/src/source/security/secure_value.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('packaged SQLite production open/write/rollback/reopen', (
    _,
  ) async {
    final support = await getApplicationSupportDirectory();
    await support.create(recursive: true);
    // Only this unique child is touched or cleaned; never the production file.
    final root = await support.createTemp('f2-storage-smoke-');
    AppDatabase? db;
    const book = ' wk8-00042/#.文😀 ';
    try {
      db = await openAppDatabase(storageRoot: () async => root);
      const migrationDataset = 'f2-7-packaged-smoke';
      final migration = LegacyStateImportService(db);
      await migration.repository.ensureDataset(migrationDataset);
      final imported = await migration.importWithReport(
        MigrationInput(
          datasetId: migrationDataset,
          inputType: MigrationInputType.legacyIosSnapshotV1,
          bytes: utf8.encode(
            '{"theme":"dark","savedIDs":["wk8-00042"],'
            '"sourceByID":{"wk8-00042":"文库8(在线)"},'
            '"bookLibrary":[{"id":"wk8-00042","title":"Smoke",'
            '"author":"Test","tags":["f2.7"],"source":"文库8(在线)",'
            '"intro":"Packaged migration","totalChapters":1,'
            '"lastChapter":0,"hasUpdate":false,"hits":0,"coverIndex":0}],'
            '"lastChapterByID":{"wk8-00042":0},'
            '"readBookIDs":["wk8-00042"]}',
          ),
        ),
      );
      expect(imported.run.state, MigrationRunState.complete);
      expect(imported.report.accentUnavailable, isTrue);
      await db.transaction(() async {
        await db!.customStatement(
          "INSERT INTO source_registrations VALUES ('smoke-source','Smoke','unresolved')",
        );
        await db!.customStatement(
          "INSERT INTO library_entries(source_id,book_id,metadata_state) VALUES ('smoke-source',?,'stub')",
          [book],
        );
      });
      await db.close();
      db = await openAppDatabase(storageRoot: () async => root);
      final importedProgress = await db
          .customSelect(
            'SELECT p.has_read,p.chapter_id,l.dataset_id,l.book_id,l.legacy_book_id,l.chapter_index '
            'FROM reading_progress p JOIN legacy_chapter_locators l ON p.legacy_locator_id=l.locator_id',
          )
          .getSingle();
      expect(importedProgress.data, {
        'has_read': 1,
        'chapter_id': null,
        'dataset_id': migrationDataset,
        'book_id': 'wk8-00042',
        'legacy_book_id': 'wk8-00042',
        'chapter_index': 0,
      });
      expect(
        (await db
                .customSelect('SELECT theme,accent FROM app_preferences')
                .getSingle())
            .data,
        {'theme': 'dark', 'accent': null},
      );
      expect(
        (await db.customSelect('SELECT tag FROM book_tags').getSingle())
            .read<String>('tag'),
        'f2.7',
      );
      expect(
        (await db
                .customSelect(
                  'SELECT book_id FROM library_entries WHERE source_id=?',
                  variables: [const Variable<String>('builtin.wenku8')],
                )
                .getSingle())
            .read<String>('book_id'),
        'wk8-00042',
      );
      expect(
        (await db
                .customSelect(
                  'SELECT book_id FROM library_entries WHERE source_id=?',
                  variables: [const Variable<String>('smoke-source')],
                )
                .getSingle())
            .read<String>('book_id'),
        book,
      );
      expect(
        (await db.customSelect('PRAGMA foreign_keys').getSingle()).read<int>(
          'foreign_keys',
        ),
        1,
      );
      expect(
        (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
          'user_version',
        ),
        1,
      );
      await expectLater(
        db.transaction(() async {
          await db!.customStatement(
            "INSERT INTO shelves VALUES ('rollback','test',0)",
          );
          throw StateError('injected rollback');
        }),
        throwsStateError,
      );
      expect(await db.customSelect('SELECT * FROM shelves').get(), isEmpty);
    } finally {
      await db?.close();
      await root.delete(recursive: true);
    }
  });

  testWidgets('packaged secure storage write/read/delete', (_) async {
    final store = FlutterSecureCredentialStore();
    final key = SecureStorageKey(
      sourceId: SourceId('f3.3-packaged-smoke'),
      name: 'roundtrip',
    );
    final sentinel = 'runtime-secret-${DateTime.now().microsecondsSinceEpoch}';
    final value = SecureValue(sentinel);
    await store.delete(key);
    await store.write(key, value);
    expect((await store.read(key))!.value, sentinel);
    await store.delete(key);
    expect(await store.read(key), isNull);
  });
}
