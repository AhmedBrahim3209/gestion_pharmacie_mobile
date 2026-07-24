import 'package:flutter/material.dart';
import '../models/dashboard_data.dart';
import '../services/api_service.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  DashboardData? _data;
  bool _isLoading = false;
  String? _error;

  DashboardData? get data => _data;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDashboard() async {
    _isLoading = true;
    notifyListeners();
    try {
      final json = await _api.getDashboard();
      _data = DashboardData.fromJson(json);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<List<dynamic>> loadEvenements() async {
    try {
      return await _api.getEvenementsSuperAdmin();
    } catch (_) {
      return [];
    }
  }
}
