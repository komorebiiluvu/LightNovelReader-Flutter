import 'package:drift/drift.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../../../domain/identity/opaque_ids.dart';
import '../../../domain/identity/source_refs.dart';
import '../../../domain/library/repository_failure.dart';
import '../database.dart';

/// Infrastructure-only helper. Each call observes/commits one transaction.
final class RepositoryAccess {
  RepositoryAccess(this.db);
  final AppDatabase db;

  Future<T> run<T>(Future<T> Function() action) async {
    try {
      return await db.transaction(action);
    } on RepositoryFailure {
      rethrow;
    } on sqlite.SqliteException catch (error) {
      throw RepositoryFailure(switch (error.extendedResultCode) {
        1555 || 2067 => RepositoryFailureReason.conflict,
        787 => RepositoryFailureReason.invalidReference,
        275 || 1299 => RepositoryFailureReason.invalidInput,
        _ => RepositoryFailureReason.storage,
      });
    } catch (_) {
      throw RepositoryFailure(RepositoryFailureReason.storage);
    }
  }

  Future<List<QueryRow>> rows(String sql, [List<Object> args = const []]) => db
      .customSelect(
        sql,
        variables: args
            .map(
              (value) => switch (value) {
                String v => Variable<String>(v),
                int v => Variable<int>(v),
                _ => throw RepositoryFailure(
                  RepositoryFailureReason.invalidInput,
                ),
              },
            )
            .toList(),
      )
      .get();

  Future<void> write(String sql, [List<Object?> args = const []]) =>
      db.customStatement(sql, args);

  Future<void> requireRow(
    String sql,
    List<Object> args, [
    RepositoryFailureReason reason = RepositoryFailureReason.notFound,
  ]) async {
    if ((await rows(sql, args)).isEmpty) throw RepositoryFailure(reason);
  }

  Future<void> requireBook(SourceBookRef ref) => requireRow(
    'SELECT 1 FROM library_entries WHERE source_id=? AND book_id=?',
    keys(ref),
    RepositoryFailureReason.invalidReference,
  );

  static List<String> keys(SourceBookRef ref) => [
    ref.sourceId.value,
    ref.bookId.value,
  ];
  static SourceBookRef ref(QueryRow row) => SourceBookRef(
    sourceId: SourceId(row.read<String>('source_id')),
    bookId: BookId(row.read<String>('book_id')),
  );

  static void unique<T>(List<T> values) {
    if (values.toSet().length != values.length) {
      throw RepositoryFailure(RepositoryFailureReason.invalidInput);
    }
  }

  static void permutation<T>(List<T> target, Iterable<T> current) {
    unique(target);
    final existing = current.toSet();
    if (target.length != existing.length || !existing.containsAll(target)) {
      throw RepositoryFailure(RepositoryFailureReason.invalidInput);
    }
  }
}
