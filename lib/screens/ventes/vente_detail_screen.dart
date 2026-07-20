import 'package:flutter/material.dart';
import '../../models/vente.dart';
import '../../services/pdf_service.dart';

class VenteDetailScreen extends StatelessWidget {
  final Vente vente;
  const VenteDetailScreen({super.key, required this.vente});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vente #${vente.numero}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Télécharger le reçu',
            onPressed: () async {
              final pdf = await PdfService.generateSaleReceipt(vente);
              if (context.mounted) {
                await PdfService.saveAndOpen(pdf, 'recu_vente_${vente.numero}.pdf');
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Vente #${vente.numero}', style: Theme.of(context).textTheme.titleLarge),
                  const Divider(),
                  _row('Date', vente.dateVente),
                  _row('Client', vente.clientNom ?? 'N/A'),
                  _row('Statut', vente.statut),
                  _row('Enregistré par', vente.enregistreParNom ?? 'N/A'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Articles', style: Theme.of(context).textTheme.titleMedium),
          ...vente.lignes.map((l) => Card(
            child: ListTile(
              title: Text(l.medicamentNom),
              subtitle: Text('${l.quantite} x ${l.prixUnitaire} CFA'),
              trailing: Text('${l.sousTotal} CFA', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          )),
          const Divider(),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _row('Total', '${vente.montantTotal} CFA'),
                  _row('Remise', '${vente.remise} CFA'),
                  _row('Net à payer', '${vente.montantNet} CFA', isBold: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: isBold ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16) : null),
      ]),
    );
  }
}
