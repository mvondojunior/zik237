import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_mobile_music_underground/core/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 3), () {
      // Vérification que le widget est toujours monté
      // avant de naviguer — évite les crashs
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/Loginscreen');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Image.asset(
          'assets/images/zik-237-mobile-app-icon.png',
          width: 180,
          height: 180,
        ),
      ),
    );
  }
}