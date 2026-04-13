/// Helios **Todo** microservice base URL (no trailing slash), e.g.
/// `http://localhost:8081` — **not** Helios Core.
class TodoConfig {
  TodoConfig._();

  static const String serviceBase = String.fromEnvironment(
    'TODO_SERVICE_BASE',
    defaultValue: '',
  );

  static const String apiPrefix = '/todo/v1';

  static bool get hasServiceBase => serviceBase.trim().isNotEmpty;

  /// Join [path] (leading `/` optional) to [serviceBase].
  static String joinUrl(String base, String path) {
    final b = base.trim().replaceAll(RegExp(r'/+$'), '');
    final p = path.startsWith('/') ? path : '/$path';
    return '$b$p';
  }

  static String todoServiceUrl(String pathAfterPrefix) {
    final p = pathAfterPrefix.startsWith('/')
        ? pathAfterPrefix
        : '/$pathAfterPrefix';
    return joinUrl(serviceBase, '$apiPrefix$p');
  }
}
