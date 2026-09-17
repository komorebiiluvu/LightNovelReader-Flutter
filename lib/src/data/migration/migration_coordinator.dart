import '../../domain/migration/migration_failure.dart';
import '../../domain/migration/migration_models.dart';
import '../../domain/migration/migration_planner.dart';
import '../../domain/migration/raw_json.dart';
import '../persistence/database.dart' show AppDatabase;
import 'migration_repository.dart';

final class MigrationCoordinator {
  MigrationCoordinator(
    this.repository, {
    MigrationResourceLimits limits = const MigrationResourceLimits(),
    MigrationUnitHandler? handler,
    this.failureInjector,
  }) : planner = MigrationPlanner(limits: limits),
       handler = handler ?? _noopHandler;

  final MigrationRepository repository;
  final MigrationPlanner planner;
  final MigrationUnitHandler handler;
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
      return repository.verifyRun(run.key);
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
    return repository.verifyRun(run.key);
  }

  static Future<void> _noopHandler(
    MigrationUnit unit,
    AppDatabase database,
  ) async {}
}
