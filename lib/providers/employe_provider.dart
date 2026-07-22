import 'package:flutter/material.dart';
import '../models/employe.dart';
import '../services/api_service.dart';

class EmployeProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  List<Employe> _employes = [];
  bool _isLoading = false;
  String? _error;

  List<Employe> get employes => _employes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadEmployes() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _api.getEmployes();
      _employes = data.map((e) => Employe.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createEmploye(Map<String, dynamic> data) async {
    try {
      final result = await _api.createEmploye(data);
      _employes.add(Employe.fromJson(result));
      notifyListeners();
      loadEmployes();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> deleteEmploye(int id) async {
    try {
      await _api.deleteEmploye(id);
      await loadEmployes();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }
}
