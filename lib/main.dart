import 'package:app_mobile_music_underground/screens/auditeur/profil_screen.dart';
import 'package:app_mobile_music_underground/screens/auditeur/recherche_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_mobile_music_underground/services/auth_service.dart';
import 'package:app_mobile_music_underground/screens/auth/login_screen.dart';
import 'package:app_mobile_music_underground/screens/auth/register_screen.dart';
import 'package:app_mobile_music_underground/core/app_constants.dart';
import 'package:app_mobile_music_underground/screens/auditeur/decouverte_screen.dart';
import 'package:app_mobile_music_underground/screens/artiste/dashboard_screen.dart';
import 'package:app_mobile_music_underground/screens/auth/forgot_password.dart';
import 'package:app_mobile_music_underground/screens/auditeur/lecteur_screen.dart';
import 'package:app_mobile_music_underground/screens/artiste/profil_artiste_screen.dart';
import 'package:app_mobile_music_underground/screens/auditeur/profil_screen.dart';
import 'package:app_mobile_music_underground/screens/artiste/mes_titres_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Initialisation Supabase ──────────────────────────────────────────
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/':(context) => LoginScreen(),
        '/Register':(context) => RegisterScreen(),
        '/Forgotpassword':(context) => ForgotPasswordScreen(),
        '/decouvertescreen': (context) => DecouverteScreen(),
        '/recherche': (context) => RechercheScreen(),
        '/dashboardscreen': (context) => DashboardScreen(),
        '/profilartiste': (context) => ProfilArtisteScreen(),
        '/profilauditeur': (context) => ProfilScreen(),
        '/mestitres' : (context) => MesTitresScreen(),
      },
    );
  }
}