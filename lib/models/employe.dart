class Employe {
  final int id;
  final int? utilisateurId;
  final String? utilisateurNom;
  final String? role;
  final int pharmacieId;
  final String? poste;
  final String? dateEmbauche;
  final double? salaire;
  final String? numeroEmploye;

  Employe({
    required this.id,
    this.utilisateurId,
    this.utilisateurNom,
    this.role,
    required this.pharmacieId,
    this.poste,
    this.dateEmbauche,
    this.salaire,
    this.numeroEmploye,
  });

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  factory Employe.fromJson(Map<String, dynamic> json) {
    final detail = json['utilisateur_detail'] as Map<String, dynamic>?;
    return Employe(
      id: json['id'],
      utilisateurId: json['utilisateur'],
      utilisateurNom: json['utilisateur_nom'] ?? detail?['username'],
      role: detail?['role'],
      pharmacieId: json['pharmacie'],
      poste: json['poste'],
      dateEmbauche: json['date_embauche'],
      salaire: _toDouble(json['salaire']),
      numeroEmploye: json['numero_employe'],
    );
  }

  Map<String, dynamic> toJson() => {
    'utilisateur': utilisateurId,
    'pharmacie': pharmacieId,
    'poste': poste,
    'date_embauche': dateEmbauche,
    'salaire': salaire,
    'numero_employe': numeroEmploye,
  };
}
