import '../../source/transport/source_http_models.dart';

/// The characterized Wenku8 exploration categories.
enum Wenku8ExploreCategory {
  all(path: 'modules/article/articlelist.php'),
  allVisit(path: 'modules/article/toplist.php', parameter: 'allvisit'),
  anime(path: 'modules/article/toplist.php', parameter: 'anime'),
  lastUpdate(path: 'modules/article/toplist.php', parameter: 'lastupdate'),
  postDate(path: 'modules/article/toplist.php', parameter: 'postdate'),
  completed(path: 'modules/article/articlelist.php', parameter: 'fullflag');

  const Wenku8ExploreCategory({required this.path, this.parameter});

  final String path;
  final String? parameter;
}

/// A search intent. The provider search type is frozen to the title search
/// used by the Legacy source; callers supply only the search text and page.
final class Wenku8SearchIntent {
  Wenku8SearchIntent({required this.query, this.page = 1}) {
    _validatePage(page);
    _validateText(query, 'query');
  }

  final String query;
  final int page;
}

/// A source-neutral description of a Wenku8 explore surface.
final class Wenku8ExploreIntent {
  Wenku8ExploreIntent.home({this.page = 1}) : category = null, tag = null {
    _validatePage(page);
  }

  Wenku8ExploreIntent.category(this.category, {this.page = 1}) : tag = null {
    _validatePage(page);
  }

  Wenku8ExploreIntent.tag(String tag, {this.page = 1})
    : category = null,
      tag = tag {
    _validatePage(page);
    _validateText(tag, 'tag');
  }

  final int page;
  final Wenku8ExploreCategory? category;
  final String? tag;

  bool get isHome => category == null && tag == null;
}

/// Opaque provider route evidence for a book's numeric directory.
///
/// Legacy evidence uses `novel/<directory>/<book>/...`. The directory is
/// supplied as already-characterized route data; this layer never parses or
/// normalizes the book locator.
final class Wenku8BookRoute {
  Wenku8BookRoute({required this.bookLocator, required this.directory}) {
    _validateOpaqueLocator(bookLocator, 'bookLocator');
    _validatePathSegment(directory, 'directory');
  }

  final String bookLocator;
  final String directory;
}

final class Wenku8BookDetailIntent {
  Wenku8BookDetailIntent({required this.bookLocator}) {
    _validateOpaqueLocator(bookLocator, 'bookLocator');
  }

  final String bookLocator;
}

final class Wenku8CatalogIntent {
  Wenku8CatalogIntent({required this.book}) : bookLocator = book.bookLocator;

  Wenku8CatalogIntent.fromParts({
    required String bookLocator,
    required String directory,
  }) : book = Wenku8BookRoute(bookLocator: bookLocator, directory: directory),
       bookLocator = bookLocator;

  final Wenku8BookRoute book;
  final String bookLocator;
}

final class Wenku8ChapterContentIntent {
  Wenku8ChapterContentIntent({
    required this.book,
    required this.chapterLocator,
  }) {
    _validateOpaqueLocator(chapterLocator, 'chapterLocator');
  }

  Wenku8ChapterContentIntent.fromParts({
    required String bookLocator,
    required String directory,
    required String chapterLocator,
  }) : book = Wenku8BookRoute(bookLocator: bookLocator, directory: directory),
       chapterLocator = chapterLocator {
    _validateOpaqueLocator(chapterLocator, 'chapterLocator');
  }

  final Wenku8BookRoute book;
  final String chapterLocator;
}

void _validatePage(int page) {
  if (page < 1) throw ArgumentError.value(page, 'page');
}

void _validateText(String value, String name) {
  if (value.contains('\u0000')) throw ArgumentError.value(value, name);
}

void _validatePathSegment(String value, String name) {
  if (value.isEmpty ||
      value == '.' ||
      value == '..' ||
      value.contains('/') ||
      value.contains('\\') ||
      value.contains('\u0000')) {
    throw ArgumentError.value(value, name);
  }
}

void _validateOpaqueLocator(String value, String name) {
  if (value.isEmpty || value.contains('\u0000')) {
    throw ArgumentError.value(value, name);
  }
}

/// Query evidence is retained for tests and review without making it part of
/// the source-neutral transport model. Its string form deliberately redacts
/// the actual query value.
final class Wenku8QueryEvidence {
  Wenku8QueryEvidence({
    required this.encodedQuery,
    required Iterable<String> fieldNames,
    required Iterable<String> legacyEncodedFields,
    required this.inputByteLength,
  }) : fieldNames = List<String>.unmodifiable(fieldNames),
       legacyEncodedFields = List<String>.unmodifiable(legacyEncodedFields);

  final String encodedQuery;
  final List<String> fieldNames;
  final List<String> legacyEncodedFields;
  final int inputByteLength;

  @override
  String toString() =>
      'Wenku8QueryEvidence(fields: $fieldNames, bytes: $inputByteLength)';
}

/// Builder output: a neutral request plus reviewed construction evidence.
final class Wenku8BuiltRequest {
  Wenku8BuiltRequest({required this.request, required this.query});

  final SourceHttpRequest request;
  final Wenku8QueryEvidence query;

  @override
  String toString() => 'Wenku8BuiltRequest(<request>, $query)';
}

enum Wenku8RequestFailureKind {
  invalidIntent,
  invalidHost,
  invalidScheme,
  userInfoNotAllowed,
  arbitraryUriNotAllowed,
  unsupportedQueryCharacter,
}

final class Wenku8RequestBuildException implements Exception {
  const Wenku8RequestBuildException({
    required this.kind,
    required this.operation,
  });

  final Wenku8RequestFailureKind kind;
  final String operation;

  @override
  String toString() =>
      'Wenku8RequestBuildException(${kind.name}, operation: $operation)';
}

void validateWenku8IntentText(String value, String name) =>
    _validateText(value, name);

void validateWenku8PathSegment(String value, String name) =>
    _validatePathSegment(value, name);

void validateWenku8OpaqueLocator(String value, String name) =>
    _validateOpaqueLocator(value, name);

void validateWenku8Page(int page) => _validatePage(page);
