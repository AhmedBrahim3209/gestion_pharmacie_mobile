import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/loading_widget.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  Timer? _refreshTimer;
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications();
    });
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) context.read<NotificationProvider>().loadNotifications();
    });
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<NotificationProvider>().loadNextPage();
    }
  }

  IconData _typeIcon(String? type) {
    switch (type) {
      case 'vente': return Icons.receipt;
      case 'stock': return Icons.inventory_2;
      case 'stock_faible': return Icons.inventory_2;
      case 'stock_rupture': return Icons.error_outline;
      case 'expiration': return Icons.warning_amber_rounded;
      case 'expire_bientot': return Icons.hourglass_bottom;
      case 'system': return Icons.settings;
      case 'message': return Icons.message;
      case 'abonnement': return Icons.subscriptions;
      case 'paiement': return Icons.payments;
      case 'pharmacie': return Icons.local_pharmacy;
      case 'compte': return Icons.person;
      default: return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Notifications'),
            if (provider.unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppTheme.errorColor, borderRadius: BorderRadius.circular(12)),
                child: Text('${provider.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
        actions: [
          if (provider.unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: 'Tout marquer comme lu',
              onPressed: () => provider.markAllRead(),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); provider.setSearchQuery(''); })
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade50,
                isDense: true,
              ),
              onChanged: (v) => provider.setSearchQuery(v),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _filterChip('Tous', 'toutes', provider.statusFilter, provider.setStatusFilter),
                _filterChip('Non lues', 'non_lues', provider.statusFilter, provider.setStatusFilter),
                _filterChip('Lues', 'lues', provider.statusFilter, provider.setStatusFilter),
                const SizedBox(width: 8),
                _filterChip('Type: Stock', 'stock', provider.typeFilter, provider.setTypeFilter),
                _filterChip('Type: Paiement', 'paiement', provider.typeFilter, provider.setTypeFilter),
                _filterChip('Type: Système', 'system', provider.typeFilter, provider.setTypeFilter),
              ],
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? const LoadingWidget()
                : RefreshIndicator(
                    onRefresh: () => provider.loadNotifications(),
                    child: provider.notifications.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                              Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade300),
                                    const SizedBox(height: 16),
                                    Text('Aucune notification', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: provider.notifications.length + (provider.hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == provider.notifications.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                                );
                              }
                              final n = provider.notifications[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                color: n.estLue ? Colors.white : AppTheme.accentColor.withValues(alpha: 0.05),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    if (!n.estLue) provider.markAsRead(n.id);
                                  },
                                  onLongPress: () {
                                    showDialog(context: context, builder: (ctx) => AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      title: const Text('Notification'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(n.titre, style: const TextStyle(fontWeight: FontWeight.bold)),
                                          if (n.message != null) ...[const SizedBox(height: 8), Text(n.message!)],
                                          if (n.typeNotification != null) ...[const SizedBox(height: 4), Text('Type: ${n.typeNotification}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500))],
                                          if (n.date != null) Text('Date: ${n.date}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
                                        TextButton(onPressed: () {
                                          Navigator.pop(ctx);
                                          provider.deleteNotification(n.id);
                                        }, child: const Text('Supprimer', style: TextStyle(color: AppTheme.errorColor))),
                                      ],
                                    ));
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: n.estLue ? Colors.grey.shade100 : AppTheme.accentColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(_typeIcon(n.typeNotification), color: n.estLue ? Colors.grey : AppTheme.primaryColor, size: 22),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(n.titre, style: TextStyle(fontWeight: n.estLue ? FontWeight.w500 : FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
                                                  ),
                                                  if (!n.estLue)
                                                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle)),
                                                ],
                                              ),
                                              if (n.message != null) ...[
                                                const SizedBox(height: 4),
                                                Text(n.message!, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                                              ],
                                              if (n.date != null) ...[
                                                const SizedBox(height: 4),
                                                Text(n.date!, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                                              ],
                                            ],
                                          ),
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
    );
  }

  Widget _filterChip(String label, String value, String currentValue, void Function(String) onChanged) {
    final selected = currentValue == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 11, color: selected ? Colors.white : Colors.grey.shade700)),
        selected: selected,
        selectedColor: AppTheme.primaryColor,
        backgroundColor: Colors.grey.shade100,
        onSelected: (_) => onChanged(value),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
