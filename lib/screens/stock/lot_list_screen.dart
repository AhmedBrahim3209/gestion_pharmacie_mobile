import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../providers/lot_provider.dart';
import '../../models/lot.dart';
import '../../widgets/loading_widget.dart';
import 'add_edit_lot_screen.dart';
import 'lot_detail_screen.dart';

class LotListScreen extends StatefulWidget {
  const LotListScreen({super.key});

  @override
  State<LotListScreen> createState() => _LotListScreenState();
}

class _LotListScreenState extends State<LotListScreen> {
  String _filtre = 'tous';
  String _recherche = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LotProvider>().loadLots();
      context.read<LotProvider>().loadLotsExpirant();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LotProvider>();
    final lots = provider.lots;

    final filtres = {
      'tous': 'Tous',
      'actifs': 'Actifs',
      'expires': 'Expirés',
      'bientot': 'Expire bientôt',
      'faible': 'Stock faible',
    };

    final filtered = lots.where((l) {
      if (_recherche.isNotEmpty) {
        final q = _recherche.toLowerCase();
        if (!l.numeroLot.toLowerCase().contains(q) && !l.medicamentNom.toLowerCase().contains(q)) {
          return false;
        }
      }
      switch (_filtre) {
        case 'actifs': return l.estActif && l.quantite > 0 && !l.estExpire;
        case 'expires': return l.estExpire;
        case 'bientot': return !l.estExpire && l.expireBientot;
        case 'faible': return l.quantite > 0 && l.quantite <= (l.quantiteInitiale * 0.2);
        default: return true;
      }
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Lots'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.warning_amber_rounded, size: 18),
            label: Text('${provider.lotsExpires.length + provider.lotsBientotExpires.length}'),
            onPressed: () => _showAlertes(context, provider),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => provider.loadLots()),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Rechercher lot ou médicament...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _recherche.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); setState(() => _recherche = ''); }) : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true, fillColor: Colors.grey.shade50, isDense: true,
              ),
              onChanged: (v) => setState(() => _recherche = v),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: filtres.entries.map((e) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(e.value, style: const TextStyle(fontSize: 12)),
                  selected: _filtre == e.key,
                  onSelected: (_) => setState(() => _filtre = e.key),
                  selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                ),
              )).toList(),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: provider.isLoading && lots.isEmpty
                ? const LoadingWidget()
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text('Aucun lot trouvé', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => provider.loadLots(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) => _LotCard(lot: filtered[index]),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Nouveau lot'),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditLotScreen())).then((_) => provider.loadLots()),
      ),
    );
  }

  void _showAlertes(BuildContext context, LotProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.orange), SizedBox(width: 8), Text('Alertes Lots')]),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              if (provider.lotsExpires.isNotEmpty) ...[
                Text('${provider.lotsExpires.length} expiré(s)', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.errorColor)),
                ...provider.lotsExpires.take(5).map((l) => ListTile(
                  dense: true, leading: const Icon(Icons.error, color: AppTheme.errorColor, size: 20),
                  title: Text(l.numeroLot, style: const TextStyle(fontSize: 13)),
                  subtitle: Text('${l.medicamentNom} - ${DateFormat('dd/MM/yyyy').format(l.dateExpiration)}', style: const TextStyle(fontSize: 11)),
                )),
                const Divider(),
              ],
              if (provider.lotsBientotExpires.isNotEmpty) ...[
                Text('${provider.lotsBientotExpires.length} expire(nt) bientôt', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.warningColor)),
                ...provider.lotsBientotExpires.map((l) => ListTile(
                  dense: true, leading: Icon(Icons.schedule, color: AppTheme.warningColor, size: 20),
                  title: Text(l.numeroLot, style: const TextStyle(fontSize: 13)),
                  subtitle: Text('${l.medicamentNom} - J-${l.joursRestants}', style: const TextStyle(fontSize: 11)),
                )),
              ],
              if (provider.lotsExpires.isEmpty && provider.lotsBientotExpires.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('Aucune alerte', style: TextStyle(color: AppTheme.successColor, fontWeight: FontWeight.bold))),
                ),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer'))],
      ),
    );
  }
}

class _LotCard extends StatelessWidget {
  final Lot lot;
  const _LotCard({required this.lot});

  @override
  Widget build(BuildContext context) {
    final isExpired = lot.estExpire;
    final isExpiring = !isExpired && lot.expireBientot;
    final isLow = lot.quantite > 0 && lot.quantite <= (lot.quantiteInitiale * 0.2);

    Color accentColor = AppTheme.primaryColor;
    if (isExpired) accentColor = AppTheme.errorColor;
    else if (isExpiring) accentColor = AppTheme.warningColor;
    else if (isLow) accentColor = Colors.orange;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: accentColor.withValues(alpha: 0.4), width: accentColor != AppTheme.primaryColor ? 1.5 : 0),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LotDetailScreen(lotId: lot.id))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(isExpired ? Icons.error_outline : isExpiring ? Icons.schedule : Icons.inventory_2, color: accentColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(lot.medicamentNom, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text('Lot: ${lot.numeroLot}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      isExpired ? 'Expiré' : isExpiring ? 'J-${lot.joursRestants}' : lot.quantite > 0 ? 'En stock' : 'Épuisé',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: accentColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _chip( Icons.calendar_today, 'Exp: ${DateFormat('dd/MM/yyyy').format(lot.dateExpiration)}'),
                  const SizedBox(width: 12),
                  _chip(Icons.login, 'Fab: ${DateFormat('dd/MM/yyyy').format(lot.dateFabrication)}'),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _statItem('Qté', lot.quantite.toStringAsFixed(0)),
                  const SizedBox(width: 20),
                  _statItem('Initiale', lot.quantiteInitiale.toStringAsFixed(0)),
                  const Spacer(),
                  Text('${lot.prixAchat.toStringAsFixed(0)} CFA', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                ],
              ),
              if (lot.quantite > 0) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: lot.quantite / lot.quantiteInitiale,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(isLow ? AppTheme.warningColor : AppTheme.successColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
