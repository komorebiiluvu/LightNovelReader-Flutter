import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:light_novel_reader/src/data/source_runtime/flutter_secure_credential_store.dart';
import 'package:light_novel_reader/src/domain/identity/opaque_ids.dart';
import 'package:light_novel_reader/src/source/security/secure_value.dart';

const _stage = String.fromEnvironment('F3_7_SECURE_RESTART_STAGE');
const _runId = String.fromEnvironment('F3_7_SECURE_RESTART_ID');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('secure value survives a separate packaged process', (_) async {
    expect(_stage, anyOf('write', 'read'));
    expect(_runId, isNotEmpty);
    final key = SecureStorageKey(
      sourceId: SourceId('f3.7.restart.smoke'),
      name: 'synthetic-$_runId',
    );
    final expected = 'SYNTHETIC_RESTART_$_runId';
    final store = FlutterSecureCredentialStore();

    if (_stage == 'write') {
      await store.delete(key);
      await store.write(key, SecureValue(expected));
      expect((await store.read(key))?.value, expected);
      return;
    }

    try {
      expect((await store.read(key))?.value, expected);
    } finally {
      await store.delete(key);
    }
    expect(await store.read(key), isNull);
  });
}
