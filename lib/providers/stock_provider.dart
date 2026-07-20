import 'package:flutter/material.dart';
import '../models/stock.dart';
import '../services/api_service.dart';

class StockProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  List<Stock> _stockItems = [];
  List<Stock> _lowStock = [];
  List<Stock> _outOfStock = [];
  List<MouvementStock> _mouvements = [];
  bool _isLoading = false;
  String? _error;

  List<Stock> get stockItems => _stockItems;
  List<Stock> get lowStock => _lowStock;
  List<Stock> get outOfStock => _outOfStock;
  List<MouvementStock> get mouvements => _mouvements;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadStock() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _api.getStock();
      _stockItems = data.map((e) => Stock.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadLowStock() async {
    try {
      final data = await _api.getLowStock();
      _lowStock = data.map((e) => Stock.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> loadOutOfStock() async {
    try {
      final data = await _api.getOutOfStock();
      _outOfStock = data.map((e) => Stock.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> loadMouvements() async {
    try {
      final data = await _api.getMouvements();
      _mouvements = data.map((e) => MouvementStock.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<bool> adjustStock(int id, Map<String, dynamic> data) async {
    try {
      await _api.adjustStock(id, data);
      await loadStock();
      await loadMouvements();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }
}
