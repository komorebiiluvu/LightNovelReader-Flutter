import '../../source/session/source_session_manager.dart';
import '../../source/source_registry.dart';
import '../../sources/wenku8/wenku8_authenticator.dart';
import '../../sources/wenku8/wenku8_source.dart';
import 'dio_source_transport.dart';

/// Explicit application composition. The transport and provider adapter share
/// exactly one source-scoped session authority; neither creates a cookie jar.
final class Wenku8RuntimeComposition {
  Wenku8RuntimeComposition._({
    required this.registry,
    required this.sessions,
    required this.transport,
    required this.source,
    required this.authenticator,
  });

  factory Wenku8RuntimeComposition.create() {
    final sessions = SourceSessionManager();
    final transport = DioSourceTransport(sessionAuthority: sessions);
    final source = Wenku8Source(transport: transport, sessions: sessions);
    final authenticator = Wenku8Authenticator(
      transport: transport,
      sessions: sessions,
    );
    final registry = SourceRegistry()
      ..register(source, authenticator: authenticator);
    return Wenku8RuntimeComposition._(
      registry: registry,
      sessions: sessions,
      transport: transport,
      source: source,
      authenticator: authenticator,
    );
  }

  final SourceRegistry registry;
  final SourceSessionManager sessions;
  final DioSourceTransport transport;
  final Wenku8Source source;
  final Wenku8Authenticator authenticator;
}
