import 'source_capability.dart';
import 'source_diagnostics.dart';

/// Stable, source-neutral failure codes.
enum SourceFailureCode {
  network('network'),
  authentication('authentication'),
  rateLimit('rateLimit'),
  notFound('notFound'),
  parse('parse'),
  incompatibleResponse('incompatibleResponse'),
  cancelled('cancelled'),
  unsupportedCapability('unsupportedCapability'),
  sourceUnavailable('sourceUnavailable'),
  invalidRequest('invalidRequest'),
  securityPolicy('securityPolicy'),
  secureStorage('secureStorage');

  const SourceFailureCode(this.wireName);

  final String wireName;
}

/// The single public failure boundary for Source operations.
///
/// Diagnostics use the finite [SourceFailureDiagnostics] field set. Raw
/// exceptions, response bodies, credentials and arbitrary provider messages
/// cannot be attached through this API, and [toString] is always redacted.
final class SourceFailure implements Exception {
  SourceFailure({
    required this.code,
    this.retryable = false,
    this.retryAfter,
    SourceFailureDiagnostics? diagnostics,
  }) : diagnostics = diagnostics ?? SourceFailureDiagnostics() {
    if (retryAfter != null && retryAfter! < Duration.zero) {
      throw ArgumentError.value(retryAfter, 'retryAfter');
    }
  }

  SourceFailure.unsupportedCapability(SourceCapability capability)
    : code = SourceFailureCode.unsupportedCapability,
      retryable = false,
      retryAfter = null,
      diagnostics = SourceFailureDiagnostics(capability: capability);

  SourceFailure.sourceUnavailable()
    : code = SourceFailureCode.sourceUnavailable,
      retryable = false,
      retryAfter = null,
      diagnostics = SourceFailureDiagnostics();

  SourceFailure.invalidRequest()
    : code = SourceFailureCode.invalidRequest,
      retryable = false,
      retryAfter = null,
      diagnostics = SourceFailureDiagnostics();

  SourceFailure.cancelled()
    : code = SourceFailureCode.cancelled,
      retryable = false,
      retryAfter = null,
      diagnostics = SourceFailureDiagnostics();

  final SourceFailureCode code;
  final bool retryable;
  final Duration? retryAfter;
  final SourceFailureDiagnostics diagnostics;

  String get codeName => code.wireName;

  @override
  String toString() => 'SourceFailure($codeName)';
}
