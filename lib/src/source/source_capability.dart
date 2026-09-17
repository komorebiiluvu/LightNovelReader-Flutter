import '../domain/identity/opaque_ids.dart';
import 'source_explore.dart';

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
    List<ExploreDescriptor> exploreDescriptors = const [],
  }) : capabilities = Set<SourceCapability>.unmodifiable(capabilities),
       exploreDescriptors = List<ExploreDescriptor>.unmodifiable(
         exploreDescriptors,
       ) {
    if (displayName.isEmpty) {
      throw ArgumentError.value(displayName, 'displayName');
    }
    if (exploreDescriptors.isNotEmpty &&
        !this.capabilities.contains(SourceCapability.explore)) {
      throw ArgumentError(
        'Explore descriptors require the explore capability.',
      );
    }
  }

  final SourceId sourceId;
  final String displayName;
  final Set<SourceCapability> capabilities;
  final List<ExploreDescriptor> exploreDescriptors;

  /// Alias matching the public contract sketch.
  SourceId get id => sourceId;

  SourceDescriptor copyWith({
    String? displayName,
    Set<SourceCapability>? capabilities,
    List<ExploreDescriptor>? exploreDescriptors,
  }) => SourceDescriptor(
    sourceId: sourceId,
    displayName: displayName ?? this.displayName,
    capabilities: capabilities ?? this.capabilities,
    exploreDescriptors: exploreDescriptors ?? this.exploreDescriptors,
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
