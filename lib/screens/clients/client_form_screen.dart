import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/client_provider.dart';

class ClientFormScreen extends StatefulWidget {
  const ClientFormScreen({super.key});

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();
  String? _sexe;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _telCtrl.dispose();
    _emailCtrl.dispose();
    _adresseCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final clientProv = context.read<ClientProvider>();
    final success = await clientProv.createClient({
      'nom': _nomCtrl.text.trim(),
      'prenom': _prenomCtrl.text.trim(),
      'telephone': _telCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'adresse': _adresseCtrl.text.trim(),
      'sexe': _sexe,
    });
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(clientProv.error ?? 'Erreur lors de la création'), backgroundColor: AppTheme.errorColor));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau Client'), actions: [
        TextButton(onPressed: _save, child: const Text('Enregistrer')),
      ]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: _nomCtrl, decoration: const InputDecoration(labelText: 'Nom *', border: OutlineInputBorder()), validator: (v) => v == null || v.isEmpty ? 'Requis' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _prenomCtrl, decoration: const InputDecoration(labelText: 'Prénom', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextFormField(controller: _telCtrl, decoration: const InputDecoration(labelText: 'Téléphone', border: OutlineInputBorder()), keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              TextFormField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              TextFormField(controller: _adresseCtrl, decoration: const InputDecoration(labelText: 'Adresse', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _sexe,
                decoration: const InputDecoration(labelText: 'Sexe', border: OutlineInputBorder()),
                items: const [DropdownMenuItem(value: 'M', child: Text('Masculin')), DropdownMenuItem(value: 'F', child: Text('Féminin'))],
                onChanged: (v) => setState(() => _sexe = v),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
