import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'dev_network_call.dart';
import 'dev_network_log_store.dart';

/// Debug-only HTTP “interceptor” for `package:http`.
///
/// **There is no global interceptor API** in `package:http` (unlike Dio). The
/// supported pattern is **composition**: subclass [http.BaseClient], delegate
/// [send] to an inner [http.Client], then wrap that client at the **call site**
/// (`HeliosCoreApi`, `TodoApiClient` in [main.dart]). Existing code keeps using
/// `http.Client` methods; this class is a drop-in replacement.
///
/// Request/response bodies and headers are stored **without truncation** (aside
/// from redacting `Authorization` values). Very large payloads can use more
/// memory in debug builds.
class DevHttpLoggingClient extends http.BaseClient {
  DevHttpLoggingClient({
    required http.Client inner,
    required DevNetworkLogStore store,
    this.logToConsole = true,
  })  : _inner = inner,
        _store = store;

  final http.Client _inner;
  final DevNetworkLogStore _store;
  final bool logToConsole;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final id = _store.allocateId();
    final startedAt = DateTime.now();
    final method = request.method;
    final url = request.url.toString();

    final reqHeaders = _redactHeaders(
      Map<String, String>.from(request.headers),
    );

    String? reqBody;
    if (request is http.Request && request.body.isNotEmpty) {
      reqBody = request.body;
    }

    final sw = Stopwatch()..start();
    try {
      final streamed = await _inner.send(request);
      final bytes = await streamed.stream.toBytes();
      sw.stop();

      final bodyStr = utf8.decode(bytes, allowMalformed: true);
      final resHeaders = Map<String, String>.from(streamed.headers);

      final call = DevNetworkCall(
        id: id,
        startedAt: startedAt,
        method: method,
        url: url,
        requestHeaders: reqHeaders,
        requestBody: reqBody,
        statusCode: streamed.statusCode,
        responseHeaders: resHeaders,
        responseBody: bodyStr,
        durationMs: sw.elapsedMilliseconds,
      );
      _store.add(call);
      _emitConsoleIfEnabled(call);

      return http.StreamedResponse(
        Stream.value(bytes),
        streamed.statusCode,
        contentLength: bytes.length,
        request: streamed.request,
        headers: streamed.headers,
        isRedirect: streamed.isRedirect,
        persistentConnection: streamed.persistentConnection,
        reasonPhrase: streamed.reasonPhrase,
      );
    } catch (e, st) {
      sw.stop();
      final err = '$e\n$st';
      final call = DevNetworkCall(
        id: id,
        startedAt: startedAt,
        method: method,
        url: url,
        requestHeaders: reqHeaders,
        requestBody: reqBody,
        durationMs: sw.elapsedMilliseconds,
        errorMessage: err,
      );
      _store.add(call);
      _emitConsoleIfEnabled(call, thrown: e);
      rethrow;
    }
  }

  void _emitConsoleIfEnabled(
    DevNetworkCall call, {
    Object? thrown,
  }) {
    if (!logToConsole || !kDebugMode) return;

    final buf = StringBuffer()
      ..writeln(
        '[Helios HTTP #${call.id}] ${call.method} ${call.url}',
      )
      ..writeln(
        '  → ${call.statusCode ?? '—'} in ${call.durationMs ?? '?'} ms${thrown != null ? ' (threw: $thrown)' : ''}',
      );

    if (call.requestHeaders.isNotEmpty) {
      buf.writeln('  request headers:');
      for (final e in call.requestHeaders.entries) {
        buf.writeln('    ${e.key}: ${e.value}');
      }
    }
    if (call.requestBody != null && call.requestBody!.isNotEmpty) {
      buf.writeln('  request body:\n${call.requestBody}');
    }
    if (call.responseHeaders.isNotEmpty) {
      buf.writeln('  response headers:');
      for (final e in call.responseHeaders.entries) {
        buf.writeln('    ${e.key}: ${e.value}');
      }
    }
    if (call.responseBody != null && call.responseBody!.isNotEmpty) {
      buf.writeln('  response body:\n${call.responseBody}');
    }
    if (call.errorMessage != null) {
      buf.writeln('  error:\n${call.errorMessage}');
    }

    debugPrint(buf.toString());
  }

  static Map<String, String> _redactHeaders(Map<String, String> headers) {
    final out = <String, String>{};
    for (final e in headers.entries) {
      if (e.key.toLowerCase() == 'authorization') {
        final v = e.value;
        if (v.length > 12 && v.toLowerCase().startsWith('bearer ')) {
          out[e.key] = 'Bearer <redacted len=${v.length}>';
        } else {
          out[e.key] = '<redacted>';
        }
      } else {
        out[e.key] = e.value;
      }
    }
    return out;
  }

  @override
  void close() {
    _inner.close();
  }
}
