import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

/// Lightweight exception carrying the HTTP status code and backend detail.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Thin HTTP wrapper that auto-injects JWT tokens and handles refresh rotation.
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  // ── Token helpers ──────────────────────────────────────────────

  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<String?> _getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refresh_token');
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  // ── Header builder ─────────────────────────────────────────────

  Future<Map<String, String>> _headers({bool withAuth = true}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (withAuth) {
      final token = await _getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // ── Token refresh ──────────────────────────────────────────────

  Future<bool> _tryRefresh() async {
    final refreshToken = await _getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await saveTokens(data['access_token'], data['refresh_token']);
        return true;
      }
    } catch (_) {}
    // Refresh failed — caller should treat as logged-out
    await clearTokens();
    return false;
  }

  // ── Core request method ────────────────────────────────────────

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    bool withAuth = true,
  }) async {
    var uri = Uri.parse('${ApiConfig.baseUrl}$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    Future<http.Response> send(Map<String, String> headers) {
      switch (method) {
        case 'POST':
          return http.post(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
        case 'PUT':
          return http.put(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
        case 'PATCH':
          return http.patch(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
        case 'DELETE':
          return http.delete(uri, headers: headers);
        default:
          return http.get(uri, headers: headers);
      }
    }

    var headers = await _headers(withAuth: withAuth);
    var response = await send(headers);

    // Auto-refresh on 401 and retry once
    if (response.statusCode == 401 && withAuth) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        headers = await _headers(withAuth: true);
        response = await send(headers);
      }
    }

    // Parse response
    if (response.statusCode == 204) return null;

    final decoded = response.body.isNotEmpty ? jsonDecode(response.body) : null;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    // Extract error detail
    String detail = 'Something went wrong';
    if (decoded is Map && decoded.containsKey('detail')) {
      detail = decoded['detail'].toString();
    }
    throw ApiException(response.statusCode, detail);
  }

  // ── Public convenience methods ─────────────────────────────────

  Future<dynamic> get(String path, {Map<String, String>? queryParams, bool withAuth = true}) =>
      _request('GET', path, queryParams: queryParams, withAuth: withAuth);

  Future<dynamic> post(String path, {Map<String, dynamic>? body, bool withAuth = true}) =>
      _request('POST', path, body: body, withAuth: withAuth);

  Future<dynamic> put(String path, {Map<String, dynamic>? body, bool withAuth = true}) =>
      _request('PUT', path, body: body, withAuth: withAuth);

  Future<dynamic> patch(String path, {Map<String, dynamic>? body, bool withAuth = true}) =>
      _request('PATCH', path, body: body, withAuth: withAuth);

  Future<dynamic> delete(String path, {bool withAuth = true}) =>
      _request('DELETE', path, withAuth: withAuth);
}
