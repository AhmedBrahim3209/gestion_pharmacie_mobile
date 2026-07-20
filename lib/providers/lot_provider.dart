import 'package:flutter/material.dart';
import '../models/lot.dart';
import '../services/api_service.dart';

class LotProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  List<Lot> _lots = [];
  List<Lot> _lotsExpirant = [];
  List<MouvementLot> _mouvements = [];
  Lot? _lotSelectionne;
  bool _isLoading = false;
  String? _error;

  List<Lot> get lots => _lots;
  List<Lot> get lotsExpirant => _lotsExpirant;
  List<MouvementLot> get mouvements => _mouvements;
  Lot? get lotSelectionne => _lotSelectionne;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Lot> get lotsActifs => _lots.where((l) => l.estActif && l.quantite > 0).toList();
  List<Lot> get lotsExpires => _lots.where((l) => l.estExpire).toList();
  List<Lot> get lotsBientotExpires => _lots.where((l) => !l.estExpire && l.expireBientot).toList();

  Future<void> loadLots({int? medicamentId, bool seulementActifs = true}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.getLots(medicamentId: medicamentId, seulementActifs: seulementActifs);
      _lots = data.map((e) => Lot.fromJson(e)).toList();
      _lots.sort((a, b) => a.dateExpiration.compareTo(b.dateExpiration));
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadLotDetail(int id) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _api.getLotDetail(id);
      _lotSelectionne = Lot.fromJson(data);
      final mouvementsData = await _api.getMouvementsLot(id);
      _mouvements = mouvementsData.map((e) => MouvementLot.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadLotsExpirant({int jours = 90}) async {
    try {
      final data = await _api.getLotsExpirant(jours: jours);
      _lotsExpirant = data.map((e) => Lot.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<bool> createLot(Map<String, dynamic> data) async {
    try {
      await _api.createLot(data);
      await loadLots();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> updateLot(int id, Map<String, dynamic> data) async {
    try {
      await _api.updateLot(id, data);
      await loadLots();
      if (_lotSelectionne?.id == id) await loadLotDetail(id);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> deleteLot(int id) async {
    try {
      await _api.deleteLot(id);
      await loadLots();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> ajustementLot(int lotId, {
    required String typeMouvement,
    required double quantite,
    String? motif,
  }) async {
    try {
      await _api.ajustementLot(lotId, {
        'type_mouvement': typeMouvement,
        'quantite': quantite,
        'motif': motif,
      });
      await loadLots();
      if (_lotSelectionne?.id == lotId) await loadLotDetail(lotId);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  List<Lot> getLotsPourMedicament(int medicamentId) {
    return _lots.where((l) => l.medicamentId == medicamentId && l.estActif && l.quantite > 0)
        .toList()..sort((a, b) => a.dateExpiration.compareTo(b.dateExpiration));
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearSelection() {
    _lotSelectionne = null;
    _mouvements = [];
    notifyListeners();
  }
}