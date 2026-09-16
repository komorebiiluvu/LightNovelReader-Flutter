import '../identity/identity_failure.dart';
import '../identity/opaque_ids.dart';
import '../identity/source_refs.dart';

final class LegacyDatasetId extends OpaqueId {
  LegacyDatasetId(super.value);
}

enum LegacyIdentityResolution { unresolved, resolved, conflict }

/// Evidence only. Alias selection, placeholder assignment and persistence are
/// importer responsibilities. Conflicting candidates remain separate raw fields.
/// No wire format is frozen for mapping receipts in F2.1.
final class LegacySourceMapping {
  LegacySourceMapping({
    required this.datasetId,
    required this.originalBookKey,
    required this.mappingVersion,
    required this.resolution,
    this.sourceByIdName,
    this.bookSourceName,
    this.targetRef,
  }) {
    if (mappingVersion < 1 ||
        (resolution == LegacyIdentityResolution.resolved &&
            targetRef == null)) {
      throw IdentityFailure(IdentityFailureReason.invalidValue);
    }
  }

  final LegacyDatasetId datasetId;
  // Raw evidence may be empty/invalid as an ID. Do not normalize it or log it.
  final String originalBookKey;
  final String? sourceByIdName;
  final String? bookSourceName;
  final SourceBookRef? targetRef;
  final int mappingVersion;
  final LegacyIdentityResolution resolution;

  Object get _values => (
    datasetId,
    originalBookKey,
    sourceByIdName,
    bookSourceName,
    targetRef,
    mappingVersion,
    resolution,
  );

  @override
  bool operator ==(Object other) =>
      other is LegacySourceMapping && _values == other._values;

  @override
  int get hashCode => _values.hashCode;
}
