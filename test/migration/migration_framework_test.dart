import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_reader/src/data/migration/migration_coordinator.dart';
import 'package:light_novel_reader/src/data/migration/migration_repository.dart';
import 'package:light_novel_reader/src/data/persistence/database.dart';
import 'package:light_novel_reader/src/domain/migration/migration_failure.dart';
import 'package:light_novel_reader/src/domain/migration/migration_models.dart';
import 'package:light_novel_reader/src/domain/migration/migration_planner.dart';
import 'package:light_novel_reader/src/domain/migration/raw_json.dart';

MigrationInput backup(
  String state, {
  String datasetId = 'synthetic-dataset',
  int importerVersion = initialImporterVersion,
}) => MigrationInput(
  datasetId: datasetId,
  inputType: MigrationInputType.legacyBackupV1,
  importerVersion: importerVersion,
  bytes: utf8.encode(
    '{"format":"lightnovelreader-backup","version":1,'
    '"exportedAt":"2026-09-17T00:00:00Z","wenku8Cookie":"'
    'SYNTHETIC_SECRET_DO_NOT_STORE","state":$state}',
  ),
);

MigrationInput snapshot(
  String state, {
  String datasetId = 'snapshot-dataset',
}) => MigrationInput(
  datasetId: datasetId,
  inputType: MigrationInputType.legacyIosSnapshotV1,
  bytes: utf8.encode(state),
);

Future<int> count(AppDatabase db, String table) async =>
    (await db.customSelect('SELECT count(*) AS n FROM $table').getSingle())
        .read<int>('n');

Future<void> syntheticHandler(MigrationUnit unit, AppDatabase database) =>
    database.customStatement(
      'INSERT INTO synthetic_effects(legacy_key,canonical_value) VALUES (?,?) '
      'ON CONFLICT(legacy_key) DO UPDATE SET canonical_value=excluded.canonical_value',
      [unit.legacyKey, candidateIdFor(unit.evidence)],
    );

Future<bool> syntheticVerifier(MigrationUnit unit, AppDatabase database) async {
  final rows = await database
      .customSelect(
        'SELECT canonical_value FROM synthetic_effects WHERE legacy_key=?',
        variables: [Variable<String>(unit.legacyKey)],
      )
      .get();
  return rows.length == 1 &&
      rows.single.read<String>('canonical_value') ==
          candidateIdFor(unit.evidence);
}

MigrationCoordinator coordinatorFor(
  MigrationRepository repository, {
  MigrationUnitHandler handler = syntheticHandler,
  MigrationUnitVerifier verifier = syntheticVerifier,
  MigrationFailureInjector? failureInjector,
}) => MigrationCoordinator(
  repository,
  handler: handler,
  verifier: verifier,
  failureInjector: failureInjector,
);

void main() {
  late AppDatabase db;
  late MigrationRepository repository;

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });
  tearDownAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
  });

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.customSelect('SELECT 1').get();
    await db.customStatement(
      'CREATE TABLE synthetic_effects('
      'legacy_key TEXT PRIMARY KEY, canonical_value TEXT NOT NULL)',
    );
    repository = MigrationRepository(db);
  });

  tearDown(() => db.close());

  test('raw parser preserves scalar types, ordering, escapes, and unicode', () {
    final value = RawJsonParser().parse(
      utf8.encode(
        r''' {"null":null,"bool":true,"int":42,"decimal":1.5,"exp":2e2,"text":"a\n😀","array":[false]} ''',
      ),
    );
    expect(value, isA<RawJsonObject>());
    final object = value as RawJsonObject;
    expect(object.valueFor('null'), isA<RawJsonNull>());
    expect((object.valueFor('bool')! as RawJsonBoolean).value, isTrue);
    expect((object.valueFor('int')! as RawJsonInteger).value, 42);
    expect((object.valueFor('decimal')! as RawJsonNumber).value, 1.5);
    expect((object.valueFor('exp')! as RawJsonNumber).value, 200);
    expect((object.valueFor('text')! as RawJsonString).value, 'a\n😀');
  });

  test(
    'raw parser accepts JSON unicode surrogate pairs and control escapes',
    () {
      final value = RawJsonParser().parse(
        utf8.encode(r'"\uD83D\uDE00\b\f\n\r\t\/"'),
      );
      expect(value, isA<RawJsonString>());
      expect((value as RawJsonString).value, '😀\b\f\n\r\t/');
    },
  );

  test(
    'strict parser rejects duplicate keys while import mode retains them',
    () {
      final bytes = utf8.encode('{"a":1,"a":2}');
      expect(
        () => RawJsonParser().parse(bytes),
        throwsA(
          isA<MigrationFailure>().having(
            (error) => error.reason,
            'reason',
            MigrationFailureReason.duplicateKey,
          ),
        ),
      );
      final value = RawJsonParser().parse(bytes, allowDuplicateKeys: true);
      expect((value as RawJsonObject).hasDuplicateKeys, isTrue);
    },
  );

  test('raw parser rejects invalid UTF-8, malformed numbers, surrogates, and tails', () {
    final inputs = <List<int>>[
      [0xC3, 0x28],
      utf8.encode('01'),
      utf8.encode('+1'),
      utf8.encode('1.'),
      utf8.encode('1e'),
      utf8.encode(r'"\uD800"'),
      utf8.encode('{"a":1'),
      utf8.encode('[1,2'),
      utf8.encode('null false'),
      utf8.encode('null trailing'),
    ];
    for (final input in inputs) {
      expect(
        () => RawJsonParser().parse(input),
        throwsA(isA<MigrationFailure>()),
      );
    }
  });

  test('parser limits are typed and injectable', () {
    final limits = const MigrationResourceLimits(
      maxNestingDepth: 2,
      maxObjectFields: 1,
      maxArrayElements: 1,
      maxStringLength: 2,
      maxParsedNodes: 2,
    );
    for (final json in ['[[[0]]]', '{"a":1,"b":2}', '[1,2]', '"abc"']) {
      expect(
        () => RawJsonParser(limits: limits).parse(utf8.encode(json)),
        throwsA(
          isA<MigrationFailure>().having(
            (error) => error.reason,
            'reason',
            MigrationFailureReason.resourceLimit,
          ),
        ),
      );
    }
    expect(
      () =>
          RawJsonParser(limits: const MigrationResourceLimits(maxInputBytes: 1))
              .parse(utf8.encode('null')),
      throwsA(
        isA<MigrationFailure>().having(
          (error) => error.reason,
          'reason',
          MigrationFailureReason.resourceLimit,
        ),
      ),
    );
    expect(
      () => MigrationPlanner(
        limits: const MigrationResourceLimits(maxPlannedUnits: 0),
      ).plan(backup('{"bookLibrary":[{"id":"a"}]}')),
      throwsA(
        isA<MigrationFailure>().having(
          (error) => error.reason,
          'reason',
          MigrationFailureReason.resourceLimit,
        ),
      ),
    );
  });

  test(
    'explicit backup and snapshot types have distinct envelope rules',
    () async {
      await repository.ensureDataset('snapshot-dataset');
      final coordinator = coordinatorFor(repository);
      final snapshotRun = await coordinator.importInput(
        snapshot('{"theme":"dark"}'),
      );
      expect(snapshotRun.state, MigrationRunState.complete);
      expect(
        () => MigrationPlanner().plan(
          MigrationInput(
            datasetId: 'snapshot-dataset',
            inputType: MigrationInputType.legacyBackupV1,
            bytes: utf8.encode('{"theme":"dark"}'),
          ),
        ),
        throwsA(
          isA<MigrationFailure>().having(
            (error) => error.reason,
            'reason',
            MigrationFailureReason.invalidEnvelope,
          ),
        ),
      );
      expect(
        () => MigrationPlanner().plan(
          MigrationInput(
            datasetId: 'snapshot-dataset',
            inputType: MigrationInputType.legacyIosSnapshotV1,
            bytes: backup('{"theme":"dark"}').bytes,
          ),
        ),
        throwsA(isA<MigrationFailure>()),
      );
    },
  );

  test('fatal envelope failure writes no migration rows', () async {
    await repository.ensureDataset('fatal-dataset');
    final coordinator = coordinatorFor(repository);
    final invalid = MigrationInput(
      datasetId: 'fatal-dataset',
      inputType: MigrationInputType.legacyBackupV1,
      bytes: utf8.encode('{"format":"lightnovelreader-backup","version":1}'),
    );
    await expectLater(
      coordinator.importInput(invalid),
      throwsA(isA<MigrationFailure>()),
    );
    expect(await count(db, 'migration_runs'), 0);
    expect(await count(db, 'record_receipts'), 0);
    expect(await count(db, 'safe_legacy_values'), 0);
  });

  test('duplicate top-level and state keys are envelope-fatal', () {
    final topLevel = MigrationInput(
      datasetId: 'duplicate-envelope',
      inputType: MigrationInputType.legacyBackupV1,
      bytes: utf8.encode(
        '{"format":"lightnovelreader-backup","format":"other",'
        '"version":1,"exportedAt":"2026-09-17T00:00:00Z",'
        '"state":{}}',
      ),
    );
    final state = MigrationInput(
      datasetId: 'duplicate-envelope',
      inputType: MigrationInputType.legacyBackupV1,
      bytes: utf8.encode(
        '{"format":"lightnovelreader-backup","version":1,'
        '"exportedAt":"2026-09-17T00:00:00Z",'
        '"state":{"theme":"system","theme":"dark"}}',
      ),
    );
    for (final input in [topLevel, state]) {
      expect(
        () => MigrationPlanner().plan(input),
        throwsA(
          isA<MigrationFailure>().having(
            (error) => error.reason,
            'reason',
            MigrationFailureReason.invalidEnvelope,
          ),
        ),
      );
    }
  });

  test('duplicate record is isolated from valid siblings and corrected input can retry it', () async {
    await repository.ensureDataset('records-dataset');
    final first = backup(
      '{"bookLibrary":['
      '{"id":"a","title":"A"},'
      '{"id":"b","title":"B","title":"duplicate"},'
      '{"id":"c","title":"C"}]}',
      datasetId: 'records-dataset',
    );
    final coordinator = coordinatorFor(repository);
    final partial = await coordinator.importInput(first);
    expect(partial.state, MigrationRunState.partial);
    final outcomes = await repository.listOutcomes(first.runKey);
    expect(
      outcomes.map((record) => record.outcome),
      containsAllInOrder([
        MigrationOutcome.imported,
        MigrationOutcome.failed,
        MigrationOutcome.imported,
      ]),
    );
    expect(
      (await repository.listReceipts(
        'records-dataset',
        1,
      )).map((receipt) => receipt.legacyKey),
      ['a', 'b', 'c'],
    );

    final corrected = backup(
      '{"bookLibrary":['
      '{"id":"a","title":"A"},'
      '{"id":"b","title":"B"},'
      '{"id":"c","title":"C"}]}',
      datasetId: 'records-dataset',
    );
    final complete = await coordinator.importInput(corrected);
    expect(complete.state, MigrationRunState.complete);
    expect(await count(db, 'record_receipts'), 3);
  });

  test('malformed record with duplicate non-ID field keeps its stable ID', () {
    final plan = MigrationPlanner().plan(
      backup('{"bookLibrary":[{"id":"b","title":"B","title":"duplicate"}]}'),
    );
    expect(plan.units.single.legacyKey, 'b');
    expect(plan.units.single.diagnostic, MigrationDiagnosticCode.invalidField);
  });

  test('duplicate ID fields use a positional failure key', () {
    final plan = MigrationPlanner().plan(
      backup('{"bookLibrary":[{"id":"b","id":"other","title":"B"}]}'),
    );
    expect(plan.units.single.legacyKey, 'bookLibrary[0]');
    expect(plan.units.single.legacyKey, isNot(anyOf('b', 'other')));
  });

  test('malformed shelf with duplicate non-ID field keeps its stable ID', () {
    final plan = MigrationPlanner().plan(
      backup('{"shelves":[{"id":"shelf-b","name":"B","name":"duplicate"}]}'),
    );
    expect(plan.units.single.entityKind, MigrationEntityKind.shelf);
    expect(plan.units.single.legacyKey, 'shelf-b');
    expect(plan.units.single.diagnostic, MigrationDiagnosticCode.invalidField);
  });

  test(
    'duplicate stable IDs become one explicit conflict while siblings survive',
    () async {
      await repository.ensureDataset('duplicate-id-dataset');
      final input = backup(
        '{"bookLibrary":['
        '{"id":"same","title":"A"},'
        '{"id":"same","title":"B"},'
        '{"id":"sibling","title":"S"}]}',
        datasetId: 'duplicate-id-dataset',
      );
      final plan = MigrationPlanner().plan(input);
      expect(plan.units, hasLength(2));
      expect(plan.units.first.legacyKey, 'same');
      expect(
        plan.units.first.diagnostic,
        MigrationDiagnosticCode.conflictingEvidence,
      );

      final run = await coordinatorFor(repository).importInput(input);
      expect(run.state, MigrationRunState.partial);
      expect(run.expectedUnits, 2);
      expect(run.verifiedUnits, 1);
      final outcomes = await repository.listOutcomes(input.runKey);
      expect(
        outcomes.map(
          (outcome) => '${outcome.legacyKey}:${outcome.outcome.wireName}',
        ),
        containsAll(<String>['same:failed', 'sibling:imported']),
      );
      expect(
        outcomes
            .singleWhere((outcome) => outcome.legacyKey == 'same')
            .diagnostic,
        MigrationDiagnosticCode.conflictingEvidence,
      );
      expect(
        (await repository.listReceipts(
          'duplicate-id-dataset',
          1,
        )).map((receipt) => receipt.legacyKey),
        ['same', 'sibling'],
      );
    },
  );

  test('run identity is exact bytes, dataset, and importer version', () async {
    await repository.ensureDataset('identity-a');
    await repository.ensureDataset('identity-b');
    final one = backup('{"theme":"dark"}', datasetId: 'identity-a');
    final same = backup('{"theme":"dark"}', datasetId: 'identity-a');
    final changed = backup('{"theme":"light"}', datasetId: 'identity-a');
    final otherDataset = backup('{"theme":"dark"}', datasetId: 'identity-b');
    final laterImporter = backup(
      '{"theme":"dark"}',
      datasetId: 'identity-a',
      importerVersion: 2,
    );
    await repository.ensureDataset('identity-a');
    final coordinator = coordinatorFor(repository);
    final firstRun = await coordinator.importInput(one);
    final sameRun = await coordinator.importInput(same);
    final changedRun = await coordinator.importInput(changed);
    final otherRun = await coordinator.importInput(otherDataset);
    final laterRun = await coordinator.importInput(laterImporter);
    expect(sameRun.key, firstRun.key);
    expect(changedRun.key, isNot(firstRun.key));
    expect(otherRun.key, isNot(firstRun.key));
    expect(laterRun.key, isNot(firstRun.key));
    expect(one.inputDigest, matches(RegExp(r'^[0-9a-f]{64}$')));
    expect(one.bytes, same.bytes);
  });

  test('accepted baseline stays immutable and changed evidence becomes conflict candidate', () async {
    await repository.ensureDataset('conflict-dataset');
    final coordinator = coordinatorFor(repository);
    final first = backup(
      '{"bookLibrary":[{"id":"book","title":"Original"}]}',
      datasetId: 'conflict-dataset',
    );
    final second = backup(
      '{"bookLibrary":[{"id":"book","title":"Changed"}]}',
      datasetId: 'conflict-dataset',
    );
    expect(
      (await coordinator.importInput(first)).state,
      MigrationRunState.complete,
    );
    expect(
      (await coordinator.importInput(second)).state,
      MigrationRunState.partial,
    );
    final values = await repository.listSafeValues(
      datasetId: 'conflict-dataset',
      importerVersion: 1,
      entityKind: MigrationEntityKind.book,
      legacyKey: 'book',
    );
    expect(
      values.where(
        (value) => value.purpose == SafeLegacyValuePurpose.acceptedBaseline,
      ),
      hasLength(2),
    );
    expect(
      values.where(
        (value) => value.purpose == SafeLegacyValuePurpose.conflictCandidate,
      ),
      isNotEmpty,
    );
    expect(
      values
          .where(
            (value) =>
                value.purpose == SafeLegacyValuePurpose.acceptedBaseline &&
                value.evidence.field == 'book.title',
          )
          .single
          .evidence
          .value
          .typedValue,
      'Original',
    );
  });

  test(
    'handler mutation rolls back atomically while sibling units commit',
    () async {
      await repository.ensureDataset('atomic-dataset');
      final coordinator = MigrationCoordinator(
        repository,
        handler: (unit, database) async {
          await database.customStatement(
            'INSERT INTO synthetic_effects(legacy_key,canonical_value) '
            'VALUES (?,?)',
            [unit.legacyKey, candidateIdFor(unit.evidence)],
          );
          if (unit.legacyKey == 'b') throw StateError('synthetic failure');
        },
        verifier: syntheticVerifier,
      );
      final input = backup(
        '{"bookLibrary":[{"id":"a","title":"A"},{"id":"b","title":"B"}]}',
        datasetId: 'atomic-dataset',
      );
      final run = await coordinator.importInput(input);
      expect(run.state, MigrationRunState.partial);
      expect(await count(db, 'synthetic_effects'), 1);
      expect(
        (await db
                .customSelect('SELECT legacy_key FROM synthetic_effects')
                .getSingle())
            .read<String>('legacy_key'),
        'a',
      );
    },
  );

  test('temporary file database reopens and resumes the same run', () async {
    final directory = await Directory.systemTemp.createTemp('lnr-f26-');
    final path = '${directory.path}${Platform.pathSeparator}migration.sqlite';
    final bytes = backup(
      '{"bookLibrary":[{"id":"a","title":"A"},{"id":"b","title":"B"}]}',
      datasetId: 'file-dataset',
    );
    var fileDb = AppDatabase(NativeDatabase(File(path)));
    await fileDb.customSelect('SELECT 1').get();
    await fileDb.customStatement(
      'CREATE TABLE IF NOT EXISTS synthetic_effects('
      'legacy_key TEXT PRIMARY KEY, canonical_value TEXT NOT NULL)',
    );
    var fileRepository = MigrationRepository(fileDb);
    await fileRepository.ensureDataset('file-dataset');
    var failOnce = true;
    final firstCoordinator = MigrationCoordinator(
      fileRepository,
      handler: (unit, database) async {
        if (unit.legacyKey == 'b' && failOnce) {
          failOnce = false;
          throw StateError('interrupt');
        }
        await syntheticHandler(unit, database);
      },
      verifier: syntheticVerifier,
    );
    final first = await firstCoordinator.importInput(bytes);
    expect(first.state, MigrationRunState.partial);
    await fileDb.close();

    fileDb = AppDatabase(NativeDatabase(File(path)));
    await fileDb.customSelect('SELECT 1').get();
    await fileDb.customStatement(
      'CREATE TABLE IF NOT EXISTS synthetic_effects('
      'legacy_key TEXT PRIMARY KEY, canonical_value TEXT NOT NULL)',
    );
    fileRepository = MigrationRepository(fileDb);
    var resumedHandlerCalls = 0;
    final resumed = await coordinatorFor(
      fileRepository,
      handler: (unit, database) async {
        resumedHandlerCalls++;
        await syntheticHandler(unit, database);
      },
    ).importInput(bytes);
    expect(resumed.key, first.key);
    expect(resumed.state, MigrationRunState.complete);
    expect(resumedHandlerCalls, 1);
    expect(await fileRepository.listReceipts('file-dataset', 1), hasLength(2));
    await fileDb.close();
    await directory.delete(recursive: true);
  });

  test('secret and unknown values never enter migration storage', () async {
    await repository.ensureDataset('secret-dataset');
    final original = utf8.encode(
      '{"format":"lightnovelreader-backup","version":1,'
      '"exportedAt":"2026-09-17T00:00:00Z","wenku8Cookie":"'
      'SYNTHETIC_SECRET_DO_NOT_STORE","state":{"bookLibrary":[{'
      '"id":"safe","title":"Safe","password":"SYNTHETIC_SECRET_DO_NOT_STORE",'
      '"metadata":{"token":"SYNTHETIC_SECRET_DO_NOT_STORE"}}]}}',
    );
    final input = MigrationInput(
      datasetId: 'secret-dataset',
      inputType: MigrationInputType.legacyBackupV1,
      bytes: original,
    );
    final run = await coordinatorFor(repository).importInput(input);
    expect(run.state, MigrationRunState.complete);
    expect(input.bytes, original);
    final values = await db
        .customSelect(
          'SELECT text_value FROM safe_legacy_values WHERE text_value IS NOT NULL',
        )
        .get();
    final outcomes = await db
        .customSelect('SELECT diagnostic_code,legacy_key FROM record_outcomes')
        .get();
    expect(
      values.map((row) => row.read<String>('text_value')),
      isNot(contains('SYNTHETIC_SECRET_DO_NOT_STORE')),
    );
    expect(
      outcomes.map((row) => row.read<String>('legacy_key')),
      isNot(contains('SYNTHETIC_SECRET_DO_NOT_STORE')),
    );
  });

  test('receipt and outcome alone cannot cause COMPLETE', () async {
    await repository.ensureDataset('receipt-only-dataset');
    final input = backup(
      '{"bookLibrary":[{"id":"manual","title":"Manual"}]}',
      datasetId: 'receipt-only-dataset',
    );
    final plan = MigrationPlanner().plan(input);
    final run = await repository.createOrReuseRun(
      key: plan.runKey,
      mappingVersion: input.mappingVersion,
      expectedUnits: plan.units.length,
    );
    await repository.transition(run.key, MigrationRunState.applying);
    await repository.upsertReceipt(
      datasetId: input.datasetId,
      importerVersion: input.importerVersion,
      entityKind: plan.units.single.entityKind,
      legacyKey: plan.units.single.legacyKey,
    );
    await repository.upsertOutcome(
      key: run.key,
      unit: plan.units.single,
      outcome: MigrationOutcome.imported,
    );
    await repository.transition(run.key, MigrationRunState.verifying);
    final verified = await repository.verifyRun(
      key: run.key,
      units: plan.units,
      verifier: syntheticVerifier,
    );
    expect(verified.state, MigrationRunState.partial);
    expect(verified.verifiedUnits, 0);
    expect(
      (await repository.getOutcome(
        run.key,
        entityKind: plan.units.single.entityKind,
        legacyKey: plan.units.single.legacyKey,
      ))!.diagnostic,
      MigrationDiagnosticCode.verificationFailed,
    );
  });

  test(
    'verifier false blocks COMPLETE without clearing durable state',
    () async {
      await repository.ensureDataset('false-verifier-dataset');
      final input = backup(
        '{"bookLibrary":[{"id":"false","title":"False"}]}',
        datasetId: 'false-verifier-dataset',
      );
      final run = await coordinatorFor(
        repository,
        verifier: (unit, database) async => false,
      ).importInput(input);
      expect(run.state, MigrationRunState.partial);
      expect(await count(db, 'synthetic_effects'), 1);
      expect(
        (await repository.getOutcome(
          input.runKey,
          entityKind: MigrationEntityKind.book,
          legacyKey: 'false',
        ))!.diagnostic,
        MigrationDiagnosticCode.verificationFailed,
      );
    },
  );

  test('verifier exception becomes a safe verification failure', () async {
    await repository.ensureDataset('exception-verifier-dataset');
    final input = backup(
      '{"bookLibrary":[{"id":"exception","title":"Exception"}]}',
      datasetId: 'exception-verifier-dataset',
    );
    final run = await coordinatorFor(
      repository,
      verifier: (unit, database) async => throw StateError('verification'),
    ).importInput(input);
    expect(run.state, MigrationRunState.partial);
    expect(
      (await repository.getOutcome(
        input.runKey,
        entityKind: MigrationEntityKind.book,
        legacyKey: 'exception',
      ))!.diagnostic,
      MigrationDiagnosticCode.verificationFailed,
    );
  });

  test('run transitions reject arbitrary backwards movement', () async {
    await repository.ensureDataset('state-dataset');
    final input = backup('{"theme":"dark"}', datasetId: 'state-dataset');
    final planner = MigrationPlanner();
    final plan = planner.plan(input);
    final run = await repository.createOrReuseRun(
      key: plan.runKey,
      mappingVersion: 1,
      expectedUnits: plan.units.length,
    );
    expect(run.state, MigrationRunState.pending);
    await expectLater(
      repository.transition(run.key, MigrationRunState.complete),
      throwsA(
        isA<MigrationFailure>().having(
          (error) => error.reason,
          'reason',
          MigrationFailureReason.invalidStateTransition,
        ),
      ),
    );
  });
}
