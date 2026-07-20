import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../providers/lot_provider.dart';
import '../../providers/medicament_provider.dart';
import '../../models/lot.dart';
import '../../models/medicament.dart';

class AddEditLotScreen extends StatefulWidget {
  final Lot? lot;
  const AddEditLotScreen({super.key, this.lot});

  @override
  State<AddEditLotScreen> createState() => _AddEditLotScreenState();
}

class _AddEditLotScreenState extends State<AddEditLotScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numeroLotCtrl = TextEditingController();
  final _quantiteCtrl = TextEditingController();
  final _prixAchatCtrl = TextEditingController();
  final _prixVenteCtrl = TextEditingController();
  final _fournisseurCtrl = TextEditingController();

  Medicament? _medicamentSelectionne;
  DateTime _dateFabrication = DateTime.now();
  DateTime _dateExpiration = DateTime.now().add(const Duration(days: 365));
  bool _estActif = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.lot != null) {
      final l = widget.lot!;
      _numeroLotCtrl.text = l.numeroLot;
      _quantiteCtrl.text = l.quantiteInitiale.toStringAsFixed(0);
      _prixAchatCtrl.text = l.prixAchat.toStringAsFixed(0);
      _prixVenteCtrl.text = l.prixVente.toStringAsFixed(0);
      _dateFabrication = l.dateFabrication;
      _dateExpiration = l.dateExpiration;
      _estActif = l.estActif;
      _fournisseurCtrl.text = l.fournisseurNom ?? '';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final meds = context.read<MedicamentProvider>().medicaments;
        final match = meds.where((m) => m.id == l.medicamentId).firstOrNull;
        if (match != null) setState(() => _medicamentSelectionne = match);
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedicamentProvider>().loadMedicaments();
    });
  }

  @override
  void dispose() {
    _numeroLotCtrl.dispose();
    _quantiteCtrl.dispose();
    _prixAchatCtrl.dispose();
    _prixVenteCtrl.dispose();
    _fournisseurCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool fabrication) async {
    final initial = fabrication ? _dateFabrication : _dateExpiration;
    final picked = await showDatePicker(
      context: context, initialDate: initial,
      firstDate: fabrication ? DateTime(2020) : _dateFabrication, lastDate: DateTime(2040),
    );
    if (picked != null) {
      setState(() {
        if (fabrication) {
          _dateFabrication = picked;
          if (_dateExpiration.isBefore(picked)) _dateExpiration = picked.add(const Duration(days: 365));
        } else {
          _dateExpiration = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_medicamentSelectionne == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sélectionnez un médicament')));
      return;
    }
    setState(() => _isSaving = true);
    final data = {
      'medicament': _medicamentSelectionne!.id,
      'numero_lot': _numeroLotCtrl.text.trim(),
      'quantite': double.parse(_quantiteCtrl.text),
      'quantite_initiale': double.parse(_quantiteCtrl.text),
      'date_fabrication': DateFormat('yyyy-MM-dd').format(_dateFabrication),
      'date_expiration': DateFormat('yyyy-MM-dd').format(_dateExpiration),
      'prix_achat': double.tryParse(_prixAchatCtrl.text) ?? 0,
      'prix_vente': double.tryParse(_prixVenteCtrl.text) ?? 0,
      'fournisseur_nom': _fournisseurCtrl.text.trim().isNotEmpty ? _fournisseurCtrl.text.trim() : null,
      'est_actif': _estActif,
    };
    final provider = context.read<LotProvider>();
    final success = widget.lot == null
        ? await provider.createLot(data)
        : await provider.updateLot(widget.lot!.id, data);
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.lot == null ? 'Lot créé !' : 'Lot mis à jour !'), backgroundColor: AppTheme.successColor));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.error ?? 'Erreur'), backgroundColor: AppTheme.errorColor));
    }
  }

  @override
  Widget build(BuildContext context) {
    final medProv = context.watch<MedicamentProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(widget.lot == null ? 'Nouveau lot' : 'Modifier lot')),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  DropdownButtonFormField<Medicament>(
                    value: _medicamentSelectionne,
                    decoration: const InputDecoration(labelText: 'Médicament *', border: OutlineInputBorder()),
                    isExpanded: true,
                    items: medProv.medicaments.where((m) => m.estActif).map((m) => DropdownMenuItem(value: m, child: Text('${m.nom} (${m.codeBarre ?? '-'})'))).toList(),
                    onChanged: (v) => setState(() => _medicamentSelectionne = v),
                    validator: (v) => v == null ? 'Requis' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(controller: _numeroLotCtrl, decoration: const InputDecoration(labelText: 'Numéro de lot *', border: OutlineInputBorder()), validator: (v) => v!.trim().isEmpty ? 'Requis' : null),
                  const SizedBox(height: 16),
                  TextFormField(controller: _quantiteCtrl, decoration: const InputDecoration(labelText: 'Quantité initiale *', border: OutlineInputBorder()), keyboardType: TextInputType.number,
                    validator: (v) { if (v!.trim().isEmpty) return 'Requis'; final q = double.tryParse(v); if (q == null || q <= 0) return 'Invalide'; return null; },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: InkWell(onTap: () => _pickDate(true), child: InputDecorator(decoration: const InputDecoration(labelText: 'Fabrication *', border: OutlineInputBorder()), child: Text(DateFormat('dd/MM/yyyy').format(_dateFabrication))))),
                      const SizedBox(width: 12),
                      Expanded(child: InkWell(onTap: () => _pickDate(false), child: InputDecorator(decoration: const InputDecoration(labelText: 'Expiration *', border: OutlineInputBorder()), child: Text(DateFormat('dd/MM/yyyy').format(_dateExpiration))))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: _prixAchatCtrl, decoration: const InputDecoration(labelText: 'Prix achat', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(child: TextFormField(controller: _prixVenteCtrl, decoration: const InputDecoration(labelText: 'Prix vente', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(controller: _fournisseurCtrl, decoration: const InputDecoration(labelText: 'Fournisseur', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  SwitchListTile(title: const Text('Lot actif'), value: _estActif, onChanged: (v) => setState(() => _estActif = v), contentPadding: EdgeInsets.zero),
                  const SizedBox(height: 24),
                  SizedBox(height: 48, child: ElevatedButton(onPressed: _save, child: Text(widget.lot == null ? 'Créer' : 'Mettre à jour', style: const TextStyle(fontSize: 16)))),
                ],
              ),
            ),
    );
  }
}