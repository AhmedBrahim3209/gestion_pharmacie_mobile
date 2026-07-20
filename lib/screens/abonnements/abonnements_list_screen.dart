import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/abonnement_provider.dart';
import '../../providers/pharmacie_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/loading_widget.dart';

class AbonnementsListScreen extends StatefulWidget {
  const AbonnementsListScreen({super.key});

  @override
  State<AbonnementsListScreen> createState() => _AbonnementsListScreenState();
}

class _AbonnementsListScreenState extends State<AbonnementsListScreen> {
  final _planCtrl = TextEditingController();
  final _montantCtrl = TextEditingController();
  int? _pharmacieId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AbonnementProvider>().loadAbonnements();
      context.read<PharmacieProvider>().loadPharmacies();
    });
  }

  @override
  void dispose() {
    _planCtrl.dispose();
    _montantCtrl.dispose();
    super.dispose();
  }

  Color _statutColor(String statut) {
    switch (statut) {
      case 'actif': return AppTheme.successColor;
      case 'expire': return AppTheme.errorColor;
      case 'suspendu': return AppTheme.warningColor;
      default: return Colors.grey;
    }
  }

  String _statutLabel(String statut) {
    switch (statut) {
      case 'actif': return 'Actif';
      case 'expire': return 'Expiré';
      case 'suspendu': return 'Suspendu';
      default: return statut;
    }
  }

  void _ajouter() {
    final pharmacieProvider = context.read<PharmacieProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Nouvel abonnement'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: _pharmacieId,
                decoration: const InputDecoration(labelText: 'Pharmacie *', border: OutlineInputBorder()),
                items: pharmacieProvider.pharmacies.map((p) => DropdownMenuItem(value: p.id, child: Text(p.nom))).toList(),
                onChanged: (v) => setState(() => _pharmacieId = v),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _planCtrl.text.isNotEmpty ? _planCtrl.text : null,
                decoration: const InputDecoration(labelText: 'Plan *', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'mensuel', child: Text('Mensuel')),
                  DropdownMenuItem(value: 'trimestriel', child: Text('Trimestriel')),
                  DropdownMenuItem(value: 'annuel', child: Text('Annuel')),
                ],
                onChanged: (v) => _planCtrl.text = v ?? '',
              ),
              const SizedBox(height: 8),
              TextField(controller: _montantCtrl, decoration: InputDecoration(labelText: 'Montant', border: OutlineInputBorder(), filled: true, fillColor: Colors.grey.shade50), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (_pharmacieId == null || _planCtrl.text.isEmpty) return;
              context.read<AbonnementProvider>().createAbonnement({
                'pharmacie': _pharmacieId,
                'plan': _planCtrl.text,
                'montant': double.tryParse(_montantCtrl.text),
              });
              _pharmacieId = null;
              _planCtrl.clear();
              _montantCtrl.clear();
              Navigator.pop(ctx);
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, dynamic a) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(a.pharmacieNom ?? 'Abonnement #${a.id}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            _row('Plan', a.plan),
            const Divider(height: 1),
            _row('Montant', a.montant != null ? '${a.montant} CFA' : 'N/A'),
            const Divider(height: 1),
            _row('Date début', a.dateDebut ?? 'N/A'),
            const Divider(height: 1),
            _row('Date fin', a.dateFin ?? 'N/A'),
            const Divider(height: 1),
            _row('Statut', _statutLabel(a.statut)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (a.statut == 'actif')
                  TextButton.icon(
                    icon: const Icon(Icons.pause_circle, color: AppTheme.warningColor),
                    label: const Text('Suspendre', style: TextStyle(color: AppTheme.warningColor)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.read<AbonnementProvider>().suspendreAbonnement(a.id);
                    },
                  )
                else
                  TextButton.icon(
                    icon: const Icon(Icons.play_circle, color: AppTheme.successColor),
                    label: const Text('Activer', style: TextStyle(color: AppTheme.successColor)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.read<AbonnementProvider>().activerAbonnement(a.id);
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(color: Colors.grey.shade600)), Text(value, style: const TextStyle(fontWeight: FontWeight.w500))]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AbonnementProvider>();
    final auth = context.watch<AuthProvider>();

    final abonnements = provider.abonnements.where((a) {
      if (auth.user?.isSuperAdmin == true) return true;
      return a.pharmacieId == auth.user?.pharmacieId;
    }).toList();

    return Scaffold(
      body: provider.isLoading
          ? const LoadingWidget()
          : abonnements.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.subscriptions_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('Aucun abonnement', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => provider.loadAbonnements(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: abonnements.length,
                    itemBuilder: (context, index) {
                      final a = abonnements[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showDetail(context, a),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _statutColor(a.statut).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.subscriptions, color: _statutColor(a.statut), size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(a.pharmacieNom ?? 'Pharmacie #${a.pharmacieId}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.textPrimary)),
                                      const SizedBox(height: 4),
                                      Text('${a.plan}  •  ${a.dateDebut ?? ""} - ${a.dateFin ?? ""}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statutColor(a.statut).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(_statutLabel(a.statut), style: TextStyle(fontSize: 11, color: _statutColor(a.statut), fontWeight: FontWeight.w500)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: auth.user?.isSuperAdmin == true
          ? FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: _ajouter,
            )
          : null,
    );
  }
}
