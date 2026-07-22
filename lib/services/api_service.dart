import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ConnectivityException implements Exception {
  final String message;
  ConnectivityException([this.message = 'Aucune connexion internet']);
  @override
  String toString() => message;
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _accessToken;
  String? _refreshToken;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

  Future<void> _saveTokens(String access, String refresh) async {
    _accessToken = access;
    _refreshToken = refresh;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', access);
    await prefs.setString('refresh_token', refresh);
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  void clearTokensSync() {
    _accessToken = null;
    _refreshToken = null;
  }

  bool get isAuthenticated => _accessToken != null;

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _saveTokens(data['access'], data['refresh']);
      return data;
    }
    throw HttpException('Erreur de connexion: ${response.statusCode}');
  }

  Future<void> logout() async {
    try {
      if (_refreshToken != null) {
        await http.post(
          Uri.parse('${ApiConfig.baseUrl}/auth/logout/'),
          headers: _headers,
          body: jsonEncode({'refresh': _refreshToken}),
        );
      }
    } catch (_) {}
    try {
      await clearTokens();
    } catch (_) {
      _accessToken = null;
      _refreshToken = null;
    }
  }

  Future<Map<String, dynamic>> refreshToken() async {
    if (_refreshToken == null) throw HttpException('No refresh token');
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/refresh/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': _refreshToken}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _accessToken = data['access'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', data['access']);
      return data;
    }
    await clearTokens();
    throw HttpException('Session expirée');
  }

  Future<dynamic> _request(Future<http.Response> Function() request, {bool list = false}) async {
    var response = await request();
    if (response.statusCode == 401 && _refreshToken != null) {
      await refreshToken();
      response = await request();
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      final data = jsonDecode(response.body);
      if (list && data is Map && data.containsKey('results')) {
        return data['results'];
      }
      return data;
    }
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
    throw HttpException(body is Map ? (body['detail'] ?? body.toString()) : body.toString());
  }

  Future<dynamic> _get(String path) => _request(() => http.get(
    Uri.parse('${ApiConfig.baseUrl}$path'),
    headers: _headers,
  ), list: true);

  Future<dynamic> get(String path) => _request(() => http.get(
    Uri.parse('${ApiConfig.baseUrl}$path'),
    headers: _headers,
  ));

  Future<dynamic> post(String path, {Map<String, dynamic>? data}) => _request(() => http.post(
    Uri.parse('${ApiConfig.baseUrl}$path'),
    headers: _headers,
    body: data != null ? jsonEncode(data) : null,
  ));

  Future<dynamic> patch(String path, {Map<String, dynamic>? data}) => _request(() => http.patch(
    Uri.parse('${ApiConfig.baseUrl}$path'),
    headers: _headers,
    body: data != null ? jsonEncode(data) : null,
  ));

  Future<dynamic> put(String path, {Map<String, dynamic>? data}) => _request(() => http.put(
    Uri.parse('${ApiConfig.baseUrl}$path'),
    headers: _headers,
    body: data != null ? jsonEncode(data) : null,
  ));

  Future<dynamic> delete(String path) => _request(() => http.delete(
    Uri.parse('${ApiConfig.baseUrl}$path'),
    headers: _headers,
  ));

  Future<dynamic> uploadFile(String path, File file, {Map<String, String>? fields}) async {
    final request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}$path'));
    if (_accessToken != null) request.headers['Authorization'] = 'Bearer $_accessToken';
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    if (fields != null) request.fields.addAll(fields);
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }
    throw HttpException('Upload failed: ${response.statusCode}');
  }

  // Auth
  Future<Map<String, dynamic>> getMe() async => (await get('/auth/me/')) as Map<String, dynamic>;
  Future<Map<String, dynamic>> updateMe(Map<String, dynamic> data) async => (await patch('/auth/me/', data: data)) as Map<String, dynamic>;
  Future<dynamic> changePassword(Map<String, dynamic> data) => post('/auth/change-password/', data: data);

  // Medicaments
  Future<List<dynamic>> getMedicaments() async => (await _get('/medicaments/')) as List<dynamic>;
  Future<Map<String, dynamic>> getMedicament(int id) async => (await get('/medicaments/$id/')) as Map<String, dynamic>;
  Future<Map<String, dynamic>> createMedicament(Map<String, dynamic> data) async => (await post('/medicaments/', data: data)) as Map<String, dynamic>;
  Future<Map<String, dynamic>> updateMedicament(int id, Map<String, dynamic> data) async => (await patch('/medicaments/$id/', data: data)) as Map<String, dynamic>;
  Future<void> deleteMedicament(int id) => delete('/medicaments/$id/');
  Future<List<dynamic>> getExpiredMedicaments() async => (await _get('/medicaments/expires/')) as List<dynamic>;
  Future<List<dynamic>> getExpiringSoonMedicaments() async => (await _get('/medicaments/expire-bientot/')) as List<dynamic>;

  // Categories
  Future<List<dynamic>> getCategories() async => (await _get('/medicaments/categories/')) as List<dynamic>;
  Future<Map<String, dynamic>> createCategory(Map<String, dynamic> data) async => (await post('/medicaments/categories/', data: data)) as Map<String, dynamic>;

  // Stock
  Future<List<dynamic>> getStock() async => (await _get('/stock/')) as List<dynamic>;
  Future<Map<String, dynamic>> getStockItem(int id) async => (await get('/stock/$id/')) as Map<String, dynamic>;
  Future<List<dynamic>> getLowStock() async => (await _get('/stock/faibles/')) as List<dynamic>;
  Future<List<dynamic>> getOutOfStock() async => (await _get('/stock/rupture/')) as List<dynamic>;
  Future<Map<String, dynamic>> adjustStock(int id, Map<String, dynamic> data) async => (await post('/stock/$id/ajuster/', data: data)) as Map<String, dynamic>;
  Future<List<dynamic>> getMouvements() async => (await _get('/stock/mouvements/')) as List<dynamic>;

  // Lots (via Stock - le backend utilise le modèle Stock)
  Future<List<dynamic>> getLots({int? medicamentId, bool seulementActifs = true}) async {
    if (medicamentId != null) {
      return (await _get('/stock/?medicament=$medicamentId')) as List<dynamic>;
    }
    return (await _get('/stock/')) as List<dynamic>;
  }
  Future<Map<String, dynamic>> getLotDetail(int id) async => (await get('/stock/$id/')) as Map<String, dynamic>;
  Future<Map<String, dynamic>> createLot(Map<String, dynamic> data) async => (await post('/stock/lots/', data: data)) as Map<String, dynamic>;
  Future<Map<String, dynamic>> updateLot(int id, Map<String, dynamic> data) async => (await patch('/stock/$id/', data: data)) as Map<String, dynamic>;
  Future<void> deleteLot(int id) => delete('/stock/$id/');
  Future<List<dynamic>> getMouvementsLot(int lotId) async => (await _get('/stock/mouvements/')) as List<dynamic>;
  Future<Map<String, dynamic>> ajustementLot(int lotId, Map<String, dynamic> data) async => (await post('/stock/$lotId/ajuster/', data: data)) as Map<String, dynamic>;
  Future<List<dynamic>> getLotsExpirant({int jours = 90}) async => (await _get('/medicaments/expire-bientot/')) as List<dynamic>;
  Future<List<dynamic>> getLotsPourVente(int medicamentId, double quantite) async => (await _get('/stock/')) as List<dynamic>;

  // Ventes
  Future<List<dynamic>> getVentes() async => (await _get('/ventes/')) as List<dynamic>;
  Future<Map<String, dynamic>> getVente(int id) async => (await get('/ventes/$id/')) as Map<String, dynamic>;
  Future<Map<String, dynamic>> createVente(Map<String, dynamic> data) async => (await post('/ventes/', data: data)) as Map<String, dynamic>;
  Future<Map<String, dynamic>> getVentesStats() async => (await _get('/ventes/statistiques/')) as Map<String, dynamic>;

  // Achats
  Future<List<dynamic>> getAchats() async => (await _get('/achats/')) as List<dynamic>;
  Future<Map<String, dynamic>> getAchat(int id) async => (await get('/achats/$id/')) as Map<String, dynamic>;
  Future<Map<String, dynamic>> createAchat(Map<String, dynamic> data) async => (await post('/achats/', data: data)) as Map<String, dynamic>;

  // Fournisseurs
  Future<List<dynamic>> getFournisseurs() async => (await _get('/achats/fournisseurs/')) as List<dynamic>;
  Future<Map<String, dynamic>> createFournisseur(Map<String, dynamic> data) async => (await post('/achats/fournisseurs/', data: data)) as Map<String, dynamic>;

  // Clients
  Future<List<dynamic>> getClients() async => (await _get('/clients/')) as List<dynamic>;
  Future<Map<String, dynamic>> createClient(Map<String, dynamic> data) async => (await post('/clients/', data: data)) as Map<String, dynamic>;
  Future<Map<String, dynamic>> updateClient(int id, Map<String, dynamic> data) async => (await put('/clients/$id/', data: data)) as Map<String, dynamic>;

  // Dashboard
  Future<Map<String, dynamic>> getDashboard() async => (await get('/rapports/dashboard/')) as Map<String, dynamic>;

  // Notifications
  Future<List<dynamic>> getNotifications() async => (await _get('/notifications/')) as List<dynamic>;
  Future<int> getUnreadCount() async {
    final data = await _get('/notifications/non-lues/');
    if (data is Map) return data['count'] ?? 0;
    return 0;
  }
  Future<void> markAsRead(int id) => post('/notifications/$id/marquer-lue/');
  Future<void> markAllRead() => post('/notifications/tout-lire/');

  // Prescriptions (via clients app)
  Future<List<dynamic>> getPrescriptions() async => (await _get('/clients/prescriptions/')) as List<dynamic>;
  Future<Map<String, dynamic>> getPrescription(int id) async => (await get('/clients/prescriptions/$id/')) as Map<String, dynamic>;
  Future<Map<String, dynamic>> createPrescription(Map<String, dynamic> data) async => (await post('/clients/prescriptions/', data: data)) as Map<String, dynamic>;
  Future<Map<String, dynamic>> updatePrescription(int id, Map<String, dynamic> data) async => (await patch('/clients/prescriptions/$id/', data: data)) as Map<String, dynamic>;
  Future<void> deletePrescription(int id) => delete('/clients/prescriptions/$id/');

  // Employes
  Future<List<dynamic>> getEmployes() async => (await _get('/employes/')) as List<dynamic>;
  Future<Map<String, dynamic>> createEmploye(Map<String, dynamic> data) async => (await post('/employes/', data: data)) as Map<String, dynamic>;
  Future<Map<String, dynamic>> updateEmploye(int id, Map<String, dynamic> data) async => (await patch('/employes/$id/', data: data)) as Map<String, dynamic>;
  Future<void> deleteEmploye(int id) => delete('/employes/$id/');

  // Abonnements
  Future<List<dynamic>> getAbonnements() async => (await _get('/abonnements/')) as List<dynamic>;
  Future<Map<String, dynamic>> createAbonnement(Map<String, dynamic> data) async => (await post('/abonnements/', data: data)) as Map<String, dynamic>;
  Future<Map<String, dynamic>> updateAbonnement(int id, Map<String, dynamic> data) async => (await patch('/abonnements/$id/', data: data)) as Map<String, dynamic>;
  Future<void> suspendreAbonnement(int id) => post('/abonnements/$id/suspendre/');
  Future<void> activerAbonnement(int id) => post('/abonnements/$id/activer/');

  // Paiements (platform-wide)
  Future<List<dynamic>> getPaiements() async => (await _get('/paiements/')) as List<dynamic>;
  Future<Map<String, dynamic>> createPaiement(Map<String, dynamic> data) async => (await post('/paiements/', data: data)) as Map<String, dynamic>;

  // Pharmacies
  Future<List<dynamic>> getPharmacies() async => (await _get('/pharmacies/')) as List<dynamic>;
  Future<Map<String, dynamic>> createPharmacie(Map<String, dynamic> data) async => (await post('/pharmacies/', data: data)) as Map<String, dynamic>;
  Future<Map<String, dynamic>> updatePharmacie(int id, Map<String, dynamic> data) async => (await patch('/pharmacies/$id/', data: data)) as Map<String, dynamic>;
  Future<void> deletePharmacie(int id) => delete('/pharmacies/$id/');
  Future<Map<String, dynamic>> getPharmacieStats(int id) async => (await get('/pharmacies/$id/statistiques/')) as Map<String, dynamic>;
  Future<void> togglePharmacieActif(int id) => post('/pharmacies/$id/toggle-actif/');

  // Pharmacy Settings
  Future<Map<String, dynamic>> getPharmacySettings() async => (await get('/pharmacies/mes-parametres/')) as Map<String, dynamic>;
  Future<Map<String, dynamic>> updatePharmacySettings(Map<String, dynamic> data) async => (await patch('/pharmacies/mes-parametres/', data: data)) as Map<String, dynamic>;

  // Platform Settings (super admin)
  Future<Map<String, dynamic>> getPlatformSettings() async => (await get('/pharmacies/parametres-plateforme/')) as Map<String, dynamic>;
  Future<Map<String, dynamic>> updatePlatformSettings(Map<String, dynamic> data) async => (await patch('/pharmacies/parametres-plateforme/', data: data)) as Map<String, dynamic>;

  // Vente payment
  Future<Map<String, dynamic>> addVentePayment(int venteId, Map<String, dynamic> data) async => (await post('/ventes/$venteId/paiement/', data: data)) as Map<String, dynamic>;

  // Abonnement payment
  Future<Map<String, dynamic>> addAbonnementPayment(int abonnementId, Map<String, dynamic> data) async => (await post('/abonnements/$abonnementId/paiement/', data: data)) as Map<String, dynamic>;

  // User Management (Super Admin)
  Future<List<dynamic>> getUsers() async => (await _get('/auth/utilisateurs/')) as List<dynamic>;
  Future<Map<String, dynamic>> createUser(Map<String, dynamic> data) async => (await post('/auth/utilisateurs/', data: data)) as Map<String, dynamic>;
  Future<Map<String, dynamic>> updateUser(int id, Map<String, dynamic> data) async => (await patch('/auth/utilisateurs/$id/', data: data)) as Map<String, dynamic>;
  Future<void> deleteUser(int id) => delete('/auth/utilisateurs/$id/');
  Future<void> toggleUserActif(int id) => post('/auth/utilisateurs/$id/toggle-actif/');

  // Client purchase history
  Future<List<dynamic>> getClientPurchases(int clientId) async => (await _get('/clients/$clientId/achats/')) as List<dynamic>;

  // Chat/AI
  Future<Map<String, dynamic>> sendChatMessage(String message) async => (await post('/auth/chat/', data: {'message': message})) as Map<String, dynamic>;

  // Rapports
  Future<Map<String, dynamic>> getRapportVentes({String? dateDebut, String? dateFin}) async {
    var path = '/ventes/statistiques/';
    if (dateDebut != null || dateFin != null) {
      path += '?';
      if (dateDebut != null) path += 'date_debut=$dateDebut';
      if (dateDebut != null && dateFin != null) path += '&';
      if (dateFin != null) path += 'date_fin=$dateFin';
    }
    return (await get(path)) as Map<String, dynamic>;
  }
  Future<List<dynamic>> getEvenementsSuperAdmin() async => (await _get('/rapports/evenements/')) as List<dynamic>;

  // Vente stats with params
  Future<Map<String, dynamic>> getVentesStatsDetailed({String? periode}) async {
    var path = '/ventes/statistiques/';
    if (periode != null) path += '?periode=$periode';
    return (await get(path)) as Map<String, dynamic>;
  }
}

class HttpException implements Exception {
  final String message;
  HttpException(this.message);
  @override
  String toString() => message;
}
