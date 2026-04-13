/// Placeholder base URL for a future movies microservice.
class MoviesApiConfig {
  MoviesApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'MOVIES_API_BASE',
    defaultValue: 'https://movies.example.invalid',
  );
}
