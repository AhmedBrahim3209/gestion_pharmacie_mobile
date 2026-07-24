import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_theme.dart';
import '../../config/currency_helper.dart';
import '../../providers/abonnement_provider.dart';
import '../../widgets/loading_widget.dart';

class MonAbonnementScreen extends StatefulWidget {
  const MonAbonnementScreen({super.key});

  @override
  State<MonAbonnementScreen> createState() => _MonAbonnementScreenState();
}

class _MonAbonnementScreenState extends State<MonAbonnementScreen> {
  Map<String, dynamic>? _abonnement;
  Map<String, dynamic>? _prix;
  bool _isLoading = true;
  bool _paying = false;
  bool _paySuccess = false;
  String _selectedMethod = '';
  File? _captureFile;

  static const _modesPaiement = [
    {'key': 'bankily', 'label': 'Bankily'},
    {'key': 'sedad', 'label': 'Sedad'},
    {'key': 'masrifi', 'label': 'Masrifi'},
    {'key': 'especes', 'label': 'Espèces'},
    {'key': 'carte', 'label': 'Carte'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _charger());
  }

  Future<void> _charger() async {
    setState(() => _isLoading = true);
    final prov = context.read<AbonnementProvider>();
    final abo = await prov.getMonAbonnement();
    final prix = await prov.getPrix();
    if (mounted) setState(() { _abonnement = abo; _prix = prix; _isLoading = false; });
  }

  String _planLabel(String? plan) {
    switch (plan) {
      case 'essai_gratuit': return 'Essai Gratuit';
      case 'standard': return 'Abonnement Standard';
      default: return plan ?? 'N/A';
    }
  }

  String _statutLabel(String? statut) {
    switch (statut) {
      case 'actif': return 'Actif';
      case 'expire': return 'Expiré';
      case 'suspendu': return 'Suspendu';
      case 'annule': return 'Annulé';
      default: return statut ?? 'N/A';
    }
  }

  Color _statutColor(String? statut) {
    switch (statut) {
      case 'actif': return AppTheme.successColor;
      case 'expire': return AppTheme.errorColor;
      case 'suspendu': return AppTheme.warningColor;
      default: return Colors.grey;
    }
  }

  Future<void> _payer() async {
    if (_selectedMethod.isEmpty) return;
    setState(() => _paying = true);
    final prov = context.read<AbonnementProvider>();
    final data = <String, dynamic>{
      'mode_paiement': _selectedMethod,
      'reference': 'PAY-${DateTime.now().millisecondsSinceEpoch}',
      'transaction_id': 'TXN-${DateTime.now().millisecondsSinceEpoch}',
    };
    final ok = await prov.payerMonAbonnement(data);
    if (mounted) {
      setState(() => _paying = false);
      if (ok) {
        setState(() { _paySuccess = true; _selectedMethod = ''; _captureFile = null; });
        _charger();
        Future.delayed(const Duration(seconds: 4), () { if (mounted) setState(() => _paySuccess = false); });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(prov.error ?? 'Erreur de paiement'),
          backgroundColor: AppTheme.errorColor,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Scaffold(appBar: AppBar(title: const Text('Mon abonnement')), body: const LoadingWidget());
    if (_abonnement == null) return Scaffold(
      appBar: AppBar(title: const Text('Mon abonnement')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.subscriptions_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Aucun abonnement trouvé', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
            const SizedBox(height: 8),
            TextButton(onPressed: _charger, child: const Text('Réessayer')),
          ],
        ),
      ),
    );

    final abo = _abonnement!;
    final prix = _prix;
    final montantPrix = (prix?['prix'] as num?)?.toDouble() ?? 500;
    final isEssai = abo['plan'] == 'essai_gratuit';
    final joursRestants = abo['jours_restants'] ?? 0;
    final progression = (abo['progression'] as num?)?.toDouble() ?? 0;
    final estExpire = abo['statut'] == 'expire' || (isEssai && joursRestants == 0 && abo['statut'] == 'actif');
    final paiements = (abo['paiements'] as List<dynamic>?) ?? [];

    Color progColor = AppTheme.successColor;
    if (progression > 80) progColor = AppTheme.errorColor;
    else if (progression > 50) progColor = AppTheme.warningColor;

    return Scaffold(
      appBar: AppBar(title: const Text('Mon abonnement')),
      body: RefreshIndicator(
        onRefresh: _charger,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_paySuccess)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.successColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.3))),
                child: const Row(children: [Icon(Icons.check_circle, color: AppTheme.successColor), SizedBox(width: 8), Text('Paiement réussi !', style: TextStyle(color: AppTheme.successColor, fontWeight: FontWeight.w600))]),
              ),
            if (_paySuccess) const SizedBox(height: 12),
            if (estExpire)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: AppTheme.errorColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3))),
                child: Row(children: [Icon(Icons.warning, color: AppTheme.errorColor), const SizedBox(width: 8), Expanded(child: Text('Votre abonnement a expiré. Veuillez payer $montantPrix ${AppCurrency.symbol} pour activer l\'abonnement.', style: TextStyle(color: AppTheme.errorColor)))]),
              ),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: AppTheme.successColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.subscriptions, color: AppTheme.successColor, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(abo['pharmacie_nom'] ?? 'Mon abonnement', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppTheme.accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(_planLabel(abo['plan']), style: TextStyle(fontSize: 11, color: AppTheme.accentColor, fontWeight: FontWeight.w600))),
                        const SizedBox(width: 6),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: _statutColor(abo['statut']).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(_statutLabel(abo['statut']), style: TextStyle(fontSize: 11, color: _statutColor(abo['statut']), fontWeight: FontWeight.w600))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (abo['date_debut'] != null || abo['date_fin'] != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(abo['date_debut'] ?? '', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                          Text('$joursRestants jours restants', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: progColor)),
                          Text(abo['date_fin'] ?? '', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progression / 100,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(progColor),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _infoRow('Plan', _planLabel(abo['plan'])),
                    const Divider(height: 1),
                    _infoRow('Prix', isEssai ? 'Gratuit' : '$montantPrix ${AppCurrency.symbol}'),
                    const Divider(height: 1),
                    _infoRow('Durée', isEssai ? '30 jours' : '1 mois'),
                    const Divider(height: 1),
                    if (abo['date_debut'] != null) ...[_infoRow('Date début', abo['date_debut']), const Divider(height: 1)],
                    if (abo['date_fin'] != null) ...[_infoRow('Date fin', abo['date_fin']), const Divider(height: 1)],
                    _infoRow('Renouvellement auto', abo['renouvellement_auto'] == true ? 'Oui' : 'Non'),
                    const Divider(height: 1),
                    _infoRow('Dernier paiement', abo['dernier_paiement'] != null ? (abo['dernier_paiement']['date_paiement'] ?? '-') : '-'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (isEssai || estExpire) ...[
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppTheme.primaryColor, width: 2)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [const Icon(Icons.credit_card, size: 20), const SizedBox(width: 8), Text('Payer — $montantPrix ${AppCurrency.symbol} /mois', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
                      const SizedBox(height: 8),
                      Text(estExpire ? 'Votre essai est terminé. Payez $montantPrix ${AppCurrency.symbol} pour activer l\'abonnement.' : 'Payez $montantPrix ${AppCurrency.symbol} pour passer à l\'abonnement standard.', style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 16),
                      ..._modesPaiement.map((m) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () => setState(() => _selectedMethod = m['key']!),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _selectedMethod == m['key'] ? AppTheme.primaryColor : Colors.grey.shade300, width: _selectedMethod == m['key'] ? 2 : 1),
                              color: _selectedMethod == m['key'] ? AppTheme.primaryColor.withValues(alpha: 0.05) : Colors.white,
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.payment, color: _selectedMethod == m['key'] ? AppTheme.primaryColor : Colors.grey.shade500, size: 20),
                                const SizedBox(width: 12),
                                Expanded(child: Text(m['label']!, style: TextStyle(fontWeight: _selectedMethod == m['key'] ? FontWeight.w600 : FontWeight.normal))),
                                if (_selectedMethod == m['key']) const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 20),
                              ],
                            ),
                          ),
                        ),
                      )),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.image),
                            label: Text(_captureFile != null ? 'Changer la capture' : 'Joindre une capture'),
                            onPressed: () async {
                              final picker = ImagePicker();
                              final picked = await picker.pickImage(source: ImageSource.gallery);
                              if (picked != null) setState(() => _captureFile = File(picked.path));
                            },
                          ),
                          if (_captureFile != null) Expanded(child: Text(_captureFile!.path.split('/').last, style: TextStyle(fontSize: 11, color: Colors.grey.shade500), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          icon: _paying ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.credit_card),
                          label: Text(_paying ? 'Paiement en cours...' : 'Payer $montantPrix ${AppCurrency.symbol}'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          onPressed: _selectedMethod.isNotEmpty && !_paying ? _payer : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Historique des paiements', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (paiements.isEmpty)
                      Center(child: Padding(padding: const EdgeInsets.all(16), child: Text('Aucun paiement', style: TextStyle(color: Colors.grey.shade500))))
                    else
                      ...paiements.map((p) => Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p['date_paiement'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                    const SizedBox(height: 2),
                                    Text('${(p['montant'] as num?)?.toDouble() ?? 0} ${AppCurrency.symbol}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (p['statut'] == 'valide' ? AppTheme.successColor : p['statut'] == 'en_attente' ? AppTheme.warningColor : AppTheme.errorColor).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  p['statut'] == 'valide' ? 'Validé' : p['statut'] == 'en_attente' ? 'En attente' : 'Échoué',
                                  style: TextStyle(fontSize: 10, color: p['statut'] == 'valide' ? AppTheme.successColor : p['statut'] == 'en_attente' ? AppTheme.warningColor : AppTheme.errorColor, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(color: Colors.grey.shade600)), Text(value, style: const TextStyle(fontWeight: FontWeight.w500))]),
    );
  }
}