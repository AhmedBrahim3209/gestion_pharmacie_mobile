import 'package:flutter/material.dart';
import '../models/client.dart';
import '../models/vente.dart';
import '../services/api_service.dart';

class ClientProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  List<Client> _clients = [];
  List<Vente> _clientPurchases = [];
  bool _isLoading = false;
  bool _isLoadingPurchases = false;
  String? _error;

  List<Client> get clients => _clients;
  List<Vente> get clientPurchases => _clientPurchases;
  bool get isLoading => _isLoading;
  bool get isLoadingPurchases => _isLoadingPurchases;
  String? get error => _error;

  Future<void> loadClients() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _api.getClients();
      _clients = data.map((e) => Client.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadClientPurchases(int clientId) async {
    _isLoadingPurchases = true;
    notifyListeners();
    try {
      final data = await _api.getClientPurchases(clientId);
      _clientPurchases = data.map((e) => Vente.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
    }
    _isLoadingPurchases = false;
    notifyListeners();
  }

  Future<bool> createClient(Map<String, dynamic> data) async {
    try {
      await _api.createClient(data);
      await loadClients();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> updateClient(int id, Map<String, dynamic> data) async {
    try {
      await _api.updateClient(id, data);
      await loadClients();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }
}
