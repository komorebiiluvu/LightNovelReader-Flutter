import '../domain/identity/opaque_ids.dart';
import 'source_cancellation.dart';
import 'source_failure.dart';

enum SourceOperation {
  search('search'),
  explore('explore'),
  bookDetail('bookDetail'),
  catalog('catalog'),
  chapterContent('chapterContent'),
  authentication('authentication');

  const SourceOperation(this.wireName);

  final String wireName;
}

/// Opaque caller-provided identity for a logical request.
///
/// The value must not contain secrets, URLs or provider request objects. It is
/// retained only to bind continuations to the request that created them.
final class SourceRequestIdentity {
  SourceRequestIdentity(this.value) {
    if (value.isEmpty || value.contains('\u0000')) {
      throw ArgumentError.value(value, 'value');
    }
  }

  final String value;

  @override
  bool operator ==(Object other) =>
      other is SourceRequestIdentity && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'SourceRequestIdentity(<opaque>)';
}

/// Provider continuation data with all reuse bindings retained by the host.
final class SourceContinuation {
  SourceContinuation({
    required this.sourceId,
    required this.operation,
    required this.requestIdentity,
    required this.sessionGeneration,
    required this.opaqueValue,
  }) {
    if (sessionGeneration < 0) {
      throw ArgumentError.value(sessionGeneration, 'sessionGeneration');
    }
    if (opaqueValue.isEmpty || opaqueValue.contains('\u0000')) {
      throw ArgumentError.value(opaqueValue, 'opaqueValue');
    }
  }

  final SourceId sourceId;
  final SourceOperation operation;
  final SourceRequestIdentity requestIdentity;
  final int sessionGeneration;
  final String opaqueValue;

  void validateFor({
    required SourceId sourceId,
    required SourceOperation operation,
    required SourceRequestIdentity requestIdentity,
    required int sessionGeneration,
  }) {
    if (this.sourceId != sourceId ||
        this.operation != operation ||
        this.requestIdentity != requestIdentity ||
        this.sessionGeneration != sessionGeneration) {
      throw SourceFailure.invalidRequest();
    }
  }

  @override
  bool operator ==(Object other) =>
      other is SourceContinuation &&
      sourceId == other.sourceId &&
      operation == other.operation &&
      requestIdentity == other.requestIdentity &&
      sessionGeneration == other.sessionGeneration &&
      opaqueValue == other.opaqueValue;

  @override
  int get hashCode => Object.hash(
    sourceId,
    operation,
    requestIdentity,
    sessionGeneration,
    opaqueValue,
  );

  @override
  String toString() => 'SourceContinuation(<opaque>)';
}

/// Explicit operation context shared by all Source calls.
final class SourceOperationContext {
  SourceOperationContext({
    required this.sourceId,
    required this.operation,
    required this.requestIdentity,
    required this.sessionGeneration,
    required this.cancellation,
  }) {
    if (sessionGeneration < 0) {
      throw ArgumentError.value(sessionGeneration, 'sessionGeneration');
    }
  }

  final SourceId sourceId;
  final SourceOperation operation;
  final SourceRequestIdentity requestIdentity;
  final int sessionGeneration;
  final SourceCancellation cancellation;

  void requireOperation(SourceOperation expected) {
    if (operation != expected) throw SourceFailure.invalidRequest();
  }

  void requireActive() => cancellation.throwIfCancelled();

  void requireContinuation(SourceContinuation? continuation) {
    continuation?.validateFor(
      sourceId: sourceId,
      operation: operation,
      requestIdentity: requestIdentity,
      sessionGeneration: sessionGeneration,
    );
  }

  @override
  String toString() => 'SourceOperationContext(<opaque>)';
}
