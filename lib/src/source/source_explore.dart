/// A neutral, immutable Explore surface declared by a Source.
///
/// Descriptor IDs and filter values are opaque provider metadata. They are
/// never interpreted by the Core or turned into transport details.
final class ExploreDescriptor {
  ExploreDescriptor({
    required this.id,
    required this.title,
    this.isHome = false,
    List<SourceFilterDescriptor> filters = const [],
  }) : filters = List<SourceFilterDescriptor>.unmodifiable(filters) {
    _requireNonEmpty(id, 'id');
  }

  final String id;
  final String title;
  final bool isHome;
  final List<SourceFilterDescriptor> filters;
}

/// A neutral immutable filter declaration for an [ExploreDescriptor].
final class SourceFilterDescriptor {
  SourceFilterDescriptor({
    required this.id,
    required this.label,
    List<String> values = const [],
  }) : values = List<String>.unmodifiable(values) {
    _requireNonEmpty(id, 'id');
  }

  final String id;
  final String label;
  final List<String> values;
}

void _requireNonEmpty(String value, String name) {
  if (value.isEmpty) throw ArgumentError.value(value, name);
}
