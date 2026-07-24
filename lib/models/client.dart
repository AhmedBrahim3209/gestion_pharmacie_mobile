class Client {
  final int id;
  final String nom;
  final String? prenom;
  final String? telephone;
  final String? email;
  final String? adresse;
  final String? sexe;
  final DateTime? dateNaissance;
  final String? statut;
  final int nombreAchats;

  Client({
    required this.id,
    required this.nom,
    this.prenom,
    this.telephone,
    this.email,
    this.adresse,
    this.sexe,
    this.dateNaissance,
    this.statut,
    this.nombreAchats = 0,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'],
      nom: json['nom'],
      prenom: json['prenom'],
      telephone: json['telephone'],
      email: json['email'],
      adresse: json['adresse'],
      sexe: json['sexe'],
      dateNaissance: json['date_naissance'] != null ? DateTime.tryParse(json['date_naissance']) : null,
      statut: json['statut'],
      nombreAchats: json['nombre_achats'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'nom': nom,
    'prenom': prenom,
    'telephone': telephone,
    'email': email,
    'adresse': adresse,
    'sexe': sexe,
    'date_naissance': dateNaissance?.toIso8601String().split('T').first,
  };

  String get fullName => '${prenom ?? ''} $nom'.trim();
  bool get isFidele => statut == 'fidele';
  bool get isActif => statut == 'actif';
}
