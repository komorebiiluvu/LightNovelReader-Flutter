import '../source_failure.dart';
import 'secure_value.dart';

/// Neutral source-scoped secure storage boundary.
abstract interface class SecureCredentialStore {
  Future<SecureValue?> read(SecureStorageKey key);

  Future<void> write(SecureStorageKey key, SecureValue value);

  Future<void> delete(SecureStorageKey key);
}

/// Deterministic backend seam for unit tests and explicit non-persistent mode.
abstract interface class SecureValueBackend {
  Future<String?> read(String storageName);

  Future<void> write(String storageName, String value);

  Future<void> delete(String storageName);
}

/// In-memory backend used by tests. It never persists values to disk.
final class InMemorySecureValueBackend implements SecureValueBackend {
  final Map<String, String> values = <String, String>{};
  SourceFailure? failure;

  @override
  Future<String?> read(String storageName) async {
    _throwIfFailed();
    return values[storageName];
  }

  @override
  Future<void> write(String storageName, String value) async {
    _throwIfFailed();
    values[storageName] = value;
  }

  @override
  Future<void> delete(String storageName) async {
    _throwIfFailed();
    values.remove(storageName);
  }

  void _throwIfFailed() {
    final error = failure;
    if (error != null) throw error;
  }
}

/// Secure-store implementation that maps backend failures to the neutral
/// secureStorage code without exposing backend exception text.
final class BackendSecureCredentialStore implements SecureCredentialStore {
  const BackendSecureCredentialStore(this.backend);

  final SecureValueBackend backend;

  @override
  Future<SecureValue?> read(SecureStorageKey key) async {
    try {
      final value = await backend.read(key.storageName);
      return value == null ? null : SecureValue(value);
    } catch (_) {
      throw _secureFailure();
    }
  }

  @override
  Future<void> write(SecureStorageKey key, SecureValue value) async {
    try {
      await backend.write(key.storageName, value.value);
    } catch (_) {
      throw _secureFailure();
    }
  }

  @override
  Future<void> delete(SecureStorageKey key) async {
    try {
      await backend.delete(key.storageName);
    } catch (_) {
      throw _secureFailure();
    }
  }
}

SourceFailure _secureFailure() =>
    SourceFailure(code: SourceFailureCode.secureStorage);
