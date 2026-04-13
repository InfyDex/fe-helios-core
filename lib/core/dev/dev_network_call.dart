/// One logged HTTP round-trip for the dev network inspector.
class DevNetworkCall {
  DevNetworkCall({
    required this.id,
    required this.startedAt,
    required this.method,
    required this.url,
    required this.requestHeaders,
    this.requestBody,
    this.statusCode,
    this.responseHeaders = const {},
    this.responseBody,
    this.durationMs,
    this.errorMessage,
  });

  final int id;
  final DateTime startedAt;
  final String method;
  final String url;
  final Map<String, String> requestHeaders;
  final String? requestBody;
  final int? statusCode;
  final Map<String, String> responseHeaders;
  final String? responseBody;
  final int? durationMs;
  final String? errorMessage;

  bool get isError => errorMessage != null;
}
