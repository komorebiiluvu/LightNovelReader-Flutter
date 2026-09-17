import 'source_capability.dart';
import 'source_operation.dart';

/// Reviewed, source-neutral metadata allowed on a [SourceFailure].
///
/// The typed fields are deliberately finite. This prevents credentials,
/// response bodies, raw requests and arbitrary provider messages from crossing
/// the Source boundary through diagnostics.
final class SourceFailureDiagnostics {
  SourceFailureDiagnostics({
    this.operation,
    this.capability,
    this.statusCode,
    this.attempt,
    this.retryCount,
    this.elapsedMilliseconds,
    this.fromCache,
  }) {
    if (statusCode != null && (statusCode! < 100 || statusCode! > 599)) {
      throw ArgumentError.value(statusCode, 'statusCode');
    }
    if (attempt != null && attempt! < 1) {
      throw ArgumentError.value(attempt, 'attempt');
    }
    if (retryCount != null && retryCount! < 0) {
      throw ArgumentError.value(retryCount, 'retryCount');
    }
    if (elapsedMilliseconds != null && elapsedMilliseconds! < 0) {
      throw ArgumentError.value(elapsedMilliseconds, 'elapsedMilliseconds');
    }
  }

  final SourceOperation? operation;
  final SourceCapability? capability;
  final int? statusCode;
  final int? attempt;
  final int? retryCount;
  final int? elapsedMilliseconds;
  final bool? fromCache;

  /// A stable, immutable view for telemetry adapters. Keys are fixed by this
  /// type and cannot be added by callers.
  Map<String, Object?> get asMap {
    final values = <String, Object?>{};
    if (operation != null) values['operation'] = operation!.wireName;
    if (capability != null) values['capability'] = capability!.wireName;
    if (statusCode != null) values['statusCode'] = statusCode;
    if (attempt != null) values['attempt'] = attempt;
    if (retryCount != null) values['retryCount'] = retryCount;
    if (elapsedMilliseconds != null) {
      values['elapsedMilliseconds'] = elapsedMilliseconds;
    }
    if (fromCache != null) values['fromCache'] = fromCache;
    return Map<String, Object?>.unmodifiable(values);
  }
}
