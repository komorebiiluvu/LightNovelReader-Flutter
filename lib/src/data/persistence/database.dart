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
  int get schemaVersion => 1;

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

  /// Future released versions add explicit, tested upgrades here.
  Future<void> upgradeSchema(Migrator migrator, int from, int to) async {
    throw const PersistenceFailure.schema();
  }
}
