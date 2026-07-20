import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/stock_provider.dart';

class AjusterStockScreen extends StatefulWidget {
  final int stockId;
  final String medicamentNom;
  final double quantiteActuelle;

  const AjusterStockScreen({
    super.key,
    required this.stockId,
    required this.medicamentNom,
    required this.quantiteActuelle,
  });

  @override
  State<AjusterStockScreen> createState() => _AjusterStockScreenState();
}

class _AjusterStockScreenState extends State<AjusterStockScreen> {
  final _quantiteCtrl = TextEditingController();
  final _lotCtrl = TextEditingController();
  final _motifCtrl = TextEditingController();
  String _typeMouvement = 'entree';

  @override
  void dispose() {
    _quantiteCtrl.dispose();
    _lotCtrl.dispose();
    _motifCtrl.dispose();
    super.dispose();
  }

  Future<void> _ajuster() async {
    final qte = double.tryParse(_quantiteCtrl.text);
    if (qte == null || qte <= 0) return;

    final stockProv = context.read<StockProvider>();
    final success = await stockProv.adjustStock(widget.stockId, {
      'type_mouvement': _typeMouvement,
      'quantite': qte,
      'numero_lot': _lotCtrl.text.trim().isNotEmpty ? _lotCtrl.text.trim() : null,
      'motif': _motifCtrl.text.trim(),
    });

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stock mis à jour')));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(stockProv.error ?? 'Erreur lors de l\'ajustement'), backgroundColor: AppTheme.errorColor));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ajuster: ${widget.medicamentNom}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [const Text('Stock actuel: '), Text('${widget.quantiteActuelle.toStringAsFixed(0)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))]))),
            const SizedBox(height: 24),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'entree', label: Text('Entrée'), icon: Icon(Icons.add)),
                ButtonSegment(value: 'sortie', label: Text('Sortie'), icon: Icon(Icons.remove)),
                ButtonSegment(value: 'ajustement', label: Text('Ajustement'), icon: Icon(Icons.tune)),
              ],
              selected: {_typeMouvement},
              onSelectionChanged: (v) => setState(() => _typeMouvement = v.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _quantiteCtrl,
              decoration: const InputDecoration(labelText: 'Quantité', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _lotCtrl,
              decoration: const InputDecoration(labelText: 'Numéro de lot (optionnel)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _motifCtrl,
              decoration: const InputDecoration(labelText: 'Motif (optionnel)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 48, child: ElevatedButton(onPressed: _ajuster, child: const Text('Valider'))),
          ],
        ),
      ),
    );
  }
}
