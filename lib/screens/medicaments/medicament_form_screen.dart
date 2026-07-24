import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_theme.dart';
import '../../models/medicament.dart';
import '../../providers/medicament_provider.dart';
import '../../services/api_service.dart';

class MedicamentFormScreen extends StatefulWidget {
  final Medicament? medicament;
  const MedicamentFormScreen({super.key, this.medicament});

  @override
  State<MedicamentFormScreen> createState() => _MedicamentFormScreenState();
}

class _MedicamentFormScreenState extends State<MedicamentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomCtrl;
  late TextEditingController _descriptionCtrl;
  late TextEditingController _codeBarreCtrl;
  late TextEditingController _prixAchatCtrl;
  late TextEditingController _prixVenteCtrl;
  late TextEditingController _dateExpCtrl;
  int? _categorieId;
  File? _imageFile;

  bool get isEditing => widget.medicament != null;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _scanCode() async {
    try {
      final result = await BarcodeScanner.scan();
      if (result.rawContent.isNotEmpty) {
        _codeBarreCtrl.text = result.rawContent;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur de scan: $e'), backgroundColor: AppTheme.errorColor));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    final m = widget.medicament;
    _nomCtrl = TextEditingController(text: m?.nom ?? '');
    _descriptionCtrl = TextEditingController(text: m?.description ?? '');
    _codeBarreCtrl = TextEditingController(text: m?.codeBarre ?? '');
    _prixAchatCtrl = TextEditingController(text: m?.prixAchat?.toString() ?? '');
    _prixVenteCtrl = TextEditingController(text: m?.prixVente.toString() ?? '');
    _dateExpCtrl = TextEditingController(text: m?.dateExpiration != null ? '${m!.dateExpiration!.day}/${m.dateExpiration!.month}/${m.dateExpiration!.year}' : '');
    _categorieId = m?.categorieId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedicamentProvider>().loadCategories();
    });
  }

  Widget _imagePlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined, size: 32, color: Colors.grey.shade400),
          const SizedBox(height: 4),
          Text('Ajouter une image', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _descriptionCtrl.dispose();
    _codeBarreCtrl.dispose();
    _prixAchatCtrl.dispose();
    _prixVenteCtrl.dispose();
    _dateExpCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    DateTime? dateExp;
    if (_dateExpCtrl.text.isNotEmpty) {
      final parts = _dateExpCtrl.text.split('/');
      if (parts.length == 3) {
        dateExp = DateTime.tryParse('${parts[2]}-${parts[1]}-${parts[0]}');
      }
    }
    final prixVente = double.tryParse(_prixVenteCtrl.text);
    if (prixVente == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prix de vente invalide'), backgroundColor: AppTheme.errorColor));
      return;
    }
    final data = {
      'nom': _nomCtrl.text.trim(),
      'description': _descriptionCtrl.text.trim(),
      'code_barre': _codeBarreCtrl.text.trim(),
      'prix_achat': double.tryParse(_prixAchatCtrl.text),
      'prix_vente': prixVente,
      'categorie': _categorieId,
      if (!isEditing) 'unite': 'unité',
      'date_expiration': dateExp?.toIso8601String().split('T')[0],
      if (!isEditing) 'est_actif': true,
    };
    final provider = context.read<MedicamentProvider>();
    bool success;
    if (isEditing) {
      success = await provider.updateMedicament(widget.medicament!.id, data);
    } else {
      success = await provider.createMedicament(data);
    }
    if (success && _imageFile != null) {
      try {
        final medId = isEditing ? widget.medicament!.id : (await ApiService().getMedicaments()).last['id'] as int;
        await ApiService().uploadFile('/medicaments/$medId/upload-image/', _imageFile!);
      } catch (_) {}
    }
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
    } else {
      final err = context.read<MedicamentProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'Erreur lors de l\'enregistrement'), backgroundColor: AppTheme.errorColor));
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<MedicamentProvider>().categories;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Modifier Médicament' : 'Nouveau Médicament'), actions: [
        TextButton(onPressed: _save, child: const Text('Enregistrer')),
      ]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              InkWell(
                onTap: _pickImage,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_imageFile!, width: double.infinity, height: 120, fit: BoxFit.cover),
                        )
                      : widget.medicament?.image != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(widget.medicament!.image!, width: double.infinity, height: 120, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _imagePlaceholder()),
                            )
                          : _imagePlaceholder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(controller: _nomCtrl, decoration: const InputDecoration(labelText: 'Nom', border: OutlineInputBorder()), validator: (v) => v == null || v.isEmpty ? 'Requis' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _descriptionCtrl, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()), maxLines: 3),
              const SizedBox(height: 16),
              TextFormField(controller: _codeBarreCtrl, decoration: InputDecoration(labelText: 'Code barre', border: OutlineInputBorder(), suffixIcon: IconButton(icon: const Icon(Icons.qr_code_scanner), onPressed: _scanCode))),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _categorieId,
                decoration: const InputDecoration(labelText: 'Catégorie', border: OutlineInputBorder()),
                items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nom))).toList(),
                onChanged: (v) => setState(() => _categorieId = v),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _prixAchatCtrl, decoration: const InputDecoration(labelText: 'Prix achat', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: TextFormField(controller: _prixVenteCtrl, decoration: const InputDecoration(labelText: 'Prix vente *', border: OutlineInputBorder()), keyboardType: TextInputType.number, validator: (v) => v == null || v.isEmpty ? 'Requis' : null)),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(controller: _dateExpCtrl, decoration: const InputDecoration(labelText: 'Date expiration (jj/mm/aaaa)', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_month)), readOnly: true, onTap: () async {
                final date = await showDatePicker(context: context, firstDate: DateTime(2000), lastDate: DateTime(2100), initialDate: widget.medicament?.dateExpiration ?? DateTime.now());
                if (date != null) _dateExpCtrl.text = '${date.day}/${date.month}/${date.year}';
              }),
            ],
          ),
        ),
      ),
    );
  }
}
