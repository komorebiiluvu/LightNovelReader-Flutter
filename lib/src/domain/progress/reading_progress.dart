import '../identity/identity_failure.dart';
import '../identity/identity_json.dart';
import '../identity/source_refs.dart';
import '../legacy/legacy_chapter_locator.dart';

/// Durable progress metadata. It deliberately contains no Reader position.
final class ReadingProgressV1 {
  ReadingProgressV1({
    required this.bookRef,
    required this.hasRead,
    this.chapterRef,
    this.legacyLocator,
    DateTime? lastReadAt,
  }) : lastReadAt = lastReadAt == null ? null : _millisecondUtc(lastReadAt) {
    if (chapterRef != null &&
        (chapterRef!.sourceId != bookRef.sourceId ||
            chapterRef!.bookId != bookRef.bookId)) {
      throw IdentityFailure(IdentityFailureReason.invalidValue);
    }
    if (legacyLocator != null && legacyLocator!.bookRef != bookRef) {
      throw IdentityFailure(IdentityFailureReason.invalidValue);
    }
  }

  factory ReadingProgressV1.fromJson(Object? input) {
    final fields = readIdentityV1(
      input,
      kind: 'readingProgress',
      requiredFields: {'bookRef', 'hasRead'},
      optionalFields: {'chapterRef', 'legacyLocator', 'lastReadAt'},
    );
    final hasRead = fields['hasRead'];
    if (hasRead is! bool) {
      throw IdentityFailure(IdentityFailureReason.wrongType);
    }
    DateTime? lastReadAt;
    if (fields.containsKey('lastReadAt')) {
      final value = fields['lastReadAt'];
      if (value is! String) {
        throw IdentityFailure(IdentityFailureReason.wrongType);
      }
      lastReadAt = decodeCanonicalUtc(value);
    }
    return ReadingProgressV1(
      bookRef: SourceBookRef.fromJson(fields['bookRef']),
      hasRead: hasRead,
      chapterRef: fields.containsKey('chapterRef')
          ? SourceChapterRef.fromJson(fields['chapterRef'])
          : null,
      legacyLocator: fields.containsKey('legacyLocator')
          ? LegacyChapterLocatorV1.fromJson(fields['legacyLocator'])
          : null,
      lastReadAt: lastReadAt,
    );
  }

  final SourceBookRef bookRef;
  final bool hasRead;
  final SourceChapterRef? chapterRef;
  final LegacyChapterLocatorV1? legacyLocator;
  final DateTime? lastReadAt;

  Map<String, Object?> toJson() => {
    'kind': 'readingProgress',
    'version': 1,
    'bookRef': bookRef.toJson(),
    'hasRead': hasRead,
    if (chapterRef != null) 'chapterRef': chapterRef!.toJson(),
    if (legacyLocator != null) 'legacyLocator': legacyLocator!.toJson(),
    if (lastReadAt != null) 'lastReadAt': encodeCanonicalUtc(lastReadAt!),
  };

  @override
  bool operator ==(Object other) =>
      other is ReadingProgressV1 &&
      other.bookRef == bookRef &&
      other.hasRead == hasRead &&
      other.chapterRef == chapterRef &&
      other.legacyLocator == legacyLocator &&
      other.lastReadAt == lastReadAt;

  @override
  int get hashCode =>
      Object.hash(bookRef, hasRead, chapterRef, legacyLocator, lastReadAt);
}

/// Canonical durable representation used by progress JSON and SQLite.
String encodeCanonicalUtc(DateTime value) {
  final utc = value.toUtc();
  if (utc.year < 0 || utc.year > 9999) {
    throw IdentityFailure(IdentityFailureReason.invalidValue);
  }
  return '${_four(utc.year)}-${_two(utc.month)}-${_two(utc.day)}'
      'T${_two(utc.hour)}:${_two(utc.minute)}:${_two(utc.second)}'
      '.${_three(utc.millisecond)}Z';
}

DateTime decodeCanonicalUtc(String value) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$')
      .hasMatch(value)) {
    throw IdentityFailure(IdentityFailureReason.invalidValue);
  }
  try {
    final parsed = DateTime.parse(value);
    if (!parsed.isUtc || encodeCanonicalUtc(parsed) != value) {
      throw IdentityFailure(IdentityFailureReason.invalidValue);
    }
    return parsed;
  } on FormatException {
    throw IdentityFailure(IdentityFailureReason.invalidValue);
  }
}

String _two(int value) => value.toString().padLeft(2, '0');
String _three(int value) => value.toString().padLeft(3, '0');
String _four(int value) => value.toString().padLeft(4, '0');

DateTime _millisecondUtc(DateTime value) {
  final utc = value.toUtc();
  return DateTime.utc(
    utc.year,
    utc.month,
    utc.day,
    utc.hour,
    utc.minute,
    utc.second,
    utc.millisecond,
  );
}
