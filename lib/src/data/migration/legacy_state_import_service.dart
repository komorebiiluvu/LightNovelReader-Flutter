import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../../domain/identity/opaque_ids.dart';
import '../../domain/identity/source_refs.dart';
import '../../domain/legacy/legacy_chapter_locator.dart';
import '../../domain/legacy/legacy_source_mapping.dart';
import '../../domain/library/library_models.dart';
import '../../domain/migration/legacy_import_models.dart';
import '../../domain/migration/legacy_import_planner.dart';
import '../../domain/migration/migration_models.dart';
import '../../domain/migration/raw_json.dart';
import '../../domain/preferences/preferences.dart';
import '../../domain/progress/reading_progress.dart';
import '../persistence/database.dart' show AppDatabase;
import 'migration_coordinator.dart';
import 'migration_repository.dart';

/// Concrete, offline F2.7 conversion service. The caller supplies an already
/// opened database and must explicitly register the dataset before import.
final class LegacyStateImportService {
  LegacyStateImportService(
    this.database, {
    MigrationRepository? migrationRepository,
    this.limits = const MigrationResourceLimits(),
    this.failureInjector,
  }) : repository = migrationRepository ?? MigrationRepository(database);

  final AppDatabase database;
  final MigrationRepository repository;
  final MigrationResourceLimits limits;
  final MigrationFailureInjector? failureInjector;

  /// Imports the selected frozen input and returns only a safe summary.
  Future<LegacyImportResult> importWithReport(MigrationInput input) async {
    final context = LegacyImportExecutionContext(
      datasetId: input.datasetId,
      mappingVersion: input.mappingVersion,
    );
    final execution = _LegacyImportExecution(context);
    final conversion = LegacyImportPlanner(limits: limits).plan(input);
    final coordinator = MigrationCoordinator(
      repository,
      applier: (unit, db) =>
          execution._apply(unit, conversion.payloadFor(unit), db),
      typedVerifier: (unit, db) =>
          execution._verify(unit, conversion.payloadFor(unit), db),
      planBuilder: (_) => conversion.plan,
      failureInjector: failureInjector,
    );
    final run = await coordinator.importInput(input);
    return LegacyImportResult(
      run: run,
      report: await _report(run, conversion.plan),
    );
  }

  /// Convenience API for callers that need only the durable run model.
  Future<MigrationRun> importInput(MigrationInput input) async =>
      (await importWithReport(input)).run;

  Future<LegacyImportReport> _report(
    MigrationRun run,
    MigrationPlan plan,
  ) async {
    final outcomes = await repository.listOutcomes(run.key);
    final expected = <MigrationEntityKind, int>{};
    for (final unit in plan.units) {
      expected[unit.entityKind] = (expected[unit.entityKind] ?? 0) + 1;
    }
    final verified = <MigrationEntityKind, int>{};
    final counts = <MigrationOutcome, int>{};
    for (final record in outcomes) {
      counts[record.outcome] = (counts[record.outcome] ?? 0) + 1;
      if (record.outcome != MigrationOutcome.failed &&
          record.outcome != MigrationOutcome.conflict) {
        verified[record.entityKind] = (verified[record.entityKind] ?? 0) + 1;
      }
    }
    final unresolved = (counts[MigrationOutcome.preservedUnresolved] ?? 0);
    final deferred = (counts[MigrationOutcome.deferredPreserved] ?? 0);
    return LegacyImportReport(
      run: run,
      expectedByKind: Map.unmodifiable(expected),
      verifiedByKind: Map.unmodifiable(verified),
      outcomeCounts: Map.unmodifiable(counts),
      unresolvedRecords: unresolved,
      deferredRecords: deferred,
      conflicts: counts[MigrationOutcome.conflict] ?? 0,
      failures: counts[MigrationOutcome.failed] ?? 0,
    );
  }
}

/// Invocation-owned state captured by the coordinator closures.
final class _LegacyImportExecution {
  const _LegacyImportExecution(this.context);
  final LegacyImportExecutionContext context;

  Future<MigrationApplyResult> _apply(
    MigrationUnit unit,
    LegacyImportPayload payload,
    AppDatabase db,
  ) async {
    switch (payload) {
      case SourceImportPayload value:
        return _applySource(value, db);
      case BookImportPayload value:
        return _applyBook(unit, value, db);
      case ShelfImportPayload value:
        return _applyShelf(value, db);
      case GroupImportPayload value:
        return _applyGroup(value, db);
      case AutoGroupRenamePayload():
        return const MigrationApplyResult.deferredPreserved();
      case SplitImportPayload value:
        return _applySplit(value, db);
      case ProgressImportPayload value:
        return _applyProgress(unit, value, db);
      case OrphanProgressPayload():
        return const MigrationApplyResult.preservedUnresolved(
          diagnostic: MigrationDiagnosticCode.missingEvidence,
        );
      case ReaderPreferencesImportPayload value:
        return _applyReader(value, db);
      case AppPreferencesImportPayload value:
        return _applyApp(value, db);
      case DeferredStatisticsPayload():
      case DeferredSearchHistoryPayload():
        return const MigrationApplyResult.deferredPreserved();
    }
  }

  Future<MigrationVerificationDisposition> _verify(
    MigrationUnit unit,
    LegacyImportPayload payload,
    AppDatabase db,
  ) async {
    try {
      switch (payload) {
        case SourceImportPayload value:
          return await _verifySource(value, db);
        case BookImportPayload value:
          return await _verifyBook(value, db);
        case ShelfImportPayload value:
          return await _verifyShelf(value, db);
        case GroupImportPayload value:
          return await _verifyGroup(value, db);
        case AutoGroupRenamePayload():
          return MigrationVerificationDisposition.verified;
        case SplitImportPayload value:
          return await _verifySplit(value, db);
        case ProgressImportPayload value:
          return await _verifyProgress(value, db);
        case OrphanProgressPayload():
          return MigrationVerificationDisposition.verified;
        case ReaderPreferencesImportPayload value:
          return await _verifyReader(value, db);
        case AppPreferencesImportPayload value:
          return await _verifyApp(value, db);
        case DeferredStatisticsPayload():
        case DeferredSearchHistoryPayload():
          return MigrationVerificationDisposition.verified;
      }
    } on Object {
      return MigrationVerificationDisposition.verificationFailure;
    }
  }

  Future<MigrationApplyResult> _applySource(
    SourceImportPayload payload,
    AppDatabase db,
  ) async {
    final builtin = payload.sourceId.value == 'builtin.wenku8';
    await _ensureSource(db, payload.sourceId, payload.legacyName, builtin);
    final ok = await _ensureMapping(
      db,
      entityKind: MigrationEntityKind.source,
      legacyKey: payload.legacyName.isEmpty
          ? '__unassigned__'
          : payload.legacyName,
      resolution: builtin ? 'resolved' : 'unresolved',
      targetSourceId: payload.sourceId.value,
    );
    return ok
        ? (builtin
              ? const MigrationApplyResult.imported()
              : const MigrationApplyResult.preservedUnresolved())
        : const MigrationApplyResult.conflict();
  }

  Future<MigrationApplyResult> _applyBook(
    MigrationUnit unit,
    BookImportPayload payload,
    AppDatabase db,
  ) async {
    final sourceId = payload.bookRef.sourceId;
    await _ensureSource(
      db,
      sourceId,
      payload.sourceName ?? '',
      sourceId.value == 'builtin.wenku8',
    );
    // Capture durable stub provenance before this operation can create the
    // book mapping. A mapping created while handling a preexisting product
    // row must not be mistaken for evidence that migration created the row.
    final migrationCreatedStub = await _hasMigrationCreatedBookStub(
      db,
      payload,
    );
    final preexistingUnknownStub =
        !migrationCreatedStub &&
        await _hasUnknownSavedStubProvenance(db, payload);
    // The book foreign key must exist before its durable identity mapping can
    // be inserted. A stub is safe here and is upgraded below when metadata is
    // available.
    await _ensureBookStub(db, payload);
    var conflict = payload.sourceConflict;
    final key = [sourceId.value, payload.bookId.value];
    final rows = await _rows(
      db,
      'SELECT saved,metadata_state,title,author,description,known_total_chapters,update_flag FROM library_entries WHERE source_id=? AND book_id=?',
      key,
    );
    final known = _hasBookMetadata(payload);
    if (rows.isEmpty) {
      await _write(
        db,
        'INSERT INTO library_entries(source_id,book_id,saved,metadata_state,title,author,description,known_total_chapters,update_flag) VALUES (?,?,?,?,?,?,?,?,?)',
        [
          sourceId.value,
          payload.bookId.value,
          payload.saved == true ? 1 : 0,
          known ? 'known' : 'stub',
          payload.title,
          payload.author,
          payload.intro,
          payload.knownTotal,
          payload.updateFlag,
        ],
      );
      await _writeTags(db, payload.bookRef, payload.tags);
    } else {
      final row = rows.single;
      final updates = <String, Object?>{};
      if (payload.saved != null &&
          row.read<int>('saved') != (payload.saved! ? 1 : 0)) {
        final unresolvedStub =
            row.read<String>('metadata_state') == 'stub' &&
            migrationCreatedStub &&
            await _hasUnknownSavedStubProvenance(db, payload);
        if (unresolvedStub) {
          updates['saved'] = payload.saved! ? 1 : 0;
        } else {
          conflict = true;
        }
      }
      void merge(String column, Object? incoming) {
        if (incoming == null) return;
        final Object? existing = switch (column) {
          'title' ||
          'author' ||
          'description' => row.readNullable<String>(column),
          'known_total_chapters' ||
          'update_flag' => row.readNullable<int>(column),
          _ => null,
        };
        if (existing == null) {
          updates[column] = incoming;
        } else if (existing != incoming) {
          conflict = true;
        }
      }

      merge('title', payload.title);
      merge('author', payload.author);
      merge('description', payload.intro);
      merge('known_total_chapters', payload.knownTotal);
      merge(
        'update_flag',
        payload.updateFlag == null ? null : (payload.updateFlag! ? 1 : 0),
      );
      if (known) {
        if (row.read<String>('metadata_state') == 'stub') {
          updates['metadata_state'] = 'known';
        }
        final tags = await _tagValues(db, payload.bookRef);
        if (tags.isEmpty && payload.tags.isNotEmpty) {
          await _writeTags(db, payload.bookRef, payload.tags);
        } else if (!_listEquals(tags, payload.tags)) {
          conflict = true;
        }
      }
      if (updates.isNotEmpty) {
        final assignments = updates.keys.map((column) => '$column=?').join(',');
        await _write(
          db,
          'UPDATE library_entries SET $assignments WHERE source_id=? AND book_id=?',
          [...updates.values, ...key],
        );
      }
    }
    conflict = await _mergeLegacyBookMetadata(db, payload) || conflict;
    final finalRows = await _rows(
      db,
      'SELECT metadata_state FROM library_entries WHERE source_id=? AND book_id=?',
      key,
    );
    // A preexisting stub with unresolved saved provenance does not receive a
    // book mapping here. Such a mapping is the durable marker for a stub
    // created by migration, so creating it during a later corrected import
    // would make the old product row look migration-owned on the next retry.
    final canRecordBookMapping =
        migrationCreatedStub ||
        (!preexistingUnknownStub &&
            finalRows.single.read<String>('metadata_state') != 'stub');
    if (canRecordBookMapping) {
      final resolution = payload.sourceConflict || conflict
          ? 'conflict'
          : sourceId.value == 'builtin.wenku8'
          ? 'resolved'
          : 'unresolved';
      final mappingOk = await _ensureMapping(
        db,
        entityKind: MigrationEntityKind.book,
        legacyKey: payload.bookId.value,
        resolution: resolution,
        sourceByIdName: payload.sourceByIdName,
        bookSourceName: payload.bookSourceName,
        targetSourceId: sourceId.value,
        targetBookId: payload.bookId.value,
      );
      if (!mappingOk) return const MigrationApplyResult.conflict();
    }
    if (conflict) return const MigrationApplyResult.conflict();
    final unresolved =
        payload.sourceConflict ||
        sourceId.value != 'builtin.wenku8' ||
        unit.diagnostic == MigrationDiagnosticCode.invalidField ||
        unit.diagnostic == MigrationDiagnosticCode.conflictingEvidence;
    return unresolved
        ? const MigrationApplyResult.preservedUnresolved()
        : const MigrationApplyResult.imported();
  }

  Future<MigrationApplyResult> _applyShelf(
    ShelfImportPayload payload,
    AppDatabase db,
  ) async {
    if (payload.hasDuplicateMembers) {
      return const MigrationApplyResult.conflict();
    }
    for (final member in payload.members) {
      await _ensureBookStub(db, member);
    }
    final existingMapping = await _rows(
      db,
      'SELECT target_shelf_id FROM legacy_identity_mappings WHERE dataset_id=? AND entity_kind=? AND legacy_key=? AND mapping_version=?',
      [
        context.datasetId,
        MigrationEntityKind.shelf.wireName,
        payload.legacyId,
        context.mappingVersion,
      ],
    );
    final rows = await _rows(
      db,
      'SELECT name,ordinal FROM shelves WHERE shelf_id=?',
      [payload.targetId.value],
    );
    if (rows.isNotEmpty && existingMapping.isEmpty) {
      return const MigrationApplyResult.conflict();
    }
    var created = false;
    if (rows.isEmpty) {
      await _write(
        db,
        'INSERT INTO shelves(shelf_id,name,ordinal) VALUES (?,?,?)',
        [payload.targetId.value, payload.name, payload.ordinal],
      );
      created = true;
    }
    final mappingOk = await _ensureMapping(
      db,
      entityKind: MigrationEntityKind.shelf,
      legacyKey: payload.legacyId,
      resolution: 'resolved',
      targetShelfId: payload.targetId.value,
    );
    if (!mappingOk) {
      if (created) {
        await _write(db, 'DELETE FROM shelves WHERE shelf_id=?', [
          payload.targetId.value,
        ]);
      }
      return const MigrationApplyResult.conflict();
    }
    final refs = [for (final member in payload.members) member.bookRef];
    if (created) {
      await _writeShelfMembers(db, payload.targetId, refs);
      return payload.hasInvalidMembers
          ? const MigrationApplyResult.preservedUnresolved(
              diagnostic: MigrationDiagnosticCode.invalidField,
            )
          : const MigrationApplyResult.imported();
    }
    final existing = await _shelfRefs(db, payload.targetId);
    if (rows.single.read<String>('name') != payload.name ||
        rows.single.read<int>('ordinal') != payload.ordinal ||
        !_refListEquals(existing, refs)) {
      return const MigrationApplyResult.conflict();
    }
    return payload.hasInvalidMembers
        ? const MigrationApplyResult.preservedUnresolved(
            diagnostic: MigrationDiagnosticCode.invalidField,
          )
        : const MigrationApplyResult.unchanged();
  }

  Future<MigrationApplyResult> _applyGroup(
    GroupImportPayload payload,
    AppDatabase db,
  ) async {
    for (final member in payload.members) {
      await _ensureBookStub(db, member);
    }
    final existingMapping = await _rows(
      db,
      'SELECT target_group_id FROM legacy_identity_mappings WHERE dataset_id=? AND entity_kind=? AND legacy_key=? AND mapping_version=?',
      [
        context.datasetId,
        MigrationEntityKind.group.wireName,
        payload.legacyId,
        context.mappingVersion,
      ],
    );
    final rows = await _rows(
      db,
      'SELECT display_name FROM manual_groups WHERE group_id=?',
      [payload.targetId.value],
    );
    if (rows.isNotEmpty && existingMapping.isEmpty) {
      return const MigrationApplyResult.conflict();
    }
    var created = false;
    if (rows.isEmpty) {
      await _write(
        db,
        'INSERT INTO manual_groups(group_id,display_name) VALUES (?,?)',
        [payload.targetId.value, payload.displayName],
      );
      created = true;
    }
    final mappingOk = await _ensureMapping(
      db,
      entityKind: MigrationEntityKind.group,
      legacyKey: payload.legacyId,
      resolution: 'resolved',
      targetGroupId: payload.targetId.value,
    );
    if (!mappingOk) {
      if (created) {
        await _write(db, 'DELETE FROM manual_groups WHERE group_id=?', [
          payload.targetId.value,
        ]);
      }
      return const MigrationApplyResult.conflict();
    }
    final refs = [for (final member in payload.members) member.bookRef];
    if (created) {
      for (final ref in refs) {
        await _write(
          db,
          'INSERT INTO group_members(group_id,source_id,book_id) VALUES (?,?,?)',
          [payload.targetId.value, ref.sourceId.value, ref.bookId.value],
        );
      }
      return const MigrationApplyResult.imported();
    }
    final existingName = rows.single.readNullable<String>('display_name');
    final existing = await _groupRefs(db, payload.targetId);
    if (existingName != payload.displayName || !_refSetEquals(existing, refs)) {
      return const MigrationApplyResult.conflict();
    }
    return const MigrationApplyResult.unchanged();
  }

  Future<MigrationApplyResult> _applySplit(
    SplitImportPayload payload,
    AppDatabase db,
  ) async {
    await _ensureBookStub(db, payload.book);
    final rows = await _rows(
      db,
      'SELECT is_split FROM split_overrides WHERE source_id=? AND book_id=?',
      [payload.book.bookRef.sourceId.value, payload.book.bookId.value],
    );
    if (rows.isNotEmpty && rows.single.read<int>('is_split') != 1) {
      return const MigrationApplyResult.conflict();
    }
    await _write(
      db,
      'INSERT INTO split_overrides(source_id,book_id,is_split) VALUES (?,?,1) ON CONFLICT(source_id,book_id) DO UPDATE SET is_split=1',
      [payload.book.bookRef.sourceId.value, payload.book.bookId.value],
    );
    return rows.isEmpty
        ? const MigrationApplyResult.imported()
        : const MigrationApplyResult.unchanged();
  }

  Future<MigrationApplyResult> _applyProgress(
    MigrationUnit unit,
    ProgressImportPayload payload,
    AppDatabase db,
  ) async {
    await _ensureBookStub(db, payload.book);
    final ref = payload.book.bookRef;
    final existingProgress = await _rows(
      db,
      'SELECT has_read,chapter_id,legacy_locator_id,last_read_at FROM reading_progress WHERE source_id=? AND book_id=?',
      [ref.sourceId.value, ref.bookId.value],
    );
    LegacyChapterLocatorV1? locator;
    String? locatorId;
    if (payload.selectedChapter != null) {
      locator = LegacyChapterLocatorV1(
        datasetId: LegacyDatasetId(context.datasetId),
        bookRef: ref,
        legacyBookId: payload.book.bookId,
        chapterIndex: payload.selectedChapter!,
        rawOffsetKey: payload.selectedOffsetKey,
        fraction: payload.selectedFraction,
      );
      locatorId = _locatorId(locator);
    }
    final lastReadAt = payload.lastReadAt == null
        ? null
        : encodeCanonicalUtc(payload.lastReadAt!);
    if (existingProgress.isNotEmpty) {
      final row = existingProgress.single;
      if (row.read<int>('has_read') != (payload.hasRead ? 1 : 0) ||
          row.readNullable<String>('chapter_id') != null ||
          row.readNullable<String>('legacy_locator_id') != locatorId ||
          row.readNullable<String>('last_read_at') != lastReadAt) {
        return const MigrationApplyResult.conflict();
      }
      return const MigrationApplyResult.unchanged();
    }
    if (locator != null) {
      await _write(
        db,
        'INSERT INTO legacy_chapter_locators(locator_id,version,dataset_id,source_id,book_id,legacy_book_id,chapter_index,raw_offset_key,fraction) VALUES (?,?,?,?,?,?,?,?,?) ON CONFLICT(locator_id) DO NOTHING',
        [
          locatorId,
          1,
          context.datasetId,
          ref.sourceId.value,
          ref.bookId.value,
          ref.bookId.value,
          locator.chapterIndex,
          locator.rawOffsetKey,
          locator.fraction,
        ],
      );
    }
    await _write(
      db,
      'INSERT INTO reading_progress(source_id,book_id,version,has_read,chapter_id,legacy_locator_id,last_read_at) VALUES (?,?,1,?,?,?,?)',
      [
        ref.sourceId.value,
        ref.bookId.value,
        payload.hasRead ? 1 : 0,
        null,
        locatorId,
        lastReadAt,
      ],
    );
    if (unit.diagnostic != null ||
        (payload.appleDateSeconds != null && payload.lastReadAt == null)) {
      return const MigrationApplyResult.preservedUnresolved(
        diagnostic: MigrationDiagnosticCode.conflictingEvidence,
      );
    }
    return const MigrationApplyResult.imported();
  }

  Future<MigrationApplyResult> _applyReader(
    ReaderPreferencesImportPayload payload,
    AppDatabase db,
  ) async {
    final rows = await _rows(
      db,
      'SELECT * FROM reader_preferences WHERE singleton=1',
    );
    final args = _readerArgs(payload.value);
    if (rows.isEmpty) {
      await _write(
        db,
        'INSERT INTO reader_preferences(singleton,version,font_size,line_spacing,background,mode,font_family,bold,margin_left,margin_right,margin_top,margin_bottom) VALUES (1,1,?,?,?,?,?,?,?,?,?,?)',
        args,
      );
      return payload.invalidFields.isEmpty
          ? const MigrationApplyResult.imported()
          : const MigrationApplyResult.preservedUnresolved(
              diagnostic: MigrationDiagnosticCode.invalidField,
            );
    }
    if (!_readerMatches(rows.single, payload.value)) {
      return const MigrationApplyResult.conflict();
    }
    return payload.invalidFields.isEmpty
        ? const MigrationApplyResult.unchanged()
        : const MigrationApplyResult.preservedUnresolved(
            diagnostic: MigrationDiagnosticCode.invalidField,
          );
  }

  Future<MigrationApplyResult> _applyApp(
    AppPreferencesImportPayload payload,
    AppDatabase db,
  ) async {
    await _ensureSource(
      db,
      payload.preferredSourceId,
      payload.preferredSourceId.value == 'builtin.wenku8' ? '文库8(在线)' : '',
      payload.preferredSourceId.value == 'builtin.wenku8',
    );
    final rows = await _rows(
      db,
      'SELECT * FROM app_preferences WHERE singleton=1',
    );
    final selected = await _selectedShelf(payload, db);
    final unresolvedShelf = payload.selectedShelfId != null && selected == null;
    if (rows.isEmpty) {
      await _write(
        db,
        'INSERT INTO app_preferences(singleton,version,theme,preferred_source_id,selected_shelf_id,accent) VALUES (1,1,?,?,?,NULL)',
        [_theme(payload.theme), payload.preferredSourceId.value, selected],
      );
      return payload.invalidFields.isEmpty &&
              !unresolvedShelf &&
              payload.preferredSourceId.value == 'builtin.wenku8'
          ? const MigrationApplyResult.imported()
          : const MigrationApplyResult.preservedUnresolved(
              diagnostic: MigrationDiagnosticCode.missingEvidence,
            );
    }
    final row = rows.single;
    if (row.read<String>('theme') != _theme(payload.theme) ||
        row.readNullable<String>('preferred_source_id') !=
            payload.preferredSourceId.value ||
        row.readNullable<String>('selected_shelf_id') != selected) {
      return const MigrationApplyResult.conflict();
    }
    return payload.invalidFields.isEmpty &&
            !unresolvedShelf &&
            payload.preferredSourceId.value == 'builtin.wenku8'
        ? const MigrationApplyResult.unchanged()
        : const MigrationApplyResult.preservedUnresolved(
            diagnostic: MigrationDiagnosticCode.missingEvidence,
          );
  }

  Future<MigrationVerificationDisposition> _verifySource(
    SourceImportPayload p,
    AppDatabase db,
  ) async {
    final rows = await _rows(
      db,
      'SELECT availability FROM source_registrations WHERE source_id=?',
      [p.sourceId.value],
    );
    if (rows.isEmpty) {
      return MigrationVerificationDisposition.verificationFailure;
    }
    final mapping = await _mapping(
      db,
      MigrationEntityKind.source,
      p.legacyName.isEmpty ? '__unassigned__' : p.legacyName,
    );
    return mapping == p.sourceId.value
        ? MigrationVerificationDisposition.verified
        : MigrationVerificationDisposition.targetConflict;
  }

  Future<MigrationVerificationDisposition> _verifyBook(
    BookImportPayload p,
    AppDatabase db,
  ) async {
    final rows = await _rows(
      db,
      'SELECT saved,metadata_state,title,author,description,known_total_chapters,update_flag FROM library_entries WHERE source_id=? AND book_id=?',
      [p.bookRef.sourceId.value, p.bookId.value],
    );
    if (rows.isEmpty) {
      return MigrationVerificationDisposition.verificationFailure;
    }
    final row = rows.single;
    if (p.saved != null && row.read<int>('saved') != (p.saved! ? 1 : 0)) {
      return MigrationVerificationDisposition.targetConflict;
    }
    if (p.title != null && row.readNullable<String>('title') != p.title) {
      return MigrationVerificationDisposition.targetConflict;
    }
    if (p.author != null && row.readNullable<String>('author') != p.author) {
      return MigrationVerificationDisposition.targetConflict;
    }
    if (p.intro != null && row.readNullable<String>('description') != p.intro) {
      return MigrationVerificationDisposition.targetConflict;
    }
    if (p.knownTotal != null &&
        row.readNullable<int>('known_total_chapters') != p.knownTotal) {
      return MigrationVerificationDisposition.targetConflict;
    }
    if (p.updateFlag != null &&
        row.readNullable<int>('update_flag') != (p.updateFlag! ? 1 : 0)) {
      return MigrationVerificationDisposition.targetConflict;
    }
    if (_hasBookMetadata(p) && row.read<String>('metadata_state') != 'known') {
      return MigrationVerificationDisposition.targetConflict;
    }
    final tags = await _tagValues(db, p.bookRef);
    if (_hasBookMetadata(p) && !_listEquals(tags, p.tags)) {
      return MigrationVerificationDisposition.targetConflict;
    }
    final meta = await _rows(
      db,
      'SELECT cover_reference,total_chapters,last_chapter,hits,cover_index,has_update,publishing_house,last_update,is_completed,word_count_k FROM legacy_book_metadata WHERE source_id=? AND book_id=?',
      [p.bookRef.sourceId.value, p.bookId.value],
    );
    if (meta.isEmpty) {
      return MigrationVerificationDisposition.verificationFailure;
    }
    final metadata = meta.single;
    if (p.coverUrl != null &&
            metadata.readNullable<String>('cover_reference') != p.coverUrl ||
        p.totalChapters != null &&
            metadata.readNullable<int>('total_chapters') != p.totalChapters ||
        p.lastChapter != null &&
            metadata.readNullable<int>('last_chapter') != p.lastChapter ||
        p.hits != null && metadata.readNullable<int>('hits') != p.hits ||
        p.coverIndex != null &&
            metadata.readNullable<int>('cover_index') != p.coverIndex ||
        p.hasUpdate != null &&
            metadata.readNullable<int>('has_update') !=
                (p.hasUpdate! ? 1 : 0) ||
        p.publishingHouse != null &&
            metadata.readNullable<String>('publishing_house') !=
                p.publishingHouse ||
        p.lastUpdate != null &&
            metadata.readNullable<String>('last_update') != p.lastUpdate ||
        p.isCompleted != null &&
            metadata.readNullable<int>('is_completed') !=
                (p.isCompleted! ? 1 : 0) ||
        p.wordCountK != null &&
            metadata.readNullable<int>('word_count_k') != p.wordCountK) {
      return MigrationVerificationDisposition.targetConflict;
    }
    return MigrationVerificationDisposition.verified;
  }

  Future<MigrationVerificationDisposition> _verifyShelf(
    ShelfImportPayload p,
    AppDatabase db,
  ) async {
    final rows = await _rows(
      db,
      'SELECT name,ordinal FROM shelves WHERE shelf_id=?',
      [p.targetId.value],
    );
    if (rows.isEmpty || rows.single.read<String>('name') != p.name) {
      return rows.isEmpty
          ? MigrationVerificationDisposition.verificationFailure
          : MigrationVerificationDisposition.targetConflict;
    }
    if (rows.single.read<int>('ordinal') != p.ordinal) {
      return MigrationVerificationDisposition.targetConflict;
    }
    return _refListEquals(await _shelfRefs(db, p.targetId), [
          for (final m in p.members) m.bookRef,
        ])
        ? MigrationVerificationDisposition.verified
        : MigrationVerificationDisposition.targetConflict;
  }

  Future<MigrationVerificationDisposition> _verifyGroup(
    GroupImportPayload p,
    AppDatabase db,
  ) async {
    final rows = await _rows(
      db,
      'SELECT display_name FROM manual_groups WHERE group_id=?',
      [p.targetId.value],
    );
    if (rows.isEmpty) {
      return MigrationVerificationDisposition.verificationFailure;
    }
    if (rows.single.readNullable<String>('display_name') != p.displayName) {
      return MigrationVerificationDisposition.targetConflict;
    }
    return _refSetEquals(await _groupRefs(db, p.targetId), [
          for (final m in p.members) m.bookRef,
        ])
        ? MigrationVerificationDisposition.verified
        : MigrationVerificationDisposition.targetConflict;
  }

  Future<MigrationVerificationDisposition> _verifySplit(
    SplitImportPayload p,
    AppDatabase db,
  ) async {
    final rows = await _rows(
      db,
      'SELECT is_split FROM split_overrides WHERE source_id=? AND book_id=?',
      [p.book.bookRef.sourceId.value, p.book.bookId.value],
    );
    return rows.length == 1 && rows.single.read<int>('is_split') == 1
        ? MigrationVerificationDisposition.verified
        : MigrationVerificationDisposition.targetConflict;
  }

  Future<MigrationVerificationDisposition> _verifyProgress(
    ProgressImportPayload p,
    AppDatabase db,
  ) async {
    final rows = await _rows(
      db,
      'SELECT * FROM reading_progress WHERE source_id=? AND book_id=?',
      [p.book.bookRef.sourceId.value, p.book.bookId.value],
    );
    if (rows.isEmpty) {
      return MigrationVerificationDisposition.verificationFailure;
    }
    final row = rows.single;
    if (row.read<int>('has_read') != (p.hasRead ? 1 : 0) ||
        row.readNullable<String>('chapter_id') != null ||
        row.readNullable<String>('last_read_at') !=
            (p.lastReadAt == null ? null : encodeCanonicalUtc(p.lastReadAt!))) {
      return MigrationVerificationDisposition.targetConflict;
    }
    final id = row.readNullable<String>('legacy_locator_id');
    if (p.selectedChapter == null) {
      return id == null
          ? MigrationVerificationDisposition.verified
          : MigrationVerificationDisposition.targetConflict;
    }
    if (id == null) return MigrationVerificationDisposition.verificationFailure;
    final locators = await _rows(
      db,
      'SELECT * FROM legacy_chapter_locators WHERE locator_id=?',
      [id],
    );
    if (locators.isEmpty) {
      return MigrationVerificationDisposition.verificationFailure;
    }
    final locator = locators.single;
    final expected = LegacyChapterLocatorV1(
      datasetId: LegacyDatasetId(context.datasetId),
      bookRef: p.book.bookRef,
      legacyBookId: p.book.bookId,
      chapterIndex: p.selectedChapter!,
      rawOffsetKey: p.selectedOffsetKey,
      fraction: p.selectedFraction,
    );
    final matches =
        id == _locatorId(expected) &&
        locator.read<int>('version') == 1 &&
        locator.read<String>('dataset_id') == context.datasetId &&
        locator.read<String>('source_id') == p.book.bookRef.sourceId.value &&
        locator.read<String>('book_id') == p.book.bookId.value &&
        locator.read<String>('legacy_book_id') == p.book.bookId.value &&
        locator.read<int>('chapter_index') == p.selectedChapter &&
        locator.readNullable<String>('raw_offset_key') == p.selectedOffsetKey &&
        locator.readNullable<double>('fraction') == p.selectedFraction &&
        locator.readNullable<String>('remote_id_evidence') == null &&
        locator.readNullable<String>('chapter_title_evidence') == null &&
        locator.readNullable<String>('volume_title_evidence') == null &&
        locator.readNullable<String>('catalog_digest') == null;
    return matches
        ? MigrationVerificationDisposition.verified
        : MigrationVerificationDisposition.targetConflict;
  }

  Future<MigrationVerificationDisposition> _verifyReader(
    ReaderPreferencesImportPayload p,
    AppDatabase db,
  ) async {
    final rows = await _rows(
      db,
      'SELECT * FROM reader_preferences WHERE singleton=1',
    );
    return rows.length == 1 && _readerMatches(rows.single, p.value)
        ? MigrationVerificationDisposition.verified
        : MigrationVerificationDisposition.targetConflict;
  }

  Future<MigrationVerificationDisposition> _verifyApp(
    AppPreferencesImportPayload p,
    AppDatabase db,
  ) async {
    final rows = await _rows(
      db,
      'SELECT * FROM app_preferences WHERE singleton=1',
    );
    if (rows.isEmpty) {
      return MigrationVerificationDisposition.verificationFailure;
    }
    final row = rows.single;
    return row.read<String>('theme') == _theme(p.theme) &&
            row.readNullable<String>('preferred_source_id') ==
                p.preferredSourceId.value &&
            row.readNullable<String>('selected_shelf_id') ==
                await _selectedShelf(p, db)
        ? MigrationVerificationDisposition.verified
        : MigrationVerificationDisposition.targetConflict;
  }

  Future<String?> _selectedShelf(
    AppPreferencesImportPayload p,
    AppDatabase db,
  ) async {
    if (p.selectedShelfId == null) return null;
    final rows = await _rows(
      db,
      'SELECT m.target_shelf_id FROM legacy_identity_mappings m '
      'JOIN shelves s ON s.shelf_id=m.target_shelf_id '
      "WHERE m.dataset_id=? AND m.mapping_version=? AND m.entity_kind='shelf' "
      "AND m.legacy_key=? AND m.resolution='resolved'",
      [context.datasetId, context.mappingVersion, p.selectedShelfLegacyId],
    );
    return rows.isEmpty ? null : rows.single.read<String>('target_shelf_id');
  }

  Future<void> _ensureSource(
    AppDatabase db,
    SourceId id,
    String? name,
    bool builtin,
  ) async {
    final rows = await _rows(
      db,
      'SELECT source_id FROM source_registrations WHERE source_id=?',
      [id.value],
    );
    if (rows.isNotEmpty) return;
    await _write(
      db,
      'INSERT INTO source_registrations(source_id,display_name,availability) VALUES (?,?,?)',
      [
        id.value,
        name == null || name.isEmpty ? null : name,
        builtin ? 'unavailable' : 'unresolved',
      ],
    );
  }

  Future<void> _ensureBookStub(AppDatabase db, BookImportPayload p) async {
    await _ensureSource(
      db,
      p.bookRef.sourceId,
      p.sourceName,
      p.bookRef.sourceId.value == 'builtin.wenku8',
    );
    final existing = await _rows(
      db,
      'SELECT 1 FROM library_entries WHERE source_id=? AND book_id=?',
      [p.bookRef.sourceId.value, p.bookId.value],
    );
    await _write(
      db,
      'INSERT INTO library_entries(source_id,book_id,metadata_state,saved) VALUES (?,?,\'stub\',?) ON CONFLICT(source_id,book_id) DO NOTHING',
      [p.bookRef.sourceId.value, p.bookId.value, p.saved == true ? 1 : 0],
    );
    if (existing.isEmpty) {
      await _ensureMapping(
        db,
        entityKind: MigrationEntityKind.book,
        legacyKey: p.bookId.value,
        resolution: p.sourceConflict
            ? 'conflict'
            : p.bookRef.sourceId.value == 'builtin.wenku8'
            ? 'resolved'
            : 'unresolved',
        sourceByIdName: p.sourceByIdName,
        bookSourceName: p.bookSourceName,
        targetSourceId: p.bookRef.sourceId.value,
        targetBookId: p.bookId.value,
      );
    }
  }

  Future<bool> _hasMigrationCreatedBookStub(
    AppDatabase db,
    BookImportPayload p,
  ) async {
    final rows = await _rows(
      db,
      "SELECT 1 FROM legacy_identity_mappings WHERE dataset_id=? AND entity_kind='book' AND legacy_key=? AND mapping_version=? AND target_source_id=? AND target_book_id=? LIMIT 1",
      [
        context.datasetId,
        p.bookId.value,
        context.mappingVersion,
        p.bookRef.sourceId.value,
        p.bookId.value,
      ],
    );
    return rows.isNotEmpty;
  }

  Future<bool> _hasUnknownSavedStubProvenance(
    AppDatabase db,
    BookImportPayload p,
  ) async {
    final rows = await _rows(
      db,
      "SELECT 1 FROM safe_legacy_values WHERE dataset_id=? AND entity_kind='book' AND legacy_key=? AND field='book.saved' AND purpose='conflict-candidate' AND value_type='string' AND text_value='unknown' LIMIT 1",
      [context.datasetId, p.bookId.value],
    );
    return rows.isNotEmpty;
  }

  Future<bool> _ensureMapping(
    AppDatabase db, {
    required MigrationEntityKind entityKind,
    required String legacyKey,
    required String resolution,
    String? sourceByIdName,
    String? bookSourceName,
    String? targetSourceId,
    String? targetBookId,
    String? targetShelfId,
    String? targetGroupId,
  }) async {
    final mappingId = _mappingId(entityKind, legacyKey);
    final rows = await _rows(
      db,
      'SELECT resolution,source_by_id_name,book_source_name,target_source_id,target_book_id,target_shelf_id,target_group_id FROM legacy_identity_mappings WHERE dataset_id=? AND entity_kind=? AND legacy_key=? AND mapping_version=?',
      [
        context.datasetId,
        entityKind.wireName,
        legacyKey,
        context.mappingVersion,
      ],
    );
    if (rows.isNotEmpty) {
      final row = rows.single;
      return row.read<String>('resolution') == resolution &&
          row.readNullable<String>('source_by_id_name') == sourceByIdName &&
          row.readNullable<String>('book_source_name') == bookSourceName &&
          row.readNullable<String>('target_source_id') == targetSourceId &&
          row.readNullable<String>('target_book_id') == targetBookId &&
          row.readNullable<String>('target_shelf_id') == targetShelfId &&
          row.readNullable<String>('target_group_id') == targetGroupId;
    }
    await _write(
      db,
      'INSERT INTO legacy_identity_mappings(mapping_id,dataset_id,entity_kind,legacy_key,mapping_version,resolution,source_by_id_name,book_source_name,target_source_id,target_book_id,target_shelf_id,target_group_id) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)',
      [
        mappingId,
        context.datasetId,
        entityKind.wireName,
        legacyKey,
        context.mappingVersion,
        resolution,
        sourceByIdName,
        bookSourceName,
        targetSourceId,
        targetBookId,
        targetShelfId,
        targetGroupId,
      ],
    );
    return true;
  }

  Future<bool> _mergeLegacyBookMetadata(
    AppDatabase db,
    BookImportPayload p,
  ) async {
    final key = [p.bookRef.sourceId.value, p.bookId.value];
    final existing = await _rows(
      db,
      'SELECT * FROM legacy_book_metadata WHERE source_id=? AND book_id=?',
      key,
    );
    final values = <String, Object?>{
      'legacy_source_name': p.sourceName,
      'total_chapters': p.totalChapters,
      'last_chapter': p.lastChapter,
      'hits': p.hits,
      'cover_index': p.coverIndex,
      'has_update': p.hasUpdate == null ? null : (p.hasUpdate! ? 1 : 0),
      'cover_reference': p.coverUrl,
      'publishing_house': p.publishingHouse,
      'last_update': p.lastUpdate,
      'is_completed': p.isCompleted == null ? null : (p.isCompleted! ? 1 : 0),
      'word_count_k': p.wordCountK,
    };
    if (existing.isEmpty) {
      await _write(
        db,
        'INSERT INTO legacy_book_metadata(source_id,book_id,legacy_source_name,total_chapters,last_chapter,hits,cover_index,has_update,cover_reference,publishing_house,last_update,is_completed,word_count_k) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)',
        [key[0], key[1], ...values.values],
      );
      return false;
    }
    final row = existing.single;
    var conflict = false;
    final updates = <String, Object?>{};
    for (final entry in values.entries) {
      final incoming = entry.value;
      if (incoming == null) continue;
      final current = switch (entry.key) {
        'total_chapters' ||
        'last_chapter' ||
        'hits' ||
        'cover_index' ||
        'has_update' ||
        'is_completed' ||
        'word_count_k' => row.readNullable<int>(entry.key),
        _ => row.readNullable<String>(entry.key),
      };
      if (current == null) {
        updates[entry.key] = incoming;
      } else if (current != incoming) {
        conflict = true;
      }
    }
    if (updates.isNotEmpty) {
      await _write(
        db,
        'UPDATE legacy_book_metadata SET ${updates.keys.map((key) => '$key=?').join(',')} WHERE source_id=? AND book_id=?',
        [...updates.values, ...key],
      );
    }
    return conflict;
  }

  Future<void> _writeTags(
    AppDatabase db,
    SourceBookRef ref,
    List<String> tags,
  ) async {
    for (var i = 0; i < tags.length; i++) {
      await _write(
        db,
        'INSERT INTO book_tags(source_id,book_id,ordinal,tag) VALUES (?,?,?,?)',
        [ref.sourceId.value, ref.bookId.value, i, tags[i]],
      );
    }
  }

  Future<void> _writeShelfMembers(
    AppDatabase db,
    ShelfId id,
    List<SourceBookRef> refs,
  ) async {
    for (var i = 0; i < refs.length; i++) {
      await _write(
        db,
        'INSERT INTO shelf_members(shelf_id,source_id,book_id,ordinal) VALUES (?,?,?,?)',
        [id.value, refs[i].sourceId.value, refs[i].bookId.value, i],
      );
    }
  }

  Future<List<SourceBookRef>> _shelfRefs(AppDatabase db, ShelfId id) async => [
    for (final row in await _rows(
      db,
      'SELECT source_id,book_id FROM shelf_members WHERE shelf_id=? ORDER BY ordinal',
      [id.value],
    ))
      SourceBookRef(
        sourceId: SourceId(row.read<String>('source_id')),
        bookId: BookId(row.read<String>('book_id')),
      ),
  ];
  Future<List<SourceBookRef>> _groupRefs(
    AppDatabase db,
    ManualGroupId id,
  ) async => [
    for (final row in await _rows(
      db,
      'SELECT source_id,book_id FROM group_members WHERE group_id=? ORDER BY source_id COLLATE BINARY,book_id COLLATE BINARY',
      [id.value],
    ))
      SourceBookRef(
        sourceId: SourceId(row.read<String>('source_id')),
        bookId: BookId(row.read<String>('book_id')),
      ),
  ];
  Future<List<String>> _tagValues(AppDatabase db, SourceBookRef ref) async => [
    for (final row in await _rows(
      db,
      'SELECT tag FROM book_tags WHERE source_id=? AND book_id=? ORDER BY ordinal',
      [ref.sourceId.value, ref.bookId.value],
    ))
      row.read<String>('tag'),
  ];

  Future<List<QueryRow>> _rows(
    AppDatabase db,
    String sql, [
    List<Object?> args = const [],
  ]) => db
      .customSelect(
        sql,
        variables: args
            .map(
              (value) => switch (value) {
                String v => Variable<String>(v),
                int v => Variable<int>(v),
                double v => Variable<double>(v),
                _ => throw StateError('unsupported migration query variable'),
              },
            )
            .toList(),
      )
      .get();
  Future<void> _write(
    AppDatabase db,
    String sql, [
    List<Object?> args = const [],
  ]) => db.customStatement(sql, args);

  Future<String?> _mapping(
    AppDatabase db,
    MigrationEntityKind kind,
    String key,
  ) async {
    final rows = await _rows(
      db,
      'SELECT target_source_id FROM legacy_identity_mappings WHERE dataset_id=? AND entity_kind=? AND legacy_key=? AND mapping_version=?',
      [context.datasetId, kind.wireName, key, context.mappingVersion],
    );
    return rows.isEmpty
        ? null
        : rows.single.readNullable<String>('target_source_id');
  }

  String _mappingId(MigrationEntityKind kind, String key) =>
      'legacyMapping.v1.${sha256.convert(utf8.encode('${context.datasetId}\u0000${context.mappingVersion}\u0000${kind.wireName}\u0000$key')).toString()}';
  static String _locatorId(LegacyChapterLocatorV1 locator) =>
      'legacyLocator.v1.${base64Url.encode(utf8.encode(jsonEncode(locator.toJson()))).replaceAll('=', '')}';
  static String _theme(AppTheme value) => value.name;
  static bool _hasBookMetadata(BookImportPayload p) =>
      p.title != null ||
      p.author != null ||
      p.intro != null ||
      p.tags.isNotEmpty ||
      p.totalChapters != null ||
      p.lastChapter != null ||
      p.hits != null ||
      p.coverIndex != null ||
      p.hasUpdate != null ||
      p.coverUrl != null ||
      p.publishingHouse != null ||
      p.lastUpdate != null ||
      p.isCompleted != null ||
      p.wordCountK != null;
  static bool _listEquals<T>(List<T> a, List<T> b) =>
      a.length == b.length &&
      a.asMap().entries.every((e) => e.value == b[e.key]);
  static bool _refListEquals(List<SourceBookRef> a, List<SourceBookRef> b) =>
      _listEquals(a, b);
  static bool _refSetEquals(List<SourceBookRef> a, List<SourceBookRef> b) =>
      a.toSet().length == b.toSet().length && a.toSet().containsAll(b);
  static List<Object?> _readerArgs(ReaderPreferencesV1 p) => [
    p.fontSize,
    p.lineSpacing,
    p.background.name,
    p.mode.name,
    p.fontFamily.name,
    p.bold ? 1 : 0,
    p.marginLeft,
    p.marginRight,
    p.marginTop,
    p.marginBottom,
  ];
  static bool _readerMatches(QueryRow row, ReaderPreferencesV1 p) =>
      row.read<double>('font_size') == p.fontSize &&
      row.read<double>('line_spacing') == p.lineSpacing &&
      row.read<String>('background') == p.background.name &&
      row.read<String>('mode') == p.mode.name &&
      row.read<String>('font_family') == p.fontFamily.name &&
      row.read<int>('bold') == (p.bold ? 1 : 0) &&
      row.read<double>('margin_left') == p.marginLeft &&
      row.read<double>('margin_right') == p.marginRight &&
      row.read<double>('margin_top') == p.marginTop &&
      row.read<double>('margin_bottom') == p.marginBottom;
}
