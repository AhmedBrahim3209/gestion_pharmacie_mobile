import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/medicament_provider.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _nomCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedicamentProvider>().loadCategories();
    });
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    super.dispose();
  }

  void _addCategory() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Nouvelle catégorie'),
      content: TextField(controller: _nomCtrl, decoration: const InputDecoration(labelText: 'Nom', border: OutlineInputBorder()), autofocus: true),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
        TextButton(onPressed: () {
          if (_nomCtrl.text.isNotEmpty) {
            context.read<MedicamentProvider>().createCategory({'nom': _nomCtrl.text});
            _nomCtrl.clear();
            Navigator.pop(ctx);
          }
        }, child: const Text('Ajouter')),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<MedicamentProvider>().categories;

    return Scaffold(
      appBar: AppBar(title: const Text('Catégories'), actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: _addCategory),
      ]),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.category)),
            title: Text(cat.nom),
            subtitle: cat.description != null ? Text(cat.description!) : null,
          );
        },
      ),
    );
  }
}
