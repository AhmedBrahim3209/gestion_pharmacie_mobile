import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_theme.dart';
import '../../config/currency_helper.dart';
import '../../providers/pharmacie_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/localisation_provider.dart';
import '../../providers/configuration_abonnement_provider.dart';

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

  // Platform pricing fields
  // Security
  final _oldPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  final _confirmPwCtrl = TextEditingController();
  bool _showPasswordForm = false;
  bool _twoFactorEnabled = false;

  final _prixAbonnementCtrl = TextEditingController();
  final _dureeEssaiCtrl = TextEditingController();
  final _dureeStandardCtrl = TextEditingController();
  final _remisePourcentageCtrl = TextEditingController();
  bool _remiseActive = false;

  // Config form fields
  final _configMontantCtrl = TextEditingController();
  final _configDureeCtrl = TextEditingController();
  final _configDateDebutCtrl = TextEditingController();
  final _configDateFinCtrl = TextEditingController();
  String _configPharmacieId = '';
  String _configPlan = 'standard';
  bool _showConfigForm = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pp = context.read<PharmacieProvider>();
      pp.loadMySettings();
      pp.loadPlatformSettings();
      context.read<ConfigurationAbonnementProvider>().loadConfigurations();
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
    _oldPwCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    _prixAbonnementCtrl.dispose();
    _dureeEssaiCtrl.dispose();
    _dureeStandardCtrl.dispose();
    _remisePourcentageCtrl.dispose();
    _configMontantCtrl.dispose();
    _configDureeCtrl.dispose();
    _configDateDebutCtrl.dispose();
    _configDateFinCtrl.dispose();
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
      _devise = p.devise ?? AppCurrency.symbol;
    }
  }

  void _initPlatformFields(PharmacieProvider pp) {
    final s = pp.platformSettings;
    if (s != null) {
      _plateformeNomCtrl.text = s.nom ?? '';
      _descriptionCtrl.text = s.description ?? '';
      _supportEmailCtrl.text = s.supportEmail ?? '';
      _supportTelCtrl.text = s.supportPhone ?? '';
      _prixAbonnementCtrl.text = s.prixAbonnement?.toStringAsFixed(0) ?? '500';
      _dureeEssaiCtrl.text = s.dureeEssaiJours?.toString() ?? '30';
      _dureeStandardCtrl.text = s.dureeStandardJours?.toString() ?? '30';
      _remisePourcentageCtrl.text = s.remisePourcentage?.toStringAsFixed(0) ?? '0';
      _remiseActive = s.remiseActive;
      _twoFactorEnabled = s.twoFactorEnabled;
    }
  }

  bool _fieldsInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_fieldsInitialized) {
      final pp = context.read<PharmacieProvider>();
      if (pp.myPharmacie != null) {
        _initPharmacyFields(pp);
        _fieldsInitialized = true;
      }
      if (pp.platformSettings != null) {
        _initPlatformFields(pp);
        _fieldsInitialized = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<PharmacieProvider>();
    final auth = context.watch<AuthProvider>();
    final loc = context.watch<LocalisationProvider>();

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
                      onChanged: (v) => setState(() => _devise = v ?? AppCurrency.symbol),
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
                      TextFormField(controller: _telCtrl, decoration: const InputDecoration(labelText: 'Téléphone (8 chiffres)'), keyboardType: TextInputType.phone, validator: (v) {
                        if (v == null || v.isEmpty) return null;
                        if (v.replaceAll(RegExp(r'\D'), '').length != 8) return '8 chiffres requis';
                        return null;
                      }),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(controller: _plateformeNomCtrl, decoration: const InputDecoration(labelText: 'Nom plateforme')),
                      const SizedBox(height: 12),
                      TextFormField(controller: _descriptionCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
                      const SizedBox(height: 12),
                      TextFormField(controller: _supportEmailCtrl, decoration: const InputDecoration(labelText: 'Email support')),
                      const SizedBox(height: 12),
                      TextFormField(controller: _supportTelCtrl, decoration: const InputDecoration(labelText: 'Téléphone support')),
                      const SizedBox(height: 12),
                      const Divider(),
                      const Text('Prix & Abonnement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 12),
                      TextFormField(controller: _prixAbonnementCtrl, decoration: const InputDecoration(labelText: "Prix d'abonnement (MRU)"), keyboardType: TextInputType.number),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: TextFormField(controller: _dureeEssaiCtrl, decoration: const InputDecoration(labelText: 'Durée essai (jours)'), keyboardType: TextInputType.number)),
                          const SizedBox(width: 12),
                          Expanded(child: TextFormField(controller: _dureeStandardCtrl, decoration: const InputDecoration(labelText: 'Durée standard (jours)'), keyboardType: TextInputType.number)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(controller: _remisePourcentageCtrl, decoration: const InputDecoration(labelText: 'Remise (%)'), keyboardType: TextInputType.number),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Activer remise', style: TextStyle(fontSize: 13)),
                              value: _remiseActive,
                              onChanged: (v) => setState(() => _remiseActive = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            pp.updatePlatformSettings({
                              'nom': _plateformeNomCtrl.text.trim(),
                              'description': _descriptionCtrl.text.trim(),
                              'support_email': _supportEmailCtrl.text.trim(),
                              'support_phone': _supportTelCtrl.text.trim(),
                              'prix_abonnement': double.tryParse(_prixAbonnementCtrl.text) ?? 500,
                              'duree_essai_jours': int.tryParse(_dureeEssaiCtrl.text) ?? 30,
                              'duree_standard_jours': int.tryParse(_dureeStandardCtrl.text) ?? 30,
                              'remise_pourcentage': double.tryParse(_remisePourcentageCtrl.text) ?? 0,
                              'remise_active': _remiseActive,
                              'two_factor_enabled': _twoFactorEnabled,
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
              const SizedBox(height: 24),
              _sectionHeader('Sécurité'),
              const SizedBox(height: 8),
              Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Authentification à deux facteurs (2FA)'),
                        subtitle: Text('Renforce la sécurité du compte administrateur', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        value: _twoFactorEnabled,
                        onChanged: (v) => setState(() => _twoFactorEnabled = v),
                      ),
                      const Divider(),
                      InkWell(
                        onTap: () => setState(() => _showPasswordForm = !_showPasswordForm),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.lock_reset, color: AppTheme.primaryColor),
                              const SizedBox(width: 12),
                              const Text('Changer mot de passe administrateur', style: TextStyle(fontWeight: FontWeight.w500)),
                              const Spacer(),
                              Icon(_showPasswordForm ? Icons.expand_less : Icons.expand_more, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                      if (_showPasswordForm) ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _oldPwCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'Mot de passe actuel *', border: OutlineInputBorder(), isDense: true),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _newPwCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'Nouveau mot de passe *', border: OutlineInputBorder(), isDense: true),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _confirmPwCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'Confirmer *', border: OutlineInputBorder(), isDense: true),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_newPwCtrl.text != _confirmPwCtrl.text) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Les mots de passe ne correspondent pas'), backgroundColor: AppTheme.errorColor));
                                return;
                              }
                              final auth = context.read<AuthProvider>();
                              final ok = await auth.changePassword(_oldPwCtrl.text, _newPwCtrl.text);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(ok ? 'Mot de passe changé' : auth.error ?? 'Erreur'),
                                  backgroundColor: ok ? Colors.green : AppTheme.errorColor,
                                ));
                                if (ok) {
                                  _oldPwCtrl.clear();
                                  _newPwCtrl.clear();
                                  _confirmPwCtrl.clear();
                                  setState(() => _showPasswordForm = false);
                                }
                              }
                            },
                            child: const Text('Changer le mot de passe'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _sectionHeader('Configurations abonnement par pharmacie'),
              const SizedBox(height: 8),
              _buildConfigurationsSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationsSection() {
    final configProv = context.watch<ConfigurationAbonnementProvider>();
    final pharmProv = context.watch<PharmacieProvider>();

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Définir des tarifs ou durées personnalisés pour des pharmacies spécifiques.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const SizedBox(height: 12),
            if (configProv.configurations.isNotEmpty) ...[
              ...configProv.configurations.map((c) => Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.pharmacieNom ?? 'Pharmacie #${c.pharmacieId}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text('${c.montant.toStringAsFixed(0)} MRU • ${c.dureeJours}j • ${c.dateDebut} → ${c.dateFin}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (c.actif ? AppTheme.successColor : Colors.grey).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(c.actif ? 'Actif' : 'Inactif', style: TextStyle(fontSize: 10, color: c.actif ? AppTheme.successColor : Colors.grey, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        child: const Icon(Icons.delete_outline, color: AppTheme.errorColor, size: 18),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Confirmer'),
                              content: Text('Supprimer la configuration pour ${c.pharmacieNom ?? "cette pharmacie"} ?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
                                ElevatedButton(onPressed: () { Navigator.pop(ctx); configProv.deleteConfiguration(c.id); }, child: const Text('Supprimer')),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              )),
            ] else ...[
              Center(child: Padding(padding: const EdgeInsets.all(16), child: Text('Aucune configuration personnalisée', style: TextStyle(color: Colors.grey.shade500)))),
            ],
            const SizedBox(height: 12),
            if (!_showConfigForm)
              OutlinedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ajouter une configuration'),
                onPressed: () => setState(() => _showConfigForm = true),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _configPharmacieId.isNotEmpty ? _configPharmacieId : null,
                      decoration: const InputDecoration(labelText: 'Pharmacie *', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                      items: pharmProv.pharmacies.map((p) => DropdownMenuItem(value: p.id.toString(), child: Text(p.nom))).toList(),
                      onChanged: (v) => setState(() => _configPharmacieId = v ?? ''),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _configPlan,
                      decoration: const InputDecoration(labelText: 'Plan *', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                      items: const [
                        DropdownMenuItem(value: 'standard', child: Text('Standard')),
                        DropdownMenuItem(value: 'essai_gratuit', child: Text('Essai Gratuit')),
                      ],
                      onChanged: (v) => setState(() => _configPlan = v ?? 'standard'),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(controller: _configMontantCtrl, decoration: const InputDecoration(labelText: 'Montant (MRU) *', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)), keyboardType: TextInputType.number),
                    const SizedBox(height: 8),
                    TextFormField(controller: _configDureeCtrl, decoration: const InputDecoration(labelText: 'Durée (jours) *', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)), keyboardType: TextInputType.number),
                    const SizedBox(height: 8),
                    TextFormField(controller: _configDateDebutCtrl, decoration: const InputDecoration(labelText: 'Date début * (AAAA-MM-JJ)', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10))),
                    const SizedBox(height: 8),
                    TextFormField(controller: _configDateFinCtrl, decoration: const InputDecoration(labelText: 'Date fin * (AAAA-MM-JJ)', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10))),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (_configPharmacieId.isEmpty || _configMontantCtrl.text.isEmpty || _configDureeCtrl.text.isEmpty || _configDateDebutCtrl.text.isEmpty || _configDateFinCtrl.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez remplir tous les champs'), backgroundColor: AppTheme.errorColor));
                                return;
                              }
                              configProv.createConfiguration({
                                'pharmacie': int.parse(_configPharmacieId),
                                'plan': _configPlan,
                                'montant': double.tryParse(_configMontantCtrl.text) ?? 0,
                                'duree_jours': int.tryParse(_configDureeCtrl.text) ?? 30,
                                'date_debut': _configDateDebutCtrl.text.trim(),
                                'date_fin': _configDateFinCtrl.text.trim(),
                              });
                              _configMontantCtrl.clear();
                              _configDureeCtrl.clear();
                              _configDateDebutCtrl.clear();
                              _configDateFinCtrl.clear();
                              setState(() { _configPharmacieId = ''; _showConfigForm = false; });
                            },
                            child: const Text('Enregistrer'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => setState(() { _showConfigForm = false; _configPharmacieId = ''; _configMontantCtrl.clear(); _configDureeCtrl.clear(); _configDateDebutCtrl.clear(); _configDateFinCtrl.clear(); }),
                          child: const Text('Annuler'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
