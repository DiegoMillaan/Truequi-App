import 'dart:async';
import 'package:flutter/material.dart';
import 'home_web.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // Controladores para las animaciones maestras
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _fadeController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Animación de "respiración" (latido)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 2. Animación de rotación infinita y suave para el ícono de intercambio
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // 3. Animación de aparición (Fade-in) para toda la pantalla
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _fadeController.forward();

    // 4. Temporizador para cambiar a la pantalla principal (HomeWeb)
    Timer(const Duration(milliseconds: 3800), () {
      if (!mounted) return;

      // Hacemos que el splash se desvanezca antes de cambiar
      _fadeController.reverse().then((_) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const HomeWeb(),
            transitionDuration: const Duration(milliseconds: 900),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    // Limpiamos la memoria de los 3 controladores
    _pulseController.dispose();
    _rotationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fondo oscuro y elegante que resalta los colores neón
      backgroundColor: const Color(0xFF0D0A15), 
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // ========================================================
            // CAPA 1: DEGRADADO DE FONDO Y BRILLO
            // ========================================================
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Color(0xFF2A1B54), // Púrpura oscuro en el centro
                      Color(0xFF0D0A15), // Negro en los bordes
                    ],
                    radius: 1.2,
                  ),
                ),
              ),
            ),

            // ========================================================
            // CAPA 2: ELEMENTOS CENTRALES ANIMADOS
            // ========================================================
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Ícono animado que respira y rota
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: RotationTransition(
                      turns: _rotationController,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6B42E0).withOpacity(0.5),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6B42E0), Color(0xFFFFA800)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.sync_rounded,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),

                  // Texto de la marca con espaciado elegante
                  const Text(
                    'T R U E Q U I',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 8.0, 
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Subtítulo minimalista en lugar del aburrido "Cargando..."
                  Text(
                    'El valor de compartir',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}