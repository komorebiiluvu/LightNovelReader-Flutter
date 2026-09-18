/// Encoding modes supported by the source-neutral charset boundary.
enum SourceEncoding { utf8, legacyCp936Compatible, gb18030 }

/// How malformed input is handled while decoding.
enum CharsetErrorMode { strict, replacement }

/// A validated, immutable byte sequence.
final class RawBytes {
  RawBytes(Iterable<int> values)
    : bytes = List<int>.unmodifiable(_copy(values));

  final List<int> bytes;

  int get length => bytes.length;

  int operator [](int index) => bytes[index];

  static List<int> _copy(Iterable<int> values) {
    final result = <int>[];
    for (final value in values) {
      if (value < 0 || value > 0xff) {
        throw ArgumentError.value(value, 'bytes', 'Each byte must be 0..255.');
      }
      result.add(value);
    }
    return result;
  }
}

/// The trusted reason supplied by the caller for selecting an encoding.
///
/// This is deliberately bounded and does not appear in failure diagnostics.
final class CharsetEvidence {
  CharsetEvidence(String reason) : reason = _validateReason(reason);

  final String reason;

  static String _validateReason(String value) {
    if (value.isEmpty || value.length > 256) {
      throw ArgumentError.value(value, 'reason');
    }
    if (value.codeUnits.any((unit) => unit < 0x20 || unit == 0x7f)) {
      throw ArgumentError.value(value, 'reason');
    }
    return value;
  }
}

/// Safe metadata describing replacements made in replacement mode.
final class ReplacementMetadata {
  ReplacementMetadata({required this.count, required Iterable<int> offsets})
    : offsets = List<int>.unmodifiable(offsets) {
    if (count < 0 || count != this.offsets.length) {
      throw ArgumentError('Replacement count must match its offsets.');
    }
  }

  ReplacementMetadata.none() : count = 0, offsets = const [];

  final int count;
  final List<int> offsets;

  bool get wasUsed => count != 0;
}

enum CharsetFailureKind {
  invalidByte,
  invalidContinuation,
  truncatedSequence,
  unmappedSequence,
  invalidUnicodeScalar,
  unrepresentableCodePoint,
}

/// Safe failure information. It contains no input bytes or response text.
final class CharsetFailureInfo {
  const CharsetFailureInfo({
    required this.encoding,
    required this.kind,
    required this.offset,
  });

  final SourceEncoding encoding;
  final CharsetFailureKind kind;
  final int offset;

  @override
  bool operator ==(Object other) =>
      other is CharsetFailureInfo &&
      other.encoding == encoding &&
      other.kind == kind &&
      other.offset == offset;

  @override
  int get hashCode => Object.hash(encoding, kind, offset);
}

final class CharsetDecodeException implements Exception {
  const CharsetDecodeException(this.info);

  final CharsetFailureInfo info;

  @override
  String toString() =>
      'CharsetDecodeException(${info.encoding.name}, '
      '${info.kind.name}, offset ${info.offset})';
}

final class CharsetEncodeException implements Exception {
  const CharsetEncodeException(this.info);

  final CharsetFailureInfo info;

  @override
  String toString() =>
      'CharsetEncodeException(${info.encoding.name}, '
      '${info.kind.name}, offset ${info.offset})';
}

/// Unicode output plus the provenance and replacement audit for one decode.
final class DecodedDocument {
  DecodedDocument({
    required this.text,
    required this.encoding,
    required this.evidence,
    required this.replacements,
  });

  final String text;
  final SourceEncoding encoding;
  final CharsetEvidence evidence;
  final ReplacementMetadata replacements;
}
