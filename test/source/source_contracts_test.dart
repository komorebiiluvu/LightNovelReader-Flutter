import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_reader/src/domain/content/chapter_content.dart';
import 'package:light_novel_reader/src/domain/identity/opaque_ids.dart';
import 'package:light_novel_reader/src/domain/identity/source_refs.dart';
import 'package:light_novel_reader/src/source/source.dart';

const allCapabilities = <SourceCapability>{
  SourceCapability.search,
  SourceCapability.explore,
  SourceCapability.bookDetail,
  SourceCapability.catalog,
  SourceCapability.chapterContent,
  SourceCapability.images,
  SourceCapability.authentication,
  SourceCapability.cookies,
  SourceCapability.filters,
  SourceCapability.updates,
};

SourceOperationContext operationContext(
  SourceId sourceId,
  SourceOperation operation, {
  int generation = 0,
  SourceCancellation? cancellation,
}) => SourceOperationContext(
  sourceId: sourceId,
  operation: operation,
  sessionGeneration: generation,
  cancellation: cancellation ?? SourceCancellation(),
);

SourceBookRef bookRef(SourceId sourceId, [String value = 'book|中文']) =>
    SourceBookRef(sourceId: sourceId, bookId: BookId(value));

SourceChapterRef chapterRef(
  SourceBookRef book, [
  String value = 'chapter/😀',
]) => SourceChapterRef(
  sourceId: book.sourceId,
  bookId: book.bookId,
  chapterId: ChapterId(value),
);

SourceCatalog catalogFor(
  SourceBookRef book, {
  SourceCatalogGrouping? grouping,
}) {
  final first = chapterRef(book, 'first|id');
  final second = chapterRef(book, 'second/编号');
  return SourceCatalog(
    chapters: [
      SourceCatalogEntry(
        chapterRef: first,
        title: 'First',
        sourceOrdinal: 99,
        grouping: grouping,
      ),
      SourceCatalogEntry(chapterRef: second, title: 'Second', sourceOrdinal: 0),
    ],
  );
}

ChapterContent contentFor(SourceChapterRef chapter) => ChapterContent(
  chapterRef: chapter,
  nodes: [
    const TextNode('before'),
    ImageNode(
      assetRef: SourceAssetRef(
        sourceId: chapter.sourceId,
        bookId: chapter.bookId,
        assetId: AssetId('asset|1'),
      ),
    ),
    const TextNode('after'),
  ],
);

final class FakeSource extends GuardedBookSource {
  FakeSource({
    required SourceId id,
    Set<SourceCapability> capabilities = allCapabilities,
    this.catalogShape,
    this.searchNext,
    this.exploreNext,
    List<ExploreDescriptor> exploreDescriptors = const [],
  }) : descriptor = SourceDescriptor(
         sourceId: id,
         displayName: 'Same display name',
         capabilities: capabilities,
         exploreDescriptors: exploreDescriptors,
       );

  @override
  final SourceDescriptor descriptor;
  final SourceCatalog? catalogShape;
  final SourceContinuation? searchNext;
  final SourceContinuation? exploreNext;
  int searchCalls = 0;
  int exploreCalls = 0;
  int bookCalls = 0;
  int catalogCalls = 0;
  int contentCalls = 0;

  SourceBookSummary get summary => SourceBookSummary(
    bookRef: bookRef(descriptor.sourceId),
    title: 'A title',
    author: 'An author',
    tags: const ['tag'],
  );

  @override
  Future<SearchResult> onSearch(
    SearchQuery query,
    SourceOperationContext context,
  ) async {
    searchCalls++;
    return SourcePage(items: [summary], next: searchNext);
  }

  @override
  Future<ExploreResult> onExplore(
    ExploreRequest request,
    SourceOperationContext context,
  ) async {
    exploreCalls++;
    return ExploreResult(
      blocks: [
        ExploreBlock(id: 'block', title: 'Block', books: [summary]),
      ],
      next: exploreNext,
    );
  }

  @override
  Future<SourceBook> onGetBook(
    SourceBookRef book,
    SourceOperationContext context,
  ) async {
    bookCalls++;
    return SourceBook(bookRef: book, title: 'Detail', tags: const ['tag']);
  }

  @override
  Future<SourceCatalog> onGetCatalog(
    SourceBookRef book,
    SourceOperationContext context,
  ) async {
    catalogCalls++;
    return catalogShape ?? catalogFor(book);
  }

  @override
  Future<ChapterContent> onGetChapterContent(
    SourceChapterRef chapter,
    SourceOperationContext context,
  ) async {
    contentCalls++;
    return contentFor(chapter);
  }
}

final class FakeCredential implements SourceCredential {
  const FakeCredential(this.secret);

  final String secret;

  @override
  String toString() => 'FakeCredential(<redacted>)';
}

final class FakeAuthenticator implements SourceAuthenticator {
  FakeAuthenticator(this.sourceId, {this.failure});

  @override
  final SourceId sourceId;
  final SourceFailure? failure;

  @override
  Future<SourceAuthState> signIn(
    SourceCredential credential,
    SourceOperationContext context,
  ) async {
    if (failure != null) throw failure!;
    context.requireActive();
    return const SourceAuthState(SourceAuthStatus.authenticated);
  }

  @override
  Future<SourceAuthState> status(SourceOperationContext context) async =>
      const SourceAuthState(SourceAuthStatus.unauthenticated);

  @override
  Future<SourceAuthState> signOut(SourceOperationContext context) async =>
      const SourceAuthState(SourceAuthStatus.unauthenticated);
}

Matcher sourceFailure(SourceFailureCode code) => throwsA(
  isA<SourceFailure>().having((failure) => failure.code, 'code', code),
);

void main() {
  final sourceA = SourceId('source|A 中文');

  test('descriptor identity is SourceId and capabilities are immutable', () {
    final input = <SourceCapability>{SourceCapability.search};
    final descriptor = SourceDescriptor(
      sourceId: sourceA,
      displayName: 'Display',
      capabilities: input,
    );
    input.add(SourceCapability.catalog);
    expect(descriptor.capabilities, {SourceCapability.search});
    expect(
      () => descriptor.capabilities.add(SourceCapability.catalog),
      throwsUnsupportedError,
    );
    expect(descriptor, descriptor.copyWith(displayName: 'Renamed'));
    expect(descriptor.displayName, 'Display');
  });

  test('fake Sources declare an immutable neutral Explore surface', () {
    final descriptors = [
      ExploreDescriptor(
        id: '首页|α',
        title: 'Home',
        isHome: true,
        filters: [
          SourceFilterDescriptor(
            id: '排序/一',
            label: 'Sort',
            values: ['new', 'old'],
          ),
        ],
      ),
      ExploreDescriptor(
        id: '分类::二',
        title: 'Category',
        filters: [
          SourceFilterDescriptor(id: '标签', label: 'Tag', values: ['A', 'B']),
        ],
      ),
    ];
    final source = FakeSource(id: sourceA, exploreDescriptors: descriptors);
    descriptors.clear();
    expect(source.descriptor.exploreDescriptors, hasLength(2));
    expect(source.descriptor.exploreDescriptors.first.id, '首页|α');
    expect(
      () => source.descriptor.exploreDescriptors.add(
        ExploreDescriptor(id: 'extra', title: 'Extra'),
      ),
      throwsUnsupportedError,
    );
    expect(
      () => source.descriptor.exploreDescriptors.first.filters.clear(),
      throwsUnsupportedError,
    );
    expect(
      () => source.descriptor.exploreDescriptors.first.filters.first.values.add(
        'x',
      ),
      throwsUnsupportedError,
    );
    final BookSource neutralView = source;
    expect(neutralView.descriptor.exploreDescriptors.map((item) => item.id), [
      '首页|α',
      '分类::二',
    ]);
  });

  test('Sources without Explore expose no usable Explore surface', () {
    final source = FakeSource(
      id: sourceA,
      capabilities: const {SourceCapability.search},
    );
    expect(source.descriptor.exploreDescriptors, isEmpty);
    expect(
      () => source.explore(
        ExploreRequest(descriptorId: 'undeclared'),
        operationContext(sourceA, SourceOperation.explore),
      ),
      sourceFailure(SourceFailureCode.unsupportedCapability),
    );
    expect(source.exploreCalls, 0);
    expect(
      () => SourceDescriptor(
        sourceId: sourceA,
        displayName: 'invalid',
        capabilities: const {SourceCapability.search},
        exploreDescriptors: [
          ExploreDescriptor(id: 'declared', title: 'Declared'),
        ],
      ),
      throwsArgumentError,
    );
  });

  test('source models preserve exact opaque source-aware IDs', () {
    final book = bookRef(sourceA, 'wk8-00042/%2F|中文');
    final summary = SourceBookSummary(bookRef: book, title: '  title  ');
    expect(summary.bookRef, book);
    expect(summary.bookRef.bookId.value, 'wk8-00042/%2F|中文');
    expect(summary.title, '  title  ');
    expect(summary.tags, isEmpty);
  });

  test('same BookId remains distinct across SourceIds', () {
    final left = bookRef(SourceId('left'), 'same');
    final right = bookRef(SourceId('right'), 'same');
    expect(left, isNot(right));
    expect({left, right}, hasLength(2));
  });

  test('unsupported search is rejected before delegated work', () async {
    final source = FakeSource(
      id: sourceA,
      capabilities: const {SourceCapability.bookDetail},
    );
    await expectLater(
      source.search(
        SearchQuery(text: 'term'),
        operationContext(sourceA, SourceOperation.search),
      ),
      sourceFailure(SourceFailureCode.unsupportedCapability),
    );
    expect(source.searchCalls, 0);
  });

  test('unsupported explore and filters are capability-gated', () async {
    final noExplore = FakeSource(
      id: sourceA,
      capabilities: const {SourceCapability.search},
    );
    await expectLater(
      noExplore.explore(
        ExploreRequest(descriptorId: 'home'),
        operationContext(sourceA, SourceOperation.explore),
      ),
      sourceFailure(SourceFailureCode.unsupportedCapability),
    );
    expect(noExplore.exploreCalls, 0);

    final noFilters = FakeSource(
      id: sourceA,
      capabilities: const {SourceCapability.search},
    );
    await expectLater(
      noFilters.search(
        SearchQuery(text: 'term', filters: const {'sort': 'new'}),
        operationContext(sourceA, SourceOperation.search),
      ),
      sourceFailure(SourceFailureCode.unsupportedCapability),
    );
    expect(noFilters.searchCalls, 0);
  });

  test(
    'wrong-source book and chapter refs are rejected before delegation',
    () async {
      final source = FakeSource(id: sourceA);
      final wrongSource = SourceId('source|B');
      await expectLater(
        source.getBook(
          bookRef(wrongSource),
          operationContext(sourceA, SourceOperation.bookDetail),
        ),
        sourceFailure(SourceFailureCode.invalidRequest),
      );
      await expectLater(
        source.getChapterContent(
          chapterRef(bookRef(wrongSource)),
          operationContext(sourceA, SourceOperation.chapterContent),
        ),
        sourceFailure(SourceFailureCode.invalidRequest),
      );
      expect(source.bookCalls, 0);
      expect(source.contentCalls, 0);
    },
  );

  test('wrong operation or context source is rejected before work', () async {
    final source = FakeSource(id: sourceA);
    await expectLater(
      source.search(
        SearchQuery(text: 'term'),
        operationContext(sourceA, SourceOperation.explore),
      ),
      sourceFailure(SourceFailureCode.invalidRequest),
    );
    await expectLater(
      source.search(
        SearchQuery(text: 'term'),
        operationContext(SourceId('other'), SourceOperation.search),
      ),
      sourceFailure(SourceFailureCode.invalidRequest),
    );
    expect(source.searchCalls, 0);
  });

  test('search results use source-aware refs and immutable pages', () async {
    final source = FakeSource(id: sourceA);
    final result = await source.search(
      SearchQuery(text: 'term'),
      operationContext(sourceA, SourceOperation.search),
    );
    expect(result.items.single.bookRef.sourceId, sourceA);
    expect(result.items.single.title, 'A title');
    expect(() => result.items.add(source.summary), throwsUnsupportedError);
  });

  test('explore descriptors and selections are neutral and immutable', () {
    final values = <String>['new', 'old'];
    final filter = SourceFilterDescriptor(
      id: 'sort',
      label: 'Sort',
      values: values,
    );
    final descriptor = ExploreDescriptor(
      id: 'home',
      title: 'Home',
      isHome: true,
      filters: [filter],
    );
    values.add('changed');
    expect(descriptor.filters.single.values, ['new', 'old']);
    expect(() => descriptor.filters.add(filter), throwsUnsupportedError);
    final selections = <String, String>{'sort': 'new'};
    final request = ExploreRequest(
      descriptorId: descriptor.id,
      selections: selections,
    );
    selections['sort'] = 'old';
    expect(request.selections['sort'], 'new');
  });

  test(
    'flat catalog has one ordered sequence and no fabricated volume',
    () async {
      final source = FakeSource(id: sourceA);
      final result = await source.getCatalog(
        bookRef(sourceA),
        operationContext(sourceA, SourceOperation.catalog),
      );
      expect(result.chapters, hasLength(2));
      expect(result.chapters.map((entry) => entry.chapterRef.chapterId.value), [
        'first|id',
        'second/编号',
      ]);
      expect(result.chapters.every((entry) => entry.grouping == null), isTrue);
    },
  );

  test(
    'stable volume catalog carries a real source-aware volume ref',
    () async {
      final book = bookRef(sourceA);
      final volume = SourceVolumeRef(
        sourceId: sourceA,
        bookId: book.bookId,
        volumeId: VolumeId('volume-A'),
      );
      final source = FakeSource(
        id: sourceA,
        catalogShape: catalogFor(
          book,
          grouping: SourceCatalogGrouping(label: 'Volume A', volumeRef: volume),
        ),
      );
      final result = await source.getCatalog(
        book,
        operationContext(sourceA, SourceOperation.catalog),
      );
      expect(result.chapters.first.grouping?.volumeRef, volume);
    },
  );

  test(
    'presentation grouping without stable VolumeId remains metadata only',
    () async {
      final book = bookRef(sourceA);
      final source = FakeSource(
        id: sourceA,
        catalogShape: catalogFor(
          book,
          grouping: SourceCatalogGrouping(label: 'Volume label only'),
        ),
      );
      final result = await source.getCatalog(
        book,
        operationContext(sourceA, SourceOperation.catalog),
      );
      expect(result.chapters.first.grouping?.label, 'Volume label only');
      expect(result.chapters.first.grouping?.volumeRef, isNull);
    },
  );

  test('chapter ordinal and list order never become ChapterId', () async {
    final source = FakeSource(id: sourceA);
    final result = await source.getCatalog(
      bookRef(sourceA),
      operationContext(sourceA, SourceOperation.catalog),
    );
    expect(result.chapters.first.sourceOrdinal, 99);
    expect(result.chapters.last.sourceOrdinal, 0);
    expect(result.chapters.first.chapterRef.chapterId.value, 'first|id');
    expect(result.chapters.last.chapterRef.chapterId.value, 'second/编号');
  });

  test('chapter content reuses the ordered F2 ChapterContent model', () async {
    final source = FakeSource(id: sourceA);
    final chapter = chapterRef(bookRef(sourceA));
    final result = await source.getChapterContent(
      chapter,
      operationContext(sourceA, SourceOperation.chapterContent),
    );
    expect(result, contentFor(chapter));
    expect(result.nodes, hasLength(3));
    expect(result.nodes[0], const TextNode('before'));
    expect(result.nodes[1], isA<ImageNode>());
    expect(result.nodes[2], const TextNode('after'));
  });

  test(
    'same search request may reuse its structurally bound continuation',
    () async {
      final continuation = SourceContinuation.forSearch(
        sourceId: sourceA,
        queryText: 'term',
        filters: const {'genre': 'fantasy'},
        sessionGeneration: 4,
        opaqueValue: 'opaque-provider-token',
      );
      final source = FakeSource(id: sourceA, searchNext: continuation);
      final result = await source.search(
        SearchQuery(
          text: 'term',
          filters: const {'genre': 'fantasy'},
          continuation: continuation,
        ),
        operationContext(sourceA, SourceOperation.search, generation: 4),
      );
      expect(result.next, continuation);
      expect(result.next!.opaqueValue, 'opaque-provider-token');
      expect(result.next.toString(), isNot(contains('opaque-provider-token')));
      final reordered = SourceContinuation.forSearch(
        sourceId: sourceA,
        queryText: 'term',
        filters: const {'other': 'value', 'genre': 'fantasy'},
        sessionGeneration: 4,
        opaqueValue: 'opaque-provider-token',
      );
      reordered.validateForSearch(
        sourceId: sourceA,
        queryText: 'term',
        filters: const {'genre': 'fantasy', 'other': 'value'},
        sessionGeneration: 4,
      );
    },
  );

  test('changed search text rejects an old continuation', () async {
    final continuation = SourceContinuation.forSearch(
      sourceId: sourceA,
      queryText: 'cat',
      sessionGeneration: 0,
      opaqueValue: 'opaque',
    );
    final source = FakeSource(id: sourceA, searchNext: continuation);
    await expectLater(
      source.search(
        SearchQuery(text: 'dog', continuation: continuation),
        operationContext(sourceA, SourceOperation.search),
      ),
      sourceFailure(SourceFailureCode.invalidRequest),
    );
    expect(source.searchCalls, 0);
  });

  test('changed search filters reject an old continuation', () async {
    final continuation = SourceContinuation.forSearch(
      sourceId: sourceA,
      queryText: 'cat',
      filters: const {'genre': 'fantasy'},
      sessionGeneration: 0,
      opaqueValue: 'opaque',
    );
    final source = FakeSource(id: sourceA, searchNext: continuation);
    await expectLater(
      source.search(
        SearchQuery(
          text: 'cat',
          filters: const {'genre': 'mystery'},
          continuation: continuation,
        ),
        operationContext(sourceA, SourceOperation.search),
      ),
      sourceFailure(SourceFailureCode.invalidRequest),
    );
    expect(source.searchCalls, 0);
  });

  test('changed explore descriptor rejects an old continuation', () async {
    final continuation = SourceContinuation.forExplore(
      sourceId: sourceA,
      descriptorId: 'home|one',
      sessionGeneration: 0,
      opaqueValue: 'opaque',
    );
    final source = FakeSource(id: sourceA, exploreNext: continuation);
    await expectLater(
      source.explore(
        ExploreRequest(
          descriptorId: 'category|two',
          continuation: continuation,
        ),
        operationContext(sourceA, SourceOperation.explore),
      ),
      sourceFailure(SourceFailureCode.invalidRequest),
    );
    expect(source.exploreCalls, 0);
  });

  test('changed explore selections reject an old continuation', () async {
    final continuation = SourceContinuation.forExplore(
      sourceId: sourceA,
      descriptorId: 'home|one',
      selections: const {'sort': 'new'},
      sessionGeneration: 0,
      opaqueValue: 'opaque',
    );
    final source = FakeSource(id: sourceA, exploreNext: continuation);
    await expectLater(
      source.explore(
        ExploreRequest(
          descriptorId: 'home|one',
          selections: const {'sort': 'old'},
          continuation: continuation,
        ),
        operationContext(sourceA, SourceOperation.explore),
      ),
      sourceFailure(SourceFailureCode.invalidRequest),
    );
    expect(source.exploreCalls, 0);
  });

  test(
    'continuation rejects cross-source, operation and session reuse',
    () async {
      final continuation = SourceContinuation.forSearch(
        sourceId: sourceA,
        queryText: 'term',
        sessionGeneration: 4,
        opaqueValue: 'opaque-provider-token',
      );
      final source = FakeSource(id: sourceA, searchNext: continuation);

      for (final context in [
        operationContext(
          SourceId('other'),
          SourceOperation.search,
          generation: 4,
        ),
        operationContext(sourceA, SourceOperation.explore, generation: 4),
        operationContext(sourceA, SourceOperation.search, generation: 5),
      ]) {
        await expectLater(
          source.search(
            SearchQuery(text: 'term', continuation: continuation),
            context,
          ),
          sourceFailure(SourceFailureCode.invalidRequest),
        );
      }
    },
  );

  test('failed and cancelled calls do not advance a continuation', () async {
    final source = FakeSource(id: sourceA);
    final token = SourceCancellation()..cancel();
    await expectLater(
      source.search(
        SearchQuery(text: 'term'),
        operationContext(sourceA, SourceOperation.search, cancellation: token),
      ),
      sourceFailure(SourceFailureCode.cancelled),
    );
    expect(source.searchCalls, 0);
  });

  test('cancellation token notifies listeners and is idempotent', () {
    final token = SourceCancellation();
    var notifications = 0;
    final remove = token.addListener(() => notifications++);
    token.cancel();
    token.cancel();
    remove();
    expect(token.isCancelled, isTrue);
    expect(notifications, 1);
    expect(
      () => token.throwIfCancelled(),
      sourceFailure(SourceFailureCode.cancelled),
    );
  });

  test('typed failures expose only allowlisted immutable diagnostics', () {
    final failure = SourceFailure(
      code: SourceFailureCode.rateLimit,
      retryable: true,
      retryAfter: const Duration(seconds: 3),
      diagnostics: SourceFailureDiagnostics(
        operation: SourceOperation.search,
        statusCode: 429,
        attempt: 1,
        elapsedMilliseconds: 120,
        fromCache: false,
      ),
    );
    expect(failure.codeName, 'rateLimit');
    expect(failure.retryable, isTrue);
    expect(failure.retryAfter, const Duration(seconds: 3));
    expect(failure.toString(), 'SourceFailure(rateLimit)');
    expect(failure.diagnostics.statusCode, 429);
    expect(failure.diagnostics.asMap, {
      'operation': 'search',
      'statusCode': 429,
      'attempt': 1,
      'elapsedMilliseconds': 120,
      'fromCache': false,
    });
    expect(
      () => failure.diagnostics.asMap['statusCode'] = 500,
      throwsUnsupportedError,
    );
    for (final name in [#password, #rawHtml, #serverMessage]) {
      expect(
        () => Function.apply(SourceFailureDiagnostics.new, const [], {
          name: 'secret',
        }),
        throwsA(isA<NoSuchMethodError>()),
      );
    }
    expect(
      () => SourceFailureDiagnostics(statusCode: 600),
      throwsArgumentError,
    );
    expect(failure.toString(), isNot(contains('429')));
    expect(failure.toString(), isNot(contains('secret')));
    expect(failure.toString(), isNot(contains('<html>')));
  });

  test(
    'authentication is a separate contract and unsupported auth is distinct',
    () async {
      final source = FakeSource(
        id: sourceA,
        capabilities: const {SourceCapability.bookDetail},
      );
      final registry = SourceRegistry()..register(source);
      expect(
        () => registry.resolveAuthenticator(sourceA),
        sourceFailure(SourceFailureCode.unsupportedCapability),
      );

      final authSource = FakeSource(
        id: SourceId('auth-source'),
        capabilities: const {SourceCapability.authentication},
      );
      final authFailure = SourceFailure(code: SourceFailureCode.authentication);
      final auth = FakeAuthenticator(
        authSource.descriptor.sourceId,
        failure: authFailure,
      );
      final authRegistry = SourceRegistry()
        ..register(authSource, authenticator: auth);
      final resolved = authRegistry.resolveAuthenticator(
        authSource.descriptor.sourceId,
      );
      await expectLater(
        resolved.signIn(
          const FakeCredential('secret-value'),
          operationContext(
            authSource.descriptor.sourceId,
            SourceOperation.authentication,
          ),
        ),
        sourceFailure(SourceFailureCode.authentication),
      );
      expect(
        const FakeCredential('secret-value').toString(),
        isNot(contains('secret-value')),
      );
    },
  );

  test('registry rejects duplicate IDs but allows duplicate display names', () {
    final first = FakeSource(id: sourceA);
    final second = FakeSource(id: SourceId('source|B'));
    final registry = SourceRegistry()
      ..register(first)
      ..register(second);
    expect(registry.entries, hasLength(2));
    expect(registry.resolve(sourceA), same(first));
    expect(
      () => registry.register(FakeSource(id: sourceA)),
      sourceFailure(SourceFailureCode.invalidRequest),
    );
    expect(first.descriptor.displayName, second.descriptor.displayName);
  });

  test('registry identity is unaffected by display-name changes', () {
    final source = FakeSource(id: sourceA);
    final registry = SourceRegistry()..register(source);
    final renamed = source.descriptor.copyWith(displayName: 'Renamed');
    expect(renamed.sourceId, sourceA);
    expect(renamed, source.descriptor);
    expect(registry.resolve(renamed.sourceId), same(source));
  });

  test('unknown and unavailable sources return typed sourceUnavailable without fallback', () {
    final source = FakeSource(id: sourceA);
    final unavailableId = SourceId('unavailable');
    final registry = SourceRegistry()
      ..register(source)
      ..registerUnavailable(
        SourceDescriptor(
          sourceId: unavailableId,
          displayName: 'Unavailable',
          capabilities: const {SourceCapability.search},
        ),
        availability: SourceAvailability.disabled,
      );
    expect(
      () => registry.resolve(SourceId('missing')),
      sourceFailure(SourceFailureCode.sourceUnavailable),
    );
    expect(
      () => registry.resolve(unavailableId),
      sourceFailure(SourceFailureCode.sourceUnavailable),
    );
    expect(registry.entry(unavailableId).descriptor.sourceId, unavailableId);
    expect(
      () =>
          registry.setAvailability(unavailableId, SourceAvailability.available),
      sourceFailure(SourceFailureCode.invalidRequest),
    );
  });

  test(
    'registry preserves runtime availability state without deleting identity',
    () {
      final source = FakeSource(id: sourceA);
      final registry = SourceRegistry()..register(source);
      registry.setAvailability(sourceA, SourceAvailability.unavailable);
      expect(registry.entry(sourceA).descriptor.sourceId, sourceA);
      expect(
        () => registry.resolve(sourceA),
        sourceFailure(SourceFailureCode.sourceUnavailable),
      );
      registry.setAvailability(sourceA, SourceAvailability.available);
      expect(registry.resolve(sourceA), same(source));
    },
  );

  test(
    'public source models do not mix local library, progress or download state',
    () {
      final book = SourceBookSummary(bookRef: bookRef(sourceA), title: 'title');
      final detail = SourceBook(bookRef: book.bookRef, title: book.title);
      expect(book, isNot(isA<Map>()));
      expect(detail, isNot(isA<Map>()));
      expect(detail.description, isNull);
      expect(detail.coverAssetRef, isNull);
      expect(detail.tags, isEmpty);
    },
  );
}
