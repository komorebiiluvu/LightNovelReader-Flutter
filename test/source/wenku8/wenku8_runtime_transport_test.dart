import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_reader/src/data/source_runtime/dio_source_transport.dart';
import 'package:light_novel_reader/src/data/source_runtime/wenku8_runtime_composition.dart';
import 'package:light_novel_reader/src/domain/identity/opaque_ids.dart';
import 'package:light_novel_reader/src/domain/identity/source_refs.dart';
import 'package:light_novel_reader/src/source/source.dart';
import 'package:light_novel_reader/src/sources/wenku8/wenku8.dart';

void main() {
  final sourceId = SourceId('builtin.wenku8');

  SourceOperationContext context(
    SourceSessionManager sessions,
    SourceOperation operation,
  ) => SourceOperationContext(
    sourceId: sourceId,
    operation: operation,
    sessionGeneration: sessions.snapshot(sourceId).generation,
    cancellation: SourceCancellation(),
  );

  test('composition registers one Source and matching authenticator', () {
    final runtime = Wenku8RuntimeComposition.create();
    expect(identical(runtime.registry.resolve(sourceId), runtime.source), true);
    expect(
      identical(
        runtime.registry.resolveAuthenticator(sourceId),
        runtime.authenticator,
      ),
      true,
    );
  });

  test(
    'scripted Dio login, search, detail and logout isolate cookies',
    () async {
      final requests = <RequestOptions>[];
      final adapter = _Adapter((options, _, _) async {
        requests.add(options);
        final cookie = options.headers.entries
            .where((entry) => entry.key.toLowerCase() == 'cookie')
            .map((entry) => entry.value.toString())
            .firstOrNull;
        if (options.path.contains('/login.php')) {
          expect(options.method, 'POST');
          expect(cookie, isNull);
          return ResponseBody.fromBytes(
            const [],
            302,
            headers: {
              'set-cookie': [
                'PHPSESSID=SYNTHETIC_SESSION; Path=/; Secure',
                'jieqiUserInfo=SYNTHETIC_USER_INFO; Path=/; Secure',
              ],
            },
          );
        }
      if (options.path.contains('/modules/article/search.php')) {
        expect(options.uri.query, contains('searchkey='));
          if (requests.length == 2) {
            expect(cookie, contains('jieqiUserInfo=SYNTHETIC_USER_INFO'));
          } else {
            expect(cookie, isNull);
          }
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
        expect(options.path, contains('/book/201.htm'));
        expect(
          cookie,
          isNull,
          reason: 'host-only .net cookie must not reach .cc',
        );
        return ResponseBody.fromBytes(
          utf8.encode('<div id="content"><b>书名</b></div>'),
          200,
          headers: {
            'content-type': ['text/html; charset=utf-8'],
          },
        );
      });
      final sessions = SourceSessionManager();
      final transport = DioSourceTransport(
        adapter: adapter,
        sessionAuthority: sessions,
      );
      final source = Wenku8Source(transport: transport, sessions: sessions);
      final auth = Wenku8Authenticator(
        transport: transport,
        sessions: sessions,
      );
      final registry = SourceRegistry()..register(source, authenticator: auth);
      final credentials = Wenku8Credentials(
        username: SecureValue('SYNTHETIC_USER'),
        password: SecureValue('SYNTHETIC_PASSWORD'),
      );
      expect(
        (await registry
                .resolveAuthenticator(sourceId)
                .signIn(
                  credentials,
                  context(sessions, SourceOperation.authentication),
                ))
            .isAuthenticated,
        true,
      );
      final search = await registry
          .resolve(sourceId)
          .search(
            SearchQuery(text: '书名'),
            context(sessions, SourceOperation.search),
          );
      expect(search.items.single.bookRef.bookId, BookId('wk8-201'));
      final detail = await registry
          .resolve(sourceId)
          .getBook(
            SourceBookRef(sourceId: sourceId, bookId: BookId('wk8-201')),
            context(sessions, SourceOperation.bookDetail),
          );
      expect(detail.title, '书名');
      await auth.signOut(context(sessions, SourceOperation.authentication));
      expect(sessions.snapshot(sourceId).cookies, isEmpty);
      await source.search(
        SearchQuery(text: '书名'),
        context(sessions, SourceOperation.search),
      );
      expect(requests.length, 4);
    },
  );
}

final class _Adapter implements HttpClientAdapter {
  _Adapter(this.handler);

  final Future<ResponseBody> Function(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  )
  handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => handler(options, requestStream, cancelFuture);

  @override
  void close({bool force = false}) {}
}
