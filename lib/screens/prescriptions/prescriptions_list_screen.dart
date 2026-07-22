import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/prescription.dart';
import '../../providers/prescription_provider.dart';
import '../../services/api_service.dart';
import '../../services/pdf_service.dart';
import '../../widgets/loading_widget.dart';
import 'prescription_form_screen.dart';

class PrescriptionsListScreen extends StatefulWidget {
  const PrescriptionsListScreen({super.key});

  @override
  State<PrescriptionsListScreen> createState() => _PrescriptionsListScreenState();
}

class _PrescriptionsListScreenState extends State<PrescriptionsListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PrescriptionProvider>().loadPrescriptions();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrescriptionProvider>();
    final filtered = provider.prescriptions.where((p) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return p.numero.toLowerCase().contains(q) || (p.clientNom?.toLowerCase().contains(q) ?? false);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Prescriptions')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Rechercher par patient ou numéro...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade50,
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? const LoadingWidget()
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.description_outlined, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text('Aucune prescription', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => provider.loadPrescriptions(),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final p = filtered[index];
                            final isServie = p.estServie;
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _showDetail(context, p),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isServie ? AppTheme.successColor.withValues(alpha: 0.1) : AppTheme.warningColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(isServie ? Icons.check_circle : Icons.pending, color: isServie ? AppTheme.successColor : AppTheme.warningColor, size: 24),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(p.numero, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.textPrimary)),
                                            const SizedBox(height: 4),
                                            Text('${p.clientNom ?? "N/A"}  •  Dr. ${p.medecinNom ?? "N/A"}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isServie ? AppTheme.successColor.withValues(alpha: 0.1) : AppTheme.warningColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(isServie ? 'Servie' : 'Non servie', style: TextStyle(fontSize: 11, color: isServie ? AppTheme.successColor : AppTheme.warningColor, fontWeight: FontWeight.w500)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrescriptionFormScreen())),
      ),
    );
  }

  void _showDetail(BuildContext context, Prescription p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(p.numero, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            _row('Patient', p.clientNom ?? 'N/A'),
            const Divider(height: 1), _row('Médecin', p.medecinNom ?? 'N/A'),
            const Divider(height: 1), _row('Spécialité', p.medecinSpecialite ?? 'N/A'),
            const Divider(height: 1), _row('Date prescription', p.datePrescription ?? 'N/A'),
            const Divider(height: 1), _row('Validité', p.dateValidite ?? 'N/A'),
            const Divider(height: 1), _row('Statut', p.estServie ? 'Servie' : 'Non servie'),
            if (p.notes != null && p.notes!.isNotEmpty) ...[const Divider(height: 1), _row('Notes', p.notes!)],
            if (p.lignes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Médicaments:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              ...p.lignes.map((l) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(children: [
                  Icon(Icons.medication, size: 16, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text('${l.medicamentNom} (${l.quantite})${l.posologie != null ? " - ${l.posologie}" : ""}', style: TextStyle(color: Colors.grey.shade700)),
                ]),
              )),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.picture_as_pdf, color: AppTheme.primaryColor),
                  label: const Text('PDF', style: TextStyle(color: AppTheme.primaryColor)),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    Prescription presc = p;
                    if (p.lignes.isEmpty) {
                      try {
                        final detail = await ApiService().getPrescription(p.id);
                        presc = Prescription.fromJson(detail);
                      } catch (_) {}
                    }
                    final pdf = await PdfService.generatePrescription(presc);
                    if (context.mounted) {
                      await PdfService.saveAndOpen(pdf, 'prescription_${presc.numero}.pdf');
                    }
                  },
                ),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
                  label: const Text('Supprimer', style: TextStyle(color: AppTheme.errorColor)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _confirmDelete(p.id);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(color: Colors.grey.shade600)), Text(value, style: const TextStyle(fontWeight: FontWeight.w500))]),
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmer'),
        content: const Text('Supprimer cette prescription ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<PrescriptionProvider>().deletePrescription(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
