import 'source_failure.dart';

/// Lightweight dependency-free cancellation token for Source calls.
final class SourceCancellation {
  bool _cancelled = false;
  final Set<void Function()> _listeners = <void Function()>{};

  bool get isCancelled => _cancelled;

  /// Marks this operation obsolete. Repeated calls are harmless.
  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    final listeners = List<void Function()>.of(_listeners);
    _listeners.clear();
    for (final listener in listeners) {
      listener();
    }
  }

  /// Registers a synchronous notification and returns its removal callback.
  void Function() addListener(void Function() listener) {
    if (_cancelled) {
      listener();
      return () {};
    }
    _listeners.add(listener);
    return () => _listeners.remove(listener);
  }

  void throwIfCancelled() {
    if (_cancelled) throw SourceFailure.cancelled();
  }

  @override
  String toString() => 'SourceCancellation(<opaque>)';
}
