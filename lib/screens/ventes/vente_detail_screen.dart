import 'package:flutter/material.dart';
import '../../config/currency_helper.dart';
import '../../models/vente.dart';
import '../../providers/vente_provider.dart';
import '../../services/pdf_service.dart';

class VenteDetailScreen extends StatefulWidget {
  final Vente vente;
  const VenteDetailScreen({super.key, required this.vente});

  @override
  State<VenteDetailScreen> createState() => _VenteDetailScreenState();
}

class _VenteDetailScreenState extends State<VenteDetailScreen> {
  Vente? _venteComplete;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chargerVenteComplete();
  }

  Future<void> _chargerVenteComplete() async {
    if (widget.vente.lignes.isNotEmpty) {
      setState(() { _venteComplete = widget.vente; _isLoading = false; });
      return;
    }
    final prov = VenteProvider();
    final v = await prov.getVenteDetail(widget.vente.id);
    if (mounted) setState(() { _venteComplete = v ?? widget.vente; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final vente = _venteComplete ?? widget.vente;

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
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
              subtitle: Text('${l.quantite.toStringAsFixed(0)} x ${l.prixUnitaire.toStringAsFixed(0)} ${AppCurrency.symbol}'),
              trailing: Text('${l.sousTotal.toStringAsFixed(0)} ${AppCurrency.symbol}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          )),
          const Divider(),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _row('Total', '${vente.montantTotal.toStringAsFixed(0)} ${AppCurrency.symbol}'),
                  _row('Remise', '${vente.remise.toStringAsFixed(0)} ${AppCurrency.symbol}'),
                  _row('Net à payer', '${vente.montantNet.toStringAsFixed(0)} ${AppCurrency.symbol}', isBold: true),
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
