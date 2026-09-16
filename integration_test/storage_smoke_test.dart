import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:light_novel_reader/src/data/persistence/database.dart';
import 'package:light_novel_reader/src/data/persistence/database_open.dart';

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
      expect(
        (await db
                .customSelect('SELECT book_id FROM library_entries')
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
}
