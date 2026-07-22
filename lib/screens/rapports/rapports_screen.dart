import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../../config/app_theme.dart';
import '../../config/currency_helper.dart';
import '../../providers/rapport_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/stat_card.dart';

class RapportsScreen extends StatefulWidget {
  const RapportsScreen({super.key});

  @override
  State<RapportsScreen> createState() => _RapportsScreenState();
}

class _RapportsScreenState extends State<RapportsScreen> {
  String _period = 'today';
  DateTime? _dateDebut;
  DateTime? _dateFin;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RapportProvider>().loadVentesRapport();
      context.read<DashboardProvider>().loadDashboard();
    });
  }

  void _charger() {
    final r = context.read<RapportProvider>();
    if (_dateDebut != null && _dateFin != null) {
      r.loadVentesRapport(
        dateDebut: _dateDebut!.toIso8601String().split('T').first,
        dateFin: _dateFin!.toIso8601String().split('T').first,
      );
    } else {
      r.loadVentesRapport();
    }
  }

  Future<void> _pickerDaterange() async {
    final range = await showDateRangePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (range != null) {
      setState(() {
        _dateDebut = range.start;
        _dateFin = range.end;
        _period = 'custom';
      });
      _charger();
    }
  }

  @override
  Widget build(BuildContext context) {
    final rapport = context.watch<RapportProvider>();
    final dashboardProv = context.watch<DashboardProvider>();
    final dashboard = dashboardProv.data;

    final data = rapport.ventesData;
    final totalVentes = data?['total_ventes'] ?? 0;
    final caTotal = (data?['ca_total'] as num?)?.toDouble() ?? 0;
    final nbTransactions = data?['nb_transactions'] ?? 0;
    final panierMoyen = (data?['panier_moyen'] as num?)?.toDouble() ?? 0;
    final bestSellers = (data?['meilleures_ventes'] as List<dynamic>?) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapports'),
        actions: [
          IconButton(icon: const Icon(Icons.file_download), tooltip: 'Exporter CSV', onPressed: _exporterCSV),
        ],
      ),
      body: rapport.isLoading
          ? const LoadingWidget()
          : RefreshIndicator(
              onRefresh: () async {
                await rapport.loadVentesRapport();
                await dashboardProv.loadDashboard();
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'today', label: Text('Aujourd\'hui')),
                              ButtonSegment(value: 'week', label: Text('Cette semaine')),
                              ButtonSegment(value: 'month', label: Text('Ce mois')),
                            ],
                            selected: {_period},
                            onSelectionChanged: (v) {
                              setState(() => _period = v.first);
                              if (_period != 'custom') {
                                _dateDebut = null;
                                _dateFin = null;
                                _charger();
                              }
                            },
                          ),
                          if (_period != 'custom')
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                icon: const Icon(Icons.date_range),
                                label: const Text('Choisir dates'),
                                onPressed: _pickerDaterange,
                              ),
                            ),
                          if (_period == 'custom') ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(_dateDebut != null ? '${_dateDebut!.day}/${_dateDebut!.month}/${_dateDebut!.year}' : 'Début', style: TextStyle(color: Colors.grey.shade600)),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text('-', style: TextStyle(color: Colors.grey.shade600)),
                                ),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(_dateFin != null ? '${_dateFin!.day}/${_dateFin!.month}/${_dateFin!.year}' : 'Fin', style: TextStyle(color: Colors.grey.shade600)),
                                  ),
                                ),
                                IconButton(icon: const Icon(Icons.edit_calendar), onPressed: _pickerDaterange),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: [
                      StatCard(title: 'Total ventes', value: '$totalVentes', icon: Icons.receipt, color: AppTheme.accentColor),
                      StatCard(title: 'CA total', value: '$caTotal ${AppCurrency.symbol}', icon: Icons.attach_money, color: AppTheme.successColor),
                      StatCard(title: 'Transactions', value: '$nbTransactions', icon: Icons.swap_horiz, color: AppTheme.warningColor),
                      StatCard(title: 'Panier moyen', value: '${panierMoyen.toStringAsFixed(0)} ${AppCurrency.symbol}', icon: Icons.shopping_cart, color: Colors.purple),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _sectionDivider('Meilleures ventes'),
                  if (bestSellers.isEmpty)
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(child: Text('Aucune donnée disponible', style: TextStyle(color: Colors.grey.shade500))),
                      ),
                    )
                  else
                    ...bestSellers.take(5).map((item) => Card(
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                              child: Center(child: Text('${item['total'] ?? 0}', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(item['medicament__nom'] ?? item['medicament_nom'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w500))),
                            Text('${item['quantite_totale'] ?? item['quantite'] ?? 0} vendus', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          ],
                        ),
                      ),
                    )),
                  const SizedBox(height: 24),
                  _sectionDivider('Alertes stock'),
                  Card(
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _alerteRow('Stock faible', dashboard?.stockFaible ?? 0, AppTheme.warningColor),
                          const Divider(height: 1),
                          _alerteRow('Médicaments expirés', dashboard?.medicamentsExpires ?? 0, AppTheme.errorColor),
                          const Divider(height: 1),
                          _alerteRow('Expire bientôt', dashboard?.expiresBientot ?? 0, AppTheme.warningColor),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _exporterCSV() async {
    final rapport = context.read<RapportProvider>();
    final data = rapport.ventesData;
    if (data == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aucune donnée à exporter')));
      return;
    }
    final totalVentes = data['total_ventes'] ?? 0;
    final caTotal = (data['ca_total'] as num?)?.toDouble() ?? 0;
    final nbTransactions = data['nb_transactions'] ?? 0;
    final panierMoyen = (data['panier_moyen'] as num?)?.toDouble() ?? 0;
    final bestSellers = (data['meilleures_ventes'] as List<dynamic>?) ?? [];

    final periodLabel = _period == 'custom' && _dateDebut != null && _dateFin != null
        ? 'Du ${DateFormat('dd/MM/yyyy').format(_dateDebut!)} au ${DateFormat('dd/MM/yyyy').format(_dateFin!)}'
        : _period;
    final buf = StringBuffer();
    buf.writeln('Rapport de ventes - $periodLabel');
    buf.writeln('');
    buf.writeln('Indicateur,Valeur');
    buf.writeln('Total ventes,$totalVentes');
    buf.writeln('CA total,$caTotal ${AppCurrency.symbol}');
    buf.writeln('Transactions,$nbTransactions');
    buf.writeln('Panier moyen,${panierMoyen.toStringAsFixed(0)} ${AppCurrency.symbol}');
    buf.writeln('');
    buf.writeln('Meilleures ventes');
    buf.writeln('Médicament,Quantité vendue');
    for (final item in bestSellers) {
      final nom = item['medicament__nom'] ?? item['medicament_nom'] ?? 'N/A';
      final qte = item['quantite_totale'] ?? item['quantite'] ?? 0;
      buf.writeln('$nom,$qte');
    }
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'rapport_ventes_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(buf.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exporté: $fileName')));
        await OpenFile.open(file.path);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur export: $e'), backgroundColor: AppTheme.errorColor));
    }
  }

  Widget _sectionDivider(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const SizedBox(width: 12),
          Expanded(child: Divider(color: Colors.grey.shade200)),
        ],
      ),
    );
  }

  Widget _alerteRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
