import 'package:flutter/material.dart';
import 'login_screen.dart';

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
        // Inyectamos el ADN visual en toda la aplicación
        colorSchemeSeed: const Color(0xFF6B42E0), // Truequi purpura
        scaffoldBackgroundColor: const Color(0xFFF8F9FA), // Truequi fondoClaro
        
        // Estandarizamos la barra superior para todas las pantallas
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF101828), // textoOscuro
          elevation: 0,
          centerTitle: false,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}