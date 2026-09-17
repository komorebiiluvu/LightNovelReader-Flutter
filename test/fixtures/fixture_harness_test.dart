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
    File(path).absolute.path.replaceAll('\\', '/').toLowerCase();

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
    expect(entries, hasLength(79));
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

  test('authentication material is inert and secret-safe', () {
    final secretPatterns = [
      RegExp(r'authorization\s*:', caseSensitive: false),
      RegExp(r'\bbearer\s+[a-z0-9._-]+', caseSensitive: false),
      RegExp(r'password\s*=', caseSensitive: false),
    ];
    for (final entry in entries) {
      final text = fixtureText(entry);
      for (final pattern in secretPatterns) {
        expect(pattern.hasMatch(text), isFalse, reason: '${entry['id']}');
      }
      expect(entry['sanitization']['rawAuthenticated'], isFalse);
      expect(entry['sanitization']['inert'], isTrue);
      for (final match in RegExp(
        r'(PHPSESSID|jieqiUserInfo)=([^;\s]*)',
      ).allMatches(text)) {
        expect(
          {'SYNTHETIC_SESSION', 'SYNTHETIC_USER_INFO', ''},
          contains(match.group(2)),
          reason: '${entry['id']} contains a non-synthetic cookie',
        );
      }
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
