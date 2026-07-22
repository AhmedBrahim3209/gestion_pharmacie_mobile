import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../config/currency_helper.dart';
import '../../providers/lot_provider.dart';
import '../../models/lot.dart';
import '../../widgets/loading_widget.dart';
import 'add_edit_lot_screen.dart';

class LotDetailScreen extends StatefulWidget {
  final int lotId;
  const LotDetailScreen({super.key, required this.lotId});

  @override
  State<LotDetailScreen> createState() => _LotDetailScreenState();
}

class _LotDetailScreenState extends State<LotDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LotProvider>().loadLotDetail(widget.lotId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LotProvider>();
    final lot = provider.lotSelectionne;

    return Scaffold(
      appBar: AppBar(
        title: Text(lot?.numeroLot ?? 'Détail lot'),
        actions: [
          if (lot != null) ...[
            IconButton(icon: const Icon(Icons.edit), onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditLotScreen(lot: lot)));
            }),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'ajuster_entree') _showAjustementDialog('entree');
                if (v == 'ajuster_sortie') _showAjustementDialog('sortie');
                if (v == 'desactiver') _toggleActif(false);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'ajuster_entree', child: ListTile(leading: Icon(Icons.add, color: Colors.green), title: Text('Entrée stock'))),
                const PopupMenuItem(value: 'ajuster_sortie', child: ListTile(leading: Icon(Icons.remove, color: Colors.red), title: Text('Sortie stock'))),
                if (lot.estActif)
                  const PopupMenuItem(value: 'desactiver', child: ListTile(leading: Icon(Icons.block, color: Colors.orange), title: Text('Désactiver'))),
              ],
            ),
          ],
        ],
      ),
      body: provider.isLoading
          ? const LoadingWidget()
          : lot == null
              ? const Center(child: Text('Lot introuvable'))
              : RefreshIndicator(
                  onRefresh: () => provider.loadLotDetail(widget.lotId),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _headerCard(lot),
                      const SizedBox(height: 16),
                      _infoGrid(lot),
                      const SizedBox(height: 20),
                      _sectionHeader('Mouvements du lot (${provider.mouvements.length})'),
                      if (provider.mouvements.isEmpty)
                        Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(child: Text('Aucun mouvement', style: TextStyle(color: Colors.grey.shade500))),
                          ),
                        )
                      else
                        ...provider.mouvements.map((m) => Card(
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          child: ListTile(
                            dense: true,
                            leading: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: m.typeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                              child: Icon(m.typeMouvement == 'entree' || m.typeMouvement == 'retour' ? Icons.arrow_downward : Icons.arrow_upward, color: m.typeColor, size: 18),
                            ),
                            title: Text(m.typeLibelle, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                            subtitle: Text('${DateFormat('dd/MM/yyyy HH:mm').format(m.date)}${m.utilisateurNom != null ? ' par ${m.utilisateurNom}' : ''}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${m.quantite.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: m.typeColor, fontSize: 15)),
                                Text('${m.quantiteApres.toStringAsFixed(0)} restant', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                              ],
                            ),
                          ),
                        )),
                    ],
                  ),
                ),
    );
  }

  Widget _headerCard(Lot lot) {
    final isExpired = lot.estExpire;
    final isExpiring = lot.expireBientot;
    Color accent = AppTheme.primaryColor;
    if (isExpired) accent = AppTheme.errorColor;
    else if (isExpiring) accent = AppTheme.warningColor;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [accent.withValues(alpha: 0.08), Colors.white]),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                  child: Icon(Icons.inventory_2, color: accent, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lot.medicamentNom, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Lot: ${lot.numeroLot}', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _bigStat('Stock', '${lot.quantite.toStringAsFixed(0)}', accent),
                _bigStat('Initial', '${lot.quantiteInitiale.toStringAsFixed(0)}', Colors.grey.shade600),
                _bigStat('Consommé', '${lot.tauxConsommation.toStringAsFixed(1)}%', lot.tauxConsommation > 80 ? AppTheme.warningColor : AppTheme.successColor),
              ],
            ),
            if (lot.quantite > 0) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: lot.quantite / lot.quantiteInitiale,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(lot.quantite / lot.quantiteInitiale < 0.2 ? AppTheme.warningColor : AppTheme.successColor),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _bigStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _infoGrid(Lot lot) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _infoRow(Icons.calendar_today, 'Fabrication', DateFormat('dd/MM/yyyy').format(lot.dateFabrication)),
            const Divider(height: 1),
            _infoRow(Icons.calendar_month, 'Expiration', DateFormat('dd/MM/yyyy').format(lot.dateExpiration)),
            const Divider(height: 1),
            _infoRow(Icons.hourglass_bottom, 'Jours restants', '${lot.joursRestants} jours', color: lot.estExpire ? AppTheme.errorColor : lot.expireBientot ? AppTheme.warningColor : AppTheme.successColor),
            const Divider(height: 1),
            if (lot.fournisseurNom != null) ...[
              _infoRow(Icons.business, 'Fournisseur', lot.fournisseurNom!),
              const Divider(height: 1),
            ],
            _infoRow(Icons.monetization_on, 'Prix achat', '${lot.prixAchat.toStringAsFixed(0)} ${AppCurrency.symbol}'),
            const Divider(height: 1),
            _infoRow(Icons.monetization_on, 'Prix vente', '${lot.prixVente.toStringAsFixed(0)} ${AppCurrency.symbol}'),
            const Divider(height: 1),
            _infoRow(Icons.circle, 'Statut', lot.statut, color: lot.statutColor),
            const Divider(height: 1),
            _infoRow(Icons.date_range, 'Créé le', DateFormat('dd/MM/yyyy').format(lot.dateCreation)),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          const Spacer(),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: color ?? AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          Expanded(child: Divider(color: Colors.grey.shade200)),
        ],
      ),
    );
  }

  void _showAjustementDialog(String type) {
    final qteCtrl = TextEditingController();
    final motifCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(type == 'entree' ? 'Entrée stock' : 'Sortie stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qteCtrl,
              decoration: const InputDecoration(labelText: 'Quantité', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: motifCtrl,
              decoration: const InputDecoration(labelText: 'Motif (optionnel)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(onPressed: () async {
            final qte = double.tryParse(qteCtrl.text);
            if (qte == null || qte <= 0) return;
            final provider = context.read<LotProvider>();
            final success = await provider.ajustementLot(widget.lotId,
              typeMouvement: type, quantite: qte, motif: motifCtrl.text.trim().isNotEmpty ? motifCtrl.text.trim() : null,
            );
            if (ctx.mounted) Navigator.pop(ctx);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(success ? 'Ajustement effectué' : provider.error ?? 'Erreur'),
                backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
              ));
            }
          }, child: const Text('Valider')),
        ],
      ),
    );
  }

  Future<void> _toggleActif(bool actif) async {
    final provider = context.read<LotProvider>();
    final success = await provider.updateLot(widget.lotId, {'est_actif': actif});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? 'Lot désactivé' : provider.error ?? 'Erreur'),
        backgroundColor: success ? AppTheme.successColor : AppTheme.errorColor,
      ));
    }
  }
}