import 'dart:convert';

import 'package:helios_auth_contract/helios_auth_contract.dart';
import 'package:http/http.dart' as http;

import '../../../core/env/helios_env.dart';

/// Helios Core HTTP client (identity only).
class HeliosCoreApi {
  HeliosCoreApi({
    http.Client? httpClient,
    /// When set (non-empty after trim), used instead of [HeliosEnv.apiBase] for
    /// requests and [HeliosEnv.hasApiBase] checks (e.g. unit tests).
    String? apiBaseOverride,
  })  : _client = httpClient ?? http.Client(),
        _apiBaseOverride = _trimmedOrNull(apiBaseOverride);

  final http.Client _client;
  final String? _apiBaseOverride;

  static String? _trimmedOrNull(String? value) {
    if (value == null) return null;
    final t = value.trim();
    return t.isEmpty ? null : t;
  }

  bool get _hasApiBase =>
      _apiBaseOverride != null || HeliosEnv.hasApiBase;

  Uri _uri(String path) => Uri.parse(_apiUrl(path));

  String _apiUrl(String path) {
    if (_apiBaseOverride != null) {
      return HeliosEnv.joinApiBaseAndPath(_apiBaseOverride, path);
    }
    return HeliosEnv.apiUrl(path);
  }

  /// `POST /core/v1/auth/google` with Google ID token.
  Future<HeliosAuthExchangeResult> exchangeGoogleIdToken(String idToken) async {
    if (!_hasApiBase) {
      return HeliosAuthExchangeResult.failure(
        'API_BASE is not set. Run with --dart-define=API_BASE=https://your-host',
      );
    }
    final uri = _uri('/core/v1/auth/google');
    try {
      final res = await _client.post(
        uri,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'idToken': idToken}),
      );
      if (res.statusCode < 200 || res.statusCode >= 300) {
        return HeliosAuthExchangeResult.failure(
          'Helios Core returned ${res.statusCode}: ${res.body}',
        );
      }
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      final userJson = map['user'] as Map<String, dynamic>?;
      final token = map['token'] as String?;
      if (userJson == null || token == null || token.isEmpty) {
        return HeliosAuthExchangeResult.failure('Invalid response from Helios Core');
      }
      final user = HeliosUser.fromJson(userJson);
      return HeliosAuthExchangeResult.ok(user: user, token: token);
    } catch (e) {
      return HeliosAuthExchangeResult.failure('Network error: $e');
    }
  }

  /// Optional connectivity probe: `GET /core/v1/health`.
  Future<bool> healthOk() async {
    if (!_hasApiBase) return false;
    final uri = _uri('/core/v1/health');
    try {
      final res = await _client.get(uri);
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _client.close();
  }
}

class HeliosAuthExchangeResult {
  HeliosAuthExchangeResult._({this.user, this.token, this.error});

  final HeliosUser? user;
  final String? token;
  final String? error;

  bool get isSuccess =>
      user != null && (token?.isNotEmpty ?? false) && error == null;

  factory HeliosAuthExchangeResult.ok({
    required HeliosUser user,
    required String token,
  }) =>
      HeliosAuthExchangeResult._(user: user, token: token);

  factory HeliosAuthExchangeResult.failure(String message) =>
      HeliosAuthExchangeResult._(error: message);
}
