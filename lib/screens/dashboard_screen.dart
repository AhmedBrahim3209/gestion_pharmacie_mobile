import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../config/app_theme.dart';
import '../config/currency_helper.dart';
import '../providers/dashboard_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/stat_card.dart';
import '../widgets/loading_widget.dart';
import 'ventes/nouvelle_vente_screen.dart';
import 'stock/stock_list_screen.dart';
import 'ventes/ventes_list_screen.dart';
import 'employes/employes_list_screen.dart';
import 'abonnements/abonnements_list_screen.dart';
import 'pharmacies/pharmacies_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  const DashboardScreen({super.key, this.onMenuTap});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<dynamic> _evenements = [];
  int _totalPharmacies = 0;
  int _totalEmployes = 0;
  int _abonnementsActifs = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAll();
    });
  }

  Future<void> _loadAll() async {
    final prov = context.read<DashboardProvider>();
    await prov.loadDashboard();
    final user = context.read<AuthProvider>().user;
    if (user?.isSuperAdmin == true) {
      await _loadSuperAdminData();
    }
  }

  Future<void> _loadSuperAdminData() async {
    final api = ApiService();
    try {
      final d = context.read<DashboardProvider>();
      final events = await d.loadEvenements();
      if (mounted) setState(() => _evenements = events);
    } catch (_) {}
    try {
      final pharms = await api.getPharmacies();
      if (mounted) setState(() => _totalPharmacies = pharms.length);
    } catch (_) {}
    try {
      final users = await api.getUsers();
      if (mounted) setState(() => _totalEmployes = users.length);
    } catch (_) {}
    try {
      final abos = await api.getAbonnements();
      if (mounted) setState(() => _abonnementsActifs = abos.where((a) => a['statut'] == 'actif').length);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final dashboard = context.watch<DashboardProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: widget.onMenuTap),
        title: Text(user?.isSuperAdmin == true ? 'Dashboard' : 'Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
          CircleAvatar(
            radius: 14,
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
            child: Text(user?.username[0].toUpperCase() ?? '?', style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor)),
          ),
        ],
      ),
      body: RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.primaryColor, AppTheme.secondaryColor]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(user?.username[0].toUpperCase() ?? '?', style: const TextStyle(fontSize: 20, color: Colors.white)),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bonjour, ${user?.username ?? ''}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(user?.isSuperAdmin == true ? 'Super Administrateur' : (user?.pharmacieNom ?? ''), style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (dashboard.isLoading)
            const LoadingWidget()
          else
            ..._buildDashboardGrid(context, dashboard.data, user),
        ],
      ),
    ),
    );
  }

  List<Widget> _buildDashboardGrid(BuildContext context, data, user) {
    if (data == null) return const [Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Aucune donnée disponible', style: TextStyle(color: Colors.grey))))];
    return [
      if (user?.isSuperAdmin == true)
        _buildSuperAdminSection(data)
      else ...[
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            StatCard(title: 'CA aujourd\'hui', value: '${data.caAujourdhui} ${AppCurrency.symbol}', icon: Icons.today, color: AppTheme.accentColor),
            StatCard(title: 'CA du mois', value: '${data.caMois} ${AppCurrency.symbol}', icon: Icons.monetization_on, color: AppTheme.successColor),
            StatCard(title: 'Ventes aujourd\'hui', value: '${data.ventesAujourdhui}', icon: Icons.shopping_cart, color: AppTheme.warningColor),
            StatCard(title: 'Stock faible', value: '${data.stockFaible}', icon: Icons.warning_amber, color: AppTheme.errorColor),
            StatCard(title: 'Expire bientôt', value: '${data.expiresBientot}', icon: Icons.calendar_month, color: Colors.purple),
            StatCard(title: 'Expirés', value: '${data.medicamentsExpires}', icon: Icons.medication, color: Colors.teal),
          ],
        ),
        const SizedBox(height: 16),
        _sectionCard(
          title: 'Actions rapides',
          child: Row(
            children: [
              _actionChip(context, Icons.add_shopping_cart, 'Nouvelle vente', AppTheme.successColor, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NouvelleVenteScreen()))),
              const SizedBox(width: 8),
              _actionChip(context, Icons.inventory, 'Voir stock', AppTheme.accentColor, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StockListScreen()))),
              const SizedBox(width: 8),
              _actionChip(context, Icons.receipt_long, 'Historique', AppTheme.warningColor, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VentesListScreen()))),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          title: 'Évolution du chiffre d\'affaires',
                child: SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 50000, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1)),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 50, getTitlesWidget: (value, meta) => Text('${value.toInt()}', style: const TextStyle(fontSize: 10)))),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
                    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
                    return value.toInt() >= 0 && value.toInt() < days.length ? Text(days[value.toInt()], style: const TextStyle(fontSize: 10)) : const SizedBox();
                  })),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0, maxX: 6,
                minY: 0, maxY: _calcMaxY(data.caParJour),
                lineBarsData: [
                  LineChartBarData(spots: _buildChartSpots(data.caParJour), isCurved: true, color: AppTheme.primaryColor, barWidth: 3, dotData: FlDotData(show: true), belowBarData: BarAreaData(show: true, color: AppTheme.primaryColor.withValues(alpha: 0.1))),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          title: 'Alertes',
          child: Column(
            children: [
              _alertRow(Icons.warning_amber_rounded, 'Stock faible', '${data.stockFaible} médicaments', data.stockFaible > 0 ? AppTheme.warningColor : AppTheme.successColor),
              const Divider(height: 1),
              _alertRow(Icons.sick_outlined, 'En rupture', '${data.enRupture} médicaments', data.enRupture > 0 ? AppTheme.errorColor : AppTheme.successColor),
              const Divider(height: 1),
              _alertRow(Icons.calendar_month_outlined, 'Expire bientôt', '${data.expiresBientot} médicaments', data.expiresBientot > 0 ? AppTheme.warningColor : AppTheme.successColor),
            ],
          ),
        ),
      ],
    ];
  }

  Widget _buildSuperAdminSection(data) {
    return Column(
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            StatCard(title: 'Pharmacies', value: '$_totalPharmacies', icon: Icons.local_pharmacy, color: AppTheme.primaryColor),
            StatCard(title: 'Employés', value: '$_totalEmployes', icon: Icons.badge, color: Colors.purple),
            StatCard(title: 'Abonnements actifs', value: '$_abonnementsActifs', icon: Icons.subscriptions, color: AppTheme.successColor),
            StatCard(title: 'CA total mois', value: '${data?.caMois ?? 0} ${AppCurrency.symbol}', icon: Icons.monetization_on, color: AppTheme.accentColor),
          ],
        ),
        const SizedBox(height: 16),
        _sectionCard(
          title: 'Actions rapides',
          child: Row(
            children: [
              _actionChip(context, Icons.local_pharmacy, 'Pharmacies', AppTheme.primaryColor, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PharmaciesListScreen()))),
              const SizedBox(width: 8),
              _actionChip(context, Icons.badge, 'Employés', AppTheme.primaryColor, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployesListScreen()))),
              const SizedBox(width: 8),
              _actionChip(context, Icons.subscriptions, 'Abonnements', AppTheme.primaryColor, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AbonnementsListScreen()))),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          title: 'Événements récents',
          child: _evenements.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('Aucun événement', style: TextStyle(color: Colors.grey.shade500)),
                )
              : Column(
                  children: _evenements.take(6).map((e) {
                    final tone = e['tone'] ?? 'info';
                    Color c;
                    switch (tone) {
                      case 'success': c = AppTheme.successColor; break;
                      case 'warning': c = AppTheme.warningColor; break;
                      case 'danger': c = AppTheme.errorColor; break;
                      default: c = AppTheme.accentColor;
                    }
                    return ListTile(
                      dense: true,
                      leading: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: Icon(
                          tone == 'success' ? Icons.check_circle : tone == 'warning' ? Icons.warning : tone == 'danger' ? Icons.error : Icons.info,
                          color: c, size: 18,
                        ),
                      ),
                      title: Text(e['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                      subtitle: Text(e['text'] ?? '', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  double _calcMaxY(List<double> caParJour) {
    if (caParJour.isEmpty) return 350000;
    double max = 0;
    for (final v in caParJour) {
      if (v > max) max = v;
    }
    return max * 1.3;
  }

  List<FlSpot> _buildChartSpots(List<double>? caParJour) {
    if (caParJour == null || caParJour.isEmpty) {
      return const [
        FlSpot(0, 120000), FlSpot(1, 180000), FlSpot(2, 150000),
        FlSpot(3, 240000), FlSpot(4, 210000), FlSpot(5, 290000), FlSpot(6, 310000),
      ];
    }
    return List.generate(caParJour.length, (i) => FlSpot(i.toDouble(), caParJour[i]));
  }

  Widget _actionChip(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _alertRow(IconData icon, String title, String subtitle, Color color) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
    );
  }
}
