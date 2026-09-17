import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'migration_failure.dart';
import 'migration_models.dart';
import 'raw_json.dart';

/// Plans only sanitized evidence units. Concrete product conversion remains
/// F2.7 and is deliberately outside this class.
final class MigrationPlanner {
  const MigrationPlanner({this.limits = const MigrationResourceLimits()});

  final MigrationResourceLimits limits;

  MigrationPlan plan(MigrationInput input) {
    final root = RawJsonParser(limits: limits)
        .parse(input.bytes, allowDuplicateKeys: true);
    final state = _validatedState(root, input.inputType);
    final units = <MigrationUnit>[];
    _planBookLibrary(state, units);
    _planShelves(state, units);
    _planSources(state, units);
    _planReaderPreferences(state, units);
    _planAppPreferences(state, units);
    if (units.length > limits.maxPlannedUnits) {
      throw const MigrationFailure(MigrationFailureReason.resourceLimit);
    }
    return MigrationPlan(
      inputType: input.inputType,
      runKey: input.runKey,
      units: units,
    );
  }

  RawJsonObject _validatedState(
    RawJsonValue root,
    MigrationInputType inputType,
  ) {
    if (root is! RawJsonObject || root.hasDuplicateKeys) _invalidEnvelope();
    final values = root.uniqueValues();
    return switch (inputType) {
      MigrationInputType.legacyBackupV1 => _backupState(values),
      MigrationInputType.legacyIosSnapshotV1 => _snapshotState(values),
    };
  }

  RawJsonObject _backupState(Map<String, RawJsonValue> values) {
    if (values.containsKey('format') == false ||
        values.containsKey('version') == false ||
        values.containsKey('state') == false ||
        values.containsKey('exportedAt') == false) {
      _invalidEnvelope();
    }
    if (values['format'] case RawJsonString(:final value)) {
      if (value != 'lightnovelreader-backup') _invalidEnvelope();
    } else {
      _invalidEnvelope();
    }
    if (values['version'] case RawJsonInteger(:final value)) {
      if (value != 1) {
        throw const MigrationFailure(MigrationFailureReason.unsupportedVersion);
      }
    } else {
      _invalidEnvelope();
    }
    if (values['exportedAt'] is! RawJsonString) _invalidEnvelope();
    // The cookie is intentionally inspected only as an excluded envelope key;
    // its value is never copied, hashed separately, logged, or persisted.
    if (values['wenku8Cookie'] case RawJsonValue value) {
      if (value is! RawJsonString && value is! RawJsonNull) _invalidEnvelope();
    }
    final state = values['state'];
    if (state is! RawJsonObject || state.hasDuplicateKeys) _invalidEnvelope();
    return state;
  }

  RawJsonObject _snapshotState(Map<String, RawJsonValue> values) {
    // Explicit snapshot input is not allowed to smuggle a backup wrapper in
    // under a different caller-selected type.
    if (values.containsKey('format') ||
        values.containsKey('version') ||
        values.containsKey('state') ||
        values.containsKey('exportedAt') ||
        values.containsKey('wenku8Cookie')) {
      _invalidEnvelope();
    }
    final state = RawJsonObject(
      values.entries.map((entry) => RawJsonField(entry.key, entry.value)),
    );
    return state;
  }

  void _planBookLibrary(RawJsonObject state, List<MigrationUnit> units) {
    final raw = state.valueFor('bookLibrary');
    if (raw == null) return;
    if (raw is! RawJsonArray) {
      units.add(_failed(MigrationEntityKind.book, 'bookLibrary'));
      return;
    }
    for (var index = 0; index < raw.values.length; index++) {
      final record = raw.values[index];
      if (record is! RawJsonObject || record.containsDuplicateKeysDeep()) {
        units.add(_failed(MigrationEntityKind.book, 'bookLibrary[$index]'));
        continue;
      }
      units.add(_bookUnit(record, index));
      _checkPlannedUnits(units);
    }
  }

  MigrationUnit _bookUnit(RawJsonObject record, int index) {
    final values = record.uniqueValues();
    final id = values['id'];
    if (id is! RawJsonString || id.value.isEmpty) {
      return _failed(MigrationEntityKind.book, 'bookLibrary[$index]');
    }
    final evidence = <SafeLegacyEvidence>[];
    var omitted = 0;
    MigrationDiagnosticCode? diagnostic;
    const fields = <String, String>{
      'id': 'book.id',
      'title': 'book.title',
      'author': 'book.author',
      'source': 'book.source',
      'intro': 'book.intro',
      'coverURL': 'book.coverReference',
      'publishingHouse': 'book.publishingHouse',
      'lastUpdate': 'book.lastUpdate',
      'totalChapters': 'book.totalChapters',
      'lastChapter': 'book.lastChapter',
      'hits': 'book.hits',
      'coverIndex': 'book.coverIndex',
      'hasUpdate': 'book.hasUpdate',
      'isCompleted': 'book.isCompleted',
      'wordCountK': 'book.wordCountK',
    };
    for (final entry in values.entries) {
      if (entry.key == 'tags') {
        final tags = entry.value;
        if (tags is! RawJsonArray ||
            tags.values.any((value) => value is! RawJsonString)) {
          diagnostic ??= MigrationDiagnosticCode.invalidField;
        } else {
          for (var tagIndex = 0; tagIndex < tags.values.length; tagIndex++) {
            evidence.add(
              SafeLegacyEvidence(
                field: 'book.tag',
                ordinal: tagIndex,
                value: safeValueFromRaw(tags.values[tagIndex]),
              ),
            );
          }
        }
        continue;
      }
      final field = fields[entry.key];
      if (field == null) {
        omitted++;
        diagnostic ??= _isSecretLike(entry.key)
            ? MigrationDiagnosticCode.secretExcluded
            : MigrationDiagnosticCode.unknownField;
        continue;
      }
      if (!_bookFieldTypeIsValid(field, entry.value)) {
        diagnostic ??= MigrationDiagnosticCode.invalidField;
        continue;
      }
      evidence.add(
        SafeLegacyEvidence(field: field, value: safeValueFromRaw(entry.value)),
      );
    }
    if (diagnostic == MigrationDiagnosticCode.invalidField) {
      return MigrationUnit(
        entityKind: MigrationEntityKind.book,
        legacyKey: id.value,
        evidence: evidence,
        omittedFieldCount: omitted,
        diagnostic: diagnostic,
      );
    }
    return MigrationUnit(
      entityKind: MigrationEntityKind.book,
      legacyKey: id.value,
      evidence: evidence,
      omittedFieldCount: omitted,
      diagnostic: diagnostic,
    );
  }

  bool _bookFieldTypeIsValid(String field, RawJsonValue value) {
    if (value is RawJsonNull) {
      return field == 'book.coverReference' ||
          field == 'book.publishingHouse' ||
          field == 'book.lastUpdate' ||
          field == 'book.isCompleted' ||
          field == 'book.wordCountK';
    }
    return switch (field) {
      'book.totalChapters' ||
      'book.lastChapter' ||
      'book.hits' ||
      'book.coverIndex' ||
      'book.wordCountK' => value is RawJsonInteger,
      'book.hasUpdate' || 'book.isCompleted' => value is RawJsonBoolean,
      _ => value is RawJsonString,
    };
  }

  void _planShelves(RawJsonObject state, List<MigrationUnit> units) {
    final raw = state.valueFor('shelves');
    if (raw is! RawJsonArray) return;
    for (var index = 0; index < raw.values.length; index++) {
      final record = raw.values[index];
      if (record is! RawJsonObject || record.containsDuplicateKeysDeep()) {
        units.add(_failed(MigrationEntityKind.shelf, 'shelves[$index]'));
        continue;
      }
      final values = record.uniqueValues();
      final id = values['id'];
      if (id is! RawJsonString || id.value.isEmpty) {
        units.add(_failed(MigrationEntityKind.shelf, 'shelves[$index]'));
        continue;
      }
      final evidence = <SafeLegacyEvidence>[];
      var omitted = 0;
      MigrationDiagnosticCode? diagnostic;
      for (final entry in values.entries) {
        switch (entry.key) {
          case 'id':
            if (entry.value is RawJsonString) {
              evidence.add(
                SafeLegacyEvidence(
                  field: 'shelf.id',
                  value: safeValueFromRaw(entry.value),
                ),
              );
            } else {
              diagnostic ??= MigrationDiagnosticCode.invalidField;
            }
          case 'name':
            if (entry.value is RawJsonString) {
              evidence.add(
                SafeLegacyEvidence(
                  field: 'shelf.name',
                  value: safeValueFromRaw(entry.value),
                ),
              );
            } else {
              diagnostic ??= MigrationDiagnosticCode.invalidField;
            }
          case 'bookIDs':
            final members = entry.value;
            if (members is RawJsonArray &&
                members.values.every((value) => value is RawJsonString)) {
              for (
                var memberIndex = 0;
                memberIndex < members.values.length;
                memberIndex++
              ) {
                evidence.add(
                  SafeLegacyEvidence(
                    field: 'shelf.member',
                    ordinal: memberIndex,
                    value: safeValueFromRaw(members.values[memberIndex]),
                  ),
                );
              }
            } else {
              diagnostic ??= MigrationDiagnosticCode.invalidField;
            }
          default:
            omitted++;
            diagnostic ??= _isSecretLike(entry.key)
                ? MigrationDiagnosticCode.secretExcluded
                : MigrationDiagnosticCode.unknownField;
        }
      }
      units.add(
        MigrationUnit(
          entityKind: MigrationEntityKind.shelf,
          legacyKey: id.value,
          evidence: evidence,
          omittedFieldCount: omitted,
          diagnostic: diagnostic,
        ),
      );
      _checkPlannedUnits(units);
    }
  }

  void _planSources(RawJsonObject state, List<MigrationUnit> units) {
    final raw = state.valueFor('sourceByID');
    if (raw is RawJsonObject) {
      if (raw.containsDuplicateKeysDeep()) {
        units.add(_failed(MigrationEntityKind.source, 'sourceByID'));
        return;
      }
      for (final entry in raw.uniqueValues().entries) {
        if (entry.value is RawJsonString) {
          units.add(
            MigrationUnit(
              entityKind: MigrationEntityKind.source,
              legacyKey: entry.key,
              evidence: [
                SafeLegacyEvidence(
                  field: 'source.byIdName',
                  mapKey: entry.key,
                  value: safeValueFromRaw(entry.value),
                ),
              ],
            ),
          );
        } else {
          units.add(_failed(MigrationEntityKind.source, entry.key));
        }
        _checkPlannedUnits(units);
      }
    }
    final preferred = state.valueFor('preferredSource');
    if (preferred is RawJsonString) {
      units.add(
        MigrationUnit(
          entityKind: MigrationEntityKind.source,
          legacyKey: 'preferred',
          evidence: [
            SafeLegacyEvidence(
              field: 'source.preferred',
              value: SafeLegacyValue.string(preferred.value),
            ),
          ],
        ),
      );
    }
  }

  void _planReaderPreferences(RawJsonObject state, List<MigrationUnit> units) {
    final raw = state.valueFor('readerPreferences');
    if (raw is! RawJsonObject) return;
    if (raw.containsDuplicateKeysDeep()) {
      units.add(_failed(MigrationEntityKind.readerPreferences, 'singleton'));
      return;
    }
    const fields = <String, String>{
      'fontSize': 'reader.fontSize',
      'lineSpacing': 'reader.lineSpacing',
      'backgroundIndex': 'reader.backgroundIndex',
      'mode': 'reader.mode',
      'fontFamily': 'reader.fontFamily',
      'bold': 'reader.bold',
      'marginLeft': 'reader.marginLeft',
      'marginRight': 'reader.marginRight',
      'marginTop': 'reader.marginTop',
      'marginBottom': 'reader.marginBottom',
    };
    final evidence = <SafeLegacyEvidence>[];
    var omitted = 0;
    MigrationDiagnosticCode? diagnostic;
    for (final entry in raw.uniqueValues().entries) {
      final field = fields[entry.key];
      if (field == null) {
        omitted++;
        diagnostic ??= _isSecretLike(entry.key)
            ? MigrationDiagnosticCode.secretExcluded
            : MigrationDiagnosticCode.unknownField;
        continue;
      }
      if (entry.value is RawJsonObject || entry.value is RawJsonArray) {
        diagnostic ??= MigrationDiagnosticCode.invalidField;
        continue;
      }
      evidence.add(
        SafeLegacyEvidence(field: field, value: safeValueFromRaw(entry.value)),
      );
    }
    units.add(
      MigrationUnit(
        entityKind: MigrationEntityKind.readerPreferences,
        legacyKey: 'singleton',
        evidence: evidence,
        omittedFieldCount: omitted,
        diagnostic: diagnostic,
      ),
    );
  }

  void _planAppPreferences(RawJsonObject state, List<MigrationUnit> units) {
    final evidence = <SafeLegacyEvidence>[];
    final theme = state.valueFor('theme');
    if (theme != null) {
      if (theme is RawJsonString) {
        evidence.add(
          SafeLegacyEvidence(
            field: 'app.theme',
            value: SafeLegacyValue.string(theme.value),
          ),
        );
      } else {
        units.add(_failed(MigrationEntityKind.appPreferences, 'singleton'));
        return;
      }
    }
    final shelf = state.valueFor('selectedShelfID');
    if (shelf != null) {
      if (shelf is RawJsonString || shelf is RawJsonNull) {
        evidence.add(
          SafeLegacyEvidence(
            field: 'app.selectedShelf',
            value: safeValueFromRaw(shelf),
          ),
        );
      } else {
        units.add(_failed(MigrationEntityKind.appPreferences, 'singleton'));
        return;
      }
    }
    if (evidence.isNotEmpty) {
      units.add(
        MigrationUnit(
          entityKind: MigrationEntityKind.appPreferences,
          legacyKey: 'singleton',
          evidence: evidence,
        ),
      );
    }
  }

  MigrationUnit _failed(MigrationEntityKind kind, String key) => MigrationUnit(
    entityKind: kind,
    legacyKey: key,
    diagnostic: MigrationDiagnosticCode.invalidField,
  );

  void _checkPlannedUnits(List<MigrationUnit> units) {
    if (units.length > limits.maxPlannedUnits) {
      throw const MigrationFailure(MigrationFailureReason.resourceLimit);
    }
  }

  static bool _isSecretLike(String name) => RegExp(
    r'(cookie|password|passwd|token|secret|credential|authorization|auth)',
    caseSensitive: false,
  ).hasMatch(name);

  Never _invalidEnvelope() =>
      throw const MigrationFailure(MigrationFailureReason.invalidEnvelope);
}

/// Candidate IDs are derived only after recursive secret exclusion and use a
/// stable field/map-key/ordinal/type/value encoding.
String candidateIdFor(Iterable<SafeLegacyEvidence> values) {
  final sorted = values.toList()
    ..sort((a, b) {
      final left = _canonicalEvidence(a);
      final right = _canonicalEvidence(b);
      return left.compareTo(right);
    });
  final canonical = sorted.map(_canonicalEvidence).join('|');
  return 'candidate-${sha256.convert(utf8.encode(canonical))}';
}

String _canonicalEvidence(SafeLegacyEvidence evidence) {
  final value = evidence.value;
  final scalar = switch (value.type) {
    SafeLegacyValueType.string => base64Url.encode(
      utf8.encode(value.stringValue!),
    ),
    SafeLegacyValueType.integer => value.integerValue.toString(),
    SafeLegacyValueType.number => value.numberValue.toString(),
    SafeLegacyValueType.boolean => value.booleanValue! ? '1' : '0',
    SafeLegacyValueType.nullValue => '',
  };
  return [
    _lengthPrefixed(evidence.field),
    _lengthPrefixed(evidence.mapKey),
    evidence.ordinal.toString(),
    value.type.name,
    _lengthPrefixed(scalar),
  ].join(':');
}

String _lengthPrefixed(String value) => '${value.length}:$value';
