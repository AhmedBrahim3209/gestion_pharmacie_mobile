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

  factory Vente.fromJson(Map<String, dynamic> json) {
    return Vente(
      id: json['id'],
      numero: json['numero'] ?? '',
      clientId: json['client'],
      clientNom: json['client_nom'],
      dateVente: json['date_vente'] ?? '',
      statut: json['statut'] ?? 'en_attente',
      montantTotal: (json['montant_total'] as num?)?.toDouble() ?? 0,
      remise: (json['remise'] as num?)?.toDouble() ?? 0,
      montantNet: (json['montant_net'] as num?)?.toDouble() ?? 0,
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

  factory LigneVente.fromJson(Map<String, dynamic> json) {
    return LigneVente(
      id: json['id'],
      medicamentId: json['medicament'],
      medicamentNom: json['medicament_nom'] ?? '',
      quantite: (json['quantite'] as num).toDouble(),
      prixUnitaire: (json['prix_unitaire'] as num).toDouble(),
      sousTotal: (json['sous_total'] as num).toDouble(),
    );
  }
}
