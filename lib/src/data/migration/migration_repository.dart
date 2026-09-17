import 'package:drift/drift.dart';

import '../../domain/migration/migration_failure.dart';
import '../../domain/migration/migration_models.dart';
import '../../domain/migration/migration_planner.dart';
import '../persistence/database.dart' show AppDatabase;

enum MigrationFailurePoint {
  beforeHandler,
  afterHandler,
  beforeReceipt,
  beforeOutcome,
  beforeCommit,
}

typedef MigrationFailureInjector = void Function(MigrationFailurePoint point);

typedef MigrationUnitHandler = Future<void> Function(
  MigrationUnit unit,
  AppDatabase database,
);

typedef MigrationUnitVerifier = Future<bool> Function(
  MigrationUnit unit,
  AppDatabase database,
);

typedef MigrationUnitApplier = Future<MigrationApplyResult> Function(
  MigrationUnit unit,
  AppDatabase database,
);

typedef MigrationTypedUnitVerifier =
    Future<MigrationVerificationDisposition> Function(
      MigrationUnit unit,
      AppDatabase database,
    );

final class MigrationOutcomeRecord {
  const MigrationOutcomeRecord({
    required this.key,
    required this.entityKind,
    required this.legacyKey,
    required this.outcome,
    required this.diagnostic,
    required this.omittedFieldCount,
  });

  final MigrationRunKey key;
  final MigrationEntityKind entityKind;
  final String legacyKey;
  final MigrationOutcome outcome;
  final MigrationDiagnosticCode? diagnostic;
  final int omittedFieldCount;
}

final class SafeLegacyValueRecord {
  const SafeLegacyValueRecord({
    required this.entityKind,
    required this.legacyKey,
    required this.candidateId,
    required this.purpose,
    required this.evidence,
  });

  final MigrationEntityKind entityKind;
  final String legacyKey;
  final String candidateId;
  final SafeLegacyValuePurpose purpose;
  final SafeLegacyEvidence evidence;
}

/// Infrastructure adapter for the approved v1 migration tables.
///
/// Public methods return migration models rather than Drift rows. The one-unit
/// method owns the transaction that joins the future product handler with its
/// receipt, safe evidence, and outcome.
final class MigrationRepository {
  MigrationRepository(this.database);

  final AppDatabase database;

  Future<void> ensureDataset(String datasetId) => _safe(() async {
    if (datasetId.isEmpty || datasetId.contains('\u0000')) {
      throw const MigrationFailure(MigrationFailureReason.invalidEnvelope);
    }
    await database.transaction(() async {
      await database.customStatement(
        'INSERT OR IGNORE INTO migration_datasets(dataset_id) VALUES (?)',
        [datasetId],
      );
    });
  });

  Future<bool> datasetExists(String datasetId) => _safe(() async {
    final rows = await _select(
      'SELECT 1 FROM migration_datasets WHERE dataset_id=?',
      [datasetId],
    );
    return rows.isNotEmpty;
  });

  Future<MigrationRun?> getRun(MigrationRunKey key) => _safe(() async {
    final rows = await _select(
      'SELECT mapping_version,state,expected_units,verified_units '
      'FROM migration_runs WHERE dataset_id=? AND importer_version=? '
      'AND input_digest=?',
      [key.datasetId, key.importerVersion, key.inputDigest],
    );
    return rows.isEmpty ? null : _runFromRow(key, rows.single);
  });

  Future<MigrationRun> createOrReuseRun({
    required MigrationRunKey key,
    required int mappingVersion,
    required int expectedUnits,
  }) => _safe(() async {
    if (mappingVersion <= 0 || expectedUnits < 0) {
      throw const MigrationFailure(MigrationFailureReason.planningFailure);
    }
    return database.transaction(() async {
      final existing = await _select(
        'SELECT mapping_version,state,expected_units,verified_units '
        'FROM migration_runs WHERE dataset_id=? AND importer_version=? '
        'AND input_digest=?',
        [key.datasetId, key.importerVersion, key.inputDigest],
      );
      if (existing.isEmpty) {
        await database.customStatement(
          'INSERT INTO migration_runs(dataset_id,importer_version,input_digest,'
          'mapping_version,state,expected_units,verified_units) '
          'VALUES (?,?,?,?,?,?,?)',
          [
            key.datasetId,
            key.importerVersion,
            key.inputDigest,
            mappingVersion,
            MigrationRunState.pending.name,
            expectedUnits,
            0,
          ],
        );
        return MigrationRun(
          key: key,
          mappingVersion: mappingVersion,
          state: MigrationRunState.pending,
          expectedUnits: expectedUnits,
          verifiedUnits: 0,
        );
      }
      final current = _runFromRow(key, existing.single);
      if (current.mappingVersion != mappingVersion ||
          current.expectedUnits != expectedUnits) {
        throw const MigrationFailure(MigrationFailureReason.planningFailure);
      }
      return current;
    });
  });

  Future<MigrationRun> transition(
    MigrationRunKey key,
    MigrationRunState target, {
    int? verifiedUnits,
  }) => _safe(() async {
    return database.transaction(() async {
      final current = await _requireRun(key);
      if (current.state != target && !_legal(current.state, target)) {
        throw const MigrationFailure(
          MigrationFailureReason.invalidStateTransition,
        );
      }
      final nextVerified = verifiedUnits ?? current.verifiedUnits;
      await database.customStatement(
        'UPDATE migration_runs SET state=?,verified_units=? WHERE dataset_id=? '
        'AND importer_version=? AND input_digest=?',
        [
          target.name,
          nextVerified,
          key.datasetId,
          key.importerVersion,
          key.inputDigest,
        ],
      );
      return MigrationRun(
        key: key,
        mappingVersion: current.mappingVersion,
        state: target,
        expectedUnits: current.expectedUnits,
        verifiedUnits: nextVerified,
      );
    });
  });

  Future<MigrationOutcome> applyUnit({
    required MigrationRunKey key,
    required MigrationUnit unit,
    required MigrationUnitHandler handler,
    MigrationFailureInjector? failureInjector,
  }) => _safe(() async {
    return database.transaction(() async {
      failureInjector?.call(MigrationFailurePoint.beforeHandler);
      final receiptExists = await _receiptExists(
        unit,
        key.datasetId,
        key.importerVersion,
      );
      final baseline = await _safeRows(
        key.datasetId,
        key.importerVersion,
        unit,
        SafeLegacyValuePurpose.acceptedBaseline,
      );
      final previousOutcome = await _outcomeFor(key, unit);
      if (unit.isRecordFailure) {
        await _insertReceipt(key, unit);
        failureInjector?.call(MigrationFailurePoint.beforeOutcome);
        await _upsertOutcome(
          key: key,
          unit: unit,
          outcome: MigrationOutcome.failed,
          diagnostic: unit.diagnostic,
        );
        failureInjector?.call(MigrationFailurePoint.beforeCommit);
        return MigrationOutcome.failed;
      }

      if (baseline.isNotEmpty && _sameEvidence(baseline, unit.evidence)) {
        failureInjector?.call(MigrationFailurePoint.beforeOutcome);
        await _upsertOutcome(
          key: key,
          unit: unit,
          outcome: MigrationOutcome.unchanged,
          diagnostic: unit.diagnostic,
        );
        failureInjector?.call(MigrationFailurePoint.beforeCommit);
        return MigrationOutcome.unchanged;
      }

      if (baseline.isNotEmpty && !_sameEvidence(baseline, unit.evidence)) {
        await _insertReceipt(key, unit);
        await _insertEvidence(
          key: key,
          unit: unit,
          purpose: SafeLegacyValuePurpose.conflictCandidate,
        );
        failureInjector?.call(MigrationFailurePoint.beforeOutcome);
        await _upsertOutcome(
          key: key,
          unit: unit,
          outcome: MigrationOutcome.conflict,
          diagnostic: MigrationDiagnosticCode.conflictingEvidence,
        );
        failureInjector?.call(MigrationFailurePoint.beforeCommit);
        return MigrationOutcome.conflict;
      }

      if (receiptExists &&
          baseline.isEmpty &&
          previousOutcome != null &&
          _isAcceptable(previousOutcome)) {
        failureInjector?.call(MigrationFailurePoint.beforeOutcome);
        await _upsertOutcome(
          key: key,
          unit: unit,
          outcome: MigrationOutcome.unchanged,
          diagnostic: unit.diagnostic,
        );
        failureInjector?.call(MigrationFailurePoint.beforeCommit);
        return MigrationOutcome.unchanged;
      }

      // A failed unit may already have a receipt but no accepted baseline. It
      // is therefore deliberately retried here. A receipt alone never makes a
      // unit complete.
      if (!receiptExists || baseline.isEmpty) {
        await handler(unit, database);
        failureInjector?.call(MigrationFailurePoint.afterHandler);
      }
      failureInjector?.call(MigrationFailurePoint.beforeReceipt);
      await _insertReceipt(key, unit);
      await _insertEvidence(
        key: key,
        unit: unit,
        purpose: SafeLegacyValuePurpose.acceptedBaseline,
      );
      failureInjector?.call(MigrationFailurePoint.beforeOutcome);
      await _upsertOutcome(
        key: key,
        unit: unit,
        outcome: receiptExists
            ? MigrationOutcome.unchanged
            : MigrationOutcome.imported,
        diagnostic: unit.diagnostic,
      );
      failureInjector?.call(MigrationFailurePoint.beforeCommit);
      return receiptExists
          ? MigrationOutcome.unchanged
          : MigrationOutcome.imported;
    });
  });

  /// Typed F2.7 counterpart to [applyUnit]. The older void/bool API remains
  /// intact for F2.6 callers. A typed result lets concrete conversion report
  /// preserved-unresolved and deferred-preserved without weakening the
  /// receipt/evidence/product atomicity boundary.
  Future<MigrationOutcome> applyUnitWithResult({
    required MigrationRunKey key,
    required MigrationUnit unit,
    required MigrationUnitApplier applier,
    MigrationFailureInjector? failureInjector,
  }) => _safe(() async {
    return database.transaction(() async {
      failureInjector?.call(MigrationFailurePoint.beforeHandler);
      final baseline = await _safeRows(
        key.datasetId,
        key.importerVersion,
        unit,
        SafeLegacyValuePurpose.acceptedBaseline,
      );
      if (unit.isRecordFailure) {
        await _insertReceipt(key, unit);
        await _insertEvidence(
          key: key,
          unit: unit,
          purpose: SafeLegacyValuePurpose.conflictCandidate,
        );
        failureInjector?.call(MigrationFailurePoint.beforeOutcome);
        await _upsertOutcome(
          key: key,
          unit: unit,
          outcome: MigrationOutcome.failed,
          diagnostic: unit.diagnostic,
        );
        failureInjector?.call(MigrationFailurePoint.beforeCommit);
        return MigrationOutcome.failed;
      }

      if (baseline.isNotEmpty && _sameEvidence(baseline, unit.evidence)) {
        failureInjector?.call(MigrationFailurePoint.beforeOutcome);
        await _upsertOutcome(
          key: key,
          unit: unit,
          outcome: MigrationOutcome.unchanged,
          diagnostic: unit.diagnostic,
        );
        failureInjector?.call(MigrationFailurePoint.beforeCommit);
        return MigrationOutcome.unchanged;
      }

      if (baseline.isNotEmpty && !_sameEvidence(baseline, unit.evidence)) {
        await _insertReceipt(key, unit);
        await _insertEvidence(
          key: key,
          unit: unit,
          purpose: SafeLegacyValuePurpose.conflictCandidate,
        );
        failureInjector?.call(MigrationFailurePoint.beforeOutcome);
        await _upsertOutcome(
          key: key,
          unit: unit,
          outcome: MigrationOutcome.conflict,
          diagnostic: MigrationDiagnosticCode.conflictingEvidence,
        );
        failureInjector?.call(MigrationFailurePoint.beforeCommit);
        return MigrationOutcome.conflict;
      }

      // Receipt-without-baseline is the retry path after an interrupted or
      // failed unit. It must invoke the concrete applier again; receipt alone
      // is never a successful product effect.
      final result = await applier(unit, database);
      failureInjector?.call(MigrationFailurePoint.afterHandler);
      if (result.outcome == MigrationOutcome.conflict ||
          result.outcome == MigrationOutcome.failed) {
        await _insertReceipt(key, unit);
        await _insertEvidence(
          key: key,
          unit: unit,
          purpose: SafeLegacyValuePurpose.conflictCandidate,
        );
      } else {
        await _insertReceipt(key, unit);
        await _insertEvidence(
          key: key,
          unit: unit,
          purpose: SafeLegacyValuePurpose.acceptedBaseline,
        );
      }
      failureInjector?.call(MigrationFailurePoint.beforeReceipt);
      failureInjector?.call(MigrationFailurePoint.beforeOutcome);
      await _upsertOutcome(
        key: key,
        unit: unit,
        outcome: result.outcome,
        diagnostic: result.diagnostic ?? unit.diagnostic,
      );
      failureInjector?.call(MigrationFailurePoint.beforeCommit);
      return result.outcome;
    });
  });

  Future<void> recordFailure({
    required MigrationRunKey key,
    required MigrationUnit unit,
    MigrationDiagnosticCode diagnostic = MigrationDiagnosticCode.invalidField,
  }) => _safe(() async {
    await database.transaction(() async {
      await _insertReceipt(key, unit);
      await _upsertOutcome(
        key: key,
        unit: unit,
        outcome: MigrationOutcome.failed,
        diagnostic: diagnostic,
      );
    });
  });

  Future<MigrationRun> verifyRun({
    required MigrationRunKey key,
    required List<MigrationUnit> units,
    required MigrationUnitVerifier verifier,
  }) => _safe(() async {
    try {
      return await database.transaction(() async {
        final current = await _requireRun(key);
        if (current.state != MigrationRunState.verifying) {
          throw const MigrationFailure(
            MigrationFailureReason.invalidStateTransition,
          );
        }
        if (units.length != current.expectedUnits) {
          throw const MigrationFailure(
            MigrationFailureReason.verificationFailure,
          );
        }
        final identities = <({MigrationEntityKind kind, String key})>{};
        if (!units.every(
          (unit) =>
              identities.add((kind: unit.entityKind, key: unit.legacyKey)),
        )) {
          throw const MigrationFailure(
            MigrationFailureReason.verificationFailure,
          );
        }
        var verified = 0;
        var bad = false;
        for (final unit in units) {
          final outcome = await _outcomeFor(key, unit);
          var unitVerified = false;
          if (outcome == null || !_isAcceptable(outcome)) {
            bad = true;
          } else {
            try {
              final receipt = await _receiptExists(
                unit,
                key.datasetId,
                key.importerVersion,
              );
              final baseline = await _safeRows(
                key.datasetId,
                key.importerVersion,
                unit,
                SafeLegacyValuePurpose.acceptedBaseline,
              );
              final evidenceConsistent =
                  receipt &&
                  (unit.evidence.isEmpty ||
                      _sameEvidence(baseline, unit.evidence));
              unitVerified =
                  evidenceConsistent && await verifier(unit, database);
            } catch (_) {
              unitVerified = false;
            }
            if (unitVerified) {
              verified++;
            } else {
              bad = true;
              await _upsertOutcome(
                key: key,
                unit: unit,
                outcome: MigrationOutcome.failed,
                diagnostic: MigrationDiagnosticCode.verificationFailed,
              );
            }
          }
        }
        final complete = verified == current.expectedUnits && !bad;
        final state = complete
            ? MigrationRunState.complete
            : bad
            ? MigrationRunState.partial
            : MigrationRunState.failed;
        await database.customStatement(
          'UPDATE migration_runs SET state=?,verified_units=? WHERE '
          'dataset_id=? AND importer_version=? AND input_digest=?',
          [
            state.name,
            verified,
            key.datasetId,
            key.importerVersion,
            key.inputDigest,
          ],
        );
        return MigrationRun(
          key: key,
          mappingVersion: current.mappingVersion,
          state: state,
          expectedUnits: current.expectedUnits,
          verifiedUnits: verified,
        );
      });
    } on MigrationFailure {
      rethrow;
    } catch (_) {
      // If verification itself cannot finish, leave no false COMPLETE state.
      try {
        await transition(key, MigrationRunState.failed, verifiedUnits: 0);
      } catch (_) {
        // Preserve the stable verification failure below.
      }
      throw const MigrationFailure(MigrationFailureReason.verificationFailure);
    }
  });

  Future<MigrationRun> verifyRunWithResult({
    required MigrationRunKey key,
    required List<MigrationUnit> units,
    required MigrationTypedUnitVerifier verifier,
  }) => _verifyTyped(
    key: key,
    units: units,
    verifier: verifier,
    allowComplete: false,
  );

  /// Re-checks a completed typed run when the same bytes are presented again.
  /// This is what turns a post-import user edit into an explicit conflict
  /// instead of returning a stale false COMPLETE result.
  Future<MigrationRun> verifyCompletedRun({
    required MigrationRunKey key,
    required List<MigrationUnit> units,
    required MigrationTypedUnitVerifier verifier,
  }) => _verifyTyped(
    key: key,
    units: units,
    verifier: verifier,
    allowComplete: true,
  );

  Future<MigrationRun> _verifyTyped({
    required MigrationRunKey key,
    required List<MigrationUnit> units,
    required MigrationTypedUnitVerifier verifier,
    required bool allowComplete,
  }) => _safe(() async {
    try {
      return await database.transaction(() async {
        final current = await _requireRun(key);
        if (current.state != MigrationRunState.verifying &&
            !(allowComplete && current.state == MigrationRunState.complete)) {
          throw const MigrationFailure(
            MigrationFailureReason.invalidStateTransition,
          );
        }
        if (units.length != current.expectedUnits) {
          throw const MigrationFailure(
            MigrationFailureReason.verificationFailure,
          );
        }
        final identities = <({MigrationEntityKind kind, String key})>{};
        if (!units.every(
          (unit) =>
              identities.add((kind: unit.entityKind, key: unit.legacyKey)),
        )) {
          throw const MigrationFailure(
            MigrationFailureReason.verificationFailure,
          );
        }
        var verified = 0;
        var bad = false;
        for (final unit in units) {
          final outcome = await _outcomeFor(key, unit);
          if (outcome == null || !_isAcceptable(outcome)) {
            bad = true;
            continue;
          }
          final receipt = await _receiptExists(
            unit,
            key.datasetId,
            key.importerVersion,
          );
          final baseline = await _safeRows(
            key.datasetId,
            key.importerVersion,
            unit,
            SafeLegacyValuePurpose.acceptedBaseline,
          );
          final evidenceConsistent =
              receipt &&
              (unit.evidence.isEmpty || _sameEvidence(baseline, unit.evidence));
          if (!evidenceConsistent) {
            bad = true;
            await _upsertOutcome(
              key: key,
              unit: unit,
              outcome: MigrationOutcome.failed,
              diagnostic: MigrationDiagnosticCode.verificationFailed,
            );
            continue;
          }
          final disposition = switch (outcome) {
            MigrationOutcome.deferredPreserved ||
            MigrationOutcome.intentionallyExcluded =>
              MigrationVerificationDisposition.verified,
            _ => await verifier(unit, database),
          };
          switch (disposition) {
            case MigrationVerificationDisposition.verified:
              verified++;
            case MigrationVerificationDisposition.targetConflict:
              bad = true;
              await _upsertOutcome(
                key: key,
                unit: unit,
                outcome: MigrationOutcome.conflict,
                diagnostic: MigrationDiagnosticCode.conflictingEvidence,
              );
            case MigrationVerificationDisposition.verificationFailure:
              bad = true;
              await _upsertOutcome(
                key: key,
                unit: unit,
                outcome: MigrationOutcome.failed,
                diagnostic: MigrationDiagnosticCode.verificationFailed,
              );
          }
        }
        final complete = verified == current.expectedUnits && !bad;
        final nextState = complete
            ? MigrationRunState.complete
            : MigrationRunState.partial;
        await database.customStatement(
          'UPDATE migration_runs SET state=?,verified_units=? WHERE '
          'dataset_id=? AND importer_version=? AND input_digest=?',
          [
            nextState.name,
            verified,
            key.datasetId,
            key.importerVersion,
            key.inputDigest,
          ],
        );
        return MigrationRun(
          key: key,
          mappingVersion: current.mappingVersion,
          state: nextState,
          expectedUnits: current.expectedUnits,
          verifiedUnits: verified,
        );
      });
    } on MigrationFailure {
      rethrow;
    } catch (_) {
      try {
        await transition(key, MigrationRunState.failed, verifiedUnits: 0);
      } catch (_) {}
      throw const MigrationFailure(MigrationFailureReason.verificationFailure);
    }
  });

  Future<List<MigrationOutcomeRecord>> listOutcomes(
    MigrationRunKey key,
  ) => _safe(() async {
    final rows = await _select(
      'SELECT entity_kind,legacy_key,outcome,diagnostic_code,'
      'omitted_field_count FROM record_outcomes WHERE dataset_id=? AND '
      'importer_version=? AND input_digest=? ORDER BY entity_kind,legacy_key',
      [key.datasetId, key.importerVersion, key.inputDigest],
    );
    return rows
        .map(
          (row) => MigrationOutcomeRecord(
            key: key,
            entityKind: _entityKind(row.read<String>('entity_kind')),
            legacyKey: row.read<String>('legacy_key'),
            outcome: _outcome(row.read<String>('outcome')),
            diagnostic: _diagnostic(
              row.readNullable<String>('diagnostic_code'),
            ),
            omittedFieldCount: row.read<int>('omitted_field_count'),
          ),
        )
        .toList(growable: false);
  });

  Future<List<SafeLegacyValueRecord>> listSafeValues({
    required String datasetId,
    required int importerVersion,
    MigrationEntityKind? entityKind,
    String? legacyKey,
  }) => _safe(() async {
    final clauses = <String>['dataset_id=?', 'importer_version=?'];
    final args = <Object>[datasetId, importerVersion];
    if (entityKind != null) {
      clauses.add('entity_kind=?');
      args.add(entityKind.wireName);
    }
    if (legacyKey != null) {
      clauses.add('legacy_key=?');
      args.add(legacyKey);
    }
    final rows = await _select(
      'SELECT entity_kind,legacy_key,candidate_id,purpose,field,map_key,ordinal,'
      'value_type,text_value,integer_value,number_value,boolean_value '
      'FROM safe_legacy_values WHERE ${clauses.join(' AND ')} '
      'ORDER BY entity_kind,legacy_key,purpose,candidate_id,field,map_key,ordinal',
      args,
    );
    return rows.map(_safeValueFromRow).toList(growable: false);
  });

  Future<MigrationReceiptRecord?> getReceipt({
    required String datasetId,
    required int importerVersion,
    required MigrationEntityKind entityKind,
    required String legacyKey,
  }) => _safe(() async {
    final rows = await _select(
      'SELECT entity_kind,legacy_key FROM record_receipts WHERE dataset_id=? '
      'AND importer_version=? AND entity_kind=? AND legacy_key=?',
      [datasetId, importerVersion, entityKind.wireName, legacyKey],
    );
    if (rows.isEmpty) return null;
    return MigrationReceiptRecord(
      datasetId: datasetId,
      importerVersion: importerVersion,
      entityKind: _entityKind(rows.single.read<String>('entity_kind')),
      legacyKey: rows.single.read<String>('legacy_key'),
    );
  });

  Future<void> upsertReceipt({
    required String datasetId,
    required int importerVersion,
    required MigrationEntityKind entityKind,
    required String legacyKey,
  }) => _safe(() async {
    await database.transaction(() async {
      await database.customStatement(
        'INSERT OR IGNORE INTO record_receipts(dataset_id,importer_version,'
        'entity_kind,legacy_key) VALUES (?,?,?,?)',
        [datasetId, importerVersion, entityKind.wireName, legacyKey],
      );
    });
  });

  Future<MigrationOutcomeRecord?> getOutcome(
    MigrationRunKey key, {
    required MigrationEntityKind entityKind,
    required String legacyKey,
  }) => _safe(() async {
    final rows = await _select(
      'SELECT outcome,diagnostic_code,omitted_field_count FROM record_outcomes '
      'WHERE dataset_id=? AND importer_version=? AND input_digest=? '
      'AND entity_kind=? AND legacy_key=?',
      [
        key.datasetId,
        key.importerVersion,
        key.inputDigest,
        entityKind.wireName,
        legacyKey,
      ],
    );
    if (rows.isEmpty) return null;
    final row = rows.single;
    return MigrationOutcomeRecord(
      key: key,
      entityKind: entityKind,
      legacyKey: legacyKey,
      outcome: _outcome(row.read<String>('outcome')),
      diagnostic: _diagnostic(row.readNullable<String>('diagnostic_code')),
      omittedFieldCount: row.read<int>('omitted_field_count'),
    );
  });

  Future<void> upsertOutcome({
    required MigrationRunKey key,
    required MigrationUnit unit,
    required MigrationOutcome outcome,
    MigrationDiagnosticCode? diagnostic,
  }) => _safe(() async {
    await database.transaction(() async {
      await _upsertOutcome(
        key: key,
        unit: unit,
        outcome: outcome,
        diagnostic: diagnostic,
      );
    });
  });

  Future<void> addSafeEvidence({
    required MigrationRunKey key,
    required MigrationUnit unit,
    required SafeLegacyValuePurpose purpose,
  }) => _safe(() async {
    await database.transaction(() async {
      await _insertEvidence(key: key, unit: unit, purpose: purpose);
    });
  });

  Future<List<MigrationReceiptRecord>> listReceipts(
    String datasetId,
    int importerVersion,
  ) => _safe(() async {
    final rows = await _select(
      'SELECT entity_kind,legacy_key FROM record_receipts WHERE dataset_id=? '
      'AND importer_version=? ORDER BY entity_kind,legacy_key',
      [datasetId, importerVersion],
    );
    return rows
        .map(
          (row) => MigrationReceiptRecord(
            datasetId: datasetId,
            importerVersion: importerVersion,
            entityKind: _entityKind(row.read<String>('entity_kind')),
            legacyKey: row.read<String>('legacy_key'),
          ),
        )
        .toList(growable: false);
  });

  Future<MigrationRun> _requireRun(MigrationRunKey key) async {
    final rows = await _select(
      'SELECT mapping_version,state,expected_units,verified_units '
      'FROM migration_runs WHERE dataset_id=? AND importer_version=? '
      'AND input_digest=?',
      [key.datasetId, key.importerVersion, key.inputDigest],
    );
    if (rows.isEmpty) {
      throw const MigrationFailure(MigrationFailureReason.storage);
    }
    return _runFromRow(key, rows.single);
  }

  Future<void> _insertReceipt(MigrationRunKey key, MigrationUnit unit) async {
    await database.customStatement(
      'INSERT OR IGNORE INTO record_receipts(dataset_id,importer_version,'
      'entity_kind,legacy_key) VALUES (?,?,?,?)',
      [
        key.datasetId,
        key.importerVersion,
        unit.entityKind.wireName,
        unit.legacyKey,
      ],
    );
  }

  Future<MigrationOutcome?> _outcomeFor(
    MigrationRunKey key,
    MigrationUnit unit,
  ) async {
    final rows = await _select(
      'SELECT outcome FROM record_outcomes WHERE dataset_id=? AND '
      'importer_version=? AND input_digest=? AND entity_kind=? AND legacy_key=?',
      [
        key.datasetId,
        key.importerVersion,
        key.inputDigest,
        unit.entityKind.wireName,
        unit.legacyKey,
      ],
    );
    return rows.isEmpty ? null : _outcome(rows.single.read<String>('outcome'));
  }

  Future<bool> _receiptExists(
    MigrationUnit unit,
    String datasetId,
    int importerVersion,
  ) async {
    final rows = await _select(
      'SELECT 1 FROM record_receipts WHERE dataset_id=? AND importer_version=? '
      'AND entity_kind=? AND legacy_key=?',
      [datasetId, importerVersion, unit.entityKind.wireName, unit.legacyKey],
    );
    return rows.isNotEmpty;
  }

  Future<void> _insertEvidence({
    required MigrationRunKey key,
    required MigrationUnit unit,
    required SafeLegacyValuePurpose purpose,
  }) async {
    if (unit.evidence.isEmpty) return;
    final candidateId = _candidateId(unit.evidence);
    for (final evidence in unit.evidence) {
      final value = evidence.value;
      await database.customStatement(
        'INSERT OR IGNORE INTO safe_legacy_values('
        'dataset_id,importer_version,entity_kind,legacy_key,candidate_id,purpose,'
        'field,map_key,ordinal,value_type,text_value,integer_value,number_value,'
        'boolean_value) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)',
        [
          key.datasetId,
          key.importerVersion,
          unit.entityKind.wireName,
          unit.legacyKey,
          candidateId,
          purpose.wireName,
          evidence.field,
          evidence.mapKey,
          evidence.ordinal,
          value.type.name == 'nullValue' ? 'null' : value.type.name,
          value.stringValue,
          value.integerValue,
          value.numberValue,
          value.booleanValue == null ? null : (value.booleanValue! ? 1 : 0),
        ],
      );
    }
  }

  Future<List<SafeLegacyEvidence>> _safeRows(
    String datasetId,
    int importerVersion,
    MigrationUnit unit,
    SafeLegacyValuePurpose purpose,
  ) async {
    final rows = await _select(
      'SELECT field,map_key,ordinal,value_type,text_value,integer_value,'
      'number_value,boolean_value FROM safe_legacy_values WHERE dataset_id=? '
      'AND importer_version=? AND entity_kind=? AND legacy_key=? AND purpose=? '
      'ORDER BY field,map_key,ordinal',
      [
        datasetId,
        importerVersion,
        unit.entityKind.wireName,
        unit.legacyKey,
        purpose.wireName,
      ],
    );
    return rows
        .map(
          (row) => SafeLegacyEvidence(
            field: row.read<String>('field'),
            mapKey: row.read<String>('map_key'),
            ordinal: row.read<int>('ordinal'),
            value: _valueFromRow(row),
          ),
        )
        .toList(growable: false);
  }

  Future<void> _upsertOutcome({
    required MigrationRunKey key,
    required MigrationUnit unit,
    required MigrationOutcome outcome,
    required MigrationDiagnosticCode? diagnostic,
  }) async {
    await database.customStatement(
      'INSERT INTO record_outcomes(dataset_id,importer_version,input_digest,'
      'entity_kind,legacy_key,outcome,diagnostic_code,omitted_field_count) '
      'VALUES (?,?,?,?,?,?,?,?) ON CONFLICT(dataset_id,importer_version,'
      'input_digest,entity_kind,legacy_key) DO UPDATE SET outcome=excluded.outcome,'
      'diagnostic_code=excluded.diagnostic_code,omitted_field_count=excluded.'
      'omitted_field_count',
      [
        key.datasetId,
        key.importerVersion,
        key.inputDigest,
        unit.entityKind.wireName,
        unit.legacyKey,
        outcome.wireName,
        diagnostic?.wireName,
        unit.omittedFieldCount,
      ],
    );
  }

  Future<List<QueryRow>> _select(String sql, [List<Object?> args = const []]) =>
      database
          .customSelect(
            sql,
            variables: args
                .map(
                  (value) => switch (value) {
                    String text => Variable<String>(text),
                    int number => Variable<int>(number),
                    double number => Variable<double>(number),
                    _ => throw const MigrationFailure(
                      MigrationFailureReason.storage,
                    ),
                  },
                )
                .toList(),
          )
          .get();

  Future<T> _safe<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on MigrationFailure {
      rethrow;
    } catch (_) {
      throw const MigrationFailure(MigrationFailureReason.storage);
    }
  }

  static MigrationRun _runFromRow(MigrationRunKey key, QueryRow row) =>
      MigrationRun(
        key: key,
        mappingVersion: row.read<int>('mapping_version'),
        state: _runState(row.read<String>('state')),
        expectedUnits: row.read<int>('expected_units'),
        verifiedUnits: row.read<int>('verified_units'),
      );

  static SafeLegacyValueRecord _safeValueFromRow(QueryRow row) =>
      SafeLegacyValueRecord(
        entityKind: _entityKind(row.read<String>('entity_kind')),
        legacyKey: row.read<String>('legacy_key'),
        candidateId: row.read<String>('candidate_id'),
        purpose: _purpose(row.read<String>('purpose')),
        evidence: SafeLegacyEvidence(
          field: row.read<String>('field'),
          mapKey: row.read<String>('map_key'),
          ordinal: row.read<int>('ordinal'),
          value: _valueFromRow(row),
        ),
      );

  static SafeLegacyValue _valueFromRow(QueryRow row) {
    final type = row.read<String>('value_type');
    return switch (type) {
      'string' => SafeLegacyValue.string(row.read<String>('text_value')),
      'integer' => SafeLegacyValue.integer(row.read<int>('integer_value')),
      'number' => SafeLegacyValue.number(row.read<double>('number_value')),
      'boolean' => SafeLegacyValue.boolean(row.read<int>('boolean_value') == 1),
      'null' => const SafeLegacyValue.nullValue(),
      _ => throw const MigrationFailure(MigrationFailureReason.storage),
    };
  }

  static bool _sameEvidence(
    List<SafeLegacyEvidence> stored,
    List<SafeLegacyEvidence> current,
  ) => candidateIdFor(stored) == candidateIdFor(current);

  static bool _isAcceptable(MigrationOutcome outcome) =>
      outcome != MigrationOutcome.failed &&
      outcome != MigrationOutcome.conflict;

  static String _candidateId(Iterable<SafeLegacyEvidence> evidence) {
    return candidateIdFor(evidence);
  }

  static MigrationRunState _runState(String value) =>
      MigrationRunState.values.firstWhere(
        (state) => state.name == value,
        orElse: () =>
            throw const MigrationFailure(MigrationFailureReason.storage),
      );

  static MigrationEntityKind _entityKind(String value) =>
      MigrationEntityKind.values.firstWhere(
        (kind) => kind.wireName == value,
        orElse: () =>
            throw const MigrationFailure(MigrationFailureReason.storage),
      );

  static MigrationOutcome _outcome(String value) =>
      MigrationOutcome.values.firstWhere(
        (outcome) => outcome.wireName == value,
        orElse: () =>
            throw const MigrationFailure(MigrationFailureReason.storage),
      );

  static MigrationDiagnosticCode? _diagnostic(String? value) => value == null
      ? null
      : MigrationDiagnosticCode.values.firstWhere(
          (diagnostic) => diagnostic.wireName == value,
          orElse: () =>
              throw const MigrationFailure(MigrationFailureReason.storage),
        );

  static SafeLegacyValuePurpose _purpose(String value) =>
      SafeLegacyValuePurpose.values.firstWhere(
        (purpose) => purpose.wireName == value,
        orElse: () =>
            throw const MigrationFailure(MigrationFailureReason.storage),
      );

  static bool _legal(MigrationRunState from, MigrationRunState to) =>
      switch (from) {
        MigrationRunState.pending => to == MigrationRunState.applying,
        MigrationRunState.applying =>
          to == MigrationRunState.verifying ||
              to == MigrationRunState.partial ||
              to == MigrationRunState.failed,
        MigrationRunState.verifying =>
          to == MigrationRunState.complete ||
              to == MigrationRunState.partial ||
              to == MigrationRunState.failed,
        MigrationRunState.partial => to == MigrationRunState.applying,
        MigrationRunState.failed => to == MigrationRunState.applying,
        MigrationRunState.complete => false,
      };
}
