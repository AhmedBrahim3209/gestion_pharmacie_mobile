class Stock {
  final int id;
  final int medicamentId;
  final String medicamentNom;
  final double quantite;
  final double seuilMin;
  final String? numeroLot;
  final String? derniereMaj;

  Stock({
    required this.id,
    required this.medicamentId,
    required this.medicamentNom,
    required this.quantite,
    required this.seuilMin,
    this.numeroLot,
    this.derniereMaj,
  });

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      id: json['id'],
      medicamentId: json['medicament'],
      medicamentNom: json['medicament_nom'] ?? '',
      quantite: (json['quantite'] as num).toDouble(),
      seuilMin: (json['seuil_min'] as num).toDouble(),
      numeroLot: json['numero_lot'],
      derniereMaj: json['derniere_maj'],
    );
  }
}

class MouvementStock {
  final int id;
  final int stockId;
  final String typeMouvement;
  final double quantite;
  final double? quantiteAvant;
  final double? quantiteApres;
  final String? motif;
  final String? date;
  final String? utilisateurNom;

  MouvementStock({
    required this.id,
    required this.stockId,
    required this.typeMouvement,
    required this.quantite,
    this.quantiteAvant,
    this.quantiteApres,
    this.motif,
    this.date,
    this.utilisateurNom,
  });

  factory MouvementStock.fromJson(Map<String, dynamic> json) {
    return MouvementStock(
      id: json['id'],
      stockId: json['stock'],
      typeMouvement: json['type_mouvement'],
      quantite: (json['quantite'] as num).toDouble(),
      quantiteAvant: (json['quantite_avant'] as num?)?.toDouble(),
      quantiteApres: (json['quantite_apres'] as num?)?.toDouble(),
      motif: json['motif'],
      date: json['date'],
      utilisateurNom: json['utilisateur_nom'],
    );
  }
}
