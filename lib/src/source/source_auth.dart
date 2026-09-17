import '../domain/identity/opaque_ids.dart';
import 'source_continuation.dart';

enum SourceAuthStatus {
  unauthenticated,
  authenticating,
  authenticated,
  expired,
}

final class SourceAuthState {
  const SourceAuthState(this.status);

  final SourceAuthStatus status;

  bool get isAuthenticated => status == SourceAuthStatus.authenticated;

  @override
  String toString() => 'SourceAuthState($status)';
}

/// Source-specific credential input. Implementations may carry a reviewed
/// credential shape without requiring every Source to use passwords.
abstract interface class SourceCredential {
  const SourceCredential();
}

/// Authentication is deliberately separate from [BookSource].
abstract interface class SourceAuthenticator {
  SourceId get sourceId;

  Future<SourceAuthState> signIn(
    SourceCredential credential,
    SourceOperationContext context,
  );

  Future<SourceAuthState> status(SourceOperationContext context);

  Future<SourceAuthState> signOut(SourceOperationContext context);
}
