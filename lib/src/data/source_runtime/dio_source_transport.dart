import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../source/session/source_session.dart';
import '../../source/source_cancellation.dart';
import '../../source/source_diagnostics.dart';
import '../../source/source_failure.dart';
import '../../source/source_operation.dart';
import '../../source/transport/source_http_models.dart';
import '../../source/transport/source_transport.dart';
import '../../source/transport/source_transport_policy.dart';

/// Dio-backed implementation of the neutral [SourceTransport] contract.
///
/// Redirects, cookies, retries, deadlines and response limits are controlled
/// here. Dio remains an I/O mechanism and never owns Source session state.
final class DioSourceTransport implements SourceTransport {
  DioSourceTransport({
    Dio? dio,
    HttpClientAdapter? adapter,
    this._sessionAuthority,
  }) : _dio = dio ?? Dio() {
    if (adapter != null) _dio.httpClientAdapter = adapter;
    _dio.interceptors.clear(keepImplyContentTypeInterceptor: false);
    _dio.options.followRedirects = false;
    _dio.options.maxRedirects = 0;
    _dio.options.validateStatus = (_) => true;
  }

  final Dio _dio;
  final SourceSessionAuthority? _sessionAuthority;
  final Map<String, _TransportCapacityGate> _capacityGates = {};

  @override
  Future<SourceHttpResponse> send(SourceHttpRequest request) async {
    request.cancellation.throwIfCancelled();
    final stopwatch = Stopwatch()..start();
    final gate = _capacityGates.putIfAbsent(
      _capacityKey(request.policy.capacity),
      () => _TransportCapacityGate(request.policy.capacity),
    );
    final permit = await gate.acquire(request, stopwatch);
    try {
      return await _sendWithPermit(request, stopwatch);
    } finally {
      permit.release();
      stopwatch.stop();
    }
  }

  Future<SourceHttpResponse> _sendWithPermit(
    SourceHttpRequest request,
    Stopwatch stopwatch,
  ) async {
    final remaining = _remaining(request, stopwatch);
    if (remaining <= Duration.zero) throw _deadlineFailure(request, 1);
    final cancelToken = CancelToken();
    var deadlineHit = false;
    final deadline = Timer(remaining, () {
      deadlineHit = true;
      cancelToken.cancel(_deadlineMarker);
    });
    final removeCancellation = request.cancellation.addListener(
      () => cancelToken.cancel(),
    );
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
            () => deadlineHit,
          );
          if (_shouldRetryResponse(request, response, attempt)) {
            await _waitBeforeRetry(
              request,
              attempt,
              stopwatch,
              _retryAfterDelay(request, response, attempt),
            );
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
        } on _OperationDeadline {
          throw _deadlineFailure(request, attempt);
        } on SourceFailure catch (failure) {
          if (!_shouldRetryFailure(request, failure, attempt)) rethrow;
          await _waitBeforeRetry(
            request,
            attempt,
            stopwatch,
            request.policy.retry.delayForRetry(attempt),
          );
        } on DioException catch (error) {
          final failure = _mapDioException(
            error,
            request,
            attempt: attempt,
            deadlineHit: deadlineHit,
          );
          if (!_shouldRetryFailure(request, failure, attempt)) throw failure;
          await _waitBeforeRetry(
            request,
            attempt,
            stopwatch,
            request.policy.retry.delayForRetry(attempt),
          );
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
          await _waitBeforeRetry(
            request,
            attempt,
            stopwatch,
            request.policy.retry.delayForRetry(attempt),
          );
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
      deadline.cancel();
      removeCancellation();
    }
  }

  Future<_BufferedResponse> _performWithRedirects(
    SourceHttpRequest request,
    CancelToken cancelToken,
    SourceRedirectPolicy redirects,
    bool Function() deadlineExpired,
  ) async {
    var uri = request.uri;
    var method = request.method;
    Uint8List? body = request.bodyBytes;
    var headers = request.headers;
    final history = <SourceRedirectHop>[];

    while (true) {
      _ensureCurrent(request);
      headers = _headersForHop(request, uri, headers);
      final response = await _requestOnce(
        request,
        uri: uri,
        method: method,
        body: body,
        headers: headers,
        cancelToken: cancelToken,
        deadlineExpired: deadlineExpired,
      );
      final hopResponse = SourceHttpResponse(
        statusCode: response.statusCode,
        headers: response.headers,
        bodyBytes: response.bodyBytes,
        finalUri: uri,
        redirectHistory: history,
      );
      _commitSessionResponse(request, hopResponse);
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

  SourceHttpHeaders _headersForHop(
    SourceHttpRequest request,
    Uri uri,
    SourceHttpHeaders headers,
  ) {
    final binding = request.sessionBinding;
    if (binding == null) return headers.without(const ['cookie']);
    final authority = _sessionAuthority;
    if (authority == null) throw SourceFailure.invalidRequest();
    try {
      final cookie = authority.cookieHeader(binding, uri);
      final withoutCookie = headers.without(const ['cookie']);
      return cookie == null || cookie.isEmpty
          ? withoutCookie
          : withoutCookie.withValue('cookie', cookie);
    } on SourceFailure catch (failure) {
      if (failure.code == SourceFailureCode.invalidRequest) {
        throw SourceFailure.cancelled();
      }
      rethrow;
    }
  }

  void _ensureCurrent(SourceHttpRequest request) {
    final binding = request.sessionBinding;
    if (binding == null) return;
    final authority = _sessionAuthority;
    if (authority == null) throw SourceFailure.invalidRequest();
    if (!authority.isCurrent(binding)) throw SourceFailure.cancelled();
  }

  void _commitSessionResponse(
    SourceHttpRequest request,
    SourceHttpResponse response,
  ) {
    final binding = request.sessionBinding;
    if (binding == null) return;
    final authority = _sessionAuthority;
    if (authority == null) throw SourceFailure.invalidRequest();
    if (!authority.commitResponseCookies(
      binding,
      response.finalUri,
      response.headers,
    )) {
      throw SourceFailure.cancelled();
    }
  }

  Future<_BufferedResponse> _requestOnce(
    SourceHttpRequest request, {
    required Uri uri,
    required SourceHttpMethod method,
    required Uint8List? body,
    required SourceHttpHeaders headers,
    required CancelToken cancelToken,
    required bool Function() deadlineExpired,
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
      deadlineExpired,
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
    bool Function() deadlineExpired,
  ) async {
    if (data == null) return Uint8List(0);
    if (data is ResponseBody) {
      final builder = BytesBuilder(copy: false);
      await for (final chunk in data.stream) {
        cancellation.throwIfCancelled();
        if (deadlineExpired()) throw _OperationDeadline();
        if (builder.length + chunk.length > maximum) {
          throw _ResponseTooLarge();
        }
        builder.add(chunk);
      }
      return builder.takeBytes();
    }
    if (data is List<int>) {
      if (deadlineExpired()) throw _OperationDeadline();
      if (data.length > maximum) throw _ResponseTooLarge();
      return Uint8List.fromList(data);
    }
    throw SourceFailure(code: SourceFailureCode.network);
  }

  Future<void> _waitBeforeRetry(
    SourceHttpRequest request,
    int attempt,
    Stopwatch stopwatch,
    Duration requestedDelay,
  ) async {
    request.cancellation.throwIfCancelled();
    final remaining = _remaining(request, stopwatch);
    if (remaining <= Duration.zero) throw _deadlineFailure(request, attempt);
    final delay = requestedDelay > remaining ? remaining : requestedDelay;
    if (delay == Duration.zero) return;
    final deadlineWon = delay == remaining && requestedDelay > remaining;
    final completer = Completer<void>();
    void Function() remove = () {};
    final timer = Timer(delay, () {
      if (!completer.isCompleted) {
        if (deadlineWon) {
          completer.completeError(_deadlineFailure(request, attempt));
        } else {
          completer.complete();
        }
      }
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

  Duration _retryAfterDelay(
    SourceHttpRequest request,
    _BufferedResponse response,
    int attempt,
  ) {
    final normal = request.policy.retry.delayForRetry(attempt);
    final value = response.headers.first('retry-after')?.trim();
    if (value == null || value.isEmpty) return normal;
    final seconds = int.tryParse(value);
    if (seconds == null || seconds < 0) return normal;
    if (seconds > request.policy.retry.maxDelay.inSeconds) {
      return request.policy.retry.maxDelay;
    }
    return Duration(seconds: seconds);
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
      if (deadlineHit) return _deadlineFailure(request, attempt);
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

  SourceFailure _deadlineFailure(SourceHttpRequest request, int attempt) =>
      SourceFailure(
        code: SourceFailureCode.network,
        retryable: false,
        diagnostics: SourceFailureDiagnostics(
          operation: request.operation,
          attempt: attempt,
          retryCount: attempt > 0 ? attempt - 1 : 0,
        ),
      );

  SourceFailure _securityFailure(SourceHttpRequest request) => SourceFailure(
    code: SourceFailureCode.securityPolicy,
    retryable: false,
    diagnostics: SourceFailureDiagnostics(operation: request.operation),
  );

  Duration _remaining(SourceHttpRequest request, Stopwatch stopwatch) =>
      request.policy.timeout.operation - stopwatch.elapsed;

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

final class _OperationDeadline implements Exception {}

final class _TransportCapacityGate {
  _TransportCapacityGate(this.policy);

  final SourceTransportCapacityPolicy policy;
  var _active = 0;
  final List<_QueuedTransport> _queue = [];

  Future<_TransportPermit> acquire(
    SourceHttpRequest request,
    Stopwatch stopwatch,
  ) {
    request.cancellation.throwIfCancelled();
    if (_active < policy.maxConcurrentRequests) {
      _active++;
      return Future.value(_TransportPermit(this));
    }
    if (_queue.length >= policy.maxQueuedRequests) {
      return Future.error(_queueFailure(request));
    }
    final completer = Completer<_TransportPermit>();
    late final _QueuedTransport queued;
    Timer? deadlineTimer;
    void Function() removeCancellation = () {};
    void fail(SourceFailure failure) {
      if (completer.isCompleted) return;
      _queue.remove(queued);
      deadlineTimer?.cancel();
      removeCancellation();
      completer.completeError(failure);
    }

    queued = _QueuedTransport(completer, () {
      deadlineTimer?.cancel();
      removeCancellation();
    });
    _queue.add(queued);
    final remaining = request.policy.timeout.operation - stopwatch.elapsed;
    if (remaining <= Duration.zero) {
      fail(_deadlineFailureForQueue(request));
    } else {
      deadlineTimer = Timer(remaining, () {
        fail(_deadlineFailureForQueue(request));
      });
      removeCancellation = request.cancellation.addListener(() {
        fail(SourceFailure.cancelled());
      });
    }
    return completer.future;
  }

  void release() {
    if (_active > 0) _active--;
    while (_queue.isNotEmpty) {
      final queued = _queue.removeAt(0);
      if (queued.completer.isCompleted) continue;
      _active++;
      queued.cleanup();
      queued.completer.complete(_TransportPermit(this));
      break;
    }
  }
}

final class _QueuedTransport {
  const _QueuedTransport(this.completer, this.cleanup);

  final Completer<_TransportPermit> completer;
  final void Function() cleanup;
}

final class _TransportPermit {
  _TransportPermit(this._gate);

  final _TransportCapacityGate _gate;
  var _released = false;

  void release() {
    if (_released) return;
    _released = true;
    _gate.release();
  }
}

SourceFailure _queueFailure(SourceHttpRequest request) => SourceFailure(
  code: SourceFailureCode.network,
  retryable: false,
  diagnostics: SourceFailureDiagnostics(operation: request.operation),
);

SourceFailure _deadlineFailureForQueue(SourceHttpRequest request) =>
    SourceFailure(
      code: SourceFailureCode.network,
      retryable: false,
      diagnostics: SourceFailureDiagnostics(operation: request.operation),
    );

String _capacityKey(SourceTransportCapacityPolicy policy) =>
    '${policy.maxConcurrentRequests}:${policy.maxQueuedRequests}';

const _deadlineMarker = #deadline;
