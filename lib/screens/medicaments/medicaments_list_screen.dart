import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/medicament_provider.dart';
import '../../widgets/loading_widget.dart';
import 'medicament_form_screen.dart';
import 'categories_screen.dart';

class MedicamentsListScreen extends StatefulWidget {
  const MedicamentsListScreen({super.key});

  @override
  State<MedicamentsListScreen> createState() => _MedicamentsListScreenState();
}

class _MedicamentsListScreenState extends State<MedicamentsListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedicamentProvider>().loadMedicaments();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MedicamentProvider>();
    final filtered = provider.medicaments.where((m) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return m.nom.toLowerCase().contains(q) ||
          (m.codeBarre?.toLowerCase().contains(q) ?? false) ||
          (m.categorieNom?.toLowerCase().contains(q) ?? false);
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          if (provider.error != null)
            MaterialBanner(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              content: Text(provider.error!, style: const TextStyle(fontSize: 13)),
              backgroundColor: AppTheme.errorColor.withValues(alpha: 0.1),
              leading: const Icon(Icons.error_outline, color: AppTheme.errorColor),
              actions: [
                TextButton(onPressed: () { context.read<MedicamentProvider>().loadMedicaments(); }, child: const Text('Réessayer')),
              ],
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Rechercher par nom, catégorie ou code-barres...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); setState(() => _query = ''); }) : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade50,
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? const LoadingWidget()
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.medication_outlined, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(_query.isNotEmpty ? 'Aucun résultat' : 'Aucun médicament', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                            if (provider.error != null) ...[
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.refresh, size: 18),
                                label: const Text('Réessayer'),
                                onPressed: () => context.read<MedicamentProvider>().loadMedicaments(),
                              ),
                            ],
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => provider.loadMedicaments(),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                      final med = filtered[index];
                      Color statusColor = AppTheme.successColor;
                      String statusLabel = '';
                      if (med.isExpired) { statusColor = AppTheme.errorColor; statusLabel = 'Expiré'; }
                      else if (med.isLowStock) { statusColor = AppTheme.warningColor; statusLabel = 'Stock faible'; }
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showDetail(context, med),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: statusLabel.isEmpty ? AppTheme.primaryColor.withValues(alpha: 0.1) : statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.medication, color: statusLabel.isEmpty ? AppTheme.primaryColor : statusColor, size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(med.nom, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.textPrimary)),
                                      const SizedBox(height: 4),
                                      Text('${med.prixVente} CFA  •  Stock: ${med.stockQuantite?.toStringAsFixed(0) ?? "N/A"} ${med.unite}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                                    ],
                                  ),
                                ),
                                if (statusLabel.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(statusLabel, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w500)),
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
          floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'categories',
            child: const Icon(Icons.category),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesScreen())),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'add_med',
            child: const Icon(Icons.add),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicamentFormScreen())),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, med) {
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
            Text(med.nom, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            _detailRow('Catégorie', med.categorieNom ?? 'N/A'),
            const Divider(height: 1),
            _detailRow('Prix vente', '${med.prixVente} CFA'),
            const Divider(height: 1),
            _detailRow('Prix achat', med.prixAchat != null ? '${med.prixAchat} CFA' : 'N/A'),
            const Divider(height: 1),
            _detailRow('Stock', '${med.stockQuantite?.toStringAsFixed(0) ?? "N/A"} ${med.unite}'),
            const Divider(height: 1),
            _detailRow('Code barre', med.codeBarre ?? 'N/A'),
            const Divider(height: 1),
            _detailRow('Expiration', med.dateExpiration != null ? '${med.dateExpiration!.day}/${med.dateExpiration!.month}/${med.dateExpiration!.year}' : 'N/A'),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(icon: const Icon(Icons.edit_outlined), label: const Text('Modifier'), onPressed: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => MedicamentFormScreen(medicament: med))); }),
                const SizedBox(width: 8),
                TextButton.icon(icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor), label: const Text('Supprimer', style: TextStyle(color: AppTheme.errorColor)), onPressed: () { Navigator.pop(ctx); _confirmDelete(med.id); }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(color: Colors.grey.shade600)), Text(value, style: const TextStyle(fontWeight: FontWeight.w500))]),
    );
  }

  void _confirmDelete(int id) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Confirmer'),
      content: const Text('Supprimer ce médicament ?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
        TextButton(onPressed: () { Navigator.pop(ctx); context.read<MedicamentProvider>().deleteMedicament(id); }, child: const Text('Supprimer', style: TextStyle(color: AppTheme.errorColor))),
      ],
    ));
  }
}
