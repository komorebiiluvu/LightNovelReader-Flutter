import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'fixture_harness.dart';

const frozenCommit = 'd90d4d090c85a0a9c374684696c34befe12636d1';
const allowedOperations = {
  'search',
  'explore',
  'bookDetail',
  'catalog',
  'chapterContent',
  'authentication',
};
const allowedProvenance = {'synthetic', 'reconstructed_from_frozen_evidence'};
const allowedClassifications = {'PRESERVE', 'FIX', 'REGRESSION_TEST', 'DEFER'};
const requiredCoverage = {
  'content.multi-interleaved-order',
  'encoding.gb18030-extension',
  'encoding.invalid-sequence',
  'encoding.truncated-sequence',
  'encoding.declaration-disagreement',
  'request.gbk-percent-encoding',
  'auth.login-success',
  'auth.login-rejected',
  'auth.expiry',
  'cookies.multiple-set-cookie',
  'cookies.expires-comma',
  'auth.logout',
  'waf.http200-challenge',
  'search.normal',
  'search.direct-detail',
  'search.valid-empty',
  'search.malformed-item',
  'search.http200-waf',
  'explore.home',
  'explore.category',
  'explore.tag',
  'explore.pagination',
  'explore.malformed-block',
  'pagination.pagestats',
  'pagination.pagelink',
  'pagination.largest-linked-fallback',
  'pagination.malformed-metadata',
  'detail.normal',
  'detail.copyright-unavailable',
  'detail.description-page-chrome',
  'detail.table-cell-boundaries',
  'catalog.normal',
  'catalog.flat',
  'catalog.grouping-presentation-only',
  'catalog.missing-chapter-id',
  'catalog.reordered',
  'content.interleaved-order',
  'content.br-flush',
  'content.consecutive-br',
  'content.image-only',
  'content.repeated-image',
  'asset.relative-locator',
  'asset.protocol-relative-locator',
  'asset.absolute-locator',
  'content.missing-container',
  'content.malformed',
  'content.page-chrome',
  'host.search-net',
  'host.detail-cc',
  'host.unapproved',
  'retry.server-error',
  'retry.timeout-bounds',
  'reconciliation.opaque-id',
  'reconciliation.ordinal-only',
};

String _absolute(String path) =>
    File(path).resolveSymbolicLinksSync().replaceAll('\\', '/');

void main() {
  late Map<String, dynamic> manifest;
  late List<Map<String, dynamic>> entries;
  setUpAll(() {
    manifest = loadFixtureManifest();
    entries = fixtureEntries(manifest);
  });

  test('manifest identifies the frozen source and schema', () {
    expect(manifest['schema'], 'f3.2.fixture-manifest.v1');
    expect(manifest['sourceId'], 'builtin.wenku8');
    expect(manifest['frozenLegacyCommit'], frozenCommit);
    expect(entries, hasLength(80));
  });

  test('entries have unique IDs and valid operation metadata', () {
    expect(entries.map((e) => e['id']).toSet(), hasLength(entries.length));
    for (final entry in entries) {
      expect(allowedOperations, contains(entry['operation']));
      expect(allowedProvenance, contains(entry['provenance']));
      expect(allowedClassifications, contains(entry['classification']));
      expect(entry['frozenLegacyCommit'], frozenCommit);
      expect(entry['coverage'], isA<List<dynamic>>());
      expect(entry['expectedOutcome'], isA<Map<dynamic, dynamic>>());
    }
  });

  test('every fixture and sidecar stays inside the corpus and exists', () {
    final root = _absolute(fixtureRootPath);
    final rootPrefix = '$root/';
    for (final entry in entries) {
      for (final key in ['fixture', 'expected']) {
        final path = _absolute('$fixtureRootPath/${entry[key]}');
        expect(
          path.startsWith(rootPrefix),
          isTrue,
          reason: '$key escaped root',
        );
        expect(File(path).existsSync(), isTrue, reason: path);
      }
    }
  });

  test('raw and expected sidecar hashes match the manifest', () {
    for (final entry in entries) {
      final raw = File('$fixtureRootPath/${entry['fixture']}')
          .readAsBytesSync();
      final expected = File('$fixtureRootPath/${entry['expected']}')
          .readAsBytesSync();
      expect(sha256Hex(raw), entry['sha256'], reason: '${entry['id']} raw');
      expect(
        sha256Hex(expected),
        entry['expectedSha256'],
        reason: '${entry['id']} sidecar',
      );
    }
  });

  test('sidecars are independent contract expectations', () {
    for (final entry in entries) {
      final expected = jsonDecode(
        File('$fixtureRootPath/${entry['expected']}').readAsStringSync(),
      ) as Map<String, dynamic>;
      expect(expected['schema'], 'f3.2.expected.v1');
      expect(expected['kind'], isNotEmpty);
      final text = jsonEncode(expected);
      expect(text, isNot(contains('lib/src/source')));
      expect(text, isNot(contains('GuardedBookSource')));
      expect(text, isNot(contains('SourceContinuation')));
    }
  });

  test('binary encoding vectors retain their intended bytes', () {
    for (final entry in entries) {
      final expectation = entry['byteExpectation'];
      if (expectation == null) continue;
      final actual = File('$fixtureRootPath/${entry['fixture']}')
          .readAsBytesSync();
      expect(
        actual,
        hexDecode(expectation as String),
        reason: '${entry['id']}',
      );
    }
  });

  test('all non-UTF charset entries prove their raw bytes', () {
    for (final entry in entries) {
      expect(
        validCharsetBytes(
          entry,
          File('$fixtureRootPath/${entry['fixture']}').readAsBytesSync(),
        ),
        isTrue,
        reason: '${entry['id']}',
      );
      if (entry['encoding'] == 'utf-8' || entry['encoding'] == 'metadata') {
        expect(
          () => utf8.decode(
            File('$fixtureRootPath/${entry['fixture']}').readAsBytesSync(),
          ),
          returnsNormally,
        );
      }
    }
  });

  test(
    'charset integrity rejects UTF-8 masquerading even with matching hex',
    () {
      final bytes = utf8.encode('中文小说');
      final entry = <String, dynamic>{
        'encoding': 'gbk',
        'fixture': 'fake.bin',
        'byteExpectation': bytes.map((b) => b.toRadixString(16)).join(),
      };
      expect(validCharsetBytes(entry, bytes), isFalse);
      expect(
        validCharsetBytes({...entry, 'byteExpectation': null}, [0xd6, 0xd0]),
        isFalse,
      );
    },
  );

  test('audited charset vectors pin independent bytes and Unicode', () {
    const vectors = {
      'enc-simplified-chinese': ['d6d0cec4d0a1cbb5', '中文小说'],
      'enc-gb18030-extension': ['81308130', '\u0080'],
      'enc-gbk-pua': ['aaa1', '\ue000'],
      'enc-invalid-sequence': ['8130ff', '�'],
      'enc-truncated-sequence': ['813081', '�'],
    };
    for (final vector in vectors.entries) {
      final entry = entries.singleWhere((e) => e['id'] == vector.key);
      expect(
        File('$fixtureRootPath/${entry['fixture']}').readAsBytesSync(),
        hexDecode(vector.value[0]),
      );
      final sidecar = jsonDecode(
        File('$fixtureRootPath/${entry['expected']}').readAsStringSync(),
      );
      expect(sidecar['decoded'], vector.value[1]);
    }
    final declaration = entries.singleWhere(
      (e) => e['id'] == 'enc-declared-disagreement',
    );
    expect(
      File('$fixtureRootPath/${declaration['fixture']}').readAsBytesSync(),
      [
        ...ascii.encode('<meta charset="utf-8"><p>'),
        ...hexDecode('d6d0cec4'),
        ...ascii.encode('</p>'),
      ],
    );
  });

  test('six-node sidecar preserves every distinct text and image position', () {
    final entry = entries.singleWhere(
      (e) => e['id'] == 'content-multi-interleaved',
    );
    final sidecar = jsonDecode(
      File('$fixtureRootPath/${entry['expected']}').readAsStringSync(),
    ) as Map;
    expect(sidecar['nodes'], [
      {'type': 'text', 'text': 'First'},
      {'type': 'text', 'text': 'Second'},
      {'type': 'image', 'locator': '/first.jpg'},
      {'type': 'text', 'text': 'Third'},
      {'type': 'image', 'locator': '/second.jpg'},
      {'type': 'text', 'text': 'Fourth'},
    ]);
    expect(sidecar.containsKey('paragraphs'), isFalse);
    expect(sidecar.containsKey('images'), isFalse);
    expect(jsonEncode(sidecar), isNot(contains('assetId')));
  });

  test('complete corpus raw manifest and sidecars contain no secrets', () {
    expect(containsSecretMaterial(manifest), isFalse);
    for (final file in Directory(
      fixtureRootPath,
    ).listSync(recursive: true).whereType<File>()) {
      expect(
        containsSecretMaterial(
          utf8.decode(file.readAsBytesSync(), allowMalformed: true),
        ),
        isFalse,
        reason: file.path,
      );
    }
    for (final entry in entries) {
      expect(entry['sanitization']['rawAuthenticated'], isFalse);
      expect(entry['sanitization']['inert'], isTrue);
    }
  });

  test('scanner rejects secret structures on every metadata surface', () {
    for (final secret in [
      'Authorization: Basic NOT_A_REAL_SECRET',
      'Bearer NOT_A_REAL_SECRET',
      'password=NOT_A_REAL_SECRET',
      'cookie=NOT_A_REAL_SECRET',
      'token=NOT_A_REAL_SECRET',
      'PHPSESSID=NOT_A_REAL_SECRET',
      'jieqiUserInfo=NOT_A_REAL_SECRET',
      'Cookie: other=NOT_A_REAL_SECRET',
      'Set-Cookie: other=NOT_A_REAL_SECRET; Path=/',
      {'password': 'NOT_A_REAL_SECRET'},
      {'access_token': 'NOT_A_REAL_SECRET'},
      {'cookie': 'NOT_A_REAL_SECRET'},
      {'authorization': 'NOT_A_REAL_SECRET'},
      {'PHPSESSID': 'NOT_A_REAL_SECRET'},
      {'jieqiUserInfo': 'NOT_A_REAL_SECRET'},
    ]) {
      expect(containsSecretMaterial(secret), isTrue);
      expect(containsSecretMaterial({'notes': secret}), isTrue);
      expect(containsSecretMaterial(jsonEncode({'expected': secret})), isTrue);
    }
  });

  test('scanner allows prose and exact inert sentinel structures', () {
    for (final safe in [
      'password policy and cookie names',
      'Cookie: PHPSESSID=SYNTHETIC_SESSION',
      'Set-Cookie: A=one; Expires=Wed, 21 Oct 2015 07:28:00 GMT; Path=/',
      {
        'cookieNames': ['PHPSESSID', 'jieqiUserInfo'],
      },
      {'PHPSESSID': 'SYNTHETIC_SESSION'},
    ]) {
      expect(containsSecretMaterial(safe), isFalse);
    }
    expect(containsSecretMaterial({'token': 'SYNTHETIC_UNAPPROVED'}), isTrue);
  });

  test('required characterization coverage is present', () {
    final coverage = entries
        .expand((entry) => (entry['coverage'] as List<dynamic>).cast<String>())
        .toSet();
    expect(coverage, containsAll(requiredCoverage));
    expect(entries.where((e) => e['classification'] == 'DROP'), isEmpty);
  });

  test('all six F3.1 operations and edge-case families are represented', () {
    expect(entries.map((e) => e['operation']).toSet(), allowedOperations);
    for (final operation in allowedOperations) {
      expect(entries.any((e) => e['operation'] == operation), isTrue);
    }
    expect(
      entries.any(
        (e) => e['provenance'] == 'reconstructed_from_frozen_evidence',
      ),
      isTrue,
    );
    expect(entries.any((e) => e['classification'] == 'DEFER'), isTrue);
  });

  test('provider URLs are metadata-only and reserved to allowlisted hosts', () {
    final urlPattern = RegExp(r'https?://[^\s"<]+');
    for (final entry in entries) {
      for (final match in urlPattern.allMatches(fixtureText(entry))) {
        final url = match.group(0)!;
        final allowed =
            url.contains('www.wenku8.net') ||
            url.contains('www.wenku8.cc') ||
            url.contains('.invalid');
        expect(allowed, isTrue, reason: '${entry['id']} contains $url');
      }
    }
  });

  test('fixture files contain no Dart implementation or generated parser', () {
    final files = Directory(fixtureRootPath)
        .listSync(recursive: true)
        .whereType<File>();
    expect(files.any((file) => file.path.endsWith('.dart')), isFalse);
    for (final file in files) {
      final text = utf8.decode(file.readAsBytesSync(), allowMalformed: true);
      expect(text, isNot(contains('package:light_novel_reader/src/source')));
      expect(text, isNot(contains('parseWenku8')));
    }
  });
}

List<int> hexDecode(String value) {
  if (value.length.isOdd) throw FormatException('odd hex length');
  return [
    for (var i = 0; i < value.length; i += 2)
      int.parse(value.substring(i, i + 2), radix: 16),
  ];
}
