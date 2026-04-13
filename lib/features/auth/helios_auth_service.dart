import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:helios_auth_contract/helios_auth_contract.dart';

import '../../core/env/helios_env.dart';
import 'data/helios_core_api.dart';
import 'data/secure_session_store.dart';

/// Host-only [HeliosAuth] plus [ChangeNotifier] for [go_router] `refreshListenable`.
class HeliosAuthService extends ChangeNotifier implements HeliosAuth {
  HeliosAuthService({
    required HeliosCoreApi coreApi,
    required SecureSessionStore sessionStore,
    GoogleSignIn? googleSignIn,
  })  : _coreApi = coreApi,
        _sessionStore = sessionStore,
        _googleSignIn = googleSignIn ?? _createGoogleSignIn();

  final HeliosCoreApi _coreApi;
  final SecureSessionStore _sessionStore;
  final GoogleSignIn _googleSignIn;

  late final StreamController<HeliosAuthSnapshot> _authStream =
      StreamController<HeliosAuthSnapshot>.broadcast(
    onListen: () {
      if (!_authStream.isClosed) {
        _authStream.add(_snapshot);
      }
    },
  );

  HeliosAuthSnapshot _snapshot = HeliosAuthSnapshot.loading;
  String? _jwt;

  /// Google documents this scope as `user.phonenumbers.read` (plural). Enables
  /// `phone_number` (and related) claims on the ID token when Google includes
  /// them; Helios Core should read them from the JWT — the app does **not** send
  /// `phone` in the Core request body.
  static const String _googlePhoneScope =
      'https://www.googleapis.com/auth/user.phonenumbers.read';

  static GoogleSignIn _createGoogleSignIn() {
    const scopes = <String>[
      'email',
      'profile',
      _googlePhoneScope,
    ];
    if (kIsWeb) {
      return GoogleSignIn(
        scopes: scopes,
        clientId: HeliosEnv.webGoogleClientIdOrNull,
        serverClientId: HeliosEnv.serverClientIdOrNull,
      );
    }
    // Android/iOS: omit [serverClientId] when unset so native code can read
    // merged `default_web_client_id` from google-services / Gradle resValue.
    final serverId = HeliosEnv.serverClientIdOrNull;
    if (serverId != null) {
      return GoogleSignIn(scopes: scopes, serverClientId: serverId);
    }
    return GoogleSignIn(scopes: scopes);
  }

  /// Non-blocking: if the user denies phone access, sign-in still continues and
  /// the ID token may omit `phone_number`.
  ///
  /// **Web:** `google_sign_in` recommends [GoogleSignIn.requestScopes] for scopes
  /// beyond `email`/`profile`/`openid`.
  ///
  /// **Android / iOS:** [GoogleSignIn.canAccessScopes] is **not implemented** and
  /// throws [UnimplementedError]; phone is already requested via the [GoogleSignIn]
  /// constructor at sign-in.
  Future<void> _ensurePhoneScopeBestEffort() async {
    if (!kIsWeb) {
      return;
    }
    try {
      final account = _googleSignIn.currentUser;
      if (account == null) return;
      final snapshot = await account.authentication;
      final has = await _googleSignIn.canAccessScopes(
        [_googlePhoneScope],
        accessToken: snapshot.accessToken,
      );
      if (has) return;
      await _googleSignIn.requestScopes([_googlePhoneScope]);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Helios: optional phone scope (web): $e');
      }
    }
  }

  /// Restore persisted session (call from [main] before [runApp]).
  Future<void> init() => _restoreSession();

  void _emit(HeliosAuthSnapshot next) {
    _snapshot = next;
    if (!_authStream.isClosed) {
      _authStream.add(next);
    }
    notifyListeners();
  }

  Future<void> _restoreSession() async {
    _emit(const HeliosAuthSnapshot(status: HeliosAuthStatus.initialLoading));
    try {
      final stored = await _sessionStore.readSession();
      if (stored != null) {
        _jwt = stored.token;
        _emit(
          HeliosAuthSnapshot(
            status: HeliosAuthStatus.authenticated,
            user: stored.user,
          ),
        );
      } else {
        _jwt = null;
        _emit(HeliosAuthSnapshot.signedOut);
      }
    } catch (e) {
      _jwt = null;
      _emit(
        HeliosAuthSnapshot(
          status: HeliosAuthStatus.unauthenticated,
          errorMessage: 'Could not restore session: $e',
        ),
      );
    }
  }

  /// Google Sign-In + Helios Core exchange + secure persistence.
  Future<String?> signInWithGoogle() async {
    if (!HeliosEnv.hasApiBase) {
      return 'Set API_BASE via --dart-define=API_BASE=https://your-core-host';
    }
    if (kIsWeb && HeliosEnv.webGoogleClientIdOrNull == null) {
      return 'Web requires GOOGLE_WEB_CLIENT_ID via --dart-define.';
    }
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        return null;
      }
      await _ensurePhoneScopeBestEffort();
      final effective = _googleSignIn.currentUser ?? account;
      final googleAuth = await effective.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
          return 'Google did not return an ID token. On Android you must supply '
              'the OAuth 2.0 Web application client ID as the server client ID: '
              'use --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com '
              'or add the same line to android/local.properties as '
              'GOOGLE_SERVER_CLIENT_ID=... and rebuild. '
              'If you use Firebase, add your debug SHA-1 and re-download google-services.json '
              'so oauth_client is populated.';
        }
        return 'Google did not return an ID token. Check OAuth client configuration.';
      }
      final result = await _coreApi.exchangeGoogleIdToken(idToken);
      if (!result.isSuccess) {
        return result.error ?? 'Exchange failed';
      }
      _jwt = result.token;
      await _sessionStore.writeSession(token: _jwt!, user: result.user!);
      _emit(
        HeliosAuthSnapshot(
          status: HeliosAuthStatus.authenticated,
          user: result.user,
        ),
      );
      return null;
    } catch (e) {
      return 'Sign-in error: $e';
    }
  }

  @override
  HeliosAuthSnapshot get snapshot => _snapshot;

  @override
  Stream<HeliosAuthSnapshot> get authStateStream => _authStream.stream;

  @override
  Future<String?> getHeliosJwt() async => _jwt;

  @override
  Future<HeliosUser?> getCurrentUser() async => _snapshot.user;

  @override
  Future<void> signOut() async {
    _jwt = null;
    await _sessionStore.clear();
    await _googleSignIn.signOut();
    _emit(HeliosAuthSnapshot.signedOut);
  }

  @override
  void dispose() {
    unawaited(_authStream.close());
    super.dispose();
  }
}
