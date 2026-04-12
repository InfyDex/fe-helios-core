import 'helios_user.dart';

/// High-level auth lifecycle for the Helios host.
enum HeliosAuthStatus {
  /// Session restore in progress (cold start).
  initialLoading,

  /// No valid Helios session.
  unauthenticated,

  /// Helios JWT present and user loaded.
  authenticated,
}

/// Immutable view of auth state for routing and plugins.
class HeliosAuthSnapshot {
  const HeliosAuthSnapshot({
    required this.status,
    this.user,
    this.errorMessage,
  });

  final HeliosAuthStatus status;
  final HeliosUser? user;
  final String? errorMessage;

  bool get isLoggedIn =>
      status == HeliosAuthStatus.authenticated && user != null;

  static const HeliosAuthSnapshot loading = HeliosAuthSnapshot(
    status: HeliosAuthStatus.initialLoading,
  );

  static const HeliosAuthSnapshot signedOut = HeliosAuthSnapshot(
    status: HeliosAuthStatus.unauthenticated,
  );
}

/// Narrow facade implemented only in the host app. Feature packages consume
/// this type and obtain the Helios JWT for their own API clients.
abstract class HeliosAuth {
  /// Latest snapshot (synchronous).
  HeliosAuthSnapshot get snapshot;

  /// Emits on every auth state change (including after restore).
  Stream<HeliosAuthSnapshot> get authStateStream;

  /// Helios Core JWT for `Authorization: Bearer <token>`. Returns `null` if
  /// signed out or token missing.
  Future<String?> getHeliosJwt();

  /// Current user when authenticated; otherwise `null`.
  Future<HeliosUser?> getCurrentUser();

  Future<void> signOut();
}
