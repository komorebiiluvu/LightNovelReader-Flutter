import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_reader/src/data/source_runtime/dio_source_transport.dart';
import 'package:light_novel_reader/src/domain/identity/opaque_ids.dart';
import 'package:light_novel_reader/src/source/source.dart';

void main() {
  final sourceA = SourceId('source-A');
  final sourceB = SourceId('source-B');
  final origin = Uri.parse('https://alpha.invalid/books');

  SourceHttpRequest request({
    SourceHttpMethod method = SourceHttpMethod.get,
    Uri? uri,
    SourceHttpHeaders? headers,
    List<int>? body,
    SourceTransportPolicy? policy,
    SourceCancellation? cancellation,
    SourceOperation operation = SourceOperation.search,
    SourceId? sourceId,
    int generation = 0,
  }) => SourceHttpRequest(
    sourceId: sourceId ?? sourceA,
    operation: operation,
    method: method,
    uri: uri ?? origin,
    headers: headers ?? SourceHttpHeaders(),
    bodyBytes: body,
    policy: policy ?? SourceTransportPolicy(),
    cancellation: cancellation ?? SourceCancellation(),
    sessionGeneration: generation,
  );

  group('Dio transport', () {
    test('returns raw bytes, repeated headers and ordinary statuses', () async {
      final adapter = ScriptedAdapter((options, _, _) async {
        expect(options.responseType, ResponseType.stream);
        return ResponseBody.fromBytes(
          [0, 1, 255],
          404,
          headers: {
            'set-cookie': ['one=1', 'two=2'],
            'x-repeat': ['a', 'b'],
          },
        );
      });
      final response = await DioSourceTransport(adapter: adapter)
          .send(request());
      expect(response.statusCode, 404);
      expect(response.bodyBytes, [0, 1, 255]);
      expect(response.headers.valuesFor('SET-COOKIE'), ['one=1', 'two=2']);
      expect(response.headers.valuesFor('x-repeat'), ['a', 'b']);
      expect(response.finalUri, origin);
      expect(response.toString(), isNot(contains('one=1')));
    });

    test('supports POST byte bodies without provider encoding', () async {
      late RequestOptions seen;
      final adapter = ScriptedAdapter((options, _, _) async {
        seen = options;
        return ResponseBody.fromBytes([7], 200);
      });
      final response = await DioSourceTransport(adapter: adapter)
          .send(request(method: SourceHttpMethod.post, body: [1, 2, 3]));
      expect(response.bodyBytes, [7]);
      expect(seen.method, 'POST');
    });

    test('pre-cancelled operation performs no I/O', () async {
      final cancellation = SourceCancellation()..cancel();
      final adapter = ScriptedAdapter((_, _, _) async {
        fail('cancelled request reached Dio');
      });
      await expectLater(
        DioSourceTransport(adapter: adapter)
            .send(request(cancellation: cancellation)),
        throwsA(
          isA<SourceFailure>().having(
            (failure) => failure.code,
            'code',
            SourceFailureCode.cancelled,
          ),
        ),
      );
      expect(adapter.calls, 0);
    });

    test('cancellation during I/O aborts the scripted request', () async {
      final cancellation = SourceCancellation();
      final adapter = ScriptedAdapter((options, _, cancelFuture) async {
        await Future.any<void>([
          Completer<void>().future,
          cancelFuture!.then<void>(
            (_) => throw DioException.requestCancelled(
              requestOptions: options,
              reason: null,
            ),
          ),
        ]);
        throw StateError('unreachable');
      });
      final future = DioSourceTransport(adapter: adapter)
          .send(request(cancellation: cancellation));
      await Future<void>.delayed(Duration.zero);
      cancellation.cancel();
      await expectLater(
        future,
        throwsA(
          isA<SourceFailure>().having(
            (failure) => failure.code,
            'code',
            SourceFailureCode.cancelled,
          ),
        ),
      );
    });

    test('listener is removed after success and failure', () async {
      final successCancellation = SourceCancellation();
      final successAdapter = ScriptedAdapter(
        (_, _, _) async => ResponseBody.fromBytes([1], 200),
      );
      await DioSourceTransport(adapter: successAdapter)
          .send(request(cancellation: successCancellation));
      successCancellation.cancel();

      final failureCancellation = SourceCancellation();
      final failureAdapter = ScriptedAdapter((options, _, _) async {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      });
      await expectLater(
        DioSourceTransport(adapter: failureAdapter)
            .send(request(cancellation: failureCancellation)),
        throwsA(isA<SourceFailure>()),
      );
      failureCancellation.cancel();
    });

    test('maps Dio timeout and cancellation to neutral failures', () async {
      final timeoutAdapter = ScriptedAdapter((options, _, _) async {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.receiveTimeout,
        );
      });
      await expectLater(
        DioSourceTransport(adapter: timeoutAdapter).send(request()),
        throwsA(
          isA<SourceFailure>().having(
            (failure) => failure.code,
            'code',
            SourceFailureCode.network,
          ),
        ),
      );
    });

    test(
      'retries idempotent failures a finite exact number of times',
      () async {
        var calls = 0;
        final adapter = ScriptedAdapter((_, _, _) async {
          calls++;
          return ResponseBody.fromBytes(
            calls < 3 ? [5] : [9],
            calls < 3 ? 503 : 200,
          );
        });
        final response = await DioSourceTransport(adapter: adapter).send(
          request(
            policy: SourceTransportPolicy(
              retry: SourceRetryPolicy(
                maxAttempts: 3,
                baseDelay: Duration.zero,
                maxDelay: Duration.zero,
              ),
            ),
          ),
        );
        expect(calls, 3);
        expect(response.statusCode, 200);
        expect(response.bodyBytes, [9]);
      },
    );

    test('cancellation stops retry backoff immediately', () async {
      final cancellation = SourceCancellation();
      final requestStarted = Completer<void>();
      var calls = 0;
      final adapter = ScriptedAdapter((_, _, _) async {
        calls++;
        requestStarted.complete();
        return ResponseBody.fromBytes([], 503);
      });
      final future = DioSourceTransport(adapter: adapter).send(
        request(
          cancellation: cancellation,
          policy: SourceTransportPolicy(
            retry: SourceRetryPolicy(
              maxAttempts: 3,
              baseDelay: const Duration(seconds: 30),
              maxDelay: const Duration(seconds: 30),
            ),
          ),
        ),
      );
      await requestStarted.future;
      cancellation.cancel();
      await expectLater(
        future,
        throwsA(
          isA<SourceFailure>().having(
            (failure) => failure.code,
            'code',
            SourceFailureCode.cancelled,
          ),
        ),
      );
      expect(calls, 1);
    });

    test('does not retry authentication POST', () async {
      var calls = 0;
      final adapter = ScriptedAdapter((_, _, _) async {
        calls++;
        return ResponseBody.fromBytes([], 503);
      });
      final response = await DioSourceTransport(adapter: adapter).send(
        request(
          method: SourceHttpMethod.post,
          operation: SourceOperation.authentication,
          body: [1],
          policy: SourceTransportPolicy(
            retry: SourceRetryPolicy(
              maxAttempts: 3,
              baseDelay: Duration.zero,
              maxDelay: Duration.zero,
            ),
          ),
        ),
      );
      expect(calls, 1);
      expect(response.statusCode, 503);
    });

    test('enforces response-size below, equal and above boundaries', () async {
      Future<SourceHttpResponse> sendLength(int length, int maximum) =>
          DioSourceTransport(
            adapter: ScriptedAdapter(
              (_, _, _) async =>
                  ResponseBody.fromBytes(List<int>.filled(length, 1), 200),
            ),
          ).send(
            request(policy: SourceTransportPolicy(maxResponseBytes: maximum)),
          );
      expect((await sendLength(2, 3)).bodyBytes, hasLength(2));
      expect((await sendLength(3, 3)).bodyBytes, hasLength(3));
      await expectLater(
        sendLength(4, 3),
        throwsA(
          isA<SourceFailure>().having(
            (failure) => failure.code,
            'code',
            SourceFailureCode.network,
          ),
        ),
      );
    });

    test(
      'follows only approved redirects and strips cross-origin secrets',
      () async {
        final seen = <RequestOptions>[];
        final adapter = ScriptedAdapter((options, _, _) async {
          seen.add(options);
          if (options.uri.path == '/start') {
            return ResponseBody.fromBytes(
              [],
              302,
              headers: {
                'location': ['https://beta.invalid/final'],
              },
            );
          }
          return ResponseBody.fromBytes([8], 200);
        });
        final response = await DioSourceTransport(adapter: adapter).send(
          request(
            uri: Uri.parse('https://alpha.invalid/start'),
            headers: SourceHttpHeaders.fromSingleValue({
              'Authorization': 'Bearer TOP_SECRET_SENTINEL_DO_NOT_LOG',
              'Cookie': 'sid=TOP_SECRET_SENTINEL_DO_NOT_LOG',
            }),
            policy: SourceTransportPolicy(
              redirects: SourceRedirectPolicy.follow(
                allowedOrigins: {'https://beta.invalid'},
              ),
            ),
          ),
        );
        expect(response.statusCode, 200);
        expect(response.redirectHistory, hasLength(1));
        expect(seen.last.headers.containsKey('authorization'), isFalse);
        expect(seen.last.headers.containsKey('cookie'), isFalse);
        expect(response.toString(), isNot(contains('TOP_SECRET')));
      },
    );

    test('rejects redirect loops, limits and HTTPS downgrade', () async {
      expect(
        () => request(uri: Uri.parse('https://user:pass@alpha.invalid/')),
        throwsArgumentError,
      );
      final loopAdapter = ScriptedAdapter((options, _, _) async {
        return ResponseBody.fromBytes(
          [],
          302,
          headers: {
            'location': [options.uri.toString()],
          },
        );
      });
      await expectLater(
        DioSourceTransport(adapter: loopAdapter).send(
          request(
            policy: SourceTransportPolicy(
              redirects: SourceRedirectPolicy.follow(maxRedirects: 2),
            ),
          ),
        ),
        throwsA(
          isA<SourceFailure>().having(
            (failure) => failure.code,
            'code',
            SourceFailureCode.securityPolicy,
          ),
        ),
      );

      final downgradeAdapter = ScriptedAdapter((_, _, _) async {
        return ResponseBody.fromBytes(
          [],
          302,
          headers: {
            'location': ['http://alpha.invalid/insecure'],
          },
        );
      });
      await expectLater(
        DioSourceTransport(adapter: downgradeAdapter).send(
          request(
            policy: SourceTransportPolicy(
              redirects: SourceRedirectPolicy.follow(),
            ),
          ),
        ),
        throwsA(isA<SourceFailure>()),
      );
    });

    test('no-follow preserves the redirect response', () async {
      final adapter = ScriptedAdapter((_, _, _) async {
        return ResponseBody.fromBytes(
          [3],
          301,
          headers: {
            'location': ['https://alpha.invalid/next'],
          },
        );
      });
      final response = await DioSourceTransport(adapter: adapter)
          .send(request());
      expect(response.statusCode, 301);
      expect(response.bodyBytes, [3]);
      expect(adapter.calls, 1);
    });
  });

  group('Source cookies and sessions', () {
    test('parses Expires comma and cookie attributes', () {
      final cookie = SourceCookie.parseSetCookie(
        sourceA,
        'sid=abc; Expires=Wed, 21 Oct 2030 07:28:00 GMT; Domain=.alpha.invalid; Path=/books; Secure; HttpOnly; SameSite=Lax',
        origin,
        now: DateTime.utc(2026),
      );
      expect(cookie, isNotNull);
      expect(cookie!.domain, 'alpha.invalid');
      expect(cookie.hostOnly, isFalse);
      expect(cookie.path, '/books');
      expect(cookie.secure, isTrue);
      expect(cookie.httpOnly, isTrue);
      expect(cookie.sameSite, SourceCookieSameSite.lax);
      expect(cookie.expires, DateTime.utc(2030, 10, 21, 7, 28));
      expect(cookie.toString(), isNot(contains('abc')));
    });

    test('rejects ambiguous comma-combined cookie fields', () {
      expect(SourceCookie.parseSetCookie(sourceA, 'a=1, b=2', origin), isNull);
    });

    test('commits repeated cookies with replacement and deletion', () {
      final manager = SourceSessionManager();
      manager.now = () => DateTime.utc(2026, 1, 1);
      final binding = manager.capture(sourceA);
      expect(
        manager.commitResponseCookies(
          binding,
          origin,
          SourceHttpHeaders(
            values: {
              'Set-Cookie': [
                'sid=one; Path=/books',
                'theme=dark; Secure; Path=/',
              ],
            },
          ),
        ),
        isTrue,
      );
      expect(
        manager.cookieHeader(
          binding,
          Uri.parse('https://alpha.invalid/books/1'),
        ),
        'sid=one; theme=dark',
      );
      manager.commitResponseCookies(
        binding,
        origin,
        SourceHttpHeaders(
          values: {
            'Set-Cookie': ['sid=two; Path=/books'],
          },
        ),
      );
      expect(
        manager.cookieHeader(
          binding,
          Uri.parse('https://alpha.invalid/books/1'),
        ),
        'sid=two; theme=dark',
      );
      manager.commitResponseCookies(
        binding,
        origin,
        SourceHttpHeaders(
          values: {
            'Set-Cookie': ['sid=gone; Max-Age=0; Path=/books'],
          },
        ),
      );
      expect(
        manager.cookieHeader(
          binding,
          Uri.parse('https://alpha.invalid/books/1'),
        ),
        'theme=dark',
      );
    });

    test('enforces host, domain, path, secure and expiry matching', () {
      final manager = SourceSessionManager();
      manager.now = () => DateTime.utc(2026, 1, 1);
      final binding = manager.capture(sourceA);
      manager.commitResponseCookies(
        binding,
        origin,
        SourceHttpHeaders(
          values: {
            'set-cookie': [
              'host=1; Path=/books',
              'domain=2; Domain=alpha.invalid; Path=/',
              'secure=3; Secure; Path=/',
              'expired=4; Expires=Wed, 21 Oct 2020 07:28:00 GMT',
            ],
          },
        ),
      );
      expect(
        manager.cookieHeader(
          binding,
          Uri.parse('https://alpha.invalid/books/1'),
        ),
        'host=1; domain=2; secure=3',
      );
      expect(
        manager.cookieHeader(
          binding,
          Uri.parse('http://alpha.invalid/books/1'),
        ),
        'host=1; domain=2',
      );
      expect(
        manager.cookieHeader(
          binding,
          Uri.parse('https://child.alpha.invalid/'),
        ),
        'domain=2',
      );
      expect(
        manager.cookieHeader(
          binding,
          Uri.parse('https://beta.invalid/books/1'),
        ),
        isNull,
      );
    });

    test(
      'isolates same cookie names by SourceId and blocks stale responses',
      () {
        final manager = SourceSessionManager();
        final old = manager.capture(sourceA);
        manager.logout(sourceA);
        expect(
          manager.commitResponseCookies(
            old,
            origin,
            SourceHttpHeaders(
              values: {
                'set-cookie': ['sid=stale'],
              },
            ),
          ),
          isFalse,
        );
        expect(manager.snapshot(sourceA).generation, 1);
        expect(manager.snapshot(sourceA).cookies, isEmpty);

        final currentA = manager.capture(sourceA);
        final currentB = manager.capture(sourceB);
        manager.commitResponseCookies(
          currentA,
          origin,
          SourceHttpHeaders(
            values: {
              'set-cookie': ['sid=A'],
            },
          ),
        );
        manager.commitResponseCookies(
          currentB,
          origin,
          SourceHttpHeaders(
            values: {
              'set-cookie': ['sid=B'],
            },
          ),
        );
        expect(manager.cookieHeader(currentA, origin), 'sid=A');
        expect(manager.cookieHeader(currentB, origin), 'sid=B');
      },
    );

    test('login, expiry and security reset advance generation', () {
      final manager = SourceSessionManager();
      expect(manager.snapshot(sourceA).generation, 0);
      expect(manager.markAuthenticating(sourceA).generation, 1);
      expect(manager.establish(sourceA).generation, 2);
      expect(manager.expire(sourceA).generation, 3);
      expect(manager.securityReset(sourceA).generation, 4);
      expect(
        manager.snapshot(sourceA).authStatus,
        SourceAuthStatus.unauthenticated,
      );
    });
  });

  group('secure credential store', () {
    test('read, overwrite, delete and source isolation', () async {
      final backend = InMemorySecureValueBackend();
      final store = BackendSecureCredentialStore(backend);
      final keyA = SecureStorageKey(sourceId: sourceA, name: 'session');
      final keyB = SecureStorageKey(sourceId: sourceB, name: 'session');
      final secret = SecureValue('TOP_SECRET_SENTINEL_DO_NOT_LOG');
      await store.write(keyA, secret);
      expect((await store.read(keyA))!.value, secret.value);
      expect(await store.read(keyB), isNull);
      await store.write(keyA, SecureValue('replacement'));
      expect((await store.read(keyA))!.value, 'replacement');
      await store.delete(keyA);
      expect(await store.read(keyA), isNull);
      expect(keyA.storageName, isNot(contains(sourceA.value)));
      expect(secret.toString(), isNot(contains('TOP_SECRET')));
    });

    test(
      'backend failures map to secureStorage without plaintext fallback',
      () async {
        final backend = InMemorySecureValueBackend()
          ..failure = SourceFailure(code: SourceFailureCode.network);
        final store = BackendSecureCredentialStore(backend);
        final key = SecureStorageKey(sourceId: sourceA, name: 'session');
        await expectLater(
          store.write(key, SecureValue('TOP_SECRET_SENTINEL_DO_NOT_LOG')),
          throwsA(
            isA<SourceFailure>().having(
              (failure) => failure.code,
              'code',
              SourceFailureCode.secureStorage,
            ),
          ),
        );
        expect(backend.values, isEmpty);
        try {
          await store.read(key);
        } on SourceFailure catch (failure) {
          expect(failure.toString(), isNot(contains('TOP_SECRET')));
        }
      },
    );

    test('secure keys and failure output remain non-secret', () {
      final key = SecureStorageKey(sourceId: sourceA, name: 'session');
      final failure = SourceFailure(code: SourceFailureCode.secureStorage);
      expect(key.toString(), isNot(contains(sourceA.value)));
      expect(failure.toString(), isNot(contains('session')));
      expect(failure.toString(), isNot(contains('TOP_SECRET')));
    });
  });

  test('approved dependency imports stay behind infrastructure boundaries', () {
    final sourceRoot = Directory('lib/src');
    final dartFiles = sourceRoot
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    for (final file in dartFiles) {
      final content = file.readAsStringSync();
      if (content.contains("package:dio/")) {
        expect(
          file.path.replaceAll('\\', '/'),
          contains('lib/src/data/source_runtime/dio_source_transport.dart'),
        );
      }
      if (content.contains("package:flutter_secure_storage/")) {
        expect(
          file.path.replaceAll('\\', '/'),
          contains(
            'lib/src/data/source_runtime/flutter_secure_credential_store.dart',
          ),
        );
      }
      expect(content, isNot(contains('package:http/')));
      expect(content, isNot(contains('cookie_jar')));
      expect(content, isNot(contains('dio_cookie_manager')));
    }
  });
}

typedef AdapterHandler = Future<ResponseBody> Function(
  RequestOptions options,
  Stream<Uint8List>? requestStream,
  Future<void>? cancelFuture,
);

final class ScriptedAdapter implements HttpClientAdapter {
  ScriptedAdapter(this.handler);

  final AdapterHandler handler;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    calls++;
    return handler(options, requestStream, cancelFuture);
  }

  @override
  void close({bool force = false}) {}
}
