import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/client.dart';
import '../../providers/client_provider.dart';

class ClientFormScreen extends StatefulWidget {
  final Client? client;
  const ClientFormScreen({super.key, this.client});

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

  bool get isEditing => widget.client != null;

  @override
  void initState() {
    super.initState();
    final c = widget.client;
    if (c != null) {
      _nomCtrl.text = c.nom;
      _prenomCtrl.text = c.prenom ?? '';
      _telCtrl.text = c.telephone ?? '';
      _emailCtrl.text = c.email ?? '';
      _adresseCtrl.text = c.adresse ?? '';
      _sexe = c.sexe;
    }
  }

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
    final data = {
      'nom': _nomCtrl.text.trim(),
      'prenom': _prenomCtrl.text.trim(),
      'telephone': _telCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'adresse': _adresseCtrl.text.trim(),
      'sexe': _sexe,
    };
    final bool success;
    if (isEditing) {
      success = await clientProv.updateClient(widget.client!.id, data);
    } else {
      success = await clientProv.createClient(data);
    }
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(clientProv.error ?? 'Erreur'), backgroundColor: AppTheme.errorColor));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Modifier Client' : 'Nouveau Client'), actions: [
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
              TextFormField(controller: _telCtrl, decoration: const InputDecoration(labelText: 'Téléphone (8 chiffres)', border: OutlineInputBorder(), hintText: '45123456'), keyboardType: TextInputType.phone, validator: (v) {
                if (v == null || v.isEmpty) return null;
                if (v.replaceAll(RegExp(r'\D'), '').length != 8) return 'Le numéro doit faire 8 chiffres';
                return null;
              }),
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
