class Pharmacie {
  final int id;
  final String nom;
  final String? adresse;
  final String? telephone;
  final String? email;
  final String? logo;
  final String? numeroLicence;
  final bool estActive;
  final String? dateCreation;
  final String? langue;
  final String? devise;
  final String? messageTicket;

  Pharmacie({
    required this.id,
    required this.nom,
    this.adresse,
    this.telephone,
    this.email,
    this.logo,
    this.numeroLicence,
    this.estActive = true,
    this.dateCreation,
    this.langue,
    this.devise,
    this.messageTicket,
  });

  factory Pharmacie.fromJson(Map<String, dynamic> json) {
    return Pharmacie(
      id: json['id'],
      nom: json['nom'],
      adresse: json['adresse'],
      telephone: json['telephone'],
      email: json['email'],
      logo: json['logo'],
      numeroLicence: json['numero_licence'],
      estActive: json['est_active'] ?? true,
      dateCreation: json['date_creation'],
      langue: json['langue'],
      devise: json['devise'],
      messageTicket: json['message_ticket'],
    );
  }

  Map<String, dynamic> toJson() => {
    'nom': nom,
    'adresse': adresse,
    'telephone': telephone,
    'email': email,
    'numero_licence': numeroLicence,
    'est_active': estActive,
    'langue': langue,
    'devise': devise,
    'message_ticket': messageTicket,
  };
}
