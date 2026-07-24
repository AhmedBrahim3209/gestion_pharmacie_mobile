import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/currency_helper.dart';
import '../../models/medicament.dart';
import '../../providers/medicament_provider.dart';
import '../../providers/achat_provider.dart';

class NouvelAchatScreen extends StatefulWidget {
  const NouvelAchatScreen({super.key});

  @override
  State<NouvelAchatScreen> createState() => _NouvelAchatScreenState();
}

class _NouvelAchatScreenState extends State<NouvelAchatScreen> {
  final _lignes = <_LigneAchat>[];
  int? _fournisseurId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedicamentProvider>().loadMedicaments();
      context.read<AchatProvider>().loadFournisseurs();
    });
  }

  double get _total => _lignes.fold<double>(0.0, (sum, l) => sum + (l.prixUnitaire * l.quantite));

  void _ajouterLigne(Medicament med) {
    setState(() => _lignes.add(_LigneAchat(medicament: med, quantite: 1, prixUnitaire: med.prixAchat ?? 0)));
  }

  Future<void> _enregistrer() async {
    if (_lignes.isEmpty || _fournisseurId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complétez tous les champs')));
      return;
    }
    final data = {
      'fournisseur': _fournisseurId,
      'lignes': _lignes.map((l) => {'medicament': l.medicament.id, 'quantite': l.quantite, 'prix_unitaire': l.prixUnitaire}).toList(),
    };
    final achatProv = context.read<AchatProvider>();
    final success = await achatProv.createAchat(data);
    if (!mounted) return;
    if (success) {
      try { if (mounted) context.read<MedicamentProvider>().loadMedicaments(); } catch (_) {}
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(achatProv.error ?? 'Erreur lors de l\'achat'), backgroundColor: AppTheme.errorColor));
    }
  }

  @override
  Widget build(BuildContext context) {
    final medicaments = context.watch<MedicamentProvider>().medicaments;
    final fournisseurs = context.watch<AchatProvider>().fournisseurs;

    return Scaffold(
      appBar: AppBar(title: const Text('Nouvel Achat'), actions: [
        TextButton(onPressed: _lignes.isEmpty ? null : _enregistrer, child: const Text('Enregistrer')),
      ]),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<int>(
              value: _fournisseurId,
              decoration: const InputDecoration(labelText: 'Fournisseur', border: OutlineInputBorder()),
              items: fournisseurs.map((f) => DropdownMenuItem(value: f.id, child: Text(f.nom))).toList(),
              onChanged: (v) => setState(() => _fournisseurId = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: medicaments.length,
              itemBuilder: (context, index) {
                final med = medicaments[index];
                return ListTile(
                  leading: CircleAvatar(child: Text('${(med.prixAchat ?? 0).toStringAsFixed(0)} ${AppCurrency.symbol}', style: const TextStyle(fontSize: 9))),
                  title: Text(med.nom),
                  subtitle: Text('Prix achat: ${med.prixAchat ?? "N/A"} ${AppCurrency.symbol}'),
                  trailing: IconButton(icon: const Icon(Icons.add), onPressed: () => _ajouterLigne(med)),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('$_total ${AppCurrency.symbol}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _LigneAchat {
  final Medicament medicament;
  double quantite;
  double prixUnitaire;
  _LigneAchat({required this.medicament, required this.quantite, required this.prixUnitaire});
}
