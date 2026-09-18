import 'generated/gb18030_data.g.dart';
import 'charset_models.dart';

final class CharsetDecoder {
  const CharsetDecoder();

  DecodedDocument decode(
    RawBytes input, {
    required SourceEncoding encoding,
    CharsetErrorMode errorMode = CharsetErrorMode.strict,
    required CharsetEvidence evidence,
  }) {
    final result = switch (encoding) {
      SourceEncoding.utf8 => _decodeUtf8(input, errorMode),
      SourceEncoding.legacyCp936Compatible => _decodeLegacy(input, errorMode),
      SourceEncoding.gb18030 => _decodeGb18030(input, errorMode),
    };
    return DecodedDocument(
      text: result.text,
      encoding: encoding,
      evidence: evidence,
      replacements: result.replacements,
    );
  }
}

final class CharsetEncoder {
  const CharsetEncoder();

  RawBytes encode(String text, {required SourceEncoding encoding}) {
    return switch (encoding) {
      SourceEncoding.utf8 => RawBytes(_encodeUtf8(text, encoding)),
      SourceEncoding.legacyCp936Compatible => RawBytes(
        _encodeLegacy(text, encoding),
      ),
      SourceEncoding.gb18030 => RawBytes(_encodeGb18030(text, encoding)),
    };
  }
}

final class _DecodeOutput {
  const _DecodeOutput(this.text, this.replacements);

  final String text;
  final ReplacementMetadata replacements;
}

_DecodeOutput _decodeUtf8(RawBytes input, CharsetErrorMode mode) {
  final output = StringBuffer();
  final replacements = <int>[];
  var offset = 0;
  while (offset < input.length) {
    final start = offset;
    final first = input[offset];
    if (first <= 0x7f) {
      output.writeCharCode(first);
      offset++;
      continue;
    }

    final width = switch (first) {
      >= 0xc2 && <= 0xdf => 2,
      >= 0xe0 && <= 0xef => 3,
      >= 0xf0 && <= 0xf4 => 4,
      _ => 0,
    };
    if (width == 0 || offset + width > input.length) {
      if (mode == CharsetErrorMode.strict) {
        throw CharsetDecodeException(
          CharsetFailureInfo(
            encoding: SourceEncoding.utf8,
            kind: width == 0
                ? CharsetFailureKind.invalidByte
                : CharsetFailureKind.truncatedSequence,
            offset: start,
          ),
        );
      }
      output.writeCharCode(0xfffd);
      replacements.add(start);
      offset++;
      continue;
    }

    final second = input[offset + 1];
    final validSecond = switch (first) {
      0xe0 => second >= 0xa0 && second <= 0xbf,
      0xed => second >= 0x80 && second <= 0x9f,
      0xf0 => second >= 0x90 && second <= 0xbf,
      0xf4 => second >= 0x80 && second <= 0x8f,
      _ => second >= 0x80 && second <= 0xbf,
    };
    var valid = validSecond;
    for (var index = 2; valid && index < width; index++) {
      valid = input[offset + index] >= 0x80 && input[offset + index] <= 0xbf;
    }
    if (!valid) {
      if (mode == CharsetErrorMode.strict) {
        throw CharsetDecodeException(
          CharsetFailureInfo(
            encoding: SourceEncoding.utf8,
            kind: CharsetFailureKind.invalidContinuation,
            offset: start,
          ),
        );
      }
      output.writeCharCode(0xfffd);
      replacements.add(start);
      offset++;
      continue;
    }

    var codePoint =
        first &
        (width == 2
            ? 0x1f
            : width == 3
            ? 0x0f
            : 0x07);
    for (var index = 1; index < width; index++) {
      codePoint = (codePoint << 6) | (input[offset + index] & 0x3f);
    }
    output.write(String.fromCharCodes([codePoint]));
    offset += width;
  }
  return _DecodeOutput(
    output.toString(),
    ReplacementMetadata(count: replacements.length, offsets: replacements),
  );
}

_DecodeOutput _decodeLegacy(RawBytes input, CharsetErrorMode mode) {
  final output = StringBuffer();
  final replacements = <int>[];
  var offset = 0;
  while (offset < input.length) {
    final first = input[offset];
    if (first <= 0x7f) {
      output.writeCharCode(first);
      offset++;
      continue;
    }
    if (first == 0x80) {
      output.writeCharCode(0x20ac);
      offset++;
      continue;
    }
    if (first < 0x81 || first > 0xfe) {
      offset = _handleInvalid(
        output,
        replacements,
        offset,
        mode,
        CharsetFailureKind.invalidByte,
        SourceEncoding.legacyCp936Compatible,
      );
      continue;
    }
    if (offset + 1 >= input.length) {
      offset = _handleInvalid(
        output,
        replacements,
        offset,
        mode,
        CharsetFailureKind.truncatedSequence,
        SourceEncoding.legacyCp936Compatible,
      );
      continue;
    }
    final second = input[offset + 1];
    if (!_isDoubleByteTrail(second)) {
      offset = _handleInvalid(
        output,
        replacements,
        offset,
        mode,
        CharsetFailureKind.invalidContinuation,
        SourceEncoding.legacyCp936Compatible,
      );
      continue;
    }
    final pointer = _doubleBytePointer(first, second);
    final codePoint = _twoByteCodePoint(pointer);
    if (codePoint == null) {
      offset = _handleInvalid(
        output,
        replacements,
        offset,
        mode,
        CharsetFailureKind.unmappedSequence,
        SourceEncoding.legacyCp936Compatible,
      );
      continue;
    }
    output.write(String.fromCharCodes([codePoint]));
    offset += 2;
  }
  return _DecodeOutput(
    output.toString(),
    ReplacementMetadata(count: replacements.length, offsets: replacements),
  );
}

_DecodeOutput _decodeGb18030(RawBytes input, CharsetErrorMode mode) {
  final output = StringBuffer();
  final replacements = <int>[];
  var offset = 0;
  while (offset < input.length) {
    final first = input[offset];
    if (first <= 0x7f) {
      output.writeCharCode(first);
      offset++;
      continue;
    }
    if (first == 0x80) {
      output.writeCharCode(0x20ac);
      offset++;
      continue;
    }
    if (first < 0x81 || first > 0xfe || offset + 1 >= input.length) {
      offset = _handleInvalid(
        output,
        replacements,
        offset,
        mode,
        offset + 1 >= input.length
            ? CharsetFailureKind.truncatedSequence
            : CharsetFailureKind.invalidByte,
        SourceEncoding.gb18030,
      );
      continue;
    }
    final second = input[offset + 1];
    if (second >= 0x30 && second <= 0x39) {
      if (offset + 2 >= input.length) {
        offset = _handleInvalid(
          output,
          replacements,
          offset,
          mode,
          CharsetFailureKind.truncatedSequence,
          SourceEncoding.gb18030,
        );
        continue;
      }
      final third = input[offset + 2];
      if (third < 0x81 || third > 0xfe) {
        offset = _handleInvalid(
          output,
          replacements,
          offset,
          mode,
          CharsetFailureKind.invalidContinuation,
          SourceEncoding.gb18030,
        );
        continue;
      }
      if (offset + 3 >= input.length) {
        offset = _handleInvalid(
          output,
          replacements,
          offset,
          mode,
          CharsetFailureKind.truncatedSequence,
          SourceEncoding.gb18030,
        );
        continue;
      }
      final fourth = input[offset + 3];
      if (fourth < 0x30 || fourth > 0x39) {
        offset = _handleInvalid(
          output,
          replacements,
          offset,
          mode,
          CharsetFailureKind.invalidContinuation,
          SourceEncoding.gb18030,
        );
        continue;
      }
      final pointer = _fourBytePointer(first, second, third, fourth);
      final codePoint = _rangeCodePoint(pointer);
      if (codePoint == null) {
        offset = _handleInvalid(
          output,
          replacements,
          offset,
          mode,
          CharsetFailureKind.unmappedSequence,
          SourceEncoding.gb18030,
        );
        continue;
      }
      output.write(String.fromCharCodes([codePoint]));
      offset += 4;
      continue;
    }
    if (!_isDoubleByteTrail(second)) {
      offset = _handleInvalid(
        output,
        replacements,
        offset,
        mode,
        CharsetFailureKind.invalidContinuation,
        SourceEncoding.gb18030,
      );
      continue;
    }
    final codePoint = _twoByteCodePoint(_doubleBytePointer(first, second));
    if (codePoint == null) {
      offset = _handleInvalid(
        output,
        replacements,
        offset,
        mode,
        CharsetFailureKind.unmappedSequence,
        SourceEncoding.gb18030,
      );
      continue;
    }
    output.write(String.fromCharCodes([codePoint]));
    offset += 2;
  }
  return _DecodeOutput(
    output.toString(),
    ReplacementMetadata(count: replacements.length, offsets: replacements),
  );
}

int _handleInvalid(
  StringBuffer output,
  List<int> replacements,
  int offset,
  CharsetErrorMode mode,
  CharsetFailureKind kind,
  SourceEncoding encoding,
) {
  if (mode == CharsetErrorMode.strict) {
    throw CharsetDecodeException(
      CharsetFailureInfo(encoding: encoding, kind: kind, offset: offset),
    );
  }
  output.writeCharCode(0xfffd);
  replacements.add(offset);
  return offset + 1;
}

bool _isDoubleByteTrail(int value) =>
    value >= 0x40 && value <= 0x7e || value >= 0x80 && value <= 0xfe;

int _doubleBytePointer(int lead, int trail) =>
    (lead - 0x81) * 190 + (trail < 0x7f ? trail - 0x40 : trail - 0x41);

int? _twoByteCodePoint(int pointer) {
  if (pointer < 0 || pointer >= gb18030TwoByteCodePoints.length) return null;
  final codePoint = gb18030TwoByteCodePoints[pointer];
  return codePoint == 0 ? null : codePoint;
}

int _fourBytePointer(int first, int second, int third, int fourth) =>
    ((first - 0x81) * 10 * 126 * 10) +
    ((second - 0x30) * 126 * 10) +
    ((third - 0x81) * 10) +
    (fourth - 0x30);

int? _rangeCodePoint(int pointer) {
  if (pointer < 0 || pointer > 1237575) return null;
  var low = 0;
  var high = gb18030RangePointers.length;
  while (low < high) {
    final middle = (low + high) >> 1;
    if (gb18030RangePointers[middle] <= pointer) {
      low = middle + 1;
    } else {
      high = middle;
    }
  }
  final index = low - 1;
  if (index < 0) return null;
  if (pointer > 39419 && pointer < 189000) return null;
  final codePoint =
      gb18030RangeCodePoints[index] + pointer - gb18030RangePointers[index];
  if (codePoint > 0x10ffff || codePoint >= 0xd800 && codePoint <= 0xdfff) {
    return null;
  }
  return codePoint;
}

List<int> _encodeUtf8(String text, SourceEncoding encoding) {
  final result = <int>[];
  for (final codePoint in _scalars(text, encoding)) {
    if (codePoint <= 0x7f) {
      result.add(codePoint);
    } else if (codePoint <= 0x7ff) {
      result.addAll([0xc0 | (codePoint >> 6), 0x80 | (codePoint & 0x3f)]);
    } else if (codePoint <= 0xffff) {
      result.addAll([
        0xe0 | (codePoint >> 12),
        0x80 | ((codePoint >> 6) & 0x3f),
        0x80 | (codePoint & 0x3f),
      ]);
    } else {
      result.addAll([
        0xf0 | (codePoint >> 18),
        0x80 | ((codePoint >> 12) & 0x3f),
        0x80 | ((codePoint >> 6) & 0x3f),
        0x80 | (codePoint & 0x3f),
      ]);
    }
  }
  return result;
}

List<int> _encodeLegacy(String text, SourceEncoding encoding) {
  final result = <int>[];
  for (final codePoint in _scalars(text, encoding)) {
    if (codePoint <= 0x7f) {
      result.add(codePoint);
      continue;
    }
    final pointer = _twoBytePointerForCodePoint(codePoint);
    if (pointer == null) {
      throw CharsetEncodeException(
        CharsetFailureInfo(
          encoding: encoding,
          kind: CharsetFailureKind.unrepresentableCodePoint,
          offset: result.length,
        ),
      );
    }
    result.addAll(_bytesForDoubleBytePointer(pointer));
  }
  return result;
}

List<int> _encodeGb18030(String text, SourceEncoding encoding) {
  final result = <int>[];
  for (final codePoint in _scalars(text, encoding)) {
    if (codePoint <= 0x7f) {
      result.add(codePoint);
      continue;
    }
    final twoBytePointer = _twoBytePointerForCodePoint(codePoint);
    if (twoBytePointer != null) {
      result.addAll(_bytesForDoubleBytePointer(twoBytePointer));
      continue;
    }
    final fourBytePointer = _fourBytePointerForCodePoint(codePoint);
    if (fourBytePointer == null) {
      throw CharsetEncodeException(
        CharsetFailureInfo(
          encoding: encoding,
          kind: CharsetFailureKind.unrepresentableCodePoint,
          offset: result.length,
        ),
      );
    }
    result.addAll(_bytesForFourBytePointer(fourBytePointer));
  }
  return result;
}

Iterable<int> _scalars(String text, SourceEncoding encoding) sync* {
  final units = text.codeUnits;
  for (var index = 0; index < units.length; index++) {
    final unit = units[index];
    if (unit >= 0xd800 && unit <= 0xdbff) {
      if (index + 1 >= units.length ||
          units[index + 1] < 0xdc00 ||
          units[index + 1] > 0xdfff) {
        throw CharsetEncodeException(
          CharsetFailureInfo(
            encoding: encoding,
            kind: CharsetFailureKind.invalidUnicodeScalar,
            offset: index,
          ),
        );
      }
      final low = units[++index];
      yield 0x10000 + ((unit - 0xd800) << 10) + low - 0xdc00;
    } else if (unit >= 0xdc00 && unit <= 0xdfff) {
      throw CharsetEncodeException(
        CharsetFailureInfo(
          encoding: encoding,
          kind: CharsetFailureKind.invalidUnicodeScalar,
          offset: index,
        ),
      );
    } else {
      yield unit;
    }
  }
}

int? _twoBytePointerForCodePoint(int codePoint) {
  var low = 0;
  var high = gb18030TwoByteReversePairs.length ~/ 2;
  while (low < high) {
    final middle = (low + high) >> 1;
    final value = gb18030TwoByteReversePairs[middle * 2];
    if (value < codePoint) {
      low = middle + 1;
    } else {
      high = middle;
    }
  }
  if (low >= gb18030TwoByteReversePairs.length ~/ 2 ||
      gb18030TwoByteReversePairs[low * 2] != codePoint) {
    return null;
  }
  return gb18030TwoByteReversePairs[low * 2 + 1];
}

List<int> _bytesForDoubleBytePointer(int pointer) {
  final lead = pointer ~/ 190 + 0x81;
  final trailPointer = pointer % 190;
  final trail = trailPointer < 63 ? trailPointer + 0x40 : trailPointer + 0x41;
  return [lead, trail];
}

int? _fourBytePointerForCodePoint(int codePoint) {
  var low = 0;
  var high = gb18030RangeCodePoints.length;
  while (low < high) {
    final middle = (low + high) >> 1;
    if (gb18030RangeCodePoints[middle] <= codePoint) {
      low = middle + 1;
    } else {
      high = middle;
    }
  }
  final index = low - 1;
  if (index < 0) return null;
  final pointer =
      gb18030RangePointers[index] + codePoint - gb18030RangeCodePoints[index];
  if (pointer < gb18030RangePointers[index] ||
      pointer > 1237575 ||
      pointer > 39419 && pointer < 189000 ||
      _rangeCodePoint(pointer) != codePoint) {
    return null;
  }
  return pointer;
}

List<int> _bytesForFourBytePointer(int pointer) {
  final first = pointer ~/ (10 * 126 * 10);
  final remainder1 = pointer % (10 * 126 * 10);
  final second = remainder1 ~/ (126 * 10);
  final remainder2 = remainder1 % (126 * 10);
  final third = remainder2 ~/ 10;
  final fourth = remainder2 % 10;
  return [first + 0x81, second + 0x30, third + 0x81, fourth + 0x30];
}
