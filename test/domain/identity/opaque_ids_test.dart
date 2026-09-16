import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_reader/src/core/app_error.dart';
import 'package:light_novel_reader/src/core/app_logger.dart';
import 'package:light_novel_reader/src/domain/identity/identity_failure.dart';
import 'package:light_novel_reader/src/domain/identity/opaque_ids.dart';

void main() {
  final factories =
      <String, (OpaqueId Function(String), OpaqueId Function(Object?))>{
        'SourceId': (SourceId.new, SourceId.fromJson),
        'BookId': (BookId.new, BookId.fromJson),
        'VolumeId': (VolumeId.new, VolumeId.fromJson),
        'ChapterId': (ChapterId.new, ChapterId.fromJson),
        'AssetId': (AssetId.new, AssetId.fromJson),
      };

  for (final entry in factories.entries) {
    final (create, decode) = entry.value;
    group(entry.key, () {
      test('preserves exact scalar strings through JSON and equality', () {
        for (final value in [
          '42',
          '00042',
          ' 中文😀 ',
          '\t\n',
          'Aa',
          'aA',
          'é',
          'e\u0301',
          'wk8-123',
          'a/b#c.d-%2F',
        ]) {
          final id = create(value);
          expect(id.value, value);
          expect(jsonDecode(jsonEncode(id)), value);
          expect(decode(jsonDecode(jsonEncode(id))), id);
          expect(create(value).hashCode, id.hashCode);
          expect({id, create(value)}, hasLength(1));
        }
        expect(create('42'), isNot(create('00042')));
        expect(create('Aa'), isNot(create('aa')));
        expect(create('é'), isNot(create('e\u0301')));
        expect(create(' a '), isNot(create('a')));
        expect(create('%2F'), isNot(create('/')));
        expect(create('wk8-123'), isNot(create('123')));
      });

      test('rejects empty, NUL and unpaired surrogates without repair', () {
        final cases = {
          '': IdentityFailureReason.emptyId,
          'a\u0000b': IdentityFailureReason.nulCharacter,
          String.fromCharCode(0xd800): IdentityFailureReason.invalidUnicode,
          String.fromCharCode(0xdc00): IdentityFailureReason.invalidUnicode,
          String.fromCharCodes([0xd800, 0x61]):
              IdentityFailureReason.invalidUnicode,
          String.fromCharCodes([0xd800, 0xd800]):
              IdentityFailureReason.invalidUnicode,
          String.fromCharCodes([0xd83d, 0xde00, 0xdc00]):
              IdentityFailureReason.invalidUnicode,
        };
        for (final entry in cases.entries) {
          final matcher = throwsA(
            isA<IdentityFailure>().having(
              (error) => error.reason,
              'reason',
              entry.value,
            ),
          );
          expect(() => create(entry.key), matcher);
          expect(() => decode(entry.key), matcher);
        }
      });

      test('never coerces a JSON number, null or container into an ID', () {
        for (final value in [
          42,
          1.0,
          true,
          null,
          <Object>[],
          <String, Object>{},
        ]) {
          expect(
            () => decode(value),
            throwsA(
              isA<IdentityFailure>().having(
                (error) => error.reason,
                'reason',
                IdentityFailureReason.wrongType,
              ),
            ),
          );
        }
      });
    });
  }

  test(
    'concrete ID namespaces are distinct in equality and hash collections',
    () {
      final ids = factories.values.map((factory) => factory.$1('42')).toList();
      expect(ids.toSet(), hasLength(5));
      for (var left = 0; left < ids.length; left++) {
        for (var right = 0; right < ids.length; right++) {
          expect(ids[left] == ids[right], left == right);
        }
      }
    },
  );

  test(
    'validation failure integrates with F1 diagnostics without raw input',
    () {
      final logs = <String>[];
      final reporter = AppErrorReporter(AppLogger(write: logs.add));
      try {
        BookId('private-book\u0000');
        fail('Expected a validation failure');
      } on IdentityFailure catch (failure) {
        expect(
          reporter.report(failure, event: 'identity.invalid'),
          same(failure),
        );
        expect(failure.code, 'identity_nul_character');
        expect(failure.message, isNot(contains('private-book')));
        expect(failure.toString(), isNot(contains('private-book')));
        expect(logs.single, isNot(contains('private-book')));
      }
      expect(
        BookId('private-book').toString(),
        isNot(contains('private-book')),
      );
    },
  );
}
