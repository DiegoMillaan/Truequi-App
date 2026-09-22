import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'login_screen.dart';

class _SplashColors {
  static const Color purpura = Color(0xFF6B42E0);
  static const Color amarillo = Color(0xFFFFA800);
  static const Color fondoProfundo = Color(0xFF0A0514); // Un fondo abismal para resaltar la luz
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Animaciones controladas por intervalos precisos
  late Animation<double> _rotacionOrbes;
  late Animation<double> _convergenciaOrbes;
  late Animation<double> _escalaLogo;
  late Animation<double> _opacidadCristal;
  late Animation<double> _explosionLuz;

  @override
  void initState() {
    super.initState();
    
    // Duración total de la obra: 4.5 segundos antes de pasar al login
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    );

    // 1. Los orbes giran caóticamente al inicio (0.0 a 0.7)
    _rotacionOrbes = Tween<double>(begin: 0.0, end: 4 * math.pi).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.7, curve: Curves.easeInOutCubic)),
    );

    // 2. Los orbes se atraen hacia el centro simulando un trueque (0.4 a 0.7)
    _convergenciaOrbes = Tween<double>(begin: 120.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 0.7, curve: Curves.easeInExpo)),
    );

    // 3. El panel de cristal esmerilado aparece (0.5 a 0.7)
    _opacidadCristal = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 0.7, curve: Curves.easeOut)),
    );

    // 4. El logo se escala con un rebote elástico (0.6 a 0.8)
    _escalaLogo = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.6, 0.8, curve: Curves.elasticOut)),
    );

    // 5. Los orbes explotan en luz llenando la pantalla antes de la transición (0.8 a 1.0)
    _explosionLuz = Tween<double>(begin: 1.0, end: 15.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.85, 1.0, curve: Curves.easeInExpo)),
    );

    _controller.forward().then((_) => _navegarAlLogin());
  }

  void _navegarAlLogin() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 1200),
        pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Transición de desvanecimiento ultra suave desde la luz pura
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _SplashColors.fondoProfundo,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // ========================================================
              // CAPA 1: ORBES HIPNÓTICOS LÍQUIDOS (METABALLS)
              // ========================================================
              ...List.generate(3, (index) {
                // Matemáticas de Lissajous para movimiento orgánico
                final desfase = index * (math.pi / 1.5);
                final radioX = _convergenciaOrbes.value * (index == 1 ? 1.2 : 1.0);
                final radioY = _convergenciaOrbes.value * (index == 2 ? 1.5 : 0.8);
                
                final x = math.cos(_rotacionOrbes.value + desfase) * radioX;
                final y = math.sin(_rotacionOrbes.value * 1.5 + desfase) * radioY;

                final color = index == 0 
                    ? _SplashColors.purpura 
                    : index == 1 
                        ? _SplashColors.amarillo 
                        : const Color(0xFF9D72FF);

                return Transform.translate(
                  offset: Offset(x, y),
                  child: Transform.scale(
                    scale: _explosionLuz.value,
                    child: Container(
                      width: size.width * 0.45,
                      height: size.width * 0.45,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withOpacity(0.6),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.8),
                            blurRadius: 60,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              // ========================================================
              // CAPA 2: EFECTO DE LÍQUIDO / CRISTAL DESENFOCADO MASSIVO
              // ========================================================
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50.0, sigmaY: 50.0),
                child: Container(
                  color: _SplashColors.fondoProfundo.withOpacity(0.3),
                ),
              ),

              // ========================================================
              // CAPA 3: REVELACIÓN DEL LOGO (GLASSMORPHISM)
              // ========================================================
              Opacity(
                opacity: _opacidadCristal.value,
                child: Transform.scale(
                  scale: _escalaLogo.value,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 40,
                              spreadRadius: -10,
                              offset: const Offset(0, 20),
                            )
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.9),
                                boxShadow: [
                                  BoxShadow(
                                    color: _SplashColors.amarillo.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 5),
                                  )
                                ],
                              ),
                              child: const Icon(
                                Icons.sync_rounded,
                                size: 54,
                                color: _SplashColors.purpura,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'truequi',
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'El valor está en el cambio',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.7),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}