import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_reader/src/data/persistence/database.dart'
    show AppDatabase;
import 'package:light_novel_reader/src/data/persistence/repositories/drift_library_repository.dart';
import 'package:light_novel_reader/src/data/persistence/repositories/drift_preferences_repository.dart';
import 'package:light_novel_reader/src/data/persistence/repositories/drift_progress_repository.dart';
import 'package:light_novel_reader/src/data/persistence/repositories/drift_shelf_repository.dart';
import 'package:light_novel_reader/src/domain/identity/identity_failure.dart';
import 'package:light_novel_reader/src/domain/identity/opaque_ids.dart';
import 'package:light_novel_reader/src/domain/identity/source_refs.dart';
import 'package:light_novel_reader/src/domain/legacy/legacy_chapter_locator.dart';
import 'package:light_novel_reader/src/domain/legacy/legacy_source_mapping.dart';
import 'package:light_novel_reader/src/domain/library/library_models.dart';
import 'package:light_novel_reader/src/domain/library/repository_failure.dart';
import 'package:light_novel_reader/src/domain/preferences/preferences.dart';
import 'package:light_novel_reader/src/domain/progress/reading_progress.dart';

SourceBookRef book(String source, [String id = ' 00042/#.文😀 ']) =>
    SourceBookRef(sourceId: SourceId(source), bookId: BookId(id));

Matcher repositoryFailure(RepositoryFailureReason reason) => throwsA(
  isA<RepositoryFailure>().having((e) => e.reason, 'reason', reason),
);

void main() {
  late AppDatabase db;
  late DriftLibraryRepository library;
  late DriftProgressRepository progress;
  late DriftPreferencesRepository preferences;
  late DriftShelfRepository shelves;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    library = DriftLibraryRepository(db);
    progress = DriftProgressRepository(db);
    preferences = DriftPreferencesRepository(db);
    shelves = DriftShelfRepository(db);
    for (final source in ['a', 'b']) {
      await db.customStatement(
        "INSERT INTO source_registrations(source_id,availability) "
        "VALUES (?,'unresolved')",
        [source],
      );
    }
  });

  tearDown(() => db.close());

  Future<void> addBooks(Iterable<SourceBookRef> books) async {
    for (final ref in books) {
      await library.ensureStub(ref);
    }
  }

  Future<void> addDataset([String id = 'legacy.dataset']) => db.customStatement(
    'INSERT INTO migration_datasets(dataset_id) VALUES (?)',
    [id],
  );

  LegacyChapterLocatorV1 locator(
    SourceBookRef ref, {
    String dataset = 'legacy.dataset',
    String legacyBook = 'wk8-00042',
    int index = 0,
    double? fraction,
  }) => LegacyChapterLocatorV1(
    datasetId: LegacyDatasetId(dataset),
    bookRef: ref,
    legacyBookId: BookId(legacyBook),
    chapterIndex: index,
    rawOffsetKey: ' 00042/#.$index/文😀 ',
    fraction: fraction,
    remoteIdEvidence: 'remote/$index',
    chapterTitleEvidence: '标题 $index',
    volumeTitleEvidence: '卷 / $index',
    catalogDigest: 'digest-$index',
  );

  test('ReadingProgressV1 preserves all fields and strict v1 JSON', () {
    final ref = book('a');
    final chapter = SourceChapterRef(
      sourceId: ref.sourceId,
      bookId: ref.bookId,
      chapterId: ChapterId('001/#/文😀'),
    );
    final value = ReadingProgressV1(
      bookRef: ref,
      hasRead: true,
      chapterRef: chapter,
      legacyLocator: locator(ref, fraction: 1),
      lastReadAt: DateTime.utc(2026, 9, 17, 1, 2, 3),
    );
    expect(ReadingProgressV1.fromJson(value.toJson()), value);
    expect(value.toJson()['lastReadAt'], '2026-09-17T01:02:03.000Z');

    final unknown = value.toJson()..['extra'] = true;
    expect(
      () => ReadingProgressV1.fromJson(unknown),
      throwsA(isA<IdentityFailure>()),
    );
    final malformed = value.toJson()..['lastReadAt'] = '2026-09-17T01:02:03Z';
    expect(
      () => ReadingProgressV1.fromJson(malformed),
      throwsA(isA<IdentityFailure>()),
    );
  });

  test('progress accepts hasRead-only and timestamp-only records', () {
    final ref = book('a');
    final hasReadOnly = ReadingProgressV1(bookRef: ref, hasRead: true);
    expect(ReadingProgressV1.fromJson(hasReadOnly.toJson()), hasReadOnly);
    final timestampOnly = ReadingProgressV1(
      bookRef: ref,
      hasRead: false,
      lastReadAt: DateTime.utc(2026, 1, 2),
    );
    expect(ReadingProgressV1.fromJson(timestampOnly.toJson()), timestampOnly);
  });

  test('progress rejects locator ownership and unsupported primitive values', () {
    final a = book('a');
    final other = book('b');
    final chapter = SourceChapterRef(
      sourceId: other.sourceId,
      bookId: other.bookId,
      chapterId: ChapterId('chapter'),
    );
    expect(
      () => ReadingProgressV1(bookRef: a, hasRead: true, chapterRef: chapter),
      throwsA(isA<IdentityFailure>()),
    );
    expect(
      () => ReadingProgressV1(
        bookRef: a,
        hasRead: true,
        legacyLocator: locator(other),
      ),
      throwsA(isA<IdentityFailure>()),
    );
    expect(
      () => LegacyChapterLocatorV1(
        datasetId: LegacyDatasetId('dataset'),
        bookRef: a,
        legacyBookId: BookId('legacy'),
        chapterIndex: 0,
        fraction: 1.1,
      ),
      throwsA(isA<IdentityFailure>()),
    );
  });

  test('timestamp normalization is UTC and missing timestamp stays absent', () {
    final local = DateTime(2026, 9, 17, 9, 2, 3);
    final value = ReadingProgressV1(bookRef: book('a'), hasRead: true, lastReadAt: local);
    expect(value.lastReadAt, local.toUtc());
    expect(value.toJson()['lastReadAt'], encodeCanonicalUtc(local.toUtc()));
    expect(ReadingProgressV1(bookRef: book('a'), hasRead: true).toJson(), {
      'kind': 'readingProgress',
      'version': 1,
      'bookRef': book('a').toJson(),
      'hasRead': true,
    });
  });

  test('reader defaults and every preferences codec token are stable', () {
    final defaults = ReaderPreferencesV1.defaults();
    expect(defaults.fontSize, 22);
    expect(defaults.lineSpacing, 8);
    expect(defaults.background, ReaderBackground.paperWhite);
    expect(defaults.mode, ReaderMode.pageCurl);
    expect(defaults.fontFamily, ReaderFontFamily.kaiti);
    expect(defaults.bold, isFalse);
    expect(defaults.marginLeft, 35);
    expect(defaults.marginRight, 35);
    expect(defaults.marginTop, 72);
    expect(defaults.marginBottom, 24);
    expect(ReaderPreferencesV1.fromJson(defaults.toJson()), defaults);

    final custom = ReaderPreferencesV1(
      fontSize: 18.5,
      lineSpacing: 0,
      background: ReaderBackground.eyeCare,
      mode: ReaderMode.scroll,
      fontFamily: ReaderFontFamily.yuanti,
      bold: true,
      marginLeft: 0,
      marginRight: 1.5,
      marginTop: 2,
      marginBottom: 3,
    );
    expect(ReaderPreferencesV1.fromJson(custom.toJson()), custom);
    final unknown = custom.toJson()..['extra'] = 1;
    expect(
      () => ReaderPreferencesV1.fromJson(unknown),
      throwsA(isA<IdentityFailure>()),
    );
    expect(
      () => ReaderPreferencesV1.fromJson({...custom.toJson()}..remove('bold')),
      throwsA(isA<IdentityFailure>()),
    );
    expect(
      () => ReaderPreferencesV1(fontSize: double.nan, lineSpacing: 0,
        background: ReaderBackground.paperWhite, mode: ReaderMode.scroll,
        fontFamily: ReaderFontFamily.system, bold: false, marginLeft: 0,
        marginRight: 0, marginTop: 0, marginBottom: 0),
      throwsA(isA<IdentityFailure>()),
    );
  });

  test('app preference tokens, opaque refs and nullable absence round-trip', () {
    final value = AppPreferencesV1(
      theme: AppTheme.dark,
      preferredSourceId: SourceId('source/文😀'),
      selectedShelfId: ShelfId(' shelf/#/文 '),
      accent: AppAccent.orange,
    );
    expect(AppPreferencesV1.fromJson(value.toJson()), value);
    final absent = const AppPreferencesV1(theme: AppTheme.system);
    expect(AppPreferencesV1.fromJson(absent.toJson()), absent);
    final unknown = absent.toJson()..['accent'] = 'unknown';
    expect(
      () => AppPreferencesV1.fromJson(unknown),
      throwsA(isA<IdentityFailure>()),
    );
    expect(
      () => AppPreferencesV1.fromJson(
        absent.toJson()..['preferredSourceId'] = 42,
      ),
      throwsA(isA<IdentityFailure>()),
    );
  });

  test('progress requires an existing LibraryEntry and never creates one', () async {
    final missing = book('a');
    await expectLater(
      progress.save(ReadingProgressV1(bookRef: missing, hasRead: true)),
      repositoryFailure(RepositoryFailureReason.invalidReference),
    );
    expect(await library.get(missing), isNull);
    expect(await progress.list(), isEmpty);
  });

  test('progress round-trips opaque Unicode refs and source-aware ordering', () async {
    final a = book('a', ' 00002/#/文 ');
    final b = book('a', ' 00001/#/文 ');
    final sameBookOtherSource = book('b', b.bookId.value);
    await addBooks([a, b, sameBookOtherSource]);
    await progress.save(ReadingProgressV1(bookRef: sameBookOtherSource, hasRead: true));
    await progress.save(ReadingProgressV1(bookRef: a, hasRead: false));
    await progress.save(ReadingProgressV1(bookRef: b, hasRead: true));
    expect((await progress.list()).map((item) => item.bookRef), [b, a, sameBookOtherSource]);
    expect((await DriftProgressRepository(db).get(a))!.bookRef, a);
  });

  test('legacy locator requires an existing dataset and preserves all evidence', () async {
    final ref = book('a');
    await addBooks([ref]);
    final missing = locator(ref, dataset: 'missing');
    await expectLater(
      progress.save(ReadingProgressV1(bookRef: ref, hasRead: true, legacyLocator: missing)),
      repositoryFailure(RepositoryFailureReason.invalidReference),
    );
    expect(await progress.get(ref), isNull);

    await addDataset();
    final stored = locator(ref, fraction: 0);
    await progress.save(ReadingProgressV1(bookRef: ref, hasRead: true, legacyLocator: stored));
    expect((await progress.get(ref))!.legacyLocator, stored);
    final row = await db.customSelect('SELECT * FROM legacy_chapter_locators').get();
    expect(row, hasLength(1));
    expect(row.single.read<String>('legacy_book_id'), 'wk8-00042');
    expect(row.single.read<double>('fraction'), 0);
  });

  test('modern and legacy locators remain independent; old locators are retained', () async {
    final ref = book('a');
    await addBooks([ref]);
    await addDataset();
    final first = locator(ref, index: 1, fraction: 0.25);
    final second = locator(ref, index: 2, fraction: 0.75);
    final modern = SourceChapterRef(
      sourceId: ref.sourceId,
      bookId: ref.bookId,
      chapterId: ChapterId('opaque-chapter'),
    );
    await progress.save(ReadingProgressV1(
      bookRef: ref,
      hasRead: true,
      chapterRef: modern,
      legacyLocator: first,
    ));
    await progress.save(ReadingProgressV1(
      bookRef: ref,
      hasRead: false,
      chapterRef: modern,
      legacyLocator: second,
    ));
    final current = (await progress.get(ref))!;
    expect(current.chapterRef, modern);
    expect(current.legacyLocator, second);
    expect(await db.customSelect('SELECT locator_id FROM legacy_chapter_locators').get(), hasLength(2));
    expect(second, isNot(first));
  });

  test('identical locator saves are idempotent and locator id is internal', () async {
    final ref = book('a');
    await addBooks([ref]);
    await addDataset();
    final value = locator(ref, index: 7, fraction: 1);
    await progress.save(ReadingProgressV1(bookRef: ref, hasRead: true, legacyLocator: value));
    await progress.save(ReadingProgressV1(bookRef: ref, hasRead: true, legacyLocator: value));
    expect(await db.customSelect('SELECT locator_id FROM legacy_chapter_locators').get(), hasLength(1));
    expect(ReadingProgressV1(bookRef: ref, hasRead: true, legacyLocator: value).toJson().containsKey('locator_id'), isFalse);
  });

  test('locator insertion failure rolls back the whole progress transaction', () async {
    final ref = book('a');
    await addBooks([ref]);
    await addDataset();
    await db.customStatement(
      "CREATE TEMP TRIGGER fail_locator BEFORE INSERT ON legacy_chapter_locators "
      "WHEN NEW.legacy_book_id='fail' BEGIN SELECT RAISE(ABORT, 'synthetic'); END",
    );
    await expectLater(
      progress.save(ReadingProgressV1(
        bookRef: ref,
        hasRead: true,
        legacyLocator: locator(ref, legacyBook: 'fail'),
      )),
      repositoryFailure(RepositoryFailureReason.storage),
    );
    expect(await progress.get(ref), isNull);
    expect(await db.customSelect('SELECT * FROM legacy_chapter_locators').get(), isEmpty);
  });

  test('progress insertion failure rolls back a newly inserted locator', () async {
    final ref = book('a', 'bad');
    await addBooks([ref]);
    await addDataset();
    await db.customStatement(
      "CREATE TEMP TRIGGER fail_progress BEFORE INSERT ON reading_progress "
      "WHEN NEW.book_id='bad' BEGIN SELECT RAISE(ABORT, 'synthetic'); END",
    );
    await expectLater(
      progress.save(ReadingProgressV1(bookRef: ref, hasRead: true, legacyLocator: locator(ref))),
      repositoryFailure(RepositoryFailureReason.storage),
    );
    expect(await progress.get(ref), isNull);
    expect(await db.customSelect('SELECT * FROM legacy_chapter_locators').get(), isEmpty);
  });

  test('progress replacement preserves unrelated library and group state', () async {
    final ref = book('a');
    await addBooks([ref]);
    final shelf = Shelf(id: ShelfId('shelf'), name: 'Shelf', ordinal: 0);
    await shelves.createShelf(shelf);
    await shelves.addMember(shelf.id, ref);
    await progress.save(ReadingProgressV1(bookRef: ref, hasRead: true));
    await progress.save(ReadingProgressV1(bookRef: ref, hasRead: false));
    expect((await library.get(ref))!.saved, isFalse);
    expect(await shelves.listMembers(shelf.id), hasLength(1));
    expect((await progress.get(ref))!.hasRead, isFalse);
    final second = DriftProgressRepository(db);
    expect((await second.get(ref))!.hasRead, isFalse);
  });

  test('preference reads return null without persisting defaults', () async {
    expect(await preferences.getReaderPreferences(), isNull);
    expect(await preferences.getAppPreferences(), isNull);
    expect(await db.customSelect('SELECT * FROM reader_preferences').get(), isEmpty);
    expect(await db.customSelect('SELECT * FROM app_preferences').get(), isEmpty);
  });

  test('reader preferences replace complete state and survive another repository', () async {
    final value = ReaderPreferencesV1(
      fontSize: 19,
      lineSpacing: 4,
      background: ReaderBackground.parchment,
      mode: ReaderMode.scroll,
      fontFamily: ReaderFontFamily.songti,
      bold: true,
      marginLeft: 1,
      marginRight: 2,
      marginTop: 3,
      marginBottom: 4,
    );
    await preferences.saveReaderPreferences(value);
    expect(await DriftPreferencesRepository(db).getReaderPreferences(), value);
    await preferences.saveReaderPreferences(ReaderPreferencesV1.defaults());
    expect(await preferences.getReaderPreferences(), ReaderPreferencesV1.defaults());
  });

  test('app preference FKs are existing-only and null values explicitly clear', () async {
    await expectLater(
      preferences.saveAppPreferences(AppPreferencesV1(
        theme: AppTheme.light,
        preferredSourceId: SourceId('missing'),
      )),
      repositoryFailure(RepositoryFailureReason.invalidReference),
    );
    expect(await preferences.getAppPreferences(), isNull);

    final shelf = Shelf(id: ShelfId('selected'), name: 'Selected', ordinal: 0);
    await shelves.createShelf(shelf);
    final value = AppPreferencesV1(
      theme: AppTheme.dark,
      preferredSourceId: SourceId('a'),
      selectedShelfId: shelf.id,
      accent: AppAccent.red,
    );
    await preferences.saveAppPreferences(value);
    expect(await preferences.getAppPreferences(), value);
    const cleared = AppPreferencesV1(theme: AppTheme.system);
    await preferences.saveAppPreferences(cleared);
    expect(await preferences.getAppPreferences(), cleared);
  });

  test('preference write SQL failures become safe typed storage failures', () async {
    await db.customStatement(
      "CREATE TEMP TRIGGER fail_reader BEFORE INSERT ON reader_preferences "
      "BEGIN SELECT RAISE(ABORT, 'synthetic'); END",
    );
    await expectLater(
      preferences.saveReaderPreferences(ReaderPreferencesV1.defaults()),
      repositoryFailure(RepositoryFailureReason.storage),
    );
    expect(await preferences.getReaderPreferences(), isNull);
  });
}
