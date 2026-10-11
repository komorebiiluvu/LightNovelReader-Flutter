import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:light_novel_reader/src/data/source_runtime/flutter_secure_credential_store.dart';
import 'package:light_novel_reader/src/data/source_runtime/dio_source_transport.dart';
import 'package:light_novel_reader/src/data/migration/legacy_state_import_service.dart';
import 'package:light_novel_reader/src/data/persistence/database.dart';
import 'package:light_novel_reader/src/data/persistence/database_open.dart';
import 'package:light_novel_reader/src/domain/migration/migration_models.dart';
import 'package:light_novel_reader/src/domain/identity/opaque_ids.dart';
import 'package:light_novel_reader/src/source/charset/charset.dart';
import 'package:light_novel_reader/src/domain/content/chapter_content.dart';
import 'package:light_novel_reader/src/domain/identity/source_refs.dart';
import 'package:light_novel_reader/src/source/source.dart';
import 'package:light_novel_reader/src/sources/wenku8/wenku8.dart';

import '../test/persistence/generated/schema_v1.dart' as v1;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('packaged SQLite production open/write/rollback/reopen', (
    _,
  ) async {
    final support = await getApplicationSupportDirectory();
    await support.create(recursive: true);
    // Only this unique child is touched or cleaned; never the production file.
    final root = await support.createTemp('f2-storage-smoke-');
    AppDatabase? db;
    const book = ' wk8-00042/#.文😀 ';
    try {
      db = await openAppDatabase(storageRoot: () async => root);
      const migrationDataset = 'f2-7-packaged-smoke';
      final migration = LegacyStateImportService(db);
      await migration.repository.ensureDataset(migrationDataset);
      final imported = await migration.importWithReport(
        MigrationInput(
          datasetId: migrationDataset,
          inputType: MigrationInputType.legacyIosSnapshotV1,
          bytes: utf8.encode(
            '{"theme":"dark","savedIDs":["wk8-00042"],'
            '"sourceByID":{"wk8-00042":"文库8(在线)"},'
            '"bookLibrary":[{"id":"wk8-00042","title":"Smoke",'
            '"author":"Test","tags":["f2.7"],"source":"文库8(在线)",'
            '"intro":"Packaged migration","totalChapters":1,'
            '"lastChapter":0,"hasUpdate":false,"hits":0,"coverIndex":0}],'
            '"lastChapterByID":{"wk8-00042":0},'
            '"readBookIDs":["wk8-00042"]}',
          ),
        ),
      );
      expect(imported.run.state, MigrationRunState.complete);
      expect(imported.report.accentUnavailable, isTrue);
      await db.transaction(() async {
        await db!.customStatement(
          "INSERT INTO source_registrations VALUES ('smoke-source','Smoke','unresolved')",
        );
        await db!.customStatement(
          "INSERT INTO library_entries(source_id,book_id,metadata_state) VALUES ('smoke-source',?,'stub')",
          [book],
        );
      });
      await db.close();
      db = await openAppDatabase(storageRoot: () async => root);
      final importedProgress = await db
          .customSelect(
            'SELECT p.has_read,p.chapter_id,l.dataset_id,l.book_id,l.legacy_book_id,l.chapter_index '
            'FROM reading_progress p JOIN legacy_chapter_locators l ON p.legacy_locator_id=l.locator_id',
          )
          .getSingle();
      expect(importedProgress.data, {
        'has_read': 1,
        'chapter_id': null,
        'dataset_id': migrationDataset,
        'book_id': 'wk8-00042',
        'legacy_book_id': 'wk8-00042',
        'chapter_index': 0,
      });
      expect(
        (await db
                .customSelect('SELECT theme,accent FROM app_preferences')
                .getSingle())
            .data,
        {'theme': 'dark', 'accent': null},
      );
      expect(
        (await db.customSelect('SELECT tag FROM book_tags').getSingle())
            .read<String>('tag'),
        'f2.7',
      );
      expect(
        (await db
                .customSelect(
                  'SELECT book_id FROM library_entries WHERE source_id=?',
                  variables: [const Variable<String>('builtin.wenku8')],
                )
                .getSingle())
            .read<String>('book_id'),
        'wk8-00042',
      );
      expect(
        (await db
                .customSelect(
                  'SELECT book_id FROM library_entries WHERE source_id=?',
                  variables: [const Variable<String>('smoke-source')],
                )
                .getSingle())
            .read<String>('book_id'),
        book,
      );
      expect(
        (await db.customSelect('PRAGMA foreign_keys').getSingle()).read<int>(
          'foreign_keys',
        ),
        1,
      );
      expect(
        (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
          'user_version',
        ),
        2,
      );
      expect(
        (await db
                .customSelect(
                  'SELECT reconciliation_receipt_id FROM reading_progress',
                )
                .getSingle())
            .readNullable<String>('reconciliation_receipt_id'),
        isNull,
      );
      expect(
        await db
            .customSelect('SELECT * FROM chapter_reconciliation_receipts')
            .get(),
        isEmpty,
      );
      await expectLater(
        db.transaction(() async {
          await db!.customStatement(
            "INSERT INTO shelves VALUES ('rollback','test',0)",
          );
          throw StateError('injected rollback');
        }),
        throwsStateError,
      );
      expect(await db.customSelect('SELECT * FROM shelves').get(), isEmpty);
    } finally {
      await db?.close();
      await root.delete(recursive: true);
    }
  });

  testWidgets('packaged v1 database upgrades to v2 without losing progress', (
    _,
  ) async {
    final support = await getApplicationSupportDirectory();
    await support.create(recursive: true);
    final root = await support.createTemp('f3-7-upgrade-smoke-');
    AppDatabase? upgraded;
    try {
      final file = File.fromUri(root.uri.resolve(databaseFilename));
      final old = v1.DatabaseAtV1(NativeDatabase(file));
      try {
        await old.customStatement(
          "INSERT INTO source_registrations(source_id,availability) VALUES ('smoke','unresolved')",
        );
        await old.customStatement(
          "INSERT INTO library_entries(source_id,book_id,metadata_state) VALUES ('smoke','book','stub')",
        );
        await old.customStatement(
          "INSERT INTO migration_datasets(dataset_id) VALUES ('smoke-dataset')",
        );
        await old.customStatement(
          "INSERT INTO legacy_chapter_locators(locator_id,dataset_id,source_id,book_id,legacy_book_id,chapter_index,fraction) VALUES ('locator','smoke-dataset','smoke','book','book',2,0.25)",
        );
        await old.customStatement(
          "INSERT INTO reading_progress(source_id,book_id,has_read,legacy_locator_id) VALUES ('smoke','book',1,'locator')",
        );
      } finally {
        await old.close();
      }
      upgraded = await openAppDatabase(storageRoot: () async => root);
      expect(
        (await upgraded.customSelect('PRAGMA user_version').getSingle())
            .read<int>('user_version'),
        2,
      );
      final row = await upgraded
          .customSelect(
            'SELECT p.chapter_id,p.reconciliation_receipt_id,l.chapter_index,l.fraction '
            'FROM reading_progress p JOIN legacy_chapter_locators l '
            'ON p.legacy_locator_id=l.locator_id',
          )
          .getSingle();
      expect(row.readNullable<String>('chapter_id'), isNull);
      expect(row.readNullable<String>('reconciliation_receipt_id'), isNull);
      expect(row.read<int>('chapter_index'), 2);
      expect(row.read<double>('fraction'), 0.25);
    } finally {
      await upgraded?.close();
      await root.delete(recursive: true);
    }
  });

  testWidgets('packaged secure storage write/read/delete', (_) async {
    final store = FlutterSecureCredentialStore();
    final key = SecureStorageKey(
      sourceId: SourceId('f3.3-packaged-smoke'),
      name: 'roundtrip',
    );
    final sentinel = 'runtime-secret-${DateTime.now().microsecondsSinceEpoch}';
    final value = SecureValue(sentinel);
    await store.delete(key);
    await store.write(key, value);
    expect((await store.read(key))!.value, sentinel);
    expect(
      (await FlutterSecureCredentialStore().read(key))!.value,
      sentinel,
      reason: 'a new adapter instance must observe the packaged storage value',
    );
    await store.delete(key);
    expect(await store.read(key), isNull);
  });

  testWidgets('secure-storage failure is typed and contains no value', (
    _,
  ) async {
    final store = FlutterSecureCredentialStore(
      storage: _FailingSecureStorage(),
    );
    final key = SecureStorageKey(
      sourceId: SourceId('f3.7-packaged-failure'),
      name: 'roundtrip',
    );
    await expectLater(
      store.read(key),
      throwsA(
        isA<SourceFailure>()
            .having(
              (failure) => failure.code,
              'code',
              SourceFailureCode.secureStorage,
            )
            .having(
              (failure) => failure.toString(),
              'safe message',
              isNot(contains('SYNTHETIC_SECRET')),
            ),
      ),
    );
  });

  testWidgets('packaged charset vectors execute on this runtime', (_) async {
    const decoder = CharsetDecoder();
    final evidence = CharsetEvidence(
      'F3.7 independently authored runtime vector',
    );
    DecodedDocument decode(
      List<int> bytes,
      SourceEncoding encoding, {
      CharsetErrorMode mode = CharsetErrorMode.strict,
    }) => decoder.decode(
      RawBytes(bytes),
      encoding: encoding,
      errorMode: mode,
      evidence: evidence,
    );

    expect(
      decode(const [
        0xd6,
        0xd0,
        0xce,
        0xc4,
        0xd0,
        0xa1,
        0xcb,
        0xb5,
      ], SourceEncoding.legacyCp936Compatible).text,
      '中文小说',
    );
    expect(
      decode(const [0xaa, 0xa1], SourceEncoding.legacyCp936Compatible).text,
      '\ue000',
    );
    expect(
      decode(const [0x81, 0x30, 0x81, 0x30], SourceEncoding.gb18030).text,
      '\u0080',
    );
    for (final bytes in [
      const [0x81, 0x30, 0xff],
      const [0x81, 0x30, 0x81],
    ]) {
      expect(
        () => decode(bytes, SourceEncoding.gb18030),
        throwsA(isA<CharsetDecodeException>()),
      );
    }
    final replaced = decode(
      const [0x81, 0x30, 0xff],
      SourceEncoding.gb18030,
      mode: CharsetErrorMode.replacement,
    );
    expect(replaced.text, '\ufffd0\ufffd');
    expect(replaced.replacements.offsets, [0, 2]);
  });

  testWidgets('packaged scripted Source normalizes the complete read path', (
    _,
  ) async {
    final sourceId = SourceId('builtin.wenku8');
    final sessions = SourceSessionManager();
    final transport = _PackagedSourceTransport();
    final source = Wenku8Source(transport: transport, sessions: sessions);
    final registry = SourceRegistry()..register(source);
    SourceOperationContext context(SourceOperation operation) =>
        SourceOperationContext(
          sourceId: sourceId,
          operation: operation,
          sessionGeneration: sessions.snapshot(sourceId).generation,
          cancellation: SourceCancellation(),
        );

    final search = await registry
        .resolve(sourceId)
        .search(SearchQuery(text: '中文'), context(SourceOperation.search));
    expect(search.items.single.bookRef.bookId, BookId('wk8-201'));
    expect(search.next, isNull);
    expect(
      transport.requests.first.uri.query,
      contains('searchkey=%D6%D0%CE%C4'),
    );

    final explore = await source.explore(
      ExploreRequest(descriptorId: 'home'),
      context(SourceOperation.explore),
    );
    expect(
      explore.blocks.single.books.single.bookRef.bookId,
      BookId('wk8-201'),
    );

    final book = SourceBookRef(sourceId: sourceId, bookId: BookId('wk8-201'));
    final detail = await source.getBook(
      book,
      context(SourceOperation.bookDetail),
    );
    expect(detail.title, '书名');
    expect(detail.author, '作者甲');

    final catalog = await source.getCatalog(
      book,
      context(SourceOperation.catalog),
    );
    expect(
      catalog.chapters.map((chapter) => chapter.chapterRef.chapterId.value),
      ['1', '2', '3'],
    );
    final chapter = catalog.chapters.first.chapterRef;
    final content = await source.getChapterContent(
      chapter,
      context(SourceOperation.chapterContent),
    );
    expect(content.chapterRef, chapter);
    expect(content.nodes, hasLength(3));
    expect(content.nodes.first, const TextNode('前'));
    expect(content.nodes[1], isA<ImageNode>());
    expect(content.nodes.last, const TextNode('后'));
    expect(
      source.assets.locatorFor((content.nodes[1] as ImageNode).assetRef),
      '/a.jpg',
    );
    expect(transport.requests.map((request) => request.operation), [
      SourceOperation.search,
      SourceOperation.explore,
      SourceOperation.bookDetail,
      SourceOperation.catalog,
      SourceOperation.chapterContent,
    ]);
    expect(
      transport.requests.every((request) => request.uri.scheme == 'https'),
      isTrue,
    );
  });

  testWidgets('packaged Dio transport executes scripted Source search', (
    _,
  ) async {
    final sourceId = SourceId('builtin.wenku8');
    final sessions = SourceSessionManager();
    final adapter = _PackagedDioAdapter();
    final transport = DioSourceTransport(
      adapter: adapter,
      sessionAuthority: sessions,
    );
    final source = Wenku8Source(transport: transport, sessions: sessions);
    final result = await source.search(
      SearchQuery(text: '中文'),
      SourceOperationContext(
        sourceId: sourceId,
        operation: SourceOperation.search,
        sessionGeneration: sessions.snapshot(sourceId).generation,
        cancellation: SourceCancellation(),
      ),
    );
    expect(result.items.single.bookRef.bookId, BookId('wk8-201'));
    expect(adapter.paths, hasLength(1));
    expect(adapter.paths.single, contains('/modules/article/search.php'));
    expect(adapter.paths.single, contains('searchkey=%D6%D0%CE%C4'));
  });

  testWidgets('packaged session rejects late cookies after logout', (_) async {
    final sessions = SourceSessionManager();
    final source = SourceId('builtin.wenku8');
    final other = SourceId('synthetic.other');
    final binding = sessions.capture(source);
    final uri = Uri.parse('https://www.wenku8.net/book/201.htm');
    final headers = SourceHttpHeaders(
      values: {
        'set-cookie': ['PHPSESSID=SYNTHETIC_RUNTIME; Path=/; Secure'],
      },
    );
    expect(sessions.commitResponseCookies(binding, uri, headers), isTrue);
    expect(sessions.snapshot(source).cookies, hasLength(1));
    expect(sessions.snapshot(other).cookies, isEmpty);
    sessions.logout(source);
    expect(sessions.commitResponseCookies(binding, uri, headers), isFalse);
    expect(sessions.snapshot(source).cookies, isEmpty);
    expect(sessions.snapshot(other).cookies, isEmpty);
  });

  testWidgets('packaged Source suppresses late search after logout', (_) async {
    final sessions = SourceSessionManager();
    final sourceId = SourceId('builtin.wenku8');
    final transport = _DelayedPackagedSourceTransport();
    final source = Wenku8Source(transport: transport, sessions: sessions);
    final pending = source.search(
      SearchQuery(text: '中文'),
      SourceOperationContext(
        sourceId: sourceId,
        operation: SourceOperation.search,
        sessionGeneration: sessions.snapshot(sourceId).generation,
        cancellation: SourceCancellation(),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    sessions.logout(sourceId);
    transport.complete();
    await expectLater(
      pending,
      throwsA(
        isA<SourceFailure>().having(
          (failure) => failure.code,
          'code',
          SourceFailureCode.cancelled,
        ),
      ),
    );
  });
}

final class _PackagedSourceTransport implements SourceTransport {
  final requests = <SourceHttpRequest>[];

  @override
  Future<SourceHttpResponse> send(SourceHttpRequest request) async {
    requests.add(request);
    final html = switch (request.operation) {
      SourceOperation.search =>
        '<a href="/book/201.htm">书名</a>'
            '<div id="pagelink"><em>1 / 1</em></div>',
      SourceOperation.explore =>
        '<div class="block"><h2>热门</h2>'
            '<a href="/book/201.htm">书名</a></div>',
      SourceOperation.bookDetail =>
        '<div id="content"><table><tr><td><b>书名</b></td></tr>'
            '<tr><td>小说作者： 作者甲</td></tr></table>'
            '<span>内容简介：</span><span>简介正文</span>'
            '<span><a href="/novel/0/201/index.htm">最近章节</a></span></div>',
      SourceOperation.catalog =>
        '<table><tbody><tr><td class="vcss" vid="v1">第一卷</td></tr>'
            '<tr><td><a href="1.htm">第一章</a></td>'
            '<td><a href="2.htm">第二章</a></td></tr>'
            '<tr><td class="vcss" vid="v2">第二卷</td></tr>'
            '<tr><td><a href="3.htm">第三章</a></td></tr></tbody></table>',
      SourceOperation.chapterContent =>
        '<p>前</p><div class="image"><img src="/a.jpg"></div><p>后</p>',
      _ => throw StateError('Unexpected operation in packaged Source smoke'),
    };
    return SourceHttpResponse(
      statusCode: 200,
      headers: SourceHttpHeaders.fromSingleValue({
        'content-type': 'text/html; charset=utf-8',
      }),
      bodyBytes: utf8.encode(html),
      finalUri: request.uri,
    );
  }
}

final class _PackagedDioAdapter implements HttpClientAdapter {
  final paths = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    paths.add(options.uri.toString());
    return ResponseBody.fromBytes(
      utf8.encode(
        '<a href="/book/201.htm">书名</a>'
        '<div id="pagelink"><em>1 / 1</em></div>',
      ),
      200,
      headers: {
        'content-type': ['text/html; charset=utf-8'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

final class _DelayedPackagedSourceTransport implements SourceTransport {
  final _response = Completer<SourceHttpResponse>();
  SourceHttpRequest? _request;

  @override
  Future<SourceHttpResponse> send(SourceHttpRequest request) {
    _request = request;
    return _response.future;
  }

  void complete() {
    final request = _request!;
    _response.complete(
      SourceHttpResponse(
        statusCode: 200,
        headers: SourceHttpHeaders.fromSingleValue({
          'content-type': 'text/html; charset=utf-8',
        }),
        bodyBytes: utf8.encode(
          '<a href="/book/201.htm">书名</a>'
          '<div id="pagelink"><em>1 / 1</em></div>',
        ),
        finalUri: request.uri,
      ),
    );
  }
}

final class _FailingSecureStorage extends FlutterSecureStorage {
  const _FailingSecureStorage();

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) => throw StateError('SYNTHETIC_SECRET');
}
