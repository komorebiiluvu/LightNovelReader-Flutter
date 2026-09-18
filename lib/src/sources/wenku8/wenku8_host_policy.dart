import '../../source/source_operation.dart';

/// Characterized origins and operation routing for the built-in Wenku8
/// source. This policy accepts origins only; it never accepts a caller URL.
final class Wenku8HostPolicy {
  const Wenku8HostPolicy();

  Uri originFor(SourceOperation operation, {Uri? hostOverride}) {
    final expectedHost = switch (operation) {
      SourceOperation.search || SourceOperation.explore => 'www.wenku8.net',
      SourceOperation.bookDetail ||
      SourceOperation.catalog ||
      SourceOperation.chapterContent => 'www.wenku8.cc',
      SourceOperation.authentication => throw ArgumentError.value(
        operation,
        'operation',
      ),
    };
    if (hostOverride == null) {
      return Uri(scheme: 'https', host: expectedHost);
    }
    if (hostOverride.scheme.toLowerCase() != 'https') {
      throw const FormatException('Wenku8 requires HTTPS origins.');
    }
    if (hostOverride.userInfo.isNotEmpty) {
      throw const FormatException('Wenku8 origins cannot contain user-info.');
    }
    if (hostOverride.host.toLowerCase() != expectedHost ||
        hostOverride.hasPort && hostOverride.port != 443 ||
        hostOverride.path.isNotEmpty && hostOverride.path != '/' ||
        hostOverride.query.isNotEmpty ||
        hostOverride.fragment.isNotEmpty) {
      throw const FormatException('Wenku8 origin is not an approved origin.');
    }
    return Uri(scheme: 'https', host: expectedHost);
  }
}
