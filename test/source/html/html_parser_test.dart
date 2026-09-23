import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_reader/src/source/charset/charset_models.dart';
import 'package:light_novel_reader/src/source/html/html.dart';

void main() {
  const parser = HtmlDocumentParser();

  String fixture(String name) =>
      File('test/fixtures/html/$name').readAsStringSync();

  DecodedDocument decoded(String text) => DecodedDocument(
    text: text,
    encoding: SourceEncoding.utf8,
    evidence: CharsetEvidence('generic HTML fixture'),
    replacements: ReplacementMetadata.none(),
  );

  test('uses the frozen injectable safety defaults', () {
    const limits = HtmlParserLimits();
    expect(limits.maxTraversalDepth, 64);
    expect(limits.maxTraversedNodes, 100000);
    expect(limits.maxProducedNodes, 100000);
    expect(limits.maxTextPayloadBytes, 1024 * 1024);
  });

  test('preserves ordered text nodes and title evidence', () {
    final document = parser.parse(
      decoded('<title>Fixture</title>${fixture('basic_text.html')}'),
    );

    expect(document.titleEvidence, 'Fixture');
    expect(
      document.nodes.whereType<ParsedHtmlText>().map((node) => node.text),
      ['Fixture', 'Hello', 'World'],
    );
    expect(document.nodes.map((node) => node.depth), [3, 3, 3]);
  });

  test('preserves nesting depth, order, and meaningful whitespace', () {
    final document = parser.parse(decoded(fixture('nested.html')));
    final text = document.nodes.whereType<ParsedHtmlText>().toList();

    expect(text.map((node) => node.text), ['A ', 'B', ' C']);
    expect(text.map((node) => node.depth), [3, 4, 3]);
  });

  test('preserves image and link locator evidence in document order', () {
    final input =
        '${fixture('image_order.html')}<img src="a.jpg">'
        '<a href="https://example.test/b">B</a>'
        '<img src="//cdn.example.test/c.png"><p>D</p>';
    final document = parser.parse(decoded(input));

    expect(document.nodes[0], isA<ParsedHtmlText>());
    expect((document.nodes[1] as ParsedHtmlImage).rawLocator, 'a.jpg');
    expect((document.nodes[2] as ParsedHtmlText).text, 'B');
    expect((document.nodes[3] as ParsedHtmlImage).rawLocator, 'a.jpg');
    expect(
      (document.nodes[4] as ParsedHtmlLink).rawLocator,
      'https://example.test/b',
    );
    expect((document.nodes[5] as ParsedHtmlText).text, 'B');
    expect(
      (document.nodes[6] as ParsedHtmlImage).rawLocator,
      '//cdn.example.test/c.png',
    );
    expect((document.nodes[7] as ParsedHtmlText).text, 'D');
  });

  test('HTML5 recovery handles missing closing tags and comments', () {
    final document = parser.parse(decoded(fixture('malformed.html')));

    expect(
      document.nodes.whereType<ParsedHtmlText>().map((node) => node.text),
      ['One', 'Two'],
    );
  });

  test('exposes immutable, redacted element ranges for pure adapters', () {
    final document = parser.parse(
      decoded(
        '<div id="content" class="chapter" data-secret="sentinel"><p>A</p></div>',
      ),
    );
    final content = document.elements.singleWhere(
      (element) => element.attribute('id') == 'content',
    );
    expect(content.tag, 'div');
    expect(content.hasClass('chapter'), isTrue);
    expect(content.startNodeIndex, 0);
    expect(content.endNodeIndex, 1);
    expect(document.nodes[0], isA<ParsedHtmlText>());
    expect(content.toString(), isNot(contains('sentinel')));
    expect(() => content.attributes['id'] = 'other', throwsUnsupportedError);
  });

  test('empty and whitespace-only documents remain valid', () {
    expect(parser.parse(decoded('')).nodes, isEmpty);
    expect(parser.parse(decoded(' \n\t ')).nodes, isEmpty);
    expect(
      parser
          .parse(decoded(fixture('whitespace.html')))
          .nodes
          .whereType<ParsedHtmlText>()
          .single
          .text,
      'A\nB\nC',
    );
  });

  test('normalizes only CRLF boundaries', () {
    final document = parser.parse(decoded('<p>A\r\nB\rC</p>'));
    expect(document.nodes.whereType<ParsedHtmlText>().single.text, 'A\nB\nC');
  });

  test('depth beyond the injected limit produces a typed failure', () {
    final input = '${'<div>' * 8}deep${'</div>' * 8}';
    final limited = HtmlDocumentParser(
      limits: const HtmlParserLimits(maxTraversalDepth: 4),
    );

    expect(
      () => limited.parse(decoded(input)),
      throwsA(
        isA<HtmlParserException>().having(
          (error) => error.info.kind,
          'kind',
          HtmlParserFailureKind.traversalLimitExceeded,
        ),
      ),
    );
  });

  test('default depth limit rejects generated depth greater than 64', () {
    final input = '${'<div>' * 65}deep${'</div>' * 65}';

    expect(
      () => parser.parse(decoded(input)),
      throwsA(
        isA<HtmlParserException>().having(
          (error) => error.info.kind,
          'kind',
          HtmlParserFailureKind.traversalLimitExceeded,
        ),
      ),
    );
  });

  test('traversed node limits are injectable and deterministic', () {
    final limited = HtmlDocumentParser(
      limits: const HtmlParserLimits(maxTraversedNodes: 5),
    );

    expect(
      () => limited.parse(decoded('<p>A</p><p>B</p>')),
      throwsA(
        isA<HtmlParserException>().having(
          (error) => error.info.kind,
          'kind',
          HtmlParserFailureKind.traversalLimitExceeded,
        ),
      ),
    );
  });

  test('default node limit rejects a generated corpus above 100000 nodes', () {
    final input = List<String>.filled(100001, '<br>').join();

    expect(
      () => parser.parse(decoded(input)),
      throwsA(
        isA<HtmlParserException>().having(
          (error) => error.info.limitName,
          'limit',
          'maxTraversedNodes',
        ),
      ),
    );
  });

  test('produced node limits are injectable and deterministic', () {
    final limited = HtmlDocumentParser(
      limits: const HtmlParserLimits(maxProducedNodes: 1),
    );

    expect(
      () => limited.parse(decoded('<p>A</p><p>B</p>')),
      throwsA(
        isA<HtmlParserException>().having(
          (error) => error.info.kind,
          'kind',
          HtmlParserFailureKind.producedNodeLimitExceeded,
        ),
      ),
    );
  });

  test('text payload limits are injectable and deterministic', () {
    final limited = HtmlDocumentParser(
      limits: const HtmlParserLimits(maxTextPayloadBytes: 3),
    );

    expect(
      () => limited.parse(decoded('<p>four</p>')),
      throwsA(
        isA<HtmlParserException>().having(
          (error) => error.info.kind,
          'kind',
          HtmlParserFailureKind.textPayloadLimitExceeded,
        ),
      ),
    );
  });

  test('invalid decoded Unicode is reported without package exceptions', () {
    expect(
      () => parser.parse(decoded('<p>\ud800</p>')),
      throwsA(
        isA<HtmlParserException>().having(
          (error) => error.info.kind,
          'kind',
          HtmlParserFailureKind.invalidDecodedDocument,
        ),
      ),
    );
  });

  test('diagnostics do not expose document contents or sentinel payloads', () {
    const sentinel = 'private-sentinel-7f1c';
    final document = parser.parse(
      decoded('<p>$sentinel</p><p>${'x' * 1024}</p>'),
    );
    final output = '${document.toString()} ${document.nodes.join()}';

    expect(output, isNot(contains(sentinel)));
    expect(output.length, lessThan(500));
  });

  test('package:html is isolated to the parser infrastructure', () {
    final files = Directory('lib/src')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    for (final file in files) {
      final source = file.readAsStringSync();
      final normalizedPath = file.path.replaceAll('\\', '/');
      if (!normalizedPath.contains('/source/html/')) {
        expect(source, isNot(contains('package:html/')));
      }
    }
  });
}
