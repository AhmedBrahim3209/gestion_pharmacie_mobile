import 'package:flutter/material.dart';

class Lot {
  final int id;
  final int medicamentId;
  final String medicamentNom;
  final String numeroLot;
  final double quantite;
  final double quantiteInitiale;
  final DateTime dateFabrication;
  final DateTime dateExpiration;
  final int? fournisseurId;
  final String? fournisseurNom;
  final double prixAchat;
  final double prixVente;
  final bool estActif;
  final DateTime dateCreation;
  final DateTime? dateModification;

  Lot({
    required this.id,
    required this.medicamentId,
    required this.medicamentNom,
    required this.numeroLot,
    required this.quantite,
    required this.quantiteInitiale,
    required this.dateFabrication,
    required this.dateExpiration,
    this.fournisseurId,
    this.fournisseurNom,
    required this.prixAchat,
    required this.prixVente,
    required this.estActif,
    required this.dateCreation,
    this.dateModification,
  });

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  factory Lot.fromJson(Map<String, dynamic> json) {
    return Lot(
      id: json['id'],
      medicamentId: json['medicament'],
      medicamentNom: json['medicament_nom'] ?? '',
      numeroLot: json['numero_lot'] ?? '',
      quantite: _toDouble(json['quantite']) ?? 0,
      quantiteInitiale: _toDouble(json['quantite_initiale']) ?? 0,
      dateFabrication: _parseDate(json['date_fabrication']) ?? DateTime.now(),
      dateExpiration: _parseDate(json['date_expiration']) ?? DateTime.now().add(const Duration(days: 365)),
      fournisseurId: json['fournisseur'],
      fournisseurNom: json['fournisseur_nom'],
      prixAchat: _toDouble(json['prix_achat']) ?? 0,
      prixVente: _toDouble(json['prix_vente']) ?? 0,
      estActif: json['est_actif'] ?? true,
      dateCreation: _parseDate(json['date_creation']) ?? DateTime.now(),
      dateModification: json['date_modification'] != null ? _parseDate(json['date_modification']) : null,
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  int get joursRestants => dateExpiration.difference(DateTime.now()).inDays;
  bool get estExpire => joursRestants <= 0;
  bool get expireBientot => joursRestants > 0 && joursRestants <= 90;
  double get tauxConsommation => quantiteInitiale > 0 ? ((quantiteInitiale - quantite) / quantiteInitiale) * 100 : 0;
  String get statut {
    if (!estActif) return 'Inactif';
    if (estExpire) return 'Expiré';
    if (expireBientot) return 'Expire bientôt';
    return 'OK';
  }
  Color get statutColor {
    if (!estActif) return Colors.grey;
    if (estExpire) return Colors.red;
    if (expireBientot) return Colors.orange;
    return Colors.green;
  }
}

class MouvementLot {
  final int id;
  final int lotId;
  final String typeMouvement;
  final double quantite;
  final double quantiteAvant;
  final double quantiteApres;
  final String? motif;
  final DateTime date;
  final String? utilisateurNom;
  final int? venteId;
  final int? achatId;

  MouvementLot({
    required this.id,
    required this.lotId,
    required this.typeMouvement,
    required this.quantite,
    required this.quantiteAvant,
    required this.quantiteApres,
    this.motif,
    required this.date,
    this.utilisateurNom,
    this.venteId,
    this.achatId,
  });

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  factory MouvementLot.fromJson(Map<String, dynamic> json) {
    return MouvementLot(
      id: json['id'],
      lotId: json['lot'],
      typeMouvement: json['type_mouvement'],
      quantite: _toDouble(json['quantite']) ?? 0,
      quantiteAvant: _toDouble(json['quantite_avant']) ?? 0,
      quantiteApres: _toDouble(json['quantite_apres']) ?? 0,
      motif: json['motif'],
      date: Lot._parseDate(json['date']) ?? DateTime.now(),
      utilisateurNom: json['utilisateur_nom'],
      venteId: json['vente'],
      achatId: json['achat'],
    );
  }

  String get typeLibelle {
    switch (typeMouvement) {
      case 'entree': return 'Entrée';
      case 'sortie': return 'Sortie';
      case 'ajustement': return 'Ajustement';
      case 'vente': return 'Vente';
      case 'perte': return 'Perte';
      case 'retour': return 'Retour';
      default: return typeMouvement;
    }
  }
  Color get typeColor {
    switch (typeMouvement) {
      case 'entree': return Colors.green;
      case 'sortie':
      case 'vente':
      case 'perte': return Colors.red;
      case 'retour': return Colors.blue;
      default: return Colors.orange;
    }
  }
}