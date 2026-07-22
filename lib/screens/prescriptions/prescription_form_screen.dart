import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/prescription_provider.dart';
import '../../providers/client_provider.dart';
import '../../providers/medicament_provider.dart';

class PrescriptionFormScreen extends StatefulWidget {
  const PrescriptionFormScreen({super.key});

  @override
  State<PrescriptionFormScreen> createState() => _PrescriptionFormScreenState();
}

class _PrescriptionFormScreenState extends State<PrescriptionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _clientId;
  final _medecinCtrl = TextEditingController();
  final _specialiteCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _datePrescriptionCtrl = TextEditingController();
  final _dateValiditeCtrl = TextEditingController();
  DateTime? _datePrescription;
  DateTime? _dateValidite;
  final _lignes = <_LigneOrdonnance>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientProvider>().loadClients();
      context.read<MedicamentProvider>().loadMedicaments();
    });
  }

  @override
  void dispose() {
    _medecinCtrl.dispose();
    _specialiteCtrl.dispose();
    _notesCtrl.dispose();
    _datePrescriptionCtrl.dispose();
    _dateValiditeCtrl.dispose();
    super.dispose();
  }

  void _updateDatePrescription(DateTime? d) {
    setState(() {
      _datePrescription = d;
      _datePrescriptionCtrl.text = d != null ? '${d.day}/${d.month}/${d.year}' : '';
    });
  }

  void _updateDateValidite(DateTime? d) {
    setState(() {
      _dateValidite = d;
      _dateValiditeCtrl.text = d != null ? '${d.day}/${d.month}/${d.year}' : '';
    });
  }

  void _ajouterLigne() {
    setState(() => _lignes.add(_LigneOrdonnance(medicamentId: null, quantite: 1, posologie: '', duree: '')));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_clientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sélectionnez un client')));
      return;
    }
    if (_lignes.isEmpty || _lignes.any((l) => l.medicamentId == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ajoutez au moins un médicament')));
      return;
    }
    final data = {
      'client': _clientId,
      'medecin_nom': _medecinCtrl.text.trim(),
      'medecin_specialite': _specialiteCtrl.text.trim(),
      'date_prescription': _datePrescription?.toIso8601String().split('T').first,
      'date_validite': _dateValidite?.toIso8601String().split('T').first,
      'notes': _notesCtrl.text.trim(),
      'lignes': _lignes.map((l) => {
        'medicament': l.medicamentId,
        'quantite': l.quantite,
        'posologie': l.posologie,
        'duree': l.duree,
      }).toList(),
    };
    final prescProv = context.read<PrescriptionProvider>();
    final success = await prescProv.createPrescription(data);
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(prescProv.error ?? 'Erreur lors de la création'), backgroundColor: AppTheme.errorColor));
    }
  }

  @override
  Widget build(BuildContext context) {
    final clients = context.watch<ClientProvider>().clients;
    final medicaments = context.watch<MedicamentProvider>().medicaments;

    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle Prescription'), actions: [
        TextButton(onPressed: _save, child: const Text('Enregistrer')),
      ]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<int>(
                value: _clientId,
                decoration: const InputDecoration(labelText: 'Client *', border: OutlineInputBorder()),
                items: clients.map((c) => DropdownMenuItem(value: c.id, child: Text(c.fullName))).toList(),
                onChanged: (v) => setState(() => _clientId = v),
              ),
              const SizedBox(height: 16),
              TextFormField(controller: _medecinCtrl, decoration: const InputDecoration(labelText: 'Nom du médecin', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextFormField(controller: _specialiteCtrl, decoration: const InputDecoration(labelText: 'Spécialité', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: 'Date prescription', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_month)),
                      readOnly: true,
                      controller: _datePrescriptionCtrl,
                      onTap: () async {
                        final d = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2100));
                        if (d != null) _updateDatePrescription(d);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: 'Validité', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_month)),
                      readOnly: true,
                      controller: _dateValiditeCtrl,
                      onTap: () async {
                        final d = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2100));
                        if (d != null) _updateDateValidite(d);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(controller: _notesCtrl, decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()), maxLines: 3),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Médicaments', style: Theme.of(context).textTheme.titleMedium),
                  TextButton.icon(icon: const Icon(Icons.add), label: const Text('Ajouter'), onPressed: _ajouterLigne),
                ],
              ),
              ..._lignes.asMap().entries.map((entry) {
                final i = entry.key;
                final l = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        DropdownButtonFormField<int>(
                          value: l.medicamentId,
                          decoration: const InputDecoration(labelText: 'Médicament *', border: OutlineInputBorder(), isDense: true),
                          items: medicaments.map((m) => DropdownMenuItem(value: m.id, child: Text(m.nom))).toList(),
                          onChanged: (v) => setState(() => l.medicamentId = v),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Qté', border: OutlineInputBorder(), isDense: true), keyboardType: TextInputType.number, initialValue: l.quantite.toString(), onChanged: (v) => l.quantite = double.tryParse(v) ?? 1)),
                            const SizedBox(width: 8),
                            Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Posologie', border: OutlineInputBorder(), isDense: true), initialValue: l.posologie, onChanged: (v) => l.posologie = v)),
                            const SizedBox(width: 8),
                            Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Durée', border: OutlineInputBorder(), isDense: true), initialValue: l.duree, onChanged: (v) => l.duree = v)),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                            label: const Text('Retirer', style: TextStyle(color: Colors.red, fontSize: 12)),
                            onPressed: () => setState(() => _lignes.removeAt(i)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _LigneOrdonnance {
  int? medicamentId;
  double quantite;
  String posologie;
  String duree;

  _LigneOrdonnance({
    required this.medicamentId,
    required this.quantite,
    required this.posologie,
    required this.duree,
  });
}
