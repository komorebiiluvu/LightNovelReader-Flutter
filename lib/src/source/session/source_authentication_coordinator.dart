import 'dart:async';

import '../../domain/identity/opaque_ids.dart';
import '../source_cancellation.dart';
import '../source_failure.dart';

/// Coordinates provider-neutral authentication work without storing
/// credentials. Operations for one Source are serialized; other Sources are
/// independent.
final class SourceAuthenticationCoordinator {
  SourceAuthenticationCoordinator({
    this.maxQueuedPerSource = 4,
    this.maxWait = const Duration(seconds: 30),
  }) {
    if (maxQueuedPerSource < 0 || maxQueuedPerSource > 32) {
      throw ArgumentError.value(maxQueuedPerSource, 'maxQueuedPerSource');
    }
    if (maxWait <= Duration.zero) {
      throw ArgumentError.value(maxWait, 'maxWait');
    }
  }

  final int maxQueuedPerSource;
  final Duration maxWait;
  final Map<SourceId, _AuthenticationGate> _gates = {};

  Future<T> run<T>(
    SourceId sourceId,
    SourceCancellation cancellation,
    Future<T> Function() operation,
  ) => _gates
      .putIfAbsent(
        sourceId,
        () => _AuthenticationGate(maxQueuedPerSource, maxWait),
      )
      .run(cancellation, operation);
}

final class _AuthenticationGate {
  _AuthenticationGate(this.maxQueued, this.maxWait);

  final int maxQueued;
  final Duration maxWait;
  var _running = false;
  final List<_AuthenticationWaiter<dynamic>> _queue = [];

  Future<T> run<T>(
    SourceCancellation cancellation,
    Future<T> Function() operation,
  ) async {
    cancellation.throwIfCancelled();
    final permit = await _acquire(cancellation);
    try {
      return await operation();
    } finally {
      permit.release();
    }
  }

  Future<_AuthenticationPermit> _acquire(SourceCancellation cancellation) {
    if (!_running) {
      _running = true;
      return Future.value(_AuthenticationPermit(this));
    }
    if (_queue.length >= maxQueued) {
      return Future.error(_authenticationQueueFailure());
    }
    final completer = Completer<_AuthenticationPermit>();
    late final _AuthenticationWaiter<_AuthenticationPermit> waiter;
    Timer? timer;
    void Function() removeCancellation = () {};
    void fail(SourceFailure failure) {
      if (completer.isCompleted) return;
      _queue.remove(waiter);
      timer?.cancel();
      removeCancellation();
      completer.completeError(failure);
    }

    waiter = _AuthenticationWaiter(completer, () {
      timer?.cancel();
      removeCancellation();
    });
    _queue.add(waiter);
    timer = Timer(maxWait, () => fail(_authenticationQueueFailure()));
    removeCancellation = cancellation.addListener(
      () => fail(SourceFailure.cancelled()),
    );
    return completer.future;
  }

  void _release() {
    while (_queue.isNotEmpty) {
      final waiter = _queue.removeAt(0);
      if (waiter.completer.isCompleted) continue;
      waiter.cleanup();
      waiter.completer.complete(_AuthenticationPermit(this));
      return;
    }
    _running = false;
  }
}

final class _AuthenticationWaiter<T> {
  const _AuthenticationWaiter(this.completer, this.cleanup);

  final Completer<T> completer;
  final void Function() cleanup;
}

final class _AuthenticationPermit {
  _AuthenticationPermit(this._gate);

  final _AuthenticationGate _gate;
  var _released = false;

  void release() {
    if (_released) return;
    _released = true;
    _gate._release();
  }
}

SourceFailure _authenticationQueueFailure() =>
    SourceFailure(code: SourceFailureCode.network, retryable: false);
