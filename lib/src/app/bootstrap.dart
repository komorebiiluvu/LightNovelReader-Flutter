import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_error.dart';
import '../core/app_logger.dart';
import 'app.dart';
import 'app_providers.dart';

/// Owns binding setup, root error hooks and the root dependency scope.
/// Binding initialization and runApp stay in the same zone.
void bootstrap({AppLogger? logger}) {
  WidgetsFlutterBinding.ensureInitialized();
  final appLogger = logger ?? AppLogger();
  final errors = AppErrorReporter(appLogger);

  FlutterError.onError = (details) {
    errors.report(
      details.exception,
      event: 'flutter.error',
      stackTrace: details.stack,
    );
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    errors.report(error, event: 'platform.error', stackTrace: stack);
    return true;
  };

  appLogger.log(LogLevel.info, 'app.bootstrap');
  runApp(
    ProviderScope(
      overrides: [
        appLoggerProvider.overrideWithValue(appLogger),
        appErrorReporterProvider.overrideWithValue(errors),
      ],
      child: const LightNovelReaderApp(),
    ),
  );
}
