import 'package:drift/drift.dart';

import '../../../domain/identity/source_refs.dart';
import '../../../domain/library/library_models.dart';
import '../../../domain/library/repositories.dart';
import '../../../domain/library/repository_failure.dart';
import '../database.dart' show AppDatabase;
import 'repository_access.dart';

final class DriftShelfRepository implements ShelfRepository {
  DriftShelfRepository(AppDatabase db) : _access = RepositoryAccess(db);
  final RepositoryAccess _access;

  Shelf _shelf(QueryRow row) => Shelf(
    id: ShelfId(row.read<String>('shelf_id')),
    name: row.read<String>('name'),
    ordinal: row.read<int>('ordinal'),
  );
  Future<void> _require(ShelfId id) =>
      _access.requireRow('SELECT 1 FROM shelves WHERE shelf_id=?', [id.value]);
  Future<List<ShelfMember>> _members(ShelfId id) async => [
    for (final row in await _access.rows(
      'SELECT * FROM shelf_members WHERE shelf_id=? ORDER BY ordinal',
      [id.value],
    ))
      ShelfMember(
        shelfId: id,
        bookRef: RepositoryAccess.ref(row),
        ordinal: row.read<int>('ordinal'),
      ),
  ];

  @override
  Future<Shelf?> getShelf(ShelfId id) => _access.run(() async {
    final rows = await _access.rows('SELECT * FROM shelves WHERE shelf_id=?', [
      id.value,
    ]);
    return rows.isEmpty ? null : _shelf(rows.single);
  });
  @override
  Future<List<Shelf>> listShelves() => _access.run(
    () async => [
      for (final row in await _access.rows(
        'SELECT * FROM shelves ORDER BY ordinal, shelf_id COLLATE BINARY',
      ))
        _shelf(row),
    ],
  );
  @override
  Future<void> createShelf(Shelf shelf) => _access.run(() async {
    if (shelf.ordinal < 0) {
      throw RepositoryFailure(RepositoryFailureReason.invalidInput);
    }
    await _access.write(
      'INSERT INTO shelves(shelf_id,name,ordinal) VALUES (?,?,?)',
      [shelf.id.value, shelf.name, shelf.ordinal],
    );
  });
  @override
  Future<void> renameShelf(ShelfId id, String name) => _access.run(() async {
    await _require(id);
    await _access.write('UPDATE shelves SET name=? WHERE shelf_id=?', [
      name,
      id.value,
    ]);
  });
  @override
  Future<void> reorderShelves(List<ShelfId> ids) {
    final order = List<ShelfId>.of(ids);
    return _access.run(() async {
      final rows = await _access.rows('SELECT shelf_id FROM shelves');
      RepositoryAccess.permutation(
        order,
        rows.map((r) => ShelfId(r.read<String>('shelf_id'))),
      );
      // Shelf ordinals have no UNIQUE constraint; member ordinals do.
      for (var i = 0; i < order.length; i++) {
        await _access.write('UPDATE shelves SET ordinal=? WHERE shelf_id=?', [
          i,
          order[i].value,
        ]);
      }
    });
  }

  @override
  Future<void> deleteShelf(ShelfId id) => _access.run(() async {
    await _require(id);
    // RESTRICT can report SQLITE_CONSTRAINT_TRIGGER rather than FOREIGNKEY.
    // Identify approved external references without inspecting error messages.
    final references = await _access.rows(
      'SELECT 1 FROM app_preferences WHERE selected_shelf_id=? '
      'UNION ALL SELECT 1 FROM legacy_identity_mappings WHERE target_shelf_id=?',
      [id.value, id.value],
    );
    if (references.isNotEmpty) {
      throw RepositoryFailure(RepositoryFailureReason.invalidReference);
    }
    await _access.write('DELETE FROM shelf_members WHERE shelf_id=?', [
      id.value,
    ]);
    await _access.write('DELETE FROM shelves WHERE shelf_id=?', [id.value]);
  });
  @override
  Future<List<ShelfMember>> listMembers(ShelfId id) => _access.run(() async {
    await _require(id);
    return _members(id);
  });
  @override
  Future<void> addMember(ShelfId id, SourceBookRef ref) =>
      _access.run(() async {
        await _require(id);
        await _access.requireBook(ref);
        final members = await _members(id);
        if (members.any((m) => m.bookRef == ref)) {
          throw RepositoryFailure(RepositoryFailureReason.conflict);
        }
        final ordinal = members.isEmpty ? 0 : members.last.ordinal + 1;
        await _access.write(
          'INSERT INTO shelf_members(shelf_id,source_id,book_id,ordinal) VALUES (?,?,?,?)',
          [id.value, ...RepositoryAccess.keys(ref), ordinal],
        );
      });
  @override
  Future<void> removeMember(ShelfId id, SourceBookRef ref) =>
      _access.run(() async {
        await _require(id);
        await _access.write(
          'DELETE FROM shelf_members WHERE shelf_id=? AND source_id=? AND book_id=?',
          [id.value, ...RepositoryAccess.keys(ref)],
        );
      });

  Future<void> _replace(ShelfId id, List<SourceBookRef> refs) async {
    RepositoryAccess.unique(refs);
    for (final ref in refs) {
      await _access.requireBook(ref);
    }
    await _access.write('DELETE FROM shelf_members WHERE shelf_id=?', [
      id.value,
    ]);
    for (var i = 0; i < refs.length; i++) {
      await _access.write(
        'INSERT INTO shelf_members(shelf_id,source_id,book_id,ordinal) VALUES (?,?,?,?)',
        [id.value, ...RepositoryAccess.keys(refs[i]), i],
      );
    }
  }

  @override
  Future<void> replaceMembers(ShelfId id, List<SourceBookRef> refs) {
    final target = List<SourceBookRef>.of(refs);
    return _access.run(() async {
      await _require(id);
      await _replace(id, target);
    });
  }

  @override
  Future<void> reorderMembers(ShelfId id, List<SourceBookRef> refs) {
    final target = List<SourceBookRef>.of(refs);
    return _access.run(() async {
      await _require(id);
      RepositoryAccess.permutation(
        target,
        (await _members(id)).map((m) => m.bookRef),
      );
      await _replace(id, target);
    });
  }
}
