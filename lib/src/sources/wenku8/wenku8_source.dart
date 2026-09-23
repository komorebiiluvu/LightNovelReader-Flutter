import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../domain/content/chapter_content.dart';
import '../../domain/identity/opaque_ids.dart';
import '../../domain/identity/source_refs.dart';
import '../../source/book_source.dart';
import '../../source/charset/charset.dart';
import '../../source/html/html.dart';
import '../../source/parser/source_parsed_models.dart';
import '../../source/session/source_session_manager.dart';
import '../../source/source_capability.dart';
import '../../source/source_continuation.dart';
import '../../source/source_diagnostics.dart';
import '../../source/source_explore.dart';
import '../../source/source_failure.dart';
import '../../source/source_models.dart';
import '../../source/transport/source_http_models.dart';
import '../../source/transport/source_transport.dart';
import 'wenku8_parser.dart';
import 'wenku8_parser_models.dart';
import 'wenku8_request_builder.dart';
import 'wenku8_request_models.dart';

final _wenku8Id = SourceId('builtin.wenku8');

/// BookSource composition for the built-in provider. No provider detail enters
/// Core or the F2 value types.
final class Wenku8Source extends GuardedBookSource {
  Wenku8Source({
    required this._transport,
    required this._sessions,
    Wenku8RequestBuilder? requests,
    Wenku8PureParser? parser,
    CharsetDecoder? decoder,
    HtmlDocumentParser? html,
    Wenku8AssetLocatorIndex? assets,
  }) : _requests = requests ?? Wenku8RequestBuilder(),
       _parser = parser ?? const Wenku8PureParser(),
       _decoder = decoder ?? const CharsetDecoder(),
       _html = html ?? const HtmlDocumentParser(),
       assets = assets ?? Wenku8AssetLocatorIndex();

  final SourceTransport _transport;
  final SourceSessionManager _sessions;
  final Wenku8RequestBuilder _requests;
  final Wenku8PureParser _parser;
  final CharsetDecoder _decoder;
  final HtmlDocumentParser _html;
  final Wenku8AssetLocatorIndex assets;

  @override
  final SourceDescriptor descriptor = SourceDescriptor(
    sourceId: _wenku8Id,
    displayName: 'Wenku8',
    capabilities: {
      SourceCapability.search,
      SourceCapability.explore,
      SourceCapability.bookDetail,
      SourceCapability.catalog,
      SourceCapability.chapterContent,
      SourceCapability.authentication,
      SourceCapability.cookies,
      SourceCapability.filters,
      SourceCapability.images,
    },
    exploreDescriptors: [
      ExploreDescriptor(id: 'home', title: '首页', isHome: true),
      for (final category in Wenku8ExploreCategory.values)
        ExploreDescriptor(id: category.name, title: category.name),
      ExploreDescriptor(
        id: 'tag',
        title: '标签',
        filters: [SourceFilterDescriptor(id: 'tag', label: '标签')],
      ),
    ],
  );

  @override
  Future<SearchResult> onSearch(
    SearchQuery query,
    SourceOperationContext context,
  ) async {
    if (query.filters.isNotEmpty) throw SourceFailure.invalidRequest();
    final page = _page(query.continuation);
    final document = await _load(
      () => _requests.buildSearch(
        Wenku8SearchIntent(query: query.text, page: page),
      ),
      context,
    );
    final parsed = _parseFor(context, () => _parser.parseSearch(document));
    final pagination = _parse(() => _parser.parsePagination(document));
    return SearchResult(
      items: [
        for (final book in parsed.items)
          SourceBookSummary(
            bookRef: _bookRef(book.providerKey),
            title: book.title,
          ),
      ],
      next: parsed.directDetail
          ? null
          : _nextSearch(
              query,
              context,
              page,
              pagination,
              allowMissing: parsed.validEmpty,
            ),
    );
  }

  @override
  Future<ExploreResult> onExplore(
    ExploreRequest request,
    SourceOperationContext context,
  ) async {
    final page = _page(request.continuation);
    final intent = _exploreIntent(request, page);
    final document = await _load(() => _requests.buildExplore(intent), context);
    final parsed = _parseFor(
      context,
      () => _parser.parseExplore(
        document,
        context: Wenku8ExploreContext(
          descriptor: request.descriptorId,
          blockId: request.descriptorId,
          blockTitle: request.descriptorId == 'tag'
              ? request.selections['tag']
              : _descriptorTitle(request.descriptorId),
          selections: request.selections,
        ),
      ),
    );
    final pagination = _parse(() => _parser.parsePagination(document));
    final blocks = <ExploreBlock>[
      for (final block in parsed.blocks)
        ExploreBlock(
          id: block.id,
          title: block.title,
          books: [
            for (final book in block.books)
              SourceBookSummary(
                bookRef: _bookRef(book.providerKey),
                title: book.title,
              ),
          ],
        ),
      if (parsed.items.isNotEmpty)
        ExploreBlock(
          id: request.descriptorId,
          title: _descriptorTitle(request.descriptorId),
          books: [
            for (final book in parsed.items)
              SourceBookSummary(
                bookRef: _bookRef(book.providerKey),
                title: book.title,
              ),
          ],
        ),
    ];
    return ExploreResult(
      blocks: blocks,
      next: _nextExplore(
        request,
        context,
        page,
        pagination,
        allowMissing: intent.isHome || parsed.validEmpty,
      ),
    );
  }

  @override
  Future<SourceBook> onGetBook(
    SourceBookRef book,
    SourceOperationContext context,
  ) async {
    final route = _route(book);
    final document = await _load(
      () => _requests.buildBookDetail(
        Wenku8BookDetailIntent(bookLocator: route.bookLocator),
      ),
      context,
    );
    final result = _parseFor(context, () => _parser.parseDetail(document));
    if (result is SourceParsedDetailUnavailable) {
      throw SourceFailure(code: SourceFailureCode.sourceUnavailable);
    }
    final detail = result as SourceParsedDetail;
    return SourceBook(
      bookRef: book,
      title: detail.title,
      author: detail.author,
      description: detail.description,
      coverAssetRef: detail.coverLocator == null
          ? null
          : assets.register(book, 'cover', detail.coverLocator!),
    );
  }

  @override
  Future<SourceCatalog> onGetCatalog(
    SourceBookRef book,
    SourceOperationContext context,
  ) async {
    final document = await _load(
      () => _requests.buildCatalog(Wenku8CatalogIntent(book: _route(book))),
      context,
    );
    final parsed = _parseFor(context, () => _parser.parseCatalog(document));
    final labels = {
      for (final volume in parsed.volumes) volume.providerKey: volume.label,
    };
    return SourceCatalog(
      chapters: [
        for (final chapter in parsed.chapters)
          SourceCatalogEntry(
            chapterRef: SourceChapterRef(
              sourceId: _wenku8Id,
              bookId: book.bookId,
              chapterId: ChapterId(_requiredChapterKey(chapter)),
            ),
            title: chapter.title,
            sourceOrdinal: chapter.ordinal,
            grouping:
                chapter.providerVolumeKey == null && chapter.groupLabel == null
                ? null
                : SourceCatalogGrouping(
                    label:
                        chapter.groupLabel ?? labels[chapter.providerVolumeKey],
                    volumeRef: chapter.providerVolumeKey == null
                        ? null
                        : SourceVolumeRef(
                            sourceId: _wenku8Id,
                            bookId: book.bookId,
                            volumeId: VolumeId(chapter.providerVolumeKey!),
                          ),
                  ),
          ),
      ],
    );
  }

  @override
  Future<ChapterContent> onGetChapterContent(
    SourceChapterRef chapter,
    SourceOperationContext context,
  ) async {
    final route = _route(
      SourceBookRef(sourceId: chapter.sourceId, bookId: chapter.bookId),
    );
    final locator = chapter.chapterId.value;
    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(locator)) {
      throw SourceFailure.invalidRequest();
    }
    final document = await _load(
      () => _requests.buildChapterContent(
        Wenku8ChapterContentIntent(book: route, chapterLocator: locator),
      ),
      context,
    );
    final parsed = _parseFor(context, () => _parser.parseContent(document));
    final book = SourceBookRef(
      sourceId: chapter.sourceId,
      bookId: chapter.bookId,
    );
    return ChapterContent(
      chapterRef: chapter,
      nodes: [
        for (final node in parsed.nodes)
          switch (node) {
            SourceParsedText(:final text) => TextNode(text),
            SourceParsedImage(:final locator) => ImageNode(
              assetRef: assets.register(book, chapter.chapterId.value, locator),
            ),
          },
      ],
    );
  }

  Future<ParsedHtmlDocument> _load(
    Wenku8BuiltRequest Function() construct,
    SourceOperationContext context,
  ) async {
    context.requireActive();
    late final Wenku8BuiltRequest built;
    try {
      built = construct();
    } on Wenku8RequestBuildException catch (error) {
      throw SourceFailure(
        code: switch (error.kind) {
          Wenku8RequestFailureKind.invalidHost ||
          Wenku8RequestFailureKind.invalidScheme ||
          Wenku8RequestFailureKind.userInfoNotAllowed ||
          Wenku8RequestFailureKind.arbitraryUriNotAllowed =>
            SourceFailureCode.securityPolicy,
          _ => SourceFailureCode.invalidRequest,
        },
      );
    } on ArgumentError {
      throw SourceFailure.invalidRequest();
    }
    final binding = _sessions.capture(_wenku8Id);
    if (binding.generation != context.sessionGeneration) {
      throw SourceFailure.cancelled();
    }
    final base = built.request;
    final request = SourceHttpRequest(
      sourceId: base.sourceId,
      operation: base.operation,
      method: base.method,
      uri: base.uri,
      headers: base.headers,
      policy: base.policy,
      cancellation: context.cancellation,
      sessionGeneration: binding.generation,
      sessionBinding: binding,
    );
    final response = await _transport.send(request);
    context.requireActive();
    if (!_sessions.isCurrent(binding)) throw SourceFailure.cancelled();
    if (response.finalUri.scheme != 'https' ||
        response.finalUri.host != request.uri.host ||
        response.finalUri.userInfo.isNotEmpty) {
      throw SourceFailure(code: SourceFailureCode.securityPolicy);
    }
    if (response.statusCode == 401 ||
        response.statusCode == 403 ||
        response.statusCode >= 300 &&
            response.statusCode < 400 &&
            (response.headers.first('location') ?? '').contains('login')) {
      _sessions.expire(_wenku8Id);
      throw _httpFailure(SourceFailureCode.authentication, request, response);
    }
    if (response.statusCode == 404) {
      throw _httpFailure(SourceFailureCode.notFound, request, response);
    }
    if (response.statusCode == 429) {
      throw _httpFailure(SourceFailureCode.rateLimit, request, response);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _httpFailure(SourceFailureCode.network, request, response);
    }
    try {
      final encoding = _responseEncoding(response.headers);
      final decoded = _decoder.decode(
        RawBytes(response.bodyBytes),
        encoding: encoding,
        evidence: CharsetEvidence(
          response.headers.first('content-type') == null
              ? 'Wenku8 default legacy CP936-compatible encoding'
              : 'Wenku8 HTTP Content-Type encoding policy',
        ),
      );
      final document = _html.parseFragment(decoded);
      final challenge = document.nodes
          .whereType<ParsedHtmlText>()
          .map((node) => node.text.toLowerCase())
          .any(
            (text) =>
                text.contains('access denied') ||
                text.contains('just a moment') ||
                text.contains('challenge'),
          );
      if (challenge) {
        throw SourceFailure(code: SourceFailureCode.incompatibleResponse);
      }
      final login = document.elements.any(
        (element) =>
            element.tag == 'form' &&
            (element.attribute('action') ?? '').toLowerCase().contains('login'),
      );
      if (login) {
        _sessions.expire(_wenku8Id);
        throw SourceFailure(code: SourceFailureCode.authentication);
      }
      return document;
    } on CharsetDecodeException {
      throw SourceFailure(code: SourceFailureCode.parse);
    } on HtmlParserException {
      throw SourceFailure(code: SourceFailureCode.parse);
    } on ArgumentError {
      throw SourceFailure(code: SourceFailureCode.incompatibleResponse);
    }
  }

  SourceContinuation? _nextSearch(
    SearchQuery query,
    SourceOperationContext context,
    int page,
    SourceParsedPagination parsed, {
    required bool allowMissing,
  }) {
    final next = _nextPage(page, parsed, allowMissing: allowMissing);
    return next == null
        ? null
        : SourceContinuation.forSearch(
            sourceId: _wenku8Id,
            queryText: query.text,
            filters: query.filters,
            sessionGeneration: context.sessionGeneration,
            opaqueValue: '$next',
          );
  }

  SourceContinuation? _nextExplore(
    ExploreRequest request,
    SourceOperationContext context,
    int page,
    SourceParsedPagination parsed, {
    required bool allowMissing,
  }) {
    final next = _nextPage(page, parsed, allowMissing: allowMissing);
    return next == null
        ? null
        : SourceContinuation.forExplore(
            sourceId: _wenku8Id,
            descriptorId: request.descriptorId,
            selections: request.selections,
            sessionGeneration: context.sessionGeneration,
            opaqueValue: '$next',
          );
  }

  int? _nextPage(
    int page,
    SourceParsedPagination parsed, {
    required bool allowMissing,
  }) {
    if (!allowMissing && parsed.source == 'missing-metadata') {
      throw SourceFailure(code: SourceFailureCode.parse);
    }
    if (parsed.currentPage != null && parsed.currentPage != page) {
      throw SourceFailure(code: SourceFailureCode.parse);
    }
    final next = parsed.nextPage;
    if (next != null && next <= page) {
      throw SourceFailure(code: SourceFailureCode.parse);
    }
    return next;
  }

  int _page(SourceContinuation? continuation) {
    if (continuation == null) return 1;
    final page = int.tryParse(continuation.opaqueValue);
    if (page == null || page < 2) throw SourceFailure.invalidRequest();
    return page;
  }

  Wenku8ExploreIntent _exploreIntent(ExploreRequest request, int page) {
    if (request.descriptorId == 'home') {
      if (request.selections.isNotEmpty) throw SourceFailure.invalidRequest();
      return Wenku8ExploreIntent.home(page: page);
    }
    if (request.descriptorId == 'tag') {
      if (request.selections.length != 1 ||
          !request.selections.containsKey('tag')) {
        throw SourceFailure.invalidRequest();
      }
      return Wenku8ExploreIntent.tag(request.selections['tag']!, page: page);
    }
    if (request.selections.isNotEmpty) throw SourceFailure.invalidRequest();
    for (final category in Wenku8ExploreCategory.values) {
      if (category.name == request.descriptorId) {
        return Wenku8ExploreIntent.category(category, page: page);
      }
    }
    throw SourceFailure.invalidRequest();
  }

  String _descriptorTitle(String id) => descriptor.exploreDescriptors
      .where((entry) => entry.id == id)
      .first
      .title;

  T _parseFor<T>(SourceOperationContext context, T Function() operation) {
    try {
      return _parse(operation);
    } on SourceFailure catch (failure) {
      if (failure.code == SourceFailureCode.authentication &&
          _sessions.snapshot(_wenku8Id).generation ==
              context.sessionGeneration) {
        _sessions.expire(_wenku8Id);
      }
      rethrow;
    }
  }
}

/// Ephemeral locator metadata. No URL is used as an AssetId or persisted here;
/// F6 must provide a reviewed durable resolution policy before image retrieval.
final class Wenku8AssetLocatorIndex {
  final Map<SourceAssetRef, String> _locators = {};

  SourceAssetRef register(SourceBookRef book, String scope, String locator) {
    if (book.sourceId != _wenku8Id) throw SourceFailure.invalidRequest();
    if (locator.isEmpty || locator.contains('\u0000')) {
      throw SourceFailure(code: SourceFailureCode.parse);
    }
    final digest = sha256.convert(
      utf8.encode(
        'wenku8.asset.v1\u0000${book.bookId.value}\u0000$scope\u0000$locator',
      ),
    );
    final ref = SourceAssetRef(
      sourceId: book.sourceId,
      bookId: book.bookId,
      assetId: AssetId('wk8-asset-v1-$digest'),
    );
    final existing = _locators[ref];
    if (existing != null && existing != locator) {
      throw SourceFailure(code: SourceFailureCode.securityPolicy);
    }
    _locators[ref] = locator;
    return ref;
  }

  String? locatorFor(SourceAssetRef ref) => _locators[ref];

  @override
  String toString() => 'Wenku8AssetLocatorIndex(${_locators.length} entries)';
}

SourceBookRef _bookRef(String providerKey) {
  if (!RegExp(r'^[0-9]+$').hasMatch(providerKey)) {
    throw SourceFailure(code: SourceFailureCode.parse);
  }
  return SourceBookRef(sourceId: _wenku8Id, bookId: BookId('wk8-$providerKey'));
}

Wenku8BookRoute _route(SourceBookRef book) {
  if (book.sourceId != _wenku8Id) throw SourceFailure.invalidRequest();
  final match = RegExp(r'^wk8-([0-9]+)$').firstMatch(book.bookId.value);
  final aid = match == null ? null : int.tryParse(match.group(1)!);
  if (aid == null || aid < 1) throw SourceFailure.invalidRequest();
  return Wenku8BookRoute(
    bookLocator: match!.group(1)!,
    directory: '${aid ~/ 1000}',
  );
}

String _requiredChapterKey(SourceParsedChapter chapter) {
  final key = chapter.providerKey;
  if (key == null || !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(key)) {
    throw SourceFailure(code: SourceFailureCode.parse);
  }
  return key;
}

SourceEncoding _responseEncoding(SourceHttpHeaders headers) {
  final contentType = headers.first('content-type');
  if (contentType == null) return SourceEncoding.legacyCp936Compatible;
  final label = RegExp(
    r'''(?:^|;)\s*charset\s*=\s*["']?([^;"'\s]+)''',
    caseSensitive: false,
  ).firstMatch(contentType)?.group(1);
  return label == null
      ? SourceEncoding.legacyCp936Compatible
      : normalizeSourceEncodingLabel(label);
}

T _parse<T>(T Function() operation) {
  try {
    return operation();
  } on Wenku8ParseException catch (error) {
    throw SourceFailure(
      code: switch (error.kind) {
        Wenku8ParseFailureKind.parse => SourceFailureCode.parse,
        Wenku8ParseFailureKind.incompatibleResponse =>
          SourceFailureCode.incompatibleResponse,
        Wenku8ParseFailureKind.authenticationRequired =>
          SourceFailureCode.authentication,
        Wenku8ParseFailureKind.unavailable =>
          SourceFailureCode.sourceUnavailable,
      },
      diagnostics: SourceFailureDiagnostics(operation: error.operation),
    );
  }
}

SourceFailure _httpFailure(
  SourceFailureCode code,
  SourceHttpRequest request,
  SourceHttpResponse response,
) => SourceFailure(
  code: code,
  retryable:
      code == SourceFailureCode.network || code == SourceFailureCode.rateLimit,
  diagnostics: SourceFailureDiagnostics(
    operation: request.operation,
    statusCode: response.statusCode,
  ),
);
