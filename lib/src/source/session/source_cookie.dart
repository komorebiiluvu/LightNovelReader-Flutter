import '../../domain/identity/opaque_ids.dart';

enum SourceCookieSameSite { lax, strict, none }

/// A source-scoped cookie. The value is intentionally redacted from output.
final class SourceCookie {
  SourceCookie({
    required this.sourceId,
    required this.name,
    required this.value,
    required this.domain,
    this.hostOnly = true,
    this.path = '/',
    this.secure = false,
    this.httpOnly = false,
    this.expires,
    this.sameSite,
  }) {
    if (name.isEmpty || name.contains(RegExp(r'[()<>@,;:\\"/\[\]?={}\s]'))) {
      throw ArgumentError.value(name, 'name');
    }
    if (value.contains(RegExp(r'[;\r\n]'))) {
      throw ArgumentError.value(value, 'value');
    }
    if (domain.isEmpty || domain != domain.toLowerCase()) {
      throw ArgumentError.value(domain, 'domain');
    }
    if (!path.startsWith('/')) throw ArgumentError.value(path, 'path');
  }

  final SourceId sourceId;
  final String name;
  final String value;
  final String domain;
  final bool hostOnly;
  final String path;
  final bool secure;
  final bool httpOnly;
  final DateTime? expires;
  final SourceCookieSameSite? sameSite;

  bool isExpired([DateTime? now]) {
    final expiry = expires;
    return expiry != null && !expiry.isAfter(now ?? DateTime.now().toUtc());
  }

  bool matches(Uri uri, {DateTime? now}) {
    if (isExpired(now)) return false;
    if (secure && uri.scheme.toLowerCase() != 'https') return false;
    final host = uri.host.toLowerCase();
    if (hostOnly
        ? host != domain
        : !(host == domain || host.endsWith('.$domain'))) {
      return false;
    }
    return _pathMatches(uri.path.isEmpty ? '/' : uri.path, path);
  }

  String get identityKey =>
      '${sourceId.value}\u0000$name\u0000$domain\u0000$path\u0000$hostOnly';

  String get headerPair => '$name=$value';

  SourceCookie copyWith({
    String? value,
    String? domain,
    bool? hostOnly,
    String? path,
    bool? secure,
    bool? httpOnly,
    DateTime? expires,
    SourceCookieSameSite? sameSite,
  }) => SourceCookie(
    sourceId: sourceId,
    name: name,
    value: value ?? this.value,
    domain: domain ?? this.domain,
    hostOnly: hostOnly ?? this.hostOnly,
    path: path ?? this.path,
    secure: secure ?? this.secure,
    httpOnly: httpOnly ?? this.httpOnly,
    expires: expires ?? this.expires,
    sameSite: sameSite ?? this.sameSite,
  );

  /// Parses one Set-Cookie field against the response origin.
  ///
  /// Malformed or ambiguously combined fields return null. In particular, the
  /// first cookie pair is never split on comma, so an illegal combined header
  /// cannot be mistaken for two independent cookies.
  static SourceCookie? parseSetCookie(
    SourceId sourceId,
    String header,
    Uri origin, {
    DateTime? now,
  }) {
    if (origin.host.isEmpty ||
        (origin.scheme != 'http' && origin.scheme != 'https')) {
      return null;
    }
    final segments = header.split(';');
    if (segments.isEmpty) return null;
    final pair = segments.first.trim();
    final separator = pair.indexOf('=');
    if (separator <= 0) return null;
    final name = pair.substring(0, separator).trim();
    final value = pair.substring(separator + 1).trim();
    if (name.isEmpty || value.contains(',')) return null;

    final current = now ?? DateTime.now().toUtc();
    var domain = origin.host.toLowerCase();
    var hostOnly = true;
    var path = _defaultPath(origin.path);
    var secure = false;
    var httpOnly = false;
    DateTime? expires;
    int? maxAge;
    SourceCookieSameSite? sameSite;

    for (final rawAttribute in segments.skip(1)) {
      final attribute = rawAttribute.trim();
      if (attribute.isEmpty) continue;
      final equals = attribute.indexOf('=');
      final key = (equals < 0 ? attribute : attribute.substring(0, equals))
          .trim()
          .toLowerCase();
      final attributeValue = equals < 0
          ? ''
          : attribute.substring(equals + 1).trim();
      switch (key) {
        case 'domain':
          final candidate = attributeValue.toLowerCase().replaceFirst(
            RegExp(r'^\.'),
            '',
          );
          if (candidate.isEmpty ||
              !(origin.host.toLowerCase() == candidate ||
                  origin.host.toLowerCase().endsWith('.$candidate'))) {
            return null;
          }
          domain = candidate;
          hostOnly = false;
        case 'path':
          if (attributeValue.startsWith('/')) path = attributeValue;
        case 'secure':
          secure = true;
        case 'httponly':
          httpOnly = true;
        case 'expires':
          expires = _parseCookieDate(attributeValue);
        case 'max-age':
          maxAge = int.tryParse(attributeValue);
          if (maxAge == null) return null;
        case 'samesite':
          sameSite = switch (attributeValue.toLowerCase()) {
            'lax' => SourceCookieSameSite.lax,
            'strict' => SourceCookieSameSite.strict,
            'none' => SourceCookieSameSite.none,
            _ => null,
          };
        default:
          break;
      }
    }

    if (maxAge != null) {
      expires = maxAge <= 0
          ? current.subtract(const Duration(seconds: 1))
          : current.add(Duration(seconds: maxAge));
    }
    return SourceCookie(
      sourceId: sourceId,
      name: name,
      value: value,
      domain: domain,
      hostOnly: hostOnly,
      path: path,
      secure: secure,
      httpOnly: httpOnly,
      expires: expires,
      sameSite: sameSite,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SourceCookie &&
      identityKey == other.identityKey &&
      secure == other.secure &&
      httpOnly == other.httpOnly &&
      expires == other.expires &&
      sameSite == other.sameSite;

  @override
  int get hashCode =>
      Object.hash(identityKey, secure, httpOnly, expires, sameSite);

  @override
  String toString() =>
      'SourceCookie(name=$name, domain=$domain, path=$path, '
      'value=<redacted>)';
}

bool _pathMatches(String requestPath, String cookiePath) {
  if (requestPath == cookiePath) return true;
  if (!requestPath.startsWith(cookiePath)) return false;
  if (cookiePath.endsWith('/')) return true;
  return requestPath.length > cookiePath.length &&
      requestPath.codeUnitAt(cookiePath.length) == 0x2f;
}

String _defaultPath(String requestPath) {
  if (requestPath.isEmpty || !requestPath.startsWith('/')) return '/';
  final separator = requestPath.lastIndexOf('/');
  if (separator <= 0) return '/';
  return requestPath.substring(0, separator);
}

DateTime? _parseCookieDate(String value) {
  final trimmed = value.trim();
  final parsed = DateTime.tryParse(trimmed);
  if (parsed != null) return parsed.toUtc();
  final match = RegExp(
    r'^(?:[A-Za-z]+,\s*)?(\d{1,2})[- ]([A-Za-z]{3})[- ](\d{2,4})\s+(\d{2}):(\d{2}):(\d{2})',
  ).firstMatch(trimmed);
  if (match == null) return null;
  final day = int.parse(match.group(1)!);
  final month = _monthNumber(match.group(2)!);
  var year = int.parse(match.group(3)!);
  if (year < 100) year += year >= 70 ? 1900 : 2000;
  final hour = int.parse(match.group(4)!);
  final minute = int.parse(match.group(5)!);
  final second = int.parse(match.group(6)!);
  if (month == null) return null;
  try {
    final result = DateTime.utc(year, month, day, hour, minute, second);
    if (result.year != year ||
        result.month != month ||
        result.day != day ||
        result.hour != hour ||
        result.minute != minute ||
        result.second != second) {
      return null;
    }
    return result;
  } on ArgumentError {
    return null;
  }
}

int? _monthNumber(String value) => switch (value.toLowerCase()) {
  'jan' => 1,
  'feb' => 2,
  'mar' => 3,
  'apr' => 4,
  'may' => 5,
  'jun' => 6,
  'jul' => 7,
  'aug' => 8,
  'sep' => 9,
  'oct' => 10,
  'nov' => 11,
  'dec' => 12,
  _ => null,
};
