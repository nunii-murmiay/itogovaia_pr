/// Адрес PocketBase задаётся через --dart-define, не константой в коде.
/// Пример: http://127.0.0.1:8090/api
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8090/api',
);
