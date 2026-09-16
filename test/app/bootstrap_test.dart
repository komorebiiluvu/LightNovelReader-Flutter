import 'dart:convert';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_reader/src/app/app_providers.dart';
import 'package:light_novel_reader/src/app/bootstrap.dart';
import 'package:light_novel_reader/src/app/home_screen.dart';
import 'package:light_novel_reader/src/core/app_logger.dart';

void main() {
  testWidgets('Bootstrap wires both error hooks and the shared logger', (
    tester,
  ) async {
    final records = <String>[];
    final logger = AppLogger(write: records.add);
    final previousFlutterHandler = FlutterError.onError;
    final previousPlatformHandler = PlatformDispatcher.instance.onError;
    late bool handled;

    try {
      bootstrap(logger: logger);
      FlutterError.onError!(
        FlutterErrorDetails(exception: StateError('private-framework-payload')),
      );
      handled = PlatformDispatcher.instance.onError!(
        StateError('private-platform-payload'),
        StackTrace.current,
      );
    } finally {
      // Restore test binding handlers before pumping or making assertions.
      FlutterError.onError = previousFlutterHandler;
      PlatformDispatcher.instance.onError = previousPlatformHandler;
    }

    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeScreen)),
    );
    expect(container.read(appLoggerProvider), same(logger));
    expect(handled, isTrue);
    expect(records.map((line) => jsonDecode(line)['event']), [
      'app.bootstrap',
      'flutter.error',
      'platform.error',
    ]);
    expect(records.join(), isNot(contains('private-')));
    expect(tester.takeException(), isNull);
  });
}
