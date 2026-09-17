import '../source_failure.dart';
import '../source_diagnostics.dart';
import 'source_http_models.dart';

/// Neutral transport boundary. Concrete HTTP libraries never cross this API.
abstract interface class SourceTransport {
  Future<SourceHttpResponse> send(SourceHttpRequest request);
}

SourceFailure transportFailure({
  required SourceFailureCode code,
  required SourceHttpRequest request,
  int? statusCode,
  int? attempt,
  int? retryCount,
  bool retryable = false,
  Duration? retryAfter,
}) => SourceFailure(
  code: code,
  retryable: retryable,
  retryAfter: retryAfter,
  diagnostics: SourceFailureDiagnostics(
    operation: request.operation,
    statusCode: statusCode,
    attempt: attempt,
    retryCount: retryCount,
  ),
);
