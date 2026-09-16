import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_error.dart';
import '../core/app_logger.dart';
import 'app_router.dart';

// Composition lives here; core primitives do not depend on Flutter or Riverpod.
final appLoggerProvider = Provider<AppLogger>((ref) => AppLogger());

final appErrorReporterProvider = Provider<AppErrorReporter>(
  (ref) => AppErrorReporter(ref.watch(appLoggerProvider)),
);

final appRouterProvider = Provider<AppRouter>(
  (ref) => AppRouter(ref.watch(appErrorReporterProvider)),
);
