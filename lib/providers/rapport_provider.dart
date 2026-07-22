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
      final stats = await _api.getRapportVentes(dateDebut: dateDebut, dateFin: dateFin);
      List<dynamic> ventesList = [];
      try {
        ventesList = await _api.getVentes();
      } catch (_) {}
      final caTotal = (stats['ca_mois'] as num?)?.toDouble() ?? 0;
      _ventesData = {
        'total_ventes': stats['nb_ventes_mois'] ?? ventesList.length,
        'ca_total': caTotal,
        'nb_transactions': stats['nb_ventes_aujourd_hui'] ?? 0,
        'panier_moyen': stats['nb_ventes_mois'] != null && (stats['nb_ventes_mois'] as num) > 0
            ? caTotal / (stats['nb_ventes_mois'] as num)
            : 0,
        'meilleures_ventes': ventesList.isNotEmpty ? _computeBestSellers(ventesList) : [],
      };
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  List<Map<String, dynamic>> _computeBestSellers(List<dynamic> ventesList) {
    final Map<int, Map<String, dynamic>> sellerMap = {};
    for (final v in ventesList) {
      final lignes = v['lignes'] as List? ?? [];
      for (final l in lignes) {
        final medId = l['medicament'];
        final medNom = l['medicament_nom'] ?? 'N/A';
        final qte = (l['quantite'] as num?)?.toDouble() ?? 0;
        final total = (l['sous_total'] as num?)?.toDouble() ?? 0;
        if (medId != null) {
          if (!sellerMap.containsKey(medId)) {
            sellerMap[medId] = {'medicament__nom': medNom, 'quantite_totale': 0.0, 'total': 0.0};
          }
          sellerMap[medId]!['quantite_totale'] = (sellerMap[medId]!['quantite_totale'] as double) + qte;
          sellerMap[medId]!['total'] = (sellerMap[medId]!['total'] as double) + total;
        }
      }
    }
    final sorted = sellerMap.values.toList()
      ..sort((a, b) => (b['quantite_totale'] as double).compareTo(a['quantite_totale'] as double));
    return sorted.take(10).toList();
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
