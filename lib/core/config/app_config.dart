abstract final class AppConfig {
  // Trailing slash is required: Dio uses URI resolution, so "baseUrl/api/v1" +
  // "/path" strips the base path. With trailing slash + no leading slash in
  // paths, resolution works correctly.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1/',
  );

  static const String wsUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'ws://localhost:8000/api/v1/',
  );

  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static bool get isDebug => environment == 'development';
}
