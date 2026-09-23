import 'dart:convert';

import '../../domain/identity/opaque_ids.dart';
import '../../source/security/secure_value.dart';
import '../../source/session/source_authentication_coordinator.dart';
import '../../source/session/source_cookie.dart';
import '../../source/session/source_session_manager.dart';
import '../../source/source_auth.dart';
import '../../source/source_continuation.dart';
import '../../source/source_diagnostics.dart';
import '../../source/source_failure.dart';
import '../../source/source_operation.dart';
import '../../source/transport/source_http_models.dart';
import '../../source/transport/source_transport.dart';
import '../../source/transport/source_transport_policy.dart';

final _sourceId = SourceId('builtin.wenku8');

/// Explicit, memory-only Wenku8 credentials. Passwords and session cookies
/// are never persisted or included in diagnostics by this adapter.
final class Wenku8Credentials implements SourceCredential {
  const Wenku8Credentials({required this.username, required this.password});

  final SecureValue username;
  final SecureValue password;

  @override
  String toString() => 'Wenku8Credentials(<redacted>)';
}

final class Wenku8Authenticator implements SourceAuthenticator {
  Wenku8Authenticator({
    required this.transport,
    required this.sessions,
    SourceAuthenticationCoordinator? coordinator,
  }) : coordinator = coordinator ?? SourceAuthenticationCoordinator();

  final SourceTransport transport;
  final SourceSessionManager sessions;
  final SourceAuthenticationCoordinator coordinator;

  @override
  SourceId get sourceId => _sourceId;

  @override
  Future<SourceAuthState> signIn(
    SourceCredential credential,
    SourceOperationContext context,
  ) async {
    _checkContext(context);
    if (credential is! Wenku8Credentials) throw SourceFailure.invalidRequest();
    return coordinator.run(_sourceId, context.cancellation, () async {
      _checkContext(context);
      if (sessions.snapshot(_sourceId).generation !=
          context.sessionGeneration) {
        throw SourceFailure.cancelled();
      }
      final pending = sessions.markAuthenticating(_sourceId);
      final binding = sessions.capture(_sourceId);
      try {
        final request = _buildRequest(credential, context, binding.generation);
        final response = await transport.send(request);
        context.requireActive();
        if (!sessions.isCurrent(binding)) throw SourceFailure.cancelled();
        if (response.finalUri.scheme != 'https' ||
            response.finalUri.host != 'www.wenku8.net' ||
            response.finalUri.userInfo.isNotEmpty) {
          throw SourceFailure(code: SourceFailureCode.securityPolicy);
        }
        if (response.statusCode == 429) {
          throw SourceFailure(
            code: SourceFailureCode.rateLimit,
            diagnostics: SourceFailureDiagnostics(
              operation: SourceOperation.authentication,
              statusCode: response.statusCode,
            ),
          );
        }
        if (response.statusCode >= 500) {
          throw SourceFailure(
            code: SourceFailureCode.network,
            diagnostics: SourceFailureDiagnostics(
              operation: SourceOperation.authentication,
              statusCode: response.statusCode,
            ),
          );
        }
        if (response.statusCode != 200 &&
            response.statusCode != 302 &&
            response.statusCode != 303) {
          throw SourceFailure(code: SourceFailureCode.authentication);
        }
        final body = latin1.decode(response.bodyBytes).toLowerCase();
        if (body.contains('challenge') ||
            body.contains('just a moment') ||
            body.contains('access denied')) {
          throw SourceFailure(code: SourceFailureCode.incompatibleResponse);
        }
        final cookies = <SourceCookie>[];
        for (final header in response.headers.valuesFor('set-cookie')) {
          try {
            final cookie = SourceCookie.parseSetCookie(
              _sourceId,
              header,
              response.finalUri,
            );
            if (cookie != null && !cookie.isExpired()) cookies.add(cookie);
          } on ArgumentError {
            // A malformed field is never promoted to session authority.
          }
        }
        if (!cookies.any((cookie) => cookie.name == 'jieqiUserInfo')) {
          throw SourceFailure(code: SourceFailureCode.authentication);
        }
        context.requireActive();
        if (!sessions.isCurrent(binding)) throw SourceFailure.cancelled();
        return SourceAuthState(
          sessions.establish(_sourceId, cookies: cookies).authStatus,
        );
      } on SourceFailure {
        if (sessions.isCurrent(binding)) sessions.logout(_sourceId);
        rethrow;
      } catch (_) {
        if (sessions.isCurrent(binding)) sessions.logout(_sourceId);
        throw SourceFailure(code: SourceFailureCode.network);
      } finally {
        // Keep the captured generation in use only during this one operation.
        assert(pending.generation == binding.generation);
      }
    });
  }

  @override
  Future<SourceAuthState> status(SourceOperationContext context) async {
    _checkContext(context);
    final snapshot = sessions.snapshot(_sourceId);
    if (snapshot.generation != context.sessionGeneration) {
      throw SourceFailure.cancelled();
    }
    return SourceAuthState(snapshot.authStatus);
  }

  @override
  Future<SourceAuthState> signOut(SourceOperationContext context) async {
    _checkContext(context);
    return SourceAuthState(sessions.logout(_sourceId).authStatus);
  }

  void _checkContext(SourceOperationContext context) {
    context.requireOperation(SourceOperation.authentication);
    context.requireActive();
    if (context.sourceId != _sourceId) throw SourceFailure.invalidRequest();
  }

  SourceHttpRequest _buildRequest(
    Wenku8Credentials credential,
    SourceOperationContext context,
    int generation,
  ) {
    final body = [
      'username=${Uri.encodeQueryComponent(credential.username.value)}',
      'password=${Uri.encodeQueryComponent(credential.password.value)}',
      'action=login',
      'usecookie=31536000',
      'submit=jumpurl',
    ].join('&');
    return SourceHttpRequest(
      sourceId: _sourceId,
      operation: SourceOperation.authentication,
      method: SourceHttpMethod.post,
      uri: Uri.parse('https://www.wenku8.net/login.php?do=submit'),
      headers: SourceHttpHeaders.fromSingleValue({
        'content-type': 'application/x-www-form-urlencoded',
      }),
      bodyBytes: utf8.encode(body),
      policy: SourceTransportPolicy(
        redirects: const SourceRedirectPolicy.noFollow(),
        maxResponseBytes: 128 * 1024,
      ),
      cancellation: context.cancellation,
      sessionGeneration: generation,
      // No binding: login is a clean POST and may not carry old cookies.
    );
  }
}
