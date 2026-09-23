import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_reader/src/source/charset/charset_codec.dart';
import 'package:light_novel_reader/src/source/charset/charset_models.dart';
import 'package:light_novel_reader/src/source/html/html.dart';
import 'package:light_novel_reader/src/sources/wenku8/wenku8.dart';

void main() {
  const decoder = CharsetDecoder();
  const html = HtmlDocumentParser();
  const parser = Wenku8PureParser();
  const root = 'test/fixtures/sources/wenku8';
  final manifest = jsonDecode(
    File('$root/manifest.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final entries = <String, Map<String, dynamic>>{
    for (final item in manifest['entries'] as List<dynamic>)
      (item as Map<String, dynamic>)['id'] as String: item,
  };

  Map<String, dynamic> expected(String id) =>
      jsonDecode(File('$root/${entries[id]!['expected']}').readAsStringSync())
          as Map<String, dynamic>;

  ParsedHtmlDocument document(String id) {
    final entry = entries[id]!;
    final encoding = switch (entry['encoding'] as String) {
      'utf-8' => SourceEncoding.utf8,
      'gbk' || 'gb2312' => SourceEncoding.legacyCp936Compatible,
      'gb18030' => SourceEncoding.gb18030,
      final other => throw StateError('Unsupported fixture encoding: $other'),
    };
    final decoded = decoder.decode(
      RawBytes(File('$root/${entry['fixture']}').readAsBytesSync()),
      encoding: encoding,
      evidence: CharsetEvidence('frozen F3.2 fixture'),
    );
    return html.parseFragment(
      decoded,
      container: id == 'detail-table-concatenation' ? 'tr' : 'div',
    );
  }

  String key(Map<String, dynamic> book) =>
      (book['bookId'] as String).replaceFirst(RegExp(r'^wk8-'), '');

  void expectBooks(List<SourceParsedBook> actual, List<dynamic> sidecar) {
    expect(actual.length, sidecar.length);
    for (var i = 0; i < sidecar.length; i++) {
      final book = sidecar[i] as Map<String, dynamic>;
      expect(actual[i].providerKey, key(book));
      expect(actual[i].title, book['title']);
    }
  }

  test(
    'search pages match independent normal, dedup and direct-detail sidecars',
    () {
      for (final id in [
        'search-normal-multi',
        'search-duplicates',
        'search-page-2',
        'search-direct-detail',
        'search-valid-empty',
      ]) {
        final sidecar = expected(id);
        final page = parser.parseSearch(document(id));
        expectBooks(page.items, sidecar['items'] as List<dynamic>);
        expect(page.directDetail, sidecar['directDetail'] == true);
        expect(page.validEmpty, sidecar['validEmpty'] == true);
        expect(
          page.pagination,
          isNull,
          reason: 'A result fragment cannot prove pagination or exhaustion',
        );
      }
    },
  );

  test('search failure shapes are typed and redacted', () {
    for (final id in [
      'search-malformed-item',
      'search-missing-field',
      'search-login-required',
      'search-http200-waf',
    ]) {
      final sidecar = expected(id);
      final error = expectFailure(() => parser.parseSearch(document(id)));
      expect(error.kind, switch (sidecar['code']) {
        'authentication' => Wenku8ParseFailureKind.authenticationRequired,
        'incompatibleResponse' => Wenku8ParseFailureKind.incompatibleResponse,
        _ => Wenku8ParseFailureKind.parse,
      });
      if (sidecar.containsKey('field')) {
        expect(error.field?.name, sidecar['field']);
      }
      if (sidecar.containsKey('itemIndex')) {
        expect(error.itemIndex, sidecar['itemIndex']);
      }
      expect(error.toString(), isNot(contains('Access denied')));
      expect(error.toString(), isNot(contains('login.php')));
    }
  });

  test('frozen Legacy book card uses .htm ID and title evidence', () {
    final raw = File('test/source/wenku8/fixtures/legacy_book_card.html')
        .readAsBytesSync();
    expect(
      normalizedFixtureSha256(raw),
      '168bded71fe25beb78e4fdd12d95b800416f9f5b5e2e865ac866023c0c7d6c32',
    );
    final expectedBytes = File(
      'test/source/wenku8/fixtures/legacy_book_card.expected.json',
    ).readAsBytesSync();
    expect(
      normalizedFixtureSha256(expectedBytes),
      '03c66eb941999fa332830085ddcbf3e2392889f291a127732d96be827e9e397a',
    );
    final sidecar =
        jsonDecode(utf8.decode(expectedBytes)) as Map<String, dynamic>;
    expect(sidecar['provenance'], 'reconstructed_from_frozen_evidence');
    expect(
      sidecar['frozenLegacyCommit'],
      'd90d4d090c85a0a9c374684696c34befe12636d1',
    );
    final result = parser.parseSearch(
      html.parseFragment(
        decoder.decode(
          RawBytes(raw),
          encoding: SourceEncoding.utf8,
          evidence: CharsetEvidence('frozen Legacy card reconstruction'),
        ),
      ),
    );
    expect(result.items.length, sidecar['count']);
    expect('wk8-${result.items.single.providerKey}', sidecar['bookId']);
    expect(result.items.single.title, sidecar['title']);
  });

  test(
    'explore blocks, flat results, grouping and selections match sidecars',
    () {
      for (final id in [
        'explore-home',
        'explore-category',
        'explore-tag-filter',
        'explore-pagination',
        'explore-duplicate-whitespace',
        'explore-missing-optional',
        'explore-multiple-blocks',
        'explore-valid-empty',
      ]) {
        final sidecar = expected(id);
        final expectedBlocks = sidecar['blocks'] as List<dynamic>? ?? const [];
        final first = expectedBlocks.isEmpty
            ? null
            : expectedBlocks.first as Map<String, dynamic>;
        final result = parser.parseExplore(
          document(id),
          context: Wenku8ExploreContext(
            descriptor: sidecar['descriptor'] as String? ?? 'fixture',
            blockId:
                id == 'explore-home' ||
                    id == 'explore-category' ||
                    id == 'explore-tag-filter'
                ? first!['id'] as String
                : null,
            blockTitle: id == 'explore-tag-filter'
                ? first!['title'] as String
                : null,
            selections: (sidecar['selections'] as Map<String, dynamic>? ?? {})
                .map((name, value) => MapEntry(name, value as String)),
          ),
        );
        expect(result.descriptor, sidecar['descriptor'] ?? 'fixture');
        expect(result.validEmpty, sidecar['validEmpty'] == true);
        expect(result.blocks.length, expectedBlocks.length);
        for (var i = 0; i < expectedBlocks.length; i++) {
          final block = expectedBlocks[i] as Map<String, dynamic>;
          expect(result.blocks[i].id, block['id']);
          expect(result.blocks[i].title, block['title']);
          expectBooks(result.blocks[i].books, block['books'] as List<dynamic>);
        }
        if (sidecar['items'] case final List<dynamic> items) {
          expectBooks(result.items, items);
        }
        expect(
          result.pagination,
          isNull,
          reason: 'The Explore HTML fragment has no pagination evidence',
        );
        if (sidecar['selections'] != null) {
          expect(result.selections, sidecar['selections']);
        }
      }
      expectFailure(
        () => parser.parseExplore(
          document('explore-malformed-block'),
          context: Wenku8ExploreContext(descriptor: 'home'),
        ),
      );
      final noBlockIdentity = expectFailure(
        () => parser.parseExplore(
          document('explore-home'),
          context: Wenku8ExploreContext(descriptor: 'home'),
        ),
      );
      expect(noBlockIdentity.reason, Wenku8ParseReason.blockId);
      final callerPagination = SourceParsedPagination(
        currentPage: 2,
        nextPage: 3,
        exhausted: false,
        validPage: true,
        source: 'separate-caller-evidence',
      );
      final withContext = parser.parseExplore(
        document('explore-pagination'),
        context: Wenku8ExploreContext(
          descriptor: 'category',
          pagination: callerPagination,
        ),
      );
      expect(identical(withContext.pagination, callerPagination), true);
    },
  );

  test('frozen Legacy home block structure preserves two distinct groups', () {
    final raw = File('test/source/wenku8/fixtures/legacy_home_blocks.html')
        .readAsBytesSync();
    expect(
      normalizedFixtureSha256(raw),
      '23457501074ca05109f35750b0de62e8764a0723286be203a472ce2de20eb23b',
    );
    final expectedBytes = File(
      'test/source/wenku8/fixtures/legacy_home_blocks.expected.json',
    ).readAsBytesSync();
    expect(
      normalizedFixtureSha256(expectedBytes),
      '8015658ded2a0034e92478078d7f2eca5bf4c4a3bfa2fbb0bfcc4bd5d439047f',
    );
    final sidecar =
        jsonDecode(utf8.decode(expectedBytes)) as Map<String, dynamic>;
    expect(sidecar['provenance'], 'reconstructed_from_frozen_evidence');
    final result = parser.parseExplore(
      html.parseFragment(
        decoder.decode(
          RawBytes(raw),
          encoding: SourceEncoding.utf8,
          evidence: CharsetEvidence('frozen Legacy home reconstruction'),
        ),
      ),
      context: Wenku8ExploreContext(descriptor: 'home', blockId: 'home'),
    );
    final wanted = sidecar['blocks'] as List<dynamic>;
    expect(result.blocks.length, wanted.length);
    for (var index = 0; index < wanted.length; index++) {
      final expectedBlock = wanted[index] as Map<String, dynamic>;
      final block = result.blocks[index];
      expect(block.id, expectedBlock['id']);
      expect(block.title, expectedBlock['title']);
      expect('wk8-${block.books.single.providerKey}', expectedBlock['bookId']);
      expect(block.books.single.title, expectedBlock['bookTitle']);
    }
  });

  test('pagination metadata and malformed page are distinct', () {
    final stats = parser.parsePagination(document('pagination-pagestats'));
    expect(stats.currentPage, expected('pagination-pagestats')['current']);
    expect(stats.totalPages, expected('pagination-pagestats')['total']);
    expect(stats.nextPage, 2);
    final legacyPageLink = html.parseFragment(
      decoder.decode(
        RawBytes(utf8.encode('<div id="pagelink"><em>2 / 4</em></div>')),
        encoding: SourceEncoding.utf8,
        evidence: CharsetEvidence('frozen Legacy pagelink reconstruction'),
      ),
    );
    final legacy = parser.parsePagination(legacyPageLink);
    expect(legacy.currentPage, 2);
    expect(legacy.totalPages, 4);
    expect(legacy.nextPage, 3);
    expect(legacy.source, 'pagelink-em');
    final exhausted = parser.parsePagination(document('pagination-exhausted'));
    expect(exhausted.exhausted, true);
    expect(exhausted.nextPage, isNull);
    final links = parser.parsePagination(
      document('pagination-pagelink-whitespace'),
    );
    expect(
      links.linkedPages,
      expected('pagination-pagelink-whitespace')['linked'],
    );
    expect(links.nextPage, 4);
    final largest = parser.parsePagination(
      document('pagination-largest-linked-fallback'),
    );
    expect(
      largest.totalPages,
      expected('pagination-largest-linked-fallback')['total'],
    );
    final missing = parser.parsePagination(
      document('pagination-missing-metadata'),
    );
    expect(missing.source, 'missing-metadata');
    expect(missing.nextPage, isNull);
    expect(missing.validPage, true);
    expectFailure(
      () => parser.parsePagination(document('pagination-malformed-metadata')),
    );
    final books = parser.parseSearch(document('pagination-duplicate-book'));
    expectBooks(
      books.items,
      expected('pagination-duplicate-book')['items'] as List<dynamic>,
    );
    final oversized = html.parseFragment(
      decoder.decode(
        RawBytes(utf8.encode('<div id="pagestats">${'9' * 100}/8</div>')),
        encoding: SourceEncoding.utf8,
        evidence: CharsetEvidence('synthetic oversized pagination'),
      ),
    );
    final overflow = expectFailure(() => parser.parsePagination(oversized));
    expect(overflow.reason, Wenku8ParseReason.pagination);
    expect(overflow.toString(), isNot(contains('9999')));
    expect(
      () => SourceParsedPagination(
        currentPage: 2,
        nextPage: 1,
        exhausted: false,
        validPage: true,
        source: 'synthetic',
      ),
      throwsArgumentError,
    );
  });

  test('detail required fields, optional fields and chrome exclusion', () {
    for (final id in ['detail-normal', 'detail-missing-optionals']) {
      final sidecar = expected(id);
      final detail = parser.parseDetail(document(id)) as SourceParsedDetail;
      expect(detail.title, sidecar['title']);
      expect(detail.author, sidecar['author']);
      expect(detail.description, sidecar['description']);
      expect(detail.coverLocator, sidecar['coverLocator']);
    }
    expect(
      (parser.parseDetail(
        document('detail-copyright-unavailable'),
      ) as SourceParsedDetailUnavailable).reason,
      'copyright',
    );
    final error = expectFailure(
      () => parser.parseDetail(document('detail-malformed-required')),
    );
    expect(error.field, Wenku8ParseField.title);
    expect(
      parser.parseDescription(document('detail-description-page-chrome')),
      expected('detail-description-page-chrome')['description'],
    );
    final withFooter = html.parseFragment(
      decoder.decode(
        RawBytes(
          utf8.encode('<h1>书名</h1><footer class="copyright">站点版权</footer>'),
        ),
        encoding: SourceEncoding.utf8,
        evidence: CharsetEvidence('synthetic footer collision'),
      ),
    );
    expect(parser.parseDetail(withFooter), isA<SourceParsedDetail>());
  });

  test('frozen Legacy detail table yields title, author and description', () {
    final raw = File('test/source/wenku8/fixtures/legacy_detail_table.html')
        .readAsBytesSync();
    expect(
      normalizedFixtureSha256(raw),
      '4f87e264f623fb3b7efbe76453cbde93bfa8097c4881a3ece5e9ef94655cf049',
    );
    final expectedBytes = File(
      'test/source/wenku8/fixtures/legacy_detail_table.expected.json',
    ).readAsBytesSync();
    expect(
      normalizedFixtureSha256(expectedBytes),
      'e425e2300b1a5e1f7acddd67a59e0f5b3c10535abc4070585fcd878fe49bf1fa',
    );
    final sidecar =
        jsonDecode(utf8.decode(expectedBytes)) as Map<String, dynamic>;
    expect(sidecar['provenance'], 'reconstructed_from_frozen_evidence');
    final result = parser.parseDetail(
      html.parseFragment(
        decoder.decode(
          RawBytes(raw),
          encoding: SourceEncoding.utf8,
          evidence: CharsetEvidence('frozen Legacy detail reconstruction'),
        ),
      ),
    ) as SourceParsedDetail;
    expect(result.title, sidecar['title']);
    expect(result.author, sidecar['author']);
    expect(result.description, sidecar['description']);
    expect(result.coverLocator, sidecar['coverLocator']);
  });

  test('table cells remain separate even in title-less detail fragment', () {
    expect(
      parser.parseDetailTableFields(document('detail-table-concatenation')),
      expected('detail-table-concatenation')['fields'],
    );
  });

  test(
    'catalog identity evidence never uses ordinal as chapter or volume ID',
    () {
      for (final id in [
        'catalog-normal',
        'catalog-flat',
        'catalog-group-label-only',
        'catalog-multiple-volumes',
        'catalog-missing-chapter-id',
        'catalog-reordered',
      ]) {
        final sidecar = expected(id);
        final catalog = parser.parseCatalog(document(id));
        final chapters = sidecar['chapters'] as List<dynamic>?;
        if (chapters != null) {
          expect(catalog.chapters.length, chapters.length);
          for (var i = 0; i < chapters.length; i++) {
            final expectedChapter = chapters[i] as Map<String, dynamic>;
            final actual = catalog.chapters[i];
            if (expectedChapter.containsKey('chapterId')) {
              expect(actual.providerKey, expectedChapter['chapterId']);
            }
            if (expectedChapter.containsKey('volumeId')) {
              expect(actual.providerVolumeKey, expectedChapter['volumeId']);
            }
            if (expectedChapter.containsKey('ordinal')) {
              expect(actual.ordinal, expectedChapter['ordinal']);
            }
            if (expectedChapter.containsKey('title')) {
              expect(actual.title, expectedChapter['title']);
            }
          }
        }
        if (id == 'catalog-missing-chapter-id') {
          expect(catalog.chapters.single.providerKey, isNull);
          expect(catalog.chapters.single.ordinal, 0);
        }
        if (id == 'catalog-group-label-only') {
          expect(catalog.chapters.single.providerVolumeKey, isNull);
          expect(
            catalog.chapters.single.groupLabel,
            (sidecar['grouping'] as Map<String, dynamic>)['label'],
          );
        }
        if (sidecar['volumeIds'] case final List<dynamic> ids) {
          expect(catalog.volumes.map((v) => v.providerKey).toList(), ids);
        }
        if (id == 'catalog-flat') expect(catalog.volumes, isEmpty);
        if (id == 'catalog-normal') {
          expect(
            catalog.volumes.single.label,
            isNull,
            reason: 'Chapter titles are not a volume label',
          );
        }
        if (id == 'catalog-multiple-volumes') {
          expect(catalog.volumes.map((volume) => volume.label).toList(), [
            'A',
            'B',
          ]);
        }
      }
      final error = expectFailure(
        () => parser.parseCatalog(document('catalog-duplicate-id')),
      );
      expect(
        error.reason?.wireName,
        expected('catalog-duplicate-id')['reason'],
      );
    },
  );

  test('frozen Legacy table catalog keeps relative chapter and volume IDs', () {
    final raw = File('test/source/wenku8/fixtures/legacy_catalog_table.html')
        .readAsBytesSync();
    expect(
      normalizedFixtureSha256(raw),
      'fa58842725e030ab925387656e3a3ee87bfa59a63ed1c54289beef377e022ce3',
    );
    final expectedBytes = File(
      'test/source/wenku8/fixtures/legacy_catalog_table.expected.json',
    ).readAsBytesSync();
    expect(
      normalizedFixtureSha256(expectedBytes),
      '5239bb63853e909917599719e61a8eb6af773cef0b5b22014290b0247110f774',
    );
    final sidecar =
        jsonDecode(utf8.decode(expectedBytes)) as Map<String, dynamic>;
    expect(sidecar['provenance'], 'reconstructed_from_frozen_evidence');
    expect(
      sidecar['frozenLegacyCommit'],
      'd90d4d090c85a0a9c374684696c34befe12636d1',
    );
    final parsed = parser.parseCatalog(
      html.parseFragment(
        decoder.decode(
          RawBytes(raw),
          encoding: SourceEncoding.utf8,
          evidence: CharsetEvidence('frozen Legacy table reconstruction'),
        ),
      ),
    );
    expect(
      parsed.volumes.map((volume) => volume.providerKey).toList(),
      sidecar['volumeIds'],
    );
    expect(
      parsed.volumes.map((volume) => volume.label).toList(),
      sidecar['volumeLabels'],
    );
    expect(
      parsed.chapters.map((chapter) => chapter.providerKey).toList(),
      sidecar['chapterIds'],
    );
    expect(
      parsed.chapters.map((chapter) => chapter.title).toList(),
      sidecar['chapterTitles'],
    );
    expect(
      parsed.chapters.map((chapter) => chapter.providerVolumeKey).toList(),
      sidecar['chapterVolumeIds'],
    );
  });

  test(
    'content matches every ordered node sidecar including six-node case',
    () {
      for (final id in [
        'content-interleaved',
        'content-br-flush',
        'content-consecutive-br',
        'content-image-only',
        'content-repeated-image',
        'content-text-around-image',
        'content-valid-empty',
        'content-page-chrome',
        'content-nested-dom',
        'content-multi-interleaved',
      ]) {
        final sidecar = expected(id);
        final nodes = parser.parseContent(document(id)).nodes;
        final wanted = sidecar['nodes'] as List<dynamic>;
        expect(nodes.length, wanted.length, reason: id);
        for (var i = 0; i < wanted.length; i++) {
          final value = wanted[i] as Map<String, dynamic>;
          if (value['type'] == 'text') {
            expect(nodes[i], isA<SourceParsedText>(), reason: '$id/$i');
            expect((nodes[i] as SourceParsedText).text, value['text']);
          } else {
            expect(nodes[i], isA<SourceParsedImage>(), reason: '$id/$i');
            expect((nodes[i] as SourceParsedImage).locator, value['locator']);
          }
        }
      }
    },
  );

  test('asset locators remain raw evidence with no fabricated AssetId', () {
    for (final id in [
      'content-relative-locator',
      'content-protocol-relative-locator',
      'content-absolute-locator',
    ]) {
      final image =
          parser.parseContent(document(id)).nodes.single as SourceParsedImage;
      expect(image.locator, expected(id)['locator']);
    }
  });

  test('missing and malformed content fail without becoming empty success', () {
    final missing = expectFailure(
      () => parser.parseContent(document('content-missing-container')),
    );
    expect(
      missing.reason?.wireName,
      expected('content-missing-container')['reason'],
    );
    final malformed = expectFailure(
      () => parser.parseContent(document('content-malformed')),
    );
    expect(malformed.reason?.wireName, expected('content-malformed')['reason']);
  });
}

Wenku8ParseException expectFailure(void Function() action) {
  try {
    action();
  } on Wenku8ParseException catch (error) {
    return error;
  }
  throw TestFailure('Expected Wenku8ParseException');
}

/// These supplemental fixtures are UTF-8 text, unlike F3.2 byte vectors.
/// Normalize checkout line endings before hashing so Windows and Unix agree.
String normalizedFixtureSha256(List<int> bytes) => sha256
    .convert(utf8.encode(utf8.decode(bytes).replaceAll('\r\n', '\n')))
    .toString();
