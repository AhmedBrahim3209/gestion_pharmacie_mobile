import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/achat_provider.dart';
import '../../widgets/loading_widget.dart';
import 'achat_detail_screen.dart';
import 'nouvel_achat_screen.dart';
import 'fournisseurs_screen.dart';

class AchatsListScreen extends StatefulWidget {
  const AchatsListScreen({super.key});

  @override
  State<AchatsListScreen> createState() => _AchatsListScreenState();
}

class _AchatsListScreenState extends State<AchatsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AchatProvider>().loadAchats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AchatProvider>();

    return Scaffold(
      body: provider.isLoading
          ? const LoadingWidget()
          : provider.achats.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('Aucun achat', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => provider.loadAchats(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: provider.achats.length,
                    itemBuilder: (context, index) {
                      final achat = provider.achats[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AchatDetailScreen(achat: achat))),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.brown.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.shopping_bag, color: Colors.brown, size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Achat #${achat.numero}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.textPrimary)),
                                      const SizedBox(height: 4),
                                      Text('${achat.montantTotal} CFA  •  ${achat.fournisseurNom ?? "N/A"}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(achat.statut, style: TextStyle(fontSize: 11, color: AppTheme.primaryColor, fontWeight: FontWeight.w500)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(heroTag: 'fournisseurs', child: const Icon(Icons.business), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FournisseursScreen()))),
          const SizedBox(height: 8),
          FloatingActionButton(heroTag: 'add_achat', child: const Icon(Icons.add), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NouvelAchatScreen()))),
        ],
      ),
    );
  }
}
