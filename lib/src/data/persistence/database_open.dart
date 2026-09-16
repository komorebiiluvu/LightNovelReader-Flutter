import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'database.dart';

const databaseFilename = 'light_novel_reader.sqlite';

/// Called on Drift's database isolate before schema work. No SQL logging.
void _prepare(sqlite.Database database) {
  final version =
      database.select('PRAGMA user_version').single['user_version'] as int;
  if (version > 1) throw const PersistenceFailure.schema();
  database.execute('PRAGMA foreign_keys = ON');
  database.execute('PRAGMA busy_timeout = 5000');
}

/// Creates no global state. Caller owns and must close the returned database.
/// Tests inject a fresh temporary root or executor; errors never fall back to RAM.
Future<AppDatabase> openAppDatabase({
  Future<Directory> Function()? storageRoot,
  QueryExecutor? executor,
}) async {
  AppDatabase? database;
  try {
    final QueryExecutor connection;
    if (executor != null) {
      connection = executor;
    } else {
      final root = await (storageRoot ?? getApplicationSupportDirectory)();
      await root.create(recursive: true);
      final file = File.fromUri(root.uri.resolve(databaseFilename));
      connection = NativeDatabase.createInBackground(file, setup: _prepare);
    }
    database = AppDatabase(connection);
    // Drift opens lazily. Force open so failure is reported by this boundary.
    await database.customSelect('SELECT 1').get();
    return database;
  } catch (error) {
    if (database != null) {
      try {
        await database.close();
      } catch (_) {
        // Preserve the original open failure without logging path/SQL/input.
      }
    }
    if (error is PersistenceFailure) rethrow;
    throw const PersistenceFailure.open();
  }
}
