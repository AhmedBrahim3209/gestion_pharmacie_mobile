import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../../config/api_config.dart';
import '../../config/app_theme.dart';
import '../../config/currency_helper.dart';
import '../../providers/abonnement_provider.dart';
import '../../widgets/loading_widget.dart';

class CapturesScreen extends StatefulWidget {
  const CapturesScreen({super.key});

  @override
  State<CapturesScreen> createState() => _CapturesScreenState();
}

class _CapturesScreenState extends State<CapturesScreen> {
  final _searchCtrl = TextEditingController();
  List<dynamic> _captures = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _charger());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _downloadCapture(String imagePath, String nomPharmacie) async {
    try {
      final url = '${ApiConfig.baseUrl.replaceAll('/api', '/media')}$imagePath';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final fileName = 'capture_${nomPharmacie.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Téléchargée: $fileName'),
            behavior: SnackBarBehavior.floating,
          ));
          await OpenFile.open(file.path);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur téléchargement: $e'),
          backgroundColor: AppTheme.errorColor,
        ));
      }
    }
  }

  Future<void> _charger() async {
    setState(() => _isLoading = true);
    try {
      final prov = context.read<AbonnementProvider>();
      final data = await prov.getCaptures();
      if (mounted) setState(() => _captures = data ?? []);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  List<dynamic> get _filtered {
    if (_searchCtrl.text.isEmpty) return _captures;
    final q = _searchCtrl.text.toLowerCase();
    return _captures.where((c) =>
      '${c['pharmacie_nom']} ${c['reference'] ?? ''} ${c['transaction_id'] ?? ''}'.toLowerCase().contains(q)
    ).toList();
  }

  double get _totalMontant => _filtered.fold(0.0, (s, c) => s + ((c['montant'] as num?)?.toDouble() ?? 0));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Captures de transfert')),
      body: _isLoading
          ? const LoadingWidget()
          : RefreshIndicator(
              onRefresh: _charger,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Text('${_captures.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                Text('Total captures', style: TextStyle(color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Text('${_totalMontant.toStringAsFixed(0)} ${AppCurrency.symbol}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                Text('Montant total', style: TextStyle(color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Rechercher par pharmacie, référence...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  if (_filtered.isEmpty)
                    Center(child: Padding(padding: const EdgeInsets.all(32), child: Text('Aucune capture trouvée.', style: TextStyle(color: Colors.grey.shade500))))
                  else
                    ..._filtered.map((c) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(c['pharmacie_nom'] ?? 'Pharmacie', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _statutColor(c['statut']).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(_statutLabel(c['statut']), style: TextStyle(fontSize: 10, color: _statutColor(c['statut']), fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('Tel: ${c['pharmacie_telephone'] ?? '-'}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)), child: Text('${(c['montant'] as num?)?.toDouble() ?? 0} ${AppCurrency.symbol}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)), child: Text(c['mode_paiement'] ?? '-', style: const TextStyle(fontSize: 11))),
                                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)), child: Text(c['plan'] ?? '-', style: const TextStyle(fontSize: 11))),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('Date: ${c['date_paiement'] ?? '-'}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                            Text('Réf: ${c['reference'] ?? '-'}  |  TXN: ${c['transaction_id'] ?? '-'}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                            if (c['capture_transfer'] != null) ...[
                              const SizedBox(height: 8),
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      '${ApiConfig.baseUrl.replaceAll('/api', '/media')}${c['capture_transfer']}',
                                      height: 160,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        height: 160,
                                        color: Colors.grey.shade100,
                                        child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.download, color: Colors.white, size: 20),
                                        onPressed: () => _downloadCapture(c['capture_transfer'], c['pharmacie_nom'] ?? 'pharmacie'),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    )),
                ],
              ),
            ),
    );
  }

  Color _statutColor(String? statut) {
    switch (statut) {
      case 'valide': return AppTheme.successColor;
      case 'en_attente': return AppTheme.warningColor;
      case 'echoue': return AppTheme.errorColor;
      default: return Colors.grey;
    }
  }

  String _statutLabel(String? statut) {
    switch (statut) {
      case 'valide': return 'Validé';
      case 'en_attente': return 'En attente';
      case 'echoue': return 'Échoué';
      default: return statut ?? '-';
    }
  }
}