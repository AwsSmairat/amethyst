/// Base URL for the Amethyst API (includes `/api` prefix).
///
/// Override at build time, e.g. Android emulator:
/// `--dart-define=API_BASE_URL=http://10.0.2.2:4000/api`
abstract final class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:4000/api',
  );
}
