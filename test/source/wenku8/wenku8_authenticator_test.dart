import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_reader/src/domain/identity/opaque_ids.dart';
import 'package:light_novel_reader/src/source/source.dart';
import 'package:light_novel_reader/src/sources/wenku8/wenku8.dart';

void main() {
  final sourceId = SourceId('builtin.wenku8');
  final credential = Wenku8Credentials(
    username: SecureValue('SYNTHETIC_USER'),
    password: SecureValue('SYNTHETIC_PASSWORD'),
  );

  SourceOperationContext context(SourceSessionManager sessions) =>
      SourceOperationContext(
        sourceId: sourceId,
        operation: SourceOperation.authentication,
        sessionGeneration: sessions.snapshot(sourceId).generation,
        cancellation: SourceCancellation(),
      );

  SourceHttpResponse response(
    SourceHttpRequest request, {
    int status = 302,
    List<String> cookies = const [],
    String body = '',
  }) => SourceHttpResponse(
    statusCode: status,
    headers: SourceHttpHeaders(values: {'set-cookie': cookies}),
    bodyBytes: utf8.encode(body),
    finalUri: request.uri,
  );

  test(
    'explicit login establishes only verified source-scoped cookies',
    () async {
      final sessions = SourceSessionManager();
      final transport = _AuthTransport(
        (request) async => response(
          request,
          cookies: [
            'PHPSESSID=SYNTHETIC_SESSION; Path=/; Secure',
            'jieqiUserInfo=SYNTHETIC_USER_INFO; Path=/; Secure',
          ],
        ),
      );
      final auth = Wenku8Authenticator(
        transport: transport,
        sessions: sessions,
      );
      final state = await auth.signIn(credential, context(sessions));
      expect(state.status, SourceAuthStatus.authenticated);
      final request = transport.requests.single;
      expect(request.method, SourceHttpMethod.post);
      expect(
        request.uri.toString(),
        'https://www.wenku8.net/login.php?do=submit',
      );
      expect(request.sessionBinding, isNull);
      expect(request.headers.contains('cookie'), false);
      expect(request.policy.redirects.mode, SourceRedirectMode.noFollow);
      expect(
        utf8.decode(request.bodyBytes!),
        contains('password=SYNTHETIC_PASSWORD'),
      );
      expect(request.toString(), isNot(contains('SYNTHETIC_PASSWORD')));
      expect(credential.toString(), isNot(contains('SYNTHETIC_PASSWORD')));
      expect(
        sessions.cookieHeader(
          sessions.capture(sourceId),
          Uri.parse('https://www.wenku8.net/book/1.htm'),
        ),
        contains('jieqiUserInfo=SYNTHETIC_USER_INFO'),
      );
      expect(
        sessions.cookieHeader(
          sessions.capture(sourceId),
          Uri.parse('https://www.wenku8.cc/book/1.htm'),
        ),
        isNull,
      );
      expect((await auth.status(context(sessions))).isAuthenticated, true);
      expect(
        (await auth.signOut(context(sessions))).status,
        SourceAuthStatus.unauthenticated,
      );
      expect(sessions.snapshot(sourceId).cookies, isEmpty);
    },
  );

  test('PHPSESSID alone and rejected form do not authenticate', () async {
    for (final cookies in [
      ['PHPSESSID=SYNTHETIC_SESSION; Path=/'],
      <String>[],
    ]) {
      final sessions = SourceSessionManager();
      final transport = _AuthTransport(
        (request) async => response(
          request,
          status: cookies.isEmpty ? 200 : 302,
          cookies: cookies,
          body: cookies.isEmpty ? '<form>login failed</form>' : '',
        ),
      );
      final auth = Wenku8Authenticator(
        transport: transport,
        sessions: sessions,
      );
      await expectLater(
        auth.signIn(credential, context(sessions)),
        throwsA(
          isA<SourceFailure>().having(
            (failure) => failure.code,
            'code',
            SourceFailureCode.authentication,
          ),
        ),
      );
      expect(
        sessions.snapshot(sourceId).authStatus,
        SourceAuthStatus.unauthenticated,
      );
      expect(sessions.snapshot(sourceId).cookies, isEmpty);
    }
  });

  test('HTTP 200 challenge remains incompatible response', () async {
    final sessions = SourceSessionManager();
    final auth = Wenku8Authenticator(
      sessions: sessions,
      transport: _AuthTransport(
        (request) async => response(
          request,
          status: 200,
          body: '<html><title>Just a moment...</title><p>challenge</p></html>',
        ),
      ),
    );
    await expectLater(
      auth.signIn(credential, context(sessions)),
      throwsA(
        isA<SourceFailure>().having(
          (failure) => failure.code,
          'code',
          SourceFailureCode.incompatibleResponse,
        ),
      ),
    );
  });

  test(
    'logout invalidates an in-flight login before cookies can commit',
    () async {
      final sessions = SourceSessionManager();
      final pendingResponse = Completer<SourceHttpResponse>();
      final transport = _AuthTransport((_) => pendingResponse.future);
      final auth = Wenku8Authenticator(
        transport: transport,
        sessions: sessions,
      );
      final pending = auth.signIn(credential, context(sessions));
      // The coordinator enters asynchronously; allow the request to start.
      await Future<void>.delayed(Duration.zero);
      expect(transport.requests.length, 1);
      await auth.signOut(context(sessions));
      pendingResponse.complete(
        response(
          transport.requests.single,
          cookies: ['jieqiUserInfo=SYNTHETIC_USER_INFO; Path=/'],
        ),
      );
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
      expect(
        sessions.snapshot(sourceId).authStatus,
        SourceAuthStatus.unauthenticated,
      );
      expect(sessions.snapshot(sourceId).cookies, isEmpty);
    },
  );
}

final class _AuthTransport implements SourceTransport {
  _AuthTransport(this.handler);

  final Future<SourceHttpResponse> Function(SourceHttpRequest request) handler;
  final List<SourceHttpRequest> requests = [];

  @override
  Future<SourceHttpResponse> send(SourceHttpRequest request) {
    requests.add(request);
    return handler(request);
  }
}
