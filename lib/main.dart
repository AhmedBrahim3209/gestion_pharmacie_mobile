import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'services/api_service.dart';
import 'providers/auth_provider.dart';
import 'providers/medicament_provider.dart';
import 'providers/stock_provider.dart';
import 'providers/vente_provider.dart';
import 'providers/achat_provider.dart';
import 'providers/client_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/prescription_provider.dart';
import 'providers/employe_provider.dart';
import 'providers/abonnement_provider.dart';
import 'providers/paiement_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/pharmacie_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/rapport_provider.dart';
import 'providers/utilisateur_provider.dart';
import 'providers/localisation_provider.dart';
import 'providers/configuration_abonnement_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..loadUser()),
        ChangeNotifierProvider(create: (_) => MedicamentProvider()),
        ChangeNotifierProvider(create: (_) => StockProvider()),
        ChangeNotifierProvider(create: (_) => VenteProvider()),
        ChangeNotifierProvider(create: (_) => AchatProvider()),
        ChangeNotifierProvider(create: (_) => ClientProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => PrescriptionProvider()),
        ChangeNotifierProvider(create: (_) => EmployeProvider()),
        ChangeNotifierProvider(create: (_) => AbonnementProvider()),
        ChangeNotifierProvider(create: (_) => PaiementProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => PharmacieProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => RapportProvider()),
        ChangeNotifierProvider(create: (_) => UtilisateurProvider()),
        ChangeNotifierProvider(create: (_) => ConfigurationAbonnementProvider()),
        ChangeNotifierProvider(create: (_) => LocalisationProvider()),
      ],
      child: Consumer<LocalisationProvider>(
        builder: (context, loc, _) => MaterialApp(
          title: 'Gestion Pharmacie',
          debugShowCheckedModeBanner: false,
          locale: loc.locale,
          supportedLocales: const [Locale('fr'), Locale('en'), Locale('ar')],
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: Consumer<AuthProvider>(
            builder: (context, auth, _) {
              if (auth.isAuthenticated) {
                return const HomeScreen();
              }
              return const LoginScreen();
            },
          ),
        ),
      ),
    );
  }
}
