import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_reader/src/domain/identity/identity_failure.dart';
import 'package:light_novel_reader/src/domain/identity/opaque_ids.dart';
import 'package:light_novel_reader/src/domain/identity/source_refs.dart';
import 'package:light_novel_reader/src/domain/legacy/legacy_chapter_locator.dart';
import 'package:light_novel_reader/src/domain/legacy/legacy_source_mapping.dart';

Matcher failure(IdentityFailureReason reason) => throwsA(
  isA<IdentityFailure>().having((error) => error.reason, 'reason', reason),
);

void main() {
  final datasetId = LegacyDatasetId('import-001');
  final bookRef = SourceBookRef(
    sourceId: SourceId('builtin.wenku8'),
    bookId: BookId('wk8-123'),
  );
  final fixture = <String, Object?>{
    'kind': 'legacyIosChapterLocator',
    'version': 1,
    'datasetId': 'import-001',
    'bookRef': bookRef.toJson(),
    'legacyBookId': 'wk8-123',
    'chapterIndex': 0,
  };
  LegacyChapterLocatorV1 locator({int index = 0, double? fraction}) =>
      LegacyChapterLocatorV1(
        datasetId: datasetId,
        bookRef: bookRef,
        legacyBookId: BookId('wk8-123'),
        chapterIndex: index,
        fraction: fraction,
      );

  test(
    'minimal legacy fixture preserves opaque book ID and zero-based index',
    () {
      final value = locator();
      expect(value.toJson(), fixture);
      expect(LegacyChapterLocatorV1.fromJson(fixture), value);
      expect(value.legacyBookId.value, 'wk8-123');
      expect(value.bookRef.bookId, BookId('wk8-123'));
      expect(value.chapterIndex, 0);
      expect(value.remoteIdEvidence, isNull);
      expect(value.toJson().containsKey('chapterId'), isFalse);
      expect(value.toJson().containsKey('fraction'), isFalse);
      expect(locator(index: 42).chapterIndex, 42);
    },
  );

  test(
    'all optional evidence round-trips unchanged without inferring identity',
    () {
      final complete = {
        ...fixture,
        'rawOffsetKey': 'wk8-123#0',
        'fraction': 0.25,
        'remoteIdEvidence': '00007',
        'chapterTitleEvidence': ' 章😀 ',
        'volumeTitleEvidence': '',
        'catalogDigest': 'opaque-digest',
      };
      final value = LegacyChapterLocatorV1.fromJson(complete);
      expect(value.toJson(), complete);
      final decoded = LegacyChapterLocatorV1.fromJson(
        jsonDecode(jsonEncode(value)),
      );
      expect(decoded, value);
      expect(decoded.hashCode, value.hashCode);
      expect({value, decoded}, hasLength(1));
      expect(value.chapterIndex, 0);
      expect(value.remoteIdEvidence, '00007');
      expect(value.volumeTitleEvidence, '');
    },
  );

  test('fraction boundaries accept integer JSON and double values exactly', () {
    for (final fraction in [0, 1, 0.5]) {
      final value = locator(fraction: fraction.toDouble());
      expect(value.fraction, fraction);
      expect(
        LegacyChapterLocatorV1.fromJson({...fixture, 'fraction': fraction}),
        value,
      );
    }
  });

  test(
    'rejects invalid fraction without clamping or replacing with absence',
    () {
      for (final fraction in [
        -0.01,
        1.01,
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        expect(
          () => locator(fraction: fraction),
          failure(IdentityFailureReason.invalidValue),
        );
        expect(
          () => LegacyChapterLocatorV1.fromJson({
            ...fixture,
            'fraction': fraction,
          }),
          failure(IdentityFailureReason.invalidValue),
        );
      }
    },
  );

  test(
    'rejects negative/noninteger chapter index without converting to cid',
    () {
      expect(
        () => locator(index: -1),
        failure(IdentityFailureReason.invalidValue),
      );
      expect(
        () => LegacyChapterLocatorV1.fromJson({...fixture, 'chapterIndex': -1}),
        failure(IdentityFailureReason.invalidValue),
      );
      for (final value in [1.0, '1', true, null]) {
        expect(
          () => LegacyChapterLocatorV1.fromJson({
            ...fixture,
            'chapterIndex': value,
          }),
          failure(IdentityFailureReason.wrongType),
        );
      }
    },
  );

  test('required fields must exist and have the declared type', () {
    for (final key in fixture.keys) {
      expect(
        () => LegacyChapterLocatorV1.fromJson({...fixture}..remove(key)),
        failure(IdentityFailureReason.missingField),
      );
      expect(
        () => LegacyChapterLocatorV1.fromJson({...fixture, key: null}),
        failure(IdentityFailureReason.wrongType),
      );
    }
    for (final key in ['datasetId', 'legacyBookId']) {
      expect(
        () => LegacyChapterLocatorV1.fromJson({...fixture, key: ''}),
        failure(IdentityFailureReason.emptyId),
      );
      expect(
        () => LegacyChapterLocatorV1.fromJson({...fixture, key: 123}),
        failure(IdentityFailureReason.wrongType),
      );
    }
  });

  test('optional means absent, not null or coerced evidence', () {
    for (final key in [
      'rawOffsetKey',
      'fraction',
      'remoteIdEvidence',
      'chapterTitleEvidence',
      'volumeTitleEvidence',
      'catalogDigest',
    ]) {
      for (final wrong in [null, true, <Object>[]]) {
        expect(
          () => LegacyChapterLocatorV1.fromJson({...fixture, key: wrong}),
          failure(IdentityFailureReason.wrongType),
        );
      }
      if (key != 'fraction') {
        expect(
          () => LegacyChapterLocatorV1.fromJson({...fixture, key: 1}),
          failure(IdentityFailureReason.wrongType),
        );
      }
    }
    expect(
      () => LegacyChapterLocatorV1.fromJson({...fixture, 'fraction': '0.5'}),
      failure(IdentityFailureReason.wrongType),
    );
  });

  test('future envelope and nested ref fields fail without dropping data', () {
    expect(
      () => LegacyChapterLocatorV1.fromJson({...fixture, 'kind': 'future'}),
      failure(IdentityFailureReason.wrongKind),
    );
    expect(
      () => LegacyChapterLocatorV1.fromJson({...fixture, 'version': 2}),
      failure(IdentityFailureReason.unsupportedVersion),
    );
    expect(
      () => LegacyChapterLocatorV1.fromJson({...fixture, 'future': 'keep'}),
      failure(IdentityFailureReason.unknownField),
    );
    expect(
      () => LegacyChapterLocatorV1.fromJson({
        ...fixture,
        'bookRef': {...bookRef.toJson(), 'future': 'keep'},
      }),
      failure(IdentityFailureReason.unknownField),
    );
    expect(
      () => LegacyChapterLocatorV1.fromJson({
        ...fixture,
        'bookRef': {...bookRef.toJson(), 'version': 2},
      }),
      failure(IdentityFailureReason.unsupportedVersion),
    );
    expect(
      () => LegacyChapterLocatorV1.fromJson({
        ...fixture,
        'bookRef': {...bookRef.toJson(), 'kind': 'sourceChapterRef'},
      }),
      failure(IdentityFailureReason.wrongKind),
    );
  });

  test('locator equality includes provenance and all evidence', () {
    final original = locator();
    for (final delta in <Map<String, Object?>>[
      {'datasetId': 'import-002'},
      {'legacyBookId': 'wk8-0123'},
      {'chapterIndex': 1},
      {'fraction': 0},
      {'rawOffsetKey': ''},
      {'remoteIdEvidence': '1'},
      {'chapterTitleEvidence': ''},
      {'volumeTitleEvidence': ''},
      {'catalogDigest': ''},
      {
        'bookRef': {...bookRef.toJson(), 'sourceId': 'other'},
      },
    ]) {
      expect(
        LegacyChapterLocatorV1.fromJson({...fixture, ...delta}),
        isNot(original),
      );
    }
  });

  test(
    'source mapping preserves conflicting raw candidates without resolution',
    () {
      final mapping = LegacySourceMapping(
        datasetId: datasetId,
        originalBookKey: 'wk8-123',
        mappingVersion: 1,
        resolution: LegacyIdentityResolution.conflict,
        sourceByIdName: '文库8(在线)',
        bookSourceName: '文库8',
      );
      expect(mapping.targetRef, isNull);
      expect(mapping.sourceByIdName, '文库8(在线)');
      expect(mapping.bookSourceName, '文库8');
      expect(mapping.originalBookKey, 'wk8-123');
      expect(mapping.resolution, LegacyIdentityResolution.conflict);
    },
  );

  test('source mapping can retain invalid raw evidence and an unresolved placeholder', () {
    final mapping = LegacySourceMapping(
      datasetId: datasetId,
      originalBookKey: '',
      mappingVersion: 1,
      sourceByIdName: '',
      bookSourceName: null,
      targetRef: SourceBookRef(
        sourceId: SourceId('legacy.ios.unassigned'),
        bookId: BookId('wk8-123'),
      ),
      resolution: LegacyIdentityResolution.unresolved,
    );
    expect(mapping.originalBookKey, '');
    expect(mapping.sourceByIdName, '');
    expect(mapping.bookSourceName, isNull);
    expect(mapping.resolution, LegacyIdentityResolution.unresolved);
    expect(mapping.toString(), isNot(contains('wk8-123')));
  });

  test('resolved mapping requires target and a positive independent mapping version', () {
    LegacySourceMapping mapping({int version = 1, SourceBookRef? target}) =>
        LegacySourceMapping(
          datasetId: datasetId,
          originalBookKey: 'wk8-123',
          mappingVersion: version,
          resolution: LegacyIdentityResolution.resolved,
          targetRef: target,
        );
    expect(() => mapping(), failure(IdentityFailureReason.invalidValue));
    expect(
      () => mapping(version: 0, target: bookRef),
      failure(IdentityFailureReason.invalidValue),
    );
    final first = mapping(target: bookRef);
    final second = mapping(target: bookRef);
    expect(first, second);
    expect(first.hashCode, second.hashCode);
    expect(mapping(version: 2, target: bookRef), isNot(first));
    expect(first.targetRef, bookRef);
  });
}
