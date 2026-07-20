import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RapportProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _ventesData;
  List<dynamic> _evenements = [];
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get ventesData => _ventesData;
  List<dynamic> get evenements => _evenements;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadVentesRapport({String? dateDebut, String? dateFin}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _ventesData = await _api.getRapportVentes(dateDebut: dateDebut, dateFin: dateFin);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadEvenements() async {
    try {
      _evenements = await _api.getEvenementsSuperAdmin();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }
}
