import 'dart:convert';

import 'package:html/dom.dart' as html_dom;
import 'package:html/parser.dart' as html_parser;

import '../charset/charset_models.dart';
import 'html_models.dart';

/// Parses an already decoded document and exposes only project-owned models.
final class HtmlDocumentParser {
  const HtmlDocumentParser({this.limits = const HtmlParserLimits()});

  final HtmlParserLimits limits;

  ParsedHtmlDocument parse(DecodedDocument input) => _parse(input);

  /// HTML fragment parsing preserves context-sensitive elements such as `td`.
  /// The caller chooses a standard HTML container; no provider selector or
  /// package DOM escapes this boundary.
  ParsedHtmlDocument parseFragment(
    DecodedDocument input, {
    String container = 'div',
  }) => _parse(input, fragmentContainer: container);

  ParsedHtmlDocument _parse(
    DecodedDocument input, {
    String? fragmentContainer,
  }) {
    _validateDecodedText(input.text);

    final html_dom.Node document;
    final html_parser.HtmlParser parser;
    try {
      parser = html_parser.HtmlParser(input.text);
      document = fragmentContainer == null
          ? parser.parse()
          : parser.parseFragment(fragmentContainer);
    } catch (_) {
      throw const HtmlParserException(
        HtmlParserFailureInfo(kind: HtmlParserFailureKind.malformedStructure),
      );
    }

    final context = _TraversalContext(limits);
    try {
      _visit(context, document, -2, inTitle: false);
    } on HtmlParserException {
      rethrow;
    } catch (_) {
      throw const HtmlParserException(
        HtmlParserFailureInfo(
          kind: HtmlParserFailureKind.internalParserFailure,
        ),
      );
    }

    final title = context.title.toString();
    return ParsedHtmlDocument(
      titleEvidence: title.isEmpty ? null : title,
      nodes: context.nodes,
      elements: context.elements,
      traversedNodeCount: context.traversedNodes,
      parseErrorCount: parser.errors.length,
    );
  }
}

void _validateDecodedText(String text) {
  final units = text.codeUnits;
  for (var index = 0; index < units.length; index++) {
    final unit = units[index];
    if (unit >= 0xd800 && unit <= 0xdbff) {
      if (index + 1 >= units.length ||
          units[index + 1] < 0xdc00 ||
          units[index + 1] > 0xdfff) {
        throw const HtmlParserException(
          HtmlParserFailureInfo(
            kind: HtmlParserFailureKind.invalidDecodedDocument,
          ),
        );
      }
      index++;
    } else if (unit >= 0xdc00 && unit <= 0xdfff) {
      throw const HtmlParserException(
        HtmlParserFailureInfo(
          kind: HtmlParserFailureKind.invalidDecodedDocument,
        ),
      );
    }
  }
}

void _visit(
  _TraversalContext context,
  html_dom.Node node,
  int depth, {
  required bool inTitle,
}) {
  final actualDepth = depth + 1;
  if (actualDepth > context.limits.maxTraversalDepth) {
    throw HtmlParserException(
      HtmlParserFailureInfo(
        kind: HtmlParserFailureKind.traversalLimitExceeded,
        limitName: 'maxTraversalDepth',
        depth: actualDepth,
        traversedNodes: context.traversedNodes,
        producedNodes: context.nodes.length,
      ),
    );
  }

  context.traversedNodes++;
  if (context.traversedNodes > context.limits.maxTraversedNodes) {
    throw HtmlParserException(
      HtmlParserFailureInfo(
        kind: HtmlParserFailureKind.traversalLimitExceeded,
        limitName: 'maxTraversedNodes',
        depth: actualDepth,
        traversedNodes: context.traversedNodes,
        producedNodes: context.nodes.length,
      ),
    );
  }

  var childInTitle = inTitle;
  int? elementIndex;
  if (node is html_dom.Element) {
    final tag = (node.localName ?? '').toLowerCase();
    elementIndex = context.beginElement(
      tag: tag,
      attributes: node.attributes.map(
        (name, value) => MapEntry(name.toString().toLowerCase(), value),
      ),
      depth: actualDepth,
    );
    childInTitle = inTitle || tag == 'title';
    if (tag == 'img') {
      final locator = node.attributes['src'];
      if (locator != null) {
        context.add(ParsedHtmlImage(rawLocator: locator, depth: actualDepth));
      }
    } else if (tag == 'a') {
      final locator = node.attributes['href'];
      if (locator != null) {
        context.add(ParsedHtmlLink(rawLocator: locator, depth: actualDepth));
      }
    }
  } else if (node is html_dom.Text) {
    final text = _normalizeText(node.data);
    if (utf8.encode(text).length > context.limits.maxTextPayloadBytes) {
      throw HtmlParserException(
        HtmlParserFailureInfo(
          kind: HtmlParserFailureKind.textPayloadLimitExceeded,
          limitName: 'maxTextPayloadBytes',
          depth: actualDepth,
          traversedNodes: context.traversedNodes,
          producedNodes: context.nodes.length,
        ),
      );
    }
    if (childInTitle) context.title.write(text);
    if (text.isNotEmpty) {
      context.add(ParsedHtmlText(text: text, depth: actualDepth));
    }
  }

  for (final child in node.nodes) {
    _visit(context, child, actualDepth, inTitle: childInTitle);
  }
  if (elementIndex != null) context.endElement(elementIndex);
}

String _normalizeText(String value) =>
    value.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

final class _TraversalContext {
  _TraversalContext(this.limits);

  final HtmlParserLimits limits;
  final nodes = <ParsedHtmlNode>[];
  final _elements = <_MutableElement>[];
  final title = StringBuffer();
  var traversedNodes = 0;

  List<ParsedHtmlElement> get elements => List.unmodifiable(
    _elements.map(
      (element) => ParsedHtmlElement(
        tag: element.tag,
        attributes: element.attributes,
        depth: element.depth,
        startNodeIndex: element.startNodeIndex,
        endNodeIndex: element.endNodeIndex ?? nodes.length,
      ),
    ),
  );

  int beginElement({
    required String tag,
    required Map<String, String> attributes,
    required int depth,
  }) {
    _elements.add(
      _MutableElement(
        tag: tag,
        attributes: attributes,
        depth: depth,
        startNodeIndex: nodes.length,
      ),
    );
    return _elements.length - 1;
  }

  void endElement(int index) => _elements[index].endNodeIndex = nodes.length;

  void add(ParsedHtmlNode node) {
    nodes.add(node);
    if (nodes.length > limits.maxProducedNodes) {
      throw HtmlParserException(
        HtmlParserFailureInfo(
          kind: HtmlParserFailureKind.producedNodeLimitExceeded,
          limitName: 'maxProducedNodes',
          traversedNodes: traversedNodes,
          producedNodes: nodes.length,
        ),
      );
    }
  }
}

final class _MutableElement {
  _MutableElement({
    required this.tag,
    required this.attributes,
    required this.depth,
    required this.startNodeIndex,
  });

  final String tag;
  final Map<String, String> attributes;
  final int depth;
  final int startNodeIndex;
  int? endNodeIndex;
}
