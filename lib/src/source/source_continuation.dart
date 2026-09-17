import '../domain/identity/opaque_ids.dart';
import 'source_cancellation.dart';
import 'source_failure.dart';
import 'source_operation.dart';

/// Opaque provider continuation data bound to immutable request semantics.
///
/// Callers cannot supply an unrelated request identity. The only constructors
/// derive the binding from the actual Search or Explore fields, and validation
/// repeats that derivation for the request currently being executed.
final class SourceContinuation {
  SourceContinuation._({
    required this.sourceId,
    required this.operation,
    required this.sessionGeneration,
    required this.opaqueValue,
    required this._binding,
  }) {
    if (sessionGeneration < 0) {
      throw ArgumentError.value(sessionGeneration, 'sessionGeneration');
    }
    if (opaqueValue.isEmpty || opaqueValue.contains('\u0000')) {
      throw ArgumentError.value(opaqueValue, 'opaqueValue');
    }
  }

  factory SourceContinuation.forSearch({
    required SourceId sourceId,
    required String queryText,
    Map<String, String> filters = const {},
    required int sessionGeneration,
    required String opaqueValue,
  }) => SourceContinuation._(
    sourceId: sourceId,
    operation: SourceOperation.search,
    sessionGeneration: sessionGeneration,
    opaqueValue: opaqueValue,
    binding: _RequestBinding.search(queryText, filters),
  );

  factory SourceContinuation.forExplore({
    required SourceId sourceId,
    required String descriptorId,
    Map<String, String> selections = const {},
    required int sessionGeneration,
    required String opaqueValue,
  }) => SourceContinuation._(
    sourceId: sourceId,
    operation: SourceOperation.explore,
    sessionGeneration: sessionGeneration,
    opaqueValue: opaqueValue,
    binding: _RequestBinding.explore(descriptorId, selections),
  );

  final SourceId sourceId;
  final SourceOperation operation;
  final int sessionGeneration;
  final String opaqueValue;
  final _RequestBinding _binding;

  void validateForSearch({
    required SourceId sourceId,
    required String queryText,
    Map<String, String> filters = const {},
    required int sessionGeneration,
  }) {
    _validate(
      sourceId: sourceId,
      operation: SourceOperation.search,
      sessionGeneration: sessionGeneration,
      binding: _RequestBinding.search(queryText, filters),
    );
  }

  void validateForExplore({
    required SourceId sourceId,
    required String descriptorId,
    Map<String, String> selections = const {},
    required int sessionGeneration,
  }) {
    _validate(
      sourceId: sourceId,
      operation: SourceOperation.explore,
      sessionGeneration: sessionGeneration,
      binding: _RequestBinding.explore(descriptorId, selections),
    );
  }

  void _validate({
    required SourceId sourceId,
    required SourceOperation operation,
    required int sessionGeneration,
    required _RequestBinding binding,
  }) {
    if (this.sourceId != sourceId ||
        this.operation != operation ||
        this.sessionGeneration != sessionGeneration ||
        _binding != binding) {
      throw SourceFailure.invalidRequest();
    }
  }

  @override
  bool operator ==(Object other) =>
      other is SourceContinuation &&
      sourceId == other.sourceId &&
      operation == other.operation &&
      sessionGeneration == other.sessionGeneration &&
      opaqueValue == other.opaqueValue &&
      _binding == other._binding;

  @override
  int get hashCode => Object.hash(
    sourceId,
    operation,
    sessionGeneration,
    opaqueValue,
    _binding,
  );

  @override
  String toString() => 'SourceContinuation(<opaque>)';
}

/// Structural request binding used internally by continuations.
final class _RequestBinding {
  _RequestBinding.search(this.text, Map<String, String> filters)
    : operation = SourceOperation.search,
      descriptorId = null,
      values = Map<String, String>.unmodifiable(filters);

  _RequestBinding.explore(this.descriptorId, Map<String, String> selections)
    : operation = SourceOperation.explore,
      text = null,
      values = Map<String, String>.unmodifiable(selections);

  final SourceOperation operation;
  final String? text;
  final String? descriptorId;
  final Map<String, String> values;

  @override
  bool operator ==(Object other) {
    if (other is! _RequestBinding ||
        operation != other.operation ||
        text != other.text ||
        descriptorId != other.descriptorId ||
        values.length != other.values.length) {
      return false;
    }
    for (final entry in values.entries) {
      if (other.values[entry.key] != entry.value ||
          !other.values.containsKey(entry.key)) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    operation,
    text,
    descriptorId,
    Object.hashAll(_sortedEntries.map(_entryHash)),
  );

  List<MapEntry<String, String>> get _sortedEntries {
    final entries = values.entries.toList();
    return entries..sort((a, b) => a.key.compareTo(b.key));
  }

  int _entryHash(MapEntry<String, String> entry) =>
      Object.hash(entry.key, entry.value);
}

/// Explicit operation context shared by all Source calls.
final class SourceOperationContext {
  SourceOperationContext({
    required this.sourceId,
    required this.operation,
    required this.sessionGeneration,
    required this.cancellation,
  }) {
    if (sessionGeneration < 0) {
      throw ArgumentError.value(sessionGeneration, 'sessionGeneration');
    }
  }

  final SourceId sourceId;
  final SourceOperation operation;
  final int sessionGeneration;
  final SourceCancellation cancellation;

  void requireOperation(SourceOperation expected) {
    if (operation != expected) throw SourceFailure.invalidRequest();
  }

  void requireActive() => cancellation.throwIfCancelled();

  @override
  String toString() => 'SourceOperationContext(<opaque>)';
}
