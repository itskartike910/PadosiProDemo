/// Backend API base URL — override via --dart-define=API_BASE_URL=...
abstract final class AppConfig {
  static const String backendBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );
}
