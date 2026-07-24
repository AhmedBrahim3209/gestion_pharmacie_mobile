class PlatformSettings {
  final String? nom;
  final String? description;
  final String? supportEmail;
  final String? supportPhone;
  final String? logo;
  final bool twoFactorEnabled;
  final double? prixAbonnement;
  final int? dureeEssaiJours;
  final int? dureeStandardJours;
  final double? remisePourcentage;
  final bool remiseActive;

  PlatformSettings({
    this.nom,
    this.description,
    this.supportEmail,
    this.supportPhone,
    this.logo,
    this.twoFactorEnabled = false,
    this.prixAbonnement,
    this.dureeEssaiJours,
    this.dureeStandardJours,
    this.remisePourcentage,
    this.remiseActive = false,
  });

  factory PlatformSettings.fromJson(Map<String, dynamic> json) {
    return PlatformSettings(
      nom: json['nom'],
      description: json['description'],
      supportEmail: json['support_email'],
      supportPhone: json['support_phone'],
      logo: json['logo'],
      twoFactorEnabled: json['two_factor_enabled'] ?? false,
      prixAbonnement: _toDouble(json['prix_abonnement']),
      dureeEssaiJours: json['duree_essai_jours'],
      dureeStandardJours: json['duree_standard_jours'],
      remisePourcentage: _toDouble(json['remise_pourcentage']),
      remiseActive: json['remise_active'] ?? false,
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}
