import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/utilisateur_provider.dart';
import '../../widgets/loading_widget.dart';

class UtilisateursListScreen extends StatefulWidget {
  const UtilisateursListScreen({super.key});

  @override
  State<UtilisateursListScreen> createState() => _UtilisateursListScreenState();
}

class _UtilisateursListScreenState extends State<UtilisateursListScreen> {
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _role = 'employe';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UtilisateurProvider>().loadUtilisateurs();
    });
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'super_admin': return AppTheme.errorColor;
      case 'admin_pharmacie': return AppTheme.warningColor;
      case 'caissier': return AppTheme.accentColor;
      default: return AppTheme.successColor;
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'super_admin': return 'Super Admin';
      case 'admin_pharmacie': return 'Admin Pharmacie';
      case 'caissier': return 'Caissier';
      default: return 'Employé';
    }
  }

  void _ajouter() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Nouvel utilisateur'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: _usernameCtrl, decoration: InputDecoration(labelText: 'Nom d\'utilisateur *', border: OutlineInputBorder(), filled: true, fillColor: Colors.grey.shade100)),
                const SizedBox(height: 8),
                TextField(controller: _emailCtrl, decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder(), filled: true, fillColor: Colors.grey.shade100)),
                const SizedBox(height: 8),
                TextField(controller: _passwordCtrl, decoration: InputDecoration(labelText: 'Mot de passe *', border: OutlineInputBorder(), filled: true, fillColor: Colors.grey.shade100), obscureText: true),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _role,
                  decoration: InputDecoration(labelText: 'Rôle *', border: OutlineInputBorder(), filled: true, fillColor: Colors.grey.shade100),
                  items: const [
                    DropdownMenuItem(value: 'super_admin', child: Text('Super Admin')),
                    DropdownMenuItem(value: 'admin_pharmacie', child: Text('Admin Pharmacie')),
                    DropdownMenuItem(value: 'caissier', child: Text('Caissier')),
                    DropdownMenuItem(value: 'employe', child: Text('Employé')),
                  ],
                  onChanged: (v) => setDialogState(() => _role = v ?? 'employe'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () {
                if (_usernameCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) return;
                context.read<UtilisateurProvider>().createUtilisateur({
                  'username': _usernameCtrl.text.trim(),
                  'email': _emailCtrl.text.trim(),
                  'password': _passwordCtrl.text,
                  'role': _role,
                });
                _usernameCtrl.clear();
                _emailCtrl.clear();
                _passwordCtrl.clear();
                _role = 'employe';
                Navigator.pop(ctx);
              },
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UtilisateurProvider>();

    return Scaffold(
      body: provider.isLoading
          ? const LoadingWidget()
          : provider.utilisateurs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('Aucun utilisateur', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => provider.loadUtilisateurs(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: provider.utilisateurs.length,
                    itemBuilder: (context, index) {
                      final u = provider.utilisateurs[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: _roleColor(u.role).withValues(alpha: 0.1),
                                child: Text(u.username[0].toUpperCase(), style: TextStyle(color: _roleColor(u.role), fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(u.username, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.textPrimary)),
                                    const SizedBox(height: 4),
                                    Text('${u.email ?? ""}  •  ${u.pharmacieNom ?? "Aucune pharmacie"}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _roleColor(u.role).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(_roleLabel(u.role), style: TextStyle(fontSize: 11, color: _roleColor(u.role), fontWeight: FontWeight.w500)),
                              ),
                              const SizedBox(width: 4),
                              PopupMenuButton<String>(
                                itemBuilder: (ctx) => [
                                  PopupMenuItem(value: 'toggle', child: Text(u.isActive ? 'Désactiver' : 'Activer')),
                                  PopupMenuItem(value: 'delete', child: Text('Supprimer', style: TextStyle(color: AppTheme.errorColor))),
                                ],
                                onSelected: (v) {
                                  if (v == 'toggle') provider.toggleActif(u.id);
                                  if (v == 'delete') _confirmDelete(u.id);
                                },
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

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmer'),
        content: const Text('Supprimer cet utilisateur ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(onPressed: () { Navigator.pop(ctx); context.read<UtilisateurProvider>().deleteUtilisateur(id); }, child: const Text('Supprimer', style: TextStyle(color: AppTheme.errorColor))),
        ],
      ),
    );
  }
}
