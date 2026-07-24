import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/currency_helper.dart';
import '../../models/employe.dart';
import '../../providers/auth_provider.dart';
import '../../providers/employe_provider.dart';
import '../../widgets/loading_widget.dart';

class EmployesListScreen extends StatefulWidget {
  const EmployesListScreen({super.key});

  @override
  State<EmployesListScreen> createState() => _EmployesListScreenState();
}

class _EmployesListScreenState extends State<EmployesListScreen> {
  final _nomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telephoneCtrl = TextEditingController();
  final _posteCtrl = TextEditingController();
  final _salaireCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  String _role = 'employe';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployeProvider>().loadEmployes();
    });
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _emailCtrl.dispose();
    _telephoneCtrl.dispose();
    _posteCtrl.dispose();
    _salaireCtrl.dispose();
    _numeroCtrl.dispose();
    super.dispose();
  }

  void _ajouter() {
    _nomCtrl.clear();
    _emailCtrl.clear();
    _telephoneCtrl.clear();
    _posteCtrl.clear();
    _salaireCtrl.clear();
    _numeroCtrl.clear();
    _role = 'employe';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Nouvel employé'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: _nomCtrl, decoration: InputDecoration(labelText: 'Nom complet *', border: OutlineInputBorder(), filled: true, fillColor: Colors.grey.shade100)),
                const SizedBox(height: 8),
                TextField(controller: _emailCtrl, decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder(), filled: true, fillColor: Colors.grey.shade100)),
                const SizedBox(height: 8),
                TextField(controller: _telephoneCtrl, decoration: InputDecoration(labelText: 'Téléphone (8 chiffres)', border: OutlineInputBorder(), filled: true, fillColor: Colors.grey.shade100, hintText: '45123456'), keyboardType: TextInputType.phone, onChanged: (v) {
                  if (v.replaceAll(RegExp(r'\D'), '').length > 8) _telephoneCtrl.text = v.substring(0, 8);
                }),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _role,
                  decoration: InputDecoration(labelText: 'Rôle', border: OutlineInputBorder(), filled: true, fillColor: Colors.grey.shade100),
                  items: const [
                    DropdownMenuItem(value: 'caissier', child: Text('Caissier')),
                    DropdownMenuItem(value: 'employe', child: Text('Employé')),
                  ],
                  onChanged: (v) => setDialogState(() => _role = v ?? 'employe'),
                ),
                const SizedBox(height: 8),
                TextField(controller: _posteCtrl, decoration: InputDecoration(labelText: 'Poste', border: OutlineInputBorder(), filled: true, fillColor: Colors.grey.shade100)),
                const SizedBox(height: 8),
                TextField(controller: _salaireCtrl, decoration: InputDecoration(labelText: 'Salaire', border: OutlineInputBorder(), filled: true, fillColor: Colors.grey.shade50), keyboardType: TextInputType.number),
                const SizedBox(height: 8),
                TextField(controller: _numeroCtrl, decoration: InputDecoration(labelText: 'Numéro employé', border: OutlineInputBorder(), filled: true, fillColor: Colors.grey.shade50)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                if (_nomCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                    content: Text('Nom complet requis'),
                    backgroundColor: AppTheme.errorColor,
                  ));
                  return;
                }
                final data = <String, dynamic>{
                  'nom': _nomCtrl.text.trim(),
                  'email': _emailCtrl.text.trim(),
                  'telephone': _telephoneCtrl.text.trim(),
                  'role': _role,
                  'poste': _posteCtrl.text.trim(),
                  'salaire': double.tryParse(_salaireCtrl.text),
                  'numero_employe': _numeroCtrl.text.trim(),
                };
                final empProv = context.read<EmployeProvider>();
                final ok = await empProv.createEmploye(data);
                if (!ctx.mounted) return;
                if (ok) {
                  Navigator.pop(ctx);
                } else {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                    content: Text(empProv.error ?? 'Erreur lors de la création'),
                    backgroundColor: AppTheme.errorColor,
                  ));
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployeProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    List<Employe> filtered = provider.employes;
    if (user?.isSuperAdmin == true) {
      filtered = provider.employes.where((e) => e.role == 'admin_pharmacie').toList();
    } else if (user?.isAdminPharmacie == true) {
      filtered = provider.employes.where((e) => e.role == 'employe' || e.role == 'caissier').toList();
    }

    return Scaffold(
      body: provider.isLoading
          ? const LoadingWidget()
          : filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.badge_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('Aucun employé', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => provider.loadEmployes(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final e = filtered[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                                child: Text(e.utilisateurNom?.isNotEmpty == true ? e.utilisateurNom![0].toUpperCase() : '?', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(e.utilisateurNom ?? 'Employé #${e.id}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.textPrimary)),
                                    const SizedBox(height: 4),
                                    Text('${e.poste ?? "N/A"}  •  ${e.salaire != null ? "${e.salaire!.toStringAsFixed(0)} ${AppCurrency.symbol}" : "N/A"}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                                  ],
                                ),
                              ),
                              if (e.numeroEmploye != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(e.numeroEmploye!, style: TextStyle(fontSize: 11, color: AppTheme.primaryColor, fontWeight: FontWeight.w500)),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.person_add),
        onPressed: _ajouter,
      ),
    );
  }
}
