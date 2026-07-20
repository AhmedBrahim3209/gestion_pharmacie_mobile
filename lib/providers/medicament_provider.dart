import 'package:flutter/material.dart';
import '../models/medicament.dart';
import '../models/categorie.dart';
import '../services/api_service.dart';

class MedicamentProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  List<Medicament> _medicaments = [];
  List<Categorie> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<Medicament> get medicaments => _medicaments;
  List<Categorie> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadMedicaments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.getMedicaments();
      _medicaments = data.map((e) => Medicament.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadCategories() async {
    _error = null;
    try {
      final data = await _api.getCategories();
      _categories = data.map((e) => Categorie.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<bool> createMedicament(Map<String, dynamic> data) async {
    _error = null;
    try {
      await _api.createMedicament(data);
      await loadMedicaments();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> updateMedicament(int id, Map<String, dynamic> data) async {
    _error = null;
    try {
      await _api.updateMedicament(id, data);
      await loadMedicaments();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> deleteMedicament(int id) async {
    _error = null;
    try {
      await _api.deleteMedicament(id);
      await loadMedicaments();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> createCategory(Map<String, dynamic> data) async {
    _error = null;
    try {
      await _api.createCategory(data);
      await loadCategories();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }
}
