import '../../domain/migration/migration_failure.dart';
import '../../domain/migration/migration_models.dart';
import '../../domain/migration/migration_planner.dart';
import '../../domain/migration/raw_json.dart';
import 'migration_repository.dart';

final class MigrationCoordinator {
  MigrationCoordinator(
    this.repository, {
    required this.handler,
    required this.verifier,
    MigrationResourceLimits limits = const MigrationResourceLimits(),
    this.failureInjector,
  }) : planner = MigrationPlanner(limits: limits);

  final MigrationRepository repository;
  final MigrationPlanner planner;
  final MigrationUnitHandler handler;
  final MigrationUnitVerifier verifier;
  final MigrationFailureInjector? failureInjector;

  Future<MigrationRun> importInput(MigrationInput input) async {
    // Planning is deliberately before any database write. Envelope-fatal
    // failures therefore leave no run and no target/evidence rows.
    final plan = planner.plan(input);
    if (!await repository.datasetExists(input.datasetId)) {
      throw const MigrationFailure(MigrationFailureReason.datasetNotRegistered);
    }
    var run = await repository.createOrReuseRun(
      key: plan.runKey,
      mappingVersion: input.mappingVersion,
      expectedUnits: plan.units.length,
    );
    if (run.state == MigrationRunState.complete) return run;

    if (run.state == MigrationRunState.verifying) {
      return repository.verifyRun(
        key: run.key,
        units: plan.units,
        verifier: verifier,
      );
    }
    run = await repository.transition(run.key, MigrationRunState.applying);

    for (final unit in plan.units) {
      try {
        await repository.applyUnit(
          key: run.key,
          unit: unit,
          handler: handler,
          failureInjector: failureInjector,
        );
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
    return repository.verifyRun(
      key: run.key,
      units: plan.units,
      verifier: verifier,
    );
  }
}
