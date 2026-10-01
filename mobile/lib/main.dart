import 'package:flutter/material.dart';
import 'splash_screen.dart';

void main() {
  runApp(const TruequiApp());
}

class TruequiApp extends StatelessWidget {
  const TruequiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp( 
      debugShowCheckedModeBanner: false,
      title: 'Truequi',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6B42E0),
        // CORRECCIÓN: Fondo oscuro global para evitar flashes blancos en navegación
        scaffoldBackgroundColor: const Color(0xFF0D0A15), 
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
      ),
      home: const SplashScreen(), 
    );
  }
}