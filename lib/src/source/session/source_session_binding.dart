import '../../domain/identity/opaque_ids.dart';

/// Immutable request-time binding to one Source session generation.
final class SourceSessionBinding {
  const SourceSessionBinding({
    required this.sourceId,
    required this.generation,
  });

  final SourceId sourceId;
  final int generation;

  int get sessionGeneration => generation;

  @override
  String toString() =>
      'SourceSessionBinding(${sourceId.runtimeType}(<opaque>), '
      'generation=$generation)';
}
