import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_reader/src/domain/content/chapter_content.dart';
import 'package:light_novel_reader/src/domain/identity/opaque_ids.dart';
import 'package:light_novel_reader/src/domain/identity/source_refs.dart';
import 'package:light_novel_reader/src/source/source.dart';
import 'package:light_novel_reader/src/sources/wenku8/wenku8.dart';

SourceOperationContext _context(SourceId sourceId, SourceOperation operation) =>
    SourceOperationContext(
      sourceId: sourceId,
      operation: operation,
      sessionGeneration: 0,
      cancellation: SourceCancellation(),
    );

Future<ChapterContent> _checkNeutralCatalogAndContent(
  BookSource source,
  SourceBookRef book,
) async {
  final catalog = await source.getCatalog(
    book,
    _context(book.sourceId, SourceOperation.catalog),
  );
  expect(catalog.chapters, isNotEmpty);
  for (final entry in catalog.chapters) {
    expect(entry.chapterRef.sourceId, book.sourceId);
    expect(entry.chapterRef.bookId, book.bookId);
  }
  final chapter = catalog.chapters.first.chapterRef;
  final content = await source.getChapterContent(
    chapter,
    _context(book.sourceId, SourceOperation.chapterContent),
  );
  expect(content.chapterRef, chapter);
  for (final node in content.nodes.whereType<ImageNode>()) {
    expect(node.assetRef.sourceId, book.sourceId);
    expect(node.assetRef.bookId, book.bookId);
  }
  return content;
}

void main() {
  test(
    'two fake Sources keep identical opaque book/chapter IDs isolated',
    () async {
      final a = _NeutralFakeSource(SourceId('fake|源😀'));
      final b = _NeutralFakeSource(SourceId('fake/other'));
      final registry = SourceRegistry()
        ..register(a)
        ..register(b);
      final bookA = SourceBookRef(
        sourceId: a.descriptor.sourceId,
        bookId: BookId('same|书'),
      );
      final bookB = SourceBookRef(
        sourceId: b.descriptor.sourceId,
        bookId: BookId('same|书'),
      );
      final contentA = await _checkNeutralCatalogAndContent(
        registry.resolve(bookA.sourceId),
        bookA,
      );
      final contentB = await _checkNeutralCatalogAndContent(
        registry.resolve(bookB.sourceId),
        bookB,
      );
      expect(contentA.nodes, hasLength(1));
      expect(contentA.nodes.single, isA<ImageNode>());
      expect(contentB.nodes, hasLength(1));
      expect(contentB.nodes.single, isA<ImageNode>());
      expect(contentA.chapterRef.chapterId, contentB.chapterRef.chapterId);
      expect(contentA.chapterRef, isNot(contentB.chapterRef));
      final catalog = await a.getCatalog(
        bookA,
        _context(bookA.sourceId, SourceOperation.catalog),
      );
      expect(catalog.chapters.first.grouping?.label, '卷/展示');
      expect(catalog.chapters.first.grouping?.volumeRef, null);
      expect(catalog.chapters.first.sourceOrdinal, 99);
      expect(catalog.chapters.last.sourceOrdinal, 0);
      expect(
        () => registry.resolveAuthenticator(bookA.sourceId),
        throwsA(
          isA<SourceFailure>().having(
            (failure) => failure.code,
            'code',
            SourceFailureCode.unsupportedCapability,
          ),
        ),
      );
      final firstPage = await a.search(
        SearchQuery(text: 'query'),
        _context(bookA.sourceId, SourceOperation.search),
      );
      expect(firstPage.next, isNotNull);
      final secondPage = await a.search(
        SearchQuery(text: 'query', continuation: firstPage.next),
        _context(bookA.sourceId, SourceOperation.search),
      );
      expect(secondPage.next, null);
    },
  );

  test(
    'fixture-backed Wenku8 satisfies the same neutral content contract',
    () async {
      final sessions = SourceSessionManager();
      final source = Wenku8Source(
        sessions: sessions,
        transport: _FixtureTransport(),
      );
      final registry = SourceRegistry()..register(source);
      final book = SourceBookRef(
        sourceId: source.descriptor.sourceId,
        bookId: BookId('wk8-201'),
      );
      final content = await _checkNeutralCatalogAndContent(
        registry.resolve(book.sourceId),
        book,
      );
      expect(content.nodes, [
        const TextNode('First'),
        const TextNode('Second'),
        isA<ImageNode>(),
        const TextNode('Third'),
        isA<ImageNode>(),
        const TextNode('Fourth'),
      ]);
    },
  );
}

final class _NeutralFakeSource extends GuardedBookSource {
  _NeutralFakeSource(SourceId id)
    : descriptor = SourceDescriptor(
        sourceId: id,
        displayName: 'Neutral fake',
        capabilities: const {
          SourceCapability.search,
          SourceCapability.bookDetail,
          SourceCapability.catalog,
          SourceCapability.chapterContent,
        },
      );

  @override
  final SourceDescriptor descriptor;

  SourceBookRef _book() =>
      SourceBookRef(sourceId: descriptor.sourceId, bookId: BookId('same|书'));

  @override
  Future<SearchResult> onSearch(
    SearchQuery query,
    SourceOperationContext context,
  ) async => SourcePage(
    items: [SourceBookSummary(bookRef: _book(), title: 'Same title')],
    next: query.continuation == null
        ? SourceContinuation.forSearch(
            sourceId: descriptor.sourceId,
            queryText: query.text,
            sessionGeneration: context.sessionGeneration,
            opaqueValue: 'next|页',
          )
        : null,
  );

  @override
  Future<ExploreResult> onExplore(
    ExploreRequest request,
    SourceOperationContext context,
  ) async => ExploreResult(blocks: const []);

  @override
  Future<SourceBook> onGetBook(
    SourceBookRef book,
    SourceOperationContext context,
  ) async => SourceBook(bookRef: book, title: 'Same title');

  @override
  Future<SourceCatalog> onGetCatalog(
    SourceBookRef book,
    SourceOperationContext context,
  ) async => SourceCatalog(
    chapters: [
      SourceCatalogEntry(
        chapterRef: SourceChapterRef(
          sourceId: book.sourceId,
          bookId: book.bookId,
          chapterId: ChapterId('chapter|😀'),
        ),
        title: 'First',
        sourceOrdinal: 99,
        grouping: SourceCatalogGrouping(label: '卷/展示'),
      ),
      SourceCatalogEntry(
        chapterRef: SourceChapterRef(
          sourceId: book.sourceId,
          bookId: book.bookId,
          chapterId: ChapterId('chapter/二'),
        ),
        title: 'Second',
        sourceOrdinal: 0,
      ),
    ],
  );

  @override
  Future<ChapterContent> onGetChapterContent(
    SourceChapterRef chapter,
    SourceOperationContext context,
  ) async => ChapterContent(
    chapterRef: chapter,
    nodes: [
      ImageNode(
        assetRef: SourceAssetRef(
          sourceId: chapter.sourceId,
          bookId: chapter.bookId,
          assetId: AssetId('image|同一'),
        ),
      ),
    ],
  );
}

final class _FixtureTransport implements SourceTransport {
  @override
  Future<SourceHttpResponse> send(SourceHttpRequest request) async {
    final path = request.operation == SourceOperation.catalog
        ? 'test/source/wenku8/fixtures/legacy_catalog_table.html'
        : 'test/fixtures/sources/wenku8/raw/content/multi-interleaved.html';
    return SourceHttpResponse(
      statusCode: 200,
      headers: SourceHttpHeaders.fromSingleValue({
        'content-type': 'text/html; charset=utf-8',
      }),
      bodyBytes: File(path).readAsBytesSync(),
      finalUri: request.uri,
    );
  }
}
