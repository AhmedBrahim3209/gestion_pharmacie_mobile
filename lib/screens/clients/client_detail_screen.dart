import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/currency_helper.dart';
import '../../models/client.dart';
import '../../providers/client_provider.dart';
import '../../widgets/loading_widget.dart';

class ClientDetailScreen extends StatefulWidget {
  final Client client;
  const ClientDetailScreen({super.key, required this.client});

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientProvider>().loadClientPurchases(widget.client.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final clientProv = context.watch<ClientProvider>();
    final achats = clientProv.clientPurchases;

    return Scaffold(
      appBar: AppBar(title: Text(widget.client.fullName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                        child: Text(widget.client.fullName[0].toUpperCase(), style: TextStyle(fontSize: 24, color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.client.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                          if (widget.client.email != null) Text(widget.client.email!, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _infoRow(Icons.phone, widget.client.telephone ?? 'N/A'),
                  const SizedBox(height: 8),
                  _infoRow(Icons.email, widget.client.email ?? 'N/A'),
                  const SizedBox(height: 8),
                  _infoRow(Icons.home, widget.client.adresse ?? 'N/A'),
                  const SizedBox(height: 8),
                  if (widget.client.sexe != null) _infoRow(Icons.person, widget.client.sexe!),
                  if (widget.client.dateNaissance != null) ...[
                    const SizedBox(height: 8),
                    _infoRow(Icons.cake, '${widget.client.dateNaissance!.day}/${widget.client.dateNaissance!.month}/${widget.client.dateNaissance!.year}'),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Historique des achats (${achats.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          if (clientProv.isLoadingPurchases)
            const LoadingWidget()
          else if (achats.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(child: Text('Aucun achat', style: TextStyle(color: Colors.grey.shade500))),
              ),
            )
          else
            ...achats.map((v) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.receipt, color: AppTheme.primaryColor, size: 20),
                ),
                title: Text('Vente #${v.numero}', style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text('${v.montantNet} ${AppCurrency.symbol}  •  ${v.dateVente}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: v.statut == 'finalisee' || v.statut == 'terminee' ? AppTheme.successColor.withValues(alpha: 0.1) : AppTheme.warningColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(v.statut, style: TextStyle(fontSize: 11, color: v.statut == 'finalisee' || v.statut == 'terminee' ? AppTheme.successColor : AppTheme.warningColor)),
                ),
              ),
            )),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryColor),
        const SizedBox(width: 12),
        Expanded(child: Text(value, style: const TextStyle(color: AppTheme.textPrimary))),
      ],
    );
  }
}
