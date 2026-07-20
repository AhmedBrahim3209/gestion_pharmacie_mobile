import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import 'dashboard_screen.dart';
import 'medicaments/medicaments_list_screen.dart';
import 'stock/stock_list_screen.dart';
import 'ventes/ventes_list_screen.dart';
import 'ventes/nouvelle_vente_screen.dart';
import 'achats/achats_list_screen.dart';
import 'clients/clients_list_screen.dart';
import 'prescriptions/prescriptions_list_screen.dart';
import 'employes/employes_list_screen.dart';
import 'abonnements/abonnements_list_screen.dart';
import 'notifications/notifications_screen.dart';
import 'rapports/rapports_screen.dart';
import 'parametres/parametres_screen.dart';
import 'chat/chat_screen.dart';
import 'pharmacies/pharmacies_list_screen.dart';
import 'profile/profile_screen.dart';
import 'paiements/paiements_list_screen.dart';
import 'utilisateurs/utilisateurs_list_screen.dart';
import 'achats/fournisseurs_screen.dart';
import 'stock/lot_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user?.isCaissier == true) {
        setState(() => _currentIndex = 0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final user = auth.user;
        final isSuper = user?.isSuperAdmin == true;
        final isAdmin = user?.isAdminPharmacie == true;
        final isEmploye = user?.isEmploye == true;
        final isCaissier = user?.isCaissier == true;

        final screens = _buildScreens(isCaissier, isSuper);

        return Scaffold(
          appBar: AppBar(
            title: Text(_getTitle(isCaissier, isSuper)),
            actions: [
              if (!isCaissier)
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                ),
              IconButton(
                icon: CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(user?.username[0].toUpperCase() ?? '?', style: const TextStyle(fontSize: 12, color: Colors.white)),
                ),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
              ),
            ],
          ),
          drawer: Drawer(
            child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                      ),
                    ),
                    child: DrawerHeader(
                      margin: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            child: Text(user?.username[0].toUpperCase() ?? '?', style: const TextStyle(fontSize: 24, color: Colors.white)),
                          ),
                          const SizedBox(height: 10),
                          Text(user?.displayName ?? '', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          if (user != null) ...[
                            const SizedBox(height: 2),
                            Text(user.role.replaceAll('_', ' ').toUpperCase(), style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, letterSpacing: 1)),
                            if (user.pharmacieNom != null) Text(user.pharmacieNom!, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (isCaissier) ...[
                    _sectionHeader('Ventes'),
                    _drawerItem(Icons.add_shopping_cart, Icons.add_shopping_cart, 'Point de vente', 0),
                    _drawerItem(Icons.receipt_long_outlined, Icons.receipt_long, 'Historique', 1),
                  ] else if (isSuper) ...[
                    _sectionHeader('Plateforme'),
                    _drawerItem(Icons.dashboard_outlined, Icons.dashboard, 'Dashboard', 0),
                  ] else ...[
                    _sectionHeader('Gestion'),
                    _drawerItem(Icons.dashboard_outlined, Icons.dashboard, 'Dashboard', 0),
                    _drawerItem(Icons.medication_outlined, Icons.medication, 'Médicaments', 1),
                    _drawerItem(Icons.inventory_outlined, Icons.inventory, 'Stock', 2),
                    _drawerItem(Icons.inventory_2_outlined, Icons.inventory_2, 'Gestion des lots', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LotListScreen()))),
                    _drawerItem(Icons.shopping_cart_outlined, Icons.shopping_cart, 'Point de vente', 3),
                  ],
                  if (!isCaissier && !isSuper)
                    _drawerItem(Icons.receipt_long_outlined, Icons.receipt_long, 'Historique des ventes', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VentesListScreen()))),
                  if (isAdmin) ...[
                    _drawerItem(Icons.shopping_bag_outlined, Icons.shopping_bag, 'Achats', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AchatsListScreen()))),
                    _drawerItem(Icons.people_outline, Icons.people, 'Clients', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientsListScreen()))),
                    _drawerItem(Icons.description_outlined, Icons.description, 'Prescriptions', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrescriptionsListScreen()))),
                  ],
                  if (isAdmin) ...[
                    _sectionHeader('Administration'),
                    _drawerItem(Icons.badge_outlined, Icons.badge, 'Employés', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployesListScreen()))),
                    _drawerItem(Icons.assignment_outlined, Icons.assignment, 'Fournisseurs', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FournisseursScreen()))),
                    _drawerItem(Icons.inventory_2_outlined, Icons.inventory_2, 'Gestion des lots', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LotListScreen()))),
                  ],
                  if (isAdmin) ...[
                    _drawerItem(Icons.bar_chart_outlined, Icons.bar_chart, 'Rapports', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RapportsScreen()))),
                    _drawerItem(Icons.smart_toy_outlined, Icons.smart_toy, 'Assistant IA', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()))),
                    _drawerItem(Icons.settings_outlined, Icons.settings, 'Paramètres', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ParametresScreen()))),
                    _drawerItem(Icons.notifications_outlined, Icons.notifications, 'Notifications', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
                  ],
                  if (isSuper) ...[
                    _sectionHeader('Plateforme'),
                    _drawerItem(Icons.local_pharmacy_outlined, Icons.local_pharmacy, 'Pharmacies', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PharmaciesListScreen()))),
                    _drawerItem(Icons.people_outline, Icons.people, 'Utilisateurs', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UtilisateursListScreen()))),
                    _drawerItem(Icons.subscriptions_outlined, Icons.subscriptions, 'Abonnements', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AbonnementsListScreen()))),
                    _drawerItem(Icons.payments_outlined, Icons.payments, 'Paiements', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaiementsListScreen()))),
                    _drawerItem(Icons.bar_chart_outlined, Icons.bar_chart, 'Rapports', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RapportsScreen()))),
                    _drawerItem(Icons.settings_outlined, Icons.settings, 'Paramètres', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ParametresScreen()))),
                    _drawerItem(Icons.notifications_outlined, Icons.notifications, 'Notifications', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
                    _drawerItem(Icons.smart_toy_outlined, Icons.smart_toy, 'Assistant IA', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()))),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(),
                  ),
                  _drawerItem(Icons.person_outline, Icons.person, 'Profil', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()))),
                  ListTile(
                    leading: const Icon(Icons.logout, color: AppTheme.errorColor),
                    title: const Text('Déconnexion', style: TextStyle(color: AppTheme.errorColor)),
                    onTap: () async {
                      Navigator.pop(context);
                      try {
                        await auth.logout();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur de déconnexion: $e'), backgroundColor: AppTheme.errorColor),
                          );
                        }
                      }
                    },
                  ),
                ],
            ),
          ),
          body: screens[_currentIndex],
          bottomNavigationBar: _buildBottomNav(isCaissier, isSuper),
        );
      },
    );
  }

  List<Widget> _buildScreens(bool isCaissier, bool isSuper) {
    if (isCaissier) {
      return const [NouvelleVenteScreen(), VentesListScreen()];
    }
    if (isSuper) {
      return const [DashboardScreen(), PharmaciesListScreen(), AbonnementsListScreen(), PaiementsListScreen()];
    }
    return const [DashboardScreen(), MedicamentsListScreen(), StockListScreen(), NouvelleVenteScreen()];
  }

  Widget _buildBottomNav(bool isCaissier, bool isSuper) {
    if (isCaissier) {
      return NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.add_shopping_cart_outlined), selectedIcon: Icon(Icons.add_shopping_cart), label: 'Point de vente'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Historique'),
        ],
      );
    }
    if (isSuper) {
      return NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.local_pharmacy_outlined), selectedIcon: Icon(Icons.local_pharmacy), label: 'Pharmacies'),
          NavigationDestination(icon: Icon(Icons.subscriptions_outlined), selectedIcon: Icon(Icons.subscriptions), label: 'Abonnements'),
          NavigationDestination(icon: Icon(Icons.payments_outlined), selectedIcon: Icon(Icons.payments), label: 'Paiements'),
        ],
      );
    }
    return NavigationBar(
      selectedIndex: _currentIndex,
      onDestinationSelected: (i) => setState(() => _currentIndex = i),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
        NavigationDestination(icon: Icon(Icons.medication_outlined), selectedIcon: Icon(Icons.medication), label: 'Médicaments'),
        NavigationDestination(icon: Icon(Icons.inventory_outlined), selectedIcon: Icon(Icons.inventory), label: 'Stock'),
        NavigationDestination(icon: Icon(Icons.add_shopping_cart_outlined), selectedIcon: Icon(Icons.add_shopping_cart), label: 'Point de vente'),
      ],
    );
  }

  String _getTitle(bool isCaissier, bool isSuper) {
    if (isCaissier) {
      return _currentIndex == 0 ? 'Point de vente' : 'Historique';
    }
    if (isSuper) {
      switch (_currentIndex) {
        case 0: return 'Dashboard';
        case 1: return 'Pharmacies';
        case 2: return 'Abonnements';
        case 3: return 'Paiements';
        default: return 'Plateforme';
      }
    }
    switch (_currentIndex) {
      case 0: return 'Dashboard';
      case 1: return 'Médicaments';
      case 2: return 'Stock';
      case 3: return 'Point de vente';
      default: return 'Gestion Pharmacie';
    }
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryColor, letterSpacing: 1)),
    );
  }

  Widget _drawerItem(IconData icon, IconData selectedIcon, String title, dynamic target) {
    final isSelected = target is int && _currentIndex == target;
    return ListTile(
      leading: Icon(isSelected ? selectedIcon : icon, color: isSelected ? AppTheme.primaryColor : Colors.grey.shade600),
      title: Text(title, style: TextStyle(
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        color: isSelected ? AppTheme.primaryColor : Colors.grey.shade800,
      )),
      selected: isSelected,
      selectedTileColor: AppTheme.primaryColor.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () {
        Navigator.pop(context);
        if (target is int) {
          setState(() => _currentIndex = target);
        } else if (target is VoidCallback) {
          target();
        } else if (target is Function()) {
          target();
        }
      },
    );
  }
}
