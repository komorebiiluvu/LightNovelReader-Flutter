/// Bounded timeout controls for one transport operation.
final class SourceTimeoutPolicy {
  SourceTimeoutPolicy({
    this.connect = const Duration(seconds: 10),
    this.send = const Duration(seconds: 10),
    this.receive = const Duration(seconds: 30),
    this.operation = const Duration(seconds: 45),
  }) {
    _requirePositive(connect, 'connect');
    _requirePositive(send, 'send');
    _requirePositive(receive, 'receive');
    _requirePositive(operation, 'operation');
  }

  final Duration connect;
  final Duration send;
  final Duration receive;
  final Duration operation;
}

/// Finite retry policy. A value of one means the initial attempt only.
final class SourceRetryPolicy {
  SourceRetryPolicy({
    this.maxAttempts = 1,
    this.baseDelay = const Duration(milliseconds: 250),
    this.maxDelay = const Duration(seconds: 5),
  }) {
    if (maxAttempts < 1 || maxAttempts > 5) {
      throw ArgumentError.value(maxAttempts, 'maxAttempts');
    }
    if (baseDelay < Duration.zero) {
      throw ArgumentError.value(baseDelay, 'baseDelay');
    }
    if (maxDelay < baseDelay) {
      throw ArgumentError.value(maxDelay, 'maxDelay');
    }
  }

  final int maxAttempts;
  final Duration baseDelay;
  final Duration maxDelay;

  Duration delayForRetry(int retryIndex) {
    if (retryIndex < 1 || retryIndex > maxAttempts) {
      throw ArgumentError.value(retryIndex, 'retryIndex');
    }
    var milliseconds = baseDelay.inMilliseconds;
    for (var index = 1; index < retryIndex; index++) {
      milliseconds = (milliseconds * 2).clamp(0, maxDelay.inMilliseconds);
    }
    return Duration(
      milliseconds: milliseconds.clamp(0, maxDelay.inMilliseconds),
    );
  }
}

enum SourceRedirectMode { noFollow, follow }

/// Redirect controls with an explicit allowlist of approved origins.
final class SourceRedirectPolicy {
  const SourceRedirectPolicy.noFollow()
    : mode = SourceRedirectMode.noFollow,
      maxRedirects = 0,
      allowedOrigins = const <String>{};

  SourceRedirectPolicy.follow({
    this.maxRedirects = 3,
    Set<String> allowedOrigins = const <String>{},
  }) : mode = SourceRedirectMode.follow,
       allowedOrigins = Set<String>.unmodifiable(allowedOrigins);

  final SourceRedirectMode mode;
  final int maxRedirects;
  final Set<String> allowedOrigins;

  SourceRedirectPolicy._({
    required this.mode,
    required this.maxRedirects,
    required Set<String> allowedOrigins,
  }) : allowedOrigins = Set<String>.unmodifiable(allowedOrigins);

  SourceRedirectPolicy normalizedFor(Uri requestUri) {
    if (mode == SourceRedirectMode.noFollow) return this;
    if (maxRedirects < 0 || maxRedirects > 10) {
      throw ArgumentError.value(maxRedirects, 'maxRedirects');
    }
    final origins = <String>{};
    for (final origin in allowedOrigins) {
      final uri = Uri.tryParse(origin);
      if (uri == null ||
          uri.host.isEmpty ||
          (uri.scheme != 'http' && uri.scheme != 'https') ||
          uri.userInfo.isNotEmpty) {
        throw ArgumentError.value(origin, 'allowedOrigins');
      }
      origins.add(_origin(uri));
    }
    if (origins.isEmpty) origins.add(_origin(requestUri));
    return SourceRedirectPolicy._(
      mode: mode,
      maxRedirects: maxRedirects,
      allowedOrigins: origins,
    );
  }

  bool allows(Uri uri, Uri initialUri) {
    if (mode == SourceRedirectMode.noFollow) return false;
    final normalized = normalizedFor(initialUri);
    return normalized.allowedOrigins.contains(_origin(uri));
  }
}

final class SourceTransportPolicy {
  SourceTransportPolicy({
    SourceTimeoutPolicy? timeout,
    SourceRetryPolicy? retry,
    SourceRedirectPolicy? redirects,
    this.maxResponseBytes = 4 * 1024 * 1024,
  }) : timeout = timeout ?? SourceTimeoutPolicy(),
       retry = retry ?? SourceRetryPolicy(),
       redirects = redirects ?? const SourceRedirectPolicy.noFollow() {
    if (maxResponseBytes < 1) {
      throw ArgumentError.value(maxResponseBytes, 'maxResponseBytes');
    }
  }

  final SourceTimeoutPolicy timeout;
  final SourceRetryPolicy retry;
  final SourceRedirectPolicy redirects;
  final int maxResponseBytes;
}

/// Finite application-owned transport capacity. Queueing is per
/// transport authority and is FIFO; values are deliberately injectable at
/// transport construction time.
final class SourceTransportCapacityPolicy {
  SourceTransportCapacityPolicy({
    this.maxConcurrentRequests = 4,
    this.maxQueuedRequests = 16,
  }) {
    if (maxConcurrentRequests < 1 || maxConcurrentRequests > 32) {
      throw ArgumentError.value(maxConcurrentRequests, 'maxConcurrentRequests');
    }
    if (maxQueuedRequests < 0 || maxQueuedRequests > 128) {
      throw ArgumentError.value(maxQueuedRequests, 'maxQueuedRequests');
    }
  }

  final int maxConcurrentRequests;
  final int maxQueuedRequests;
}

String _origin(Uri uri) {
  final scheme = uri.scheme.toLowerCase();
  final host = uri.host.toLowerCase();
  final port =
      uri.hasPort &&
          !((scheme == 'https' && uri.port == 443) ||
              (scheme == 'http' && uri.port == 80))
      ? ':${uri.port}'
      : '';
  return '$scheme://$host$port';
}

void _requirePositive(Duration value, String name) {
  if (value <= Duration.zero) throw ArgumentError.value(value, name);
}
