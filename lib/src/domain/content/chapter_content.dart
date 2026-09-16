import '../identity/identity_failure.dart';
import '../identity/identity_json.dart';
import '../identity/source_refs.dart';

/// A successfully normalized chapter represented by one ordered node sequence.
final class ChapterContent {
  ChapterContent({
    required this.chapterRef,
    required List<ContentNode> nodes,
    this.title,
  }) : _nodes = List<ContentNode>.unmodifiable(nodes) {
    for (final node in _nodes) {
      if (node is ImageNode &&
          (node.assetRef.sourceId != chapterRef.sourceId ||
              node.assetRef.bookId != chapterRef.bookId)) {
        throw IdentityFailure(IdentityFailureReason.invalidValue);
      }
    }
  }

  factory ChapterContent.fromJson(Object? input) {
    final fields = readIdentityV1(
      input,
      kind: 'chapterContent',
      requiredFields: {'chapterRef', 'nodes'},
      optionalFields: {'title'},
    );
    final nodes = fields['nodes'];
    if (nodes is! List) {
      throw IdentityFailure(IdentityFailureReason.wrongType);
    }
    return ChapterContent(
      chapterRef: SourceChapterRef.fromJson(fields['chapterRef']),
      title: optionalIdentityString(fields, 'title'),
      nodes: nodes.map(ContentNode.fromJson).toList(growable: false),
    );
  }

  final SourceChapterRef chapterRef;
  final String? title;
  final List<ContentNode> _nodes;

  /// An unmodifiable, order-preserving view of the canonical node sequence.
  List<ContentNode> get nodes => _nodes;

  Map<String, Object?> toJson() => {
    'kind': 'chapterContent',
    'version': 1,
    'chapterRef': chapterRef.toJson(),
    if (title != null) 'title': title,
    'nodes': _nodes.map((node) => node.toJson()).toList(growable: false),
  };

  @override
  bool operator ==(Object other) =>
      other is ChapterContent &&
      chapterRef == other.chapterRef &&
      title == other.title &&
      _orderedEquals(_nodes, other._nodes);

  @override
  int get hashCode => Object.hash(chapterRef, title, Object.hashAll(_nodes));

  @override
  String toString() => 'ChapterContent(<opaque>, nodes: ${_nodes.length})';
}

/// The only canonical v1 content node variants.
sealed class ContentNode {
  const ContentNode();

  factory ContentNode.fromJson(Object? input) {
    final fields = readContentNodeObject(input);
    if (!fields.containsKey('kind')) {
      throw IdentityFailure(IdentityFailureReason.missingField);
    }
    return switch (identityString(fields['kind'])) {
      'text' => TextNode.fromJson(fields),
      'image' => ImageNode.fromJson(fields),
      _ => throw IdentityFailure(IdentityFailureReason.wrongKind),
    };
  }

  Map<String, Object?> toJson();
}

final class TextNode extends ContentNode {
  const TextNode(this.text);

  factory TextNode.fromJson(Object? input) {
    final fields = readContentNodeV1(
      input,
      kind: 'text',
      requiredFields: {'text'},
    );
    return TextNode(identityString(fields['text']));
  }

  final String text;

  @override
  Map<String, Object?> toJson() => {'kind': 'text', 'text': text};

  @override
  bool operator ==(Object other) => other is TextNode && text == other.text;

  @override
  int get hashCode => Object.hash(runtimeType, text);

  @override
  String toString() => 'TextNode(<opaque>)';
}

final class ImageNode extends ContentNode {
  const ImageNode({required this.assetRef, this.altText});

  factory ImageNode.fromJson(Object? input) {
    final fields = readContentNodeV1(
      input,
      kind: 'image',
      requiredFields: {'assetRef'},
      optionalFields: {'altText'},
    );
    return ImageNode(
      assetRef: SourceAssetRef.fromJson(fields['assetRef']),
      altText: optionalIdentityString(fields, 'altText'),
    );
  }

  final SourceAssetRef assetRef;
  final String? altText;

  @override
  Map<String, Object?> toJson() => {
    'kind': 'image',
    'assetRef': assetRef.toJson(),
    if (altText != null) 'altText': altText,
  };

  @override
  bool operator ==(Object other) =>
      other is ImageNode &&
      assetRef == other.assetRef &&
      altText == other.altText;

  @override
  int get hashCode => Object.hash(runtimeType, assetRef, altText);

  @override
  String toString() => 'ImageNode(<opaque>)';
}

Map<String, Object?> readContentNodeObject(Object? input) {
  if (input is! Map || input.keys.any((key) => key is! String)) {
    throw IdentityFailure(IdentityFailureReason.wrongType);
  }
  return Map<String, Object?>.from(input);
}

Map<String, Object?> readContentNodeV1(
  Object? input, {
  required String kind,
  required Set<String> requiredFields,
  Set<String> optionalFields = const {},
}) {
  final fields = readContentNodeObject(input);
  if (!fields.containsKey('kind')) {
    throw IdentityFailure(IdentityFailureReason.missingField);
  }
  if (identityString(fields['kind']) != kind) {
    throw IdentityFailure(IdentityFailureReason.wrongKind);
  }
  for (final field in requiredFields) {
    if (!fields.containsKey(field)) {
      throw IdentityFailure(IdentityFailureReason.missingField);
    }
  }
  final allowed = {'kind', ...requiredFields, ...optionalFields};
  if (fields.keys.any((key) => !allowed.contains(key))) {
    throw IdentityFailure(IdentityFailureReason.unknownField);
  }
  return fields;
}

bool _orderedEquals(List<ContentNode> left, List<ContentNode> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
