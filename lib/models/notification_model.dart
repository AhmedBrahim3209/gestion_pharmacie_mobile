class AppNotification {
  final int id;
  final String titre;
  final String? message;
  final bool estLue;
  final String? typeNotification;
  final String? date;
  final String? lien;

  AppNotification({
    required this.id,
    required this.titre,
    this.message,
    this.estLue = false,
    this.typeNotification,
    this.date,
    this.lien,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      titre: json['titre'] ?? '',
      message: json['message'],
      estLue: json['est_lue'] ?? false,
      typeNotification: json['type_notification'],
      date: json['date'],
      lien: json['lien'],
    );
  }
}
