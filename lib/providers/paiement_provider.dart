import 'package:flutter/material.dart';
import '../models/paiement.dart';
import '../services/api_service.dart';

class PaiementProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  List<Paiement> _paiements = [];
  bool _isLoading = false;
  String? _error;

  List<Paiement> get paiements => _paiements;
  bool get isLoading => _isLoading;
  String? get error => _error;

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
}
