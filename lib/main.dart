import 'package:flutter/material.dart';
import 'package:app_mobile_music_underground/screens/auth/login_screen.dart';
import 'package:app_mobile_music_underground/screens/auth/register_screen.dart';

void main() {
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
      },
    );
  }
}

