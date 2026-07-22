import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/currency_helper.dart';
import '../../providers/vente_provider.dart';
import '../../widgets/loading_widget.dart';
import 'nouvelle_vente_screen.dart';
import 'vente_detail_screen.dart';

class VentesListScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  const VentesListScreen({super.key, this.onMenuTap});

  @override
  State<VentesListScreen> createState() => _VentesListScreenState();
}

class _VentesListScreenState extends State<VentesListScreen> {
  DateTime? _dateDebut;
  DateTime? _dateFin;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VenteProvider>().loadVentes();
    });
  }

  Future<void> _filtrerDates() async {
    final range = await showDateRangePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (range != null) {
      setState(() {
        _dateDebut = range.start;
        _dateFin = range.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VenteProvider>();
    final ventes = provider.ventes.where((v) {
      if (_dateDebut == null || _dateFin == null) return true;
      final dateVente = DateTime.tryParse(v.dateVente);
      if (dateVente == null) return true;
      return dateVente.isAfter(_dateDebut!.subtract(const Duration(days: 1))) && dateVente.isBefore(_dateFin!.add(const Duration(days: 1)));
    }).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: widget.onMenuTap),
        title: const Text('Historique des ventes'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                OutlinedButton.icon(
                  icon: Icon(Icons.date_range, size: 18),
                  label: Text(_dateDebut != null
                      ? '${_dateDebut!.day}/${_dateDebut!.month}/${_dateDebut!.year} - ${_dateFin!.day}/${_dateFin!.month}/${_dateFin!.year}'
                      : 'Filtrer par date'),
                  onPressed: _filtrerDates,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _dateDebut != null ? AppTheme.primaryColor : Colors.grey.shade600,
                    side: BorderSide(color: _dateDebut != null ? AppTheme.primaryColor : Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                if (_dateDebut != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => setState(() { _dateDebut = null; _dateFin = null; }),
                    style: IconButton.styleFrom(foregroundColor: AppTheme.errorColor),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? const LoadingWidget()
                : ventes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(_dateDebut != null ? 'Aucune vente sur cette période' : 'Aucune vente', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                            const SizedBox(height: 8),
                            Text('Appuyez sur + pour créer une vente', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => provider.loadVentes(),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: ventes.length,
                          itemBuilder: (context, index) {
                      final vente = ventes[index];
                      final isFinalisee = vente.statut == 'finalisee' || vente.statut == 'terminee';
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VenteDetailScreen(vente: vente))),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isFinalisee ? AppTheme.successColor.withValues(alpha: 0.1) : AppTheme.warningColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.receipt, color: isFinalisee ? AppTheme.successColor : AppTheme.warningColor, size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Vente #${vente.numero}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.textPrimary)),
                                      const SizedBox(height: 4),
                                      Text('${vente.montantNet} ${AppCurrency.symbol}', style: TextStyle(fontSize: 13, color: AppTheme.primaryColor, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isFinalisee ? AppTheme.successColor.withValues(alpha: 0.1) : AppTheme.warningColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(vente.statut, style: TextStyle(fontSize: 11, color: isFinalisee ? AppTheme.successColor : AppTheme.warningColor, fontWeight: FontWeight.w500)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                ),
              ),
            ),
          ],
        ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NouvelleVenteScreen())),
      ),
    );
  }
}


