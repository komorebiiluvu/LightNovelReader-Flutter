import '../domain/identity/source_refs.dart';
import 'source_continuation.dart';
import 'source_failure.dart';

final class SearchQuery {
  SearchQuery({
    required this.text,
    Map<String, String> filters = const {},
    this.continuation,
  }) : filters = Map<String, String>.unmodifiable(filters);

  final String text;
  final Map<String, String> filters;
  final SourceContinuation? continuation;
}

final class SourceBookSummary {
  SourceBookSummary({
    required this.bookRef,
    required this.title,
    this.author,
    List<String> tags = const [],
    this.coverAssetRef,
  }) : tags = List<String>.unmodifiable(tags) {
    _requireBookAsset(bookRef, coverAssetRef);
  }

  final SourceBookRef bookRef;
  final String title;
  final String? author;
  final List<String> tags;
  final SourceAssetRef? coverAssetRef;
}

final class SourceBook {
  SourceBook({
    required this.bookRef,
    required this.title,
    this.author,
    this.description,
    List<String> tags = const [],
    this.coverAssetRef,
  }) : tags = List<String>.unmodifiable(tags) {
    _requireBookAsset(bookRef, coverAssetRef);
  }

  final SourceBookRef bookRef;
  final String title;
  final String? author;
  final String? description;
  final List<String> tags;
  final SourceAssetRef? coverAssetRef;
}

final class ExploreDescriptor {
  ExploreDescriptor({
    required this.id,
    required this.title,
    this.isHome = false,
    List<SourceFilterDescriptor> filters = const [],
  }) : filters = List<SourceFilterDescriptor>.unmodifiable(filters) {
    _requireNonEmpty(id, 'id');
  }

  final String id;
  final String title;
  final bool isHome;
  final List<SourceFilterDescriptor> filters;
}

final class SourceFilterDescriptor {
  SourceFilterDescriptor({
    required this.id,
    required this.label,
    List<String> values = const [],
  }) : values = List<String>.unmodifiable(values) {
    _requireNonEmpty(id, 'id');
  }

  final String id;
  final String label;
  final List<String> values;
}

final class ExploreRequest {
  ExploreRequest({
    required this.descriptorId,
    Map<String, String> selections = const {},
    this.continuation,
  }) : selections = Map<String, String>.unmodifiable(selections) {
    _requireNonEmpty(descriptorId, 'descriptorId');
  }

  final String descriptorId;
  final Map<String, String> selections;
  final SourceContinuation? continuation;
}

final class ExploreBlock {
  ExploreBlock({
    required this.id,
    required this.title,
    required List<SourceBookSummary> books,
  }) : books = List<SourceBookSummary>.unmodifiable(books) {
    _requireNonEmpty(id, 'id');
  }

  final String id;
  final String title;
  final List<SourceBookSummary> books;
}

final class ExploreResult {
  ExploreResult({required List<ExploreBlock> blocks, this.next})
    : blocks = List<ExploreBlock>.unmodifiable(blocks);

  final List<ExploreBlock> blocks;
  final SourceContinuation? next;
}

final class SourcePage<T> {
  SourcePage({required List<T> items, this.next})
    : items = List<T>.unmodifiable(items);

  final List<T> items;
  final SourceContinuation? next;
}

typedef SearchResult = SourcePage<SourceBookSummary>;

/// One canonical ordered chapter sequence. The list order is authoritative;
/// sourceOrdinal is optional provider metadata and never identity.
final class SourceCatalog {
  SourceCatalog({required List<SourceCatalogEntry> chapters})
    : chapters = List<SourceCatalogEntry>.unmodifiable(chapters);

  final List<SourceCatalogEntry> chapters;
}

final class SourceCatalogEntry {
  SourceCatalogEntry({
    required this.chapterRef,
    required this.title,
    this.sourceOrdinal,
    this.grouping,
  }) {
    if (sourceOrdinal != null && sourceOrdinal! < 0) {
      throw ArgumentError.value(sourceOrdinal, 'sourceOrdinal');
    }
    if (grouping?.volumeRef != null &&
        (grouping!.volumeRef!.sourceId != chapterRef.sourceId ||
            grouping!.volumeRef!.bookId != chapterRef.bookId)) {
      throw SourceFailure.invalidRequest();
    }
  }

  final SourceChapterRef chapterRef;
  final String title;
  final int? sourceOrdinal;
  final SourceCatalogGrouping? grouping;
}

/// Presentation grouping that may have no stable VolumeId.
final class SourceCatalogGrouping {
  SourceCatalogGrouping({this.label, this.volumeRef}) {
    if (label == null && volumeRef == null) {
      throw ArgumentError('A grouping needs a label or stable volume ref.');
    }
  }

  final String? label;
  final SourceVolumeRef? volumeRef;
}

void _requireBookAsset(SourceBookRef bookRef, SourceAssetRef? assetRef) {
  if (assetRef != null &&
      (assetRef.sourceId != bookRef.sourceId ||
          assetRef.bookId != bookRef.bookId)) {
    throw SourceFailure.invalidRequest();
  }
}

void _requireNonEmpty(String value, String name) {
  if (value.isEmpty) throw ArgumentError.value(value, name);
}
