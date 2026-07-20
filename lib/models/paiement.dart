class Paiement {
  final int id;
  final String? pharmacie;
  final String reference;
  final double montant;
  final String? date;
  final String statut;

  Paiement({
    required this.id,
    this.pharmacie,
    required this.reference,
    required this.montant,
    this.date,
    this.statut = 'valide',
  });

  factory Paiement.fromJson(Map<String, dynamic> json) {
    return Paiement(
      id: json['id'],
      pharmacie: json['pharmacie'],
      reference: json['reference'] ?? '',
      montant: (json['montant'] as num?)?.toDouble() ?? 0,
      date: json['date'],
      statut: json['statut'] ?? 'valide',
    );
  }
}
