class Fournisseur {
  final int id;
  final String nom;
  final String? contact;
  final String? telephone;
  final String? email;
  final String? adresse;
  final bool estActif;

  Fournisseur({
    required this.id,
    required this.nom,
    this.contact,
    this.telephone,
    this.email,
    this.adresse,
    this.estActif = true,
  });

  factory Fournisseur.fromJson(Map<String, dynamic> json) {
    return Fournisseur(
      id: json['id'],
      nom: json['nom'],
      contact: json['contact'],
      telephone: json['telephone'],
      email: json['email'],
      adresse: json['adresse'],
      estActif: json['est_actif'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'nom': nom,
    'contact': contact,
    'telephone': telephone,
    'email': email,
    'adresse': adresse,
    'est_actif': estActif,
  };
}
