import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_reader/src/source/source_operation.dart';
import 'package:light_novel_reader/src/sources/wenku8/wenku8.dart';

void main() {
  final builder = Wenku8RequestBuilder();

  group('Wenku8 host policy', () {
    test('routes characterized operations to their frozen origins', () {
      final search = builder.buildSearch(Wenku8SearchIntent(query: 'x'));
      final explore = builder.buildExplore(Wenku8ExploreIntent.home());
      final detail = builder.buildBookDetail(
        Wenku8BookDetailIntent(bookLocator: '00123'),
      );
      final catalog = builder.buildCatalog(
        Wenku8CatalogIntent.fromParts(bookLocator: '00123', directory: '12'),
      );
      final chapter = builder.buildChapterContent(
        Wenku8ChapterContentIntent.fromParts(
          bookLocator: '00123',
          directory: '12',
          chapterLocator: 'chapter-opaque',
        ),
      );

      expect(search.request.uri.host, 'www.wenku8.net');
      expect(explore.request.uri.host, 'www.wenku8.net');
      expect(detail.request.uri.host, 'www.wenku8.cc');
      expect(catalog.request.uri.host, 'www.wenku8.cc');
      expect(chapter.request.uri.host, 'www.wenku8.cc');
      expect(search.request.uri.path, '/modules/article/search.php');
      expect(explore.request.uri.path, '/index.php');
      expect(detail.request.uri.path, '/book/00123.htm');
      expect(catalog.request.uri.path, '/novel/12/00123/index.htm');
      expect(chapter.request.uri.path, '/novel/12/00123/chapter-opaque.htm');
      expect(search.request.uri.scheme, 'https');
      expect(chapter.request.operation, SourceOperation.chapterContent);
    });

    test('rejects arbitrary origins, non-HTTPS, user-info and URL paths', () {
      final intent = Wenku8SearchIntent(query: 'x');
      expect(
        () => builder.buildSearch(
          intent,
          hostOverride: Uri.parse('https://example.invalid'),
        ),
        throwsA(isA<Wenku8RequestBuildException>()),
      );
      expect(
        () => builder.buildSearch(
          intent,
          hostOverride: Uri.parse('http://www.wenku8.net'),
        ),
        throwsA(isA<Wenku8RequestBuildException>()),
      );
      expect(
        () => builder.buildSearch(
          intent,
          hostOverride: Uri.parse('https://user@www.wenku8.net'),
        ),
        throwsA(isA<Wenku8RequestBuildException>()),
      );
      expect(
        () => builder.buildSearch(
          intent,
          hostOverride: Uri.parse('https://www.wenku8.net/arbitrary'),
        ),
        throwsA(isA<Wenku8RequestBuildException>()),
      );
    });
  });

  group('Wenku8 search query construction', () {
    test('matches the accepted F3.2 GBK request fixture exactly', () {
      final raw = File(
        'test/fixtures/sources/wenku8/raw/request/gbk-query.txt',
      ).readAsStringSync().trim();
      final input = Uri.parse('https://fixture.invalid/?$raw').queryParameters;
      final expected = jsonDecode(
        File(
          'test/fixtures/sources/wenku8/expected/request/gbk-query.json',
        ).readAsStringSync(),
      ) as Map<String, dynamic>;

      expect(input['searchtype'], 'articlename');
      expect(input['page'], '1');
      final built = builder.buildSearch(
        Wenku8SearchIntent(query: input['searchkey']!),
      );

      expect(
        built.request.uri.query,
        expected['query'],
      );
      expect(built.query.encodedQuery, expected['query']);
      expect(built.query.legacyEncodedFields, ['searchkey']);
      expect(built.query.inputByteLength, 4);
    });

    test('preserves ASCII while escaping spaces and reserved characters', () {
      final built = builder.buildSearch(Wenku8SearchIntent(query: 'A B&=+?#'));

      expect(
        built.request.uri.query,
        'searchtype=articlename&searchkey=A%20B%26%3D%2B%3F%23&page=1',
      );
    });

    test('allows an empty search and encodes it explicitly', () {
      final built = builder.buildSearch(Wenku8SearchIntent(query: ''));
      expect(
        built.request.uri.query,
        'searchtype=articlename&searchkey=&page=1',
      );
    });

    test('rejects a query character that the approved legacy encoder cannot represent', () {
      expect(
        () => builder.buildSearch(Wenku8SearchIntent(query: '😀')),
        throwsA(
          isA<Wenku8RequestBuildException>().having(
            (error) => error.kind,
            'kind',
            Wenku8RequestFailureKind.unsupportedQueryCharacter,
          ),
        ),
      );
    });
  });

  group('Wenku8 explore construction', () {
    test('uses frozen category paths and query ordering', () {
      final allVisit = builder.buildExplore(
        Wenku8ExploreIntent.category(Wenku8ExploreCategory.allVisit, page: 2),
      );
      final completed = builder.buildExplore(
        Wenku8ExploreIntent.category(Wenku8ExploreCategory.completed, page: 3),
      );

      expect(
        allVisit.request.uri.toString(),
        'https://www.wenku8.net/modules/article/toplist.php?page=2&sort=allvisit',
      );
      expect(
        completed.request.uri.toString(),
        'https://www.wenku8.net/modules/article/articlelist.php?page=3&fullflag=1',
      );
    });

    test('uses legacy encoding for tag selection', () {
      final built = builder.buildExplore(Wenku8ExploreIntent.tag('校园'));
      expect(built.request.uri.query, 'page=1&t=%D0%A3%D4%B0');
      expect(built.query.legacyEncodedFields, ['t']);
    });
  });

  group('opaque locator handling', () {
    test(
      'preserves leading zero and route evidence without integer conversion',
      () {
        final catalog = builder.buildCatalog(
          Wenku8CatalogIntent.fromParts(bookLocator: '00123', directory: '12'),
        );
        final chapter = builder.buildChapterContent(
          Wenku8ChapterContentIntent.fromParts(
            bookLocator: '00123',
            directory: '12',
            chapterLocator: 'c/opaque',
          ),
        );

        expect(catalog.request.uri.pathSegments, [
          'novel',
          '12',
          '00123',
          'index.htm',
        ]);
        expect(chapter.request.uri.pathSegments, [
          'novel',
          '12',
          '00123',
          'c/opaque.htm',
        ]);
      },
    );
  });

  group('request safety', () {
    test('creates immutable headers and no credential-bearing headers', () {
      final built = builder.buildSearch(Wenku8SearchIntent(query: 'safe'));
      expect(built.request.headers.values, isEmpty);
      expect(
        () => built.request.headers.values['cookie'] = const ['x'],
        throwsUnsupportedError,
      );
      expect(built.toString(), isNot(contains('safe')));
      expect(built.toString().toLowerCase(), isNot(contains('cookie')));
      expect(built.toString().toLowerCase(), isNot(contains('authorization')));
      expect(built.request.sessionGeneration, 0);
      expect(built.request.sessionBinding, isNull);
    });
  });
}
