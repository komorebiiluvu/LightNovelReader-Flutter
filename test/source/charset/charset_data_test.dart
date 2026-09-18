import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_reader/src/source/charset/generated/gb18030_data.g.dart';

void main() {
  test('generated data carries pinned source provenance', () {
    expect(gb18030SourceIdentifier, startsWith('ff1c9a92'));
    expect(gb18030SourceDate, '2024-09-18');
    expect(gb18030IndexSha256, hasLength(64));
    expect(gb18030RangesSha256, hasLength(64));
  });

  test(
    'generated two-byte index is contiguous and independently auditable',
    () {
      expect(gb18030TwoByteCodePoints.length, 23940);
      expect(gb18030TwoByteReversePairs.length.isEven, isTrue);
      for (
        var index = 1;
        index < gb18030TwoByteReversePairs.length ~/ 2;
        index++
      ) {
        final previous = gb18030TwoByteReversePairs[(index - 1) * 2];
        final current = gb18030TwoByteReversePairs[index * 2];
        expect(current, greaterThanOrEqualTo(previous));
      }
      expect(gb18030TwoByteCodePoints[7886], 0xe000);
    },
  );

  test('generated ranges are sorted and pin the GB18030 zero pointer', () {
    expect(gb18030RangePointers.length, 207);
    expect(gb18030RangeCodePoints.length, 207);
    expect(gb18030RangePointers.first, 0);
    expect(gb18030RangeCodePoints.first, 0x0080);
    for (var index = 1; index < gb18030RangePointers.length; index++) {
      expect(
        gb18030RangePointers[index],
        greaterThan(gb18030RangePointers[index - 1]),
      );
      expect(
        gb18030RangeCodePoints[index],
        greaterThan(gb18030RangeCodePoints[index - 1]),
      );
    }
  });
}
