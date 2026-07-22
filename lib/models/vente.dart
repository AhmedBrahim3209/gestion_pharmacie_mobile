class Vente {
  final int id;
  final String numero;
  final int? clientId;
  final String? clientNom;
  final String dateVente;
  final String statut;
  final double montantTotal;
  final double remise;
  final double montantNet;
  final String? enregistreParNom;
  final String? notes;
  final List<LigneVente> lignes;

  Vente({
    required this.id,
    required this.numero,
    this.clientId,
    this.clientNom,
    required this.dateVente,
    this.statut = 'en_attente',
    this.montantTotal = 0,
    this.remise = 0,
    this.montantNet = 0,
    this.enregistreParNom,
    this.notes,
    this.lignes = const [],
  });

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  factory Vente.fromJson(Map<String, dynamic> json) {
    return Vente(
      id: json['id'],
      numero: json['numero'] ?? '',
      clientId: json['client'],
      clientNom: json['client_nom'],
      dateVente: json['date_vente'] ?? '',
      statut: json['statut'] ?? 'en_attente',
      montantTotal: _toDouble(json['montant_total']) ?? 0,
      remise: _toDouble(json['remise']) ?? 0,
      montantNet: _toDouble(json['montant_net']) ?? 0,
      enregistreParNom: json['enregistre_par_nom'],
      notes: json['notes'],
      lignes: (json['lignes'] as List?)?.map((e) => LigneVente.fromJson(e)).toList() ?? [],
    );
  }
}

class LigneVente {
  final int id;
  final int medicamentId;
  final String medicamentNom;
  final double quantite;
  final double prixUnitaire;
  final double sousTotal;

  LigneVente({
    required this.id,
    required this.medicamentId,
    required this.medicamentNom,
    required this.quantite,
    required this.prixUnitaire,
    required this.sousTotal,
  });

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  factory LigneVente.fromJson(Map<String, dynamic> json) {
    return LigneVente(
      id: json['id'],
      medicamentId: json['medicament'],
      medicamentNom: json['medicament_nom'] ?? '',
      quantite: _toDouble(json['quantite']) ?? 0,
      prixUnitaire: _toDouble(json['prix_unitaire']) ?? 0,
      sousTotal: _toDouble(json['sous_total']) ?? 0,
    );
  }
}
