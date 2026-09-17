import 'dart:convert';

import '../../domain/identity/opaque_ids.dart';

/// A value intentionally treated as secret at every diagnostic boundary.
final class SecureValue {
  const SecureValue._(this.value);

  factory SecureValue(String value) {
    if (value.isEmpty) throw ArgumentError.value(value, 'value');
    if (value.contains(RegExp(r'[\u0000\r\n]'))) {
      throw ArgumentError.value(value, 'value');
    }
    return SecureValue._(value);
  }

  final String value;

  @override
  String toString() => 'SecureValue(<redacted>)';
}

/// A non-secret source-scoped key used by [SecureCredentialStore].
final class SecureStorageKey {
  SecureStorageKey({required this.sourceId, required this.name}) {
    if (name.isEmpty || name.contains(RegExp(r'[\u0000\r\n/\\]'))) {
      throw ArgumentError.value(name, 'name');
    }
  }

  final SourceId sourceId;
  final String name;

  /// Stable namespace that does not expose arbitrary source/key punctuation to
  /// a platform plugin.
  String get storageName =>
      'source-v1.${_encode(sourceId.value)}.${_encode(name)}';

  @override
  String toString() =>
      'SecureStorageKey(${sourceId.runtimeType}(<opaque>), <opaque>)';
}

String _encode(String value) =>
    base64Url.encode(utf8.encode(value)).replaceAll('=', '');
