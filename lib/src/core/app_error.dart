import 'app_logger.dart';

/// Framework-independent failure for application/domain boundaries.
/// Codes are stable diagnostic labels; messages must be safe for users.
class AppFailure implements Exception {
  const AppFailure({required this.code, required this.message});

  const AppFailure.unexpected()
    : code = 'unexpected',
      message = 'Something went wrong. Please try again.';

  const AppFailure.routeNotFound()
    : code = 'route_not_found',
      message = 'This page is unavailable.';

  final String code;
  final String message;

  @override
  String toString() => 'AppFailure($code)';
}

class AppErrorReporter {
  const AppErrorReporter(this._logger);

  final AppLogger _logger;

  AppFailure report(
    Object error, {
    required String event,
    StackTrace? stackTrace,
  }) {
    final failure = error is AppFailure ? error : const AppFailure.unexpected();
    // Preserve runtime diagnostics without arbitrary exception messages.
    // Supply only runtime traces from a catch/framework boundary, not user data.
    _logger.log(
      LogLevel.error,
      event,
      errorCode: failure.code,
      errorType: error.runtimeType.toString(),
      stackTrace: stackTrace,
    );
    return failure;
  }
}
