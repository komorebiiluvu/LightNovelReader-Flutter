import '../identity/identity_failure.dart';
import '../identity/identity_json.dart';
import '../identity/opaque_ids.dart';
import '../identity/source_refs.dart';
import 'legacy_source_mapping.dart';

/// Unresolved legacy progress evidence, not a modern chapter or Reader anchor.
final class LegacyChapterLocatorV1 {
  LegacyChapterLocatorV1({
    required this.datasetId,
    required this.bookRef,
    required this.legacyBookId,
    required this.chapterIndex,
    this.rawOffsetKey,
    this.fraction,
    this.remoteIdEvidence,
    this.chapterTitleEvidence,
    this.volumeTitleEvidence,
    this.catalogDigest,
  }) {
    if (chapterIndex < 0 ||
        (fraction != null &&
            (!fraction!.isFinite || fraction! < 0 || fraction! > 1))) {
      throw IdentityFailure(IdentityFailureReason.invalidValue);
    }
  }

  factory LegacyChapterLocatorV1.fromJson(Object? input) {
    final fields = readIdentityV1(
      input,
      kind: 'legacyIosChapterLocator',
      requiredFields: {'datasetId', 'bookRef', 'legacyBookId', 'chapterIndex'},
      optionalFields: {
        'rawOffsetKey',
        'fraction',
        'remoteIdEvidence',
        'chapterTitleEvidence',
        'volumeTitleEvidence',
        'catalogDigest',
      },
    );
    final chapterIndex = fields['chapterIndex'];
    if (chapterIndex is! int) {
      throw IdentityFailure(IdentityFailureReason.wrongType);
    }
    double? fraction;
    if (fields.containsKey('fraction')) {
      final value = fields['fraction'];
      if (value is! num) {
        throw IdentityFailure(IdentityFailureReason.wrongType);
      }
      fraction = value.toDouble();
    }
    return LegacyChapterLocatorV1(
      datasetId: LegacyDatasetId(identityString(fields['datasetId'])),
      bookRef: SourceBookRef.fromJson(fields['bookRef']),
      legacyBookId: BookId.fromJson(fields['legacyBookId']),
      chapterIndex: chapterIndex,
      rawOffsetKey: optionalIdentityString(fields, 'rawOffsetKey'),
      fraction: fraction,
      remoteIdEvidence: optionalIdentityString(fields, 'remoteIdEvidence'),
      chapterTitleEvidence: optionalIdentityString(
        fields,
        'chapterTitleEvidence',
      ),
      volumeTitleEvidence: optionalIdentityString(
        fields,
        'volumeTitleEvidence',
      ),
      catalogDigest: optionalIdentityString(fields, 'catalogDigest'),
    );
  }

  final LegacyDatasetId datasetId;
  final SourceBookRef bookRef;
  final BookId legacyBookId;
  final int chapterIndex;
  final String? rawOffsetKey;
  final double? fraction;
  final String? remoteIdEvidence;
  final String? chapterTitleEvidence;
  final String? volumeTitleEvidence;
  final String? catalogDigest;

  Map<String, Object?> toJson() => {
    'kind': 'legacyIosChapterLocator',
    'version': 1,
    'datasetId': datasetId.toJson(),
    'bookRef': bookRef.toJson(),
    'legacyBookId': legacyBookId.toJson(),
    'chapterIndex': chapterIndex,
    if (rawOffsetKey != null) 'rawOffsetKey': rawOffsetKey,
    if (fraction != null) 'fraction': fraction,
    if (remoteIdEvidence != null) 'remoteIdEvidence': remoteIdEvidence,
    if (chapterTitleEvidence != null)
      'chapterTitleEvidence': chapterTitleEvidence,
    if (volumeTitleEvidence != null) 'volumeTitleEvidence': volumeTitleEvidence,
    if (catalogDigest != null) 'catalogDigest': catalogDigest,
  };

  Object get _values => (
    datasetId,
    bookRef,
    legacyBookId,
    chapterIndex,
    rawOffsetKey,
    fraction,
    remoteIdEvidence,
    chapterTitleEvidence,
    volumeTitleEvidence,
    catalogDigest,
  );

  @override
  bool operator ==(Object other) =>
      other is LegacyChapterLocatorV1 && _values == other._values;

  @override
  int get hashCode => _values.hashCode;
}
