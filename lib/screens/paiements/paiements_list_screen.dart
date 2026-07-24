import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/currency_helper.dart';
import '../../providers/paiement_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/loading_widget.dart';

class PaiementsListScreen extends StatefulWidget {
  const PaiementsListScreen({super.key});

  @override
  State<PaiementsListScreen> createState() => _PaiementsListScreenState();
}

class _PaiementsListScreenState extends State<PaiementsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaiementProvider>().loadPaiements();
    });
  }

  Color _statutColor(String statut) {
    switch (statut) {
      case 'valide': return AppTheme.successColor;
      case 'en_attente': return AppTheme.warningColor;
      case 'echoue':
      case 'echec': return AppTheme.errorColor;
      case 'rembourse': return AppTheme.accentColor;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaiementProvider>();
    final auth = context.watch<AuthProvider>();
    final isSuper = auth.user?.isSuperAdmin == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiements'),
        actions: [
          if (provider.isLoading)
            const SizedBox(width: 24, height: 24, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))),
        ],
      ),
      body: provider.isLoading
          ? const LoadingWidget()
          : provider.paiements.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.payment_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('Aucun paiement', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => provider.loadPaiements(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: provider.paiements.length,
                    itemBuilder: (context, index) {
                      final p = provider.paiements[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _statutColor(p.statut).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.payment, color: _statutColor(p.statut), size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.reference, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.textPrimary)),
                                    const SizedBox(height: 4),
                                    Text('${p.montant.toStringAsFixed(0)} ${AppCurrency.symbol}  •  ${p.date ?? ""}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                                    if (p.pharmacieNom != null)
                                      Text(p.pharmacieNom!, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _statutColor(p.statut).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(p.statut, style: TextStyle(fontSize: 11, color: _statutColor(p.statut), fontWeight: FontWeight.w500)),
                                  ),
                                  if (isSuper && p.statut == 'en_attente') ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        InkWell(
                                          onTap: () => context.read<PaiementProvider>().confirmerPaiement(p.id),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(color: AppTheme.successColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                            child: const Icon(Icons.check_circle, color: AppTheme.successColor, size: 18),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        InkWell(
                                          onTap: () => context.read<PaiementProvider>().annulerPaiement(p.id),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(color: AppTheme.errorColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                            child: const Icon(Icons.cancel, color: AppTheme.errorColor, size: 18),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
