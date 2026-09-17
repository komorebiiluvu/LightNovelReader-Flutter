import '../source_auth.dart';
import '../source_failure.dart';
import '../transport/source_http_models.dart';
import 'source_cookie.dart';
import 'source_session.dart';
import '../../domain/identity/opaque_ids.dart';

/// The single application-owned, source-scoped session authority.
final class SourceSessionManager {
  final Map<SourceId, _MutableSession> _sessions =
      <SourceId, _MutableSession>{};
  DateTime Function() now = () => DateTime.now().toUtc();

  SourceSessionSnapshot snapshot(SourceId sourceId) =>
      _session(sourceId).snapshot();

  SourceSessionBinding capture(SourceId sourceId) {
    final session = _session(sourceId);
    return SourceSessionBinding(
      sourceId: sourceId,
      generation: session.generation,
    );
  }

  bool isCurrent(SourceSessionBinding binding) =>
      _session(binding.sourceId).generation == binding.generation;

  /// Establishes a new session generation and replaces any previous cookies.
  SourceSessionSnapshot establish(
    SourceId sourceId, {
    Iterable<SourceCookie> cookies = const [],
  }) {
    final session = _session(sourceId);
    session.advance(clearCookies: true, status: SourceAuthStatus.authenticated);
    for (final cookie in cookies) {
      if (cookie.sourceId != sourceId) throw SourceFailure.invalidRequest();
      session.put(cookie);
    }
    return session.snapshot();
  }

  SourceSessionSnapshot markAuthenticating(SourceId sourceId) {
    final session = _session(sourceId);
    session.advance(
      clearCookies: true,
      status: SourceAuthStatus.authenticating,
    );
    return session.snapshot();
  }

  SourceSessionSnapshot logout(SourceId sourceId) =>
      _advanceTo(sourceId, SourceAuthStatus.unauthenticated);

  SourceSessionSnapshot expire(SourceId sourceId) =>
      _advanceTo(sourceId, SourceAuthStatus.expired);

  SourceSessionSnapshot securityReset(SourceId sourceId) =>
      _advanceTo(sourceId, SourceAuthStatus.unauthenticated);

  /// Commits repeated Set-Cookie fields only for the captured generation.
  /// Returns false when the response is stale and therefore ignored.
  bool commitResponseCookies(
    SourceSessionBinding binding,
    Uri responseUri,
    SourceHttpHeaders headers,
  ) {
    final session = _session(binding.sourceId);
    if (session.generation != binding.generation) return false;
    for (final header in headers.valuesFor('set-cookie')) {
      final cookie = SourceCookie.parseSetCookie(
        binding.sourceId,
        header,
        responseUri,
        now: now(),
      );
      if (cookie == null) continue;
      if (cookie.isExpired(now())) {
        session.remove(cookie.identityKey);
      } else {
        session.put(cookie);
      }
    }
    return true;
  }

  bool commitResponse(
    SourceSessionBinding binding,
    SourceHttpResponse response,
  ) => commitResponseCookies(binding, response.finalUri, response.headers);

  String? cookieHeader(SourceSessionBinding binding, Uri requestUri) {
    final session = _session(binding.sourceId);
    if (session.generation != binding.generation) {
      throw SourceFailure.invalidRequest();
    }
    session.removeExpired(now());
    return session.snapshot().cookieHeaderFor(requestUri, now: now());
  }

  _MutableSession _session(SourceId sourceId) =>
      _sessions.putIfAbsent(sourceId, () => _MutableSession(sourceId));

  SourceSessionSnapshot _advanceTo(SourceId sourceId, SourceAuthStatus status) {
    final session = _session(sourceId);
    session.advance(clearCookies: true, status: status);
    return session.snapshot();
  }
}

final class _MutableSession {
  _MutableSession(this.sourceId);

  final SourceId sourceId;
  int generation = 0;
  SourceAuthStatus status = SourceAuthStatus.unauthenticated;
  final Map<String, SourceCookie> cookies = <String, SourceCookie>{};

  void advance({required bool clearCookies, required SourceAuthStatus status}) {
    generation++;
    this.status = status;
    if (clearCookies) cookies.clear();
  }

  void put(SourceCookie cookie) => cookies[cookie.identityKey] = cookie;

  void remove(String identityKey) => cookies.remove(identityKey);

  void removeExpired(DateTime now) {
    cookies.removeWhere((_, cookie) => cookie.isExpired(now));
  }

  SourceSessionSnapshot snapshot() => SourceSessionSnapshot(
    sourceId: sourceId,
    generation: generation,
    authStatus: status,
    cookies: cookies.values.toList(),
  );
}
