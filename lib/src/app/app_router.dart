import 'package:flutter/material.dart';

import '../core/app_error.dart';
import 'home_screen.dart';

/// F1 has one destination. Unknown routes safely fall back to home; no external
/// route/argument data is logged or retained. Deep-link semantics are deferred.
class AppRouter {
  const AppRouter(this._errors);

  static const home = '/';

  final AppErrorReporter _errors;

  Route<void> onGenerateRoute(RouteSettings settings) {
    if (settings.name != home) {
      _errors.report(
        const AppFailure.routeNotFound(),
        event: 'navigation.unknown_route',
      );
    }

    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: home),
      builder: (_) => const HomeScreen(),
    );
  }
}
