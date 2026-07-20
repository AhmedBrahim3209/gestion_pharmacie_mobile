import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telephoneCtrl = TextEditingController();
  bool _isEditing = false;

  final _oldPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  final _confirmPwCtrl = TextEditingController();
  bool _showPasswordForm = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initControllers());
  }

  void _initControllers() {
    final user = context.read<AuthProvider>().user;
    _firstNameCtrl.text = user?.firstName ?? '';
    _lastNameCtrl.text = user?.lastName ?? '';
    _emailCtrl.text = user?.email ?? '';
    _telephoneCtrl.text = user?.telephone ?? '';
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _telephoneCtrl.dispose();
    _oldPwCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.updateProfile({
      'first_name': _firstNameCtrl.text.trim(),
      'last_name': _lastNameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'telephone': _telephoneCtrl.text.trim(),
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success ? 'Profil mis à jour' : auth.error ?? 'Erreur'),
      backgroundColor: success ? Colors.green : Colors.red,
    ));
    if (success) setState(() => _isEditing = false);
  }

  Future<void> _changePassword() async {
    if (_oldPwCtrl.text.isEmpty || _newPwCtrl.text.isEmpty) return;
    if (_newPwCtrl.text != _confirmPwCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Les mots de passe ne correspondent pas'), backgroundColor: AppTheme.errorColor));
      return;
    }
    final auth = context.read<AuthProvider>();
    final success = await auth.changePassword(_oldPwCtrl.text, _newPwCtrl.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success ? 'Mot de passe modifié' : auth.error ?? 'Erreur'),
      backgroundColor: success ? Colors.green : Colors.red,
    ));
    if (success) {
      _oldPwCtrl.clear();
      _newPwCtrl.clear();
      _confirmPwCtrl.clear();
      setState(() => _showPasswordForm = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    if (user == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Modifier',
              onPressed: () {
                _initControllers();
                setState(() => _isEditing = true);
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(radius: 40, backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1), child: Text(user.username[0].toUpperCase(), style: TextStyle(fontSize: 32, color: AppTheme.primaryColor, fontWeight: FontWeight.bold))),
                const SizedBox(height: 12),
                Text(user.displayName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text('@${user.username}  •  ${user.role.replaceAll('_', ' ').toUpperCase()}', style: TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          if (_isEditing)
            _buildEditForm()
          else
            _buildInfoCard(user),
          const SizedBox(height: 16),
          if (!_showPasswordForm)
            OutlinedButton.icon(
              icon: const Icon(Icons.lock_reset_outlined),
              label: const Text('Changer le mot de passe'),
              onPressed: () => setState(() => _showPasswordForm = true),
            )
          else
            Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(controller: _oldPwCtrl, decoration: const InputDecoration(labelText: 'Ancien mot de passe'), obscureText: true),
                    const SizedBox(height: 12),
                    TextField(controller: _newPwCtrl, decoration: const InputDecoration(labelText: 'Nouveau mot de passe'), obscureText: true),
                    const SizedBox(height: 12),
                    TextField(controller: _confirmPwCtrl, decoration: const InputDecoration(labelText: 'Confirmer le mot de passe'), obscureText: true),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: OutlinedButton(onPressed: () => setState(() => _showPasswordForm = false), child: const Text('Annuler'))),
                        const SizedBox(width: 12),
                        Expanded(child: ElevatedButton(onPressed: _changePassword, child: const Text('Valider'))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(user) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _infoTile(Icons.person_outlined, 'Prénom', user?.firstName ?? 'Non renseigné'),
          const Divider(height: 1, indent: 16),
          _infoTile(Icons.person_outlined, 'Nom', user?.lastName ?? 'Non renseigné'),
          const Divider(height: 1, indent: 16),
          _infoTile(Icons.email_outlined, 'Email', user?.email ?? 'Non renseigné'),
          const Divider(height: 1, indent: 16),
          _infoTile(Icons.phone_outlined, 'Téléphone', user?.telephone ?? 'Non renseigné'),
          if (user?.pharmacieNom != null) ...[
            const Divider(height: 1, indent: 16),
            _infoTile(Icons.local_pharmacy_outlined, 'Pharmacie', user?.pharmacieNom ?? ''),
          ],
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
      subtitle: Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Modifier le profil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 16),
              TextFormField(controller: _firstNameCtrl, decoration: const InputDecoration(labelText: 'Prénom', prefixIcon: Icon(Icons.person_outlined)), validator: (v) => v == null || v.isEmpty ? 'Requis' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _lastNameCtrl, decoration: const InputDecoration(labelText: 'Nom', prefixIcon: Icon(Icons.person_outlined)), validator: (v) => v == null || v.isEmpty ? 'Requis' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)), keyboardType: TextInputType.emailAddress, validator: (v) => v == null || v.isEmpty ? 'Requis' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _telephoneCtrl, decoration: const InputDecoration(labelText: 'Téléphone', prefixIcon: Icon(Icons.phone_outlined)), keyboardType: TextInputType.phone),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => setState(() => _isEditing = false), child: const Text('Annuler'))),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton(onPressed: _saveProfile, child: const Text('Enregistrer'))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
