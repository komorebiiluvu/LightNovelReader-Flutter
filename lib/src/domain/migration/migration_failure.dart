enum MigrationFailureReason {
  invalidUtf8,
  malformedJson,
  duplicateKey,
  unsupportedInputType,
  unsupportedVersion,
  resourceLimit,
  invalidEnvelope,
  planningFailure,
  storage,
  verificationFailure,
  invalidStateTransition,
  datasetNotRegistered,
}

/// A stable, content-free failure for the migration boundary.
///
/// Deliberately omits parser text, paths, SQL, exception messages, and input
/// values. Callers can use [reason] for machine-readable handling.
final class MigrationFailure implements Exception {
  const MigrationFailure(this.reason);

  final MigrationFailureReason reason;

  String get message => switch (reason) {
    MigrationFailureReason.invalidUtf8 => 'The migration input is not UTF-8.',
    MigrationFailureReason.malformedJson => 'The migration JSON is malformed.',
    MigrationFailureReason.duplicateKey =>
      'The migration JSON contains a duplicate key.',
    MigrationFailureReason.unsupportedInputType =>
      'The selected migration input type is unsupported.',
    MigrationFailureReason.unsupportedVersion =>
      'The migration input version is unsupported.',
    MigrationFailureReason.resourceLimit =>
      'The migration input exceeds a safety limit.',
    MigrationFailureReason.invalidEnvelope =>
      'The migration input envelope is invalid.',
    MigrationFailureReason.planningFailure =>
      'The migration input could not be planned.',
    MigrationFailureReason.storage => 'Migration state could not be stored.',
    MigrationFailureReason.verificationFailure =>
      'Migration verification could not complete.',
    MigrationFailureReason.invalidStateTransition =>
      'The migration run state transition is invalid.',
    MigrationFailureReason.datasetNotRegistered =>
      'The migration dataset is not registered.',
  };

  @override
  String toString() => 'MigrationFailure(${reason.name})';
}
