import 'dart:convert';

import 'package:http/http.dart' as http;

import 'todo_config.dart';
import 'todo_exceptions.dart';

/// HTTP client for Helios Todo service; injects `Authorization: Bearer` from [getToken].
class TodoApiClient {
  TodoApiClient({
    required this.getToken,
    http.Client? httpClient,
    Future<void> Function()? onUnauthorized,
    String? baseUrlOverride,
  })  : _client = httpClient ?? http.Client(),
        _onUnauthorized = onUnauthorized,
        _baseOverride = _trim(baseUrlOverride);

  final Future<String?> Function() getToken;
  final http.Client _client;
  final Future<void> Function()? _onUnauthorized;
  final String? _baseOverride;

  static String? _trim(String? s) {
    if (s == null) return null;
    final t = s.trim();
    return t.isEmpty ? null : t;
  }

  String _url(String pathAfterPrefix) {
    final override = _baseOverride;
    if (override != null) {
      return TodoConfig.joinUrl(override, '${TodoConfig.apiPrefix}$pathAfterPrefix');
    }
    return TodoConfig.todoServiceUrl(pathAfterPrefix);
  }

  bool get _configured =>
      _baseOverride != null || TodoConfig.hasServiceBase;

  Future<http.Response> _authorized(
    Future<http.Response> Function(Uri uri, Map<String, String> headers) send,
    Uri uri,
  ) async {
    if (!_configured) {
      throw TodoApiException(
        'TODO_SERVICE_BASE is not set. Use --dart-define=TODO_SERVICE_BASE=...',
      );
    }
    final token = await getToken();
    if (token == null || token.isEmpty) {
      throw TodoNoTokenException();
    }
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    final res = await send(uri, headers);
    if (res.statusCode == 401) {
      await _onUnauthorized?.call();
      throw TodoApiException('Unauthorized', statusCode: 401);
    }
    return res;
  }

  Future<http.Response> get(String pathAfterPrefix) async {
    final uri = Uri.parse(_url(pathAfterPrefix));
    return _authorized(
      (u, h) => _client.get(u, headers: h),
      uri,
    );
  }

  Future<http.Response> post(String pathAfterPrefix, Object? body) async {
    final uri = Uri.parse(_url(pathAfterPrefix));
    return _authorized(
      (u, h) => _client.post(
        u,
        headers: h,
        body: body == null ? null : jsonEncode(body),
      ),
      uri,
    );
  }

  Future<http.Response> patch(String pathAfterPrefix, Object? body) async {
    final uri = Uri.parse(_url(pathAfterPrefix));
    return _authorized(
      (u, h) => _client.patch(
        u,
        headers: h,
        body: body == null ? null : jsonEncode(body),
      ),
      uri,
    );
  }

  Future<http.Response> delete(String pathAfterPrefix) async {
    final uri = Uri.parse(_url(pathAfterPrefix));
    return _authorized(
      (u, h) => _client.delete(u, headers: h),
      uri,
    );
  }

  void dispose() {
    _client.close();
  }
}
