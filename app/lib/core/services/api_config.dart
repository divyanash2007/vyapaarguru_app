/// Central API configuration.
///
/// Toggle [isProduction] to switch between local dev and deployed backend.
///   • Production: points to your Railway / hosted backend URL
///   • Development: points to your local machine
class ApiConfig {
  ApiConfig._();

  // ── Set to true before building the release AAB ──────────────
  static const bool isProduction = true;

  // ── Production URL — Railway backend ────────
  static const String _productionUrl = 'https://posbackend-production-ba70.up.railway.app/api/v1';

  // ── Dev URLs — pick the one that matches your setup ──────────
  static const String _devUrl = 'http://10.53.10.239:8000/api/v1'; // Local dev

  static const String baseUrl = isProduction ? _productionUrl : _devUrl;
}
