import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/achat.dart';

class AchatDetailScreen extends StatelessWidget {
  final Achat achat;
  const AchatDetailScreen({super.key, required this.achat});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Achat #${achat.numero}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Achat #${achat.numero}', style: Theme.of(context).textTheme.titleLarge),
                  const Divider(),
                  _row('Date', achat.dateAchat),
                  _row('Fournisseur', achat.fournisseurNom ?? 'N/A'),
                  _row('Statut', achat.statut),
                  _row('Enregistré par', achat.enregistreParNom ?? 'N/A'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Articles', style: Theme.of(context).textTheme.titleMedium),
          ...achat.lignes.map((l) => Card(
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
              child: _row('Total', '${achat.montantTotal} CFA', isBold: true),
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
