import 'package:flutter/material.dart';
import '../models/dashboard_data.dart';
import '../services/api_service.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  DashboardData? _data;
  bool _isLoading = false;
  String? _error;

  DashboardData? get data => _data;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDashboard() async {
    _isLoading = true;
    notifyListeners();
    try {
      final json = await _api.getDashboard();
      _data = DashboardData.fromJson(json);
      if (_data!.caParJour.isEmpty) {
        _chargerStatsHebdo();
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<List<dynamic>> loadEvenements() async {
    try {
      return await _api.getEvenementsSuperAdmin();
    } catch (_) {
      return [];
    }
  }

  Future<void> _chargerStatsHebdo() async {
    try {
      final stats = await _api.getVentesStatsDetailed(periode: 'semaine');
      final caJour = stats['ca_par_jour'] as List?;
      if (caJour != null && caJour.isNotEmpty && _data != null) {
        final current = _data!;
        _data = DashboardData(
          stockFaible: current.stockFaible,
          enRupture: current.enRupture,
          expiresBientot: current.expiresBientot,
          ventesAujourdhui: current.ventesAujourdhui,
          caAujourdhui: current.caAujourdhui,
          caMois: current.caMois,
          totalVentesMois: current.totalVentesMois,
          medicamentsExpires: current.medicamentsExpires,
          caParJour: caJour.map((e) => (e as num).toDouble()).toList(),
        );
        notifyListeners();
      }
    } catch (_) {}
  }
}
