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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
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

        return Scaffold(
          key: _scaffoldKey,
          drawer: _buildDrawer(context, auth, isCaissier, isSuper, isAdmin, isEmploye),
          body: _buildScreenWithDrawerButton(isCaissier, isSuper, user),
          bottomNavigationBar: _buildBottomNav(isCaissier, isSuper),
        );
      },
    );
  }

  Widget _buildScreenWithDrawerButton(bool isCaissier, bool isSuper, user) {
    final screen = _buildScreens(isCaissier, isSuper, user);
    return screen;
  }

  Widget _buildScreens(bool isCaissier, bool isSuper, user) {
    if (isCaissier) {
      switch (_currentIndex) {
        case 0: return NouvelleVenteScreen(onMenuTap: _openDrawer);
        case 1: return VentesListScreen(onMenuTap: _openDrawer);
        default: return NouvelleVenteScreen(onMenuTap: _openDrawer);
      }
    }
    if (isSuper) {
      switch (_currentIndex) {
        case 0: return DashboardScreen(onMenuTap: _openDrawer);
        case 1: return PharmaciesListScreen();
        case 2: return AbonnementsListScreen();
        case 3: return PaiementsListScreen();
        default: return DashboardScreen(onMenuTap: _openDrawer);
      }
    }
    switch (_currentIndex) {
      case 0: return DashboardScreen(onMenuTap: _openDrawer);
      case 1: return MedicamentsListScreen(onMenuTap: _openDrawer);
      case 2: return StockListScreen(onMenuTap: _openDrawer);
      case 3: return NouvelleVenteScreen(onMenuTap: _openDrawer);
      default: return DashboardScreen(onMenuTap: _openDrawer);
    }
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

  Widget _buildDrawer(BuildContext context, AuthProvider auth, bool isCaissier, bool isSuper, bool isAdmin, bool isEmploye) {
    final user = auth.user;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E40AF), Color(0xFF172231)],
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
            _drawerItem(Icons.add_shopping_cart, 'Point de vente', 0),
            _drawerItem(Icons.receipt_long, 'Historique', 1),
          ] else if (isSuper) ...[
            _drawerItem(Icons.dashboard, 'Dashboard', 0),
          ] else ...[
            _drawerItem(Icons.dashboard, 'Dashboard', 0),
            _drawerItem(Icons.medication, 'Médicaments', 1),
            _drawerItem(Icons.inventory, 'Stock', 2),
          ],
          if (!isCaissier && !isSuper) ...[
            _drawerItem(Icons.shopping_cart, 'Point de vente', 3),
            _drawerItem(Icons.receipt_long, 'Historique ventes', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VentesListScreen()))),
          ],
          if (isAdmin) ...[
            const Divider(height: 20, color: AppTheme.sidebarBorder),
            _sectionHeader('Achats & Clients'),
            _drawerItem(Icons.shopping_bag, 'Achats', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AchatsListScreen()))),
            _drawerItem(Icons.people, 'Clients', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientsListScreen()))),
            _drawerItem(Icons.description, 'Prescriptions', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrescriptionsListScreen()))),
            const Divider(height: 20, color: AppTheme.sidebarBorder),
            _sectionHeader('Administration'),
            _drawerItem(Icons.badge, 'Employés', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployesListScreen()))),
            _drawerItem(Icons.assignment, 'Fournisseurs', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FournisseursScreen()))),
            const Divider(height: 20, color: AppTheme.sidebarBorder),
            _sectionHeader('Outils'),
            _drawerItem(Icons.bar_chart, 'Rapports', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RapportsScreen()))),
            _drawerItem(Icons.smart_toy, 'Assistant IA', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()))),
            _drawerItem(Icons.notifications, 'Notifications', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
            _drawerItem(Icons.settings, 'Paramètres', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ParametresScreen()))),
          ],
          if (isSuper) ...[
            const Divider(height: 20, color: AppTheme.sidebarBorder),
            _sectionHeader('Plateforme'),
            _drawerItem(Icons.local_pharmacy, 'Pharmacies', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PharmaciesListScreen()))),
            _drawerItem(Icons.people, 'Utilisateurs', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UtilisateursListScreen()))),
            _drawerItem(Icons.subscriptions, 'Abonnements', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AbonnementsListScreen()))),
            _drawerItem(Icons.payments, 'Paiements', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaiementsListScreen()))),
            _drawerItem(Icons.bar_chart, 'Rapports', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RapportsScreen()))),
            _drawerItem(Icons.notifications, 'Notifications', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
            _drawerItem(Icons.smart_toy, 'Assistant IA', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()))),
            _drawerItem(Icons.settings, 'Paramètres', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ParametresScreen()))),
          ],
          const Divider(height: 20, color: AppTheme.sidebarBorder),
          _drawerItem(Icons.person, 'Profil', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()))),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.logout, color: AppTheme.errorColor, size: 20),
            ),
            title: const Text('Déconnexion', style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.w600)),
            onTap: () async {
              Navigator.pop(context);
              try {
                await auth.logout();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.errorColor),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppTheme.textSidebar,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, dynamic target) {
    final isSelected = target is int && _currentIndex == target;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.sidebarActive : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isSelected ? Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.4)) : null,
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: isSelected ? AppTheme.textSidebarActive : AppTheme.textSidebar, size: 20),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? AppTheme.textSidebarActive : AppTheme.textSidebar,
            fontSize: 14,
          ),
        ),
        trailing: isSelected ? Container(
          width: 3,
          height: 20,
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            borderRadius: BorderRadius.circular(2),
          ),
        ) : null,
        onTap: () {
          Navigator.pop(context);
          if (target is int) {
            setState(() => _currentIndex = target);
          } else if (target is Function()) {
            target();
          }
        },
      ),
    );
  }
}
