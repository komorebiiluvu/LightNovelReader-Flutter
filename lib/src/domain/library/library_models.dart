import '../identity/opaque_ids.dart';
import '../identity/source_refs.dart';

final class ShelfId extends OpaqueId {
  ShelfId(super.value);
}

final class ManualGroupId extends OpaqueId {
  ManualGroupId(super.value);
}

enum MetadataState { known, stub }

final class BookMetadataSnapshot {
  BookMetadataSnapshot({
    this.title,
    this.author,
    this.description,
    this.coverAssetRef,
    List<String> tags = const [],
    this.knownTotalChapters,
    this.updateFlag,
  }) : tags = List.unmodifiable(tags);

  final String? title;
  final String? author;
  final String? description;
  final SourceAssetRef? coverAssetRef;
  final List<String> tags;
  final int? knownTotalChapters;
  final bool? updateFlag;
}

final class LibraryEntry {
  const LibraryEntry({
    required this.bookRef,
    required this.saved,
    required this.metadataState,
    required this.metadata,
  });

  final SourceBookRef bookRef;
  final bool saved;
  final MetadataState metadataState;
  final BookMetadataSnapshot metadata;
}

final class Shelf {
  const Shelf({required this.id, required this.name, required this.ordinal});
  final ShelfId id;
  final String name;
  final int ordinal;
}

final class ShelfMember {
  const ShelfMember({
    required this.shelfId,
    required this.bookRef,
    required this.ordinal,
  });
  final ShelfId shelfId;
  final SourceBookRef bookRef;
  final int ordinal;
}

final class ManualGroup {
  const ManualGroup({required this.id, this.displayName});
  final ManualGroupId id;
  final String? displayName;
}

final class ManualGroupMember {
  const ManualGroupMember({required this.groupId, required this.bookRef});
  final ManualGroupId groupId;
  final SourceBookRef bookRef;
}

final class SplitOverride {
  const SplitOverride({required this.bookRef, required this.isSplit});
  final SourceBookRef bookRef;
  final bool isSplit;
}
