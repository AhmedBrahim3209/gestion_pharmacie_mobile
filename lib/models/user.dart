class User {
  final int id;
  final String username;
  final String? email;
  final String role;
  final String? telephone;
  final String? photo;
  final bool isActive;
  final int? pharmacieId;
  final String? pharmacieNom;
  final String? firstName;
  final String? lastName;
  final String? fullName;

  User({
    required this.id,
    required this.username,
    this.email,
    required this.role,
    this.telephone,
    this.photo,
    this.isActive = true,
    this.pharmacieId,
    this.pharmacieNom,
    this.firstName,
    this.lastName,
    this.fullName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      role: json['role'] ?? 'employe',
      telephone: json['telephone'],
      photo: json['photo'],
      isActive: json['is_active'] ?? true,
      pharmacieId: json['pharmacie'],
      pharmacieNom: json['pharmacie_nom'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      fullName: json['full_name'],
    );
  }

  String get displayName => fullName ?? username;

  bool get isSuperAdmin => role == 'super_admin';
  bool get isAdminPharmacie => role == 'admin_pharmacie';
  bool get isCaissier => role == 'caissier';
  bool get isEmploye => role == 'employe';
}
