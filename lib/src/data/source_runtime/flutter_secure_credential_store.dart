import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../source/security/secure_credential_store.dart';
import '../../source/security/secure_value.dart';
import '../../source/source_failure.dart';

/// Adapter boundary for the approved flutter_secure_storage implementation.
/// The plugin type is intentionally private to this infrastructure file.
final class FlutterSecureCredentialStore implements SecureCredentialStore {
  FlutterSecureCredentialStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<SecureValue?> read(SecureStorageKey key) async {
    try {
      final value = await _storage.read(key: key.storageName);
      return value == null ? null : SecureValue(value);
    } catch (_) {
      throw _secureFailure();
    }
  }

  @override
  Future<void> write(SecureStorageKey key, SecureValue value) async {
    try {
      await _storage.write(key: key.storageName, value: value.value);
    } catch (_) {
      throw _secureFailure();
    }
  }

  @override
  Future<void> delete(SecureStorageKey key) async {
    try {
      await _storage.delete(key: key.storageName);
    } catch (_) {
      throw _secureFailure();
    }
  }
}

SourceFailure _secureFailure() =>
    SourceFailure(code: SourceFailureCode.secureStorage);
