import 'dart:convert';

import 'identity_failure.dart';
import 'identity_json.dart';
import 'opaque_ids.dart';

/// Source-aware tuple identity. Metadata is deliberately outside this value.
sealed class SourceRef {
  const SourceRef({required this.sourceId, required this.bookId});

  factory SourceRef.fromJson(Object? input) {
    final fields = readIdentityObject(input);
    if (!fields.containsKey('kind')) {
      throw IdentityFailure(IdentityFailureReason.missingField);
    }
    return switch (identityString(fields['kind'])) {
      'sourceBookRef' => SourceBookRef.fromJson(fields),
      'sourceVolumeRef' => SourceVolumeRef.fromJson(fields),
      'sourceChapterRef' => SourceChapterRef.fromJson(fields),
      'sourceAssetRef' => SourceAssetRef.fromJson(fields),
      _ => throw IdentityFailure(IdentityFailureReason.wrongKind),
    };
  }

  /// Decodes only canonical unpadded base64url components; never a file path.
  factory SourceRef.fromExternalKey(String key) {
    final parts = key.split('.');
    if (parts.length < 4 || parts[1] != 'v1') {
      throw IdentityFailure(IdentityFailureReason.invalidKey);
    }
    final extra = switch (parts.first) {
      'sourceBookRef' => null,
      'sourceVolumeRef' => 'volumeId',
      'sourceChapterRef' => 'chapterId',
      'sourceAssetRef' => 'assetId',
      _ => throw IdentityFailure(IdentityFailureReason.wrongKind),
    };
    if (parts.length != (extra == null ? 4 : 5)) {
      throw IdentityFailure(IdentityFailureReason.invalidKey);
    }
    final decoded = <String, Object?>{
      'kind': parts.first,
      'version': 1,
      'sourceId': _decodeComponent(parts[2]),
      'bookId': _decodeComponent(parts[3]),
    };
    if (extra != null) decoded[extra] = _decodeComponent(parts[4]);
    return SourceRef.fromJson(decoded);
  }

  final SourceId sourceId;
  final BookId bookId;
  String get kind;
  OpaqueId? get _localId => null;
  String? get _localField => null;

  Map<String, Object?> toJson() {
    final fields = <String, Object?>{
      'kind': kind,
      'version': 1,
      'sourceId': sourceId.toJson(),
      'bookId': bookId.toJson(),
    };
    final field = _localField;
    if (field != null) fields[field] = _localId!.toJson();
    return fields;
  }

  String toExternalKey() {
    final parts = <String>[
      kind,
      'v1',
      _encodeComponent(sourceId.value),
      _encodeComponent(bookId.value),
    ];
    final id = _localId;
    if (id != null) parts.add(_encodeComponent(id.value));
    return parts.join('.');
  }

  @override
  bool operator ==(Object other) =>
      other is SourceRef &&
      runtimeType == other.runtimeType &&
      sourceId == other.sourceId &&
      bookId == other.bookId &&
      _localId == other._localId;

  @override
  int get hashCode => Object.hash(runtimeType, sourceId, bookId, _localId);

  @override
  String toString() => '$runtimeType(<opaque>)';
}

final class SourceBookRef extends SourceRef {
  const SourceBookRef({required super.sourceId, required super.bookId});

  factory SourceBookRef.fromJson(Object? input) {
    final fields = readIdentityV1(
      input,
      kind: 'sourceBookRef',
      requiredFields: {'sourceId', 'bookId'},
    );
    return SourceBookRef(
      sourceId: SourceId.fromJson(fields['sourceId']),
      bookId: BookId.fromJson(fields['bookId']),
    );
  }

  @override
  String get kind => 'sourceBookRef';
}

final class SourceVolumeRef extends SourceRef {
  const SourceVolumeRef({
    required super.sourceId,
    required super.bookId,
    required this.volumeId,
  });

  factory SourceVolumeRef.fromJson(Object? input) {
    final fields = readIdentityV1(
      input,
      kind: 'sourceVolumeRef',
      requiredFields: {'sourceId', 'bookId', 'volumeId'},
    );
    return SourceVolumeRef(
      sourceId: SourceId.fromJson(fields['sourceId']),
      bookId: BookId.fromJson(fields['bookId']),
      volumeId: VolumeId.fromJson(fields['volumeId']),
    );
  }

  final VolumeId volumeId;
  @override
  String get kind => 'sourceVolumeRef';
  @override
  OpaqueId get _localId => volumeId;
  @override
  String get _localField => 'volumeId';
}

final class SourceChapterRef extends SourceRef {
  const SourceChapterRef({
    required super.sourceId,
    required super.bookId,
    required this.chapterId,
  });

  factory SourceChapterRef.fromJson(Object? input) {
    final fields = readIdentityV1(
      input,
      kind: 'sourceChapterRef',
      requiredFields: {'sourceId', 'bookId', 'chapterId'},
    );
    return SourceChapterRef(
      sourceId: SourceId.fromJson(fields['sourceId']),
      bookId: BookId.fromJson(fields['bookId']),
      chapterId: ChapterId.fromJson(fields['chapterId']),
    );
  }

  final ChapterId chapterId;
  @override
  String get kind => 'sourceChapterRef';
  @override
  OpaqueId get _localId => chapterId;
  @override
  String get _localField => 'chapterId';
}

final class SourceAssetRef extends SourceRef {
  const SourceAssetRef({
    required super.sourceId,
    required super.bookId,
    required this.assetId,
  });

  factory SourceAssetRef.fromJson(Object? input) {
    final fields = readIdentityV1(
      input,
      kind: 'sourceAssetRef',
      requiredFields: {'sourceId', 'bookId', 'assetId'},
    );
    return SourceAssetRef(
      sourceId: SourceId.fromJson(fields['sourceId']),
      bookId: BookId.fromJson(fields['bookId']),
      assetId: AssetId.fromJson(fields['assetId']),
    );
  }

  final AssetId assetId;
  @override
  String get kind => 'sourceAssetRef';
  @override
  OpaqueId get _localId => assetId;
  @override
  String get _localField => 'assetId';
}

String _encodeComponent(String value) =>
    base64Url.encode(utf8.encode(value)).replaceAll('=', '');

String _decodeComponent(String component) {
  if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(component)) {
    throw IdentityFailure(IdentityFailureReason.invalidKey);
  }
  try {
    final value = utf8.decode(base64Url.decode(base64Url.normalize(component)));
    if (_encodeComponent(value) != component) {
      throw IdentityFailure(IdentityFailureReason.invalidKey);
    }
    return value;
  } on FormatException {
    throw IdentityFailure(IdentityFailureReason.invalidKey);
  }
}
