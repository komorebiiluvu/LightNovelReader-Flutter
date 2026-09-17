import '../domain/identity/opaque_ids.dart';
import 'source_auth.dart';
import 'source_capability.dart';
import 'source_failure.dart';
import 'book_source.dart';

enum SourceAvailability {
  available('available'),
  unavailable('unavailable'),
  disabled('disabled'),
  unresolved('unresolved');

  const SourceAvailability(this.wireName);

  final String wireName;
}

final class SourceRegistryEntry {
  const SourceRegistryEntry({
    required this.descriptor,
    required this.availability,
    this.source,
    this.authenticator,
  });

  final SourceDescriptor descriptor;
  final SourceAvailability availability;
  final BookSource? source;
  final SourceAuthenticator? authenticator;

  bool get isAvailable =>
      availability == SourceAvailability.available && source != null;
}

/// Runtime-only registry keyed exclusively by immutable SourceId.
final class SourceRegistry {
  final Map<SourceId, SourceRegistryEntry> _entries =
      <SourceId, SourceRegistryEntry>{};

  Map<SourceId, SourceRegistryEntry> get entries =>
      Map<SourceId, SourceRegistryEntry>.unmodifiable(_entries);

  void register(BookSource source, {SourceAuthenticator? authenticator}) {
    final descriptor = source.descriptor;
    _rejectDuplicate(descriptor.sourceId);
    if (authenticator != null &&
        authenticator.sourceId != descriptor.sourceId) {
      throw SourceFailure.invalidRequest();
    }
    _entries[descriptor.sourceId] = SourceRegistryEntry(
      descriptor: descriptor,
      availability: SourceAvailability.available,
      source: source,
      authenticator: authenticator,
    );
  }

  /// Retains a source descriptor when no runnable implementation is available.
  void registerUnavailable(
    SourceDescriptor descriptor, {
    SourceAvailability availability = SourceAvailability.unavailable,
  }) {
    _rejectDuplicate(descriptor.sourceId);
    if (availability == SourceAvailability.available) {
      throw SourceFailure.invalidRequest();
    }
    _entries[descriptor.sourceId] = SourceRegistryEntry(
      descriptor: descriptor,
      availability: availability,
    );
  }

  void setAvailability(SourceId sourceId, SourceAvailability availability) {
    final entry = _entries[sourceId];
    if (entry == null) throw SourceFailure.sourceUnavailable();
    if (availability == SourceAvailability.available && entry.source == null) {
      throw SourceFailure.invalidRequest();
    }
    _entries[sourceId] = SourceRegistryEntry(
      descriptor: entry.descriptor,
      availability: availability,
      source: entry.source,
      authenticator: entry.authenticator,
    );
  }

  SourceRegistryEntry entry(SourceId sourceId) {
    final value = _entries[sourceId];
    if (value == null) throw SourceFailure.sourceUnavailable();
    return value;
  }

  BookSource resolve(SourceId sourceId) {
    final value = entry(sourceId);
    if (!value.isAvailable) throw SourceFailure.sourceUnavailable();
    return value.source!;
  }

  SourceAuthenticator resolveAuthenticator(SourceId sourceId) {
    final value = entry(sourceId);
    if (!value.isAvailable) throw SourceFailure.sourceUnavailable();
    if (!value.descriptor.capabilities.contains(
          SourceCapability.authentication,
        ) ||
        value.authenticator == null) {
      throw SourceFailure.unsupportedCapability(
        SourceCapability.authentication,
      );
    }
    return value.authenticator!;
  }

  void _rejectDuplicate(SourceId sourceId) {
    if (_entries.containsKey(sourceId)) {
      throw SourceFailure.invalidRequest();
    }
  }
}
