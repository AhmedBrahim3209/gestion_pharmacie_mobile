import 'package:flutter/material.dart';
import '../models/vente.dart';
import '../services/api_service.dart';

class VenteProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  List<Vente> _ventes = [];
  bool _isLoading = false;
  String? _error;

  List<Vente> get ventes => _ventes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadVentes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.getVentes();
      _ventes = data.map((e) => Vente.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<Vente?> createVente(Map<String, dynamic> data) async {
    _error = null;
    try {
      final result = await _api.createVente(data);
      await loadVentes();
      return Vente.fromJson(result);
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  Future<Vente?> getVenteDetail(int id) async {
    try {
      final result = await _api.getVente(id);
      return Vente.fromJson(result);
    } catch (e) {
      return null;
    }
  }
}
