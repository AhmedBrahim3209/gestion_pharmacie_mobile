import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/fournisseur.dart';
import '../../providers/achat_provider.dart';

class FournisseursScreen extends StatefulWidget {
  const FournisseursScreen({super.key});

  @override
  State<FournisseursScreen> createState() => _FournisseursScreenState();
}

class _FournisseursScreenState extends State<FournisseursScreen> {
  final _nomCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();
  Fournisseur? _editing;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AchatProvider>().loadFournisseurs();
    });
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _contactCtrl.dispose();
    _telCtrl.dispose();
    _emailCtrl.dispose();
    _adresseCtrl.dispose();
    super.dispose();
  }

  void _showForm({Fournisseur? f}) {
    _editing = f;
    if (f != null) {
      _nomCtrl.text = f.nom;
      _contactCtrl.text = f.contact ?? '';
      _telCtrl.text = f.telephone ?? '';
      _emailCtrl.text = f.email ?? '';
      _adresseCtrl.text = f.adresse ?? '';
    } else {
      _nomCtrl.clear(); _contactCtrl.clear();
      _telCtrl.clear(); _emailCtrl.clear(); _adresseCtrl.clear();
    }
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text(f != null ? 'Modifier fournisseur' : 'Nouveau fournisseur'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nomCtrl, decoration: const InputDecoration(labelText: 'Nom *', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: _contactCtrl, decoration: const InputDecoration(labelText: 'Contact', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: _telCtrl, decoration: const InputDecoration(labelText: 'Téléphone (8 chiffres)', border: OutlineInputBorder(), hintText: '45123456'), keyboardType: TextInputType.phone, onChanged: (v) {
              if (v.length > 8) _telCtrl.text = v.substring(0, 8);
            }),
            const SizedBox(height: 8),
            TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: _adresseCtrl, decoration: const InputDecoration(labelText: 'Adresse', border: OutlineInputBorder())),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
        TextButton(onPressed: () async {
          if (_nomCtrl.text.isNotEmpty) {
            if (_telCtrl.text.isNotEmpty && _telCtrl.text.replaceAll(RegExp(r'\D'), '').length != 8) {
              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Le téléphone doit faire 8 chiffres'), backgroundColor: AppTheme.errorColor));
              return;
            }
            final achatProv = context.read<AchatProvider>();
            bool ok;
            if (_editing != null) {
              ok = await achatProv.updateFournisseur(_editing!.id, {
                'nom': _nomCtrl.text.trim(),
                'contact': _contactCtrl.text.trim(),
                'telephone': _telCtrl.text.trim(),
                'email': _emailCtrl.text.trim(),
                'adresse': _adresseCtrl.text.trim(),
              });
            } else {
              ok = await achatProv.createFournisseur({
                'nom': _nomCtrl.text.trim(),
                'contact': _contactCtrl.text.trim(),
                'telephone': _telCtrl.text.trim(),
                'email': _emailCtrl.text.trim(),
                'adresse': _adresseCtrl.text.trim(),
              });
            }
            if (!ctx.mounted) return;
            if (ok) {
              _nomCtrl.clear(); _contactCtrl.clear(); _telCtrl.clear(); _emailCtrl.clear(); _adresseCtrl.clear();
              _editing = null;
              Navigator.pop(ctx);
            } else {
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                content: Text(achatProv.error ?? 'Erreur'),
                backgroundColor: AppTheme.errorColor,
              ));
            }
          }
        }, child: Text(f != null ? 'Modifier' : 'Ajouter')),
      ],
    ));
  }

  void _confirmDelete(int id) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Confirmer'),
      content: const Text('Supprimer ce fournisseur ?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
        TextButton(onPressed: () {
          Navigator.pop(ctx);
          context.read<AchatProvider>().deleteFournisseur(id);
        }, child: const Text('Supprimer', style: TextStyle(color: AppTheme.errorColor))),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final fournisseurs = context.watch<AchatProvider>().fournisseurs;

    return Scaffold(
      appBar: AppBar(title: const Text('Fournisseurs'), actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: () => _showForm()),
      ]),
      body: ListView.builder(
        itemCount: fournisseurs.length,
        itemBuilder: (context, index) {
          final f = fournisseurs[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(child: Icon(f.estActif ? Icons.business : Icons.business_outlined)),
              title: Text(f.nom),
              subtitle: Text(f.telephone ?? f.email ?? ''),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!f.estActif) const Icon(Icons.block, color: Colors.red, size: 18),
                  const SizedBox(width: 4),
                  IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _showForm(f: f)),
                  IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.errorColor), onPressed: () => _confirmDelete(f.id)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
