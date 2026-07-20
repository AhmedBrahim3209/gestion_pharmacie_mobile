class PlatformSettings {
  final String? nom;
  final String? description;
  final String? supportEmail;
  final String? supportPhone;
  final String? logo;
  final bool twoFactorEnabled;

  PlatformSettings({
    this.nom,
    this.description,
    this.supportEmail,
    this.supportPhone,
    this.logo,
    this.twoFactorEnabled = false,
  });

  factory PlatformSettings.fromJson(Map<String, dynamic> json) {
    return PlatformSettings(
      nom: json['nom'],
      description: json['description'],
      supportEmail: json['support_email'],
      supportPhone: json['support_phone'],
      logo: json['logo'],
      twoFactorEnabled: json['two_factor_enabled'] ?? false,
    );
  }
}
