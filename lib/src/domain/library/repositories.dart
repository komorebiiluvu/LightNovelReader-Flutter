import '../identity/source_refs.dart';
import 'library_models.dart';

/// Missing singular reads return null. Mutations of missing owners throw
/// RepositoryFailure.notFound; missing referenced records are invalidReference.
abstract interface class LibraryRepository {
  Future<LibraryEntry?> get(SourceBookRef ref);

  /// Binary source ID, then book ID order; not user-defined order.
  Future<List<LibraryEntry>> list();
  Future<void> ensureStub(SourceBookRef ref);

  /// Full metadata replacement, creating a known entry if absent. Keeps saved.
  Future<void> saveMetadata(SourceBookRef ref, BookMetadataSnapshot metadata);

  /// Requires an existing entry. Never deletes user state.
  Future<void> setSaved(SourceBookRef ref, bool saved);
}

abstract interface class ShelfRepository {
  Future<Shelf?> getShelf(ShelfId id);

  /// Ordinal, then binary shelf ID.
  Future<List<Shelf>> listShelves();
  Future<void> createShelf(Shelf shelf);
  Future<void> renameShelf(ShelfId id, String name);

  /// Complete permutation of all shelf IDs; assigns contiguous ordinals.
  Future<void> reorderShelves(List<ShelfId> ids);

  /// Referenced shelves (e.g. selected preferences) fail without data loss.
  Future<void> deleteShelf(ShelfId id);
  Future<List<ShelfMember>> listMembers(ShelfId id);

  /// Append. Duplicate membership is a conflict.
  Future<void> addMember(ShelfId id, SourceBookRef ref);

  /// Missing membership is an idempotent no-op; owner must exist.
  Future<void> removeMember(ShelfId id, SourceBookRef ref);
  Future<void> replaceMembers(ShelfId id, List<SourceBookRef> refs);

  /// Complete permutation of existing members; no additions/removals.
  Future<void> reorderMembers(ShelfId id, List<SourceBookRef> refs);
}

abstract interface class ManualGroupRepository {
  Future<ManualGroup?> getGroup(ManualGroupId id);

  /// Binary group ID order.
  Future<List<ManualGroup>> listGroups();
  Future<void> createGroup(ManualGroup group);
  Future<void> renameGroup(ManualGroupId id, String? displayName);
  Future<void> deleteGroup(ManualGroupId id);

  /// Binary source ID, then book ID. No user-defined group member order.
  Future<List<ManualGroupMember>> listMembers(ManualGroupId id);

  /// Duplicate membership is a conflict.
  Future<void> addMember(ManualGroupId id, SourceBookRef ref);
  Future<void> removeMember(ManualGroupId id, SourceBookRef ref);
  Future<void> replaceMembers(ManualGroupId id, List<SourceBookRef> refs);

  /// Null (absent) is distinct from a stored false override.
  Future<SplitOverride?> getSplitOverride(SourceBookRef ref);
  Future<void> setSplitOverride(SourceBookRef ref, bool isSplit);
  Future<void> clearSplitOverride(SourceBookRef ref);
}
