import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import '../../models/medicament.dart';
import '../../models/vente.dart';
import '../../config/app_theme.dart';
import '../../config/currency_helper.dart';
import '../../providers/medicament_provider.dart';
import '../../providers/vente_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../services/api_service.dart';
import '../../services/pdf_service.dart';
import '../../widgets/loading_widget.dart';

class NouvelleVenteScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  const NouvelleVenteScreen({super.key, this.onMenuTap});

  @override
  State<NouvelleVenteScreen> createState() => _NouvelleVenteScreenState();
}

class _NouvelleVenteScreenState extends State<NouvelleVenteScreen> {
  final _lignes = <_LigneVente>[];
  final _searchCtrl = TextEditingController();
  String _query = '';
  int? _categorieFilter;
  String _sortBy = 'nom';
  double _remise = 0;
  double _tauxTva = 0;
  String _modePaiement = 'Especes';
  String _montantRecu = '';

  static const _modesPaiement = ['Especes', 'Carte', 'Cheque', 'Virement', 'Mobile'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final medProv = context.read<MedicamentProvider>();
      medProv.loadMedicaments();
      medProv.loadCategories();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  double get _totalHt => _lignes.fold<double>(0.0, (sum, l) => sum + (l.medicament.prixVente * l.quantite));
  double get _totalTva => _totalHt * (_tauxTva / 100);
  double get _totalTtc => _totalHt + _totalTva;
  double get _net => _totalTtc - _remise;
  double get _monnaie {
    final recu = double.tryParse(_montantRecu) ?? 0;
    return recu > _net ? recu - _net : 0;
  }
  int get _nbArticles => _lignes.fold(0, (sum, l) => sum + l.quantite);

  DateTime? _lastTap;
  void _ajouterLigne(Medicament med) {
    final now = DateTime.now();
    final isDoubleTap = _lastTap != null && now.difference(_lastTap!).inMilliseconds < 400;
    _lastTap = now;
    final qte = isDoubleTap ? 2 : 1;
    setState(() {
      final existing = _lignes.where((l) => l.medicament.id == med.id).firstOrNull;
      if (existing != null) {
        existing.quantite += qte;
      } else {
        _lignes.add(_LigneVente(medicament: med, quantite: qte));
      }
    });
  }

  void _ouvrirPanier() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollCtrl) => _buildCartSheet(ctx, scrollCtrl),
      ),
    );
  }

  Future<void> _finaliser() async {
    if (_lignes.isEmpty) return;

    final api = ApiService();
    final lignesPayload = _lignes.map((l) => {
      'medicament': l.medicament.id,
      'quantite': l.quantite,
      'prix_unitaire': l.medicament.prixVente,
    }).toList();

    final data = {
      'lignes': lignesPayload,
      'remise': double.parse(_remise.toStringAsFixed(2)),
      'montant_recu': double.tryParse(_montantRecu),
    };
    final venteProv = context.read<VenteProvider>();
    final vente = await venteProv.createVente(data);
    if (!mounted) return;

    if (vente == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(venteProv.error ?? 'Erreur lors de la création de la vente'),
        backgroundColor: AppTheme.errorColor,
      ));
      return;
    }

    if (_modePaiement.isNotEmpty && _montantRecu.isNotEmpty) {
      try {
        await api.addVentePayment(vente.id, {
          'mode_paiement': _modePaiement.toLowerCase(),
          'montant_paye': double.tryParse(_montantRecu) ?? vente.montantNet,
          'monnaie_rendue': _monnaie,
        });
      } catch (_) {}
    }

    try { if (mounted) context.read<MedicamentProvider>().loadMedicaments(); } catch (_) {}
    try { if (mounted) context.read<DashboardProvider>().loadDashboard(); } catch (_) {}

    if (!mounted) return;

    // Build receipt data from local cart (fallback if API doesn't return lignes)
    final lignesRecu = _lignes.map((l) => LigneRecuData(
      medicamentNom: l.medicament.nom,
      quantite: l.quantite,
      prixUnitaire: l.medicament.prixVente,
    )).toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [Icon(Icons.check_circle, color: Colors.green), SizedBox(width: 8), Text('Vente effectuée')]),
        content: const Text('La vente a été enregistrée avec succès.'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _lignes.clear());
              Navigator.pop(ctx);
            },
            child: const Text('Fermer'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.print, size: 18),
            label: const Text('Imprimer ticket'),
            onPressed: () async {
              setState(() => _lignes.clear());
              Navigator.pop(ctx);
              try {
                Vente ventePourImpression = vente;
                if (vente.lignes.isEmpty) {
                  final detail = await venteProv.getVenteDetail(vente.id);
                  if (detail != null && detail.lignes.isNotEmpty) {
                    ventePourImpression = detail;
                  }
                }
                final pdf = await PdfService.generateSaleReceipt(ventePourImpression, lignesRecu: lignesRecu);
                if (mounted) {
                  await Printing.layoutPdf(onLayout: (_) => pdf);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Erreur d\'impression: $e'),
                    backgroundColor: AppTheme.errorColor,
                  ));
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final medProv = context.watch<MedicamentProvider>();
    final medicaments = medProv.medicaments;
    final categories = medProv.categories;
    final isLoading = medProv.isLoading;
    final filtered = medicaments.where((m) {
      if (_categorieFilter != null && m.categorieId != _categorieFilter) return false;
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return m.nom.toLowerCase().contains(q) || (m.codeBarre?.toLowerCase().contains(q) ?? false);
    }).toList()..sort((a, b) {
      switch (_sortBy) {
        case 'prix': return a.prixVente.compareTo(b.prixVente);
        case 'stock': return (a.stockQuantite ?? 0).compareTo(b.stockQuantite ?? 0);
        default: return a.nom.compareTo(b.nom);
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: widget.onMenuTap),
        title: const Text('Point de vente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir',
            onPressed: () => context.read<MedicamentProvider>().loadMedicaments(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Rechercher un médicament...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () { _searchCtrl.clear(); setState(() => _query = ''); },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade50,
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          if (categories.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _filterChip('Tous', null),
                    ...categories.map((c) => _filterChip(c.nom, c.id)),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Row(
              children: [
                Text('Trier: ', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                _sortChip('Nom', 'nom'),
                const SizedBox(width: 4),
                _sortChip('Prix', 'prix'),
                const SizedBox(width: 4),
                _sortChip('Stock', 'stock'),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => context.read<MedicamentProvider>().loadMedicaments(),
              child: isLoading
                  ? const LoadingWidget()
                  : filtered.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.2,
                            ),
                            Center(
                              child: Column(
                                children: [
                                  Icon(Icons.medication_outlined, size: 48, color: Colors.grey.shade300),
                                  const SizedBox(height: 12),
                                  Text(
                                    _query.isNotEmpty ? 'Aucun résultat' : 'Aucun médicament disponible',
                                    style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
                                  ),
                                  if (medProv.error != null) ...[
                                    const SizedBox(height: 8),
                                    Text(medProv.error!, style: const TextStyle(fontSize: 12, color: AppTheme.errorColor)),
                                    const SizedBox(height: 8),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.refresh, size: 16),
                                      label: const Text('Réessayer'),
                                      onPressed: () => context.read<MedicamentProvider>().loadMedicaments(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(8),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.85,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final med = filtered[index];
                            final isOut = med.isOutOfStock;
                            final isLow = med.isLowStock;
                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isOut
                                      ? AppTheme.errorColor.withValues(alpha: 0.3)
                                      : isLow
                                          ? AppTheme.warningColor.withValues(alpha: 0.3)
                                          : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: isOut ? null : () => _ajouterLigne(med),
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Center(child: Icon(Icons.medication, color: AppTheme.primaryColor, size: 22)),
                                          ),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isOut
                                                  ? AppTheme.errorColor.withValues(alpha: 0.1)
                                                  : isLow
                                                      ? AppTheme.warningColor.withValues(alpha: 0.1)
                                                      : AppTheme.successColor.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              isOut ? 'Rupture' : '${med.stockQuantite?.toStringAsFixed(0) ?? "0"}',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: isOut ? AppTheme.errorColor : isLow ? AppTheme.warningColor : AppTheme.successColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      Text(med.nom, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 2),
                                      if (med.categorieNom != null)
                                        Text(med.categorieNom!, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${med.prixVente.toStringAsFixed(0)} ${AppCurrency.symbol}',
                                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (!isOut)
                                            Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(6)),
                                              child: const Icon(Icons.add, color: Colors.white, size: 16),
                                            ),
                                        ],
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
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, -2))],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _lignes.isEmpty ? 'Panier vide' : '$_nbArticles article(s)',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                          Text(
                            '$_net ${AppCurrency.symbol}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                          ),
                        ],
                      ),
                    ),
                    if (_lignes.isNotEmpty) ...[
                      OutlinedButton.icon(
                        icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                        label: Text('Panier (${_lignes.length})'),
                        onPressed: _ouvrirPanier,
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Finaliser'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _finaliser,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartSheet(BuildContext ctx, ScrollController scrollCtrl) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: ListView(
        controller: scrollCtrl,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Panier', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('$_nbArticles article(s)', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
              const SizedBox(width: 8),
              if (_lignes.isNotEmpty)
                TextButton(
                  onPressed: () { setState(() => _lignes.clear()); Navigator.pop(ctx); },
                  child: const Text('Vider', style: TextStyle(color: AppTheme.errorColor)),
                ),
            ],
          ),
          const Divider(),
          if (_lignes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('Panier vide', style: TextStyle(color: Colors.grey.shade400))),
            )
          else
            ..._lignes.asMap().entries.map((entry) {
              final index = entry.key;
              final l = entry.value;
              final total = l.medicament.prixVente * l.quantite;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.medicament.nom, style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(
                              '${l.medicament.prixVente.toStringAsFixed(0)} ${AppCurrency.symbol} x ${l.quantite.toString()}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Text('${total.toStringAsFixed(0)} ${AppCurrency.symbol}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => setState(() => l.quantite++),
                          ),
                          Text(l.quantite.toString(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setState(() {
                                l.quantite--;
                                if (l.quantite <= 0) _lignes.removeAt(index);
                              });
                            },
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.errorColor),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => setState(() => _lignes.removeAt(index)),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const Divider(),
          _buildCartSummary(),
          const SizedBox(height: 12),
          _buildPaymentSection(),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Finaliser la vente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () { Navigator.pop(ctx); _finaliser(); },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartSummary() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _summaryRow('Total HT', '$_totalHt ${AppCurrency.symbol}'),
          const SizedBox(height: 4),
          _summaryRow(
            'TVA (${_tauxTva.toStringAsFixed(0)}%)',
            '$_totalTva ${AppCurrency.symbol}',
            editable: true,
            hint: 'Taux %',
            onChanged: (v) => setState(() => _tauxTva = double.tryParse(v) ?? 0),
          ),
          const SizedBox(height: 4),
          _summaryRow('Total TTC', '$_totalTtc ${AppCurrency.symbol}'),
          const SizedBox(height: 4),
          _summaryRow(
            'Remise',
            '$_remise ${AppCurrency.symbol}',
            editable: true,
            hint: 'Montant',
            onChanged: (v) => setState(() => _remise = double.tryParse(v) ?? 0),
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('NET À PAYER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('$_net ${AppCurrency.symbol}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool editable = false, String? hint, void Function(String)? onChanged}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
        if (editable)
          SizedBox(
            width: 100,
            child: TextField(
              decoration: InputDecoration(
                isDense: true,
                hintText: hint,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              onChanged: onChanged,
              style: const TextStyle(fontSize: 13),
            ),
          )
          else
            Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
      ],
    );
  }

  Widget _buildPaymentSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mode de paiement', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _modesPaiement.map((mode) {
                final selected = _modePaiement == mode;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(mode, style: TextStyle(fontSize: 12, color: selected ? Colors.white : Colors.grey.shade700)),
                    selected: selected,
                    selectedColor: AppTheme.primaryColor,
                    onSelected: (_) => setState(() => _modePaiement = mode),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }).toList(),
            ),
          ),
          if (_modePaiement == 'Especes') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Montant reçu',
                      hintText: '0',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixText: '${AppCurrency.symbol} ',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => setState(() => _montantRecu = v),
                  ),
                ),
                if (_monnaie > 0) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Monnaie', style: TextStyle(fontSize: 11, color: AppTheme.successColor.withValues(alpha: 0.7))),
                        Text('${_monnaie.toStringAsFixed(0)} ${AppCurrency.symbol}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successColor)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _filterChip(String label, int? id) {
    final selected = _categorieFilter == id;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : Colors.grey.shade700)),
        selected: selected,
        selectedColor: AppTheme.primaryColor,
        backgroundColor: Colors.grey.shade100,
        onSelected: (_) => setState(() => _categorieFilter = id),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _sortChip(String label, String value) {
    final selected = _sortBy == value;
    return GestureDetector(
      onTap: () => setState(() => _sortBy = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppTheme.primaryColor : Colors.grey.shade300, width: selected ? 1.5 : 0.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: selected ? AppTheme.primaryColor : Colors.grey.shade600,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _LigneVente {
  final Medicament medicament;
  int quantite;
  _LigneVente({required this.medicament, required this.quantite});
}
