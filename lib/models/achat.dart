class Achat {
  final int id;
  final String numero;
  final int? fournisseurId;
  final String? fournisseurNom;
  final String dateAchat;
  final String statut;
  final double montantTotal;
  final String? notes;
  final String? enregistreParNom;
  final List<LigneAchat> lignes;

  Achat({
    required this.id,
    required this.numero,
    this.fournisseurId,
    this.fournisseurNom,
    required this.dateAchat,
    this.statut = 'en_attente',
    this.montantTotal = 0,
    this.notes,
    this.enregistreParNom,
    this.lignes = const [],
  });

  factory Achat.fromJson(Map<String, dynamic> json) {
    return Achat(
      id: json['id'],
      numero: json['numero'] ?? '',
      fournisseurId: json['fournisseur'],
      fournisseurNom: json['fournisseur_nom'],
      dateAchat: json['date_achat'] ?? '',
      statut: json['statut'] ?? 'en_attente',
      montantTotal: (json['montant_total'] as num?)?.toDouble() ?? 0,
      notes: json['notes'],
      enregistreParNom: json['enregistre_par_nom'],
      lignes: (json['lignes'] as List?)?.map((e) => LigneAchat.fromJson(e)).toList() ?? [],
    );
  }
}

class LigneAchat {
  final int id;
  final int medicamentId;
  final String medicamentNom;
  final double quantite;
  final double prixUnitaire;
  final double sousTotal;

  LigneAchat({
    required this.id,
    required this.medicamentId,
    required this.medicamentNom,
    required this.quantite,
    required this.prixUnitaire,
    required this.sousTotal,
  });

  factory LigneAchat.fromJson(Map<String, dynamic> json) {
    return LigneAchat(
      id: json['id'],
      medicamentId: json['medicament'],
      medicamentNom: json['medicament_nom'] ?? '',
      quantite: (json['quantite'] as num).toDouble(),
      prixUnitaire: (json['prix_unitaire'] as num).toDouble(),
      sousTotal: (json['sous_total'] as num).toDouble(),
    );
  }
}
