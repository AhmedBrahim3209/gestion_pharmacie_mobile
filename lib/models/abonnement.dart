class Abonnement {
  final int id;
  final int pharmacieId;
  final String? pharmacieNom;
  final String plan;
  final String statut;
  final String? dateDebut;
  final String? dateFin;
  final double? montant;
  final String? notes;

  Abonnement({
    required this.id,
    required this.pharmacieId,
    this.pharmacieNom,
    this.plan = 'mensuel',
    this.statut = 'actif',
    this.dateDebut,
    this.dateFin,
    this.montant,
    this.notes,
  });

  factory Abonnement.fromJson(Map<String, dynamic> json) {
    return Abonnement(
      id: json['id'],
      pharmacieId: json['pharmacie'],
      pharmacieNom: json['pharmacie_nom'],
      plan: json['plan'] ?? 'mensuel',
      statut: json['statut'] ?? 'actif',
      dateDebut: json['date_debut'],
      dateFin: json['date_fin'],
      montant: (json['montant'] as num?)?.toDouble(),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() => {
    'pharmacie': pharmacieId,
    'plan': plan,
    'statut': statut,
    'date_debut': dateDebut,
    'date_fin': dateFin,
    'montant': montant,
    'notes': notes,
  };

  bool get estActif => statut == 'actif';
}
