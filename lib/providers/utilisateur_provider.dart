import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class UtilisateurProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  List<User> _utilisateurs = [];
  bool _isLoading = false;
  String? _error;

  List<User> get utilisateurs => _utilisateurs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadUtilisateurs() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _api.getUsers();
      _utilisateurs = data.map((e) => User.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createUtilisateur(Map<String, dynamic> data) async {
    try {
      await _api.createUser(data);
      await loadUtilisateurs();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> updateUtilisateur(int id, Map<String, dynamic> data) async {
    try {
      await _api.updateUser(id, data);
      await loadUtilisateurs();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<void> toggleActif(int id) async {
    try {
      await _api.toggleUserActif(id);
      await loadUtilisateurs();
    } catch (_) {}
  }

  Future<void> deleteUtilisateur(int id) async {
    try {
      await _api.deleteUser(id);
      await loadUtilisateurs();
    } catch (_) {}
  }
}
