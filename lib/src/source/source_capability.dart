import '../domain/identity/opaque_ids.dart';

/// Operations and infrastructure a Source may expose.
///
/// Capability support is independent of the current authentication state.
enum SourceCapability {
  search('search'),
  explore('explore'),
  bookDetail('bookDetail'),
  catalog('catalog'),
  chapterContent('chapterContent'),
  images('images'),
  authentication('authentication'),
  cookies('cookies'),
  filters('filters'),
  updates('updates');

  const SourceCapability(this.wireName);

  final String wireName;
}

/// Immutable source metadata used by the registry and callers.
final class SourceDescriptor {
  SourceDescriptor({
    required this.sourceId,
    required this.displayName,
    required Set<SourceCapability> capabilities,
  }) : capabilities = Set<SourceCapability>.unmodifiable(capabilities) {
    if (displayName.isEmpty) {
      throw ArgumentError.value(displayName, 'displayName');
    }
  }

  final SourceId sourceId;
  final String displayName;
  final Set<SourceCapability> capabilities;

  /// Alias matching the public contract sketch.
  SourceId get id => sourceId;

  SourceDescriptor copyWith({
    String? displayName,
    Set<SourceCapability>? capabilities,
  }) => SourceDescriptor(
    sourceId: sourceId,
    displayName: displayName ?? this.displayName,
    capabilities: capabilities ?? this.capabilities,
  );

  /// Descriptor identity is the immutable SourceId; display metadata is not.
  @override
  bool operator ==(Object other) =>
      other is SourceDescriptor && sourceId == other.sourceId;

  @override
  int get hashCode => sourceId.hashCode;

  @override
  String toString() => 'SourceDescriptor(${sourceId.runtimeType}(<opaque>))';
}
