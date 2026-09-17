import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_reader/src/data/persistence/database.dart'
    show AppDatabase;
import 'package:light_novel_reader/src/data/persistence/repositories/drift_library_repository.dart';
import 'package:light_novel_reader/src/data/persistence/repositories/drift_shelf_repository.dart';
import 'package:light_novel_reader/src/data/persistence/repositories/drift_manual_group_repository.dart';
import 'package:light_novel_reader/src/domain/identity/identity_failure.dart';
import 'package:light_novel_reader/src/domain/identity/opaque_ids.dart';
import 'package:light_novel_reader/src/domain/identity/source_refs.dart';
import 'package:light_novel_reader/src/domain/library/library_models.dart';
import 'package:light_novel_reader/src/domain/library/repositories.dart';
import 'package:light_novel_reader/src/domain/library/repository_failure.dart';

SourceBookRef ref(String source, [String book = ' 00042/#.文😀 ']) =>
    SourceBookRef(sourceId: SourceId(source), bookId: BookId(book));
Matcher failure(RepositoryFailureReason reason) =>
    throwsA(isA<RepositoryFailure>().having((e) => e.reason, 'reason', reason));

void main() {
  late AppDatabase db;
  late LibraryRepository library;
  late ShelfRepository shelves;
  late ManualGroupRepository groups;
  final a = ref('a');
  final b = ref('b');
  final sid = ShelfId(' shelf/文 ');
  final other = ShelfId('other');
  final gid = ManualGroupId(' group/文 ');

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    library = DriftLibraryRepository(db);
    shelves = DriftShelfRepository(db);
    groups = DriftManualGroupRepository(db);
    for (final source in ['a', 'b']) {
      await db.customStatement(
        "INSERT INTO source_registrations(source_id,availability) VALUES (?,'unresolved')",
        [source],
      );
    }
  });
  tearDown(() => db.close());

  Future<void> books() async {
    await library.ensureStub(a);
    await library.ensureStub(b);
  }

  Future<void> shelfFixture() async {
    await books();
    await shelves.createShelf(Shelf(id: sid, name: 'Shelf', ordinal: 0));
    await shelves.replaceMembers(sid, [a, b]);
  }

  Future<void> groupFixture() async {
    await books();
    await groups.createGroup(ManualGroup(id: gid, displayName: 'Group'));
    await groups.replaceMembers(gid, [b, a]);
  }

  Future<List<SourceBookRef>> shelfRefs() async =>
      (await shelves.listMembers(sid)).map((m) => m.bookRef).toList();
  Future<List<SourceBookRef>> groupRefs() async =>
      (await groups.listMembers(gid)).map((m) => m.bookRef).toList();
  Future<void> reject(
    String table,
    String operation,
    String condition,
  ) => db.customStatement(
    "CREATE TEMP TRIGGER injected BEFORE $operation ON $table WHEN $condition BEGIN SELECT RAISE(ABORT, 'synthetic private detail'); END",
  );

  test('local IDs preserve exact values, equality, namespaces and reject malformed input', () {
    const value = ' 0001/文😀 ';
    expect(ShelfId(value).value, value);
    expect(ShelfId(value), ShelfId(value));
    expect(ShelfId(value).hashCode, ShelfId(value).hashCode);
    expect(ManualGroupId(value).value, value);
    expect(ShelfId(value), isNot(ManualGroupId(value)));
    for (final invalid in ['', 'a\u0000', '\ud800']) {
      expect(() => ShelfId(invalid), throwsA(isA<IdentityFailure>()));
      expect(() => ManualGroupId(invalid), throwsA(isA<IdentityFailure>()));
    }
  });

  test('metadata owns an immutable defensive tags copy', () {
    final input = ['x'];
    final snapshot = BookMetadataSnapshot(tags: input);
    input.add('y');
    expect(snapshot.tags, ['x']);
    expect(() => snapshot.tags.add('z'), throwsUnsupportedError);
  });

  test('all library writes reject unregistered sources without inventing registrations', () async {
    final missing = ref('missing');
    await expectLater(
      library.ensureStub(missing),
      failure(RepositoryFailureReason.invalidReference),
    );
    await expectLater(
      library.saveMetadata(missing, BookMetadataSnapshot()),
      failure(RepositoryFailureReason.invalidReference),
    );
    await expectLater(
      library.setSaved(missing, true),
      failure(RepositoryFailureReason.invalidReference),
    );
    expect(await library.list(), isEmpty);
    expect(
      await db.customSelect('SELECT * FROM source_registrations').get(),
      hasLength(2),
    );
  });

  test('reads and transient metadata do not create library entries', () async {
    BookMetadataSnapshot(title: 'Search result');
    expect(await library.get(a), isNull);
    expect(await library.list(), isEmpty);
    await expectLater(
      library.setSaved(a, true),
      failure(RepositoryFailureReason.notFound),
    );
    expect(await library.list(), isEmpty);
  });

  test('stub is unsaved, idempotent and source-aware; list has stable identity order', () async {
    await library.ensureStub(b);
    await library.ensureStub(a);
    await library.ensureStub(a);
    final entries = await library.list();
    expect(entries.map((e) => e.bookRef), [a, b]);
    expect(
      entries.every((e) => !e.saved && e.metadataState == MetadataState.stub),
      isTrue,
    );
    expect(entries.first.bookRef.bookId.value, ' 00042/#.文😀 ');
  });

  test(
    'complete metadata round-trip, saved and known state survive ensureStub',
    () async {
      final cover = SourceAssetRef(
        sourceId: a.sourceId,
        bookId: a.bookId,
        assetId: AssetId(' 封面/01 '),
      );
      await library.saveMetadata(
        a,
        BookMetadataSnapshot(
          title: ' 标题 ',
          author: '作者',
          description: 'Line\nTwo',
          coverAssetRef: cover,
          tags: ['b', '', 'b', ' 文 '],
          knownTotalChapters: 42,
          updateFlag: false,
        ),
      );
      await library.setSaved(a, true);
      await library.ensureStub(a);
      final entry = (await library.get(a))!;
      expect(entry.saved, isTrue);
      expect(entry.metadataState, MetadataState.known);
      expect(entry.metadata.title, ' 标题 ');
      expect(entry.metadata.author, '作者');
      expect(entry.metadata.description, 'Line\nTwo');
      expect(entry.metadata.coverAssetRef, cover);
      expect(entry.metadata.tags, ['b', '', 'b', ' 文 ']);
      expect(entry.metadata.knownTotalChapters, 42);
      expect(entry.metadata.updateFlag, isFalse);
      await library.setSaved(a, false);
      expect((await library.get(a))!.metadata.tags, entry.metadata.tags);
      expect((await library.get(a))!.saved, isFalse);
    },
  );

  test(
    'metadata replacement replaces tags and nullable fields but keeps saved',
    () async {
      await library.saveMetadata(
        a,
        BookMetadataSnapshot(title: 'old', tags: ['old'], updateFlag: true),
      );
      await library.setSaved(a, true);
      await library.saveMetadata(a, BookMetadataSnapshot(tags: ['new', 'new']));
      final entry = (await library.get(a))!;
      expect(entry.saved, isTrue);
      expect(entry.metadata.title, isNull);
      expect(entry.metadata.updateFlag, isNull);
      expect(entry.metadata.tags, ['new', 'new']);
    },
  );

  test(
    'cover source or book mismatch is invalid input and preserves old metadata',
    () async {
      await library.saveMetadata(
        a,
        BookMetadataSnapshot(title: 'old', tags: ['old']),
      );
      for (final wrong in [b, ref('a', 'different')]) {
        await expectLater(
          library.saveMetadata(
            a,
            BookMetadataSnapshot(
              coverAssetRef: SourceAssetRef(
                sourceId: wrong.sourceId,
                bookId: wrong.bookId,
                assetId: AssetId('x'),
              ),
            ),
          ),
          failure(RepositoryFailureReason.invalidInput),
        );
      }
      expect((await library.get(a))!.metadata.title, 'old');
      expect((await library.get(a))!.metadata.tags, ['old']);
    },
  );

  test(
    'failure during tag insertion rolls back metadata and all tags',
    () async {
      await library.saveMetadata(
        a,
        BookMetadataSnapshot(title: 'old', tags: ['old']),
      );
      await reject('book_tags', 'INSERT', 'NEW.ordinal=1');
      await expectLater(
        library.saveMetadata(
          a,
          BookMetadataSnapshot(title: 'new', tags: ['first', 'fail']),
        ),
        failure(RepositoryFailureReason.storage),
      );
      expect((await library.get(a))!.metadata.title, 'old');
      expect((await library.get(a))!.metadata.tags, ['old']);
      await expectLater(
        library.saveMetadata(b, BookMetadataSnapshot(tags: ['first', 'fail'])),
        failure(RepositoryFailureReason.storage),
      );
      expect(await library.get(b), isNull);
    },
  );

  test(
    'shelf create/read/rename and duplicate identity/negative ordinal failures',
    () async {
      final shelf = Shelf(id: sid, name: ' exact ', ordinal: 4);
      await shelves.createShelf(shelf);
      expect((await shelves.getShelf(sid))!.name, ' exact ');
      expect((await shelves.getShelf(sid))!.id, sid);
      await shelves.renameShelf(sid, 'renamed');
      expect((await shelves.getShelf(sid))!.name, 'renamed');
      await expectLater(
        shelves.createShelf(shelf),
        failure(RepositoryFailureReason.conflict),
      );
      await expectLater(
        shelves.createShelf(Shelf(id: other, name: '', ordinal: -1)),
        failure(RepositoryFailureReason.invalidInput),
      );
      expect(await shelves.getShelf(other), isNull);
      await expectLater(
        shelves.renameShelf(other, 'x'),
        failure(RepositoryFailureReason.notFound),
      );
    },
  );

  test(
    'shelf order uses ordinal and ID tie-break; complete reorder only',
    () async {
      for (final id in [other, sid]) {
        await shelves.createShelf(Shelf(id: id, name: 'same', ordinal: 3));
      }
      expect((await shelves.listShelves()).map((s) => s.id), [sid, other]);
      await shelves.reorderShelves([other, sid]);
      expect((await shelves.listShelves()).map((s) => s.id), [other, sid]);
      expect((await shelves.listShelves()).map((s) => s.ordinal), [0, 1]);
      for (final invalid in [
        [sid],
        [sid, sid],
        [sid, ShelfId('missing')],
      ]) {
        await expectLater(
          shelves.reorderShelves(invalid),
          failure(RepositoryFailureReason.invalidInput),
        );
      }
      expect((await shelves.listShelves()).map((s) => s.id), [other, sid]);
    },
  );

  test('shelf reorder failure after first update rolls back', () async {
    await shelves.createShelf(Shelf(id: sid, name: '', ordinal: 0));
    await shelves.createShelf(Shelf(id: other, name: '', ordinal: 1));
    await reject('shelves', 'UPDATE', "NEW.shelf_id=' shelf/文 '");
    await expectLater(
      shelves.reorderShelves([other, sid]),
      failure(RepositoryFailureReason.storage),
    );
    expect((await shelves.listShelves()).map((s) => s.id), [sid, other]);
    expect((await shelves.listShelves()).map((s) => s.ordinal), [0, 1]);
  });

  test('shelf members require existing books, duplicates conflict, append preserves order', () async {
    await shelves.createShelf(Shelf(id: sid, name: '', ordinal: 0));
    await expectLater(
      shelves.addMember(sid, a),
      failure(RepositoryFailureReason.invalidReference),
    );
    expect(await library.get(a), isNull);
    await books();
    await shelves.addMember(sid, b);
    await shelves.addMember(sid, a);
    await expectLater(
      shelves.addMember(sid, a),
      failure(RepositoryFailureReason.conflict),
    );
    expect(await shelfRefs(), [b, a]);
    expect((await shelves.listMembers(sid)).map((m) => m.ordinal), [0, 1]);
  });

  test(
    'member swaps avoid UNIQUE collisions; invalid permutations preserve order',
    () async {
      await shelfFixture();
      await shelves.reorderMembers(sid, [b, a]);
      expect(await shelfRefs(), [b, a]);
      for (final invalid in [
        [a],
        [a, a],
        [a, ref('a', 'unknown')],
      ]) {
        await expectLater(
          shelves.reorderMembers(sid, invalid),
          failure(RepositoryFailureReason.invalidInput),
        );
      }
      await expectLater(
        shelves.replaceMembers(sid, [ref('a', 'unknown')]),
        failure(RepositoryFailureReason.invalidReference),
      );
      expect(await shelfRefs(), [b, a]);
    },
  );

  test('member replacement/reorder failure after delete and first insert rolls back', () async {
    await shelfFixture();
    await reject('shelf_members', 'INSERT', 'NEW.ordinal=1');
    await expectLater(
      shelves.reorderMembers(sid, [b, a]),
      failure(RepositoryFailureReason.storage),
    );
    expect(await shelfRefs(), [a, b]);
    await expectLater(
      shelves.replaceMembers(sid, [b, a]),
      failure(RepositoryFailureReason.storage),
    );
    expect(await shelfRefs(), [a, b]);
  });

  test('group create/read/rename nullable name, deterministic ID list and duplicate conflict', () async {
    await groups.createGroup(ManualGroup(id: ManualGroupId('z')));
    await groups.createGroup(ManualGroup(id: gid, displayName: 'same'));
    expect((await groups.getGroup(gid))!.displayName, 'same');
    await groups.renameGroup(gid, ' renamed ');
    expect((await groups.getGroup(gid))!.displayName, ' renamed ');
    await groups.renameGroup(gid, null);
    expect((await groups.getGroup(gid))!.displayName, isNull);
    expect((await groups.listGroups()).map((g) => g.id), [
      gid,
      ManualGroupId('z'),
    ]);
    await expectLater(
      groups.createGroup(ManualGroup(id: gid)),
      failure(RepositoryFailureReason.conflict),
    );
    expect(await groups.getGroup(ManualGroupId('missing')), isNull);
    await expectLater(
      groups.renameGroup(ManualGroupId('missing'), null),
      failure(RepositoryFailureReason.notFound),
    );
  });

  test('group membership needs library entry, keeps source identities and rejects duplicates', () async {
    await groups.createGroup(ManualGroup(id: gid));
    await expectLater(
      groups.addMember(gid, a),
      failure(RepositoryFailureReason.invalidReference),
    );
    await books();
    await groups.addMember(gid, b);
    await groups.addMember(gid, a);
    await expectLater(
      groups.addMember(gid, a),
      failure(RepositoryFailureReason.conflict),
    );
    expect(await groupRefs(), [a, b]);
    await groups.removeMember(gid, a);
    await groups.removeMember(gid, a);
    expect(await groupRefs(), [b]);
    expect(await library.list(), hasLength(2));
  });

  test('group replacement validates set and references; failure midway restores old set', () async {
    await groupFixture();
    await expectLater(
      groups.replaceMembers(gid, [a, a]),
      failure(RepositoryFailureReason.invalidInput),
    );
    await expectLater(
      groups.replaceMembers(gid, [ref('a', 'missing')]),
      failure(RepositoryFailureReason.invalidReference),
    );
    expect(await groupRefs(), [a, b]);
    await reject('group_members', 'INSERT', "NEW.source_id='a'");
    await expectLater(
      groups.replaceMembers(gid, [b, a]),
      failure(RepositoryFailureReason.storage),
    );
    expect(await groupRefs(), [a, b]);
    await db.customStatement('DROP TRIGGER injected');
    await groups.replaceMembers(gid, [b]);
    expect(await groupRefs(), [b]);
  });

  test(
    'split true/false/absent are distinct; changes never erase raw groups',
    () async {
      await groupFixture();
      expect(await groups.getSplitOverride(a), isNull);
      await groups.setSplitOverride(a, true);
      expect((await groups.getSplitOverride(a))!.isSplit, isTrue);
      await groups.setSplitOverride(a, false);
      expect((await groups.getSplitOverride(a))!.isSplit, isFalse);
      expect(await groupRefs(), [a, b]);
      await groups.clearSplitOverride(a);
      await groups.clearSplitOverride(a);
      expect(await groups.getSplitOverride(a), isNull);
      expect(
        await db.customSelect('SELECT * FROM split_overrides').get(),
        isEmpty,
      );
      expect(await groupRefs(), [a, b]);
      await expectLater(
        groups.setSplitOverride(ref('a', 'missing'), true),
        failure(RepositoryFailureReason.invalidReference),
      );
    },
  );

  test('unsave, remove and delete operations preserve unrelated user state and progress', () async {
    await shelfFixture();
    await groups.createGroup(ManualGroup(id: gid));
    await groups.replaceMembers(gid, [a, b]);
    await groups.setSplitOverride(a, true);
    await library.saveMetadata(
      a,
      BookMetadataSnapshot(title: 'keep', tags: ['keep']),
    );
    await library.setSaved(a, true);
    await shelves.createShelf(Shelf(id: other, name: '', ordinal: 1));
    await shelves.addMember(other, a);
    await db.customStatement(
      'INSERT INTO reading_progress(source_id,book_id,has_read) VALUES (?,?,1)',
      [a.sourceId.value, a.bookId.value],
    );
    Future<void> preserved() async {
      expect((await library.get(a))!.metadata.title, 'keep');
      expect((await library.get(a))!.metadata.tags, ['keep']);
      expect((await shelves.listMembers(other)).single.bookRef, a);
      expect((await groups.getSplitOverride(a))!.isSplit, isTrue);
      expect(
        await db.customSelect('SELECT * FROM reading_progress').get(),
        hasLength(1),
      );
      expect(await library.list(), hasLength(2));
    }

    await library.setSaved(a, false);
    await preserved();
    expect(await shelfRefs(), [a, b]);
    expect(await groupRefs(), [a, b]);
    await shelves.removeMember(sid, a);
    await shelves.removeMember(sid, a);
    await preserved();
    expect(await shelfRefs(), [b]);
    expect(await groupRefs(), [a, b]);
    await shelves.deleteShelf(sid);
    expect(await shelves.getShelf(sid), isNull);
    await preserved();
    await groups.removeMember(gid, a);
    await preserved();
    await groups.deleteGroup(gid);
    expect(await groups.getGroup(gid), isNull);
    expect(await db.customSelect('SELECT * FROM group_members').get(), isEmpty);
    expect(
      (await db.customSelect('SELECT * FROM shelf_members').get()),
      hasLength(1),
    );
    await preserved();
  });

  test('referenced shelf deletion rolls back membership removal with typed failure', () async {
    await shelfFixture();
    await db.customStatement(
      "INSERT INTO app_preferences(singleton,theme,selected_shelf_id) VALUES (1,'system',?)",
      [sid.value],
    );
    await expectLater(
      shelves.deleteShelf(sid),
      failure(RepositoryFailureReason.invalidReference),
    );
    expect(await shelfRefs(), [a, b]);
    expect(await shelves.getShelf(sid), isNotNull);
  });

  test('group delete failure rolls back membership removal', () async {
    await groupFixture();
    await reject('manual_groups', 'DELETE', '1');
    await expectLater(
      groups.deleteGroup(gid),
      failure(RepositoryFailureReason.storage),
    );
    expect(await groupRefs(), [a, b]);
    expect(await groups.getGroup(gid), isNotNull);
  });

  test('shelf delete failure rolls back membership removal', () async {
    await shelfFixture();
    await reject('shelves', 'DELETE', '1');
    await expectLater(
      shelves.deleteShelf(sid),
      failure(RepositoryFailureReason.storage),
    );
    expect(await shelfRefs(), [a, b]);
    expect(await shelves.getShelf(sid), isNotNull);
  });

  test('existing legacy mapping references block deletion without modifying compatibility state', () async {
    await shelfFixture();
    await groups.createGroup(ManualGroup(id: gid));
    await groups.addMember(gid, a);
    await db.customStatement(
      "INSERT INTO migration_datasets VALUES ('fixture')",
    );
    await db.customStatement(
      "INSERT INTO legacy_identity_mappings(mapping_id,dataset_id,entity_kind,legacy_key,mapping_version,resolution,target_shelf_id) VALUES ('s','fixture','shelf','s',1,'resolved',?)",
      [sid.value],
    );
    await db.customStatement(
      "INSERT INTO legacy_identity_mappings(mapping_id,dataset_id,entity_kind,legacy_key,mapping_version,resolution,target_group_id) VALUES ('g','fixture','group','g',1,'resolved',?)",
      [gid.value],
    );
    await expectLater(
      shelves.deleteShelf(sid),
      failure(RepositoryFailureReason.invalidReference),
    );
    await expectLater(
      groups.deleteGroup(gid),
      failure(RepositoryFailureReason.invalidReference),
    );
    expect(await shelfRefs(), [a, b]);
    expect(await groupRefs(), [a]);
    expect(
      await db.customSelect('SELECT * FROM legacy_identity_mappings').get(),
      hasLength(2),
    );
  });

  test(
    'deleting one group preserves another group and its distinct source refs',
    () async {
      await groupFixture();
      final second = ManualGroupId('second');
      await groups.createGroup(ManualGroup(id: second));
      await groups.replaceMembers(second, [b, a]);
      await groups.deleteGroup(gid);
      expect((await groups.listMembers(second)).map((m) => m.bookRef), [a, b]);
      expect(await library.list(), hasLength(2));
    },
  );

  test(
    'missing collection owners report notFound and replacement can clear sets',
    () async {
      await expectLater(
        shelves.listMembers(sid),
        failure(RepositoryFailureReason.notFound),
      );
      await expectLater(
        groups.listMembers(gid),
        failure(RepositoryFailureReason.notFound),
      );
      await expectLater(
        shelves.deleteShelf(sid),
        failure(RepositoryFailureReason.notFound),
      );
      await expectLater(
        groups.deleteGroup(gid),
        failure(RepositoryFailureReason.notFound),
      );
      await shelfFixture();
      await groups.createGroup(ManualGroup(id: gid));
      await groups.addMember(gid, a);
      await shelves.replaceMembers(sid, []);
      await groups.replaceMembers(gid, []);
      expect(await shelfRefs(), isEmpty);
      expect(await groupRefs(), isEmpty);
      expect(await library.list(), hasLength(2));
    },
  );

  test('repositories share database authority without cached copies; input order is captured', () async {
    await shelfFixture();
    final order = [b, a];
    final write = shelves.reorderMembers(sid, order);
    order.clear();
    await write;
    final second = DriftShelfRepository(db);
    expect((await second.listMembers(sid)).map((m) => m.bookRef), [b, a]);
    await second.removeMember(sid, b);
    expect(await shelfRefs(), [a]);
    final anotherBook = ref('a', '00001');
    await library.ensureStub(anotherBook);
    expect((await library.list()).map((e) => e.bookRef), [a, anotherBook, b]);
  });

  test(
    'concurrent append operations preserve every member and unique ordinal',
    () async {
      await shelfFixture();
      await shelves.replaceMembers(sid, []);
      await Future.wait([shelves.addMember(sid, a), shelves.addMember(sid, b)]);
      expect(await shelfRefs(), unorderedEquals([a, b]));
      expect((await shelves.listMembers(sid)).map((m) => m.ordinal), [0, 1]);
    },
  );

  test('database failures cross repository boundary as safe typed storage failures', () async {
    await db.customStatement('DROP TABLE book_tags');
    try {
      await library.saveMetadata(
        a,
        BookMetadataSnapshot(title: 'private title'),
      );
      fail('Expected failure');
    } on RepositoryFailure catch (error) {
      expect(error.reason, RepositoryFailureReason.storage);
      expect(error.toString(), isNot(contains('book_tags')));
      expect(error.message, isNot(contains('private title')));
    }
    expect(await library.get(a), isNull);
  });
}
