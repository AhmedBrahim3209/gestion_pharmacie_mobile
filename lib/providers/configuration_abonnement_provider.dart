import 'package:flutter/material.dart';
import '../models/configuration_abonnement.dart';
import '../services/api_service.dart';

class ConfigurationAbonnementProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  List<ConfigurationAbonnement> _configurations = [];
  bool _isLoading = false;
  String? _error;

  List<ConfigurationAbonnement> get configurations => _configurations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadConfigurations() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _api.getConfigurationsAbonnement();
      _configurations = data.map((e) => ConfigurationAbonnement.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createConfiguration(Map<String, dynamic> data) async {
    try {
      await _api.createConfigurationAbonnement(data);
      await loadConfigurations();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> updateConfiguration(int id, Map<String, dynamic> data) async {
    try {
      await _api.updateConfigurationAbonnement(id, data);
      await loadConfigurations();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> deleteConfiguration(int id) async {
    try {
      await _api.deleteConfigurationAbonnement(id);
      await loadConfigurations();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }
}