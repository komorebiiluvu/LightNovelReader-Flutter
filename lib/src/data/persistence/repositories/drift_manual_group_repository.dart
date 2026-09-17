import 'package:drift/drift.dart';

import '../../../domain/identity/source_refs.dart';
import '../../../domain/library/library_models.dart';
import '../../../domain/library/repositories.dart';
import '../../../domain/library/repository_failure.dart';
import '../database.dart' show AppDatabase;
import 'repository_access.dart';

final class DriftManualGroupRepository implements ManualGroupRepository {
  DriftManualGroupRepository(AppDatabase db) : _access = RepositoryAccess(db);
  final RepositoryAccess _access;
  ManualGroup _group(QueryRow row) => ManualGroup(
    id: ManualGroupId(row.read<String>('group_id')),
    displayName: row.readNullable<String>('display_name'),
  );
  Future<void> _require(ManualGroupId id) => _access.requireRow(
    'SELECT 1 FROM manual_groups WHERE group_id=?',
    [id.value],
  );

  @override
  Future<ManualGroup?> getGroup(ManualGroupId id) => _access.run(() async {
    final rows = await _access.rows(
      'SELECT * FROM manual_groups WHERE group_id=?',
      [id.value],
    );
    return rows.isEmpty ? null : _group(rows.single);
  });
  @override
  Future<List<ManualGroup>> listGroups() => _access.run(
    () async => [
      for (final row in await _access.rows(
        'SELECT * FROM manual_groups ORDER BY group_id COLLATE BINARY',
      ))
        _group(row),
    ],
  );
  @override
  Future<void> createGroup(ManualGroup group) => _access.run(
    () => _access.write(
      'INSERT INTO manual_groups(group_id,display_name) VALUES (?,?)',
      [group.id.value, group.displayName],
    ),
  );
  @override
  Future<void> renameGroup(ManualGroupId id, String? displayName) =>
      _access.run(() async {
        await _require(id);
        await _access.write(
          'UPDATE manual_groups SET display_name=? WHERE group_id=?',
          [displayName, id.value],
        );
      });
  @override
  Future<void> deleteGroup(ManualGroupId id) => _access.run(() async {
    await _require(id);
    if ((await _access.rows(
      'SELECT 1 FROM legacy_identity_mappings WHERE target_group_id=?',
      [id.value],
    )).isNotEmpty) {
      throw RepositoryFailure(RepositoryFailureReason.invalidReference);
    }
    await _access.write('DELETE FROM group_members WHERE group_id=?', [
      id.value,
    ]);
    await _access.write('DELETE FROM manual_groups WHERE group_id=?', [
      id.value,
    ]);
  });
  @override
  Future<List<ManualGroupMember>> listMembers(ManualGroupId id) =>
      _access.run(() async {
        await _require(id);
        return [
          for (final row in await _access.rows(
            'SELECT * FROM group_members WHERE group_id=? ORDER BY source_id COLLATE BINARY, book_id COLLATE BINARY',
            [id.value],
          ))
            ManualGroupMember(groupId: id, bookRef: RepositoryAccess.ref(row)),
        ];
      });
  @override
  Future<void> addMember(ManualGroupId id, SourceBookRef ref) => _access.run(
    () async {
      await _require(id);
      await _access.requireBook(ref);
      await _access.write(
        'INSERT INTO group_members(group_id,source_id,book_id) VALUES (?,?,?)',
        [id.value, ...RepositoryAccess.keys(ref)],
      );
    },
  );
  @override
  Future<void> removeMember(ManualGroupId id, SourceBookRef ref) =>
      _access.run(() async {
        await _require(id);
        await _access.write(
          'DELETE FROM group_members WHERE group_id=? AND source_id=? AND book_id=?',
          [id.value, ...RepositoryAccess.keys(ref)],
        );
      });
  @override
  Future<void> replaceMembers(ManualGroupId id, List<SourceBookRef> refs) {
    final target = List<SourceBookRef>.of(refs);
    return _access.run(() async {
      await _require(id);
      RepositoryAccess.unique(target);
      for (final ref in target) {
        await _access.requireBook(ref);
      }
      await _access.write('DELETE FROM group_members WHERE group_id=?', [
        id.value,
      ]);
      for (final ref in target) {
        await _access.write(
          'INSERT INTO group_members(group_id,source_id,book_id) VALUES (?,?,?)',
          [id.value, ...RepositoryAccess.keys(ref)],
        );
      }
    });
  }

  @override
  Future<SplitOverride?> getSplitOverride(SourceBookRef ref) => _access.run(
    () async {
      final rows = await _access.rows(
        'SELECT is_split FROM split_overrides WHERE source_id=? AND book_id=?',
        RepositoryAccess.keys(ref),
      );
      return rows.isEmpty
          ? null
          : SplitOverride(
              bookRef: ref,
              isSplit: rows.single.read<int>('is_split') == 1,
            );
    },
  );
  @override
  Future<void> setSplitOverride(SourceBookRef ref, bool isSplit) =>
      _access.run(() async {
        await _access.requireBook(ref);
        await _access.write(
          'INSERT INTO split_overrides(source_id,book_id,is_split) VALUES (?,?,?) ON CONFLICT(source_id,book_id) DO UPDATE SET is_split=excluded.is_split',
          [...RepositoryAccess.keys(ref), isSplit ? 1 : 0],
        );
      });
  @override
  Future<void> clearSplitOverride(SourceBookRef ref) => _access.run(
    () => _access.write(
      'DELETE FROM split_overrides WHERE source_id=? AND book_id=?',
      RepositoryAccess.keys(ref),
    ),
  );
}
