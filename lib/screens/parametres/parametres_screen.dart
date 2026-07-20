import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_theme.dart';
import '../../providers/pharmacie_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/localisation_provider.dart';

class ParametresScreen extends StatefulWidget {
  const ParametresScreen({super.key});

  @override
  State<ParametresScreen> createState() => _ParametresScreenState();
}

class _ParametresScreenState extends State<ParametresScreen> {
  final _nomCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _plateformeNomCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _supportEmailCtrl = TextEditingController();
  final _supportTelCtrl = TextEditingController();
  String _langue = 'fr';
  String _devise = 'MRU';
  File? _logoFile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pp = context.read<PharmacieProvider>();
      pp.loadMySettings();
      pp.loadPlatformSettings();
    });
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _adresseCtrl.dispose();
    _telCtrl.dispose();
    _emailCtrl.dispose();
    _messageCtrl.dispose();
    _plateformeNomCtrl.dispose();
    _descriptionCtrl.dispose();
    _supportEmailCtrl.dispose();
    _supportTelCtrl.dispose();
    super.dispose();
  }

  void _initPharmacyFields(PharmacieProvider pp) {
    final p = pp.myPharmacie;
    if (p != null) {
      _nomCtrl.text = p.nom;
      _adresseCtrl.text = p.adresse ?? '';
      _telCtrl.text = p.telephone ?? '';
      _emailCtrl.text = p.email ?? '';
      _messageCtrl.text = p.messageTicket ?? '';
      _langue = p.langue ?? 'fr';
      _devise = p.devise ?? 'CFA';
    }
  }

  void _initPlatformFields(PharmacieProvider pp) {
    final s = pp.platformSettings;
    if (s != null) {
      _plateformeNomCtrl.text = s.nom ?? '';
      _descriptionCtrl.text = s.description ?? '';
      _supportEmailCtrl.text = s.supportEmail ?? '';
      _supportTelCtrl.text = s.supportPhone ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<PharmacieProvider>();
    final auth = context.watch<AuthProvider>();
    final loc = context.watch<LocalisationProvider>();

    if (pp.myPharmacie != null && _nomCtrl.text.isEmpty) _initPharmacyFields(pp);
    if (pp.platformSettings != null && _plateformeNomCtrl.text.isEmpty) _initPlatformFields(pp);

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Général'),
            const SizedBox(height: 8),
            Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _langue,
                      decoration: const InputDecoration(labelText: 'Langue'),
                      items: const [
                        DropdownMenuItem(value: 'fr', child: Text('Français')),
                        DropdownMenuItem(value: 'en', child: Text('English')),
                        DropdownMenuItem(value: 'ar', child: Text('العربية')),
                      ],
                      onChanged: (v) {
                        setState(() => _langue = v ?? 'fr');
                        loc.setLocale(_langue);
                        pp.updateMySettings({'langue': _langue, 'devise': _devise});
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _devise,
                      decoration: const InputDecoration(labelText: 'Devise'),
                      items: const [
                        DropdownMenuItem(value: 'MRU', child: Text('MRU (أوقية)')),
                        DropdownMenuItem(value: 'CFA', child: Text('CFA (F CFA)')),
                        DropdownMenuItem(value: 'EUR', child: Text('Euro (€)')),
                        DropdownMenuItem(value: 'USD', child: Text('Dollar (\$)')),
                      ],
                      onChanged: (v) => setState(() => _devise = v ?? 'CFA'),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          pp.updateMySettings({'langue': _langue, 'devise': _devise});
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paramètres généraux mis à jour')));
                        },
                        child: const Text('Enregistrer'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (auth.user?.isAdminPharmacie == true || auth.user?.isSuperAdmin == true) ...[
              const SizedBox(height: 24),
              _sectionHeader('Pharmacie'),
              const SizedBox(height: 8),
              Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(controller: _nomCtrl, decoration: const InputDecoration(labelText: 'Nom')),
                      const SizedBox(height: 16),
                      TextFormField(controller: _adresseCtrl, decoration: const InputDecoration(labelText: 'Adresse')),
                      const SizedBox(height: 16),
                      TextFormField(controller: _telCtrl, decoration: const InputDecoration(labelText: 'Téléphone')),
                      const SizedBox(height: 16),
                      TextFormField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
                      const SizedBox(height: 16),
                      TextFormField(controller: _messageCtrl, decoration: const InputDecoration(labelText: 'Message ticket'), maxLines: 3),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: _logoFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(_logoFile!, width: 48, height: 48, fit: BoxFit.cover),
                              )
                            : const Icon(Icons.image_outlined),
                        title: const Text('Logo'),
                        subtitle: Text(_logoFile?.path.split('/').last ?? (pp.myPharmacie?.logo != null ? pp.myPharmacie!.logo! : 'Aucun logo'), style: TextStyle(color: Colors.grey.shade600)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_logoFile != null)
                              IconButton(
                                icon: const Icon(Icons.upload, size: 20, color: AppTheme.primaryColor),
                                onPressed: () async {
                                  final pp = context.read<PharmacieProvider>();
                                  final success = await pp.uploadLogo(_logoFile!);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                      content: Text(success ? 'Logo téléchargé' : pp.error ?? 'Erreur'),
                                      backgroundColor: success ? Colors.green : AppTheme.errorColor,
                                    ));
                                    if (success) _logoFile = null;
                                  }
                                },
                              ),
                            TextButton(
                              onPressed: () async {
                                final picker = ImagePicker();
                                final picked = await picker.pickImage(source: ImageSource.gallery);
                                if (picked != null) {
                                  setState(() => _logoFile = File(picked.path));
                                }
                              },
                              child: const Text('Choisir'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            pp.updateMySettings({
                              'nom': _nomCtrl.text.trim(),
                              'adresse': _adresseCtrl.text.trim(),
                              'telephone': _telCtrl.text.trim(),
                              'email': _emailCtrl.text.trim(),
                              'message_ticket': _messageCtrl.text.trim(),
                            });
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pharmacie mise à jour')));
                          },
                          child: const Text('Enregistrer'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (auth.user?.isSuperAdmin == true) ...[
              const SizedBox(height: 24),
              _sectionHeader('Plateforme'),
              const SizedBox(height: 8),
              Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(controller: _plateformeNomCtrl, decoration: const InputDecoration(labelText: 'Nom plateforme')),
                      const SizedBox(height: 16),
                      TextFormField(controller: _descriptionCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
                      const SizedBox(height: 16),
                      TextFormField(controller: _supportEmailCtrl, decoration: const InputDecoration(labelText: 'Email support')),
                      const SizedBox(height: 16),
                      TextFormField(controller: _supportTelCtrl, decoration: const InputDecoration(labelText: 'Téléphone support')),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            pp.updatePlatformSettings({
                              'nom': _plateformeNomCtrl.text.trim(),
                              'description': _descriptionCtrl.text.trim(),
                              'support_email': _supportEmailCtrl.text.trim(),
                              'support_phone': _supportTelCtrl.text.trim(),
                            });
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plateforme mise à jour')));
                          },
                          child: const Text('Enregistrer'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
    );
  }
}
