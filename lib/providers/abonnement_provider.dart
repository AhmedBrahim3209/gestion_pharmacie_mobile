import 'package:flutter/material.dart';
import '../models/abonnement.dart';
import '../services/api_service.dart';

class AbonnementProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  List<Abonnement> _abonnements = [];
  bool _isLoading = false;
  String? _error;

  List<Abonnement> get abonnements => _abonnements;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAbonnements() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _api.getAbonnements();
      _abonnements = data.map((e) => Abonnement.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createAbonnement(Map<String, dynamic> data) async {
    try {
      await _api.createAbonnement(data);
      await loadAbonnements();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> suspendreAbonnement(int id) async {
    try {
      await _api.suspendreAbonnement(id);
      await loadAbonnements();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> activerAbonnement(int id) async {
    try {
      await _api.activerAbonnement(id);
      await loadAbonnements();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> renouvelerAbonnement(int id, Map<String, dynamic> data) async {
    try {
      await _api.renouvelerAbonnement(id, data);
      await loadAbonnements();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<Map<String, dynamic>?> getStats() async {
    try {
      return await _api.getAbonnementStats();
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getPrix() async {
    try {
      return await _api.getAbonnementPrix();
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getMonAbonnement() async {
    try {
      return await _api.getMonAbonnement();
    } catch (_) {
      return null;
    }
  }

  Future<bool> payerMonAbonnement(Map<String, dynamic> data) async {
    try {
      await _api.payerMonAbonnement(data);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<List<dynamic>?> getCaptures() async {
    try {
      return await _api.getAbonnementCaptures();
    } catch (_) {
      return null;
    }
  }
}
