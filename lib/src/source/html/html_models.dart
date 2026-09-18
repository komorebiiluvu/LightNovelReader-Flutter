/// Safe categories for failures at the HTML foundation boundary.
enum HtmlParserFailureKind {
  traversalLimitExceeded,
  producedNodeLimitExceeded,
  textPayloadLimitExceeded,
  invalidDecodedDocument,
  malformedStructure,
  internalParserFailure,
}

final class HtmlParserFailureInfo {
  const HtmlParserFailureInfo({
    required this.kind,
    this.limitName,
    this.depth,
    this.traversedNodes,
    this.producedNodes,
  });

  final HtmlParserFailureKind kind;
  final String? limitName;
  final int? depth;
  final int? traversedNodes;
  final int? producedNodes;

  @override
  bool operator ==(Object other) =>
      other is HtmlParserFailureInfo &&
      other.kind == kind &&
      other.limitName == limitName &&
      other.depth == depth &&
      other.traversedNodes == traversedNodes &&
      other.producedNodes == producedNodes;

  @override
  int get hashCode =>
      Object.hash(kind, limitName, depth, traversedNodes, producedNodes);
}

/// A typed parser failure that never includes DOM objects or HTML content.
final class HtmlParserException implements Exception {
  const HtmlParserException(this.info);

  final HtmlParserFailureInfo info;

  @override
  String toString() {
    final details = <String>[
      info.kind.name,
      if (info.limitName != null) info.limitName!,
      if (info.depth != null) 'depth=${info.depth}',
      if (info.traversedNodes != null) 'traversed=${info.traversedNodes}',
      if (info.producedNodes != null) 'produced=${info.producedNodes}',
    ];
    return 'HtmlParserException(${details.join(', ')})';
  }
}

/// Immutable, injectable resource limits for DOM traversal normalization.
final class HtmlParserLimits {
  const HtmlParserLimits({
    this.maxTraversalDepth = 64,
    this.maxTraversedNodes = 100000,
    this.maxProducedNodes = 100000,
    this.maxTextPayloadBytes = 1024 * 1024,
  }) : assert(maxTraversalDepth >= 0),
       assert(maxTraversedNodes > 0),
       assert(maxProducedNodes > 0),
       assert(maxTextPayloadBytes > 0);

  final int maxTraversalDepth;
  final int maxTraversedNodes;
  final int maxProducedNodes;
  final int maxTextPayloadBytes;
}

/// A source-neutral ordered intermediate document.
///
/// [nodes] is a flattened pre-order sequence. Each node keeps its DOM depth,
/// preserving order and enough nesting information for later source adapters
/// without exposing package:html DOM objects.
final class ParsedHtmlDocument {
  ParsedHtmlDocument({
    required this.titleEvidence,
    required List<ParsedHtmlNode> nodes,
    required this.traversedNodeCount,
  }) : nodes = List<ParsedHtmlNode>.unmodifiable(nodes);

  final String? titleEvidence;
  final List<ParsedHtmlNode> nodes;
  final int traversedNodeCount;

  @override
  String toString() =>
      'ParsedHtmlDocument(title: ${titleEvidence == null ? 'absent' : 'present'}, '
      'nodes: ${nodes.length}, traversed: $traversedNodeCount)';
}

sealed class ParsedHtmlNode {
  const ParsedHtmlNode({required this.depth});

  final int depth;
}

final class ParsedHtmlText extends ParsedHtmlNode {
  const ParsedHtmlText({required this.text, required super.depth});

  final String text;

  @override
  String toString() => 'ParsedHtmlText(depth: $depth)';
}

final class ParsedHtmlImage extends ParsedHtmlNode {
  const ParsedHtmlImage({required this.rawLocator, required super.depth});

  final String rawLocator;

  @override
  String toString() => 'ParsedHtmlImage(depth: $depth)';
}

final class ParsedHtmlLink extends ParsedHtmlNode {
  const ParsedHtmlLink({required this.rawLocator, required super.depth});

  final String rawLocator;

  @override
  String toString() => 'ParsedHtmlLink(depth: $depth)';
}
