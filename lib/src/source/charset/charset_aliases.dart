import 'charset_models.dart';

/// Normalizes external labels at the one boundary where labels are accepted.
/// Core codec APIs use [SourceEncoding] and never accept arbitrary strings.
SourceEncoding normalizeSourceEncodingLabel(String label) {
  final normalized = label.trim().toLowerCase().replaceAll('_', '-');
  return switch (normalized) {
    'utf8' || 'utf-8' => SourceEncoding.utf8,
    'gbk' ||
    'gb2312' ||
    'gb2312-80' ||
    'cp936' ||
    'windows-936' => SourceEncoding.legacyCp936Compatible,
    'gb18030' || 'windows-54936' => SourceEncoding.gb18030,
    _ => throw ArgumentError.value(
      label,
      'label',
      'Unsupported encoding label.',
    ),
  };
}
