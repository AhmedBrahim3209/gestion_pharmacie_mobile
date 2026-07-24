import 'dart:io';
import 'package:flutter/material.dart';
import '../models/pharmacie.dart';
import '../models/platform_settings.dart';
import '../services/api_service.dart';

class PharmacieProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  List<Pharmacie> _pharmacies = [];
  Pharmacie? _myPharmacie;
  PlatformSettings? _platformSettings;
  bool _isLoading = false;
  String? _error;

  List<Pharmacie> get pharmacies => _pharmacies;
  Pharmacie? get myPharmacie => _myPharmacie;
  PlatformSettings? get platformSettings => _platformSettings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPharmacies() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _api.getPharmacies();
      _pharmacies = data.map((e) => Pharmacie.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createPharmacie(Map<String, dynamic> data) async {
    try {
      await _api.createPharmacie(data);
      await loadPharmacies();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> toggleActif(int id) async {
    try {
      await _api.togglePharmacieActif(id);
      await loadPharmacies();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<void> loadMySettings() async {
    try {
      final data = await _api.getPharmacySettings();
      _myPharmacie = Pharmacie.fromJson(data);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<bool> updateMySettings(Map<String, dynamic> data) async {
    try {
      final result = await _api.updatePharmacySettings(data);
      _myPharmacie = Pharmacie.fromJson(result);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<void> loadPlatformSettings() async {
    try {
      final data = await _api.getPlatformSettings();
      _platformSettings = PlatformSettings.fromJson(data);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<bool> updatePlatformSettings(Map<String, dynamic> data, {bool refresh = true}) async {
    try {
      final result = await _api.updatePlatformSettings(data);
      if (refresh) {
        _platformSettings = PlatformSettings.fromJson(result);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<Map<String, dynamic>?> getAbonnementConfig() async {
    try {
      return await _api.getAbonnementConfig();
    } catch (_) {
      return null;
    }
  }

  Future<bool> uploadLogo(File file) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.patchUpload('/pharmacies/mes-parametres/', file, fieldName: 'logo');
      await loadMySettings();
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
}
