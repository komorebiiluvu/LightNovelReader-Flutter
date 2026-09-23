import '../../source/parser/source_parsed_models.dart';
import '../../source/source_operation.dart';

enum Wenku8ParseFailureKind {
  parse,
  incompatibleResponse,
  authenticationRequired,
  unavailable,
}

enum Wenku8ParseField { title }

enum Wenku8ParseReason {
  waf('waf'),
  missingResults('missing-results'),
  blockTitle('block-title'),
  blockContent('block-content'),
  blockId('block-id'),
  pagination('pagination'),
  duplicateChapterId('duplicate-chapter-id'),
  missingCatalog('missing-catalog'),
  malformedDom('malformed-dom'),
  missingContentContainer('missing-content-container'),
  missingBookHref('missing-book-href');

  const Wenku8ParseReason(this.wireName);
  final String wireName;
}

/// Fixed diagnostic fields; HTML, titles, locators and server text never escape.
final class Wenku8ParseException implements Exception {
  const Wenku8ParseException({
    required this.operation,
    required this.kind,
    this.field,
    this.reason,
    this.itemIndex,
  });

  final SourceOperation operation;
  final Wenku8ParseFailureKind kind;
  final Wenku8ParseField? field;
  final Wenku8ParseReason? reason;
  final int? itemIndex;

  @override
  String toString() =>
      'Wenku8ParseException(${operation.wireName}, ${kind.name}, '
      'field: ${field?.name ?? 'none'}, reason: ${reason?.wireName ?? 'none'}, '
      'item: ${itemIndex ?? -1})';
}

final class Wenku8ExploreContext {
  Wenku8ExploreContext({
    required this.descriptor,
    this.blockId,
    this.blockTitle,
    this.pagination,
    Map<String, String> selections = const {},
  }) : selections = Map<String, String>.unmodifiable(selections);

  final String descriptor;
  final String? blockId;
  final String? blockTitle;
  final SourceParsedPagination? pagination;
  final Map<String, String> selections;
}
