import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../source/source_failure.dart';
import '../../source/source_cancellation.dart';
import '../../source/source_diagnostics.dart';
import '../../source/source_operation.dart';
import '../../source/transport/source_http_models.dart';
import '../../source/transport/source_transport.dart';
import '../../source/transport/source_transport_policy.dart';

/// Dio-backed implementation of the neutral [SourceTransport] contract.
///
/// The adapter disables Dio's automatic redirects and response decoding so
/// that security and byte-limit decisions remain explicit here.
final class DioSourceTransport implements SourceTransport {
  DioSourceTransport({Dio? dio, HttpClientAdapter? adapter})
    : _dio = dio ?? Dio() {
    if (adapter != null) _dio.httpClientAdapter = adapter;
    _dio.interceptors.clear(keepImplyContentTypeInterceptor: false);
    _dio.options.followRedirects = false;
    _dio.options.maxRedirects = 0;
    _dio.options.validateStatus = (_) => true;
  }

  final Dio _dio;

  @override
  Future<SourceHttpResponse> send(SourceHttpRequest request) async {
    request.cancellation.throwIfCancelled();
    final cancelToken = CancelToken();
    var deadlineHit = false;
    final deadline = Timer(request.policy.timeout.operation, () {
      deadlineHit = true;
      cancelToken.cancel(_deadlineMarker);
    });
    final removeCancellation = request.cancellation.addListener(
      () => cancelToken.cancel(),
    );
    final stopwatch = Stopwatch()..start();
    try {
      for (
        var attempt = 1;
        attempt <= request.policy.retry.maxAttempts;
        attempt++
      ) {
        request.cancellation.throwIfCancelled();
        try {
          final response = await _performWithRedirects(
            request,
            cancelToken,
            request.policy.redirects.normalizedFor(request.uri),
          );
          if (_shouldRetryResponse(request, response, attempt)) {
            await _waitBeforeRetry(request, attempt);
            continue;
          }
          return SourceHttpResponse(
            statusCode: response.statusCode,
            headers: response.headers,
            bodyBytes: response.bodyBytes,
            finalUri: response.finalUri,
            redirectHistory: response.redirectHistory,
            elapsed: stopwatch.elapsed,
          );
        } on _ResponseTooLarge {
          throw SourceFailure(
            code: SourceFailureCode.network,
            retryable: false,
            diagnostics: SourceFailureDiagnostics(
              operation: request.operation,
              attempt: attempt,
              retryCount: attempt - 1,
            ),
          );
        } on SourceFailure catch (failure) {
          if (!_shouldRetryFailure(request, failure, attempt)) rethrow;
          await _waitBeforeRetry(request, attempt);
        } on DioException catch (error) {
          final failure = _mapDioException(
            error,
            request,
            attempt: attempt,
            deadlineHit: deadlineHit,
          );
          if (!_shouldRetryFailure(request, failure, attempt)) throw failure;
          await _waitBeforeRetry(request, attempt);
        } catch (_) {
          final failure = SourceFailure(
            code: SourceFailureCode.network,
            retryable: true,
            diagnostics: SourceFailureDiagnostics(
              operation: request.operation,
              attempt: attempt,
              retryCount: attempt - 1,
            ),
          );
          if (!_shouldRetryFailure(request, failure, attempt)) throw failure;
          await _waitBeforeRetry(request, attempt);
        }
      }
      throw SourceFailure(
        code: SourceFailureCode.network,
        retryable: false,
        diagnostics: SourceFailureDiagnostics(
          operation: request.operation,
          attempt: request.policy.retry.maxAttempts,
          retryCount: request.policy.retry.maxAttempts - 1,
        ),
      );
    } finally {
      stopwatch.stop();
      deadline.cancel();
      removeCancellation();
    }
  }

  Future<_BufferedResponse> _performWithRedirects(
    SourceHttpRequest request,
    CancelToken cancelToken,
    SourceRedirectPolicy redirects,
  ) async {
    var uri = request.uri;
    var method = request.method;
    Uint8List? body = request.bodyBytes;
    var headers = request.headers;
    final history = <SourceRedirectHop>[];

    while (true) {
      final response = await _requestOnce(
        request,
        uri: uri,
        method: method,
        body: body,
        headers: headers,
        cancelToken: cancelToken,
      );
      final status = response.statusCode;
      final location = response.headers.first('location');
      final isRedirect = status >= 300 && status < 400;
      if (!isRedirect || redirects.mode == SourceRedirectMode.noFollow) {
        return _BufferedResponse(
          statusCode: status,
          headers: response.headers,
          bodyBytes: response.bodyBytes,
          finalUri: uri,
          redirectHistory: history,
        );
      }
      if (location == null ||
          location.isEmpty ||
          history.length >= redirects.maxRedirects) {
        throw _securityFailure(request);
      }
      late final Uri next;
      try {
        next = uri.resolve(location);
      } on FormatException {
        throw _securityFailure(request);
      }
      if ((next.scheme != 'http' && next.scheme != 'https') ||
          next.host.isEmpty ||
          next.userInfo.isNotEmpty ||
          (uri.scheme == 'https' && next.scheme != 'https') ||
          !redirects.allows(next, request.uri)) {
        throw _securityFailure(request);
      }
      history.add(SourceRedirectHop(uri: next, statusCode: status));
      if (!_sameOrigin(uri, next)) {
        headers = headers.without(const ['authorization', 'cookie']);
      }
      if (status == 301 || status == 302 || status == 303) {
        method = SourceHttpMethod.get;
        body = null;
        headers = headers.without(const ['content-length', 'content-type']);
      }
      uri = next;
    }
  }

  Future<_BufferedResponse> _requestOnce(
    SourceHttpRequest request, {
    required Uri uri,
    required SourceHttpMethod method,
    required Uint8List? body,
    required SourceHttpHeaders headers,
    required CancelToken cancelToken,
  }) async {
    request.cancellation.throwIfCancelled();
    final response = await _dio.requestUri<dynamic>(
      uri,
      data: body,
      cancelToken: cancelToken,
      options: Options(
        method: method.name,
        headers: headers.values.map(
          (name, values) =>
              MapEntry(name, values.length == 1 ? values.first : values),
        ),
        responseType: ResponseType.stream,
        connectTimeout: request.policy.timeout.connect,
        sendTimeout: request.policy.timeout.send,
        receiveTimeout: request.policy.timeout.receive,
        transformTimeout: request.policy.timeout.receive,
        followRedirects: false,
        maxRedirects: 0,
        validateStatus: (_) => true,
        receiveDataWhenStatusError: true,
      ),
    );
    final status = response.statusCode;
    if (status == null) throw SourceFailure(code: SourceFailureCode.network);
    final responseHeaders = SourceHttpHeaders(values: response.headers.map);
    final bytes = await _readBytes(
      response.data,
      request.policy.maxResponseBytes,
      request.cancellation,
    );
    return _BufferedResponse(
      statusCode: status,
      headers: responseHeaders,
      bodyBytes: bytes,
      finalUri: uri,
      redirectHistory: const [],
    );
  }

  Future<Uint8List> _readBytes(
    Object? data,
    int maximum,
    SourceCancellation cancellation,
  ) async {
    if (data == null) return Uint8List(0);
    if (data is ResponseBody) {
      final builder = BytesBuilder(copy: false);
      try {
        await for (final chunk in data.stream) {
          cancellation.throwIfCancelled();
          if (builder.length + chunk.length > maximum) {
            throw _ResponseTooLarge();
          }
          builder.add(chunk);
        }
        return builder.takeBytes();
      } finally {
        // Consuming the response stream releases the adapter-owned response.
      }
    }
    if (data is List<int>) {
      if (data.length > maximum) throw _ResponseTooLarge();
      return Uint8List.fromList(data);
    }
    throw SourceFailure(code: SourceFailureCode.network);
  }

  Future<void> _waitBeforeRetry(SourceHttpRequest request, int attempt) async {
    request.cancellation.throwIfCancelled();
    final delay = request.policy.retry.delayForRetry(attempt);
    if (delay == Duration.zero) return;
    final completer = Completer<void>();
    void Function() remove = () {};
    final timer = Timer(delay, () {
      if (!completer.isCompleted) completer.complete();
      remove();
    });
    remove = request.cancellation.addListener(() {
      timer.cancel();
      if (!completer.isCompleted) {
        completer.completeError(SourceFailure.cancelled());
      }
      remove();
    });
    try {
      await completer.future;
    } finally {
      timer.cancel();
      remove();
    }
  }

  bool _shouldRetryResponse(
    SourceHttpRequest request,
    _BufferedResponse response,
    int attempt,
  ) {
    if (!_canRetry(request, attempt)) return false;
    return response.statusCode == 408 ||
        response.statusCode == 425 ||
        response.statusCode == 429 ||
        response.statusCode >= 500;
  }

  bool _shouldRetryFailure(
    SourceHttpRequest request,
    SourceFailure failure,
    int attempt,
  ) =>
      _canRetry(request, attempt) &&
      failure.code == SourceFailureCode.network &&
      failure.retryable;

  bool _canRetry(SourceHttpRequest request, int attempt) =>
      attempt < request.policy.retry.maxAttempts &&
      request.method.isIdempotent &&
      request.operation != SourceOperation.authentication;

  SourceFailure _mapDioException(
    DioException error,
    SourceHttpRequest request, {
    required int attempt,
    required bool deadlineHit,
  }) {
    if (error.type == DioExceptionType.cancel) {
      if (deadlineHit) {
        return SourceFailure(
          code: SourceFailureCode.network,
          retryable: false,
          diagnostics: SourceFailureDiagnostics(
            operation: request.operation,
            attempt: attempt,
            retryCount: attempt - 1,
          ),
        );
      }
      return SourceFailure.cancelled();
    }
    if (error.type == DioExceptionType.badCertificate) {
      return _securityFailure(request);
    }
    return SourceFailure(
      code: SourceFailureCode.network,
      retryable: true,
      diagnostics: SourceFailureDiagnostics(
        operation: request.operation,
        attempt: attempt,
        retryCount: attempt - 1,
      ),
    );
  }

  SourceFailure _securityFailure(SourceHttpRequest request) => SourceFailure(
    code: SourceFailureCode.securityPolicy,
    retryable: false,
    diagnostics: SourceFailureDiagnostics(operation: request.operation),
  );

  bool _sameOrigin(Uri left, Uri right) =>
      left.scheme.toLowerCase() == right.scheme.toLowerCase() &&
      left.host.toLowerCase() == right.host.toLowerCase() &&
      _effectivePort(left) == _effectivePort(right);

  int _effectivePort(Uri uri) =>
      uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 80);
}

final class _BufferedResponse {
  const _BufferedResponse({
    required this.statusCode,
    required this.headers,
    required this.bodyBytes,
    required this.finalUri,
    required this.redirectHistory,
  });

  final int statusCode;
  final SourceHttpHeaders headers;
  final Uint8List bodyBytes;
  final Uri finalUri;
  final List<SourceRedirectHop> redirectHistory;
}

final class _ResponseTooLarge implements Exception {}

const _deadlineMarker = #deadline;
