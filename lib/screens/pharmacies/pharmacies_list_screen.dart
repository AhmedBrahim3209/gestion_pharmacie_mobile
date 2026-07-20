import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/pharmacie_provider.dart';
import '../../widgets/loading_widget.dart';

class PharmaciesListScreen extends StatefulWidget {
  const PharmaciesListScreen({super.key});

  @override
  State<PharmaciesListScreen> createState() => _PharmaciesListScreenState();
}

class _PharmaciesListScreenState extends State<PharmaciesListScreen> {
  final _nomCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _licenceCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PharmacieProvider>().loadPharmacies();
    });
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _adresseCtrl.dispose();
    _telCtrl.dispose();
    _emailCtrl.dispose();
    _licenceCtrl.dispose();
    super.dispose();
  }

  void _ajouter() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Nouvelle pharmacie'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _nomCtrl, decoration: InputDecoration(labelText: 'Nom *', border: OutlineInputBorder(), filled: true, fillColor: Colors.grey.shade50)),
              const SizedBox(height: 8),
              TextField(controller: _adresseCtrl, decoration: InputDecoration(labelText: 'Adresse', border: OutlineInputBorder(), filled: true, fillColor: Colors.grey.shade50)),
              const SizedBox(height: 8),
              TextField(controller: _telCtrl, decoration: InputDecoration(labelText: 'Téléphone', border: OutlineInputBorder(), filled: true, fillColor: Colors.grey.shade50)),
              const SizedBox(height: 8),
              TextField(controller: _emailCtrl, decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder(), filled: true, fillColor: Colors.grey.shade50)),
              const SizedBox(height: 8),
              TextField(controller: _licenceCtrl, decoration: InputDecoration(labelText: 'Numéro licence', border: OutlineInputBorder(), filled: true, fillColor: Colors.grey.shade50)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (_nomCtrl.text.isEmpty) return;
              context.read<PharmacieProvider>().createPharmacie({
                'nom': _nomCtrl.text.trim(),
                'adresse': _adresseCtrl.text.trim(),
                'telephone': _telCtrl.text.trim(),
                'email': _emailCtrl.text.trim(),
                'numero_licence': _licenceCtrl.text.trim(),
              });
              _nomCtrl.clear();
              _adresseCtrl.clear();
              _telCtrl.clear();
              _emailCtrl.clear();
              _licenceCtrl.clear();
              Navigator.pop(ctx);
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PharmacieProvider>();

    return Scaffold(
      body: provider.isLoading
          ? const LoadingWidget()
          : provider.pharmacies.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_pharmacy_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('Aucune pharmacie', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => provider.loadPharmacies(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: provider.pharmacies.length,
                    itemBuilder: (context, index) {
                      final p = provider.pharmacies[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            final newStatus = !p.estActive;
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: const Text('Confirmer'),
                                content: Text('${newStatus ? "Activer" : "Désactiver"} ${p.nom} ?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      provider.toggleActif(p.id);
                                    },
                                    child: Text(newStatus ? 'Activer' : 'Désactiver'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: p.estActive ? AppTheme.successColor.withValues(alpha: 0.1) : AppTheme.errorColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(p.estActive ? Icons.local_pharmacy : Icons.local_pharmacy_outlined, color: p.estActive ? AppTheme.successColor : AppTheme.errorColor, size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p.nom, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.textPrimary)),
                                      const SizedBox(height: 4),
                                      Text('${p.adresse ?? "N/A"}  •  ${p.telephone ?? "N/A"}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: p.estActive ? AppTheme.successColor.withValues(alpha: 0.1) : AppTheme.errorColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(p.estActive ? 'Active' : 'Inactive', style: TextStyle(fontSize: 11, color: p.estActive ? AppTheme.successColor : AppTheme.errorColor, fontWeight: FontWeight.w500)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: _ajouter,
      ),
    );
  }
}
