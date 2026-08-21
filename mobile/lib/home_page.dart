import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;

class TruequiColors {
  static const Color purpura = Color(0xFF6B42E0);
  static const Color amarillo = Color(0xFFFFA800);
  static const Color textoOscuro = Color(0xFF101828);
  static const Color fondoClaro = Color(0xFFF8F9FA);
}

class HomePage extends StatefulWidget {
  final String correo;
  const HomePage({super.key, required this.correo});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _indiceNavegacion = 0;
  late AnimationController _bgController;
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // 1. Controlador del fondo líquido (Continuidad con el Login)
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15), // Un poco más dinámico
    )..repeat();

    // 2. Controlador de la entrada hipnótica del contenido
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic)),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic)),
    );

    // Disparamos la animación al entrar a la pantalla
    _entranceController.forward();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String nombreUsuario = widget.correo.split('@').first;
    nombreUsuario = nombreUsuario[0].toUpperCase() + nombreUsuario.substring(1);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: TruequiColors.fondoClaro,
      extendBody: true, // Crucial para la barra flotante
      
      body: Stack(
        children: [
          // ==========================================
          // CAPA 1: FONDO LÍQUIDO (Continuidad con Login)
          // ==========================================
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: size.height * 0.05 + (math.sin(_bgController.value * 2 * math.pi) * 40),
                    left: size.width * 0.2 + (math.cos(_bgController.value * 2 * math.pi) * 40),
                    child: Container(
                      width: size.width * 0.7,
                      height: size.width * 0.7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: TruequiColors.purpura.withOpacity(0.25), // Más visible pero suave
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: size.height * 0.15 + (math.cos(_bgController.value * 2 * math.pi) * 60),
                    right: size.width * -0.1 + (math.sin(_bgController.value * 2 * math.pi) * 50),
                    child: Container(
                      width: size.width * 0.85,
                      height: size.width * 0.85,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: TruequiColors.amarillo.withOpacity(0.15),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 70.0, sigmaY: 70.0),
            child: Container(color: Colors.white.withOpacity(0.4)), // Capa esmerilada base
          ),

          // ==========================================
          // CAPA 2: CONTENIDO ANIMADO (Fade & Slide In)
          // ==========================================
          SafeArea(
            bottom: false, // Dejamos que el contenido baje hasta el fondo real
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // HEADER LIMPIO Y MINIMALISTA
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Descubre,',
                                  style: TextStyle(fontSize: 16, color: TruequiColors.textoOscuro.withOpacity(0.6), fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  nombreUsuario,
                                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: TruequiColors.purpura, letterSpacing: -0.5),
                                ),
                              ],
                            ),
                            // Avatar con Glassmorphism
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.5),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const CircleAvatar(
                                radius: 22,
                                backgroundColor: TruequiColors.amarillo,
                                child: Icon(Icons.person_rounded, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // UBICACIÓN ESTILO "PÍLDORA"
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white.withOpacity(0.8), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on_rounded, size: 16, color: TruequiColors.purpura),
                              const SizedBox(width: 8),
                              Text(
                                'Cerca de UAQ - Querétaro', // Integración natural de la ubicación
                                style: TextStyle(fontSize: 13, color: TruequiColors.textoOscuro.withOpacity(0.8), fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // BUSCADOR INTEGRADO
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 15, 24, 30),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.search_rounded, color: TruequiColors.purpura),
                              SizedBox(width: 12),
                              Text('¿Qué estás buscando hoy?', style: TextStyle(color: Colors.grey, fontSize: 15)),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // SECCIÓN BENTO: DESTACADOS
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Para ti', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: TruequiColors.textoOscuro)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                // Tarjeta Principal
                                Expanded(
                                  flex: 3,
                                  child: Container(
                                    height: 200,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(32),
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: Stack(
                                      children: [
                                        const Center(child: Icon(Icons.devices_rounded, size: 60, color: Colors.grey)),
                                        Positioned(
                                          bottom: 20,
                                          left: 20,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(color: TruequiColors.purpura, borderRadius: BorderRadius.circular(10)),
                                                child: const Text('Top Match', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                              ),
                                              const SizedBox(height: 8),
                                              const Text('MacBook Air M1', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                              Text('Busca: iPad Pro', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Tarjetas Secundarias Apiladas
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    children: [
                                      Container(
                                        height: 92,
                                        decoration: BoxDecoration(
                                          color: TruequiColors.purpura.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(24),
                                          border: Border.all(color: Colors.white, width: 1.5),
                                        ),
                                        child: const Center(child: Icon(Icons.menu_book_rounded, color: TruequiColors.purpura, size: 32)),
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        height: 92,
                                        decoration: BoxDecoration(
                                          color: TruequiColors.amarillo.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(24),
                                          border: Border.all(color: Colors.white, width: 1.5),
                                        ),
                                        child: const Center(child: Icon(Icons.gamepad_rounded, color: TruequiColors.amarillo, size: 32)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 120)), // Espacio para la barra flotante
                  ],
                ),
              ),
            ),
          ),
          
          // ==========================================
          // CAPA 3: NAVEGACIÓN FLOTANTE (Glassmorphism Pill)
          // ==========================================
          Positioned(
            bottom: 30,
            left: 30,
            right: 30,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
                    boxShadow: [BoxShadow(color: TruequiColors.purpura.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, 10))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(Icons.home_filled, 0),
                      _buildNavItem(Icons.explore_rounded, 1),
                      // Botón Central Destacado
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: TruequiColors.purpura,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: TruequiColors.purpura.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
                          ),
                          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                        ),
                      ),
                      _buildNavItem(Icons.chat_bubble_rounded, 2),
                      _buildNavItem(Icons.person_rounded, 3),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget de icono de navegación con animación implícita
  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = _indiceNavegacion == index;
    return GestureDetector(
      onTap: () => setState(() => _indiceNavegacion = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? TruequiColors.amarillo.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          color: isSelected ? TruequiColors.amarillo : Colors.grey.shade400,
          size: 26,
        ),
      ),
    );
  }
}