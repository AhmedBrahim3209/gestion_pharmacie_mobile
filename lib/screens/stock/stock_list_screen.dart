import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/stock_provider.dart';
import '../../widgets/loading_widget.dart';
import 'ajuster_stock_screen.dart';

class StockListScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  const StockListScreen({super.key, this.onMenuTap});

  @override
  State<StockListScreen> createState() => _StockListScreenState();
}

class _StockListScreenState extends State<StockListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StockProvider>().loadStock();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StockProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: widget.onMenuTap),
        title: const Text('Stock'),
      ),
      body: provider.isLoading
          ? const LoadingWidget()
          : provider.stockItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('Aucun stock', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                      if (provider.error != null) ...[
                        const SizedBox(height: 12),
                        Text(provider.error!, style: const TextStyle(color: AppTheme.errorColor, fontSize: 13)),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Réessayer'),
                          onPressed: () => context.read<StockProvider>().loadStock(),
                        ),
                      ],
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => provider.loadStock(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: provider.stockItems.length,
                    itemBuilder: (context, index) {
                      final item = provider.stockItems[index];
                      final bool isRupture = item.quantite <= 0;
                      final bool isACommander = item.quantite > 0 && item.quantite <= item.seuilMin * 0.5;
                      final bool isAttention = item.quantite > 0 && item.quantite <= item.seuilMin && !isACommander;

                      String stockLabel;
                      Color stockColor;
                      IconData stockIcon;
                      if (isRupture) {
                        stockLabel = 'Rupture';
                        stockColor = AppTheme.errorColor;
                        stockIcon = Icons.error_outline;
                      } else if (isACommander) {
                        stockLabel = 'À commander';
                        stockColor = Colors.orange;
                        stockIcon = Icons.shopping_cart_outlined;
                      } else if (isAttention) {
                        stockLabel = 'Attention';
                        stockColor = AppTheme.warningColor;
                        stockIcon = Icons.warning_amber_rounded;
                      } else {
                        stockLabel = 'Bon';
                        stockColor = AppTheme.successColor;
                        stockIcon = Icons.check_circle_outline;
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AjusterStockScreen(stockId: item.id, medicamentNom: item.medicamentNom, quantiteActuelle: item.quantite))),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: stockColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(stockIcon, color: stockColor, size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.medicamentNom, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.textPrimary)),
                                      const SizedBox(height: 4),
                                      Text('Stock: ${item.quantite.toStringAsFixed(0)}  •  Seuil: ${item.seuilMin.toStringAsFixed(0)}${item.numeroLot != null ? '  •  Lot: ${item.numeroLot}' : ''}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: stockColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(stockLabel, style: TextStyle(fontSize: 11, color: stockColor, fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
