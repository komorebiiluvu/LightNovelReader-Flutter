import 'dart:convert';

import 'package:html/dom.dart' as html_dom;
import 'package:html/parser.dart' as html_parser;

import '../charset/charset_models.dart';
import 'html_models.dart';

/// Parses an already decoded document and exposes only project-owned models.
final class HtmlDocumentParser {
  const HtmlDocumentParser({this.limits = const HtmlParserLimits()});

  final HtmlParserLimits limits;

  ParsedHtmlDocument parse(DecodedDocument input) {
    _validateDecodedText(input.text);

    final html_dom.Document document;
    try {
      document = html_parser.parse(input.text);
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
      traversedNodeCount: context.traversedNodes,
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
  if (node is html_dom.Element) {
    final tag = (node.localName ?? '').toLowerCase();
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
}

String _normalizeText(String value) =>
    value.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

final class _TraversalContext {
  _TraversalContext(this.limits);

  final HtmlParserLimits limits;
  final nodes = <ParsedHtmlNode>[];
  final title = StringBuffer();
  var traversedNodes = 0;

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
