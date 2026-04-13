/// Todo microservice HTTP or auth failure.
class TodoApiException implements Exception {
  TodoApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => 'TodoApiException($statusCode): $message';
}

/// No Helios JWT available for the Todo API.
class TodoNoTokenException implements Exception {
  @override
  String toString() => 'TodoNoTokenException: not signed in';
}
