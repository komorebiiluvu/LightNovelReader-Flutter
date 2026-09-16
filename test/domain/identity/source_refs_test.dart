import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_reader/src/domain/identity/identity_failure.dart';
import 'package:light_novel_reader/src/domain/identity/opaque_ids.dart';
import 'package:light_novel_reader/src/domain/identity/source_refs.dart';

Matcher failure(IdentityFailureReason reason) => throwsA(
  isA<IdentityFailure>().having((error) => error.reason, 'reason', reason),
);

List<SourceRef> refs(String source, String book, String local) => [
  SourceBookRef(sourceId: SourceId(source), bookId: BookId(book)),
  SourceVolumeRef(
    sourceId: SourceId(source),
    bookId: BookId(book),
    volumeId: VolumeId(local),
  ),
  SourceChapterRef(
    sourceId: SourceId(source),
    bookId: BookId(book),
    chapterId: ChapterId(local),
  ),
  SourceAssetRef(
    sourceId: SourceId(source),
    bookId: BookId(book),
    assetId: AssetId(local),
  ),
];

void main() {
  final decoders = <SourceRef Function(Object?)>[
    SourceBookRef.fromJson,
    SourceVolumeRef.fromJson,
    SourceChapterRef.fromJson,
    SourceAssetRef.fromJson,
  ];
  final kinds = [
    'sourceBookRef',
    'sourceVolumeRef',
    'sourceChapterRef',
    'sourceAssetRef',
  ];
  final extraFields = [null, 'volumeId', 'chapterId', 'assetId'];

  for (var index = 0; index < kinds.length; index++) {
    final kind = kinds[index];
    final extra = extraFields[index];
    final decode = decoders[index];
    final fixture = <String, Object?>{
      'kind': kind,
      'version': 1,
      'sourceId': 'a',
      'bookId': '00042',
    };
    if (extra != null) fixture[extra] = 'c';
    group(kind, () {
      test('matches the v1 wire fixture with string IDs', () {
        final ref = refs('a', '00042', 'c')[index];
        expect(ref.toJson(), fixture);
        expect(decode(fixture), ref);
        expect(SourceRef.fromJson(fixture), ref);
        expect(ref.toJson()['bookId'], isA<String>());
        expect(
          ref.toExternalKey(),
          '$kind.v1.YQ.MDAwNDI${extra == null ? '' : '.Yw'}',
        );
      });

      test('JSON and external keys preserve exact Unicode and delimiter-heavy tuples', () {
        for (final ref in [
          refs('source.#/-', 'wk8-123', '0007')[index],
          refs(' 中文😀 ', 'e\u0301/é.%2F', '\n\t/#.-')[index],
        ]) {
          final decoded = decode(jsonDecode(jsonEncode(ref)));
          expect(decoded, ref);
          expect(decoded.hashCode, ref.hashCode);
          expect(SourceRef.fromExternalKey(ref.toExternalKey()), ref);
        }
      });

      test(
        'source, book and local scopes stay distinct in hash collections',
        () {
          final original = refs('source-a', 'book-a', '42')[index];
          final variants = <SourceRef>{
            original,
            refs('source-a', 'book-a', '42')[index],
            refs('source-b', 'book-a', '42')[index],
            refs('source-a', 'book-b', '42')[index],
          };
          if (extra != null) {
            variants.add(refs('source-a', 'book-a', '43')[index]);
          }
          expect(variants, hasLength(extra == null ? 3 : 4));
          expect(
            variants.map((ref) => ref.toExternalKey()).toSet(),
            hasLength(variants.length),
          );
        },
      );

      test('rejects each missing or mistyped required field', () {
        for (final key in fixture.keys) {
          final missing = {...fixture}..remove(key);
          expect(
            () => decode(missing),
            failure(IdentityFailureReason.missingField),
          );
          for (final wrong in [
            null,
            true,
            <Object>[],
            <String, Object>{},
            1.0,
          ]) {
            expect(
              () => decode({...fixture, key: wrong}),
              failure(IdentityFailureReason.wrongType),
            );
          }
        }
        final identityFields = ['sourceId', 'bookId'];
        if (extra != null) identityFields.add(extra);
        for (final field in identityFields) {
          expect(
            () => decode({...fixture, field: 42}),
            failure(IdentityFailureReason.wrongType),
          );
          expect(
            () => decode({...fixture, field: ''}),
            failure(IdentityFailureReason.emptyId),
          );
          expect(
            () => decode({...fixture, field: '\u0000'}),
            failure(IdentityFailureReason.nulCharacter),
          );
          expect(
            () => decode({...fixture, field: '\ud800'}),
            failure(IdentityFailureReason.invalidUnicode),
          );
        }
      });

      test('rejects unknown kind, version and v1 fields as unsupported', () {
        expect(
          () => decode({...fixture, 'kind': 'futureRef'}),
          failure(IdentityFailureReason.wrongKind),
        );
        for (final version in [0, 2, -1]) {
          expect(
            () => decode({...fixture, 'version': version}),
            failure(IdentityFailureReason.unsupportedVersion),
          );
        }
        expect(
          () => decode({...fixture, 'title': 'future data'}),
          failure(IdentityFailureReason.unknownField),
        );
        for (final reason in [
          IdentityFailureReason.wrongKind,
          IdentityFailureReason.unsupportedVersion,
          IdentityFailureReason.unknownField,
        ]) {
          expect(IdentityFailure(reason).isUnsupported, isTrue);
        }
      });

      test('external tuple boundaries cannot collide', () {
        final left = refs('a', 'b.c', 'd')[index];
        final right = refs('a.b', 'c', 'd')[index];
        expect(left.toExternalKey(), isNot(right.toExternalKey()));
        expect(SourceRef.fromExternalKey(left.toExternalKey()), left);
        expect(SourceRef.fromExternalKey(right.toExternalKey()), right);
        if (extra != null) {
          expect(
            refs('a', 'b', 'c.d')[index].toExternalKey(),
            isNot(refs('a', 'b.c', 'd')[index].toExternalKey()),
          );
        }
      });
    });
  }

  test(
    'reference kinds remain distinct even with otherwise matching tuples',
    () {
      expect(refs('s', 'b', '42').toSet(), hasLength(4));
      expect(
        refs('s', 'b', '42').map((ref) => ref.toExternalKey()).toSet(),
        hasLength(4),
      );
      expect(
        refs(
          'private-source',
          'private-book',
          'private-local',
        ).first.toString(),
        isNot(contains('private-')),
      );
    },
  );

  test('metadata updates do not change the ref used as a map key', () {
    final ref = refs('s', 'b', 'c')[2];
    final metadata = <SourceRef, Map<String, Object>>{
      ref: {
        'title': 'Before',
        'order': 0,
        'volume': 'old',
        'sourceName': 'Old',
      },
    };
    metadata[ref] = {
      'title': 'After',
      'order': 7,
      'volume': 'new',
      'sourceName': 'New',
    };
    final sameIdentity = refs('s', 'b', 'c')[2];
    expect(metadata[sameIdentity]?['order'], 7);
    expect(metadata.keys.single, sameIdentity);
    expect(
      ref.toJson().keys,
      unorderedEquals(['kind', 'version', 'sourceId', 'bookId', 'chapterId']),
    );
  });

  test('semantic JSON equality ignores key order and escape spelling', () {
    final first = SourceRef.fromJson(
      jsonDecode(
        r'{"kind":"sourceBookRef","version":1,"sourceId":"s","bookId":"\u0034\u0032"}',
      ),
    );
    final second = SourceRef.fromJson(
      jsonDecode(
        '{"bookId":"42","sourceId":"s","version":1,"kind":"sourceBookRef"}',
      ),
    );
    expect(first, second);
  });

  test('object decoders reject scalars, containers, missing and invalid discriminators', () {
    for (final decoder in [...decoders, SourceRef.fromJson]) {
      for (final input in [
        null,
        1,
        'text',
        true,
        <Object>[],
        {1: 'value'},
      ]) {
        expect(() => decoder(input), failure(IdentityFailureReason.wrongType));
      }
    }
    expect(
      () => SourceRef.fromJson({}),
      failure(IdentityFailureReason.missingField),
    );
    expect(
      () => SourceRef.fromJson({'kind': 1}),
      failure(IdentityFailureReason.wrongType),
    );
    expect(
      () => SourceRef.fromJson({'kind': 'futureRef'}),
      failure(IdentityFailureReason.wrongKind),
    );
  });

  test('external keys reject invalid grammar, padding, UTF-8 and noncanonical bits', () {
    for (final key in [
      '', 'sourceBookRef.v2.YQ.Yg', 'sourceBookRef.v1.YQ',
      'sourceBookRef.v1.YQ.Yg.extra', 'sourceChapterRef.v1.YQ.Yg',
      'sourceBookRef.v1..Yg', 'sourceBookRef.v1.YQ==.Yg',
      'sourceBookRef.v1.Y+.Yg', 'sourceBookRef.v1.%59Q.Yg',
      'sourceBookRef.v1._w.Yg', // Invalid UTF-8 byte 0xff.
      'sourceBookRef.v1.YR.Yg', // Nonzero unused bits, noncanonical encoding of a.
      'sourceBookRef.v1.A.Yg', // Impossible base64 length.
    ]) {
      expect(
        () => SourceRef.fromExternalKey(key),
        failure(IdentityFailureReason.invalidKey),
        reason: key,
      );
    }
    expect(
      () => SourceRef.fromExternalKey('futureRef.v1.YQ.Yg'),
      failure(IdentityFailureReason.wrongKind),
    );
    expect(
      () => SourceRef.fromExternalKey('sourceBookRef.v1.AA.Yg'),
      failure(IdentityFailureReason.nulCharacter),
    );
  });

  test(
    'standard JSON decoder loses duplicate keys before object validation',
    () {
      final decoded = jsonDecode(
        '{"kind":"sourceBookRef","version":1,"sourceId":"s","bookId":"first","bookId":"second"}',
      );
      expect(decoded['bookId'], 'second');
      expect(SourceBookRef.fromJson(decoded).bookId, BookId('second'));
      // This is a documented limitation, not strict importer acceptance (F2.6).
    },
  );
}
