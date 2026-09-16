import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_reader/src/core/app_error.dart';
import 'package:light_novel_reader/src/core/app_logger.dart';

void main() {
  test('Logs are structured UTC records without arbitrary exception text', () {
    final records = <String>[];
    final logger = AppLogger(
      write: records.add,
      now: () => DateTime.utc(2026, 9, 16),
    );
    final errors = AppErrorReporter(logger);

    final trace = StackTrace.current;
    final failure = errors.report(
      StateError('Cookie=session-secret'),
      event: 'test.failure',
      stackTrace: trace,
    );

    expect(failure.code, 'unexpected');
    expect(failure.message, 'Something went wrong. Please try again.');
    expect(jsonDecode(records.single), {
      'timestamp': '2026-09-16T00:00:00.000Z',
      'level': 'error',
      'event': 'test.failure',
      'errorCode': 'unexpected',
      'errorType': 'StateError',
      'stackTrace': trace.toString(),
    });
    expect(records.single, isNot(contains('session-secret')));
  });

  test(
    'Known failures preserve identity without serializing their message',
    () {
      final records = <String>[];
      final errors = AppErrorReporter(AppLogger(write: records.add));
      const failure = AppFailure(code: 'unavailable', message: 'Please retry.');

      expect(errors.report(failure, event: 'test.failure'), same(failure));
      expect(jsonDecode(records.single)['errorCode'], 'unavailable');
      expect(records.single, isNot(contains('Please retry.')));
    },
  );
}
