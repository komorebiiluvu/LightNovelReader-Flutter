import '../../domain/identity/opaque_ids.dart';
import '../source_auth.dart';
import 'source_cookie.dart';

/// An immutable request-time view of one Source's session authority.
final class SourceSessionSnapshot {
  SourceSessionSnapshot({
    required this.sourceId,
    required this.generation,
    required this.authStatus,
    required List<SourceCookie> cookies,
  }) : cookies = List<SourceCookie>.unmodifiable(cookies) {
    if (generation < 0) throw ArgumentError.value(generation, 'generation');
  }

  final SourceId sourceId;
  final int generation;
  final SourceAuthStatus authStatus;
  final List<SourceCookie> cookies;

  int get sessionGeneration => generation;

  Iterable<SourceCookie> cookiesFor(Uri uri, {DateTime? now}) =>
      cookies.where((cookie) => cookie.matches(uri, now: now));

  String? cookieHeaderFor(Uri uri, {DateTime? now}) {
    final matching = cookiesFor(uri, now: now).toList()
      ..sort((left, right) {
        final pathOrder = right.path.length.compareTo(left.path.length);
        if (pathOrder != 0) return pathOrder;
        final nameOrder = left.name.compareTo(right.name);
        if (nameOrder != 0) return nameOrder;
        return left.domain.compareTo(right.domain);
      });
    if (matching.isEmpty) return null;
    return matching.map((cookie) => cookie.headerPair).join('; ');
  }

  @override
  String toString() =>
      'SourceSessionSnapshot(${sourceId.runtimeType}(<opaque>), '
      'generation=$generation, cookies=${cookies.length})';
}

/// Captured authority used to conditionally commit response cookies.
final class SourceSessionBinding {
  const SourceSessionBinding({
    required this.sourceId,
    required this.generation,
  });

  final SourceId sourceId;
  final int generation;

  int get sessionGeneration => generation;

  @override
  String toString() =>
      'SourceSessionBinding(${sourceId.runtimeType}(<opaque>), '
      'generation=$generation)';
}
