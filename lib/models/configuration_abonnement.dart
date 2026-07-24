class ConfigurationAbonnement {
  final int id;
  final int pharmacieId;
  final String? pharmacieNom;
  final String plan;
  final double montant;
  final int dureeJours;
  final String dateDebut;
  final String dateFin;
  final bool actif;
  final String? notes;

  ConfigurationAbonnement({
    required this.id,
    required this.pharmacieId,
    this.pharmacieNom,
    this.plan = 'standard',
    required this.montant,
    required this.dureeJours,
    required this.dateDebut,
    required this.dateFin,
    this.actif = true,
    this.notes,
  });

  factory ConfigurationAbonnement.fromJson(Map<String, dynamic> json) {
    return ConfigurationAbonnement(
      id: json['id'],
      pharmacieId: json['pharmacie'],
      pharmacieNom: json['pharmacie_nom'],
      plan: json['plan'] ?? 'standard',
      montant: _toDouble(json['montant']) ?? 0,
      dureeJours: json['duree_jours'] ?? 30,
      dateDebut: json['date_debut'] ?? '',
      dateFin: json['date_fin'] ?? '',
      actif: json['actif'] ?? true,
      notes: json['notes'],
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  Map<String, dynamic> toJson() => {
    'pharmacie': pharmacieId,
    'plan': plan,
    'montant': montant,
    'duree_jours': dureeJours,
    'date_debut': dateDebut,
    'date_fin': dateFin,
    'actif': actif,
    'notes': notes,
  };
}