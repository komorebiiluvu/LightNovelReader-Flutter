import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:light_novel_reader/src/core/app_error.dart';
import 'package:light_novel_reader/src/core/app_logger.dart';
import 'package:light_novel_reader/src/data/persistence/database.dart';
import 'package:light_novel_reader/src/data/persistence/database_open.dart';

import 'generated/schema.dart';

Future<void> source(AppDatabase db, String id) => db.customStatement(
  'INSERT INTO source_registrations(source_id, availability) VALUES (?, ?)',
  [id, 'unresolved'],
);
Future<void> book(AppDatabase db, String s, String b) => db.customStatement(
  'INSERT INTO library_entries(source_id, book_id, metadata_state) VALUES (?, ?, ?)',
  [s, b, 'stub'],
);
Future<int> count(AppDatabase db, String table) async =>
    (await db.customSelect('SELECT count(*) AS n FROM $table').getSingle())
        .read<int>('n');

// No historical Flutter SQL schema existed. This fixture lives only in tests.
class SyntheticPreV1Database extends AppDatabase {
  SyntheticPreV1Database(super.executor, {this.fail = false});
  final bool fail;

  @override
  Future<void> createSchema(Migrator migrator) => upgradeSchema(migrator, 0, 1);

  @override
  Future<void> upgradeSchema(Migrator migrator, int from, int to) async {
    if (from != 0 || to != 1) throw StateError('unexpected test migration');
    await migrator.createAll();
    await customStatement(
      "INSERT INTO source_registrations(source_id, availability) SELECT id, 'unresolved' FROM synthetic_pre_v1_sources",
    );
    await customStatement('DROP TABLE synthetic_pre_v1_sources');
    if (fail) throw StateError('injected migration failure');
  }
}

void main() {
  // Every instance below has its own executor and isolated memory/file storage.
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });
  tearDownAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
  });
  late AppDatabase db;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  test(
    'clean v1 has complete schema, foreign keys and snapshot agreement',
    () async {
      final tables = await db
          .customSelect("SELECT name FROM sqlite_schema WHERE type='table'")
          .get();
      expect(
        tables.map((row) => row.read<String>('name')),
        unorderedEquals([
          'source_registrations',
          'library_entries',
          'book_tags',
          'legacy_book_metadata',
          'shelves',
          'shelf_members',
          'manual_groups',
          'group_members',
          'split_overrides',
          'migration_datasets',
          'migration_runs',
          'record_receipts',
          'record_outcomes',
          'safe_legacy_values',
          'legacy_identity_mappings',
          'legacy_chapter_locators',
          'reading_progress',
          'reader_preferences',
          'app_preferences',
        ]),
      );
      expect(
        (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
          'user_version',
        ),
        1,
      );
      expect(
        (await db.customSelect('PRAGMA foreign_keys').getSingle()).read<int>(
          'foreign_keys',
        ),
        1,
      );
      await SchemaVerifier(GeneratedHelper()).migrateAndValidate(db, 1);
    },
  );

  test('same remote book IDs in different sources remain distinct', () async {
    for (final id in ['a', 'b']) {
      await source(db, id);
      await book(db, id, '42');
    }
    expect(await count(db, 'library_entries'), 2);
    await expectLater(
      book(db, 'a', '42'),
      throwsA(isA<sqlite.SqliteException>()),
    );
  });

  test(
    'renaming or disabling a source preserves exact library references',
    () async {
      await source(db, 'immutable-source');
      await book(db, 'immutable-source', 'wk8-001');
      await db.customStatement(
        "UPDATE source_registrations SET display_name='Renamed', availability='unavailable' WHERE source_id='immutable-source'",
      );
      final row = await db
          .customSelect('SELECT * FROM library_entries')
          .getSingle();
      expect(row.read<String>('source_id'), 'immutable-source');
      expect(row.read<String>('book_id'), 'wk8-001');
      await expectLater(
        db.customStatement(
          "UPDATE source_registrations SET source_id='replacement'",
        ),
        throwsA(isA<sqlite.SqliteException>()),
      );
    },
  );

  test(
    'injected executor avoids resolving a production storage root',
    () async {
      final opened = await openAppDatabase(
        executor: NativeDatabase.memory(),
        storageRoot: () => throw StateError('must not resolve a real root'),
      );
      try {
        await source(opened, 'in-memory');
        expect(await count(opened, 'source_registrations'), 1);
        expect(await count(db, 'source_registrations'), 0);
      } finally {
        await opened.close();
      }
    },
  );

  test('opaque TEXT identities use exact binary comparison', () async {
    await source(db, 's');
    final ids = [
      '00042',
      '42',
      'wk8-123',
      '书😀',
      ' x ',
      'x',
      'X',
      'é',
      'e\u0301',
      '#/.-%2F',
    ];
    for (final id in ids) {
      await book(db, 's', id);
    }
    final rows = await db
        .customSelect(
          'SELECT book_id, typeof(book_id) AS t FROM library_entries',
        )
        .get();
    expect(rows.map((r) => r.read<String>('book_id')), unorderedEquals(ids));
    expect(rows.every((r) => r.read<String>('t') == 'text'), isTrue);
  });

  test('same chapter ID in two books does not collide', () async {
    await source(db, 's');
    for (final id in ['b1', 'b2']) {
      await book(db, 's', id);
      await db.customStatement(
        'INSERT INTO reading_progress(source_id,book_id,has_read,chapter_id) VALUES (?,?,1,?)',
        ['s', id, '0007'],
      );
    }
    expect(await count(db, 'reading_progress'), 2);
  });

  test(
    'multi-write transaction commits and injected failure rolls back',
    () async {
      await db.transaction(() async {
        await source(db, 'kept');
        await book(db, 'kept', 'b');
      });
      await expectLater(
        db.transaction(() async {
          await source(db, 'rolled-back');
          await book(db, 'rolled-back', 'b');
          throw StateError('injected');
        }),
        throwsStateError,
      );
      expect(await count(db, 'source_registrations'), 1);
      expect(await count(db, 'library_entries'), 1);
    },
  );

  test(
    'invalid references fail and membership removal preserves other data',
    () async {
      await expectLater(
        book(db, 'missing', 'b'),
        throwsA(isA<sqlite.SqliteException>()),
      );
      await source(db, 's');
      await book(db, 's', 'b');
      await db.customStatement(
        "INSERT INTO shelves VALUES ('shelf','Shelf',0)",
      );
      await db.customStatement(
        "INSERT INTO manual_groups VALUES ('group','Group')",
      );
      await db.customStatement(
        "INSERT INTO group_members VALUES ('group','s','b')",
      );
      await db.customStatement(
        "INSERT INTO split_overrides VALUES ('s','b',1)",
      );
      await db.customStatement(
        "INSERT INTO shelf_members VALUES ('shelf','s','b',0)",
      );
      await db.customStatement(
        "INSERT INTO reading_progress(source_id,book_id,has_read) VALUES ('s','b',1)",
      );
      for (final table in [
        'source_registrations',
        'library_entries',
        'shelves',
        'manual_groups',
      ]) {
        await expectLater(
          db.customStatement('DELETE FROM $table'),
          throwsA(isA<sqlite.SqliteException>()),
        );
      }
      await db.customStatement('DELETE FROM shelf_members');
      for (final table in [
        'library_entries',
        'reading_progress',
        'group_members',
        'split_overrides',
      ]) {
        expect(await count(db, table), 1);
      }
      await db.customStatement('DELETE FROM group_members');
      expect(await count(db, 'split_overrides'), 1);
      expect(await count(db, 'reading_progress'), 1);
    },
  );

  test('every declared foreign key uses RESTRICT delete/update', () async {
    final tables = await db
        .customSelect("SELECT name FROM sqlite_schema WHERE type='table'")
        .get();
    var checked = 0;
    for (final table in tables) {
      final keys = await db
          .customSelect(
            "PRAGMA foreign_key_list('${table.read<String>('name')}')",
          )
          .get();
      for (final key in keys) {
        checked++;
        expect(key.read<String>('on_delete'), 'RESTRICT');
        expect(key.read<String>('on_update'), 'RESTRICT');
      }
    }
    expect(checked, greaterThan(25));
  });

  test(
    'separate legacy fractions and progress locator enforce owning book',
    () async {
      await source(db, 's');
      await book(db, 's', 'a');
      await book(db, 's', 'b');
      await db.customStatement(
        "INSERT INTO migration_datasets VALUES ('dataset')",
      );
      for (var i = 0; i < 2; i++) {
        await db.customStatement(
          'INSERT INTO legacy_chapter_locators(locator_id,dataset_id,source_id,book_id,legacy_book_id,chapter_index,fraction) VALUES (?,?,?,?,?,?,?)',
          ['locator-$i', 'dataset', 's', 'a', 'wk8-123', i, i.toDouble()],
        );
      }
      await db.customStatement(
        "INSERT INTO reading_progress(source_id,book_id,has_read,legacy_locator_id) VALUES ('s','a',1,'locator-0')",
      );
      await expectLater(
        db.customStatement(
          "INSERT INTO reading_progress(source_id,book_id,has_read,legacy_locator_id) VALUES ('s','b',1,'locator-0')",
        ),
        throwsA(isA<sqlite.SqliteException>()),
      );
      await expectLater(
        db.customStatement(
          "DELETE FROM legacy_chapter_locators WHERE locator_id='locator-0'",
        ),
        throwsA(isA<sqlite.SqliteException>()),
      );
      expect(await count(db, 'legacy_chapter_locators'), 2);
    },
  );

  test(
    'settings cover all ten Reader fields with constrained defaults',
    () async {
      await db.customStatement(
        'INSERT INTO reader_preferences(singleton) VALUES (1)',
      );
      final row =
          (await db
                  .customSelect('SELECT * FROM reader_preferences')
                  .getSingle())
              .data;
      expect(row, {
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
      for (final sql in [
        "UPDATE reader_preferences SET bold=2",
        "UPDATE reader_preferences SET mode='unknown'",
        'UPDATE reader_preferences SET font_size=0',
        'UPDATE reader_preferences SET line_spacing=-1',
        'UPDATE reader_preferences SET margin_top=-1',
        "INSERT INTO app_preferences(singleton,theme) VALUES (1,'unknown')",
      ]) {
        await expectLater(
          db.customStatement(sql),
          throwsA(isA<sqlite.SqliteException>()),
        );
      }
      await expectLater(
        db.customStatement('UPDATE reader_preferences SET font_size=?', [
          double.infinity,
        ]),
        throwsA(isA<sqlite.SqliteException>()),
      );
    },
  );

  test('UTC timestamp contract preserves deterministic serialized value', () async {
    await source(db, 's');
    await book(db, 's', 'b');
    final instant = DateTime.utc(2026, 9, 16, 1, 2, 3, 4, 5).toIso8601String();
    await db.customStatement(
      'INSERT INTO reading_progress(source_id,book_id,has_read,last_read_at) VALUES (?,?,?,?)',
      ['s', 'b', 1, instant],
    );
    expect(
      (await db
              .customSelect('SELECT last_read_at FROM reading_progress')
              .getSingle())
          .read<String>('last_read_at'),
      instant,
    );
    await expectLater(
      db.customStatement(
        "UPDATE reading_progress SET last_read_at='2026-09-16T09:02:03+08:00'",
      ),
      throwsA(isA<sqlite.SqliteException>()),
    );
  });

  test('migration run/receipt/outcome and safe values preserve distinct alternatives', () async {
    await db.customStatement("INSERT INTO migration_datasets VALUES ('d')");
    final digest = 'a' * 64;
    await db.customStatement(
      'INSERT INTO migration_runs(dataset_id,importer_version,input_digest,mapping_version,state) VALUES (?,?,?,?,?)',
      ['d', 1, digest, 1, 'pending'],
    );
    await db.customStatement(
      "INSERT INTO record_receipts VALUES ('d',1,'book','wk8-1')",
    );
    await db.customStatement(
      'INSERT INTO record_outcomes(dataset_id,importer_version,input_digest,entity_kind,legacy_key,outcome) VALUES (?,?,?,?,?,?)',
      ['d', 1, digest, 'book', 'wk8-1', 'conflict'],
    );
    for (final candidate in ['old', 'new']) {
      await db.customStatement(
        'INSERT INTO safe_legacy_values(dataset_id,importer_version,entity_kind,legacy_key,candidate_id,field,value_type,text_value) VALUES (?,?,?,?,?,?,?,?)',
        ['d', 1, 'book', 'wk8-1', candidate, 'book.title', 'string', candidate],
      );
    }
    expect(await count(db, 'safe_legacy_values'), 2);
    for (final table in [
      'migration_datasets',
      'migration_runs',
      'record_receipts',
    ]) {
      await expectLater(
        db.customStatement('DELETE FROM $table'),
        throwsA(isA<sqlite.SqliteException>()),
      );
    }
  });

  test('safe values distinguish accepted baselines from evidence and conflicts', () async {
    await db.customStatement("INSERT INTO migration_datasets VALUES ('d')");
    for (final key in ['source-a/book-1', 'source-b/book-1']) {
      await db.customStatement('INSERT INTO record_receipts VALUES (?,?,?,?)', [
        'd',
        1,
        'book',
        key,
      ]);
    }

    Future<void> insertValue({
      required String key,
      required String candidate,
      required String purpose,
      required String field,
      required String type,
      String? text,
      int? integer,
      double? number,
      int? boolean,
    }) => db.customStatement(
      'INSERT INTO safe_legacy_values(dataset_id,importer_version,entity_kind,legacy_key,candidate_id,purpose,field,value_type,text_value,integer_value,number_value,boolean_value) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)',
      [
        'd',
        1,
        'book',
        key,
        candidate,
        purpose,
        field,
        type,
        text,
        integer,
        number,
        boolean,
      ],
    );

    await insertValue(
      key: 'source-a/book-1',
      candidate: 'baseline',
      purpose: 'accepted-baseline',
      field: 'book.title',
      type: 'string',
      text: 'A',
    );
    await insertValue(
      key: 'source-a/book-1',
      candidate: 'baseline',
      purpose: 'accepted-baseline',
      field: 'book.totalChapters',
      type: 'integer',
      integer: 42,
    );
    await insertValue(
      key: 'source-a/book-1',
      candidate: 'baseline',
      purpose: 'accepted-baseline',
      field: 'progress.offset',
      type: 'number',
      number: .5,
    );
    await insertValue(
      key: 'source-a/book-1',
      candidate: 'baseline',
      purpose: 'accepted-baseline',
      field: 'book.saved',
      type: 'boolean',
      boolean: 1,
    );
    await insertValue(
      key: 'source-a/book-1',
      candidate: 'baseline',
      purpose: 'accepted-baseline',
      field: 'book.intro',
      type: 'null',
    );

    // The same candidate/field tuple is legal for each explicit semantic role.
    await insertValue(
      key: 'source-a/book-1',
      candidate: 'baseline',
      purpose: 'unresolved-evidence',
      field: 'book.title',
      type: 'string',
      text: 'observed',
    );
    await insertValue(
      key: 'source-a/book-1',
      candidate: 'baseline',
      purpose: 'conflict-candidate',
      field: 'book.title',
      type: 'string',
      text: 'C',
    );
    await insertValue(
      key: 'source-a/book-1',
      candidate: 'alternate',
      purpose: 'conflict-candidate',
      field: 'book.title',
      type: 'string',
      text: 'D',
    );
    await insertValue(
      key: 'source-b/book-1',
      candidate: 'baseline',
      purpose: 'accepted-baseline',
      field: 'book.title',
      type: 'string',
      text: 'Other source',
    );

    final accepted = await db
        .customSelect(
          "SELECT legacy_key, field, value_type, text_value FROM safe_legacy_values WHERE purpose='accepted-baseline' ORDER BY legacy_key, field",
        )
        .get();
    expect(accepted, hasLength(6));
    expect(
      accepted.map((row) => row.read<String>('legacy_key')),
      containsAllInOrder([
        'source-a/book-1',
        'source-a/book-1',
        'source-a/book-1',
        'source-a/book-1',
        'source-a/book-1',
        'source-b/book-1',
      ]),
    );
    expect(
      accepted.map((row) => row.read<String>('value_type')),
      containsAll(<String>['string', 'integer', 'number', 'boolean', 'null']),
    );
    expect(
      (await db
              .customSelect(
                "SELECT text_value FROM safe_legacy_values WHERE legacy_key='source-a/book-1' AND purpose='accepted-baseline' AND field='book.title'",
              )
              .getSingle())
          .read<String>('text_value'),
      'A',
    );

    await source(db, 'source-a');
    await db.customStatement(
      "INSERT INTO library_entries(source_id,book_id,metadata_state,title) VALUES ('source-a','book-1','known','B')",
    );
    expect(
      (await db
              .customSelect(
                "SELECT text_value FROM safe_legacy_values WHERE legacy_key='source-a/book-1' AND purpose='accepted-baseline' AND field='book.title'",
              )
              .getSingle())
          .read<String>('text_value'),
      'A',
    );

    await expectLater(
      insertValue(
        key: 'source-a/book-1',
        candidate: 'unknown',
        purpose: 'accepted-baseline',
        field: 'unknown.field',
        type: 'string',
        text: 'ignored',
      ),
      throwsA(isA<sqlite.SqliteException>()),
    );
    await expectLater(
      insertValue(
        key: 'source-a/book-1',
        candidate: 'secret',
        purpose: 'accepted-baseline',
        field: 'password',
        type: 'string',
        text: 'SYNTHETIC_SECRET_DO_NOT_STORE',
      ),
      throwsA(isA<sqlite.SqliteException>()),
    );
  });

  test('no secret fields or raw payload authority; rejected sentinel stays out of DB/logs', () async {
    await db.customStatement("INSERT INTO migration_datasets VALUES ('d')");
    await db.customStatement(
      "INSERT INTO record_receipts VALUES ('d',1,'book','b')",
    );
    const sentinel = 'SYNTHETIC_SECRET_DO_NOT_STORE';
    for (final field in [
      'wenku8Cookie',
      'password',
      'raw_json',
      'accessToken',
    ]) {
      await expectLater(
        db.customStatement(
          'INSERT INTO safe_legacy_values(dataset_id,importer_version,entity_kind,legacy_key,candidate_id,field,value_type,text_value) VALUES (?,?,?,?,?,?,?,?)',
          ['d', 1, 'book', 'b', 'c', field, 'string', sentinel],
        ),
        throwsA(isA<sqlite.SqliteException>()),
      );
    }
    expect(await count(db, 'safe_legacy_values'), 0);
    final schemas = await db
        .customSelect("SELECT sql FROM sqlite_schema WHERE type='table'")
        .get();
    for (final schema in schemas) {
      expect(
        schema.read<String>('sql'),
        isNot(
          matches(
            RegExp(
              r'cookie|password|access_token|raw_json',
              caseSensitive: false,
            ),
          ),
        ),
      );
    }
    final logs = <String>[];
    AppErrorReporter(AppLogger(write: logs.add))
        .report(StateError(sentinel), event: 'storage.test');
    expect(logs.single, isNot(contains(sentinel)));
  });

  group('isolated files', () {
    late Directory root;
    setUp(() async {
      root = await Directory.systemTemp.createTemp('lnr-f2-db-');
    });
    tearDown(() async {
      await root.delete(recursive: true);
    });

    test('production background boundary closes/reopens exact data in injected root', () async {
      final opened = await openAppDatabase(storageRoot: () async => root);
      try {
        await source(opened, 's😀');
        await book(opened, 's😀', ' 00042/wk8-1 ');
      } finally {
        await opened.close();
      }
      final reopened = await openAppDatabase(storageRoot: () async => root);
      try {
        expect(
          (await reopened
                  .customSelect('SELECT book_id FROM library_entries')
                  .getSingle())
              .read<String>('book_id'),
          ' 00042/wk8-1 ',
        );
      } finally {
        await reopened.close();
      }
    });

    test(
      'synthetic pre-v1 runner upgrades transactionally and verifies snapshot',
      () async {
        final file = File.fromUri(root.uri.resolve('synthetic.sqlite'));
        final raw = sqlite.sqlite3.open(file.path);
        raw.execute('CREATE TABLE synthetic_pre_v1_sources(id TEXT NOT NULL)');
        raw.execute("INSERT INTO synthetic_pre_v1_sources VALUES (' 0001😀 ')");
        raw.close();
        final upgraded = SyntheticPreV1Database(NativeDatabase(file));
        try {
          await SchemaVerifier(GeneratedHelper())
              .migrateAndValidate(upgraded, 1);
          expect(
            (await upgraded
                    .customSelect('SELECT source_id FROM source_registrations')
                    .getSingle())
                .read<String>('source_id'),
            ' 0001😀 ',
          );
        } finally {
          await upgraded.close();
        }
      },
    );

    test(
      'injected migration failure restores old schema/data and retry succeeds',
      () async {
        final file = File.fromUri(root.uri.resolve('interrupted.sqlite'));
        final raw = sqlite.sqlite3.open(file.path);
        raw.execute('CREATE TABLE synthetic_pre_v1_sources(id TEXT NOT NULL)');
        raw.execute("INSERT INTO synthetic_pre_v1_sources VALUES ('kept')");
        raw.close();
        final failed = SyntheticPreV1Database(NativeDatabase(file), fail: true);
        try {
          await expectLater(
            failed.customSelect('SELECT 1').get(),
            throwsStateError,
          );
        } finally {
          await failed.close();
        }
        final check = sqlite.sqlite3.open(file.path);
        expect(check.userVersion, 0);
        expect(
          check.select('SELECT id FROM synthetic_pre_v1_sources').single['id'],
          'kept',
        );
        expect(
          check.select(
            "SELECT name FROM sqlite_schema WHERE name='library_entries'",
          ),
          isEmpty,
        );
        check.close();
        final retry = SyntheticPreV1Database(NativeDatabase(file));
        try {
          expect(await count(retry, 'source_registrations'), 1);
        } finally {
          await retry.close();
        }
      },
    );

    test(
      'future version rejected without altering file bytes or contents',
      () async {
        final file = File.fromUri(root.uri.resolve(databaseFilename));
        final raw = sqlite.sqlite3.open(file.path);
        raw.execute('CREATE TABLE future_data(value TEXT)');
        raw.execute("INSERT INTO future_data VALUES ('keep-me')");
        raw.userVersion = 2;
        raw.close();
        final before = await file.readAsBytes();
        await expectLater(
          openAppDatabase(storageRoot: () async => root),
          throwsA(isA<PersistenceFailure>()),
        );
        expect(await file.readAsBytes(), before);
        final check = sqlite.sqlite3.open(
          file.path,
          mode: sqlite.OpenMode.readOnly,
        );
        expect(check.userVersion, 2);
        expect(
          check.select('SELECT value FROM future_data').single['value'],
          'keep-me',
        );
        check.close();
      },
    );

    test('unversioned nonempty file is refused instead of reset', () async {
      final file = File.fromUri(root.uri.resolve(databaseFilename));
      final raw = sqlite.sqlite3.open(file.path);
      raw.execute('CREATE TABLE unknown_data(value TEXT)');
      raw.close();
      final before = await file.readAsBytes();
      await expectLater(
        openAppDatabase(storageRoot: () async => root),
        throwsA(isA<PersistenceFailure>()),
      );
      expect(await file.readAsBytes(), before);
    });

    test(
      'file in place of storage directory surfaces error with no RAM fallback',
      () async {
        final file = File.fromUri(root.uri.resolve('not-directory'));
        await file.writeAsString('synthetic sentinel');
        await expectLater(
          openAppDatabase(storageRoot: () async => Directory(file.path)),
          throwsA(isA<PersistenceFailure>()),
        );
        expect(await file.readAsString(), 'synthetic sentinel');
        expect(await root.list().length, 1);
      },
    );
  });
}
