/// Placeholder base URL for a future todo microservice.
/// The host will pass [authorizationBearer] when wiring real HTTP clients.
class TodoApiConfig {
  TodoApiConfig._();

  /// Override via `--dart-define=TODO_API_BASE=...` when the service exists.
  static const String baseUrl = String.fromEnvironment(
    'TODO_API_BASE',
    defaultValue: 'https://todo.example.invalid',
  );
}
