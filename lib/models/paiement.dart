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

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  factory Paiement.fromJson(Map<String, dynamic> json) {
    return Paiement(
      id: json['id'],
      pharmacie: json['pharmacie'],
      reference: json['reference'] ?? '',
      montant: _toDouble(json['montant']) ?? 0,
      date: json['date'],
      statut: json['statut'] ?? 'valide',
    );
  }
}
