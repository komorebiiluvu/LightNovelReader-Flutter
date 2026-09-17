import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_reader/src/data/migration/legacy_state_import_service.dart';
import 'package:light_novel_reader/src/data/persistence/database.dart';
import 'package:light_novel_reader/src/domain/migration/legacy_import_models.dart';
import 'package:light_novel_reader/src/domain/migration/legacy_import_planner.dart';
import 'package:light_novel_reader/src/domain/migration/migration_models.dart';

Map<String, Object?> book([String id = 'book-a']) => {
  'id': id,
  'title': 'Title',
  'author': 'Author',
  'tags': ['A', 'B'],
  'source': '文库8(在线)',
  'totalChapters': 10,
  'lastChapter': 0,
  'hasUpdate': false,
  'hits': 1,
  'intro': 'Intro',
  'coverIndex': 0,
};

MigrationInput input(
  Map<String, Object?> state, {
  String dataset = 'review',
  int version = 1,
}) => MigrationInput(
  datasetId: dataset,
  mappingVersion: version,
  inputType: MigrationInputType.legacyIosSnapshotV1,
  bytes: utf8.encode(jsonEncode(state)),
);

void main() {
  late AppDatabase db;
  late LegacyStateImportService service;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    service = LegacyStateImportService(db);
    await service.repository.ensureDataset('review');
  });
  tearDown(() => db.close());

  Future<LegacyImportResult> run(Map<String, Object?> state) =>
      service.importWithReport(input(state));
  Future<List<Map<String, dynamic>>> rows(String sql) async =>
      (await db.customSelect(sql).get()).map((r) => r.data).toList();
  Future<Map<String, dynamic>> row(String sql) async =>
      (await rows(sql)).single;
  Future<List<Map<String, dynamic>>> evidence(String field) async =>
      (await db
              .customSelect(
                'SELECT * FROM safe_legacy_values WHERE field=? ORDER BY ordinal',
                variables: [Variable(field)],
              )
              .get())
          .map((r) => r.data)
          .toList();

  for (final name in ['文库8(在线)', '文库8', '轻小说源A', '轻小说源B', '  自定义源😀  ']) {
    test('source exact identity: $name', () async {
      await run({
        'bookLibrary': [
          {...book('wk8-000123'), 'source': name},
        ],
      });
      final expected = name == '文库8(在线)'
          ? 'builtin.wenku8'
          : 'legacy.ios.name.${base64Url.encode(utf8.encode(name)).replaceAll('=', '')}';
      expect((await row('SELECT source_id,book_id FROM library_entries')), {
        'source_id': expected,
        'book_id': 'wk8-000123',
      });
      final source = (await rows('SELECT * FROM source_registrations'))
          .singleWhere((r) => r['source_id'] == expected);
      expect(source['display_name'], name);
      expect(
        source['availability'],
        name == '文库8(在线)' ? 'unavailable' : 'unresolved',
      );
    });
  }
  test('missing source creates unassigned saved orphan stub', () async {
    await run({
      'savedIDs': ['orphan'],
    });
    final r = await row('SELECT * FROM library_entries');
    expect(r['source_id'], 'legacy.ios.unassigned');
    expect(r['saved'], 1);
    expect(r['metadata_state'], 'stub');
  });
  test('source candidate disagreement preserves both exact names', () async {
    await run({
      'bookLibrary': [book()],
      'sourceByID': {'book-a': '文库8'},
    });
    final r = await row(
      "SELECT * FROM legacy_identity_mappings WHERE entity_kind='book'",
    );
    expect(r['resolution'], 'conflict');
    expect(r['source_by_id_name'], '文库8');
    expect(r['book_source_name'], '文库8(在线)');
  });

  for (final field in book().keys) {
    for (final missing in [true, false]) {
      test(
        'required Book $field ${missing ? 'missing' : 'wrong type'} isolates sibling',
        () async {
          final bad = book();
          if (missing) {
            bad.remove(field);
          } else {
            bad[field] = {'invalid': true};
          }
          final result = await run({
            'bookLibrary': [bad, book('good')],
            'savedIDs': ['book-a'],
          });
          expect(
            result.report.failures + result.report.unresolvedRecords,
            greaterThan(0),
          );
          final all = await rows('SELECT * FROM library_entries');
          expect(
            all.singleWhere((r) => r['book_id'] == 'good')['metadata_state'],
            'known',
          );
          expect(
            all.singleWhere((r) => r['book_id'] == 'book-a')['metadata_state'],
            'stub',
          );
          expect(
            (await rows(
              "SELECT * FROM record_outcomes WHERE entity_kind='book' AND legacy_key='book-a' AND outcome='imported'",
            )),
            isEmpty,
          );
        },
      );
    }
  }
  for (final optional in [
    <String, Object?>{},
    {
      'coverURL': null,
      'publishingHouse': null,
      'isCompleted': null,
      'wordCountK': null,
      'lastUpdate': null,
    },
    {
      'coverURL': 'https://example.invalid/a',
      'publishingHouse': '出版',
      'isCompleted': true,
      'wordCountK': 12,
      'lastUpdate': '昨天',
    },
  ]) {
    test('optional Book fields ${jsonEncode(optional)}', () async {
      final result = await run({
        'bookLibrary': [
          {...book(), ...optional},
        ],
      });
      expect(result.report.failures, 0);
      expect(result.report.conflicts, 0);
      final r = await row('SELECT * FROM library_entries');
      expect(r['metadata_state'], 'known');
      expect(r['saved'], 0);
      final meta = await row('SELECT * FROM legacy_book_metadata');
      expect(meta['cover_reference'], optional['coverURL']);
      expect(meta['word_count_k'], optional['wordCountK']);
      expect(r['cover_asset_id'], isNull);
    });
  }
  for (final tags in [
    ['A', 'C'],
    ['B', 'A'],
  ]) {
    test('changed tags $tags retain accepted ordered baseline', () async {
      await run({
        'bookLibrary': [book()],
      });
      final before = await evidence('book.tag');
      expect(before.map((r) => r['text_value']), ['A', 'B']);
      expect(before.map((r) => r['ordinal']), [0, 1]);
      expect(
        (await row(
          "SELECT diagnostic_code FROM record_outcomes WHERE entity_kind='book'",
        ))['diagnostic_code'],
        isNull,
      );
      final result = await run({
        'bookLibrary': [
          {...book(), 'tags': tags},
        ],
      });
      expect(result.run.state, MigrationRunState.partial);
      expect(result.report.conflicts, greaterThan(0));
      expect(
        (await rows('SELECT tag FROM book_tags ORDER BY ordinal'))
            .map((r) => r['tag']),
        ['A', 'B'],
      );
      expect(
        (await evidence('book.tag'))
            .where((r) => r['purpose'] == 'conflict-candidate')
            .map((r) => r['text_value']),
        tags,
      );
    });
  }
  for (final existing in [null, 'user title']) {
    test(
      'preexisting metadata ${existing == null ? 'missing fields fill' : 'wins'}',
      () async {
        await db.customStatement(
          "INSERT INTO source_registrations VALUES ('builtin.wenku8','文库8(在线)','unavailable')",
        );
        await db.customStatement(
          "INSERT INTO library_entries(source_id,book_id,metadata_state,title) VALUES ('builtin.wenku8','book-a','stub',?)",
          [existing],
        );
        final result = await run({
          'bookLibrary': [book()],
        });
        expect(
          (await row('SELECT title FROM library_entries'))['title'],
          existing ?? 'Title',
        );
        expect(result.report.conflicts, existing == null ? 0 : greaterThan(0));
      },
    );
  }
  test('later metadata change is candidate, not overwrite', () async {
    await run({
      'bookLibrary': [book()],
    });
    final result = await run({
      'bookLibrary': [
        {...book(), 'title': 'Changed'},
      ],
    });
    expect(result.report.conflicts, greaterThan(0));
    expect((await row('SELECT title FROM library_entries'))['title'], 'Title');
  });

  const sets = ['savedIDs', 'readBookIDs', 'updateFlagIDs', 'splitBookIDs'];
  const maps = [
    'sourceByID',
    'manualGroupByID',
    'groupDisplayName',
    'lastChapterByID',
    'lastReadAtByID',
    'knownTotalChaptersByID',
    'chapterOffsetByID',
    'dailyStats',
    'bookReadingSeconds',
  ];
  for (final field in [...sets, ...maps, 'searchHistory']) {
    for (final bad in [42, null]) {
      test('present malformed $field=$bad is never missing default', () async {
        final result = await run({
          field: bad,
          'bookLibrary': [book()],
          'theme': 'dark',
        });
        expect(result.run.state, MigrationRunState.partial);
        expect(result.report.failures, greaterThan(0));
        expect(
          (await row('SELECT theme FROM app_preferences'))['theme'],
          'dark',
        );
        if (field == 'savedIDs') {
          expect(
            await rows(
              "SELECT * FROM record_outcomes WHERE entity_kind='book' AND outcome IN ('imported','unchanged')",
            ),
            isEmpty,
          );
        }
        if (field == 'readBookIDs') {
          expect(await rows('SELECT * FROM reading_progress'), isEmpty);
        }
      });
    }
  }
  for (final field in sets) {
    test(
      'invalid element in $field fails field instead of silent dropping',
      () async {
        final result = await run({
          field: ['book-a', 7],
          'bookLibrary': [book()],
        });
        expect(result.report.failures, greaterThan(0));
        expect(result.run.state, MigrationRunState.partial);
      },
    );
    test('duplicate $field strings collapse as Set', () async {
      final result = await run({
        field: ['book-a', 'book-a'],
        'bookLibrary': [book()],
      });
      expect(result.report.failures, 0);
      expect(result.report.conflicts, 0);
    });
  }
  for (final entry in {
    'manualGroupByID': 123,
    'groupDisplayName': false,
    'sourceByID': 123,
    'bookReadingSeconds': 12.5,
  }.entries) {
    test(
      'malformed map member ${entry.key} retained with valid sibling',
      () async {
        final good = entry.key == 'bookReadingSeconds' ? 12 : 'group-good';
        final result = await run({
          entry.key: {'bad': entry.value, 'good': good},
          'savedIDs': ['sibling'],
        });
        expect(result.report.failures, greaterThan(0));
        expect(
          await rows(
            "SELECT * FROM library_entries WHERE book_id='sibling' AND saved=1",
          ),
          hasLength(1),
        );
        expect(
          await rows(
            "SELECT * FROM safe_legacy_values WHERE map_key='bad' AND purpose='conflict-candidate'",
          ),
          isNotEmpty,
        );
        expect(
          await rows(
            "SELECT * FROM safe_legacy_values WHERE map_key='good' OR legacy_key='good' OR legacy_key='group-good'",
          ),
          isNotEmpty,
        );
      },
    );
  }

  for (final theme in [
    'absent',
    'system',
    'light',
    'dark',
    'mystery',
    7,
    true,
    null,
  ]) {
    test('theme exact missing/malformed policy: $theme', () async {
      await run({if (theme != 'absent') 'theme': theme});
      final valid = ['absent', 'system', 'light', 'dark'].contains(theme);
      expect((await row('SELECT theme,accent FROM app_preferences')), {
        'theme': ['light', 'dark'].contains(theme) ? theme : 'system',
        'accent': null,
      });
      expect(
        (await row(
          "SELECT outcome FROM record_outcomes WHERE entity_kind='appPreferences'",
        ))['outcome'],
        valid ? 'imported' : 'preserved-unresolved',
      );
      final e = (await evidence('app.theme')).single;
      if (theme == 7) {
        expect(e['integer_value'], 7);
      }
      if (theme == 'mystery') {
        expect(e['text_value'], 'mystery');
      }
    });
  }
  test('preferred source exact; preexisting app values win', () async {
    await run({'theme': 'dark', 'preferredSource': '  自定义😀  '});
    final before = await row('SELECT * FROM app_preferences');
    expect(before['preferred_source_id'], startsWith('legacy.ios.name.'));
    final result = await run({'theme': 'light'});
    expect(result.report.conflicts, greaterThan(0));
    expect(await row('SELECT * FROM app_preferences'), before);
  });

  final readerCases = <String, List<(Object, String, Object)>>{
    'backgroundIndex': [
      for (var i = 0; i < 5; i++)
        (
          i,
          'background',
          ['paperWhite', 'parchment', 'darkGray', 'black', 'eyeCare'][i],
        ),
    ],
    'mode': [('仿真翻页', 'mode', 'pageCurl'), ('滚动', 'mode', 'scroll')],
    'fontFamily': [
      ('系统', 'font_family', 'system'),
      ('宋体', 'font_family', 'songti'),
      ('楷体', 'font_family', 'kaiti'),
      ('圆体', 'font_family', 'yuanti'),
    ],
    'fontSize': [(26, 'font_size', 26.0), (26.5, 'font_size', 26.5)],
    'lineSpacing': [(9, 'line_spacing', 9.0), (9.5, 'line_spacing', 9.5)],
    'bold': [(true, 'bold', 1)],
    'marginLeft': [(40, 'margin_left', 40.0), (40.5, 'margin_left', 40.5)],
    'marginRight': [(41, 'margin_right', 41.0)],
    'marginTop': [(80, 'margin_top', 80.0)],
    'marginBottom': [(30, 'margin_bottom', 30.0)],
  };
  for (final field in readerCases.entries) {
    for (final c in field.value) {
      test('Reader ${field.key}=${c.$1}', () async {
        await run({
          'readerPreferences': {field.key: c.$1},
        });
        expect((await row('SELECT * FROM reader_preferences'))[c.$2], c.$3);
      });
    }
    test('Reader invalid ${field.key} isolated from sibling', () async {
      await run({
        'readerPreferences': {
          field.key: null,
          if (field.key != 'bold') 'bold': true,
          if (field.key == 'bold') 'fontSize': 30,
        },
      });
      final r = await row('SELECT * FROM reader_preferences');
      expect(
        r[field.key == 'bold' ? 'font_size' : 'bold'],
        field.key == 'bold' ? 30.0 : 1,
      );
      expect(
        (await row(
          "SELECT outcome FROM record_outcomes WHERE entity_kind='readerPreferences'",
        ))['outcome'],
        'preserved-unresolved',
      );
      expect(
        (await evidence('reader.${field.key}')).single['value_type'],
        'null',
      );
    });
  }
  test('absent Reader object uses all frozen defaults', () async {
    await run({});
    expect(await row('SELECT * FROM reader_preferences'), {
      'singleton': 1,
      'version': 1,
      'font_size': 22.0,
      'line_spacing': 8.0,
      'background': 'paperWhite',
      'mode': 'pageCurl',
      'font_family': 'kaiti',
      'bold': 0,
      'margin_left': 35.0,
      'margin_right': 35.0,
      'margin_top': 72.0,
      'margin_bottom': 24.0,
    });
  });
  for (final container in [42, 'bad', null, <Object>[]]) {
    test('Reader wrong container $container writes no defaults', () async {
      final result = await run({
        'readerPreferences': container,
        'theme': 'dark',
      });
      expect(result.report.failures, greaterThan(0));
      expect(await rows('SELECT * FROM reader_preferences'), isEmpty);
      expect((await row('SELECT theme FROM app_preferences'))['theme'], 'dark');
    });
  }
  test('Reader duplicate key is record-local failure', () async {
    final result = await service.importWithReport(
      MigrationInput(
        datasetId: 'review',
        inputType: MigrationInputType.legacyIosSnapshotV1,
        bytes: utf8.encode(
          '{"readerPreferences":{"fontSize":22,"fontSize":23},"theme":"dark"}',
        ),
      ),
    );
    expect(result.report.failures, 1);
    expect(await rows('SELECT * FROM reader_preferences'), isEmpty);
    expect((await row('SELECT theme FROM app_preferences'))['theme'], 'dark');
  });

  test(
    'shelves preserve order, members, same names, mappings and selected shelf',
    () async {
      final state = {
        'shelves': [
          {
            'id': 's2',
            'name': 'same',
            'bookIDs': ['b', 'a'],
          },
          {
            'id': 's1',
            'name': 'same',
            'bookIDs': ['c'],
          },
        ],
        'selectedShelfID': 's2',
      };
      await run(state);
      final shelves = await rows('SELECT * FROM shelves ORDER BY ordinal');
      expect(shelves.map((r) => r['name']), ['same', 'same']);
      expect(shelves.map((r) => r['ordinal']), [0, 1]);
      expect(
        (await rows(
          'SELECT book_id FROM shelf_members ORDER BY shelf_id DESC,ordinal',
        )).map((r) => r['book_id']).toSet(),
        {'a', 'b', 'c'},
      );
      expect(
        (await db
                .customSelect(
                  'SELECT book_id FROM shelf_members WHERE shelf_id=? ORDER BY ordinal',
                  variables: [Variable(shelves.first['shelf_id'] as String)],
                )
                .get())
            .map((r) => r.read<String>('book_id')),
        ['b', 'a'],
      );
      expect(
        (await row(
          'SELECT selected_shelf_id FROM app_preferences',
        ))['selected_shelf_id'],
        shelves.first['shelf_id'],
      );
      expect(
        (await rows('SELECT metadata_state FROM library_entries'))
            .every((r) => r['metadata_state'] == 'stub'),
        isTrue,
      );
      await run(state);
      expect(await rows('SELECT * FROM shelves ORDER BY ordinal'), shelves);
      final changed = await run({
        'shelves': [
          {
            'id': 's2',
            'name': 'same',
            'bookIDs': ['a', 'b'],
          },
          {
            'id': 's1',
            'name': 'same',
            'bookIDs': ['c'],
          },
        ],
        'selectedShelfID': 's2',
      });
      expect(changed.report.conflicts, greaterThan(0));
      expect(await rows('SELECT * FROM shelves ORDER BY ordinal'), shelves);
    },
  );
  for (final selected in [null, 'default', 'missing']) {
    test('selected shelf $selected never invented', () async {
      await run({'selectedShelfID': selected});
      expect(
        (await row(
          'SELECT selected_shelf_id FROM app_preferences',
        ))['selected_shelf_id'],
        isNull,
      );
      expect(await rows('SELECT * FROM shelves'), isEmpty);
      if (selected == 'missing') {
        expect(
          (await row(
            "SELECT outcome FROM record_outcomes WHERE entity_kind='appPreferences'",
          ))['outcome'],
          'preserved-unresolved',
        );
      }
    });
  }
  for (final shelves in [
    [
      {'id': 's', 'name': 42, 'bookIDs': <String>[]},
    ],
    [
      {'id': 's', 'name': 'one', 'bookIDs': <String>[]},
      {'id': 's', 'name': 'two', 'bookIDs': <String>[]},
    ],
    [
      {
        'id': 's',
        'name': 'one',
        'bookIDs': ['a', 'a'],
      },
    ],
  ]) {
    test('selected malformed/duplicate shelf ${jsonEncode(shelves)}', () async {
      await run({'shelves': shelves, 'selectedShelfID': 's'});
      expect(
        (await row(
          'SELECT selected_shelf_id FROM app_preferences',
        ))['selected_shelf_id'],
        isNull,
      );
      expect(
        (await row(
          "SELECT outcome FROM record_outcomes WHERE entity_kind='appPreferences'",
        ))['outcome'],
        'preserved-unresolved',
      );
      expect((await evidence('app.selectedShelf')).single['text_value'], 's');
    });
  }
  test(
    'preexisting shelf collision remains user-owned; selection unresolved',
    () async {
      final state = {
        'shelves': [
          {'id': 's', 'name': 'legacy', 'bookIDs': <String>[]},
        ],
        'selectedShelfID': 's',
      };
      final plan = LegacyImportPlanner().plan(input(state));
      final unit = plan.plan.units.singleWhere(
        (u) => u.entityKind == MigrationEntityKind.shelf,
      );
      final shelf = plan.payloadFor(unit) as ShelfImportPayload;
      await db.customStatement('INSERT INTO shelves VALUES (?,?,0)', [
        shelf.targetId.value,
        'user',
      ]);
      final result = await run(state);
      expect(result.report.conflicts, greaterThan(0));
      expect((await row('SELECT name FROM shelves'))['name'], 'user');
      expect(
        (await row(
          'SELECT selected_shelf_id FROM app_preferences',
        ))['selected_shelf_id'],
        isNull,
      );
    },
  );
  test(
    'manual group and split coexist; auto rename never creates group',
    () async {
      await run({
        'manualGroupByID': {'b': 'g', 'a': 'g'},
        'groupDisplayName': {'g': '  组😀  ', 'auto:title': 'renamed'},
        'splitBookIDs': ['a'],
      });
      expect(
        (await row('SELECT display_name FROM manual_groups'))['display_name'],
        '  组😀  ',
      );
      expect(
        (await rows('SELECT book_id FROM group_members ORDER BY book_id'))
            .map((r) => r['book_id']),
        ['a', 'b'],
      );
      expect((await row('SELECT book_id,is_split FROM split_overrides')), {
        'book_id': 'a',
        'is_split': 1,
      });
      expect(
        (await row(
          "SELECT resolution FROM legacy_identity_mappings WHERE entity_kind='group'",
        ))['resolution'],
        'resolved',
      );
      expect(
        (await row(
          "SELECT outcome FROM record_outcomes WHERE legacy_key='auto:title'",
        ))['outcome'],
        'deferred-preserved',
      );
    },
  );

  for (final fraction in [0, 1, 0.25]) {
    test(
      'final # BookId primary locator fraction $fraction and extra offset',
      () async {
        await run({
          'bookLibrary': [book('a#b')],
          'lastChapterByID': {'a#b': 2},
          'chapterOffsetByID': {'a#b#2': fraction, 'a#b#1': 0.75},
        });
        final locator = await row('SELECT * FROM legacy_chapter_locators');
        expect(locator['book_id'], 'a#b');
        expect(locator['chapter_index'], 2);
        expect(locator['raw_offset_key'], 'a#b#2');
        expect(locator['fraction'], fraction.toDouble());
        expect(
          (await evidence('progress.offset')).map((r) => r['map_key']).toSet(),
          {'a#b#2', 'a#b#1'},
        );
        expect(
          (await row('SELECT chapter_id,has_read FROM reading_progress')),
          {'chapter_id': null, 'has_read': 0},
        );
      },
    );
  }
  test(
    'Book chapter fallback remains zero based with explicit hasRead',
    () async {
      await run({
        'bookLibrary': [book()],
        'readBookIDs': ['book-a'],
      });
      expect(
        (await row(
          'SELECT chapter_index FROM legacy_chapter_locators',
        ))['chapter_index'],
        0,
      );
      expect(
        (await row('SELECT has_read FROM reading_progress'))['has_read'],
        1,
      );
    },
  );
  test('snapshot chapter precedence retains disagreement evidence', () async {
    await run({
      'bookLibrary': [book()],
      'lastChapterByID': {'book-a': 3},
    });
    expect(
      (await row(
        'SELECT chapter_index FROM legacy_chapter_locators',
      ))['chapter_index'],
      3,
    );
    expect(
      (await evidence('progress.bookLastChapter')).single['integer_value'],
      0,
    );
    expect((await evidence('progress.lastChapter')).single['integer_value'], 3);
    expect(
      (await row(
        "SELECT outcome FROM record_outcomes WHERE entity_kind='progress'",
      ))['outcome'],
      'preserved-unresolved',
    );
  });
  for (final fraction in [-0.1, 1.1, 'bad']) {
    test('invalid fraction $fraction is preserved not clamped', () async {
      await run({
        'bookLibrary': [book()],
        'chapterOffsetByID': {'book-a#0': fraction},
      });
      expect(
        (await row('SELECT fraction FROM legacy_chapter_locators'))['fraction'],
        isNull,
      );
      expect(await evidence('progress.offset'), isNotEmpty);
      expect(
        (await rows(
          "SELECT outcome FROM record_outcomes WHERE entity_kind='progress' AND legacy_key='book-a'",
        )).single['outcome'],
        'preserved-unresolved',
      );
    });
  }
  test(
    'orphan offset remains unresolved without invented book or locator',
    () async {
      await run({
        'chapterOffsetByID': {'orphan#0': 0.5},
      });
      expect(await rows('SELECT * FROM legacy_chapter_locators'), isEmpty);
      expect(await rows('SELECT * FROM library_entries'), isEmpty);
      expect((await evidence('progress.offset')).single['map_key'], 'orphan#0');
    },
  );
  for (final seconds in [0, 1.5, -1.5, null, 1e20, 'bad']) {
    test(
      'Apple date $seconds retains raw evidence and valid UTC only',
      () async {
        await run({
          'readBookIDs': ['b'],
          'lastReadAtByID': {'b': seconds},
        });
        final r = await row('SELECT * FROM reading_progress');
        expect(r['legacy_locator_id'], isNull);
        expect(r['chapter_id'], isNull);
        final valid = seconds is num && seconds.abs() < 1e10;
        expect(
          r['last_read_at'],
          valid
              ? DateTime.utc(2001)
                    .add(Duration(microseconds: (seconds * 1000000).round()))
                    .toIso8601String()
              : isNull,
        );
        expect(await evidence('progress.appleDate'), isNotEmpty);
      },
    );
  }
  test(
    'known total and update hints retained without inferring read',
    () async {
      await run({
        'knownTotalChaptersByID': {'b': 12},
        'updateFlagIDs': ['b'],
      });
      expect(
        (await row(
          'SELECT known_total_chapters,update_flag FROM library_entries',
        )),
        {'known_total_chapters': 12, 'update_flag': 1},
      );
      expect(
        (await row('SELECT has_read,legacy_locator_id FROM reading_progress')),
        {'has_read': 0, 'legacy_locator_id': null},
      );
      expect(
        (await evidence('progress.knownTotal')).single['integer_value'],
        12,
      );
      expect(await evidence('progress.updateFlag'), isNotEmpty);
    },
  );
  for (final mutation in {
    'dataset_id': 'other',
    'legacy_book_id': 'wrong',
    'chapter_index': 3,
    'raw_offset_key': 'wrong#0',
    'fraction': 0.8,
    'remote_id_evidence': 'remote',
    'chapter_title_evidence': 'chapter',
    'volume_title_evidence': 'volume',
    'catalog_digest': 'digest',
  }.entries) {
    test('durable locator ${mutation.key} corruption cannot verify', () async {
      final state = {
        'bookLibrary': [book()],
        'chapterOffsetByID': {'book-a#0': 0.5},
      };
      await run(state);
      await service.repository.ensureDataset('other');
      await db.customStatement(
        'UPDATE legacy_chapter_locators SET ${mutation.key}=?',
        [mutation.value],
      );
      final result = await run(state);
      expect(result.run.state, MigrationRunState.partial);
      expect(result.report.conflicts, greaterThan(0));
    });
  }
  test('missing required locator pointer is verification failure', () async {
    final state = {
      'bookLibrary': [book()],
    };
    await run(state);
    await db.customStatement(
      'UPDATE reading_progress SET legacy_locator_id=NULL',
    );
    final result = await run(state);
    expect(result.run.state, MigrationRunState.partial);
    expect(result.report.failures, greaterThan(0));
  });
  test('unexpected locator on no-locator progress is conflict', () async {
    final state = {
      'readBookIDs': ['b'],
    };
    await run(state);
    await db.customStatement(
      "INSERT INTO legacy_chapter_locators(locator_id,dataset_id,source_id,book_id,legacy_book_id,chapter_index) VALUES ('extra','review','legacy.ios.unassigned','b','b',0)",
    );
    await db.customStatement(
      "UPDATE reading_progress SET legacy_locator_id='extra'",
    );
    final result = await run(state);
    expect(result.report.conflicts, greaterThan(0));
  });

  test(
    'integer stats exact day, repeat never sums, later change conflicts',
    () async {
      final state = {
        'dailyStats': {
          '  日期😀  ': {'seconds': 12, 'chapters': 2},
        },
        'bookReadingSeconds': {'b': 88},
      };
      await run(state);
      final before = await rows(
        "SELECT * FROM safe_legacy_values WHERE field LIKE 'stats.%'",
      );
      expect(before.every((r) => r['value_type'] == 'integer'), isTrue);
      expect(
        (await evidence('stats.dailySeconds')).single['map_key'],
        '  日期😀  ',
      );
      await run(state);
      expect(
        await rows(
          "SELECT * FROM safe_legacy_values WHERE field LIKE 'stats.%'",
        ),
        before,
      );
      final changed = await run({
        'dailyStats': {
          '  日期😀  ': {'seconds': 13, 'chapters': 2},
        },
        'bookReadingSeconds': {'b': 88},
      });
      expect(changed.report.conflicts, greaterThan(0));
      expect(
        (await evidence('stats.dailySeconds'))
            .where((r) => r['purpose'] == 'accepted-baseline')
            .single['integer_value'],
        12,
      );
    },
  );
  for (final state in [
    {
      'dailyStats': {
        'd': {'seconds': 12.5, 'chapters': 2},
      },
    },
    {
      'dailyStats': {
        'd': {'seconds': 12, 'chapters': 2.5},
      },
    },
    {
      'bookReadingSeconds': {'b': 88.25},
    },
  ]) {
    test('decimal statistics malformed ${jsonEncode(state)}', () async {
      final result = await run(state);
      expect(result.report.failures, greaterThan(0));
      expect(
        await rows(
          "SELECT * FROM safe_legacy_values WHERE field LIKE 'stats.%' AND value_type='number' AND purpose='accepted-baseline'",
        ),
        isEmpty,
      );
      expect(
        await rows(
          "SELECT * FROM safe_legacy_values WHERE field LIKE 'stats.%' AND purpose='conflict-candidate'",
        ),
        isNotEmpty,
      );
    });
  }
  test(
    'search exact order duplicates whitespace Unicode and no truncation',
    () async {
      final terms = [
        '  😀  ',
        'same',
        'same',
        for (var i = 0; i < 15; i++) 'term$i',
      ];
      await run({'searchHistory': terms});
      expect(
        (await evidence('search.term')).map((r) => r['text_value']),
        terms,
      );
      expect(
        (await evidence('search.term')).map((r) => r['ordinal']),
        List.generate(terms.length, (i) => i),
      );
    },
  );
  for (final raw in [
    '{bad',
    '{"state":{},"state":{},"format":"lightnovelreader-backup","version":1,"exportedAt":0}',
  ]) {
    test('fatal JSON/envelope leaves zero import writes: $raw', () async {
      final before = await rows('SELECT * FROM migration_datasets');
      await expectLater(
        service.importInput(
          MigrationInput(
            datasetId: 'review',
            inputType: raw == '{bad'
                ? MigrationInputType.legacyIosSnapshotV1
                : MigrationInputType.legacyBackupV1,
            bytes: utf8.encode(raw),
          ),
        ),
        throwsA(anything),
      );
      expect(await rows('SELECT * FROM migration_runs'), isEmpty);
      expect(await rows('SELECT * FROM record_receipts'), isEmpty);
      expect(await rows('SELECT * FROM library_entries'), isEmpty);
      expect(await rows('SELECT * FROM migration_datasets'), before);
    });
  }
  test('secrets/whole input excluded from every storage column; original bytes unchanged', () async {
    const sentinel = 'REVIEW_SECRET_SENTINEL';
    final state = {
      'bookLibrary': [
        {...book(), 'cookie': sentinel},
      ],
      'cookie': sentinel,
      'password': sentinel,
      'readerPreferences': {'token': sentinel},
      'sourceCredentials': {'key': sentinel},
    };
    final bytes = utf8.encode(jsonEncode(state));
    final before = List<int>.of(bytes);
    await service.importInput(
      MigrationInput(
        datasetId: 'review',
        inputType: MigrationInputType.legacyIosSnapshotV1,
        bytes: bytes,
      ),
    );
    expect(bytes, before);
    final tables = await rows(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
    );
    for (final table in tables) {
      final name = (table['name'] as String).replaceAll('"', '""');
      for (final r in await rows('SELECT * FROM "$name"')) {
        for (final value in r.values) {
          expect(value.toString(), isNot(contains(sentinel)));
          expect(value.toString(), isNot(contains(jsonEncode(state))));
        }
      }
    }
  });
  test(
    'same service concurrent datasets isolate mappings locators and receipts',
    () async {
      await service.repository.ensureDataset('A');
      await service.repository.ensureDataset('B');
      final results = await Future.wait([
        service.importWithReport(
          input({
            'bookLibrary': [book('a')],
          }, dataset: 'A'),
        ),
        service.importWithReport(
          input(
            {
              'bookLibrary': [book('b')],
            },
            dataset: 'B',
            version: 2,
          ),
        ),
      ]);
      expect(
        results.every((r) => r.run.state == MigrationRunState.complete),
        isTrue,
      );
      final locators = await rows(
        'SELECT dataset_id,book_id FROM legacy_chapter_locators ORDER BY dataset_id',
      );
      expect(locators, [
        {'dataset_id': 'A', 'book_id': 'a'},
        {'dataset_id': 'B', 'book_id': 'b'},
      ]);
      final mappings = await rows(
        "SELECT dataset_id,legacy_key,mapping_version FROM legacy_identity_mappings WHERE entity_kind='book' ORDER BY dataset_id",
      );
      expect(mappings, [
        {'dataset_id': 'A', 'legacy_key': 'a', 'mapping_version': 1},
        {'dataset_id': 'B', 'legacy_key': 'b', 'mapping_version': 2},
      ]);
      final receipts = await rows(
        "SELECT dataset_id,legacy_key FROM record_receipts WHERE entity_kind='book' ORDER BY dataset_id",
      );
      expect(receipts, [
        {'dataset_id': 'A', 'legacy_key': 'a'},
        {'dataset_id': 'B', 'legacy_key': 'b'},
      ]);
    },
  );
  for (final column in ['source_id', 'book_id']) {
    test('damaged locator $column is detected even with broken foreign keys', () async {
      final state = {
        'bookLibrary': [book()],
      };
      await run(state);
      // Deliberately model an externally corrupted database, not a legal write.
      await db.customStatement('PRAGMA foreign_keys=OFF');
      await db.customStatement('UPDATE legacy_chapter_locators SET $column=?', [
        'wrong',
      ]);
      await db.customStatement('PRAGMA foreign_keys=ON');
      final result = await run(state);
      expect(result.run.state, MigrationRunState.partial);
      expect(result.report.conflicts, greaterThan(0));
    });
  }
  test('missing referenced locator row fails durable verification', () async {
    final state = {
      'bookLibrary': [book()],
    };
    await run(state);
    await db.customStatement('PRAGMA foreign_keys=OFF');
    await db.customStatement('DELETE FROM legacy_chapter_locators');
    await db.customStatement('PRAGMA foreign_keys=ON');
    final result = await run(state);
    expect(result.report.failures, greaterThan(0));
    expect(result.run.state, MigrationRunState.partial);
  });
  test(
    'wrong locator pointer with matching scalar fields is conflict',
    () async {
      final state = {
        'bookLibrary': [book()],
      };
      await run(state);
      await db.customStatement(
        "INSERT INTO legacy_chapter_locators(locator_id,dataset_id,source_id,book_id,legacy_book_id,chapter_index) VALUES ('wrong','review','builtin.wenku8','book-a','book-a',0)",
      );
      await db.customStatement(
        "UPDATE reading_progress SET legacy_locator_id='wrong'",
      );
      expect((await run(state)).report.conflicts, greaterThan(0));
    },
  );
  for (final field in [
    'lastChapterByID',
    'lastReadAtByID',
    'knownTotalChaptersByID',
    'chapterOffsetByID',
  ]) {
    test(
      'malformed $field member retains scalar and unrelated valid entry',
      () async {
        final badKey = field == 'chapterOffsetByID' ? 'bad#0' : 'bad';
        final goodKey = field == 'chapterOffsetByID' ? 'good#0' : 'good';
        final result = await run({
          field: {badKey: false, goodKey: 0},
          'savedIDs': ['good'],
        });
        expect(result.report.failures, greaterThan(0));
        expect(
          (await rows('SELECT * FROM safe_legacy_values')).where(
            (r) =>
                r['map_key'] == badKey && r['purpose'] == 'conflict-candidate',
          ),
          isNotEmpty,
        );
        expect(
          await rows(
            "SELECT * FROM library_entries WHERE book_id='good' AND saved=1",
          ),
          hasLength(1),
        );
      },
    );
  }
  test(
    'daily missing required integer is not valid deferred aggregate',
    () async {
      final result = await run({
        'dailyStats': {
          'bad': {'seconds': 12},
        },
        'theme': 'dark',
      });
      expect(result.report.failures, greaterThan(0));
      expect(
        (await evidence('stats.dailySeconds')).single['purpose'],
        'conflict-candidate',
      );
      expect((await row('SELECT theme FROM app_preferences'))['theme'], 'dark');
    },
  );
  test(
    'search mixed malformed element is explicit failed evidence, not success',
    () async {
      final result = await run({
        'searchHistory': ['good', 7, '  😀  '],
      });
      expect(result.report.failures, greaterThan(0));
      expect(
        (await evidence('search.term')).where((r) => r['text_value'] == 'good'),
        isNotEmpty,
      );
      expect(
        await rows(
          "SELECT * FROM record_outcomes WHERE entity_kind='searchHistory' AND outcome='deferred-preserved'",
        ),
        isEmpty,
      );
    },
  );
  test('invalid Book id still retains allowlisted scalar evidence', () async {
    final bad = book()..remove('id');
    await run({
      'bookLibrary': [bad],
    });
    expect((await evidence('book.title')).single['text_value'], 'Title');
    expect(
      (await evidence('book.title')).single['purpose'],
      'conflict-candidate',
    );
    expect(await rows('SELECT * FROM library_entries'), isEmpty);
  });
  for (final fixture in [
    'f2_7_full_backup_v1.json',
    'f2_7_full_snapshot_v1.json',
  ]) {
    test(
      'frozen happy fixture $fixture types and exact complete counts',
      () async {
        final bytes = await File('test/fixtures/$fixture').readAsBytes();
        final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
        final snapshot = fixture.contains('backup')
            ? json['state'] as Map<String, dynamic>
            : json;
        for (final b in snapshot['bookLibrary'] as List) {
          for (final field in ['id', 'title', 'author', 'source', 'intro']) {
            expect(b[field], isA<String>());
          }
          for (final field in [
            'totalChapters',
            'lastChapter',
            'hits',
            'coverIndex',
          ]) {
            expect(b[field], isA<int>());
          }
          expect(b['hasUpdate'], isA<bool>());
          expect(b['tags'], everyElement(isA<String>()));
        }
        for (final stat in (snapshot['dailyStats'] as Map).values) {
          expect(stat['seconds'], isA<int>());
          expect(stat['chapters'], isA<int>());
        }
        expect(
          (snapshot['bookReadingSeconds'] as Map).values,
          everyElement(isA<int>()),
        );
        final result = await service.importWithReport(
          MigrationInput(
            datasetId: 'review',
            inputType: fixture.contains('backup')
                ? MigrationInputType.legacyBackupV1
                : MigrationInputType.legacyIosSnapshotV1,
            bytes: bytes,
          ),
        );
        expect(result.run.state, MigrationRunState.complete);
        expect(result.report.failures, 0);
        expect(result.report.conflicts, 0);
        expect(result.report.expectedByKind, result.report.verifiedByKind);
        expect(
          result.report.expectedByKind.values.fold(0, (a, b) => a + b),
          21,
        );
        expect(result.report.outcomeCounts[MigrationOutcome.imported], 10);
        expect(
          result.report.outcomeCounts[MigrationOutcome.preservedUnresolved],
          8,
        );
        expect(
          result.report.outcomeCounts[MigrationOutcome.deferredPreserved],
          3,
        );
      },
    );
  }
}
