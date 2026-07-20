class Medicament {
  final int id;
  final String nom;
  final String? description;
  final String? codeBarre;
  final int? categorieId;
  final String? categorieNom;
  final double? prixAchat;
  final double prixVente;
  final String unite;
  final DateTime? dateExpiration;
  final String? image;
  final bool estActif;
  final double? stockQuantite;
  final double? stockSeuilMin;

  Medicament({
    required this.id,
    required this.nom,
    this.description,
    this.codeBarre,
    this.categorieId,
    this.categorieNom,
    this.prixAchat,
    required this.prixVente,
    this.unite = 'unité',
    this.dateExpiration,
    this.image,
    this.estActif = true,
    this.stockQuantite,
    this.stockSeuilMin,
  });

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  factory Medicament.fromJson(Map<String, dynamic> json) {
    return Medicament(
      id: json['id'],
      nom: json['nom'],
      description: json['description'],
      codeBarre: json['code_barre'],
      categorieId: json['categorie'],
      categorieNom: json['categorie_nom'],
      prixAchat: _toDouble(json['prix_achat']),
      prixVente: _toDouble(json['prix_vente']) ?? 0,
      unite: json['unite'] ?? 'unité',
      dateExpiration: json['date_expiration'] != null ? DateTime.tryParse(json['date_expiration']) : null,
      image: json['image'],
      estActif: json['est_actif'] ?? true,
      stockQuantite: _toDouble(json['quantite_stock']),
      stockSeuilMin: _toDouble(json['seuil_min']),
    );
  }

  Map<String, dynamic> toJson() => {
    'nom': nom,
    'description': description,
    'code_barre': codeBarre,
    'categorie': categorieId,
    'prix_achat': prixAchat,
    'prix_vente': prixVente,
    'unite': unite,
    'date_expiration': dateExpiration?.toIso8601String().split('T').first,
    'est_actif': estActif,
  };

  bool get isExpired => dateExpiration != null && dateExpiration!.isBefore(DateTime.now());
  bool get isLowStock => stockQuantite != null && stockSeuilMin != null && stockQuantite! <= stockSeuilMin!;
  bool get isOutOfStock => stockQuantite != null && stockQuantite! <= 0;
}
