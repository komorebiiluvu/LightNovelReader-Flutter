import 'dart:convert';
import 'dart:developer' as developer;

enum LogLevel { info, warning, error }

/// Local structured diagnostics. Events and error codes must be static labels,
/// never credentials, URLs, user content, or exception messages.
class AppLogger {
  AppLogger({void Function(String)? write, DateTime Function()? now})
    : _write = write ?? _developerLog,
      _now = now ?? DateTime.now;

  final void Function(String) _write;
  final DateTime Function() _now;

  void log(
    LogLevel level,
    String event, {
    String? errorCode,
    String? errorType,
    StackTrace? stackTrace,
  }) {
    _write(
      jsonEncode({
        'timestamp': _now().toUtc().toIso8601String(),
        'level': level.name,
        'event': event,
        'errorCode': ?errorCode,
        'errorType': ?errorType,
        'stackTrace': ?stackTrace?.toString(),
      }),
    );
  }

  static void _developerLog(String record) {
    developer.log(record, name: 'LightNovelReader');
  }
}
