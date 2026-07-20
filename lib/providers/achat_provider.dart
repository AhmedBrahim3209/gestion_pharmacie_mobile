import 'package:flutter/material.dart';
import '../models/achat.dart';
import '../models/fournisseur.dart';
import '../services/api_service.dart';

class AchatProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  List<Achat> _achats = [];
  List<Fournisseur> _fournisseurs = [];
  bool _isLoading = false;
  String? _error;

  List<Achat> get achats => _achats;
  List<Fournisseur> get fournisseurs => _fournisseurs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAchats() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _api.getAchats();
      _achats = data.map((e) => Achat.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadFournisseurs() async {
    try {
      final data = await _api.getFournisseurs();
      _fournisseurs = data.map((e) => Fournisseur.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<bool> createAchat(Map<String, dynamic> data) async {
    try {
      await _api.createAchat(data);
      await loadAchats();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> createFournisseur(Map<String, dynamic> data) async {
    try {
      await _api.createFournisseur(data);
      await loadFournisseurs();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> updateFournisseur(int id, Map<String, dynamic> data) async {
    try {
      await _api.patch('/achats/fournisseurs/$id/', data: data);
      await loadFournisseurs();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }
}
