import '../../source/html/html_models.dart';
import '../../source/parser/source_parsed_models.dart';
import '../../source/source_operation.dart';
import 'wenku8_parser_models.dart';

/// Pure Wenku8 normalization over source-neutral HTML evidence.
///
/// This layer does not decode bytes, execute requests, assign F2 identities,
/// or retain DOM/package objects. Callers own request and session context.
final class Wenku8PureParser {
  const Wenku8PureParser();

  SourceParsedSearch parseSearch(
    ParsedHtmlDocument document, {
    SourceParsedPagination? pagination,
  }) {
    if (_hasText(document, 'access denied')) {
      _fail(
        SourceOperation.search,
        Wenku8ParseFailureKind.incompatibleResponse,
        reason: Wenku8ParseReason.waf,
      );
    }
    if (document.elements.any(
      (element) =>
          element.tag == 'form' &&
          (element.attribute('action') ?? '').toLowerCase().contains('login'),
    )) {
      _fail(
        SourceOperation.search,
        Wenku8ParseFailureKind.authenticationRequired,
      );
    }
    final books = _books(document, SourceOperation.search);
    final heading = _firstTextOfTag(document, 'h1');
    if (heading != null && books.length == 1) {
      return SourceParsedSearch(
        items: [
          SourceParsedBook(
            providerKey: books.single.providerKey,
            title: heading,
          ),
        ],
        directDetail: true,
      );
    }
    final empty = books.isEmpty && _hasText(document, '0 results');
    if (books.isEmpty && !empty) {
      _fail(
        SourceOperation.search,
        Wenku8ParseFailureKind.parse,
        reason: Wenku8ParseReason.missingResults,
      );
    }
    return SourceParsedSearch(
      items: books,
      pagination: pagination,
      validEmpty: empty,
    );
  }

  SourceParsedExplore parseExplore(
    ParsedHtmlDocument document, {
    required Wenku8ExploreContext context,
  }) {
    final centers = document.elements
        .where((element) => element.attribute('id') == 'centers')
        .firstOrNull;
    if (centers != null) {
      final contents = document.elements
          .where(
            (element) =>
                element.hasClass('blockcontent') &&
                centers.startNodeIndex <= element.startNodeIndex &&
                element.endNodeIndex <= centers.endNodeIndex,
          )
          .toList();
      if (contents.isNotEmpty) {
        if (context.blockId == null || context.blockId!.isEmpty) {
          _fail(
            SourceOperation.explore,
            Wenku8ParseFailureKind.parse,
            reason: Wenku8ParseReason.blockId,
          );
        }
        final titles = document.elements
            .where(
              (element) =>
                  element.hasClass('blocktitle') &&
                  centers.startNodeIndex <= element.startNodeIndex &&
                  element.endNodeIndex <= centers.endNodeIndex,
            )
            .toList();
        final blocks = <SourceParsedExploreBlock>[];
        for (final content in contents) {
          final heading = titles
              .where(
                (element) =>
                    element.depth == content.depth &&
                    element.endNodeIndex <= content.startNodeIndex,
              )
              .lastOrNull;
          final title = heading == null
              ? null
              : _textIn(document, heading).split(RegExp(r'[（(]')).first.trim();
          final books = _books(
            document,
            SourceOperation.explore,
            within: content,
          );
          if (title == null || title.isEmpty || books.isEmpty) continue;
          blocks.add(
            SourceParsedExploreBlock(
              id: '${context.blockId}-${blocks.length}',
              title: title,
              books: books,
            ),
          );
        }
        if (blocks.isEmpty) {
          _fail(
            SourceOperation.explore,
            Wenku8ParseFailureKind.parse,
            reason: Wenku8ParseReason.blockContent,
          );
        }
        return SourceParsedExplore(
          descriptor: context.descriptor,
          blocks: blocks,
          items: const [],
          validEmpty: false,
          selections: context.selections,
          pagination: context.pagination,
        );
      }
    }
    final candidates = document.elements
        .where(
          (element) =>
              element.tag == 'div' &&
              (element.hasClass('block') ||
                  (element.attribute('id') != null &&
                      !const {
                        'content',
                        'intro',
                        'pagestats',
                        'pagelink',
                      }.contains(element.attribute('id')))),
        )
        .toList(growable: false);
    final blocks = <SourceParsedExploreBlock>[];
    for (final element in candidates) {
      final books = _books(document, SourceOperation.explore, within: element);
      if (books.isEmpty && _hasTextIn(document, element, '暂无')) continue;
      final title =
          _headingIn(document, element) ??
          (books.isEmpty
              ? _textIn(document, element).trim()
              : context.blockTitle);
      if (title == null || title.isEmpty) {
        _fail(
          SourceOperation.explore,
          Wenku8ParseFailureKind.parse,
          reason: Wenku8ParseReason.blockTitle,
        );
      }
      if (books.isEmpty && element.hasClass('block')) {
        _fail(
          SourceOperation.explore,
          Wenku8ParseFailureKind.parse,
          reason: Wenku8ParseReason.blockContent,
        );
      }
      final blockId = element.attribute('id') ?? context.blockId;
      if (blockId == null || blockId.isEmpty) {
        _fail(
          SourceOperation.explore,
          Wenku8ParseFailureKind.parse,
          reason: Wenku8ParseReason.blockId,
        );
      }
      blocks.add(
        SourceParsedExploreBlock(id: blockId, title: title, books: books),
      );
    }
    var items = <SourceParsedBook>[];
    if (blocks.isEmpty) {
      items = _books(document, SourceOperation.explore);
      if (items.isNotEmpty && context.blockId != null) {
        final title = context.blockTitle ?? _firstTextOfTag(document, 'h1');
        if (title == null || title.isEmpty) {
          _fail(
            SourceOperation.explore,
            Wenku8ParseFailureKind.parse,
            reason: Wenku8ParseReason.blockTitle,
          );
        }
        blocks.add(
          SourceParsedExploreBlock(
            id: context.blockId!,
            title: title,
            books: items,
          ),
        );
        items = [];
      }
    }
    final empty =
        blocks.isEmpty &&
        items.isEmpty &&
        (_hasText(document, '暂无') || _hasText(document, '0 results'));
    if (blocks.isEmpty && items.isEmpty && !empty) {
      _fail(
        SourceOperation.explore,
        Wenku8ParseFailureKind.parse,
        reason: Wenku8ParseReason.missingResults,
      );
    }
    return SourceParsedExplore(
      descriptor: context.descriptor,
      blocks: blocks,
      items: items,
      validEmpty: empty,
      selections: context.selections,
      pagination: context.pagination,
    );
  }

  SourceParsedPagination parsePagination(ParsedHtmlDocument document) {
    final pageLink = document.elements
        .where((element) => element.attribute('id') == 'pagelink')
        .firstOrNull;
    final stats = document.elements
        .where(
          (element) =>
              element.attribute('id') == 'pagestats' ||
              (element.tag == 'em' &&
                  pageLink != null &&
                  pageLink.startNodeIndex <= element.startNodeIndex &&
                  element.endNodeIndex <= pageLink.endNodeIndex),
        )
        .firstOrNull;
    if (stats != null) {
      final value = _textIn(document, stats).trim();
      final match = RegExp(r'^(\d+)\s*/\s*(\d+)$').firstMatch(value);
      if (match == null) {
        _fail(
          SourceOperation.search,
          Wenku8ParseFailureKind.parse,
          reason: Wenku8ParseReason.pagination,
        );
      }
      final current = int.tryParse(match.group(1)!);
      final total = int.tryParse(match.group(2)!);
      if (current == null || total == null || current < 1 || total < current) {
        _fail(
          SourceOperation.search,
          Wenku8ParseFailureKind.parse,
          reason: Wenku8ParseReason.pagination,
        );
      }
      return SourceParsedPagination(
        currentPage: current,
        totalPages: total,
        nextPage: current < total ? current + 1 : null,
        exhausted: current == total,
        validPage: true,
        source: stats.attribute('id') == 'pagestats'
            ? 'pagestats'
            : 'pagelink-em',
      );
    }
    final linked = <int>{};
    for (final element in document.elements.where(
      (element) => element.tag == 'a',
    )) {
      final href = element.attribute('href');
      if (href == null) continue;
      final match = RegExp(r'(?:\?|&)page=\s*(\d+)\s*(?:&|$)')
          .firstMatch(href.trim());
      if (match != null) {
        final page = int.tryParse(match.group(1)!);
        if (page == null || page < 1) {
          _fail(
            SourceOperation.search,
            Wenku8ParseFailureKind.parse,
            reason: Wenku8ParseReason.pagination,
          );
        }
        linked.add(page);
      }
    }
    final pages = linked.toList()..sort();
    return SourceParsedPagination(
      totalPages: pages.isEmpty ? null : pages.last,
      nextPage: pages.isEmpty ? null : pages.last,
      exhausted: false,
      validPage: true,
      source: pages.isEmpty ? 'missing-metadata' : 'largest-linked-page',
      linkedPages: pages,
    );
  }

  SourceParsedDetailResult parseDetail(ParsedHtmlDocument document) {
    final content = document.elements
        .where((element) => element.attribute('id') == 'content')
        .firstOrNull;
    final boldTitle = content == null
        ? null
        : document.elements
              .where(
                (element) =>
                    element.tag == 'b' &&
                    content.startNodeIndex <= element.startNodeIndex &&
                    element.endNodeIndex <= content.endNodeIndex,
              )
              .map((element) => _textIn(document, element).trim())
              .where((value) => value.isNotEmpty)
              .firstOrNull;
    final rawTitle = _firstTextOfTag(document, 'h1') ?? boldTitle;
    final title = rawTitle == null
        ? null
        : RegExp(r'^(.+?)\s*[（(].*[）)]\s*$')
                  .firstMatch(rawTitle)
                  ?.group(1)
                  ?.trim() ??
              rawTitle;
    if (title == null) {
      if (document.elements.any((element) => element.hasClass('copyright'))) {
        return const SourceParsedDetailUnavailable('copyright');
      }
      _fail(
        SourceOperation.bookDetail,
        Wenku8ParseFailureKind.parse,
        field: Wenku8ParseField.title,
      );
    }
    if (content != null && _hasTextIn(document, content, '因版权问题')) {
      return const SourceParsedDetailUnavailable('copyright');
    }
    final author = document.elements
        .where((element) => element.hasClass('author'))
        .firstOrNull;
    final images = document.nodes.whereType<ParsedHtmlImage>();
    final cover =
        images
            .where(
              (image) =>
                  image.rawLocator.contains('img.wenku8.com') ||
                  image.rawLocator.contains('/image/'),
            )
            .firstOrNull ??
        images.firstOrNull;
    final fields = parseDetailTableFields(document);
    return SourceParsedDetail(
      title: title,
      author: author == null
          ? _labeledField(document, '小说作者') ?? fields['author']
          : _textIn(document, author).trim(),
      description: parseDescription(document),
      coverLocator: cover?.rawLocator,
      fields: fields,
    );
  }

  String? parseDescription(ParsedHtmlDocument document) {
    final intro = document.elements
        .where((element) => element.attribute('id') == 'intro')
        .firstOrNull;
    if (intro != null) return _textIn(document, intro).trim();
    final spans = document.elements
        .where((element) => element.tag == 'span')
        .toList();
    final marker = spans
        .where((element) => _textIn(document, element).contains('内容简介'))
        .firstOrNull;
    if (marker == null) return null;
    for (final candidate in spans) {
      if (candidate.depth != marker.depth ||
          candidate.startNodeIndex < marker.endNodeIndex) {
        continue;
      }
      final hasLink = document.elements.any(
        (element) =>
            element.tag == 'a' &&
            candidate.startNodeIndex <= element.startNodeIndex &&
            element.endNodeIndex <= candidate.endNodeIndex,
      );
      if (hasLink) continue;
      final text = _textIn(document, candidate).trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  /// Table-cell boundary evidence can be checked even on a detail fragment
  /// that lacks the required title and is not a complete book detail response.
  Map<String, String> parseDetailTableFields(ParsedHtmlDocument document) {
    final cells = document.elements
        .where((element) => element.tag == 'td')
        .map((element) => _textIn(document, element).trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    return Map<String, String>.unmodifiable({
      if (cells.isNotEmpty) 'author': cells[0],
      if (cells.length > 1) 'publisher': cells[1],
    });
  }

  SourceParsedCatalog parseCatalog(ParsedHtmlDocument document) {
    final volumeElements = document.elements
        .where(
          (element) =>
              element.attribute('data-vid') != null ||
              (element.tag == 'td' &&
                  element.hasClass('vcss') &&
                  element.attribute('vid') != null),
        )
        .toList();
    final volumes = [
      for (final element in volumeElements)
        SourceParsedVolume(
          providerKey:
              element.attribute('data-vid') ?? element.attribute('vid')!,
          label:
              (element.tag == 'td'
                      ? _textIn(document, element)
                      : _directTextIn(document, element))
                  .trim()
                  .nullIfEmpty,
        ),
    ];
    final headings = document.elements
        .where((element) => element.tag == 'h2')
        .toList();
    final chapters = <SourceParsedChapter>[];
    final seen = <String>{};
    for (final anchor in document.elements.where(
      (element) => element.tag == 'a',
    )) {
      final href = anchor.attribute('href');
      if (href == null) continue;
      final absolute = RegExp(r'^/novel/[^/]+/([^/?#]+)').firstMatch(href);
      final inTableCell = document.elements.any(
        (element) =>
            element.tag == 'td' &&
            element.startNodeIndex <= anchor.startNodeIndex &&
            anchor.endNodeIndex <= element.endNodeIndex,
      );
      final relative = inTableCell
          ? RegExp(r'^([^/?#]+)\.htm$').firstMatch(href)
          : null;
      final key = absolute?.group(1) ?? relative?.group(1);
      if (key == 'index' || (!href.startsWith('/novel/') && relative == null)) {
        continue;
      }
      if (key != null && !seen.add(key)) {
        _fail(
          SourceOperation.catalog,
          Wenku8ParseFailureKind.parse,
          reason: Wenku8ParseReason.duplicateChapterId,
        );
      }
      final title = _textIn(document, anchor).trim();
      if (title.isEmpty) {
        _fail(
          SourceOperation.catalog,
          Wenku8ParseFailureKind.parse,
          field: Wenku8ParseField.title,
          itemIndex: chapters.length,
        );
      }
      final volume = volumeElements
          .where(
            (element) =>
                element.startNodeIndex <= anchor.startNodeIndex &&
                anchor.endNodeIndex <= element.endNodeIndex,
          )
          .lastOrNull;
      final precedingTableVolume = volume == null && relative != null
          ? volumeElements
                .where(
                  (element) =>
                      element.tag == 'td' &&
                      element.hasClass('vcss') &&
                      document.elements.indexOf(element) <
                          document.elements.indexOf(anchor),
                )
                .lastOrNull
          : null;
      final heading = headings
          .where((element) => element.endNodeIndex <= anchor.startNodeIndex)
          .lastOrNull;
      chapters.add(
        SourceParsedChapter(
          providerKey: key,
          title: title,
          ordinal: chapters.length,
          providerVolumeKey:
              volume?.attribute('data-vid') ??
              precedingTableVolume?.attribute('vid'),
          groupLabel:
              volume == null && precedingTableVolume == null && heading != null
              ? _textIn(document, heading).trim()
              : null,
        ),
      );
    }
    if (chapters.isEmpty && volumes.isEmpty) {
      _fail(
        SourceOperation.catalog,
        Wenku8ParseFailureKind.parse,
        reason: Wenku8ParseReason.missingCatalog,
      );
    }
    return SourceParsedCatalog(chapters: chapters, volumes: volumes);
  }

  SourceParsedContent parseContent(ParsedHtmlDocument document) {
    if (document.parseErrorCount > 0) {
      _fail(
        SourceOperation.chapterContent,
        Wenku8ParseFailureKind.parse,
        reason: Wenku8ParseReason.malformedDom,
      );
    }
    final content = document.elements
        .where((element) => element.attribute('id') == 'content')
        .firstOrNull;
    final start = content?.startNodeIndex ?? 0;
    final end = content?.endNodeIndex ?? document.nodes.length;
    final chrome = document.elements
        .where(
          (element) =>
              element.hasClass('nav') &&
              element.startNodeIndex >= start &&
              element.endNodeIndex <= end,
        )
        .toList();
    final breaks = document.elements
        .where(
          (element) =>
              element.tag == 'br' &&
              element.startNodeIndex >= start &&
              element.startNodeIndex <= end,
        )
        .toList();
    final paragraphs = document.elements
        .where(
          (element) =>
              element.tag == 'p' &&
              element.startNodeIndex >= start &&
              element.endNodeIndex <= end,
        )
        .toList();
    final result = <SourceParsedContentNode>[];
    final text = StringBuffer();
    ParsedHtmlElement? activeParagraph;
    var previousBreak = false;

    void flush({bool empty = false}) {
      final value = text.toString().trim();
      if (value.isNotEmpty || empty) result.add(SourceParsedText(value));
      text.clear();
    }

    for (var index = start; index <= end; index++) {
      for (final _ in breaks.where(
        (element) => element.startNodeIndex == index,
      )) {
        flush(empty: previousBreak);
        previousBreak = true;
      }
      if (index == end ||
          chrome.any(
            (element) =>
                element.startNodeIndex <= index && index < element.endNodeIndex,
          )) {
        continue;
      }
      final node = document.nodes[index];
      final paragraph = paragraphs
          .where(
            (element) =>
                element.startNodeIndex <= index && index < element.endNodeIndex,
          )
          .lastOrNull;
      if (paragraph != activeParagraph && text.isNotEmpty) flush();
      activeParagraph = paragraph;
      if (node is ParsedHtmlText) {
        text.write(node.text);
        previousBreak = false;
      } else if (node is ParsedHtmlImage) {
        flush();
        result.add(SourceParsedImage(node.rawLocator));
        previousBreak = false;
      }
      if (paragraph != null && index + 1 == paragraph.endNodeIndex) flush();
    }
    flush();
    if (content == null && result.isEmpty) {
      _fail(
        SourceOperation.chapterContent,
        Wenku8ParseFailureKind.parse,
        reason: Wenku8ParseReason.missingContentContainer,
      );
    }
    return SourceParsedContent(result);
  }
}

List<SourceParsedBook> _books(
  ParsedHtmlDocument document,
  SourceOperation operation, {
  ParsedHtmlElement? within,
}) {
  final keys = <String>[];
  final titles = <String, String>{};
  final firstIndexes = <String, int>{};
  var itemIndex = 0;
  for (final anchor in document.elements.where(
    (element) => element.tag == 'a',
  )) {
    if (within != null &&
        (anchor.startNodeIndex < within.startNodeIndex ||
            anchor.endNodeIndex > within.endNodeIndex)) {
      continue;
    }
    final href = anchor.attribute('href');
    if (href == null) {
      _fail(
        operation,
        Wenku8ParseFailureKind.parse,
        reason: Wenku8ParseReason.missingBookHref,
        itemIndex: itemIndex,
      );
    }
    final match = RegExp(r'^/book/([0-9]+)(?:\.htm)?(?:[?#].*)?$')
        .firstMatch(href);
    if (match == null) continue;
    final rawTitle =
        _textIn(document, anchor).trim().nullIfEmpty ??
        anchor.attribute('title')?.trim() ??
        '';
    final title =
        RegExp(r'^(.+?)\s*[（(].*[）)]\s*$')
            .firstMatch(rawTitle)
            ?.group(1)
            ?.trim() ??
        rawTitle;
    final key = match.group(1)!;
    if (!firstIndexes.containsKey(key)) {
      keys.add(key);
      firstIndexes[key] = itemIndex;
    }
    if (title.isNotEmpty && !titles.containsKey(key)) {
      titles[key] = title;
    }
    itemIndex++;
  }
  return [
    for (final key in keys)
      SourceParsedBook(
        providerKey: key,
        title:
            titles[key] ??
            (_fail(
              operation,
              Wenku8ParseFailureKind.parse,
              field: Wenku8ParseField.title,
              itemIndex: firstIndexes[key],
            )),
      ),
  ];
}

String _textIn(ParsedHtmlDocument document, ParsedHtmlElement element) =>
    document.nodes
        .getRange(element.startNodeIndex, element.endNodeIndex)
        .whereType<ParsedHtmlText>()
        .map((node) => node.text)
        .join();

String _directTextIn(ParsedHtmlDocument document, ParsedHtmlElement element) =>
    document.nodes
        .getRange(element.startNodeIndex, element.endNodeIndex)
        .whereType<ParsedHtmlText>()
        .where((node) => node.depth == element.depth + 1)
        .map((node) => node.text)
        .join();

bool _hasTextIn(
  ParsedHtmlDocument document,
  ParsedHtmlElement element,
  String needle,
) => _textIn(document, element).contains(needle);

bool _hasText(ParsedHtmlDocument document, String needle) => document.nodes
    .whereType<ParsedHtmlText>()
    .any((node) => node.text.toLowerCase().contains(needle.toLowerCase()));

String? _firstTextOfTag(ParsedHtmlDocument document, String tag) => document
    .elements
    .where((element) => element.tag == tag)
    .map((element) => _textIn(document, element).trim())
    .where((value) => value.isNotEmpty)
    .firstOrNull;

String? _labeledField(ParsedHtmlDocument document, String label) {
  for (final cell in document.elements.where(
    (element) => element.tag == 'td',
  )) {
    final text = _textIn(document, cell).trim();
    final match = RegExp('$label\\s*[:：]\\s*(.+)').firstMatch(text);
    if (match != null) return match.group(1)?.trim();
  }
  return null;
}

String? _headingIn(ParsedHtmlDocument document, ParsedHtmlElement parent) =>
    document.elements
        .where(
          (element) =>
              (element.tag == 'h1' || element.tag == 'h2') &&
              element.startNodeIndex >= parent.startNodeIndex &&
              element.endNodeIndex <= parent.endNodeIndex,
        )
        .map((element) => _textIn(document, element).trim())
        .where((value) => value.isNotEmpty)
        .firstOrNull;

Never _fail(
  SourceOperation operation,
  Wenku8ParseFailureKind kind, {
  Wenku8ParseField? field,
  Wenku8ParseReason? reason,
  int? itemIndex,
}) => throw Wenku8ParseException(
  operation: operation,
  kind: kind,
  field: field,
  reason: reason,
  itemIndex: itemIndex,
);

extension _EmptyString on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
