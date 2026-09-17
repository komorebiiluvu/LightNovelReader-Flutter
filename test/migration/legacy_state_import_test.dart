import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_reader/src/data/migration/legacy_state_import_service.dart';
import 'package:light_novel_reader/src/data/migration/migration_repository.dart';
import 'package:light_novel_reader/src/data/persistence/database.dart';
import 'package:light_novel_reader/src/domain/migration/migration_models.dart';

Future<List<int>> fixture(String name) =>
    File('test/fixtures/$name').readAsBytes();

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.customSelect('SELECT 1').get();
  });

  tearDown(() => db.close());

  test(
    'full backup converts concrete product state and remains complete',
    () async {
      const dataset = 'f2-7-full-backup';
      final input = MigrationInput(
        datasetId: dataset,
        inputType: MigrationInputType.legacyBackupV1,
        bytes: await fixture('f2_7_full_backup_v1.json'),
      );
      final service = LegacyStateImportService(db);
      await service.repository.ensureDataset(dataset);
      final result = await service.importWithReport(input);

      expect(result.run.state, MigrationRunState.complete);
      expect(result.report.conflicts, 0);
      expect(result.report.failures, 0);
      expect(result.report.deferredRecords, greaterThanOrEqualTo(2));
      expect(result.report.unresolvedRecords, greaterThan(0));
      expect(
        result.report.expectedByKind,
        containsPair(MigrationEntityKind.source, 5),
      );
      expect(
        result.report.expectedByKind,
        containsPair(MigrationEntityKind.book, 4),
      );
      expect(
        result.report.expectedByKind,
        containsPair(MigrationEntityKind.shelf, 2),
      );
      expect(
        result.report.expectedByKind,
        containsPair(MigrationEntityKind.group, 2),
      );
      expect(
        result.report.expectedByKind,
        containsPair(MigrationEntityKind.split, 1),
      );
      expect(
        result.report.expectedByKind,
        containsPair(MigrationEntityKind.progress, 3),
      );
      expect(
        result.report.expectedByKind,
        containsPair(MigrationEntityKind.readerPreferences, 1),
      );
      expect(
        result.report.expectedByKind,
        containsPair(MigrationEntityKind.appPreferences, 1),
      );
      expect(
        result.report.expectedByKind,
        containsPair(MigrationEntityKind.statistics, 1),
      );
      expect(
        result.report.expectedByKind,
        containsPair(MigrationEntityKind.searchHistory, 1),
      );
      expect(
        result.report.outcomeCounts,
        containsPair(MigrationOutcome.imported, 10),
      );
      expect(
        result.report.outcomeCounts,
        containsPair(MigrationOutcome.preservedUnresolved, 8),
      );
      expect(
        result.report.outcomeCounts,
        containsPair(MigrationOutcome.deferredPreserved, 3),
      );

      final sources = await db
          .customSelect(
            'SELECT source_id,availability FROM source_registrations ORDER BY source_id',
          )
          .get();
      expect(
        sources.map((r) => r.read<String>('source_id')),
        contains('builtin.wenku8'),
      );
      expect(
        sources
            .map((r) => r.read<String>('source_id'))
            .where((id) => id.startsWith('legacy.ios.name.')),
        isNotEmpty,
      );
      expect(
        (await db
                .customSelect(
                  'SELECT availability FROM source_registrations WHERE source_id=?',
                  variables: [const Variable<String>('builtin.wenku8')],
                )
                .getSingle())
            .read<String>('availability'),
        'unavailable',
      );
      expect(
        (await db
                .customSelect(
                  'SELECT book_id,saved FROM library_entries WHERE source_id=? AND book_id=?',
                  variables: [
                    const Variable<String>('builtin.wenku8'),
                    const Variable<String>('wk8-000123'),
                  ],
                )
                .getSingle())
            .read<String>('book_id'),
        'wk8-000123',
      );
      expect(
        (await db
                .customSelect(
                  'SELECT saved FROM library_entries WHERE book_id=?',
                  variables: [const Variable<String>('orphan-1')],
                )
                .getSingle())
            .read<int>('saved'),
        1,
      );
      expect(
        (await db
                .customSelect(
                  'SELECT book_id FROM library_entries WHERE book_id=?',
                  variables: [const Variable<String>('unknown#id')],
                )
                .getSingle())
            .read<String>('book_id'),
        'unknown#id',
      );
      expect(
        (await db
                .customSelect(
                  'SELECT ordinal,book_id FROM shelf_members WHERE shelf_id=(SELECT target_shelf_id FROM legacy_identity_mappings WHERE entity_kind=? AND legacy_key=? AND dataset_id=?) ORDER BY ordinal',
                  variables: [
                    const Variable<String>('shelf'),
                    const Variable<String>('shelf-a'),
                    const Variable<String>(dataset),
                  ],
                )
                .get())
            .map((r) => r.read<String>('book_id')),
        ['wk8-000123', 'orphan-1', 'unknown#id'],
      );
      expect(
        (await db
                .customSelect('SELECT ordinal FROM shelves ORDER BY ordinal')
                .get())
            .map((r) => r.read<int>('ordinal')),
        [0, 1],
      );
      expect(
        (await db
                .customSelect('SELECT display_name FROM manual_groups')
                .getSingle())
            .read<String>('display_name'),
        '手动组',
      );
      expect(
        (await db
                .customSelect(
                  'SELECT is_split FROM split_overrides WHERE book_id=?',
                  variables: [const Variable<String>('unknown#id')],
                )
                .getSingle())
            .read<int>('is_split'),
        1,
      );
      expect(
        (await db
                .customSelect(
                  'SELECT chapter_index,fraction,raw_offset_key FROM legacy_chapter_locators WHERE book_id=?',
                  variables: [const Variable<String>('wk8-000123')],
                )
                .getSingle())
            .read<int>('chapter_index'),
        5,
      );
      expect(
        (await db
                .customSelect(
                  'SELECT has_read,last_read_at FROM reading_progress WHERE book_id=?',
                  variables: [const Variable<String>('unknown#id')],
                )
                .getSingle())
            .read<int>('has_read'),
        1,
      );
      expect(
        (await db
                .customSelect('SELECT accent FROM app_preferences')
                .getSingle())
            .readNullable<String>('accent'),
        isNull,
      );
      expect(
        (await db
                .customSelect(
                  'SELECT count(*) AS n FROM safe_legacy_values WHERE text_value LIKE ?',
                  variables: [const Variable<String>('%F2_7_SECRET%')],
                )
                .getSingle())
            .read<int>('n'),
        0,
      );

      final repeated = await service.importWithReport(input);
      expect(repeated.run.key, result.run.key);
      expect(repeated.run.state, MigrationRunState.complete);
      expect(
        (await db.customSelect('SELECT count(*) AS n FROM shelves').getSingle())
            .read<int>('n'),
        2,
      );
      expect(
        (await db
                .customSelect('SELECT count(*) AS n FROM group_members')
                .getSingle())
            .read<int>('n'),
        2,
      );
    },
  );

  test(
    'snapshot input converts equivalent state under a separate lineage',
    () async {
      const dataset = 'f2-7-full-snapshot';
      final input = MigrationInput(
        datasetId: dataset,
        inputType: MigrationInputType.legacyIosSnapshotV1,
        bytes: await fixture('f2_7_full_snapshot_v1.json'),
      );
      final service = LegacyStateImportService(db);
      await service.repository.ensureDataset(dataset);
      final result = await service.importWithReport(input);
      expect(result.run.state, MigrationRunState.complete);
      expect(
        (await db
                .customSelect('SELECT count(*) AS n FROM library_entries')
                .getSingle())
            .read<int>('n'),
        greaterThanOrEqualTo(4),
      );
    },
  );

  test(
    'post-import user edit is a target conflict, not a false complete',
    () async {
      const dataset = 'f2-7-edit';
      final input = MigrationInput(
        datasetId: dataset,
        inputType: MigrationInputType.legacyBackupV1,
        bytes: await fixture('f2_7_full_backup_v1.json'),
      );
      final service = LegacyStateImportService(db);
      await service.repository.ensureDataset(dataset);
      final first = await service.importWithReport(input);
      expect(first.run.state, MigrationRunState.complete);
      await db.customStatement(
        'UPDATE library_entries SET title=? WHERE source_id=? AND book_id=?',
        ['user edit', 'builtin.wenku8', 'wk8-000123'],
      );
      final second = await service.importWithReport(input);
      expect(second.run.state, MigrationRunState.partial);
      expect(second.report.conflicts, greaterThan(0));
      expect(
        (await db
                .customSelect(
                  'SELECT title FROM library_entries WHERE book_id=?',
                  variables: [const Variable<String>('wk8-000123')],
                )
                .getSingle())
            .read<String>('title'),
        'user edit',
      );
    },
  );

  test(
    'unit failure rolls back product effect and retry resumes safely',
    () async {
      const dataset = 'f2-7-failure-injection';
      final input = MigrationInput(
        datasetId: dataset,
        inputType: MigrationInputType.legacyBackupV1,
        bytes: await fixture('f2_7_full_backup_v1.json'),
      );
      var failOnce = true;
      final service = LegacyStateImportService(
        db,
        failureInjector: (point) {
          if (failOnce && point == MigrationFailurePoint.afterHandler) {
            failOnce = false;
            throw StateError('synthetic transaction failure');
          }
        },
      );
      await service.repository.ensureDataset(dataset);
      final partial = await service.importWithReport(input);
      expect(partial.run.state, MigrationRunState.partial);
      expect(
        (await db
                .customSelect(
                  'SELECT count(*) AS n FROM record_outcomes WHERE outcome=?',
                  variables: [const Variable<String>('failed')],
                )
                .getSingle())
            .read<int>('n'),
        greaterThan(0),
      );
      final resumed = await service.importWithReport(input);
      expect(resumed.run.state, MigrationRunState.complete);
    },
  );

  test('file database closes, reopens, and reuses mappings and run', () async {
    final directory = await Directory.systemTemp.createTemp('lnr-f27-');
    final path = '${directory.path}${Platform.pathSeparator}migration.sqlite';
    const dataset = 'f2-7-reopen';
    final input = MigrationInput(
      datasetId: dataset,
      inputType: MigrationInputType.legacyBackupV1,
      bytes: await fixture('f2_7_full_backup_v1.json'),
    );
    var fileDb = AppDatabase(NativeDatabase(File(path)));
    await fileDb.customSelect('SELECT 1').get();
    var service = LegacyStateImportService(fileDb);
    await service.repository.ensureDataset(dataset);
    final first = await service.importInput(input);
    expect(first.state, MigrationRunState.complete);
    await fileDb.close();

    fileDb = AppDatabase(NativeDatabase(File(path)));
    await fileDb.customSelect('SELECT 1').get();
    service = LegacyStateImportService(fileDb);
    final reopened = await service.importInput(input);
    expect(reopened.key, first.key);
    expect(reopened.state, MigrationRunState.complete);
    expect(
      (await fileDb
              .customSelect('SELECT count(*) AS n FROM shelves')
              .getSingle())
          .read<int>('n'),
      2,
    );
    await fileDb.close();
    await directory.delete(recursive: true);
  });
}
