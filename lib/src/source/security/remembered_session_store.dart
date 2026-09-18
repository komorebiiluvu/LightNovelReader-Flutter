import '../../domain/identity/opaque_ids.dart';
import '../source_failure.dart';
import 'secure_credential_store.dart';
import 'secure_value.dart';

/// Source-neutral coordinator for one opaque remembered-session value.
///
/// It does not interpret or persist provider fields. A failed delete creates
/// an in-process tombstone: restore is blocked until an explicit successful
/// remember operation. The approved three-method store cannot make that
/// tombstone crash-safe across a process that dies while delete is failing;
/// that restart limitation remains explicit until the storage contract grows a
/// transactional revocation primitive.
final class RememberedSessionStore {
  static final Set<String> _blockedStorageNames = <String>{};

  RememberedSessionStore({
    required this._store,
    required SourceId sourceId,
    String keyName = 'remembered-session',
  }) : _key = SecureStorageKey(sourceId: sourceId, name: keyName);

  final SecureCredentialStore _store;
  final SecureStorageKey _key;

  Future<void> remember(SecureValue value) async {
    try {
      await _store.write(_key, value);
      _blockedStorageNames.remove(_key.storageName);
    } catch (_) {
      throw _secureFailure();
    }
  }

  Future<SecureValue?> restore() async {
    if (_blockedStorageNames.contains(_key.storageName)) {
      throw _secureFailure();
    }
    try {
      return await _store.read(_key);
    } catch (_) {
      throw _secureFailure();
    }
  }

  Future<void> clear() async {
    try {
      await _store.delete(_key);
      _blockedStorageNames.remove(_key.storageName);
    } catch (_) {
      _blockedStorageNames.add(_key.storageName);
      throw _secureFailure();
    }
  }
}

SourceFailure _secureFailure() =>
    SourceFailure(code: SourceFailureCode.secureStorage);
