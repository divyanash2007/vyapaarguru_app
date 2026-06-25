/// Central API configuration.
///
/// Change [baseUrl] depending on how you're running the app:
///   • Physical device (same WiFi): use your computer's local IP
///   • Android emulator:            use 10.0.2.2
///   • iOS simulator / web:         use localhost
class ApiConfig {
  ApiConfig._();

  // ── Change this to match your setup ──────────────────────────
  static const String baseUrl = 'http://10.53.10.239:8000/api/v1';
  // static const String baseUrl = 'http://10.0.2.2:8000/api/v1';   // Android emulator
  // static const String baseUrl = 'http://localhost:8000/api/v1';   // iOS simulator / web
}
