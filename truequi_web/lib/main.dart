import 'package:flutter/material.dart';
import 'splash_screen.dart';

void main() {
  runApp(const TruequiWebApp());
}

class TruequiWebApp extends StatelessWidget {
  const TruequiWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Truequi Web',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6B42E0),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),

      // La página principal será la pantalla de carga
      home: const SplashScreen(),
    );
  }
}