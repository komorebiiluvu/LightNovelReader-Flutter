import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_reader/src/domain/content/chapter_content.dart';
import 'package:light_novel_reader/src/domain/identity/opaque_ids.dart';
import 'package:light_novel_reader/src/domain/identity/source_refs.dart';
import 'package:light_novel_reader/src/source/source.dart';
import 'package:light_novel_reader/src/sources/wenku8/wenku8.dart';

void main() {
  final sourceId = SourceId('builtin.wenku8');
  final manifest = jsonDecode(
    File('test/fixtures/sources/wenku8/manifest.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final entries = {
    for (final entry in manifest['entries'] as List<dynamic>)
      (entry as Map<String, dynamic>)['id'] as String: entry,
  };

  SourceHttpResponse fixture(
    String id,
    SourceHttpRequest request, {
    String? pageMetadata,
  }) {
    final entry = entries[id]!;
    final bytes = File('test/fixtures/sources/wenku8/${entry['fixture']}')
        .readAsBytesSync();
    return SourceHttpResponse(
      statusCode: 200,
      headers: SourceHttpHeaders.fromSingleValue({
        'content-type': 'text/html; charset=${entry['encoding']}',
      }),
      bodyBytes: [
        ...bytes,
        if (pageMetadata != null)
          ...ascii.encode('<div id="pagelink"><em>$pageMetadata</em></div>'),
      ],
      finalUri: request.uri,
    );
  }

  SourceOperationContext context(
    SourceSessionManager sessions,
    SourceOperation operation, {
    SourceCancellation? cancellation,
  }) => SourceOperationContext(
    sourceId: sourceId,
    operation: operation,
    sessionGeneration: sessions.snapshot(sourceId).generation,
    cancellation: cancellation ?? SourceCancellation(),
  );

  test(
    'search composes request, bytes, parser, F2 refs and registry',
    () async {
      final sessions = SourceSessionManager();
      final transport = _ScriptedTransport(
        (request) async =>
            fixture('search-normal-multi', request, pageMetadata: '1 / 1'),
      );
      final source = Wenku8Source(transport: transport, sessions: sessions);
      final registry = SourceRegistry();
      registry.register(source);
      final resolved = registry.resolve(sourceId);
      final result = await resolved.search(
        SearchQuery(text: '中文'),
        context(sessions, SourceOperation.search),
      );
      expect(result.items.length, 2);
      expect(result.items.first.bookRef.bookId, BookId('wk8-101'));
      expect(result.items.last.bookRef.bookId, BookId('wk8-102'));
      expect(result.next, isNull);
      expect(transport.requests.single.uri.host, 'www.wenku8.net');
      expect(
        transport.requests.single.uri.query,
        contains('searchkey=%D6%D0%CE%C4'),
      );
      expect(transport.requests.single.sessionBinding?.generation, 0);
      expect(transport.requests.single.headers.contains('cookie'), false);
    },
  );

  test('pagination binds request fields and rejects stale generations', () async {
    final sessions = SourceSessionManager();
    final transport = _ScriptedTransport((request) async {
      // CP936 percent bytes are deliberately not valid UTF-8 query parameters.
      final page = RegExp(r'(?:^|&)page=(\d+)')
          .firstMatch(request.uri.query)!
          .group(1)!;
      return SourceHttpResponse(
        statusCode: 200,
        headers: SourceHttpHeaders.fromSingleValue({
          'content-type': 'text/html; charset=utf-8',
        }),
        bodyBytes: utf8.encode(
          '<a href="/book/$page">第$page章</a>'
          '<div id="pagelink"><em>$page / 2</em></div>',
        ),
        finalUri: request.uri,
      );
    });
    final source = Wenku8Source(transport: transport, sessions: sessions);
    final first = await source.search(
      SearchQuery(text: '甲'),
      context(sessions, SourceOperation.search),
    );
    expect(first.next, isNotNull);
    final second = await source.search(
      SearchQuery(text: '甲', continuation: first.next),
      context(sessions, SourceOperation.search),
    );
    expect(second.items.single.bookRef.bookId, BookId('wk8-2'));
    expect(second.next, isNull);
    final beforeInvalid = transport.requests.length;
    await expectLater(
      source.search(
        SearchQuery(text: '不同查询', continuation: first.next),
        context(sessions, SourceOperation.search),
      ),
      throwsA(
        isA<SourceFailure>().having(
          (failure) => failure.code,
          'code',
          SourceFailureCode.invalidRequest,
        ),
      ),
    );
    expect(transport.requests.length, beforeInvalid);
    sessions.logout(sourceId);
    await expectLater(
      source.search(
        SearchQuery(text: '甲', continuation: first.next),
        context(sessions, SourceOperation.search),
      ),
      throwsA(isA<SourceFailure>()),
    );
    expect(transport.requests.length, beforeInvalid);
  });

  test(
    'Explore home and category normalize blocks without UI or Core branches',
    () async {
      final sessions = SourceSessionManager();
      final transport = _ScriptedTransport(
        (request) async => fixture(
          request.uri.path == '/index.php'
              ? 'explore-home'
              : 'explore-category',
          request,
          pageMetadata: request.uri.path == '/index.php' ? null : '1 / 1',
        ),
      );
      final source = Wenku8Source(transport: transport, sessions: sessions);
      final home = await source.explore(
        ExploreRequest(descriptorId: 'home'),
        context(sessions, SourceOperation.explore),
      );
      expect(home.blocks.single.books.single.bookRef.bookId, BookId('wk8-11'));
      expect(home.next, isNull);
      final category = await source.explore(
        ExploreRequest(descriptorId: 'all'),
        context(sessions, SourceOperation.explore),
      );
      expect(
        category.blocks.single.books.single.bookRef.bookId,
        BookId('wk8-12'),
      );
      expect(
        transport.requests.last.uri.path,
        '/modules/article/articlelist.php',
      );
      final before = transport.requests.length;
      await expectLater(
        source.explore(
          ExploreRequest(descriptorId: 'unknown'),
          context(sessions, SourceOperation.explore),
        ),
        throwsA(isA<SourceFailure>()),
      );
      expect(transport.requests.length, before);
    },
  );

  test('missing pagination evidence cannot silently mean exhaustion', () async {
    final sessions = SourceSessionManager();
    final source = Wenku8Source(
      sessions: sessions,
      transport: _ScriptedTransport(
        (request) async => fixture('search-normal-multi', request),
      ),
    );
    await expectLater(
      source.search(
        SearchQuery(text: '甲'),
        context(sessions, SourceOperation.search),
      ),
      throwsA(
        isA<SourceFailure>().having(
          (failure) => failure.code,
          'code',
          SourceFailureCode.parse,
        ),
      ),
    );
  });

  test('tag Explore uses explicit selection and CP936 query bytes', () async {
    final sessions = SourceSessionManager();
    final transport = _ScriptedTransport(
      (request) async =>
          fixture('explore-tag-filter', request, pageMetadata: '1 / 1'),
    );
    final source = Wenku8Source(transport: transport, sessions: sessions);
    final result = await source.explore(
      ExploreRequest(descriptorId: 'tag', selections: {'tag': '幻想'}),
      context(sessions, SourceOperation.explore),
    );
    expect(result.blocks.single.books.single.bookRef.bookId, BookId('wk8-13'));
    expect(result.blocks.single.title, '幻想');
    expect(transport.requests.single.uri.path, '/modules/article/tags.php');
    expect(transport.requests.single.uri.query, contains('t='));
    expect(result.next, isNull);
  });

  test('unencodable query fails as a Source failure before I/O', () async {
    final sessions = SourceSessionManager();
    final transport = _ScriptedTransport(
      (request) async => fixture('search-normal-multi', request),
    );
    final source = Wenku8Source(transport: transport, sessions: sessions);
    await expectLater(
      source.search(
        SearchQuery(text: '😀'),
        context(sessions, SourceOperation.search),
      ),
      throwsA(
        isA<SourceFailure>().having(
          (failure) => failure.code,
          'code',
          SourceFailureCode.invalidRequest,
        ),
      ),
    );
    expect(transport.requests, isEmpty);
  });

  test('runtime accepts frozen Legacy .htm book-card structure', () async {
    final sessions = SourceSessionManager();
    final transport = _ScriptedTransport((request) async {
      final raw = File('test/source/wenku8/fixtures/legacy_book_card.html')
          .readAsBytesSync();
      return SourceHttpResponse(
        statusCode: 200,
        headers: SourceHttpHeaders.fromSingleValue({
          'content-type': 'text/html; charset=utf-8',
        }),
        bodyBytes: [
          ...raw,
          ...ascii.encode('<div id="pagelink"><em>1 / 1</em></div>'),
        ],
        finalUri: request.uri,
      );
    });
    final source = Wenku8Source(transport: transport, sessions: sessions);
    final result = await source.search(
      SearchQuery(text: '书名'),
      context(sessions, SourceOperation.search),
    );
    expect(result.items.single.bookRef.bookId, BookId('wk8-201'));
    expect(result.items.single.title, '书名');
  });

  test('runtime accepts frozen Legacy detail table structure', () async {
    final sessions = SourceSessionManager();
    final transport = _ScriptedTransport((request) async => SourceHttpResponse(
          statusCode: 200,
          headers: SourceHttpHeaders.fromSingleValue({
            'content-type': 'text/html; charset=utf-8',
          }),
          bodyBytes: File(
            'test/source/wenku8/fixtures/legacy_detail_table.html',
          ).readAsBytesSync(),
          finalUri: request.uri,
        ));
    final source = Wenku8Source(transport: transport, sessions: sessions);
    final detail = await source.getBook(
      SourceBookRef(sourceId: sourceId, bookId: BookId('wk8-201')),
      context(sessions, SourceOperation.bookDetail),
    );
    expect(detail.title, '书名');
    expect(detail.author, '作者甲');
    expect(detail.description, '简介正文');
    expect(source.assets.locatorFor(detail.coverAssetRef!),
        '/image/cover.jpg');
  });

  test('runtime preserves frozen Legacy home block ordering', () async {
    final sessions = SourceSessionManager();
    final transport = _ScriptedTransport((request) async => SourceHttpResponse(
          statusCode: 200,
          headers: SourceHttpHeaders.fromSingleValue({
            'content-type': 'text/html; charset=utf-8',
          }),
          bodyBytes: File(
            'test/source/wenku8/fixtures/legacy_home_blocks.html',
          ).readAsBytesSync(),
          finalUri: request.uri,
        ));
    final source = Wenku8Source(transport: transport, sessions: sessions);
    final page = await source.explore(
      ExploreRequest(descriptorId: 'home'),
      context(sessions, SourceOperation.explore),
    );
    expect(page.blocks.map((block) => block.id), ['home-0', 'home-1']);
    expect(page.blocks.map((block) => block.title), ['热门', '新书']);
    expect(page.blocks.first.books.single.bookRef.bookId, BookId('wk8-201'));
    expect(page.blocks.last.books.single.bookRef.bookId, BookId('wk8-202'));
    expect(page.next, isNull);
  });

  test('detail, table catalog and ordered content retain scoped IDs', () async {
    final sessions = SourceSessionManager();
    final transport = _ScriptedTransport((request) async {
      if (request.operation == SourceOperation.bookDetail) {
        return fixture('detail-normal', request);
      }
      if (request.operation == SourceOperation.catalog) {
        return SourceHttpResponse(
          statusCode: 200,
          headers: SourceHttpHeaders.fromSingleValue({
            'content-type': 'text/html; charset=utf-8',
          }),
          bodyBytes: File(
            'test/source/wenku8/fixtures/legacy_catalog_table.html',
          ).readAsBytesSync(),
          finalUri: request.uri,
        );
      }
      return fixture('content-interleaved', request);
    });
    final source = Wenku8Source(transport: transport, sessions: sessions);
    final book = SourceBookRef(sourceId: sourceId, bookId: BookId('wk8-201'));
    final detail = await source.getBook(
      book,
      context(sessions, SourceOperation.bookDetail),
    );
    expect(detail.bookRef, book);
    expect(detail.coverAssetRef, isNotNull);
    expect(source.assets.locatorFor(detail.coverAssetRef!), '/cover.jpg');
    final catalog = await source.getCatalog(
      book,
      context(sessions, SourceOperation.catalog),
    );
    expect(catalog.chapters.map((entry) => entry.chapterRef.chapterId.value), [
      '1',
      '2',
      '3',
    ]);
    expect(
      catalog.chapters.first.grouping?.volumeRef?.volumeId,
      VolumeId('v1'),
    );
    expect(catalog.chapters.last.grouping?.volumeRef?.volumeId, VolumeId('v2'));
    expect(transport.requests[1].uri.path, '/novel/0/201/index.htm');
    final chapter = catalog.chapters.first.chapterRef;
    final content = await source.getChapterContent(
      chapter,
      context(sessions, SourceOperation.chapterContent),
    );
    expect(content.chapterRef, chapter);
    expect(content.nodes.length, 3);
    expect(content.nodes[0], const TextNode('前'));
    final image = content.nodes[1] as ImageNode;
    expect(source.assets.locatorFor(image.assetRef), '/a.jpg');
    expect(image.assetRef.assetId.value, isNot(contains('/a.jpg')));
    expect(content.nodes[2], const TextNode('后'));
    expect(transport.requests.last.uri.path, '/novel/0/201/1.htm');
  });

  test(
    'missing provider chapter key fails atomically before normalization',
    () async {
      final sessions = SourceSessionManager();
      final transport = _ScriptedTransport(
        (request) async => fixture('catalog-missing-chapter-id', request),
      );
      final source = Wenku8Source(transport: transport, sessions: sessions);
      await expectLater(
        source.getCatalog(
          SourceBookRef(sourceId: sourceId, bookId: BookId('wk8-205')),
          context(sessions, SourceOperation.catalog),
        ),
        throwsA(
          isA<SourceFailure>().having(
            (failure) => failure.code,
            'code',
            SourceFailureCode.parse,
          ),
        ),
      );
    },
  );

  test('late response after logout cannot publish normalized result', () async {
    final sessions = SourceSessionManager();
    final response = Completer<SourceHttpResponse>();
    final transport = _ScriptedTransport((_) => response.future);
    final source = Wenku8Source(transport: transport, sessions: sessions);
    final pending = source.search(
      SearchQuery(text: '甲'),
      context(sessions, SourceOperation.search),
    );
    sessions.logout(sourceId);
    response.complete(
      fixture('search-normal-multi', transport.requests.single),
    );
    await expectLater(
      pending,
      throwsA(
        isA<SourceFailure>().having(
          (failure) => failure.code,
          'code',
          SourceFailureCode.cancelled,
        ),
      ),
    );
  });

  test('caller cancellation suppresses a late page response', () async {
    final sessions = SourceSessionManager();
    final response = Completer<SourceHttpResponse>();
    final transport = _ScriptedTransport((_) => response.future);
    final source = Wenku8Source(transport: transport, sessions: sessions);
    final cancellation = SourceCancellation();
    final pending = source.search(
      SearchQuery(text: '甲'),
      context(
        sessions,
        SourceOperation.search,
        cancellation: cancellation,
      ),
    );
    cancellation.cancel();
    response.complete(fixture(
      'search-normal-multi',
      transport.requests.single,
      pageMetadata: '1 / 1',
    ));
    await expectLater(
      pending,
      throwsA(isA<SourceFailure>().having(
        (failure) => failure.code,
        'code',
        SourceFailureCode.cancelled,
      )),
    );
  });

  test('HTTP and provider challenge failures are typed and redacted', () async {
    final sessions = SourceSessionManager();
    for (final (status, wanted) in [
      (404, SourceFailureCode.notFound),
      (429, SourceFailureCode.rateLimit),
      (503, SourceFailureCode.network),
    ]) {
      final source = Wenku8Source(
        sessions: sessions,
        transport: _ScriptedTransport(
          (request) async => SourceHttpResponse(
            statusCode: status,
            headers: SourceHttpHeaders(),
            bodyBytes: utf8.encode('sensitive server message'),
            finalUri: request.uri,
          ),
        ),
      );
      await expectLater(
        source.search(
          SearchQuery(text: 'sensitive query'),
          context(sessions, SourceOperation.search),
        ),
        throwsA(
          isA<SourceFailure>().having(
            (failure) => failure.code,
            'code',
            wanted,
          ),
        ),
      );
    }
    final challenge = Wenku8Source(
      sessions: sessions,
      transport: _ScriptedTransport(
        (request) async => fixture('search-http200-waf', request),
      ),
    );
    await expectLater(
      challenge.search(
        SearchQuery(text: 'private query'),
        context(sessions, SourceOperation.search),
      ),
      throwsA(
        isA<SourceFailure>().having(
          (failure) => failure.code,
          'code',
          SourceFailureCode.incompatibleResponse,
        ),
      ),
    );
  });

  test(
    'HTTP and HTML authentication expiry advance session generation',
    () async {
      for (final status in [401, 200]) {
        final sessions = SourceSessionManager();
        sessions.establish(sourceId);
        final initial = sessions.snapshot(sourceId).generation;
        final source = Wenku8Source(
          sessions: sessions,
          transport: _ScriptedTransport(
            (request) async => status == 200
                ? fixture('search-login-required', request)
                : SourceHttpResponse(
                    statusCode: status,
                    headers: SourceHttpHeaders(),
                    bodyBytes: const [],
                    finalUri: request.uri,
                  ),
          ),
        );
        await expectLater(
          source.search(
            SearchQuery(text: '甲'),
            context(sessions, SourceOperation.search),
          ),
          throwsA(
            isA<SourceFailure>().having(
              (failure) => failure.code,
              'code',
              SourceFailureCode.authentication,
            ),
          ),
        );
        expect(sessions.snapshot(sourceId).generation, initial + 1);
        expect(
          sessions.snapshot(sourceId).authStatus,
          SourceAuthStatus.expired,
        );
      }
    },
  );
}

final class _ScriptedTransport implements SourceTransport {
  _ScriptedTransport(this.handler);

  final Future<SourceHttpResponse> Function(SourceHttpRequest request) handler;
  final List<SourceHttpRequest> requests = [];

  @override
  Future<SourceHttpResponse> send(SourceHttpRequest request) {
    requests.add(request);
    return handler(request);
  }
}
