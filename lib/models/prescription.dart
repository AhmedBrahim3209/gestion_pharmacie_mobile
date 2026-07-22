class Prescription {
  final int id;
  final String numero;
  final int? clientId;
  final String? clientNom;
  final String? medecinNom;
  final String? medecinSpecialite;
  final String? datePrescription;
  final String? dateValidite;
  final String? notes;
  final bool estServie;
  final String? createdByName;
  final List<LignePrescription> lignes;

  Prescription({
    required this.id,
    required this.numero,
    this.clientId,
    this.clientNom,
    this.medecinNom,
    this.medecinSpecialite,
    this.datePrescription,
    this.dateValidite,
    this.notes,
    this.estServie = false,
    this.createdByName,
    this.lignes = const [],
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      id: json['id'],
      numero: json['numero'] ?? '',
      clientId: json['client'],
      clientNom: json['client_nom'],
      medecinNom: json['medecin_nom'],
      medecinSpecialite: json['medecin_specialite'],
      datePrescription: json['date_prescription'],
      dateValidite: json['date_validite'],
      notes: json['notes'],
      estServie: json['est_servie'] ?? false,
      createdByName: json['created_by_name'],
      lignes: (json['lignes'] as List?)?.map((e) => LignePrescription.fromJson(e)).toList() ?? [],
    );
  }
}

class LignePrescription {
  final int id;
  final int medicamentId;
  final String? medicamentNom;
  final double quantite;
  final String? posologie;
  final String? duree;

  LignePrescription({
    required this.id,
    required this.medicamentId,
    this.medicamentNom,
    required this.quantite,
    this.posologie,
    this.duree,
  });

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  factory LignePrescription.fromJson(Map<String, dynamic> json) {
    return LignePrescription(
      id: json['id'],
      medicamentId: json['medicament'],
      medicamentNom: json['medicament_nom'],
      quantite: _toDouble(json['quantite']) ?? 0,
      posologie: json['posologie'],
      duree: json['duree'],
    );
  }
}
