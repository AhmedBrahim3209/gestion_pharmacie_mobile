import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/client_provider.dart';
import '../../widgets/loading_widget.dart';
import 'client_form_screen.dart';
import 'client_detail_screen.dart';

class ClientsListScreen extends StatefulWidget {
  const ClientsListScreen({super.key});

  @override
  State<ClientsListScreen> createState() => _ClientsListScreenState();
}

class _ClientsListScreenState extends State<ClientsListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientProvider>().loadClients();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClientProvider>();
    final filtered = provider.clients.where((c) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return c.fullName.toLowerCase().contains(q) ||
          (c.telephone?.toLowerCase().contains(q) ?? false) ||
          (c.email?.toLowerCase().contains(q) ?? false);
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Rechercher par nom, téléphone ou email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); setState(() => _query = ''); }) : null,
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
                            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(_query.isNotEmpty ? 'Aucun résultat' : 'Aucun client', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => provider.loadClients(),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                      final client = filtered[index];
                      final isFidele = client.isFidele;
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClientDetailScreen(client: client))),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: (isFidele ? AppTheme.warningColor : AppTheme.primaryColor).withValues(alpha: 0.1),
                                  child: Text(client.fullName.isNotEmpty ? client.fullName[0].toUpperCase() : '?', style: TextStyle(color: isFidele ? AppTheme.warningColor : AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(child: Text(client.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.textPrimary))),
                                          if (isFidele)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(color: AppTheme.warningColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                              child: const Text('Fidèle', style: TextStyle(fontSize: 10, color: AppTheme.warningColor, fontWeight: FontWeight.w600)),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${client.telephone ?? client.email ?? ''}  •  ${client.nombreAchats} achat(s)',
                                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right, color: Colors.grey.shade400),
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
        child: const Icon(Icons.person_add),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientFormScreen())),
      ),
    );
  }
}
