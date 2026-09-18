import '../../domain/identity/opaque_ids.dart';
import '../../source/charset/charset.dart';
import '../../source/source_cancellation.dart';
import '../../source/source_operation.dart';
import '../../source/transport/source_http_models.dart';
import '../../source/transport/source_transport_policy.dart';
import 'wenku8_host_policy.dart';
import 'wenku8_request_models.dart';

final _sourceId = SourceId('builtin.wenku8');

/// Pure, synchronous construction of source-neutral request descriptions.
final class Wenku8RequestBuilder {
  Wenku8RequestBuilder({
    this._encoder = const CharsetEncoder(),
    this._hostPolicy = const Wenku8HostPolicy(),
  });

  final CharsetEncoder _encoder;
  final Wenku8HostPolicy _hostPolicy;

  Wenku8BuiltRequest buildSearch(
    Wenku8SearchIntent intent, {
    Uri? hostOverride,
  }) {
    final encoded = _legacyQuery(
      intent.query,
      'searchkey',
      SourceOperation.search,
    );
    final query = _joinQuery([
      'searchtype=articlename',
      encoded.queryPart,
      'page=${intent.page}',
    ]);
    return _build(
      operation: SourceOperation.search,
      path: '/modules/article/search.php',
      query: query,
      queryEvidence: Wenku8QueryEvidence(
        encodedQuery: query,
        fieldNames: const ['searchtype', 'searchkey', 'page'],
        legacyEncodedFields: const ['searchkey'],
        inputByteLength: encoded.byteLength,
      ),
      hostOverride: hostOverride,
    );
  }

  Wenku8BuiltRequest buildExplore(
    Wenku8ExploreIntent intent, {
    Uri? hostOverride,
  }) {
    if (intent.isHome) {
      if (intent.page != 1) {
        throw const Wenku8RequestBuildException(
          kind: Wenku8RequestFailureKind.invalidIntent,
          operation: 'explore',
        );
      }
      return _build(
        operation: SourceOperation.explore,
        path: '/index.php',
        query: '',
        queryEvidence: _emptyQuery,
        hostOverride: hostOverride,
      );
    }

    final category = intent.category;
    if (category != null) {
      final parts = <String>['page=${intent.page}'];
      if (category.parameter == 'fullflag') {
        parts.add('fullflag=1');
      } else if (category.parameter != null) {
        parts.add('sort=${category.parameter}');
      }
      final query = _joinQuery(parts);
      return _build(
        operation: SourceOperation.explore,
        path: '/${category.path}',
        query: query,
        queryEvidence: Wenku8QueryEvidence(
          encodedQuery: query,
          fieldNames: category.parameter == null
              ? const ['page']
              : const ['page', 'sort'],
          legacyEncodedFields: const [],
          inputByteLength: 0,
        ),
        hostOverride: hostOverride,
      );
    }

    final tag = intent.tag;
    if (tag == null) {
      throw const Wenku8RequestBuildException(
        kind: Wenku8RequestFailureKind.invalidIntent,
        operation: 'explore',
      );
    }
    final encoded = _legacyQuery(tag, 't', SourceOperation.explore);
    final query = _joinQuery(['page=${intent.page}', encoded.queryPart]);
    return _build(
      operation: SourceOperation.explore,
      path: '/modules/article/tags.php',
      query: query,
      queryEvidence: Wenku8QueryEvidence(
        encodedQuery: query,
        fieldNames: const ['page', 't'],
        legacyEncodedFields: const ['t'],
        inputByteLength: encoded.byteLength,
      ),
      hostOverride: hostOverride,
    );
  }

  Wenku8BuiltRequest buildBookDetail(
    Wenku8BookDetailIntent intent, {
    Uri? hostOverride,
  }) => _build(
    operation: SourceOperation.bookDetail,
    path: '/book/${_pathSegment(intent.bookLocator)}.htm',
    query: '',
    queryEvidence: _emptyQuery,
    hostOverride: hostOverride,
  );

  Wenku8BuiltRequest buildCatalog(
    Wenku8CatalogIntent intent, {
    Uri? hostOverride,
  }) => _build(
    operation: SourceOperation.catalog,
    path:
        '/novel/${_pathSegment(intent.book.directory)}/${_pathSegment(intent.bookLocator)}/index.htm',
    query: '',
    queryEvidence: _emptyQuery,
    hostOverride: hostOverride,
  );

  Wenku8BuiltRequest buildChapterContent(
    Wenku8ChapterContentIntent intent, {
    Uri? hostOverride,
  }) => _build(
    operation: SourceOperation.chapterContent,
    path:
        '/novel/${_pathSegment(intent.book.directory)}/${_pathSegment(intent.book.bookLocator)}/${_pathSegment(intent.chapterLocator)}.htm',
    query: '',
    queryEvidence: _emptyQuery,
    hostOverride: hostOverride,
  );

  Wenku8BuiltRequest _build({
    required SourceOperation operation,
    required String path,
    required String query,
    required Wenku8QueryEvidence queryEvidence,
    required Uri? hostOverride,
  }) {
    final origin = _origin(operation, hostOverride);
    final uri = Uri.parse('$origin$path${query.isEmpty ? '' : '?$query'}');
    final request = SourceHttpRequest(
      sourceId: _sourceId,
      operation: operation,
      method: SourceHttpMethod.get,
      uri: uri,
      headers: SourceHttpHeaders(),
      policy: SourceTransportPolicy(),
      cancellation: SourceCancellation(),
      sessionGeneration: 0,
    );
    return Wenku8BuiltRequest(request: request, query: queryEvidence);
  }

  Uri _origin(SourceOperation operation, Uri? hostOverride) {
    try {
      return _hostPolicy.originFor(operation, hostOverride: hostOverride);
    } on FormatException catch (error) {
      final message = error.message.toString();
      final kind = message.contains('HTTPS')
          ? Wenku8RequestFailureKind.invalidScheme
          : message.contains('user-info')
          ? Wenku8RequestFailureKind.userInfoNotAllowed
          : Wenku8RequestFailureKind.invalidHost;
      throw Wenku8RequestBuildException(
        kind: kind,
        operation: operation.wireName,
      );
    }
  }

  _EncodedQueryPart _legacyQuery(
    String value,
    String field,
    SourceOperation operation,
  ) {
    try {
      final bytes = _encoder.encode(
        value,
        encoding: SourceEncoding.legacyCp936Compatible,
      );
      return _EncodedQueryPart(
        queryPart: '$field=${_percentEncode(bytes.bytes)}',
        byteLength: bytes.length,
      );
    } on CharsetEncodeException {
      throw Wenku8RequestBuildException(
        kind: Wenku8RequestFailureKind.unsupportedQueryCharacter,
        operation: operation.wireName,
      );
    }
  }
}

final _emptyQuery = Wenku8QueryEvidence(
  encodedQuery: '',
  fieldNames: <String>[],
  legacyEncodedFields: <String>[],
  inputByteLength: 0,
);

final class _EncodedQueryPart {
  const _EncodedQueryPart({required this.queryPart, required this.byteLength});

  final String queryPart;
  final int byteLength;
}

String _joinQuery(Iterable<String> parts) => parts.join('&');

String _pathSegment(String value) {
  validateWenku8OpaqueLocator(value, 'path segment');
  if (value == '.' || value == '..') {
    throw ArgumentError.value(value, 'path segment');
  }
  return Uri.encodeComponent(value);
}

String _percentEncode(Iterable<int> bytes) {
  const hex = '0123456789ABCDEF';
  final output = StringBuffer();
  for (final byte in bytes) {
    if (byte >= 0x41 && byte <= 0x5a ||
        byte >= 0x61 && byte <= 0x7a ||
        byte >= 0x30 && byte <= 0x39 ||
        byte == 0x2d ||
        byte == 0x2e ||
        byte == 0x5f ||
        byte == 0x7e) {
      output.writeCharCode(byte);
    } else {
      output
        ..write('%')
        ..write(hex[(byte >> 4) & 0xf])
        ..write(hex[byte & 0xf]);
    }
  }
  return output.toString();
}
