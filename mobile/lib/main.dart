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
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF101828),
          elevation: 0,
          centerTitle: false,
        ),
      ),
      home: const SplashScreen(), 
    );
  }
}