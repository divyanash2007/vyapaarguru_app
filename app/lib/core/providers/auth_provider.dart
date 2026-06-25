import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// Manages authentication state — login, register, logout, session restore.
class AuthProvider extends ChangeNotifier {
  final _api = ApiService.instance;

  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _shopData;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get shopData => _shopData;

  // Convenience getters for common shop fields
  String get shopName => _shopData?['shop_name'] ?? '';
  String get ownerName => _shopData?['owner_name'] ?? '';
  String get phoneNo => _shopData?['phone_no'] ?? '';
  String get address => _shopData?['address'] ?? '';
  String get shopType => _shopData?['type'] ?? '';
  String? get gstNo => _shopData?['gst_no'];
  int get shopId => _shopData?['id'] ?? 0;

  /// Try to restore a previous session using stored tokens.
  /// Call this during splash screen — it runs silently.
  Future<void> tryAutoLogin() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _api.get('/shops/me');
      _shopData = Map<String, dynamic>.from(data);
      _isLoggedIn = true;
    } catch (_) {
      // Token invalid or missing — user needs to log in
      _isLoggedIn = false;
      _shopData = null;
      await _api.clearTokens();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Log in with phone number. Returns true if the shop exists and login succeeds.
  /// Returns false (with errorMessage) if the phone is not registered (401).
  Future<bool> login(String phoneNo) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _api.post(
        '/auth/login',
        body: {'phone_no': phoneNo},
        withAuth: false,
      );
      await _api.saveTokens(data['access_token'], data['refresh_token']);

      // Load shop data
      final shopData = await _api.get('/shops/me');
      _shopData = Map<String, dynamic>.from(shopData);
      _isLoggedIn = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _isLoading = false;
      if (e.statusCode == 401) {
        // Phone not registered — user needs to create a shop
        _errorMessage = null;
        notifyListeners();
        return false;
      }
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Could not connect to server. Check your network.';
      notifyListeners();
      return false;
    }
  }

  /// Register a new shop, then log in automatically.
  Future<bool> register({
    required String shopName,
    required String ownerName,
    required String type,
    required String address,
    required String phoneNo,
    String? gstNo,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Create the shop (no auth required)
      await _api.post(
        '/shops/',
        body: {
          'shop_name': shopName,
          'owner_name': ownerName,
          'type': type,
          'address': address,
          'phone_no': phoneNo,
          if (gstNo != null && gstNo.isNotEmpty) 'gst_no': gstNo,
        },
        withAuth: false,
      );

      // 2. Log in with the newly created phone
      final success = await login(phoneNo);
      return success;
    } on ApiException catch (e) {
      _isLoading = false;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Could not connect to server. Check your network.';
      notifyListeners();
      return false;
    }
  }

  /// Refresh shop data from the server (e.g. after editing profile).
  Future<void> refreshShopData() async {
    try {
      final data = await _api.get('/shops/me');
      _shopData = Map<String, dynamic>.from(data);
      notifyListeners();
    } catch (_) {}
  }

  /// Log out — revoke token on server, clear local state.
  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (_) {
      // Even if the server call fails, clear local state
    }
    await _api.clearTokens();
    _isLoggedIn = false;
    _shopData = null;
    _errorMessage = null;
    notifyListeners();
  }
}
