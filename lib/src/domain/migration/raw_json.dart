import 'dart:convert';

import 'migration_failure.dart';

/// Bounds used by the raw migration parser and planner.
///
/// The defaults are intentionally large enough for a normal legacy backup but
/// finite. Tests and controlled callers may inject lower values.
final class MigrationResourceLimits {
  const MigrationResourceLimits({
    this.maxInputBytes = 16 * 1024 * 1024,
    this.maxNestingDepth = 64,
    this.maxObjectFields = 4096,
    this.maxArrayElements = 10000,
    this.maxStringLength = 1024 * 1024,
    this.maxParsedNodes = 100000,
    this.maxPlannedUnits = 10000,
  });

  final int maxInputBytes;
  final int maxNestingDepth;
  final int maxObjectFields;
  final int maxArrayElements;
  final int maxStringLength;
  final int maxParsedNodes;
  final int maxPlannedUnits;
}

sealed class RawJsonValue {
  const RawJsonValue();
}

final class RawJsonNull extends RawJsonValue {
  const RawJsonNull();
}

final class RawJsonBoolean extends RawJsonValue {
  const RawJsonBoolean(this.value);

  final bool value;
}

final class RawJsonString extends RawJsonValue {
  const RawJsonString(this.value);

  final String value;
}

/// An integer is retained separately from a non-integral JSON number.
final class RawJsonInteger extends RawJsonValue {
  const RawJsonInteger(this.value);

  final int value;
}

final class RawJsonNumber extends RawJsonValue {
  const RawJsonNumber(this.value);

  final double value;
}

final class RawJsonArray extends RawJsonValue {
  RawJsonArray(Iterable<RawJsonValue> values)
    : values = List<RawJsonValue>.unmodifiable(values);

  final List<RawJsonValue> values;
}

final class RawJsonField {
  const RawJsonField(this.name, this.value);

  final String name;
  final RawJsonValue value;
}

final class RawJsonObject extends RawJsonValue {
  RawJsonObject(Iterable<RawJsonField> fields)
    : fields = List<RawJsonField>.unmodifiable(fields);

  final List<RawJsonField> fields;

  Set<String> get duplicateKeys {
    final seen = <String>{};
    final duplicates = <String>{};
    for (final field in fields) {
      if (!seen.add(field.name)) duplicates.add(field.name);
    }
    return Set<String>.unmodifiable(duplicates);
  }

  bool get hasDuplicateKeys => duplicateKeys.isNotEmpty;

  bool containsDuplicateKeysDeep() {
    if (hasDuplicateKeys) return true;
    for (final field in fields) {
      if (_containsDuplicate(field.value)) return true;
    }
    return false;
  }

  RawJsonValue? valueFor(String name) {
    for (final field in fields) {
      if (field.name == name) return field.value;
    }
    return null;
  }

  Map<String, RawJsonValue> uniqueValues() {
    if (hasDuplicateKeys) {
      throw const MigrationFailure(MigrationFailureReason.duplicateKey);
    }
    return <String, RawJsonValue>{
      for (final field in fields) field.name: field.value,
    };
  }
}

bool _containsDuplicate(RawJsonValue value) => switch (value) {
  RawJsonObject object => object.containsDuplicateKeysDeep(),
  RawJsonArray array => array.values.any(_containsDuplicate),
  _ => false,
};

/// Small duplicate-aware JSON parser used only at the migration boundary.
final class RawJsonParser {
  RawJsonParser({this.limits = const MigrationResourceLimits()});

  final MigrationResourceLimits limits;
  late String _source;
  int _index = 0;
  int _nodes = 0;

  RawJsonValue parse(List<int> bytes, {bool allowDuplicateKeys = false}) {
    if (bytes.length > limits.maxInputBytes) _limit();
    try {
      _source = utf8.decode(bytes, allowMalformed: false);
    } on FormatException {
      throw const MigrationFailure(MigrationFailureReason.invalidUtf8);
    }
    _index = 0;
    _nodes = 0;
    _skipWhitespace();
    if (_index == _source.length) _malformed();
    final result = _parseValue(0, allowDuplicateKeys);
    _skipWhitespace();
    if (_index != _source.length) _malformed();
    return result;
  }

  RawJsonValue _parseValue(int depth, bool allowDuplicateKeys) {
    if (depth > limits.maxNestingDepth) _limit();
    _node();
    if (_index >= _source.length) _malformed();
    return switch (_source.codeUnitAt(_index)) {
      0x6E => _parseLiteral('null', const RawJsonNull()),
      0x74 => _parseLiteral('true', const RawJsonBoolean(true)),
      0x66 => _parseLiteral('false', const RawJsonBoolean(false)),
      0x22 => RawJsonString(_parseString()),
      0x5B => _parseArray(depth, allowDuplicateKeys),
      0x7B => _parseObject(depth, allowDuplicateKeys),
      0x2D || >= 0x30 && <= 0x39 => _parseNumber(),
      _ => _malformed(),
    };
  }

  RawJsonValue _parseLiteral(String literal, RawJsonValue value) {
    if (!_source.startsWith(literal, _index)) _malformed();
    _index += literal.length;
    return value;
  }

  RawJsonArray _parseArray(int depth, bool allowDuplicateKeys) {
    _index++;
    _skipWhitespace();
    final values = <RawJsonValue>[];
    if (_consume(0x5D)) return RawJsonArray(values);
    while (true) {
      if (values.length >= limits.maxArrayElements) _limit();
      values.add(_parseValue(depth + 1, allowDuplicateKeys));
      _skipWhitespace();
      if (_consume(0x5D)) return RawJsonArray(values);
      if (!_consume(0x2C)) _malformed();
      _skipWhitespace();
      if (_index >= _source.length) _malformed();
    }
  }

  RawJsonObject _parseObject(int depth, bool allowDuplicateKeys) {
    _index++;
    _skipWhitespace();
    final fields = <RawJsonField>[];
    final names = <String>{};
    if (_consume(0x7D)) return RawJsonObject(fields);
    while (true) {
      if (fields.length >= limits.maxObjectFields) _limit();
      if (_index >= _source.length || _source.codeUnitAt(_index) != 0x22) {
        _malformed();
      }
      final name = _parseString();
      if (!names.add(name) && !allowDuplicateKeys) {
        throw const MigrationFailure(MigrationFailureReason.duplicateKey);
      }
      _skipWhitespace();
      if (!_consume(0x3A)) _malformed();
      _skipWhitespace();
      fields.add(
        RawJsonField(name, _parseValue(depth + 1, allowDuplicateKeys)),
      );
      _skipWhitespace();
      if (_consume(0x7D)) return RawJsonObject(fields);
      if (!_consume(0x2C)) _malformed();
      _skipWhitespace();
      if (_index >= _source.length) _malformed();
    }
  }

  String _parseString() {
    if (!_consume(0x22)) _malformed();
    final buffer = StringBuffer();
    while (_index < _source.length) {
      final code = _source.codeUnitAt(_index++);
      if (code == 0x22) {
        final result = buffer.toString();
        if (result.length > limits.maxStringLength) _limit();
        return result;
      }
      if (code < 0x20) _malformed();
      if (code != 0x5C) {
        if (code >= 0xD800 && code <= 0xDBFF) {
          if (_index >= _source.length) _malformed();
          final low = _source.codeUnitAt(_index);
          if (low < 0xDC00 || low > 0xDFFF) _malformed();
          _index++;
          buffer.writeCharCode(code);
          buffer.writeCharCode(low);
          continue;
        }
        if (code >= 0xDC00 && code <= 0xDFFF) _malformed();
        buffer.writeCharCode(code);
        continue;
      }
      if (_index >= _source.length) _malformed();
      final escape = _source.codeUnitAt(_index++);
      switch (escape) {
        case 0x22:
        case 0x5C:
        case 0x2F:
          buffer.writeCharCode(escape);
        case 0x62:
          buffer.writeCharCode(0x08);
        case 0x66:
          buffer.writeCharCode(0x0C);
        case 0x6E:
          buffer.writeCharCode(0x0A);
        case 0x72:
          buffer.writeCharCode(0x0D);
        case 0x74:
          buffer.writeCharCode(0x09);
        case 0x75:
          final codeUnit = _parseHexEscape();
          if (codeUnit >= 0xD800 && codeUnit <= 0xDBFF) {
            if (!_source.startsWith(r'\u', _index)) _malformed();
            _index += 2;
            final low = _parseHexEscape();
            if (low < 0xDC00 || low > 0xDFFF) _malformed();
            buffer.writeCharCode(codeUnit);
            buffer.writeCharCode(low);
          } else if (codeUnit >= 0xDC00 && codeUnit <= 0xDFFF) {
            _malformed();
          } else {
            buffer.writeCharCode(codeUnit);
          }
        default:
          _malformed();
      }
      if (buffer.length > limits.maxStringLength) _limit();
    }
    _malformed();
  }

  int _parseHexEscape() {
    if (_index + 4 > _source.length) _malformed();
    var value = 0;
    for (var i = 0; i < 4; i++) {
      final digit = _hex(_source.codeUnitAt(_index++));
      if (digit < 0) _malformed();
      value = value * 16 + digit;
    }
    return value;
  }

  RawJsonValue _parseNumber() {
    final start = _index;
    if (_consume(0x2D) && _index >= _source.length) _malformed();
    if (_index < _source.length && _source.codeUnitAt(_index) == 0x30) {
      _index++;
      if (_index < _source.length && _digit(_source.codeUnitAt(_index))) {
        _malformed();
      }
    } else {
      if (_index >= _source.length ||
          !_digitOneToNine(_source.codeUnitAt(_index))) {
        _malformed();
      }
      while (_index < _source.length && _digit(_source.codeUnitAt(_index))) {
        _index++;
      }
    }
    var nonInteger = false;
    if (_consume(0x2E)) {
      nonInteger = true;
      if (_index >= _source.length || !_digit(_source.codeUnitAt(_index))) {
        _malformed();
      }
      while (_index < _source.length && _digit(_source.codeUnitAt(_index))) {
        _index++;
      }
    }
    if (_index < _source.length &&
        (_source.codeUnitAt(_index) == 0x65 ||
            _source.codeUnitAt(_index) == 0x45)) {
      nonInteger = true;
      _index++;
      if (_index < _source.length &&
          (_source.codeUnitAt(_index) == 0x2B ||
              _source.codeUnitAt(_index) == 0x2D)) {
        _index++;
      }
      if (_index >= _source.length || !_digit(_source.codeUnitAt(_index))) {
        _malformed();
      }
      while (_index < _source.length && _digit(_source.codeUnitAt(_index))) {
        _index++;
      }
    }
    final token = _source.substring(start, _index);
    if (!nonInteger) {
      final integer = int.tryParse(token);
      if (integer != null) return RawJsonInteger(integer);
    }
    final number = double.tryParse(token);
    if (number == null || !number.isFinite) _malformed();
    return RawJsonNumber(number);
  }

  void _skipWhitespace() {
    while (_index < _source.length) {
      switch (_source.codeUnitAt(_index)) {
        case 0x20:
        case 0x09:
        case 0x0A:
        case 0x0D:
          _index++;
        default:
          return;
      }
    }
  }

  bool _consume(int code) {
    if (_index < _source.length && _source.codeUnitAt(_index) == code) {
      _index++;
      return true;
    }
    return false;
  }

  void _node() {
    _nodes++;
    if (_nodes > limits.maxParsedNodes) _limit();
  }

  Never _malformed() =>
      throw const MigrationFailure(MigrationFailureReason.malformedJson);

  Never _limit() =>
      throw const MigrationFailure(MigrationFailureReason.resourceLimit);

  static int _hex(int code) {
    if (code >= 0x30 && code <= 0x39) return code - 0x30;
    if (code >= 0x41 && code <= 0x46) return code - 0x41 + 10;
    if (code >= 0x61 && code <= 0x66) return code - 0x61 + 10;
    return -1;
  }

  static bool _digit(int code) => code >= 0x30 && code <= 0x39;

  static bool _digitOneToNine(int code) => code >= 0x31 && code <= 0x39;
}
