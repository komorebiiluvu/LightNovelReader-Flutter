import 'dart:convert';

import '../identity/opaque_ids.dart';
import '../identity/source_refs.dart';
import '../library/library_models.dart';
import '../preferences/preferences.dart';
import 'legacy_import_models.dart';
import 'migration_failure.dart';
import 'migration_models.dart';
import 'migration_planner.dart';
import 'raw_json.dart';

/// Converts the frozen Swift AppStateSnapshot into typed, sanitized units.
/// This class deliberately never hands a RawJsonValue to the application
/// layer; raw values are consumed only while constructing this plan.
final class LegacyImportPlanner {
  LegacyImportPlanner({this.limits = const MigrationResourceLimits()});
  final MigrationResourceLimits limits;
  String _datasetId = '';
  int _mappingVersion = initialMappingVersion;

  LegacyImportPlan plan(MigrationInput input) {
    _datasetId = input.datasetId;
    _mappingVersion = input.mappingVersion;
    final state = MigrationPlanner(limits: limits).parseState(input);
    final values = state.uniqueValues();
    final units = <MigrationUnit>[];
    final payloads = <String, LegacyImportPayload>{};
    final books = <String, BookImportPayload>{};
    _planMalformedFields(values, units);
    final bookRecords = <String, RawJsonObject>{};
    final duplicateBookIds = <String>{};

    final sourceMap = _stringMap(values['sourceByID']);
    final rawSourceMap = _rawObject(values['sourceByID']);
    final bookLibrary = values['bookLibrary'];
    if (bookLibrary is RawJsonArray) {
      for (var index = 0; index < bookLibrary.values.length; index++) {
        final value = bookLibrary.values[index];
        if (value is! RawJsonObject || value.containsDuplicateKeysDeep()) {
          final unit = _unit(
            MigrationEntityKind.book,
            _framedKey(value, 'bookLibrary', index, 'id'),
            diagnostic: MigrationDiagnosticCode.invalidField,
          );
          units.add(unit);
          continue;
        }
        final id = _string(value.valueFor('id'));
        if (id == null || !_validId(id)) {
          units.add(
            _unit(
              MigrationEntityKind.book,
              'bookLibrary[$index]',
              evidence: _invalidBookEvidence(value),
              diagnostic: MigrationDiagnosticCode.invalidField,
            ),
          );
          continue;
        }
        if (!bookRecords.containsKey(id)) {
          bookRecords[id] = value;
        } else {
          duplicateBookIds.add(id);
        }
      }
    } else if (bookLibrary != null) {
      units.add(
        _unit(
          MigrationEntityKind.book,
          'bookLibrary',
          diagnostic: MigrationDiagnosticCode.invalidField,
        ),
      );
    }

    final referenced = <String>{...bookRecords.keys};
    void addKeys(RawJsonValue? raw) {
      if (raw is RawJsonObject) {
        referenced.addAll(
          raw.fields.map((field) => field.name).where(_validId),
        );
      } else if (raw is RawJsonArray) {
        referenced.addAll(
          raw.values.map(_string).whereType<String>().where(_validId),
        );
      }
    }

    for (final raw in [
      values['sourceByID'],
      values['savedIDs'],
      values['updateFlagIDs'],
      values['readBookIDs'],
      values['lastChapterByID'],
      values['lastReadAtByID'],
      values['knownTotalChaptersByID'],
      values['bookReadingSeconds'],
      values['manualGroupByID'],
      values['splitBookIDs'],
    ]) {
      addKeys(raw);
    }
    final shelvesRaw = values['shelves'];
    if (shelvesRaw is RawJsonArray) {
      for (final raw in shelvesRaw.values) {
        if (raw is! RawJsonObject || raw.containsDuplicateKeysDeep()) continue;
        final members = raw.valueFor('bookIDs');
        if (members is RawJsonArray) addKeys(members);
      }
    }

    // Offset prefixes are admitted only when they exactly match an already
    // known referenced ID. An ambiguous prefix never creates a new book.
    final offsets = _rawObject(values['chapterOffsetByID']);
    final orphanOffsetKeys = <String>{};
    for (final entry in offsets.entries) {
      final split = _offsetParts(entry.key, referenced);
      if (split == null) {
        orphanOffsetKeys.add(entry.key);
      } else {
        referenced.add(split.bookId);
      }
    }

    final saved = _stringSet(values['savedIDs']);
    final updateFlags = _stringSet(values['updateFlagIDs']);
    final readFlags = _stringSet(values['readBookIDs']);
    final lastChapters = _intMap(values['lastChapterByID']);
    final knownTotals = _intMap(values['knownTotalChaptersByID']);
    final lastDates = _numberMap(values['lastReadAtByID']);
    final bookSeconds = _intMap(values['bookReadingSeconds']);

    final sourceNames = <String?>{};
    sourceNames.addAll(sourceMap.values.where((name) => name.isNotEmpty));
    for (final record in bookRecords.values) {
      final source = _string(record.valueFor('source'));
      if (source != null && source.isNotEmpty) sourceNames.add(source);
    }
    final preferredRaw = _string(values['preferredSource']);
    sourceNames.add(
      values.containsKey('preferredSource') &&
              preferredRaw != null &&
              preferredRaw.isNotEmpty
          ? preferredRaw
          : values.containsKey('preferredSource')
          ? null
          : '文库8(在线)',
    );
    sourceNames.add(null);

    for (final name in sourceNames) {
      final sourceId = _sourceId(name);
      final key = name ?? '__unassigned__';
      final payload = SourceImportPayload(
        legacyName: name ?? '',
        sourceId: sourceId,
      );
      final evidence = <SafeLegacyEvidence>[];
      if (name == null) {
        evidence.add(
          const SafeLegacyEvidence(
            field: 'source.name',
            value: SafeLegacyValue.nullValue(),
          ),
        );
      } else {
        evidence.add(
          SafeLegacyEvidence(
            field: 'source.name',
            value: SafeLegacyValue.string(name),
          ),
        );
      }
      final unit = _unit(MigrationEntityKind.source, key, evidence: evidence);
      units.add(unit);
      payloads[_identity(unit)] = payload;
    }

    for (final id in referenced.toList()..sort()) {
      final record = bookRecords[id];
      final validBook = record != null && _validBook(record.uniqueValues());
      final savedKnown = _validSet(values['savedIDs']);
      final updateFlagKnown = _validSet(values['updateFlagIDs']);
      final sourceById = sourceMap[id];
      final bookSource = record == null
          ? null
          : _string(record.valueFor('source'));
      final hasSourceCandidate = rawSourceMap.containsKey(id);
      final sourceName = _chooseSource(
        hasSourceCandidate,
        sourceById,
        bookSource,
      );
      final sourceConflict =
          hasSourceCandidate &&
          sourceById != null &&
          bookSource != null &&
          sourceById != bookSource;
      final tags = <String>[];
      final diagnostic = <MigrationDiagnosticCode>{};
      final evidence = <SafeLegacyEvidence>[
        SafeLegacyEvidence(field: 'book.id', value: SafeLegacyValue.string(id)),
        savedKnown
            ? SafeLegacyEvidence(
                field: 'book.saved',
                value: SafeLegacyValue.boolean(saved.contains(id)),
              )
            : const SafeLegacyEvidence(
                field: 'book.saved',
                value: SafeLegacyValue.string('unknown'),
              ),
      ];
      String? title;
      String? author;
      String? intro;
      int? total;
      int? bookLast;
      int? hits;
      int? coverIndex;
      bool? hasUpdate;
      String? cover;
      String? publishing;
      String? lastUpdate;
      bool? completed;
      int? wordCount;
      if (record != null) {
        final fields = record.uniqueValues();
        if (!_validBook(fields)) {
          diagnostic.add(MigrationDiagnosticCode.invalidField);
        }
        title = _readString(fields, 'title', diagnostic);
        author = _readString(fields, 'author', diagnostic);
        intro = _readString(fields, 'intro', diagnostic);
        total = _readInt(fields, 'totalChapters', diagnostic);
        bookLast = _readInt(fields, 'lastChapter', diagnostic);
        hits = _readInt(fields, 'hits', diagnostic);
        coverIndex = _readInt(fields, 'coverIndex', diagnostic);
        hasUpdate = _readBool(fields, 'hasUpdate', diagnostic);
        cover = _readNullableString(fields, 'coverURL', diagnostic);
        publishing = _readNullableString(fields, 'publishingHouse', diagnostic);
        lastUpdate = _readNullableString(fields, 'lastUpdate', diagnostic);
        completed = _readNullableBool(fields, 'isCompleted', diagnostic);
        wordCount = _readNullableInt(fields, 'wordCountK', diagnostic);
        final rawTags = fields['tags'];
        if (rawTags is RawJsonArray &&
            rawTags.values.every((v) => v is RawJsonString)) {
          tags.addAll(rawTags.values.cast<RawJsonString>().map((v) => v.value));
        } else if (rawTags != null) {
          diagnostic.add(MigrationDiagnosticCode.invalidField);
        }
        if (rawTags is RawJsonArray) {
          for (var i = 0; i < rawTags.values.length; i++) {
            final safe = _safeScalar(rawTags.values[i]);
            if (safe != null) {
              evidence.add(
                SafeLegacyEvidence(field: 'book.tag', ordinal: i, value: safe),
              );
            }
          }
        }
        for (final entry in fields.entries) {
          final field = switch (entry.key) {
            'id' => 'book.id',
            'title' => 'book.title',
            'author' => 'book.author',
            'source' => 'book.source',
            'intro' => 'book.intro',
            'coverURL' => 'book.coverReference',
            'publishingHouse' => 'book.publishingHouse',
            'lastUpdate' => 'book.lastUpdate',
            'totalChapters' => 'book.totalChapters',
            'lastChapter' => 'book.lastChapter',
            'hits' => 'book.hits',
            'coverIndex' => 'book.coverIndex',
            'hasUpdate' => 'book.hasUpdate',
            'isCompleted' => 'book.isCompleted',
            'wordCountK' => 'book.wordCountK',
            'tags' => null,
            _ => null,
          };
          if (field != null &&
              entry.key != 'id' &&
              _safeScalar(entry.value) != null) {
            evidence.add(
              SafeLegacyEvidence(
                field: field,
                value: safeValueFromRaw(entry.value),
              ),
            );
          } else if (field == null &&
              entry.key != 'id' &&
              entry.key != 'tags') {
            diagnostic.add(
              _secretLike(entry.key)
                  ? MigrationDiagnosticCode.secretExcluded
                  : MigrationDiagnosticCode.unknownField,
            );
          }
        }
      }
      if (sourceById != null) {
        evidence.add(
          SafeLegacyEvidence(
            field: 'source.byIdName',
            mapKey: id,
            value: SafeLegacyValue.string(sourceById),
          ),
        );
      }
      if (hasSourceCandidate && sourceById == null) {
        final safe = _safeScalar(rawSourceMap[id]);
        if (safe != null) {
          evidence.add(
            SafeLegacyEvidence(
              field: 'source.byIdName',
              mapKey: id,
              value: safe,
            ),
          );
        }
        diagnostic.add(MigrationDiagnosticCode.invalidField);
      }
      final knownTotal = knownTotals[id];
      final updateFlag = updateFlags.contains(id);
      if (knownTotal != null) {
        evidence.add(
          SafeLegacyEvidence(
            field: 'progress.knownTotal',
            mapKey: id,
            value: SafeLegacyValue.integer(knownTotal),
          ),
        );
      }
      if (updateFlagKnown) {
        evidence.add(
          SafeLegacyEvidence(
            field: 'progress.updateFlag',
            mapKey: id,
            value: SafeLegacyValue.boolean(updateFlag),
          ),
        );
      } else {
        evidence.add(
          SafeLegacyEvidence(
            field: 'progress.updateFlag',
            mapKey: id,
            value: const SafeLegacyValue.string('unknown'),
          ),
        );
      }
      final payload = BookImportPayload(
        bookId: BookId(id),
        bookRef: SourceBookRef(
          sourceId: _sourceId(sourceName),
          bookId: BookId(id),
        ),
        saved: savedKnown ? saved.contains(id) : null,
        sourceName: sourceName,
        sourceByIdName: sourceById,
        bookSourceName: bookSource,
        title: validBook ? title : null,
        author: validBook ? author : null,
        intro: validBook ? intro : null,
        tags: validBook ? tags : const [],
        totalChapters: validBook ? total : null,
        lastChapter: validBook ? bookLast : null,
        hits: validBook ? hits : null,
        coverIndex: validBook ? coverIndex : null,
        hasUpdate: validBook ? hasUpdate : null,
        coverUrl: validBook ? cover : null,
        publishingHouse: validBook ? publishing : null,
        lastUpdate: validBook ? lastUpdate : null,
        isCompleted: validBook ? completed : null,
        wordCountK: validBook ? wordCount : null,
        knownTotal: knownTotal,
        updateFlag: updateFlagKnown ? updateFlag : null,
        sourceConflict: sourceConflict,
      );
      books[id] = payload;
      final unit = _unit(
        MigrationEntityKind.book,
        id,
        evidence: evidence,
        diagnostic: !_validSet(values['savedIDs'])
            ? MigrationDiagnosticCode.invalidField
            : diagnostic.isEmpty
            ? null
            : _diagnostic(diagnostic),
        fatal: !savedKnown || !updateFlagKnown,
      );
      units.add(unit);
      payloads[_identity(unit)] = payload;
      if (duplicateBookIds.contains(id)) {
        // The plan's normalized identity is still unique; this explicit
        // conflict keeps the duplicate from being silently accepted.
        units.removeLast();
        final conflict = _unit(
          MigrationEntityKind.book,
          id,
          evidence: evidence,
          diagnostic: MigrationDiagnosticCode.conflictingEvidence,
        );
        units.add(conflict);
        payloads[_identity(conflict)] = payload;
      }
    }

    _planShelves(values, books, units, payloads);
    _planGroups(values, books, units, payloads);
    _planSplits(values, books, units, payloads);
    _planProgress(
      values,
      books,
      lastChapters,
      lastDates,
      readFlags,
      offsets,
      orphanOffsetKeys,
      units,
      payloads,
    );
    _planReader(values, units, payloads);
    _planApp(values, units, payloads);
    _planDeferred(values, books, bookSeconds, units, payloads);

    units.sort(_compareUnits);
    final normalized = _normalize(units);
    if (normalized.length > limits.maxPlannedUnits) {
      throw const MigrationFailure(MigrationFailureReason.resourceLimit);
    }
    return LegacyImportPlan(
      plan: MigrationPlan(
        inputType: input.inputType,
        runKey: input.runKey,
        units: normalized,
      ),
      payloads: Map.unmodifiable(payloads),
    );
  }

  void _planShelves(
    Map<String, RawJsonValue> values,
    Map<String, BookImportPayload> books,
    List<MigrationUnit> units,
    Map<String, LegacyImportPayload> payloads,
  ) {
    final raw = values['shelves'];
    if (raw == null) return;
    if (raw is! RawJsonArray) {
      units.add(
        _unit(
          MigrationEntityKind.shelf,
          'shelves',
          diagnostic: MigrationDiagnosticCode.invalidField,
        ),
      );
      return;
    }
    for (var index = 0; index < raw.values.length; index++) {
      final record = raw.values[index];
      if (record is! RawJsonObject || record.containsDuplicateKeysDeep()) {
        units.add(
          _unit(
            MigrationEntityKind.shelf,
            _framedKey(record, 'shelves', index, 'id'),
            diagnostic: MigrationDiagnosticCode.invalidField,
          ),
        );
        continue;
      }
      final id = _string(record.valueFor('id'));
      final name = _string(record.valueFor('name'));
      final memberRaw = record.valueFor('bookIDs');
      if (id == null ||
          !_validId(id) ||
          name == null ||
          memberRaw is! RawJsonArray) {
        units.add(
          _unit(
            MigrationEntityKind.shelf,
            id ?? 'shelves[$index]',
            diagnostic: MigrationDiagnosticCode.invalidField,
          ),
        );
        continue;
      }
      final members = <BookImportPayload>[];
      final memberIds = <String>[];
      var invalid = false;
      for (final member in memberRaw.values) {
        final bookId = _string(member);
        if (bookId == null || !books.containsKey(bookId)) {
          invalid = true;
          continue;
        }
        memberIds.add(bookId);
        members.add(books[bookId]!);
      }
      final duplicate = memberIds.toSet().length != memberIds.length;
      final targetId = ShelfId(_stableLocalId('shelf', id));
      final evidence = <SafeLegacyEvidence>[
        SafeLegacyEvidence(
          field: 'shelf.id',
          value: SafeLegacyValue.string(id),
        ),
        SafeLegacyEvidence(
          field: 'shelf.name',
          value: SafeLegacyValue.string(name),
        ),
        SafeLegacyEvidence(
          field: 'shelf.ordinal',
          value: SafeLegacyValue.integer(index),
        ),
        for (var i = 0; i < memberIds.length; i++)
          SafeLegacyEvidence(
            field: 'shelf.member',
            ordinal: i,
            value: SafeLegacyValue.string(memberIds[i]),
          ),
      ];
      final payload = ShelfImportPayload(
        legacyId: id,
        targetId: targetId,
        name: name,
        ordinal: index,
        members: members,
        hasDuplicateMembers: duplicate,
        hasInvalidMembers: invalid,
      );
      final unit = _unit(
        MigrationEntityKind.shelf,
        id,
        evidence: evidence,
        diagnostic: (duplicate || invalid)
            ? MigrationDiagnosticCode.conflictingEvidence
            : null,
        fatal: false,
      );
      units.add(unit);
      payloads[_identity(unit)] = payload;
    }
  }

  void _planGroups(
    Map<String, RawJsonValue> values,
    Map<String, BookImportPayload> books,
    List<MigrationUnit> units,
    Map<String, LegacyImportPayload> payloads,
  ) {
    final mapping = _stringMap(values['manualGroupByID']);
    final display = _stringMap(values['groupDisplayName']);
    final ids = <String>{...mapping.values, ...display.keys}
      ..removeWhere((id) => !_validId(id) || id.startsWith('auto:'));
    for (final id in ids.toList()..sort()) {
      final memberIds = mapping.entries
          .where((entry) => entry.value == id)
          .map((entry) => entry.key)
          .where(books.containsKey)
          .toList();
      final evidence = <SafeLegacyEvidence>[
        SafeLegacyEvidence(
          field: 'group.id',
          value: SafeLegacyValue.string(id),
        ),
        if (display[id] != null)
          SafeLegacyEvidence(
            field: 'group.name',
            value: SafeLegacyValue.string(display[id]!),
          ),
        for (var i = 0; i < memberIds.length; i++)
          SafeLegacyEvidence(
            field: 'group.member',
            ordinal: i,
            value: SafeLegacyValue.string(memberIds[i]),
          ),
      ];
      final unit = _unit(MigrationEntityKind.group, id, evidence: evidence);
      units.add(unit);
      payloads[_identity(unit)] = GroupImportPayload(
        legacyId: id,
        targetId: ManualGroupId(_stableLocalId('group', id)),
        displayName: display[id],
        members: [for (final member in memberIds) books[member]!],
      );
    }
    for (final entry in display.entries.where(
      (entry) => entry.key.startsWith('auto:'),
    )) {
      final unit = _unit(
        MigrationEntityKind.group,
        entry.key,
        evidence: [
          SafeLegacyEvidence(
            field: 'group.autoRename',
            value: SafeLegacyValue.string(entry.value),
          ),
        ],
      );
      units.add(unit);
      payloads[_identity(unit)] = AutoGroupRenamePayload(
        displayName: entry.value,
      );
    }
  }

  void _planSplits(
    Map<String, RawJsonValue> values,
    Map<String, BookImportPayload> books,
    List<MigrationUnit> units,
    Map<String, LegacyImportPayload> payloads,
  ) {
    final split = _stringSet(values['splitBookIDs']);
    for (final id in split.toList()..sort()) {
      final book = books[id];
      final unit = _unit(
        MigrationEntityKind.split,
        id,
        evidence: [
          SafeLegacyEvidence(
            field: 'split.bookId',
            value: SafeLegacyValue.string(id),
          ),
        ],
        diagnostic: book == null
            ? MigrationDiagnosticCode.missingEvidence
            : null,
        fatal: book == null,
      );
      units.add(unit);
      if (book != null) {
        payloads[_identity(unit)] = SplitImportPayload(book: book);
      }
    }
  }

  void _planProgress(
    Map<String, RawJsonValue> values,
    Map<String, BookImportPayload> books,
    Map<String, int> lastChapters,
    Map<String, double> lastDates,
    Set<String> readFlags,
    Map<String, RawJsonValue> offsets,
    Set<String> orphanOffsetKeys,
    List<MigrationUnit> units,
    Map<String, LegacyImportPayload> payloads,
  ) {
    final bookIds = <String>{
      ...books.values
          .where((book) => book.lastChapter != null)
          .map((book) => book.bookId.value),
      ...lastChapters.keys,
      ...lastDates.keys,
      ...readFlags,
      ...offsets.keys
          .map((key) => _offsetParts(key, books.keys)?.bookId)
          .whereType<String>(),
      ..._rawObject(values['lastChapterByID']).keys.where(_validId),
      ..._rawObject(values['lastReadAtByID']).keys.where(_validId),
      ..._rawObject(values['knownTotalChaptersByID']).keys.where(_validId),
      ..._stringSet(values['updateFlagIDs']),
    };
    for (final id in bookIds.toList()..sort()) {
      final book = books[id];
      if (book == null) continue;
      final rawLastChapters = _rawObject(values['lastChapterByID']);
      final rawLastDates = _rawObject(values['lastReadAtByID']);
      final rawKnownTotals = _rawObject(values['knownTotalChaptersByID']);
      final invalidLastChapter =
          rawLastChapters.containsKey(id) &&
          (_int(rawLastChapters[id]) == null || _int(rawLastChapters[id])! < 0);
      final invalidLastDate =
          rawLastDates.containsKey(id) && _number(rawLastDates[id]) == null;
      final invalidKnownTotal =
          rawKnownTotals.containsKey(id) && _int(rawKnownTotals[id]) == null;
      final selected = lastChapters[id] != null && lastChapters[id]! >= 0
          ? lastChapters[id]
          : (book.lastChapter != null && book.lastChapter! >= 0
                ? book.lastChapter
                : null);
      final disagreement =
          lastChapters[id] != null &&
          book.lastChapter != null &&
          lastChapters[id] != book.lastChapter;
      final fractionEntries = <({String key, int index, RawJsonValue value})>[];
      for (final entry in offsets.entries) {
        final parsed = _offsetParts(entry.key, books.keys);
        if (parsed?.bookId == id) {
          fractionEntries.add((
            key: entry.key,
            index: parsed!.chapterIndex,
            value: entry.value,
          ));
        }
      }
      fractionEntries.sort((a, b) => a.key.compareTo(b.key));
      double? fraction;
      String? selectedKey;
      var invalidFraction = false;
      final evidence = <SafeLegacyEvidence>[
        if (lastChapters[id] != null)
          SafeLegacyEvidence(
            field: 'progress.lastChapter',
            mapKey: id,
            value: SafeLegacyValue.integer(lastChapters[id]!),
          ),
        if (book.lastChapter != null)
          SafeLegacyEvidence(
            field: 'progress.bookLastChapter',
            mapKey: id,
            value: SafeLegacyValue.integer(book.lastChapter!),
          ),
        if (invalidLastChapter &&
            lastChapters[id] == null &&
            _safeScalar(rawLastChapters[id]) != null)
          SafeLegacyEvidence(
            field: 'progress.lastChapter',
            mapKey: id,
            value: _safeScalar(rawLastChapters[id])!,
          ),
        SafeLegacyEvidence(
          field: 'progress.hasRead',
          mapKey: id,
          value: SafeLegacyValue.boolean(readFlags.contains(id)),
        ),
      ];
      for (final entry in fractionEntries) {
        final value = _number(entry.value);
        final safe = _safeScalar(entry.value);
        if (safe != null) {
          evidence.add(
            SafeLegacyEvidence(
              field: 'progress.offset',
              mapKey: entry.key,
              value: safe,
            ),
          );
        }
        if (entry.index == selected && selectedKey == null) {
          selectedKey = entry.key;
          if (value != null && value >= 0 && value <= 1) {
            fraction = value;
          } else {
            invalidFraction = true;
          }
        }
      }
      final dateSeconds = lastDates[id];
      if (dateSeconds != null) {
        evidence.add(
          SafeLegacyEvidence(
            field: 'progress.appleDate',
            mapKey: id,
            value: SafeLegacyValue.number(dateSeconds),
          ),
        );
      }
      if (invalidLastDate) {
        final safe = _safeScalar(rawLastDates[id]);
        if (safe != null) {
          evidence.add(
            SafeLegacyEvidence(
              field: 'progress.appleDate',
              mapKey: id,
              value: safe,
            ),
          );
        }
      }
      if (invalidKnownTotal) {
        final safe = _safeScalar(rawKnownTotals[id]);
        if (safe != null) {
          evidence.add(
            SafeLegacyEvidence(
              field: 'progress.knownTotal',
              mapKey: id,
              value: safe,
            ),
          );
        }
      }
      final unit = _unit(
        MigrationEntityKind.progress,
        id,
        evidence: evidence,
        diagnostic:
            (!_validSet(values['readBookIDs']) ||
                disagreement ||
                invalidLastChapter ||
                invalidLastDate ||
                invalidKnownTotal ||
                invalidFraction ||
                (dateSeconds != null && _appleDate(dateSeconds) == null))
            ? MigrationDiagnosticCode.conflictingEvidence
            : null,
        fatal: !_validSet(values['readBookIDs']),
      );
      units.add(unit);
      payloads[_identity(unit)] = ProgressImportPayload(
        book: book,
        hasRead: readFlags.contains(id),
        selectedChapter: selected,
        selectedFraction: fraction,
        selectedOffsetKey: selectedKey,
        appleDateSeconds: dateSeconds,
        lastReadAt: _appleDate(dateSeconds),
      );
    }
    for (final key in orphanOffsetKeys.toList()..sort()) {
      final safe = _safeScalar(offsets[key]);
      final unit = _unit(
        MigrationEntityKind.progress,
        'offset:$key',
        evidence: safe == null
            ? const []
            : [
                SafeLegacyEvidence(
                  field: 'progress.offset',
                  mapKey: key,
                  value: safe,
                ),
              ],
        diagnostic: MigrationDiagnosticCode.missingEvidence,
        fatal: false,
      );
      units.add(unit);
      payloads[_identity(unit)] = const OrphanProgressPayload();
    }
  }

  void _planReader(
    Map<String, RawJsonValue> values,
    List<MigrationUnit> units,
    Map<String, LegacyImportPayload> payloads,
  ) {
    final raw = values['readerPreferences'];
    if (raw != null && (raw is! RawJsonObject || raw.hasDuplicateKeys)) {
      units.add(
        _unit(
          MigrationEntityKind.readerPreferences,
          'readerPreferences',
          diagnostic: MigrationDiagnosticCode.invalidField,
        ),
      );
      return;
    }
    final object = raw is RawJsonObject
        ? raw.uniqueValues()
        : const <String, RawJsonValue>{};
    final defaults = ReaderPreferencesV1.defaults();
    final invalid = <String>{};
    double number(String name, double fallback) {
      final value = _number(object[name]);
      if (object.containsKey(name) &&
          (value == null || (name == 'fontSize' ? value <= 0 : value < 0))) {
        invalid.add(name);
        return fallback;
      }
      return value ?? fallback;
    }

    bool boolean(String name, bool fallback) {
      final value = _bool(object[name]);
      if (object.containsKey(name) && value == null) {
        invalid.add(name);
        return fallback;
      }
      return value ?? fallback;
    }

    final value = ReaderPreferencesV1(
      fontSize: number('fontSize', defaults.fontSize),
      lineSpacing: number('lineSpacing', defaults.lineSpacing),
      background: _background(
        object['backgroundIndex'],
        defaults.background,
        invalid,
      ),
      mode: _mode(object['mode'], defaults.mode, invalid),
      fontFamily: _fontFamily(
        object['fontFamily'],
        defaults.fontFamily,
        invalid,
      ),
      bold: boolean('bold', defaults.bold),
      marginLeft: number('marginLeft', defaults.marginLeft),
      marginRight: number('marginRight', defaults.marginRight),
      marginTop: number('marginTop', defaults.marginTop),
      marginBottom: number('marginBottom', defaults.marginBottom),
    );
    final evidence = <SafeLegacyEvidence>[];
    for (final name in const [
      'fontSize',
      'lineSpacing',
      'backgroundIndex',
      'mode',
      'fontFamily',
      'bold',
      'marginLeft',
      'marginRight',
      'marginTop',
      'marginBottom',
    ]) {
      final field =
          'reader.${name == 'backgroundIndex' ? 'backgroundIndex' : name}';
      final rawValue = object[name];
      final safe =
          _safeScalar(rawValue) ?? _preferenceFallbackEvidence(name, value);
      if (safe != null) {
        evidence.add(SafeLegacyEvidence(field: field, value: safe));
      }
    }
    final unit = _unit(
      MigrationEntityKind.readerPreferences,
      'readerPreferences',
      evidence: evidence,
      diagnostic: invalid.isEmpty ? null : MigrationDiagnosticCode.invalidField,
      fatal: false,
    );
    units.add(unit);
    payloads[_identity(unit)] = ReaderPreferencesImportPayload(
      value: value,
      invalidFields: invalid,
    );
  }

  void _planApp(
    Map<String, RawJsonValue> values,
    List<MigrationUnit> units,
    Map<String, LegacyImportPayload> payloads,
  ) {
    final themeRaw = _string(values['theme']);
    final invalid = <String>{};
    final AppTheme theme;
    if (themeRaw == null) {
      if (values.containsKey('theme')) invalid.add('theme');
      theme = AppTheme.system;
    } else if (themeRaw == 'system') {
      theme = AppTheme.system;
    } else if (themeRaw == 'light') {
      theme = AppTheme.light;
    } else if (themeRaw == 'dark') {
      theme = AppTheme.dark;
    } else {
      invalid.add('theme');
      theme = AppTheme.system;
    }
    final preferredPresent = values.containsKey('preferredSource');
    final preferredName = preferredPresent
        ? (_string(values['preferredSource']) ?? '')
        : '文库8(在线)';
    if (preferredPresent && _string(values['preferredSource']) == null) {
      invalid.add('preferredSource');
    }
    final selectedRaw = values['selectedShelfID'];
    final selectedLegacy = _string(selectedRaw);
    if (values.containsKey('selectedShelfID') &&
        selectedRaw is! RawJsonString &&
        selectedRaw is! RawJsonNull) {
      invalid.add('selectedShelfID');
    }
    final selected = selectedLegacy == null || selectedLegacy == 'default'
        ? null
        : ShelfId(_stableLocalId('shelf', selectedLegacy));
    if (selectedLegacy != null && selectedLegacy != 'default') {
      final candidates = units
          .where(
            (unit) =>
                unit.entityKind == MigrationEntityKind.shelf &&
                unit.legacyKey == selectedLegacy,
          )
          .toList();
      final payload = candidates.length == 1
          ? payloads[_identity(candidates.single)]
          : null;
      final exists =
          candidates.length == 1 &&
          !candidates.single.isRecordFailure &&
          payload is ShelfImportPayload &&
          !payload.hasDuplicateMembers &&
          !payload.hasInvalidMembers;
      if (!exists) invalid.add('selectedShelfID');
    }
    final evidence = <SafeLegacyEvidence>[
      SafeLegacyEvidence(
        field: 'app.theme',
        value:
            _safeScalar(values['theme']) ??
            const SafeLegacyValue.string('system'),
      ),
      SafeLegacyEvidence(
        field: 'source.preferred',
        value:
            _safeScalar(values['preferredSource']) ??
            SafeLegacyValue.string(preferredName),
      ),
      if (_safeScalar(selectedRaw) != null)
        SafeLegacyEvidence(
          field: 'app.selectedShelf',
          value: _safeScalar(selectedRaw)!,
        )
      else if (selectedRaw is RawJsonNull || selectedRaw == null)
        const SafeLegacyEvidence(
          field: 'app.selectedShelf',
          value: SafeLegacyValue.nullValue(),
        ),
    ];
    final unit = _unit(
      MigrationEntityKind.appPreferences,
      'appPreferences',
      evidence: evidence,
      diagnostic: invalid.isEmpty
          ? null
          : MigrationDiagnosticCode.missingEvidence,
      fatal: false,
    );
    units.add(unit);
    payloads[_identity(unit)] = AppPreferencesImportPayload(
      theme: theme,
      preferredSourceId: _sourceId(preferredName),
      selectedShelfId: invalid.contains('selectedShelfID') ? null : selected,
      selectedShelfLegacyId: selectedLegacy,
      invalidFields: invalid,
    );
  }

  void _planDeferred(
    Map<String, RawJsonValue> values,
    Map<String, BookImportPayload> books,
    Map<String, int> bookSeconds,
    List<MigrationUnit> units,
    Map<String, LegacyImportPayload> payloads,
  ) {
    final statsEvidence = <SafeLegacyEvidence>[];
    var invalid = false;
    final daily = _rawObject(values['dailyStats']);
    for (final entry in daily.entries) {
      if (entry.value is! RawJsonObject) continue;
      final fields = entry.value as RawJsonObject;
      if (fields.containsDuplicateKeysDeep() ||
          fields.valueFor('seconds') is! RawJsonInteger ||
          fields.valueFor('chapters') is! RawJsonInteger) {
        invalid = true;
      }
      final seconds = _int(fields.valueFor('seconds'));
      final chapters = _int(fields.valueFor('chapters'));
      if (seconds != null) {
        statsEvidence.add(
          SafeLegacyEvidence(
            field: 'stats.dailySeconds',
            mapKey: entry.key,
            value: SafeLegacyValue.integer(seconds),
          ),
        );
      } else if (fields.fields.any((field) => field.name == 'seconds')) {
        invalid = true;
        final safe = _safeScalar(fields.valueFor('seconds'));
        if (safe != null) {
          statsEvidence.add(
            SafeLegacyEvidence(
              field: 'stats.dailySeconds',
              mapKey: entry.key,
              value: safe,
            ),
          );
        }
      }
      if (chapters != null) {
        statsEvidence.add(
          SafeLegacyEvidence(
            field: 'stats.dailyChapters',
            mapKey: entry.key,
            value: SafeLegacyValue.integer(chapters),
          ),
        );
      } else if (fields.fields.any((field) => field.name == 'chapters')) {
        invalid = true;
        final safe = _safeScalar(fields.valueFor('chapters'));
        if (safe != null) {
          statsEvidence.add(
            SafeLegacyEvidence(
              field: 'stats.dailyChapters',
              mapKey: entry.key,
              value: safe,
            ),
          );
        }
      }
    }
    final rawBookSeconds = _rawObject(values['bookReadingSeconds']);
    for (final entry in rawBookSeconds.entries) {
      if (!books.containsKey(entry.key)) continue;
      final seconds = bookSeconds[entry.key];
      if (seconds != null) {
        statsEvidence.add(
          SafeLegacyEvidence(
            field: 'stats.bookSeconds',
            mapKey: entry.key,
            value: SafeLegacyValue.integer(seconds),
          ),
        );
      } else {
        invalid = true;
        final safe = _safeScalar(entry.value);
        if (safe != null) {
          statsEvidence.add(
            SafeLegacyEvidence(
              field: 'stats.bookSeconds',
              mapKey: entry.key,
              value: safe,
            ),
          );
        }
      }
    }
    if (statsEvidence.isNotEmpty) {
      final unit = _unit(
        MigrationEntityKind.statistics,
        'statistics',
        evidence: statsEvidence,
        diagnostic: invalid ? MigrationDiagnosticCode.invalidField : null,
      );
      units.add(unit);
      payloads[_identity(unit)] = DeferredStatisticsPayload(
        evidenceCount: statsEvidence.length,
      );
    }
    final search = values['searchHistory'];
    if (search is RawJsonArray) {
      final evidence = <SafeLegacyEvidence>[];
      var invalidSearch = false;
      for (var i = 0; i < search.values.length; i++) {
        final term = _string(search.values[i]);
        if (term != null) {
          evidence.add(
            SafeLegacyEvidence(
              field: 'search.term',
              ordinal: i,
              value: SafeLegacyValue.string(term),
            ),
          );
        } else {
          invalidSearch = true;
          final safe = _safeScalar(search.values[i]);
          if (safe != null) {
            evidence.add(
              SafeLegacyEvidence(field: 'search.term', ordinal: i, value: safe),
            );
          }
        }
      }
      if (evidence.isNotEmpty) {
        final unit = _unit(
          MigrationEntityKind.searchHistory,
          'searchHistory',
          evidence: evidence,
          diagnostic: invalidSearch
              ? MigrationDiagnosticCode.invalidField
              : null,
        );
        units.add(unit);
        payloads[_identity(unit)] = DeferredSearchHistoryPayload(
          termCount: evidence.length,
        );
      }
    }
  }

  static List<SafeLegacyEvidence> _invalidBookEvidence(RawJsonObject record) {
    const fields = {
      'id': 'book.id',
      'title': 'book.title',
      'author': 'book.author',
      'source': 'book.source',
      'intro': 'book.intro',
      'totalChapters': 'book.totalChapters',
      'lastChapter': 'book.lastChapter',
      'hasUpdate': 'book.hasUpdate',
      'hits': 'book.hits',
      'coverIndex': 'book.coverIndex',
      'coverURL': 'book.coverReference',
      'publishingHouse': 'book.publishingHouse',
      'isCompleted': 'book.isCompleted',
      'wordCountK': 'book.wordCountK',
      'lastUpdate': 'book.lastUpdate',
    };
    final evidence = <SafeLegacyEvidence>[];
    for (final entry in record.uniqueValues().entries) {
      final field = fields[entry.key];
      final safe = _safeScalar(entry.value);
      if (field != null && safe != null) {
        evidence.add(SafeLegacyEvidence(field: field, value: safe));
      }
      final value = entry.value;
      if (entry.key == 'tags' && value is RawJsonArray) {
        for (var i = 0; i < value.values.length; i++) {
          final tag = _safeScalar(value.values[i]);
          if (tag != null) {
            evidence.add(
              SafeLegacyEvidence(field: 'book.tag', ordinal: i, value: tag),
            );
          }
        }
      }
    }
    return evidence;
  }

  static bool _validSet(RawJsonValue? raw) =>
      raw == null ||
      raw is RawJsonArray &&
          raw.values.every((v) => v is RawJsonString && _validId(v.value));

  static bool _validBook(Map<String, RawJsonValue> fields) {
    for (final name in ['id', 'title', 'author', 'source', 'intro']) {
      if (fields[name] is! RawJsonString) return false;
    }
    for (final name in ['totalChapters', 'lastChapter', 'hits', 'coverIndex']) {
      if (fields[name] is! RawJsonInteger) return false;
    }
    final tags = fields['tags'];
    return fields['hasUpdate'] is RawJsonBoolean &&
        tags is RawJsonArray &&
        tags.values.every((v) => v is RawJsonString);
  }

  /// Invalid containers and entries get explicit field-local failed receipts.
  /// Only schema-allowlisted scalars are retained, never arbitrary nested JSON.
  static void _planMalformedFields(
    Map<String, RawJsonValue> values,
    List<MigrationUnit> units,
  ) {
    const specs = <String, (MigrationEntityKind, String?, String)>{
      'savedIDs': (MigrationEntityKind.book, 'book.saved', 'set'),
      'readBookIDs': (MigrationEntityKind.progress, 'progress.hasRead', 'set'),
      'updateFlagIDs': (MigrationEntityKind.book, 'progress.updateFlag', 'set'),
      'splitBookIDs': (MigrationEntityKind.split, 'split.bookId', 'set'),
      'sourceByID': (
        MigrationEntityKind.source,
        'source.byIdName',
        'stringMap',
      ),
      'manualGroupByID': (MigrationEntityKind.group, 'group.id', 'stringMap'),
      'groupDisplayName': (
        MigrationEntityKind.group,
        'group.name',
        'stringMap',
      ),
      'lastChapterByID': (
        MigrationEntityKind.progress,
        'progress.lastChapter',
        'intMap',
      ),
      'lastReadAtByID': (
        MigrationEntityKind.progress,
        'progress.appleDate',
        'numberMap',
      ),
      'knownTotalChaptersByID': (
        MigrationEntityKind.book,
        'progress.knownTotal',
        'intMap',
      ),
      'chapterOffsetByID': (
        MigrationEntityKind.progress,
        'progress.offset',
        'numberMap',
      ),
      'dailyStats': (MigrationEntityKind.statistics, null, 'dailyMap'),
      'bookReadingSeconds': (
        MigrationEntityKind.statistics,
        'stats.bookSeconds',
        'intMap',
      ),
      'searchHistory': (
        MigrationEntityKind.searchHistory,
        'search.term',
        'array',
      ),
    };
    for (final spec in specs.entries) {
      final raw = values[spec.key];
      if (raw == null) continue;
      final (kind, field, type) = spec.value;
      void fail(String key, RawJsonValue? value, {int ordinal = 0}) {
        final safe = _safeScalar(value);
        units.add(
          _unit(
            kind,
            '\u0000invalid:${spec.key}:$key',
            evidence: field != null && safe != null
                ? [
                    SafeLegacyEvidence(
                      field: field,
                      mapKey: key,
                      ordinal: ordinal,
                      value: safe,
                    ),
                  ]
                : const [],
            diagnostic: MigrationDiagnosticCode.invalidField,
          ),
        );
      }

      if (type == 'set' || type == 'array') {
        if (raw is! RawJsonArray) {
          fail('', raw);
          continue;
        }
        for (var i = 0; i < raw.values.length; i++) {
          final value = raw.values[i];
          if (value is! RawJsonString ||
              (type == 'set' && !_validId(value.value))) {
            fail('index:$i', value, ordinal: i);
          }
        }
        continue;
      }
      if (raw is! RawJsonObject) {
        fail('', raw);
        continue;
      }
      final duplicate = raw.duplicateKeys;
      for (final key in duplicate) {
        fail(key, null);
      }
      for (final entry in raw.fields) {
        if (duplicate.contains(entry.name)) continue;
        final value = entry.value;
        final valid = switch (type) {
          'stringMap' =>
            value is RawJsonString &&
                (spec.key == 'groupDisplayName' || _validId(value.value)),
          'intMap' => value is RawJsonInteger,
          'numberMap' => _number(value) != null,
          'dailyMap' =>
            value is RawJsonObject &&
                !value.containsDuplicateKeysDeep() &&
                value.valueFor('seconds') is RawJsonInteger &&
                value.valueFor('chapters') is RawJsonInteger,
          _ => false,
        };
        if (!valid || (spec.key != 'dailyStats' && !_validId(entry.name))) {
          fail(entry.name, value);
        }
      }
    }
  }

  static MigrationUnit _unit(
    MigrationEntityKind kind,
    String key, {
    List<SafeLegacyEvidence> evidence = const [],
    MigrationDiagnosticCode? diagnostic,
    bool? fatal,
  }) => MigrationUnit(
    entityKind: kind,
    legacyKey: key,
    evidence: List.unmodifiable(evidence),
    diagnostic: diagnostic,
    fatal: fatal,
  );

  static String _identity(MigrationUnit unit) =>
      '${unit.entityKind.wireName}\u0000${unit.legacyKey}';

  static List<MigrationUnit> _normalize(List<MigrationUnit> units) {
    final byIdentity = <String, MigrationUnit>{};
    for (final unit in units) {
      final id = _identity(unit);
      final old = byIdentity[id];
      if (old == null) {
        byIdentity[id] = unit;
      } else {
        byIdentity[id] = _unit(
          unit.entityKind,
          unit.legacyKey,
          evidence: old.evidence,
          diagnostic: MigrationDiagnosticCode.conflictingEvidence,
        );
      }
    }
    return byIdentity.values.toList()..sort(_compareUnits);
  }

  static int _compareUnits(MigrationUnit a, MigrationUnit b) {
    const order = <MigrationEntityKind>[
      MigrationEntityKind.source,
      MigrationEntityKind.book,
      MigrationEntityKind.shelf,
      MigrationEntityKind.group,
      MigrationEntityKind.split,
      MigrationEntityKind.progress,
      MigrationEntityKind.readerPreferences,
      MigrationEntityKind.appPreferences,
      MigrationEntityKind.statistics,
      MigrationEntityKind.searchHistory,
    ];
    final compared = order
        .indexOf(a.entityKind)
        .compareTo(order.indexOf(b.entityKind));
    return compared == 0 ? a.legacyKey.compareTo(b.legacyKey) : compared;
  }

  static String? _string(RawJsonValue? value) =>
      value is RawJsonString ? value.value : null;
  static bool? _bool(RawJsonValue? value) =>
      value is RawJsonBoolean ? value.value : null;
  static int? _int(RawJsonValue? value) =>
      value is RawJsonInteger ? value.value : null;
  static double? _number(RawJsonValue? value) => switch (value) {
    RawJsonInteger(:final value) => value.toDouble(),
    RawJsonNumber(:final value) => value,
    _ => null,
  };

  static String? _readString(
    Map<String, RawJsonValue> fields,
    String name,
    Set<MigrationDiagnosticCode> diagnostics,
  ) {
    final value = fields[name];
    if (value == null) return null;
    final result = _string(value);
    if (result == null) diagnostics.add(MigrationDiagnosticCode.invalidField);
    return result;
  }

  static String? _readNullableString(
    Map<String, RawJsonValue> fields,
    String name,
    Set<MigrationDiagnosticCode> diagnostics,
  ) {
    final value = fields[name];
    if (value == null || value is RawJsonNull) return null;
    return _readString(fields, name, diagnostics);
  }

  static int? _readInt(
    Map<String, RawJsonValue> fields,
    String name,
    Set<MigrationDiagnosticCode> diagnostics,
  ) {
    final value = fields[name];
    if (value == null) return null;
    final result = _int(value);
    if (result == null) diagnostics.add(MigrationDiagnosticCode.invalidField);
    return result;
  }

  static int? _readNullableInt(
    Map<String, RawJsonValue> fields,
    String name,
    Set<MigrationDiagnosticCode> diagnostics,
  ) {
    if (fields[name] is RawJsonNull) return null;
    return _readInt(fields, name, diagnostics);
  }

  static bool? _readBool(
    Map<String, RawJsonValue> fields,
    String name,
    Set<MigrationDiagnosticCode> diagnostics,
  ) {
    final value = fields[name];
    if (value == null) return null;
    final result = _bool(value);
    if (result == null) diagnostics.add(MigrationDiagnosticCode.invalidField);
    return result;
  }

  static bool? _readNullableBool(
    Map<String, RawJsonValue> fields,
    String name,
    Set<MigrationDiagnosticCode> diagnostics,
  ) {
    if (fields[name] is RawJsonNull) return null;
    return _readBool(fields, name, diagnostics);
  }

  static Map<String, RawJsonValue> _rawObject(RawJsonValue? value) {
    if (value is! RawJsonObject) return const {};
    final counts = <String, int>{};
    for (final field in value.fields) {
      counts[field.name] = (counts[field.name] ?? 0) + 1;
    }
    return <String, RawJsonValue>{
      for (final field in value.fields)
        if (counts[field.name] == 1) field.name: field.value,
    };
  }

  static Map<String, String> _stringMap(RawJsonValue? value) => {
    for (final entry in _rawObject(value).entries)
      if (_string(entry.value) != null) entry.key: _string(entry.value)!,
  };
  static Map<String, int> _intMap(RawJsonValue? value) => {
    for (final entry in _rawObject(value).entries)
      if (_int(entry.value) != null) entry.key: _int(entry.value)!,
  };
  static Map<String, double> _numberMap(RawJsonValue? value) => {
    for (final entry in _rawObject(value).entries)
      if (_number(entry.value) != null) entry.key: _number(entry.value)!,
  };
  static Set<String> _stringSet(RawJsonValue? value) =>
      value is RawJsonArray && _validSet(value)
      ? value.values.map(_string).whereType<String>().where(_validId).toSet()
      : <String>{};
  static bool _validId(String id) => id.isNotEmpty && !id.contains('\u0000');

  static String? _chooseSource(
    bool hasPrimary,
    String? primary,
    String? fallback,
  ) => hasPrimary
      ? (primary == null || primary.isEmpty ? null : primary)
      : (fallback == null || fallback.isEmpty ? null : fallback);

  static SourceId _sourceId(String? name) {
    if (name == null || !_validId(name)) {
      return SourceId('legacy.ios.unassigned');
    }
    if (name == '文库8(在线)') return SourceId('builtin.wenku8');
    final encoded = base64Url.encode(utf8.encode(name)).replaceAll('=', '');
    return SourceId('legacy.ios.name.$encoded');
  }

  String _stableLocalId(String kind, String legacyId) {
    final datasetComponent = base64Url
        .encode(utf8.encode('$_datasetId\u0000$_mappingVersion'))
        .replaceAll('=', '');
    final idComponent = base64Url
        .encode(utf8.encode(legacyId))
        .replaceAll('=', '');
    return 'legacy.ios.$kind.v1.$datasetComponent.$idComponent';
  }

  static SafeLegacyValue? _safeScalar(RawJsonValue? value) {
    if (value == null || value is RawJsonObject || value is RawJsonArray) {
      return null;
    }
    return safeValueFromRaw(value);
  }

  static MigrationDiagnosticCode _diagnostic(
    Set<MigrationDiagnosticCode> values,
  ) => values.contains(MigrationDiagnosticCode.invalidField)
      ? MigrationDiagnosticCode.invalidField
      : values.first;

  static ReaderBackground _background(
    RawJsonValue? raw,
    ReaderBackground fallback,
    Set<String> invalid,
  ) {
    final value = _int(raw);
    if (raw == null) return fallback;
    if (value == null || value < 0 || value > 4) {
      invalid.add('backgroundIndex');
      return fallback;
    }
    return ReaderBackground.values[value];
  }

  static ReaderMode _mode(
    RawJsonValue? raw,
    ReaderMode fallback,
    Set<String> invalid,
  ) {
    final value = _string(raw);
    if (raw == null) return fallback;
    if (value == '仿真翻页') return ReaderMode.pageCurl;
    if (value == '滚动') return ReaderMode.scroll;
    invalid.add('mode');
    return fallback;
  }

  static ReaderFontFamily _fontFamily(
    RawJsonValue? raw,
    ReaderFontFamily fallback,
    Set<String> invalid,
  ) {
    final value = _string(raw);
    if (raw == null) return fallback;
    if (value == '系统') return ReaderFontFamily.system;
    if (value == '宋体') return ReaderFontFamily.songti;
    if (value == '楷体') return ReaderFontFamily.kaiti;
    if (value == '圆体') return ReaderFontFamily.yuanti;
    invalid.add('fontFamily');
    return fallback;
  }

  static SafeLegacyValue? _preferenceFallbackEvidence(
    String name,
    ReaderPreferencesV1 value,
  ) => switch (name) {
    'fontSize' => SafeLegacyValue.number(value.fontSize),
    'lineSpacing' => SafeLegacyValue.number(value.lineSpacing),
    'backgroundIndex' => SafeLegacyValue.integer(value.background.index),
    'mode' => SafeLegacyValue.string(
      value.mode == ReaderMode.pageCurl ? 'pageCurl' : 'scroll',
    ),
    'fontFamily' => SafeLegacyValue.string(value.fontFamily.name),
    'bold' => SafeLegacyValue.boolean(value.bold),
    'marginLeft' => SafeLegacyValue.number(value.marginLeft),
    'marginRight' => SafeLegacyValue.number(value.marginRight),
    'marginTop' => SafeLegacyValue.number(value.marginTop),
    'marginBottom' => SafeLegacyValue.number(value.marginBottom),
    _ => null,
  };

  static ({String bookId, int chapterIndex})? _offsetParts(
    String key,
    Iterable<String> knownIds,
  ) {
    final index = key.lastIndexOf('#');
    if (index <= 0 || index == key.length - 1) return null;
    final bookId = key.substring(0, index);
    final suffix = key.substring(index + 1);
    if (!knownIds.contains(bookId) ||
        !RegExp(r'^(0|[1-9][0-9]*)$').hasMatch(suffix)) {
      return null;
    }
    final chapter = int.tryParse(suffix);
    return chapter == null ? null : (bookId: bookId, chapterIndex: chapter);
  }

  static DateTime? _appleDate(double? seconds) {
    if (seconds == null || !seconds.isFinite) return null;
    try {
      final micros = (seconds * Duration.microsecondsPerSecond).round();
      final value = DateTime.utc(2001).add(Duration(microseconds: micros));
      if (value.year < 0 || value.year > 9999) return null;
      return value;
    } on Object {
      return null;
    }
  }

  static String _framedKey(
    RawJsonValue value,
    String field,
    int index,
    String idField,
  ) {
    if (value is RawJsonObject && !value.hasDuplicateKeys) {
      final id = _string(value.valueFor(idField));
      if (id != null && id.isNotEmpty) return id;
    }
    return '$field[$index]';
  }

  static bool _secretLike(String name) => RegExp(
    r'(cookie|password|token|credential|authorization|secret|passwd|api.?key)',
    caseSensitive: false,
  ).hasMatch(name);
}
