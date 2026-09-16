import 'identity_failure.dart';

/// Exact opaque Unicode value. Subtypes are different identity namespaces.
abstract base class OpaqueId {
  OpaqueId(this.value) {
    if (value.isEmpty) {
      throw IdentityFailure(IdentityFailureReason.emptyId);
    }
    for (var index = 0; index < value.length; index++) {
      final unit = value.codeUnitAt(index);
      if (unit == 0) {
        throw IdentityFailure(IdentityFailureReason.nulCharacter);
      }
      if (unit >= 0xd800 && unit <= 0xdbff) {
        if (++index >= value.length) {
          throw IdentityFailure(IdentityFailureReason.invalidUnicode);
        }
        final low = value.codeUnitAt(index);
        if (low < 0xdc00 || low > 0xdfff) {
          throw IdentityFailure(IdentityFailureReason.invalidUnicode);
        }
      } else if (unit >= 0xdc00 && unit <= 0xdfff) {
        throw IdentityFailure(IdentityFailureReason.invalidUnicode);
      }
    }
  }

  final String value;

  String toJson() => value;

  @override
  bool operator ==(Object other) =>
      other is OpaqueId &&
      runtimeType == other.runtimeType &&
      value == other.value;

  @override
  int get hashCode => Object.hash(runtimeType, value);

  @override
  String toString() => '$runtimeType(<opaque>)';
}

String _jsonString(Object? value) {
  if (value is! String) {
    throw IdentityFailure(IdentityFailureReason.wrongType);
  }
  return value;
}

final class SourceId extends OpaqueId {
  SourceId(super.value);
  factory SourceId.fromJson(Object? value) => SourceId(_jsonString(value));
}

final class BookId extends OpaqueId {
  BookId(super.value);
  factory BookId.fromJson(Object? value) => BookId(_jsonString(value));
}

final class VolumeId extends OpaqueId {
  VolumeId(super.value);
  factory VolumeId.fromJson(Object? value) => VolumeId(_jsonString(value));
}

final class ChapterId extends OpaqueId {
  ChapterId(super.value);
  factory ChapterId.fromJson(Object? value) => ChapterId(_jsonString(value));
}

final class AssetId extends OpaqueId {
  AssetId(super.value);
  factory AssetId.fromJson(Object? value) => AssetId(_jsonString(value));
}
