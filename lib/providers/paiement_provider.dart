import 'package:flutter/material.dart';
import '../models/paiement.dart';
import '../services/api_service.dart';

class PaiementProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  List<Paiement> _paiements = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _stats;

  List<Paiement> get paiements => _paiements;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get stats => _stats;

  Future<void> loadPaiements() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _api.getPaiements();
      _paiements = data.map((e) => Paiement.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createPaiement(Map<String, dynamic> data) async {
    try {
      await _api.createPaiement(data);
      await loadPaiements();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> confirmerPaiement(int id) async {
    try {
      await _api.confirmerPaiement(id);
      await loadPaiements();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> annulerPaiement(int id) async {
    try {
      await _api.annulerPaiement(id);
      await loadPaiements();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<void> loadStats() async {
    try {
      _stats = await _api.getPaiementStats();
      notifyListeners();
    } catch (_) {}
  }
}
