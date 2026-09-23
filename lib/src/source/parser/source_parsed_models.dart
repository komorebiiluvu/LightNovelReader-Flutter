/// Provider keys and locators remain parser evidence. F3.5 owns conversion to
/// verified F2 opaque identities; an ordinal never becomes an ID here.
final class SourceParsedBook {
  const SourceParsedBook({required this.providerKey, required this.title});

  final String providerKey;
  final String title;
}

final class SourceParsedPagination {
  SourceParsedPagination({
    this.currentPage,
    this.totalPages,
    this.nextPage,
    required this.exhausted,
    required this.validPage,
    required this.source,
    List<int> linkedPages = const [],
  }) : linkedPages = List<int>.unmodifiable(linkedPages) {
    if ((currentPage != null && currentPage! < 1) ||
        (totalPages != null && totalPages! < 1) ||
        (currentPage != null &&
            totalPages != null &&
            totalPages! < currentPage!) ||
        (nextPage != null && nextPage! < 1) ||
        (currentPage != null &&
            nextPage != null &&
            nextPage! <= currentPage!) ||
        (exhausted && nextPage != null) ||
        this.linkedPages.any((page) => page < 1)) {
      throw ArgumentError('Invalid pagination evidence');
    }
  }

  final int? currentPage;
  final int? totalPages;
  final int? nextPage;
  final bool exhausted;
  final bool validPage;
  final String source;
  final List<int> linkedPages;
}

final class SourceParsedSearch {
  SourceParsedSearch({
    required List<SourceParsedBook> items,
    this.pagination,
    this.directDetail = false,
    this.validEmpty = false,
  }) : items = List<SourceParsedBook>.unmodifiable(items);

  final List<SourceParsedBook> items;
  final SourceParsedPagination? pagination;
  final bool directDetail;
  final bool validEmpty;
}

final class SourceParsedExploreBlock {
  SourceParsedExploreBlock({
    required this.id,
    required this.title,
    required List<SourceParsedBook> books,
  }) : books = List<SourceParsedBook>.unmodifiable(books);

  final String id;
  final String title;
  final List<SourceParsedBook> books;
}

final class SourceParsedExplore {
  SourceParsedExplore({
    required this.descriptor,
    required List<SourceParsedExploreBlock> blocks,
    required List<SourceParsedBook> items,
    required this.validEmpty,
    required Map<String, String> selections,
    this.pagination,
  }) : blocks = List<SourceParsedExploreBlock>.unmodifiable(blocks),
       items = List<SourceParsedBook>.unmodifiable(items),
       selections = Map<String, String>.unmodifiable(selections);

  final String descriptor;
  final List<SourceParsedExploreBlock> blocks;
  final List<SourceParsedBook> items;
  final bool validEmpty;
  final Map<String, String> selections;
  final SourceParsedPagination? pagination;
}

sealed class SourceParsedDetailResult {
  const SourceParsedDetailResult();
}

final class SourceParsedDetail extends SourceParsedDetailResult {
  SourceParsedDetail({
    required this.title,
    this.author,
    this.description,
    this.coverLocator,
    Map<String, String> fields = const {},
  }) : fields = Map<String, String>.unmodifiable(fields);

  final String title;
  final String? author;
  final String? description;
  final String? coverLocator;
  final Map<String, String> fields;
}

final class SourceParsedDetailUnavailable extends SourceParsedDetailResult {
  const SourceParsedDetailUnavailable(this.reason);
  final String reason;
}

final class SourceParsedVolume {
  const SourceParsedVolume({required this.providerKey, this.label});
  final String providerKey;
  final String? label;
}

final class SourceParsedChapter {
  const SourceParsedChapter({
    required this.title,
    required this.ordinal,
    this.providerKey,
    this.providerVolumeKey,
    this.groupLabel,
  });

  final String title;
  final int ordinal;
  final String? providerKey;
  final String? providerVolumeKey;
  final String? groupLabel;
}

final class SourceParsedCatalog {
  SourceParsedCatalog({
    required List<SourceParsedChapter> chapters,
    required List<SourceParsedVolume> volumes,
  }) : chapters = List<SourceParsedChapter>.unmodifiable(chapters),
       volumes = List<SourceParsedVolume>.unmodifiable(volumes);

  final List<SourceParsedChapter> chapters;
  final List<SourceParsedVolume> volumes;
}

sealed class SourceParsedContentNode {
  const SourceParsedContentNode();
}

final class SourceParsedText extends SourceParsedContentNode {
  const SourceParsedText(this.text);
  final String text;
}

final class SourceParsedImage extends SourceParsedContentNode {
  const SourceParsedImage(this.locator);
  final String locator;
}

final class SourceParsedContent {
  SourceParsedContent(List<SourceParsedContentNode> nodes)
    : nodes = List<SourceParsedContentNode>.unmodifiable(nodes);

  final List<SourceParsedContentNode> nodes;
}
