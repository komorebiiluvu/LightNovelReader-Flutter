import 'dart:convert';
import 'dart:io';

const fixtureRootPath = 'test/fixtures/sources/wenku8';

Map<String, dynamic> loadFixtureManifest() =>
    jsonDecode(File('$fixtureRootPath/manifest.json').readAsStringSync())
        as Map<String, dynamic>;

List<Map<String, dynamic>> fixtureEntries(Map<String, dynamic> manifest) =>
    (manifest['entries'] as List<dynamic>)
        .cast<Map<dynamic, dynamic>>()
        .map((entry) => entry.map((key, value) => MapEntry('$key', value)))
        .toList(growable: false);

int _rotateRight(int value, int count) {
  const mask = 0xffffffff;
  return ((value >>> count) | (value << (32 - count))) & mask;
}

/// Small independent SHA-256 implementation used only to verify fixture bytes.
List<int> sha256Bytes(List<int> input) {
  const mask = 0xffffffff;
  const initial = <int>[
    0x6a09e667,
    0xbb67ae85,
    0x3c6ef372,
    0xa54ff53a,
    0x510e527f,
    0x9b05688c,
    0x1f83d9ab,
    0x5be0cd19,
  ];
  const round = <int>[
    0x428a2f98,
    0x71374491,
    0xb5c0fbcf,
    0xe9b5dba5,
    0x3956c25b,
    0x59f111f1,
    0x923f82a4,
    0xab1c5ed5,
    0xd807aa98,
    0x12835b01,
    0x243185be,
    0x550c7dc3,
    0x72be5d74,
    0x80deb1fe,
    0x9bdc06a7,
    0xc19bf174,
    0xe49b69c1,
    0xefbe4786,
    0x0fc19dc6,
    0x240ca1cc,
    0x2de92c6f,
    0x4a7484aa,
    0x5cb0a9dc,
    0x76f988da,
    0x983e5152,
    0xa831c66d,
    0xb00327c8,
    0xbf597fc7,
    0xc6e00bf3,
    0xd5a79147,
    0x06ca6351,
    0x14292967,
    0x27b70a85,
    0x2e1b2138,
    0x4d2c6dfc,
    0x53380d13,
    0x650a7354,
    0x766a0abb,
    0x81c2c92e,
    0x92722c85,
    0xa2bfe8a1,
    0xa81a664b,
    0xc24b8b70,
    0xc76c51a3,
    0xd192e819,
    0xd6990624,
    0xf40e3585,
    0x106aa070,
    0x19a4c116,
    0x1e376c08,
    0x2748774c,
    0x34b0bcb5,
    0x391c0cb3,
    0x4ed8aa4a,
    0x5b9cca4f,
    0x682e6ff3,
    0x748f82ee,
    0x78a5636f,
    0x84c87814,
    0x8cc70208,
    0x90befffa,
    0xa4506ceb,
    0xbef9a3f7,
    0xc67178f2,
  ];
  final padded = <int>[...input, 0x80];
  while (padded.length % 64 != 56) {
    padded.add(0);
  }
  final bitLength = input.length * 8;
  for (var shift = 56; shift >= 0; shift -= 8) {
    padded.add((bitLength >> shift) & 0xff);
  }
  final h = [...initial];
  for (var offset = 0; offset < padded.length; offset += 64) {
    final w = List<int>.filled(64, 0);
    for (var i = 0; i < 16; i++) {
      final p = offset + i * 4;
      w[i] =
          ((padded[p] << 24) |
              (padded[p + 1] << 16) |
              (padded[p + 2] << 8) |
              padded[p + 3]) &
          mask;
    }
    for (var i = 16; i < 64; i++) {
      final a = w[i - 15];
      final b = w[i - 2];
      final s0 = _rotateRight(a, 7) ^ _rotateRight(a, 18) ^ (a >>> 3);
      final s1 = _rotateRight(b, 17) ^ _rotateRight(b, 19) ^ (b >>> 10);
      w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & mask;
    }
    var a = h[0];
    var b = h[1];
    var c = h[2];
    var d = h[3];
    var e = h[4];
    var f = h[5];
    var g = h[6];
    var i = h[7];
    for (var j = 0; j < 64; j++) {
      final s1 = _rotateRight(e, 6) ^ _rotateRight(e, 11) ^ _rotateRight(e, 25);
      final ch = (e & f) ^ ((~e) & g);
      final t1 = (i + s1 + ch + round[j] + w[j]) & mask;
      final s0 = _rotateRight(a, 2) ^ _rotateRight(a, 13) ^ _rotateRight(a, 22);
      final maj = (a & b) ^ (a & c) ^ (b & c);
      final t2 = (s0 + maj) & mask;
      i = g;
      g = f;
      f = e;
      e = (d + t1) & mask;
      d = c;
      c = b;
      b = a;
      a = (t1 + t2) & mask;
    }
    h[0] = (h[0] + a) & mask;
    h[1] = (h[1] + b) & mask;
    h[2] = (h[2] + c) & mask;
    h[3] = (h[3] + d) & mask;
    h[4] = (h[4] + e) & mask;
    h[5] = (h[5] + f) & mask;
    h[6] = (h[6] + g) & mask;
    h[7] = (h[7] + i) & mask;
  }
  final output = <int>[];
  for (final value in h) {
    output
      ..add((value >>> 24) & 0xff)
      ..add((value >>> 16) & 0xff)
      ..add((value >>> 8) & 0xff)
      ..add(value & 0xff);
  }
  return output;
}

String sha256Hex(List<int> input) =>
    sha256Bytes(input)
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();

String fixtureText(Map<String, dynamic> entry) => utf8.decode(
  File('$fixtureRootPath/${entry['fixture']}').readAsBytesSync(),
  allowMalformed: true,
);
