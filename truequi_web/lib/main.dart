import 'package:flutter/material.dart';
import 'login_web.dart'; // Importamos la pantalla de Login

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
        colorSchemeSeed: const Color(0xFF6B42E0), // Tu color púrpura
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),
      // La primera pantalla sea el Login
      home: const LoginWeb(), 
    );
  }
}