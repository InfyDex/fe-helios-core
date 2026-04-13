import 'package:flutter/foundation.dart';

/// Compile-time configuration via `--dart-define`.
///
/// Example:
/// `flutter run --dart-define=API_BASE=https://api.dev.example --dart-define=GOOGLE_WEB_CLIENT_ID=xxx.apps.googleusercontent.com`
class HeliosEnv {
  HeliosEnv._();

  /// Helios Core base URL **without** trailing slash (e.g. `https://api.dev.example`).
  static const String apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: '',
  );

  /// Web OAuth client ID (required for Flutter web Google Sign-In).
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

  /// Optional web client ID used as `serverClientId` on Android/iOS so the
  /// Google ID token audience matches a backend web client. If empty, each
  /// platform uses its native client only (backend must allow those `aud`).
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );

  static bool get hasApiBase => apiBase.trim().isNotEmpty;

  static String? get webGoogleClientIdOrNull {
    final v = googleWebClientId.trim();
    if (v.isEmpty) return null;
    return v;
  }

  static String? get serverClientIdOrNull {
    final v = googleServerClientId.trim();
    if (v.isEmpty) return null;
    return v;
  }

  /// Joins a base URL (trailing slashes stripped) with [path] (leading `/` optional).
  static String joinApiBaseAndPath(String base, String path) {
    final b = base.trim().replaceAll(RegExp(r'/+$'), '');
    final p = path.startsWith('/') ? path : '/$path';
    return '$b$p';
  }

  static String apiUrl(String path) => joinApiBaseAndPath(apiBase, path);

  static void assertWebClientConfigured() {
    if (kIsWeb && !hasApiBase) {
      debugPrint(
        'Helios: API_BASE is empty. Set --dart-define=API_BASE=...',
      );
    }
    if (kIsWeb && googleWebClientId.trim().isEmpty) {
      debugPrint(
        'Helios: GOOGLE_WEB_CLIENT_ID is empty. Web Google Sign-In will fail.',
      );
    }
  }
}
