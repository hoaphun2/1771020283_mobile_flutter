import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile_flutter/services/api_service.dart';
import 'package:mobile_flutter/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  User? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AuthProvider() {
    _apiService.init();
    _loadToken();
  }

  Future<void> _loadToken() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        _token = prefs.getString('token');
        if (_token != null) {
          _apiService.setToken(_token!);
          await getCurrentUser();
        }
      } else {
        _token = await _storage.read(key: 'token');
        if (_token != null) {
          _apiService.setToken(_token!);
          await getCurrentUser();
        }
      }
    } catch (e) {
      _error = 'Lỗi khi tải token: $e';
    }
    notifyListeners();
  }

  Future<void> _saveToken(String token) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      _token = token;
    } else {
      await _storage.write(key: 'token', value: token);
      _token = token;
    }
    _apiService.setToken(token);
  }

  Future<void> _clearToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
    } else {
      await _storage.delete(key: 'token');
    }
    _token = null;
    _currentUser = null;
    _apiService.clearToken();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final request = LoginRequest(email: email, password: password);
      final response = await _apiService.login(request);
      
      await _saveToken(response.token);
      _currentUser = response.user;
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password, String fullName, String? phone) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final request = RegisterRequest(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      final response = await _apiService.register(request);
      
      await _saveToken(response.token);
      _currentUser = response.user;
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> getCurrentUser() async {
    try {
      _currentUser = await _apiService.getCurrentUser();
      
      // Load persisted simulated balance
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final savedBalance = prefs.getDouble('saved_wallet_balance');
        if (savedBalance != null && _currentUser != null) {
          _currentUser = _currentUser!.copyWith(walletBalance: savedBalance);
        }
      } else {
        // For mobile/desktop
        final prefs = await SharedPreferences.getInstance();
        final savedBalance = prefs.getDouble('saved_wallet_balance');
        if (savedBalance != null && _currentUser != null) {
          _currentUser = _currentUser!.copyWith(walletBalance: savedBalance);
        }
      }
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      await logout();
    }
  }

  Future<void> logout() async {
    await _clearToken();
    _currentUser = null;
    _token = null;
    _error = null;
    notifyListeners();
  }

  void updateUser(User user) {
    _currentUser = user;
    notifyListeners();
    
    // Save new balance to persistence
    if (user.walletBalance != null) {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setDouble('saved_wallet_balance', user.walletBalance!);
      });
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}