import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_reader/src/data/source_runtime/dio_source_transport.dart';
import 'package:light_novel_reader/src/domain/identity/opaque_ids.dart';
import 'package:light_novel_reader/src/source/source.dart';

void main() {
  final secretSentinel =
      'TOP_SECRET_SENTINEL_${DateTime.now().microsecondsSinceEpoch}';
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
    SourceSessionBinding? binding,
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
    sessionBinding: binding,
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

    test(
      'uses bounded Retry-After seconds for replay-safe 429 responses',
      () async {
        final times = <DateTime>[];
        final adapter = ScriptedAdapter((_, _, _) async {
          times.add(DateTime.now());
          return ResponseBody.fromBytes(
            [],
            times.length == 1 ? 429 : 200,
            headers: times.length == 1
                ? {
                    'retry-after': ['1'],
                  }
                : const {},
          );
        });
        final started = DateTime.now();
        final response = await DioSourceTransport(adapter: adapter).send(
          request(
            policy: SourceTransportPolicy(
              timeout: SourceTimeoutPolicy(
                operation: const Duration(seconds: 3),
              ),
              retry: SourceRetryPolicy(
                maxAttempts: 2,
                baseDelay: Duration.zero,
                maxDelay: const Duration(seconds: 2),
              ),
            ),
          ),
        );
        expect(response.statusCode, 200);
        expect(times, hasLength(2));
        expect(
          times[1].difference(started),
          greaterThanOrEqualTo(const Duration(milliseconds: 800)),
        );
      },
    );

    test(
      'malformed and huge Retry-After values stay within finite backoff',
      () async {
        var calls = 0;
        final adapter = ScriptedAdapter((_, _, _) async {
          calls++;
          return ResponseBody.fromBytes(
            [],
            429,
            headers: {
              'retry-after': [
                calls == 1 ? 'not-a-delay' : '999999999999999999999',
              ],
            },
          );
        });
        final response = await DioSourceTransport(adapter: adapter).send(
          request(
            policy: SourceTransportPolicy(
              timeout: SourceTimeoutPolicy(
                operation: const Duration(seconds: 1),
              ),
              retry: SourceRetryPolicy(
                maxAttempts: 2,
                baseDelay: Duration.zero,
                maxDelay: const Duration(milliseconds: 20),
              ),
            ),
          ),
        );
        expect(response.statusCode, 429);
        expect(calls, 2);
      },
    );

    test(
      'operation deadline includes retry backoff and prevents next I/O',
      () async {
        final cancellation = SourceCancellation();
        var calls = 0;
        final adapter = ScriptedAdapter((_, _, _) async {
          calls++;
          return ResponseBody.fromBytes([], 503);
        });
        final started = Stopwatch()..start();
        await expectLater(
          DioSourceTransport(adapter: adapter).send(
            request(
              cancellation: cancellation,
              policy: SourceTransportPolicy(
                timeout: SourceTimeoutPolicy(
                  operation: const Duration(milliseconds: 100),
                ),
                retry: SourceRetryPolicy(
                  maxAttempts: 3,
                  baseDelay: const Duration(seconds: 5),
                  maxDelay: const Duration(seconds: 5),
                ),
              ),
            ),
          ),
          throwsA(
            isA<SourceFailure>().having(
              (failure) => failure.code,
              'code',
              SourceFailureCode.network,
            ),
          ),
        );
        expect(started.elapsed, lessThan(const Duration(seconds: 1)));
        expect(calls, 1);
      },
    );

    test(
      'explicit cancellation during retry backoff remains cancelled',
      () async {
        final cancellation = SourceCancellation();
        final started = Completer<void>();
        final adapter = ScriptedAdapter((_, _, _) async {
          started.complete();
          return ResponseBody.fromBytes([], 503);
        });
        final future = DioSourceTransport(adapter: adapter).send(
          request(
            cancellation: cancellation,
            policy: SourceTransportPolicy(
              retry: SourceRetryPolicy(
                maxAttempts: 2,
                baseDelay: const Duration(seconds: 5),
                maxDelay: const Duration(seconds: 5),
              ),
            ),
          ),
        );
        await started.future;
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
      },
    );

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
              'Authorization': 'Bearer $secretSentinel',
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
        expect(response.toString(), isNot(contains(secretSentinel)));
      },
    );

    test('rejects caller Cookie headers at the neutral request boundary', () {
      expect(
        () => request(
          headers: SourceHttpHeaders.fromSingleValue({'Cookie': 'sid=manual'}),
        ),
        throwsArgumentError,
      );
    });

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

    test('redirect history strips query secrets from safe metadata', () async {
      final adapter = ScriptedAdapter((options, _, _) async {
        if (options.uri.path == '/start') {
          return ResponseBody.fromBytes(
            [],
            302,
            headers: {
              'location': ['/next?token=$secretSentinel#fragment'],
            },
          );
        }
        return ResponseBody.fromBytes([], 200);
      });
      final response = await DioSourceTransport(adapter: adapter).send(
        request(
          uri: Uri.parse('https://alpha.invalid/start'),
          policy: SourceTransportPolicy(
            redirects: SourceRedirectPolicy.follow(),
          ),
        ),
      );
      expect(response.redirectHistory.single.uri.query, isEmpty);
      expect(response.redirectHistory.single.uri.fragment, isEmpty);
      expect(
        response.redirectHistory.single.toString(),
        isNot(contains(secretSentinel)),
      );
      expect(response.toString(), isNot(contains(secretSentinel)));
    });

    test(
      'same-origin redirect recomputes cookies from the session authority',
      () async {
        final manager = SourceSessionManager();
        final binding = manager.capture(sourceA);
        final seen = <RequestOptions>[];
        final adapter = ScriptedAdapter((options, _, _) async {
          seen.add(options);
          if (options.uri.path == '/start') {
            return ResponseBody.fromBytes(
              [],
              302,
              headers: {
                'set-cookie': ['first=one; Path=/'],
                'location': ['/middle'],
              },
            );
          }
          return ResponseBody.fromBytes([], 200);
        });
        final response =
            await DioSourceTransport(
              adapter: adapter,
              sessionAuthority: manager,
            ).send(
              request(
                uri: Uri.parse('https://alpha.invalid/start'),
                binding: binding,
                policy: SourceTransportPolicy(
                  redirects: SourceRedirectPolicy.follow(),
                ),
              ),
            );
        expect(response.statusCode, 200);
        expect(seen[1].headers['cookie'], 'first=one');
      },
    );

    test(
      'multi-hop and approved cross-origin redirects recompute cookies',
      () async {
        final manager = SourceSessionManager();
        final binding = manager.capture(sourceA);
        final seen = <RequestOptions>[];
        final adapter = ScriptedAdapter((options, _, _) async {
          seen.add(options);
          switch (options.uri.path) {
            case '/start':
              return ResponseBody.fromBytes(
                [],
                302,
                headers: {
                  'set-cookie': ['alpha=one; Path=/'],
                  'location': ['https://beta.invalid/middle'],
                },
              );
            case '/middle':
              return ResponseBody.fromBytes(
                [],
                302,
                headers: {
                  'set-cookie': ['beta=two; Domain=beta.invalid; Path=/'],
                  'location': ['https://beta.invalid/final'],
                },
              );
            default:
              return ResponseBody.fromBytes([], 200);
          }
        });
        final response =
            await DioSourceTransport(
              adapter: adapter,
              sessionAuthority: manager,
            ).send(
              request(
                uri: Uri.parse('https://alpha.invalid/start'),
                binding: binding,
                policy: SourceTransportPolicy(
                  redirects: SourceRedirectPolicy.follow(
                    allowedOrigins: {'https://beta.invalid'},
                  ),
                ),
              ),
            );
        expect(response.statusCode, 200);
        expect(seen[1].headers['cookie'], isNull);
        expect(seen[2].headers['cookie'], 'beta=two');
      },
    );

    test(
      'stale redirect response cannot install cookies or publish final data',
      () async {
        final manager = SourceSessionManager();
        final binding = manager.capture(sourceA);
        final adapter = ScriptedAdapter((_, _, _) async {
          manager.logout(sourceA);
          return ResponseBody.fromBytes(
            [],
            302,
            headers: {
              'set-cookie': ['stale=secret; Path=/'],
              'location': ['/final'],
            },
          );
        });
        await expectLater(
          DioSourceTransport(adapter: adapter, sessionAuthority: manager).send(
            request(
              binding: binding,
              policy: SourceTransportPolicy(
                redirects: SourceRedirectPolicy.follow(),
              ),
            ),
          ),
          throwsA(
            isA<SourceFailure>().having(
              (failure) => failure.code,
              'code',
              SourceFailureCode.cancelled,
            ),
          ),
        );
        final current = manager.capture(sourceA);
        expect(manager.cookieHeader(current, origin), isNull);
      },
    );
  });

  group('transport capacity', () {
    test('bounds simultaneous adapter calls and releases permits', () async {
      final entered = <Completer<void>>[];
      final twoEntered = Completer<void>();
      var active = 0;
      var maximum = 0;
      final adapter = ScriptedAdapter((_, _, _) async {
        active++;
        maximum = maximum < active ? active : maximum;
        if (active == 2) twoEntered.complete();
        final release = Completer<void>();
        entered.add(release);
        await release.future;
        active--;
        return ResponseBody.fromBytes([], 200);
      });
      final policy = SourceTransportPolicy(
        capacity: SourceTransportCapacityPolicy(
          maxConcurrentRequests: 2,
          maxQueuedRequests: 2,
        ),
      );
      final transport = DioSourceTransport(adapter: adapter);
      final futures = [
        transport.send(request(policy: policy)),
        transport.send(request(policy: policy)),
      ];
      await twoEntered.future;
      expect(maximum, 2);
      for (final release in entered) {
        release.complete();
      }
      await Future.wait(futures);
      expect(maximum, 2);
    });

    test('queued work is FIFO, cancellable and bounded', () async {
      final firstEntered = Completer<void>();
      final releaseFirst = Completer<void>();
      var calls = 0;
      final adapter = ScriptedAdapter((_, _, _) async {
        calls++;
        if (calls == 1) {
          firstEntered.complete();
          await releaseFirst.future;
        }
        return ResponseBody.fromBytes([], 200);
      });
      final policy = SourceTransportPolicy(
        capacity: SourceTransportCapacityPolicy(
          maxConcurrentRequests: 1,
          maxQueuedRequests: 1,
        ),
      );
      final transport = DioSourceTransport(adapter: adapter);
      final first = transport.send(request(policy: policy));
      await firstEntered.future;
      final cancelled = SourceCancellation()..cancel();
      final second = transport.send(
        request(policy: policy, cancellation: cancelled),
      );
      await expectLater(second, throwsA(isA<SourceFailure>()));
      releaseFirst.complete();
      await first;
      expect(calls, 1);
    });

    test('queue overflow is typed and performs no I/O', () async {
      final release = Completer<void>();
      final firstStarted = Completer<void>();
      var calls = 0;
      final adapter = ScriptedAdapter((_, _, _) async {
        calls++;
        if (calls == 1) firstStarted.complete();
        await release.future;
        return ResponseBody.fromBytes([], 200);
      });
      final policy = SourceTransportPolicy(
        timeout: SourceTimeoutPolicy(
          operation: const Duration(milliseconds: 500),
        ),
        capacity: SourceTransportCapacityPolicy(
          maxConcurrentRequests: 1,
          maxQueuedRequests: 1,
        ),
      );
      final transport = DioSourceTransport(adapter: adapter);
      final first = transport.send(request(policy: policy));
      await firstStarted.future;
      final second = transport.send(request(policy: policy));
      final third = transport.send(request(policy: policy));
      await expectLater(
        third,
        throwsA(
          isA<SourceFailure>().having(
            (failure) => failure.code,
            'code',
            SourceFailureCode.network,
          ),
        ),
      );
      release.complete();
      await first;
      await second;
      expect(calls, 2);
    });

    test('operation deadline can expire while waiting for a permit', () async {
      final release = Completer<void>();
      final started = Completer<void>();
      var calls = 0;
      final adapter = ScriptedAdapter((_, _, _) async {
        calls++;
        started.complete();
        await release.future;
        return ResponseBody.fromBytes([], 200);
      });
      final capacity = SourceTransportCapacityPolicy(
        maxConcurrentRequests: 1,
        maxQueuedRequests: 1,
      );
      final longPolicy = SourceTransportPolicy(capacity: capacity);
      final shortPolicy = SourceTransportPolicy(
        timeout: SourceTimeoutPolicy(operation: Duration(milliseconds: 30)),
        capacity: capacity,
      );
      final transport = DioSourceTransport(adapter: adapter);
      final first = transport.send(request(policy: longPolicy));
      await started.future;
      final queued = transport.send(request(policy: shortPolicy));
      await expectLater(
        queued,
        throwsA(
          isA<SourceFailure>().having(
            (failure) => failure.code,
            'code',
            SourceFailureCode.network,
          ),
        ),
      );
      release.complete();
      await first;
      expect(calls, 1);
    });
  });

  group('authentication coordination', () {
    test(
      'serializes one Source while allowing another Source concurrently',
      () async {
        final coordinator = SourceAuthenticationCoordinator();
        final releaseA = Completer<void>();
        final startedA = Completer<void>();
        var activeA = 0;
        final firstA = coordinator.run(sourceA, SourceCancellation(), () async {
          activeA++;
          startedA.complete();
          await releaseA.future;
          activeA--;
          return 'a1';
        });
        await startedA.future;
        var secondStarted = false;
        final secondA = coordinator.run(
          sourceA,
          SourceCancellation(),
          () async {
            secondStarted = true;
            return 'a2';
          },
        );
        final sourceBResult = coordinator.run(
          sourceB,
          SourceCancellation(),
          () async => 'b',
        );
        await Future<void>.delayed(Duration.zero);
        expect(secondStarted, isFalse);
        expect(await sourceBResult, 'b');
        releaseA.complete();
        expect(await firstA, 'a1');
        expect(await secondA, 'a2');
        expect(activeA, 0);
      },
    );

    test(
      'queued authentication cancellation and failure release the gate',
      () async {
        final coordinator = SourceAuthenticationCoordinator(
          maxWait: const Duration(seconds: 1),
        );
        final release = Completer<void>();
        final started = Completer<void>();
        final first = coordinator.run(sourceA, SourceCancellation(), () async {
          started.complete();
          await release.future;
          throw StateError('expected');
        });
        await started.future;
        final cancelled = SourceCancellation()..cancel();
        final queued = coordinator.run(sourceA, cancelled, () async => 'never');
        await expectLater(queued, throwsA(isA<SourceFailure>()));
        release.complete();
        await expectLater(first, throwsA(isA<StateError>()));
        expect(
          await coordinator.run(
            sourceA,
            SourceCancellation(),
            () async => 'ok',
          ),
          'ok',
        );
      },
    );
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

    test('host-only and domain variants replace one cookie identity', () {
      final manager = SourceSessionManager();
      final binding = manager.capture(sourceA);
      manager.commitResponseCookies(
        binding,
        origin,
        SourceHttpHeaders(
          values: {
            'set-cookie': ['sid=old; Path=/'],
          },
        ),
      );
      manager.commitResponseCookies(
        binding,
        origin,
        SourceHttpHeaders(
          values: {
            'set-cookie': ['sid=new; Domain=alpha.invalid; Path=/'],
          },
        ),
      );
      expect(manager.cookieHeader(binding, origin), 'sid=new');

      manager.commitResponseCookies(
        binding,
        origin,
        SourceHttpHeaders(
          values: {
            'set-cookie': ['sid=domain; Domain=alpha.invalid; Path=/'],
          },
        ),
      );
      manager.commitResponseCookies(
        binding,
        origin,
        SourceHttpHeaders(
          values: {
            'set-cookie': ['sid=host; Path=/'],
          },
        ),
      );
      expect(manager.cookieHeader(binding, origin), 'sid=host');
      expect(manager.snapshot(sourceA).cookies, hasLength(1));
      expect(manager.snapshot(sourceB).cookies, isEmpty);
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
      final secret = SecureValue(secretSentinel);
      await store.write(keyA, secret);
      expect((await store.read(keyA))!.value, secret.value);
      expect(await store.read(keyB), isNull);
      await store.write(keyA, SecureValue('replacement'));
      expect((await store.read(keyA))!.value, 'replacement');
      await store.delete(keyA);
      expect(await store.read(keyA), isNull);
      expect(keyA.storageName, isNot(contains(sourceA.value)));
      expect(secret.toString(), isNot(contains(secretSentinel)));
    });

    test(
      'backend failures map to secureStorage without plaintext fallback',
      () async {
        final backend = InMemorySecureValueBackend()
          ..failure = SourceFailure(code: SourceFailureCode.network);
        final store = BackendSecureCredentialStore(backend);
        final key = SecureStorageKey(sourceId: sourceA, name: 'session');
        await expectLater(
          store.write(key, SecureValue(secretSentinel)),
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
          expect(failure.toString(), isNot(contains(secretSentinel)));
        }
      },
    );

    test('secure keys and failure output remain non-secret', () {
      final key = SecureStorageKey(sourceId: sourceA, name: 'session');
      final failure = SourceFailure(code: SourceFailureCode.secureStorage);
      expect(key.toString(), isNot(contains(sourceA.value)));
      expect(failure.toString(), isNot(contains('session')));
      expect(failure.toString(), isNot(contains(secretSentinel)));
    });

    test(
      'remembered session survives coordinator recreation and clears',
      () async {
        final backend = InMemorySecureValueBackend();
        final store = BackendSecureCredentialStore(backend);
        final first = RememberedSessionStore(store: store, sourceId: sourceA);
        await first.remember(SecureValue(secretSentinel));
        final recreated = RememberedSessionStore(
          store: store,
          sourceId: sourceA,
        );
        expect((await recreated.restore())!.value, secretSentinel);
        await recreated.clear();
        final afterClear = RememberedSessionStore(
          store: store,
          sourceId: sourceA,
        );
        expect(await afterClear.restore(), isNull);
        final otherSource = RememberedSessionStore(
          store: store,
          sourceId: sourceB,
        );
        expect(await otherSource.restore(), isNull);
      },
    );

    test(
      'remembered-session delete failure blocks same-process restore',
      () async {
        final backend = InMemorySecureValueBackend();
        final store = BackendSecureCredentialStore(backend);
        final coordinator = RememberedSessionStore(
          store: store,
          sourceId: sourceA,
        );
        await coordinator.remember(SecureValue(secretSentinel));
        backend.failure = SourceFailure(code: SourceFailureCode.network);
        await expectLater(coordinator.clear(), throwsA(isA<SourceFailure>()));
        await expectLater(coordinator.restore(), throwsA(isA<SourceFailure>()));
        final recreated = RememberedSessionStore(
          store: store,
          sourceId: sourceA,
        );
        await expectLater(recreated.restore(), throwsA(isA<SourceFailure>()));
        expect(coordinator.toString(), isNot(contains(secretSentinel)));
      },
    );
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
