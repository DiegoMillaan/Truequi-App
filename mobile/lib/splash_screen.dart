import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'login_screen.dart';

// Paleta institucional compartida
class _SplashColors {
  static const Color purpura = Color(0xFF6B42E0);
  static const Color amarillo = Color(0xFFFFA800);
  static const Color textoOscuro = Color(0xFF101828);
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 1. Simula o ejecuta validaciones iniciales y precarga en segundo plano (duración entre 3 y 5 segundos)
    await Future.delayed(const Duration(seconds: 4));

    // 2. Validación de seguridad antes de navegar
    if (!mounted) return;

    // 3. Transición hacia el Login
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          );
          return FadeTransition(opacity: fadeAnimation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final avance = _animationController.value * 2 * math.pi;
            final latido = 1.0 + (math.sin(avance * 6) * 0.04);
            final levitacion = math.sin(avance) * 8.0;

            return Transform.translate(
              offset: Offset(0, levitacion),
              child: Transform.scale(
                scale: latido,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo Biológico en miniatura para el Splash
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _SplashColors.purpura.withValues(alpha: 0.4),
                                  blurRadius: 30,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: _SplashColors.purpura.withValues(alpha: 0.3), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.sync_rounded, size: 50, color: _SplashColors.purpura),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'truequi',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: _SplashColors.purpura,
                        letterSpacing: -1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Cambia algo, gana mucho.',
                      style: TextStyle(
                        fontSize: 15,
                        color: _SplashColors.textoOscuro,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 40),
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(_SplashColors.amarillo),
                        strokeWidth: 2.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}