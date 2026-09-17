import 'source_capability.dart';

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
/// Diagnostics are deliberately restricted to scalar, allowlisted-style values
/// and are never included in [toString]. Raw exceptions, response bodies and
/// credentials must be mapped before constructing this value.
final class SourceFailure implements Exception {
  SourceFailure({
    required this.code,
    this.retryable = false,
    this.retryAfter,
    Map<String, Object?> diagnostics = const {},
  }) : diagnostics = _safeDiagnostics(diagnostics) {
    if (retryAfter != null && retryAfter! < Duration.zero) {
      throw ArgumentError.value(retryAfter, 'retryAfter');
    }
  }

  SourceFailure.unsupportedCapability(SourceCapability capability)
    : this(
        code: SourceFailureCode.unsupportedCapability,
        diagnostics: {'capability': capability.wireName},
      );

  SourceFailure.sourceUnavailable()
    : this(code: SourceFailureCode.sourceUnavailable);

  SourceFailure.invalidRequest() : this(code: SourceFailureCode.invalidRequest);

  SourceFailure.cancelled() : this(code: SourceFailureCode.cancelled);

  final SourceFailureCode code;
  final bool retryable;
  final Duration? retryAfter;
  final Map<String, Object?> diagnostics;

  String get codeName => code.wireName;

  @override
  String toString() => 'SourceFailure($codeName)';
}

Map<String, Object?> _safeDiagnostics(Map<String, Object?> input) {
  final copy = <String, Object?>{};
  final keyPattern = RegExp(r'^[A-Za-z0-9_.-]+$');
  for (final entry in input.entries) {
    if (!keyPattern.hasMatch(entry.key)) {
      throw ArgumentError.value(entry.key, 'diagnostics');
    }
    final value = entry.value;
    if (value != null && value is! String && value is! num && value is! bool) {
      throw ArgumentError.value(value, 'diagnostics');
    }
    copy[entry.key] = value;
  }
  return Map<String, Object?>.unmodifiable(copy);
}
