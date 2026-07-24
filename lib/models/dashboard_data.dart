class DashboardData {
  final int stockFaible;
  final int enRupture;
  final int expiresBientot;
  final int ventesAujourdhui;
  final double caAujourdhui;
  final double caMois;
  final int totalVentesMois;
  final int medicamentsExpires;
  final List<double> caParJour;

  DashboardData({
    this.stockFaible = 0,
    this.enRupture = 0,
    this.expiresBientot = 0,
    this.ventesAujourdhui = 0,
    this.caAujourdhui = 0,
    this.caMois = 0,
    this.totalVentesMois = 0,
    this.medicamentsExpires = 0,
    this.caParJour = const [],
  });

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    List<double> parseCaParJour(dynamic data) {
      if (data is List) {
        if (data.every((e) => e is num)) {
          return data.map((e) => (e as num).toDouble()).toList();
        }
        return data.map((e) {
          if (e is Map) return _toDouble(e['ca']) ?? 0.0;
          return _toDouble(e) ?? 0.0;
        }).toList();
      }
      return [];
    }

    return DashboardData(
      stockFaible: json['stock_faible'] ?? 0,
      enRupture: json['stock_rupture'] ?? 0,
      expiresBientot: json['medicaments_expire_bientot'] ?? 0,
      ventesAujourdhui: json['nb_ventes_jour'] ?? 0,
      caAujourdhui: _toDouble(json['ca_aujourd_hui']) ?? 0,
      caMois: _toDouble(json['ca_mois']) ?? 0,
      totalVentesMois: json['nb_ventes_mois'] ?? 0,
      medicamentsExpires: json['medicaments_expires'] ?? 0,
      caParJour: parseCaParJour(json['ventes_semaine'] ?? json['ca_par_jour']),
    );
  }
}
