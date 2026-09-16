import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_reader/src/domain/content/chapter_content.dart';
import 'package:light_novel_reader/src/domain/identity/identity_failure.dart';
import 'package:light_novel_reader/src/domain/identity/opaque_ids.dart';
import 'package:light_novel_reader/src/domain/identity/source_refs.dart';

Matcher failure(IdentityFailureReason reason) => throwsA(
  isA<IdentityFailure>().having((error) => error.reason, 'reason', reason),
);

final chapterRef = SourceChapterRef(
  sourceId: SourceId('source.#/- 中文😀'),
  bookId: BookId('wk8-00042/%2F'),
  chapterId: ChapterId('chapter 0001/intro'),
);
final assetRef = SourceAssetRef(
  sourceId: SourceId('source.#/- 中文😀'),
  bookId: BookId('wk8-00042/%2F'),
  assetId: AssetId('asset.#/- 中文😀'),
);

ChapterContent mixedContent({String? title = ' 章😀 '}) => ChapterContent(
  chapterRef: chapterRef,
  title: title,
  nodes: [
    const TextNode('First'),
    const TextNode(''),
    const TextNode('  second\nline\t '),
    ImageNode(assetRef: assetRef, altText: '图 / alt'),
    ImageNode(assetRef: assetRef),
    const TextNode('last'),
  ],
);

void main() {
  test('mixed content uses one ordered sequence and round-trips exactly', () {
    final original = mixedContent();
    final wire = original.toJson();
    expect(
      wire.keys,
      unorderedEquals(['kind', 'version', 'chapterRef', 'title', 'nodes']),
    );
    expect(wire['kind'], 'chapterContent');
    expect(wire['version'], 1);
    expect((wire['nodes']! as List).map((node) => (node as Map)['kind']), [
      'text',
      'text',
      'text',
      'image',
      'image',
      'text',
    ]);
    expect(ChapterContent.fromJson(wire), original);
    expect(ChapterContent.fromJson(jsonDecode(jsonEncode(original))), original);
    expect(original.nodes, [
      const TextNode('First'),
      const TextNode(''),
      const TextNode('  second\nline\t '),
      ImageNode(assetRef: assetRef, altText: '图 / alt'),
      ImageNode(assetRef: assetRef),
      const TextNode('last'),
    ]);
  });

  test(
    'empty, text-only and image-only chapters are successful content values',
    () {
      final empty = ChapterContent(chapterRef: chapterRef, nodes: const []);
      final textOnly = ChapterContent(
        chapterRef: chapterRef,
        nodes: const [TextNode('plain')],
      );
      final imageOnly = ChapterContent(
        chapterRef: chapterRef,
        nodes: [ImageNode(assetRef: assetRef)],
      );
      for (final value in [empty, textOnly, imageOnly]) {
        expect(ChapterContent.fromJson(value.toJson()), value);
        expect(value.nodes, isA<List<ContentNode>>());
      }
      expect(empty.nodes, isEmpty);
      expect(textOnly.nodes.single, const TextNode('plain'));
      expect(imageOnly.nodes.single, ImageNode(assetRef: assetRef));
      expect(empty.title, isNull);
      expect(empty.toJson().containsKey('title'), isFalse);
    },
  );

  test('title absent/present and Unicode title are preserved without normalization', () {
    final absent = mixedContent(title: null);
    expect(absent.title, isNull);
    expect(absent.toJson().containsKey('title'), isFalse);
    expect(ChapterContent.fromJson(absent.toJson()), absent);
    for (final title in ['标题😀', '', '  leading and trailing  ', 'e\u0301']) {
      final value = mixedContent(title: title);
      expect(value.title, title);
      expect(ChapterContent.fromJson(value.toJson()).title, title);
    }
  });

  test(
    'text nodes preserve empty, whitespace, line breaks, Unicode and adjacency',
    () {
      final values = ['', ' ', '  x  ', '\n\r\n', '中文😀', 'e\u0301'];
      final content = ChapterContent(
        chapterRef: chapterRef,
        nodes: values.map(TextNode.new).toList(),
      );
      expect(content.nodes, values.map(TextNode.new).toList());
      expect(content.nodes, hasLength(values.length));
      expect(content.nodes[0], const TextNode(''));
      expect(content.nodes[1], const TextNode(' '));
      expect(content.nodes[2], const TextNode('  x  '));
      expect(content.nodes[3], const TextNode('\n\r\n'));
      expect(ChapterContent.fromJson(content.toJson()), content);
      final adjacent = ChapterContent(
        chapterRef: chapterRef,
        nodes: const [TextNode('a'), TextNode('b')],
      );
      expect(adjacent.nodes, hasLength(2));
      expect(
        adjacent,
        isNot(
          ChapterContent(chapterRef: chapterRef, nodes: const [TextNode('ab')]),
        ),
      );
    },
  );

  test('order is equality-significant and survives serialization', () {
    final ordered = mixedContent();
    final reordered = ChapterContent(
      chapterRef: chapterRef,
      title: ordered.title,
      nodes: ordered.nodes.reversed.toList(),
    );
    expect(ordered, isNot(reordered));
    expect(ChapterContent.fromJson(ordered.toJson()), ordered);
    expect((ordered.nodes[0] as TextNode).text, 'First');
    expect(ordered.nodes[3], ImageNode(assetRef: assetRef, altText: '图 / alt'));
    expect(ordered.nodes[4], ImageNode(assetRef: assetRef));
  });

  test('caller mutation after construction cannot mutate nodes', () {
    final input = <ContentNode>[const TextNode('before')];
    final content = ChapterContent(chapterRef: chapterRef, nodes: input);
    input.add(const TextNode('after'));
    expect(content.nodes, [const TextNode('before')]);
    expect(
      () => content.nodes.add(const TextNode('blocked')),
      throwsUnsupportedError,
    );
  });

  test('image asset ref and altText round-trip, including repeated refs', () {
    final content = ChapterContent(
      chapterRef: chapterRef,
      nodes: [
        ImageNode(assetRef: assetRef, altText: ''),
        ImageNode(assetRef: assetRef, altText: null),
        ImageNode(assetRef: assetRef, altText: 'alt'),
        ImageNode(assetRef: assetRef),
      ],
    );
    expect(content.nodes, hasLength(4));
    expect(content.nodes[0], ImageNode(assetRef: assetRef, altText: ''));
    expect(content.nodes[1], ImageNode(assetRef: assetRef));
    expect((content.nodes[2] as ImageNode).altText, 'alt');
    expect(content.toJson(), containsPair('nodes', isA<List>()));
    expect(ChapterContent.fromJson(jsonDecode(jsonEncode(content))), content);
  });

  test(
    'mismatched image source or book is rejected at chapter construction',
    () {
      final wrongSource = SourceAssetRef(
        sourceId: SourceId('other-source'),
        bookId: assetRef.bookId,
        assetId: assetRef.assetId,
      );
      final wrongBook = SourceAssetRef(
        sourceId: assetRef.sourceId,
        bookId: BookId('other-book'),
        assetId: assetRef.assetId,
      );
      expect(
        () => ChapterContent(
          chapterRef: chapterRef,
          nodes: [ImageNode(assetRef: wrongSource)],
        ),
        failure(IdentityFailureReason.invalidValue),
      );
      expect(
        () => ChapterContent(
          chapterRef: chapterRef,
          nodes: [ImageNode(assetRef: wrongBook)],
        ),
        failure(IdentityFailureReason.invalidValue),
      );
      expect(
        () => ChapterContent.fromJson({
          ...mixedContent().toJson(),
          'nodes': [ImageNode(assetRef: wrongSource).toJson()],
        }),
        failure(IdentityFailureReason.invalidValue),
      );
    },
  );

  test('text and image node JSON shapes are strict and versionless', () {
    expect(const TextNode('text').toJson(), {'kind': 'text', 'text': 'text'});
    expect(ImageNode(assetRef: assetRef).toJson(), {
      'kind': 'image',
      'assetRef': assetRef.toJson(),
    });
    expect(TextNode.fromJson({'kind': 'text', 'text': ''}), const TextNode(''));
    expect(
      ImageNode.fromJson({'kind': 'image', 'assetRef': assetRef.toJson()}),
      ImageNode(assetRef: assetRef),
    );
    expect(
      () => ContentNode.fromJson(null),
      failure(IdentityFailureReason.wrongType),
    );
    expect(
      () => ContentNode.fromJson([]),
      failure(IdentityFailureReason.wrongType),
    );
    expect(
      () => ContentNode.fromJson({}),
      failure(IdentityFailureReason.missingField),
    );
    expect(
      () => TextNode.fromJson({'kind': 'text'}),
      failure(IdentityFailureReason.missingField),
    );
    expect(
      () => ImageNode.fromJson({'kind': 'image'}),
      failure(IdentityFailureReason.missingField),
    );
    expect(
      () => TextNode.fromJson({'kind': 'text', 'text': null}),
      failure(IdentityFailureReason.wrongType),
    );
    expect(
      () => ImageNode.fromJson({'kind': 'image', 'assetRef': null}),
      failure(IdentityFailureReason.wrongType),
    );
    expect(
      () => ImageNode.fromJson({
        'kind': 'image',
        'assetRef': assetRef.toJson(),
        'altText': 1,
      }),
      failure(IdentityFailureReason.wrongType),
    );
  });

  test('chapter JSON validates discriminators, required fields and top-level types', () {
    final wire = mixedContent().toJson();
    expect(
      () => ChapterContent.fromJson(null),
      failure(IdentityFailureReason.wrongType),
    );
    expect(
      () => ChapterContent.fromJson([]),
      failure(IdentityFailureReason.wrongType),
    );
    for (final key in ['kind', 'version', 'chapterRef', 'nodes']) {
      final missing = {...wire}..remove(key);
      expect(
        () => ChapterContent.fromJson(missing),
        failure(IdentityFailureReason.missingField),
      );
    }
    expect(
      () => ChapterContent.fromJson({...wire, 'kind': 'other'}),
      failure(IdentityFailureReason.wrongKind),
    );
    for (final version in [0, 2, -1]) {
      expect(
        () => ChapterContent.fromJson({...wire, 'version': version}),
        failure(IdentityFailureReason.unsupportedVersion),
      );
    }
    for (final value in [null, true, 1.0, []]) {
      expect(
        () => ChapterContent.fromJson({...wire, 'version': value}),
        failure(IdentityFailureReason.wrongType),
      );
      expect(
        () => ChapterContent.fromJson({...wire, 'chapterRef': value}),
        failure(IdentityFailureReason.wrongType),
      );
    }
    expect(
      () => ChapterContent.fromJson({...wire, 'chapterRef': {}}),
      failure(IdentityFailureReason.missingField),
    );
    for (final value in [null, true, 1, 1.0, 'nodes', {}]) {
      expect(
        () => ChapterContent.fromJson({...wire, 'nodes': value}),
        failure(IdentityFailureReason.wrongType),
      );
    }
    expect(
      () => ChapterContent.fromJson({...wire, 'title': null}),
      failure(IdentityFailureReason.wrongType),
    );
    expect(
      () => ChapterContent.fromJson({...wire, 'future': true}),
      failure(IdentityFailureReason.unknownField),
    );
  });

  test('unknown node kind rejects the entire chapter rather than returning partial content', () {
    final wire = mixedContent().toJson();
    final nodes = (wire['nodes']! as List).toList();
    nodes[1] = {'kind': 'futureNode', 'text': 'must not be retained'};
    expect(
      () => ChapterContent.fromJson({...wire, 'nodes': nodes}),
      failure(IdentityFailureReason.wrongKind),
    );
    expect(
      () => ChapterContent.fromJson({
        ...wire,
        'nodes': [
          const TextNode('ok').toJson(),
          {'kind': 'imageV2'},
        ],
      }),
      failure(IdentityFailureReason.wrongKind),
    );
    expect(
      () => TextNode.fromJson({'kind': 'futureNode', 'text': 'x'}),
      failure(IdentityFailureReason.wrongKind),
    );
    expect(
      () => ImageNode.fromJson({
        'kind': 'futureNode',
        'assetRef': assetRef.toJson(),
      }),
      failure(IdentityFailureReason.wrongKind),
    );
  });

  test('unknown fields in nodes and nested refs are rejected', () {
    final text = {...const TextNode('x').toJson(), 'extra': true};
    final image = {...ImageNode(assetRef: assetRef).toJson(), 'extra': true};
    expect(
      () => TextNode.fromJson(text),
      failure(IdentityFailureReason.unknownField),
    );
    expect(
      () => ImageNode.fromJson(image),
      failure(IdentityFailureReason.unknownField),
    );
    expect(
      () => ImageNode.fromJson({
        ...ImageNode(assetRef: assetRef).toJson(),
        'assetRef': {...assetRef.toJson(), 'extra': true},
      }),
      failure(IdentityFailureReason.unknownField),
    );
    expect(
      () => ChapterContent.fromJson({
        ...mixedContent().toJson(),
        'chapterRef': {...chapterRef.toJson(), 'extra': true},
      }),
      failure(IdentityFailureReason.unknownField),
    );
  });

  test(
    'identity types survive nested content serialization without coercion',
    () {
      final decoded = ChapterContent.fromJson(
        jsonDecode(jsonEncode(mixedContent())),
      );
      expect(decoded.chapterRef.sourceId, SourceId('source.#/- 中文😀'));
      expect(decoded.chapterRef.bookId, BookId('wk8-00042/%2F'));
      expect(decoded.chapterRef.chapterId, ChapterId('chapter 0001/intro'));
      final image = decoded.nodes.whereType<ImageNode>().first;
      expect(image.assetRef.sourceId, SourceId('source.#/- 中文😀'));
      expect(image.assetRef.bookId, BookId('wk8-00042/%2F'));
      expect(image.assetRef.assetId, AssetId('asset.#/- 中文😀'));
      expect(decoded.chapterRef.bookId, isNot(ChapterId('wk8-00042/%2F')));
      expect(decoded.chapterRef.bookId, isNot(BookId('42')));
    },
  );

  test(
    'decoded JSON key order and escaping do not affect semantic equality',
    () {
      final ref = chapterRef.toJson();
      final raw = jsonEncode({
        'kind': 'chapterContent',
        'version': 1,
        'chapterRef': {
          'chapterId': 'chapter 0001/intro',
          'bookId': 'wk8-00042/%2F',
          'sourceId': 'source.#/- 中文😀',
          'version': 1,
          'kind': 'sourceChapterRef',
        },
        'nodes': [
          {'text': 'x', 'kind': 'text'},
        ],
      });
      expect(
        ref.keys,
        containsAll(['kind', 'version', 'sourceId', 'bookId', 'chapterId']),
      );
      final value = ChapterContent.fromJson(jsonDecode(raw));
      expect(value.chapterRef, chapterRef);
      expect(value.nodes, const [TextNode('x')]);
    },
  );

  test('standard JSON duplicate-key limitation remains explicit for F2.6', () {
    final decoded = jsonDecode('''
      {"kind":"chapterContent","version":1,
       "chapterRef":{"kind":"sourceChapterRef","version":1,"sourceId":"s","bookId":"b","chapterId":"c"},
       "nodes":[{"kind":"text","text":"first","text":"second"}]}
    ''');
    expect((decoded['nodes'] as List).single['text'], 'second');
    final value = ChapterContent.fromJson(decoded);
    expect(value.nodes, const [TextNode('second')]);
    // A duplicate-aware raw importer remains an F2.6 requirement.
  });
}
