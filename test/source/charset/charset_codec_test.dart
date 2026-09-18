import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_reader/src/source/charset/charset.dart';

void main() {
  const decoder = CharsetDecoder();
  const encoder = CharsetEncoder();

  CharsetEvidence evidence() => CharsetEvidence('independent frozen vector');

  test('preserves source encoding and evidence in a decoded document', () {
    final document = decoder.decode(
      RawBytes(const [0x68, 0x69]),
      encoding: SourceEncoding.utf8,
      evidence: evidence(),
    );

    expect(document.text, 'hi');
    expect(document.encoding, SourceEncoding.utf8);
    expect(document.evidence.reason, 'independent frozen vector');
    expect(document.replacements.wasUsed, isFalse);
  });

  test(
    'decodes and encodes the frozen LegacyCP936Compatible Chinese vector',
    () {
      final bytes = RawBytes(const [
        0xd6,
        0xd0,
        0xce,
        0xc4,
        0xd0,
        0xa1,
        0xcb,
        0xb5,
      ]);
      final document = decoder.decode(
        bytes,
        encoding: SourceEncoding.legacyCp936Compatible,
        evidence: evidence(),
      );

      expect(document.text, '中文小说');
      expect(
        encoder
            .encode('中文小说', encoding: SourceEncoding.legacyCp936Compatible)
            .bytes,
        bytes.bytes,
      );
    },
  );

  test('preserves the CP936-compatible private-use mapping', () {
    final document = decoder.decode(
      RawBytes(const [0xaa, 0xa1]),
      encoding: SourceEncoding.legacyCp936Compatible,
      evidence: evidence(),
    );

    expect(document.text, '\ue000');
    expect(
      encoder
          .encode('\ue000', encoding: SourceEncoding.legacyCp936Compatible)
          .bytes,
      [0xaa, 0xa1],
    );
  });

  test('decodes the independent GB18030 four-byte vector', () {
    final document = decoder.decode(
      RawBytes(const [0x81, 0x30, 0x81, 0x30]),
      encoding: SourceEncoding.gb18030,
      evidence: evidence(),
    );

    expect(document.text, '\u0080');
    expect(encoder.encode('\u0080', encoding: SourceEncoding.gb18030).bytes, [
      0x81,
      0x30,
      0x81,
      0x30,
    ]);
  });

  test('does not treat GB18030 four-byte input as LegacyCP936Compatible', () {
    expect(
      () => decoder.decode(
        RawBytes(const [0x81, 0x30, 0x81, 0x30]),
        encoding: SourceEncoding.legacyCp936Compatible,
        evidence: evidence(),
      ),
      throwsA(
        isA<CharsetDecodeException>().having(
          (error) => error.info.kind,
          'kind',
          CharsetFailureKind.invalidContinuation,
        ),
      ),
    );
  });

  test('fails deterministically on malformed GB18030 input', () {
    expect(
      () => decoder.decode(
        RawBytes(const [0x81, 0x30, 0xff]),
        encoding: SourceEncoding.gb18030,
        evidence: evidence(),
      ),
      throwsA(
        isA<CharsetDecodeException>().having(
          (error) => error.info,
          'safe info',
          const CharsetFailureInfo(
            encoding: SourceEncoding.gb18030,
            kind: CharsetFailureKind.invalidContinuation,
            offset: 0,
          ),
        ),
      ),
    );
  });

  test('fails deterministically on truncated GB18030 input', () {
    expect(
      () => decoder.decode(
        RawBytes(const [0x81, 0x30, 0x81]),
        encoding: SourceEncoding.gb18030,
        evidence: evidence(),
      ),
      throwsA(
        isA<CharsetDecodeException>().having(
          (error) => error.info.kind,
          'kind',
          CharsetFailureKind.truncatedSequence,
        ),
      ),
    );
  });

  test('replacement mode is explicit and records safe byte offsets', () {
    final document = decoder.decode(
      RawBytes(const [0x81, 0x30, 0xff]),
      encoding: SourceEncoding.gb18030,
      errorMode: CharsetErrorMode.replacement,
      evidence: evidence(),
    );

    expect(document.text, '\ufffd0\ufffd');
    expect(document.replacements.count, 2);
    expect(document.replacements.offsets, [0, 2]);
  });

  test('UTF-8 strict and replacement modes are deterministic', () {
    expect(
      () => decoder.decode(
        RawBytes(const [0xc3, 0x28]),
        encoding: SourceEncoding.utf8,
        evidence: evidence(),
      ),
      throwsA(isA<CharsetDecodeException>()),
    );
    final document = decoder.decode(
      RawBytes(const [0xc3, 0x28]),
      encoding: SourceEncoding.utf8,
      errorMode: CharsetErrorMode.replacement,
      evidence: evidence(),
    );
    expect(document.text, '\ufffd(');
    expect(document.replacements.offsets, [0]);
  });

  test('encoder rejects unsupported legacy code points without fallback', () {
    expect(
      () =>
          encoder.encode('😀', encoding: SourceEncoding.legacyCp936Compatible),
      throwsA(
        isA<CharsetEncodeException>().having(
          (error) => error.info.kind,
          'kind',
          CharsetFailureKind.unrepresentableCodePoint,
        ),
      ),
    );
  });

  test('GB18030 supports scalar values outside the BMP', () {
    const text = '😀';
    final bytes = encoder.encode(text, encoding: SourceEncoding.gb18030);
    final document = decoder.decode(
      bytes,
      encoding: SourceEncoding.gb18030,
      evidence: evidence(),
    );
    expect(document.text, text);
  });

  test('unpaired UTF-16 code units are rejected by every encoder', () {
    expect(
      () => encoder.encode('\ud800', encoding: SourceEncoding.utf8),
      throwsA(isA<CharsetEncodeException>()),
    );
  });
}
