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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications();
    });
  }

  IconData _typeIcon(String? type) {
    switch (type) {
      case 'vente':
        return Icons.receipt;
      case 'stock':
        return Icons.inventory_2;
      case 'expiration':
        return Icons.warning_amber_rounded;
      case 'system':
        return Icons.settings;
      case 'message':
        return Icons.message;
      default:
        return Icons.notifications;
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
      body: provider.isLoading
          ? const LoadingWidget()
          : RefreshIndicator(
              onRefresh: () => provider.loadNotifications(),
              child: provider.notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text('Aucune notification', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: provider.notifications.length,
                      itemBuilder: (context, index) {
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
    );
  }
}
