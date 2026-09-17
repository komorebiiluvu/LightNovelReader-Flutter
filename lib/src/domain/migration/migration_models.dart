import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'migration_failure.dart';
import 'raw_json.dart';

const initialImporterVersion = 1;
const initialMappingVersion = 1;

enum MigrationInputType {
  legacyBackupV1('legacyBackupV1'),
  legacyIosSnapshotV1('legacyIosSnapshotV1');

  const MigrationInputType(this.wireName);
  final String wireName;
}

enum MigrationRunState {
  pending,
  applying,
  verifying,
  complete,
  partial,
  failed,
}

enum MigrationEntityKind {
  source('source'),
  book('book'),
  shelf('shelf'),
  group('group'),
  split('split'),
  progress('progress'),
  readerPreferences('readerPreferences'),
  appPreferences('appPreferences'),
  statistics('statistics'),
  searchHistory('searchHistory'),
  catalog('catalog');

  const MigrationEntityKind(this.wireName);
  final String wireName;
}

enum MigrationOutcome {
  imported('imported'),
  unchanged('unchanged'),
  preservedUnresolved('preserved-unresolved'),
  deferredPreserved('deferred-preserved'),
  intentionallyExcluded('intentionally-excluded'),
  failed('failed'),
  conflict('conflict');

  const MigrationOutcome(this.wireName);
  final String wireName;
}

enum MigrationDiagnosticCode {
  invalidField('invalid-field'),
  unknownField('unknown-field'),
  unsupported('unsupported'),
  missingEvidence('missing-evidence'),
  conflictingEvidence('conflicting-evidence'),
  verificationFailed('verification-failed'),
  secretExcluded('secret-excluded');

  const MigrationDiagnosticCode(this.wireName);
  final String wireName;
}

enum SafeLegacyValueType { string, integer, number, boolean, nullValue }

enum SafeLegacyValuePurpose {
  acceptedBaseline('accepted-baseline'),
  unresolvedEvidence('unresolved-evidence'),
  conflictCandidate('conflict-candidate');

  const SafeLegacyValuePurpose(this.wireName);
  final String wireName;
}

final class MigrationInput {
  MigrationInput({
    required String datasetId,
    required this.inputType,
    required List<int> bytes,
    this.importerVersion = initialImporterVersion,
    this.mappingVersion = initialMappingVersion,
  }) : datasetId = _validatedText(datasetId),
       bytes = _copyBytes(bytes) {
    if (importerVersion <= 0 || mappingVersion <= 0) {
      throw const MigrationFailure(MigrationFailureReason.invalidEnvelope);
    }
  }

  final String datasetId;
  final MigrationInputType inputType;
  final List<int> bytes;
  final int importerVersion;
  final int mappingVersion;

  String get inputDigest => sha256.convert(bytes).toString();

  MigrationRunKey get runKey => MigrationRunKey(
    datasetId: datasetId,
    importerVersion: importerVersion,
    inputDigest: inputDigest,
  );
}

final class MigrationRunKey {
  const MigrationRunKey({
    required this.datasetId,
    required this.importerVersion,
    required this.inputDigest,
  });

  final String datasetId;
  final int importerVersion;
  final String inputDigest;

  @override
  bool operator ==(Object other) =>
      other is MigrationRunKey &&
      other.datasetId == datasetId &&
      other.importerVersion == importerVersion &&
      other.inputDigest == inputDigest;

  @override
  int get hashCode => Object.hash(datasetId, importerVersion, inputDigest);
}

final class MigrationRun {
  const MigrationRun({
    required this.key,
    required this.mappingVersion,
    required this.state,
    required this.expectedUnits,
    required this.verifiedUnits,
  });

  final MigrationRunKey key;
  final int mappingVersion;
  final MigrationRunState state;
  final int expectedUnits;
  final int verifiedUnits;
}

final class MigrationReceiptRecord {
  const MigrationReceiptRecord({
    required this.datasetId,
    required this.importerVersion,
    required this.entityKind,
    required this.legacyKey,
  });

  final String datasetId;
  final int importerVersion;
  final MigrationEntityKind entityKind;
  final String legacyKey;
}

final class SafeLegacyValue {
  const SafeLegacyValue._({
    required this.type,
    this.stringValue,
    this.integerValue,
    this.numberValue,
    this.booleanValue,
  });

  const SafeLegacyValue.string(String value)
    : this._(type: SafeLegacyValueType.string, stringValue: value);
  const SafeLegacyValue.integer(int value)
    : this._(type: SafeLegacyValueType.integer, integerValue: value);
  const SafeLegacyValue.number(double value)
    : this._(type: SafeLegacyValueType.number, numberValue: value);
  const SafeLegacyValue.boolean(bool value)
    : this._(type: SafeLegacyValueType.boolean, booleanValue: value);
  const SafeLegacyValue.nullValue()
    : this._(type: SafeLegacyValueType.nullValue);

  final SafeLegacyValueType type;
  final String? stringValue;
  final int? integerValue;
  final double? numberValue;
  final bool? booleanValue;

  Object? get typedValue => switch (type) {
    SafeLegacyValueType.string => stringValue,
    SafeLegacyValueType.integer => integerValue,
    SafeLegacyValueType.number => numberValue,
    SafeLegacyValueType.boolean => booleanValue,
    SafeLegacyValueType.nullValue => null,
  };
}

final class SafeLegacyEvidence {
  const SafeLegacyEvidence({
    required this.field,
    required this.value,
    this.mapKey = '',
    this.ordinal = 0,
  });

  final String field;
  final String mapKey;
  final int ordinal;
  final SafeLegacyValue value;
}

final class MigrationUnit {
  const MigrationUnit({
    required this.entityKind,
    required this.legacyKey,
    this.evidence = const [],
    this.omittedFieldCount = 0,
    this.diagnostic,
    this.fatal,
  });

  final MigrationEntityKind entityKind;
  final String legacyKey;
  final List<SafeLegacyEvidence> evidence;
  final int omittedFieldCount;
  final MigrationDiagnosticCode? diagnostic;

  /// F2.7 can preserve a record with a best-effort fallback. A null value
  /// retains the F2.6 diagnostic-derived behavior for existing callers.
  final bool? fatal;

  bool get isRecordFailure =>
      fatal ??
      (diagnostic == MigrationDiagnosticCode.invalidField ||
          diagnostic == MigrationDiagnosticCode.unsupported ||
          diagnostic == MigrationDiagnosticCode.missingEvidence ||
          diagnostic == MigrationDiagnosticCode.conflictingEvidence ||
          diagnostic == MigrationDiagnosticCode.verificationFailed);
}

final class MigrationPlan {
  MigrationPlan({
    required this.inputType,
    required this.runKey,
    required Iterable<MigrationUnit> units,
  }) : units = List<MigrationUnit>.unmodifiable(units);

  final MigrationInputType inputType;
  final MigrationRunKey runKey;
  final List<MigrationUnit> units;
}

final class MigrationVerificationResult {
  const MigrationVerificationResult({
    required this.state,
    required this.expectedUnits,
    required this.verifiedUnits,
  });

  final MigrationRunState state;
  final int expectedUnits;
  final int verifiedUnits;
}

/// The concrete product effect and its disposition, returned by a typed
/// migration applier. This is intentionally separate from [MigrationUnit],
/// which contains only sanitized identity/evidence.
enum MigrationEffectKind { materialized, preservationOnly }

final class MigrationApplyResult {
  const MigrationApplyResult({
    required this.outcome,
    this.diagnostic,
    this.effect = MigrationEffectKind.materialized,
  });

  const MigrationApplyResult.imported({MigrationDiagnosticCode? diagnostic})
    : this(outcome: MigrationOutcome.imported, diagnostic: diagnostic);

  const MigrationApplyResult.unchanged({MigrationDiagnosticCode? diagnostic})
    : this(outcome: MigrationOutcome.unchanged, diagnostic: diagnostic);

  const MigrationApplyResult.preservedUnresolved({
    MigrationDiagnosticCode? diagnostic,
  }) : this(
         outcome: MigrationOutcome.preservedUnresolved,
         diagnostic: diagnostic,
       );

  const MigrationApplyResult.deferredPreserved()
    : this(
        outcome: MigrationOutcome.deferredPreserved,
        effect: MigrationEffectKind.preservationOnly,
      );

  const MigrationApplyResult.intentionallyExcluded({
    MigrationDiagnosticCode? diagnostic,
  }) : this(
         outcome: MigrationOutcome.intentionallyExcluded,
         diagnostic: diagnostic,
         effect: MigrationEffectKind.preservationOnly,
       );

  const MigrationApplyResult.conflict({
    MigrationDiagnosticCode diagnostic =
        MigrationDiagnosticCode.conflictingEvidence,
  }) : this(outcome: MigrationOutcome.conflict, diagnostic: diagnostic);

  const MigrationApplyResult.failed({
    MigrationDiagnosticCode diagnostic = MigrationDiagnosticCode.invalidField,
  }) : this(outcome: MigrationOutcome.failed, diagnostic: diagnostic);

  final MigrationOutcome outcome;
  final MigrationDiagnosticCode? diagnostic;
  final MigrationEffectKind effect;
}

enum MigrationVerificationDisposition {
  verified,
  targetConflict,
  verificationFailure,
}

String _validatedText(String value) {
  if (value.isEmpty || value.contains('\u0000')) {
    throw const MigrationFailure(MigrationFailureReason.invalidEnvelope);
  }
  return value;
}

List<int> _copyBytes(List<int> bytes) {
  final copy = List<int>.from(bytes);
  if (copy.any((byte) => byte < 0 || byte > 255)) {
    throw const MigrationFailure(MigrationFailureReason.invalidEnvelope);
  }
  return List<int>.unmodifiable(Uint8List.fromList(copy));
}

SafeLegacyValue safeValueFromRaw(RawJsonValue value) => switch (value) {
  RawJsonNull() => const SafeLegacyValue.nullValue(),
  RawJsonBoolean(:final value) => SafeLegacyValue.boolean(value),
  RawJsonString(:final value) => SafeLegacyValue.string(value),
  RawJsonInteger(:final value) => SafeLegacyValue.integer(value),
  RawJsonNumber(:final value) => SafeLegacyValue.number(value),
  RawJsonArray() || RawJsonObject() => throw const MigrationFailure(
    MigrationFailureReason.planningFailure,
  ),
};
