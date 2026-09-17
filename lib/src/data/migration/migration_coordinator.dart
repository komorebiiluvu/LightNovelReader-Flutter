import '../../domain/migration/migration_failure.dart';
import '../../domain/migration/migration_models.dart';
import '../../domain/migration/migration_planner.dart';
import '../../domain/migration/raw_json.dart';
import 'migration_repository.dart';

typedef MigrationPlanBuilder = MigrationPlan Function(MigrationInput input);

final class MigrationCoordinator {
  MigrationCoordinator(
    this.repository, {
    this.handler,
    this.verifier,
    this.applier,
    this.typedVerifier,
    MigrationResourceLimits limits = const MigrationResourceLimits(),
    this.failureInjector,
    this.planBuilder,
  }) : planner = MigrationPlanner(limits: limits) {
    final legacyPair = handler != null && verifier != null;
    final typedPair = applier != null && typedVerifier != null;
    if (legacyPair == typedPair) {
      throw ArgumentError(
        'MigrationCoordinator requires exactly one handler/verifier pair.',
      );
    }
  }

  final MigrationRepository repository;
  final MigrationPlanner planner;
  final MigrationUnitHandler? handler;
  final MigrationUnitVerifier? verifier;
  final MigrationUnitApplier? applier;
  final MigrationTypedUnitVerifier? typedVerifier;
  final MigrationFailureInjector? failureInjector;
  final MigrationPlanBuilder? planBuilder;

  Future<MigrationRun> importInput(MigrationInput input) async {
    // Planning is deliberately before any database write. Envelope-fatal
    // failures therefore leave no run and no target/evidence rows.
    final plan = planBuilder?.call(input) ?? planner.plan(input);
    if (!await repository.datasetExists(input.datasetId)) {
      throw const MigrationFailure(MigrationFailureReason.datasetNotRegistered);
    }
    var run = await repository.createOrReuseRun(
      key: plan.runKey,
      mappingVersion: input.mappingVersion,
      expectedUnits: plan.units.length,
    );
    if (run.state == MigrationRunState.complete) {
      if (applier != null) {
        return repository.verifyCompletedRun(
          key: run.key,
          units: plan.units,
          verifier: typedVerifier!,
        );
      }
      return run;
    }

    if (run.state == MigrationRunState.verifying) {
      if (applier != null) {
        return repository.verifyRunWithResult(
          key: run.key,
          units: plan.units,
          verifier: typedVerifier!,
        );
      }
      return repository.verifyRun(
        key: run.key,
        units: plan.units,
        verifier: verifier!,
      );
    }
    run = await repository.transition(run.key, MigrationRunState.applying);

    for (final unit in plan.units) {
      try {
        if (applier != null) {
          await repository.applyUnitWithResult(
            key: run.key,
            unit: unit,
            applier: applier!,
            failureInjector: failureInjector,
          );
        } else {
          await repository.applyUnit(
            key: run.key,
            unit: unit,
            handler: handler!,
            failureInjector: failureInjector,
          );
        }
      } on MigrationFailure catch (error) {
        await repository.recordFailure(
          key: run.key,
          unit: unit,
          diagnostic: error.reason == MigrationFailureReason.verificationFailure
              ? MigrationDiagnosticCode.verificationFailed
              : MigrationDiagnosticCode.invalidField,
        );
      }
    }
    run = await repository.transition(run.key, MigrationRunState.verifying);
    if (applier != null) {
      return repository.verifyRunWithResult(
        key: run.key,
        units: plan.units,
        verifier: typedVerifier!,
      );
    }
    return repository.verifyRun(
      key: run.key,
      units: plan.units,
      verifier: verifier!,
    );
  }
}
