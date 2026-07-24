import 'package:flutter/material.dart';
import '../models/prescription.dart';
import '../services/api_service.dart';

class PrescriptionProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  List<Prescription> _prescriptions = [];
  bool _isLoading = false;
  String? _error;

  List<Prescription> get prescriptions => _prescriptions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPrescriptions() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _api.getPrescriptions();
      _prescriptions = data.map((e) => Prescription.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createPrescription(Map<String, dynamic> data) async {
    try {
      await _api.createPrescription(data);
      await loadPrescriptions();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> updatePrescription(int id, Map<String, dynamic> data) async {
    try {
      await _api.updatePrescription(id, data);
      await loadPrescriptions();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> deletePrescription(int id) async {
    try {
      await _api.deletePrescription(id);
      await loadPrescriptions();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }
}
