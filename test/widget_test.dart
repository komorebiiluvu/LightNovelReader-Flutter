import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_reader/src/app/app.dart';
import 'package:light_novel_reader/src/app/app_providers.dart';
import 'package:light_novel_reader/src/app/home_screen.dart';
import 'package:light_novel_reader/src/core/app_logger.dart';

void main() {
  testWidgets('Home renders through the root scope and router', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LightNovelReaderApp()));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('LightNovelReader'), findsOneWidget);
    expect(find.text('Welcome to LightNovelReader.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Unknown route uses overridden diagnostics and returns home', (
    tester,
  ) async {
    final records = <String>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appLoggerProvider.overrideWithValue(AppLogger(write: records.add)),
        ],
        child: const LightNovelReaderApp(),
      ),
    );
    await tester.pumpAndSettle();
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    // External route data must never be echoed to diagnostics.
    navigator.pushNamed<void>('/missing?token=private');
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(
      ModalRoute.of(tester.element(find.byType(HomeScreen)))!.settings.name,
      '/',
    );
    expect(records, hasLength(1));
    expect(jsonDecode(records.single)['errorCode'], 'route_not_found');
    expect(records.single, isNot(contains('private')));
    navigator.pop();
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(navigator.canPop(), isFalse);
    expect(tester.takeException(), isNull);
  });
}
