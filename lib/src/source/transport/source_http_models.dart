import 'dart:typed_data';

import '../../domain/identity/opaque_ids.dart';
import '../source_cancellation.dart';
import '../source_operation.dart';
import 'source_transport_policy.dart';

/// HTTP methods understood by the source-neutral transport boundary.
enum SourceHttpMethod {
  get('GET'),
  post('POST'),
  head('HEAD');

  const SourceHttpMethod(this.name);

  final String name;

  bool get isIdempotent => this == get || this == head;
}

/// Immutable, case-insensitive HTTP headers that retain repeated values.
final class SourceHttpHeaders {
  SourceHttpHeaders._(Map<String, List<String>> values)
    : _values = Map<String, List<String>>.unmodifiable(
        values.map(
          (name, entries) => MapEntry(
            _normalizeName(name),
            List<String>.unmodifiable(entries),
          ),
        ),
      );

  factory SourceHttpHeaders({Map<String, List<String>> values = const {}}) {
    final normalized = <String, List<String>>{};
    for (final entry in values.entries) {
      final name = _normalizeName(entry.key);
      _validateName(name);
      for (final value in entry.value) {
        _validateValue(value);
      }
      normalized.putIfAbsent(name, () => <String>[]).addAll(entry.value);
    }
    return SourceHttpHeaders._(normalized);
  }

  factory SourceHttpHeaders.fromSingleValue(Map<String, String> values) =>
      SourceHttpHeaders(
        values: values.map((name, value) => MapEntry(name, <String>[value])),
      );

  final Map<String, List<String>> _values;

  Map<String, List<String>> get values => _values;

  Iterable<String> names() => _values.keys;

  List<String> valuesFor(String name) =>
      _values[_normalizeName(name)] ?? const <String>[];

  String? first(String name) {
    final values = valuesFor(name);
    return values.isEmpty ? null : values.first;
  }

  bool contains(String name) => _values.containsKey(_normalizeName(name));

  SourceHttpHeaders without(Iterable<String> names) {
    final excluded = names.map(_normalizeName).toSet();
    return SourceHttpHeaders._(
      Map<String, List<String>>.fromEntries(
        _values.entries
            .where((entry) => !excluded.contains(entry.key))
            .map((entry) => MapEntry(entry.key, entry.value)),
      ),
    );
  }

  SourceHttpHeaders withValue(String name, String value) {
    final normalized = _normalizeName(name);
    _validateName(normalized);
    _validateValue(value);
    return SourceHttpHeaders._({
      ..._values,
      normalized: <String>[value],
    });
  }

  @override
  String toString() => 'SourceHttpHeaders(${_values.keys.toList()})';
}

/// A safe redirect record. It intentionally contains no request/response
/// headers or bodies.
final class SourceRedirectHop {
  const SourceRedirectHop({required this.uri, required this.statusCode});

  final Uri uri;
  final int statusCode;

  @override
  String toString() => 'SourceRedirectHop($statusCode, <uri>)';
}

/// A raw transport response. Bytes are never decoded at this boundary.
final class SourceHttpResponse {
  SourceHttpResponse({
    required this.statusCode,
    required this.headers,
    required List<int> bodyBytes,
    required this.finalUri,
    List<SourceRedirectHop> redirectHistory = const [],
    this.elapsed,
  }) : bodyBytes = Uint8List.fromList(bodyBytes),
       redirectHistory = List<SourceRedirectHop>.unmodifiable(redirectHistory) {
    if (statusCode < 100 || statusCode > 599) {
      throw ArgumentError.value(statusCode, 'statusCode');
    }
  }

  final int statusCode;
  final SourceHttpHeaders headers;
  final Uint8List bodyBytes;
  final Uri finalUri;
  final List<SourceRedirectHop> redirectHistory;
  final Duration? elapsed;

  Uint8List get bytes => bodyBytes;

  @override
  String toString() =>
      'SourceHttpResponse($statusCode, ${bodyBytes.length} bytes, <uri>)';
}

/// One source-neutral HTTP request.
final class SourceHttpRequest {
  SourceHttpRequest({
    required this.sourceId,
    required this.operation,
    required this.method,
    required this.uri,
    required this.headers,
    List<int>? bodyBytes,
    required this.policy,
    required this.cancellation,
    required this.sessionGeneration,
  }) : bodyBytes = bodyBytes == null ? null : Uint8List.fromList(bodyBytes) {
    if ((uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      throw ArgumentError.value(uri, 'uri');
    }
    if (sessionGeneration < 0) {
      throw ArgumentError.value(sessionGeneration, 'sessionGeneration');
    }
    if (method == SourceHttpMethod.get || method == SourceHttpMethod.head) {
      if (this.bodyBytes != null && this.bodyBytes!.isNotEmpty) {
        throw ArgumentError('GET and HEAD requests cannot carry a body.');
      }
    }
  }

  final SourceId sourceId;
  final SourceOperation operation;
  final SourceHttpMethod method;
  final Uri uri;
  final SourceHttpHeaders headers;
  final Uint8List? bodyBytes;
  final SourceTransportPolicy policy;
  final SourceCancellation cancellation;
  final int sessionGeneration;

  @override
  String toString() =>
      'SourceHttpRequest(${sourceId.runtimeType}(<opaque>), '
      '${method.name}, <uri>, ${bodyBytes?.length ?? 0} bytes)';
}

String _normalizeName(String name) => name.trim().toLowerCase();

void _validateName(String name) {
  if (name.isEmpty || name.contains(RegExp(r'[\s():<>@,;\\"/\[\]?={}\t]'))) {
    throw ArgumentError.value(name, 'header name');
  }
}

void _validateValue(String value) {
  if (value.contains(RegExp(r'[\u0000\r\n]'))) {
    throw ArgumentError.value(value, 'header value');
  }
}
