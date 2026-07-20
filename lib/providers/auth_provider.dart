import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _api.isAuthenticated;

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _api.login(username, password);
      final userData = await _api.getMe();
      _user = User.fromJson(userData);
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

  Future<void> loadUser() async {
    if (!_api.isAuthenticated) return;
    try {
      final userData = await _api.getMe();
      _user = User.fromJson(userData);
      notifyListeners();
    } catch (_) {
      await _api.clearTokens();
    }
  }

  Future<void> logout() async {
    _api.clearTokensSync();
    _user = null;
    notifyListeners();
    try {
      await _api.logout();
    } catch (_) {}
  }

  Future<bool> changePassword(String oldPw, String newPw) async {
    try {
      await _api.changePassword({'old_password': oldPw, 'new_password': newPw, 'new_password_confirm': newPw});
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final result = await _api.updateMe(data);
      _user = User.fromJson(result);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }
}
