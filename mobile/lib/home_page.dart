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

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  int _indiceNavegacion = 0;
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    // Animación muy lenta para no distraer de los productos (dura 20 segundos)
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String nombreUsuario = widget.correo.split('@').first;
    nombreUsuario = nombreUsuario[0].toUpperCase() + nombreUsuario.substring(1);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white, // Fondo base puro
      extendBody: true, // Permite que el contenido fluya debajo del BottomNav
      extendBodyBehindAppBar: true, // Permite que el contenido fluya debajo del AppBar
      
      body: Stack(
        children: [
          // CAPA 1: Fondo animado sutil
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: -100 + (math.sin(_bgController.value * 2 * math.pi) * 50),
                    left: -50 + (math.cos(_bgController.value * 2 * math.pi) * 50),
                    child: Container(
                      width: size.width * 0.8,
                      height: size.width * 0.8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: TruequiColors.purpura.withOpacity(0.15),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: size.height * 0.2 + (math.cos(_bgController.value * 2 * math.pi) * 50),
                    right: -100 + (math.sin(_bgController.value * 2 * math.pi) * 50),
                    child: Container(
                      width: size.width * 0.9,
                      height: size.width * 0.9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: TruequiColors.amarillo.withOpacity(0.10),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // CAPA 2: Blur extremo para el fondo
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80.0, sigmaY: 80.0),
            child: Container(color: Colors.transparent),
          ),

          // CAPA 3: Contenido de la aplicación (Scroll)
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // APP BAR DE CRISTAL
              SliverAppBar(
                expandedHeight: 120,
                floating: true,
                pinned: true,
                backgroundColor: Colors.white.withOpacity(0.7),
                elevation: 0,
                flexibleSpace: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.only(left: 20, bottom: 16, right: 20),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '¡Hola, $nombreUsuario!',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: TruequiColors.textoOscuro),
                              ),
                              const SizedBox(height: 4),
                              // EL MÓDULO DE UBICACIÓN 📍
                              Row(
                                children: [
                                  Icon(Icons.location_on_rounded, size: 14, color: TruequiColors.purpura),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Cerca de UAQ - Querétaro',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                                  ),
                                  const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Colors.grey),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                            ),
                            child: const Icon(Icons.notifications_outlined, size: 20, color: TruequiColors.textoOscuro),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // CONTENIDO DEL FEED
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 100), // Margen inferior para el BottomNav
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // BUSCADOR FLOTANTE
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))],
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.search_rounded, color: TruequiColors.purpura),
                              SizedBox(width: 12),
                              Text('¿Qué estás buscando hoy?', style: TextStyle(color: Colors.grey, fontSize: 14)),
                              Spacer(),
                              Icon(Icons.tune_rounded, color: TruequiColors.amarillo, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // CATEGORÍAS (Píldoras de cristal)
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          physics: const BouncingScrollPhysics(),
                          children: const [
                            BurbujaCategoria(texto: 'Para ti', activo: true),
                            BurbujaCategoria(texto: 'Tecnología', activo: false),
                            BurbujaCategoria(texto: 'Libros', activo: false),
                            BurbujaCategoria(texto: 'Ropa', activo: false),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      // SECCIÓN: OPORTUNIDADES CERCA (Highlighting location)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: Text(
                          'Oportunidades cerca de ti',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: TruequiColors.textoOscuro),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 240,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(left: 20),
                          physics: const BouncingScrollPhysics(),
                          itemCount: 3,
                          itemBuilder: (context, index) => const TarjetaProductoHorizontal(),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // SECCIÓN: DESCUBRIMIENTOS
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: Text(
                          'Descubrimientos recientes',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: TruequiColors.textoOscuro),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: GridView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.65,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: 4,
                          itemBuilder: (context, index) => const TarjetaProductoVertical(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),

      // BOTTOM NAV BAR DE CRISTAL
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.5), width: 1)),
            ),
            child: BottomNavigationBar(
              currentIndex: _indiceNavegacion,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent, // Transparente para ver el cristal
              selectedItemColor: TruequiColors.purpura,
              unselectedItemColor: Colors.grey.shade400,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              elevation: 0,
              onTap: (index) => setState(() => _indiceNavegacion = index),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Inicio'),
                BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), label: 'Explorar'),
                BottomNavigationBarItem(icon: ContainerIcon(icon: Icons.add), label: 'Subir'), // Botón central destacado
                BottomNavigationBarItem(icon: Icon(Icons.handshake_outlined), label: 'Ofertas'),
                BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// COMPONENTES UI MEJORADOS
// ==========================================

class ContainerIcon extends StatelessWidget {
  final IconData icon;
  const ContainerIcon({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: TruequiColors.amarillo,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: TruequiColors.amarillo, blurRadius: 8, spreadRadius: -2)],
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }
}

class BurbujaCategoria extends StatelessWidget {
  final String texto;
  final bool activo;
  const BurbujaCategoria({super.key, required this.texto, required this.activo});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: activo ? TruequiColors.purpura : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: activo ? TruequiColors.purpura : Colors.white, width: 1.5),
        boxShadow: [
          if (!activo) BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)
        ],
      ),
      child: Center(
        child: Text(
          texto,
          style: TextStyle(color: activo ? Colors.white : TruequiColors.textoOscuro, fontWeight: activo ? FontWeight.bold : FontWeight.w600),
        ),
      ),
    );
  }
}

class TarjetaProductoHorizontal extends StatelessWidget {
  const TarjetaProductoHorizontal({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Stack(
                children: [
                  const Center(child: Icon(Icons.headset_rounded, color: Colors.grey, size: 48)),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), shape: BoxShape.circle),
                      child: const Icon(Icons.favorite_border_rounded, size: 16, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Audífonos Sony', style: TextStyle(fontWeight: FontWeight.bold, color: TruequiColors.textoOscuro, fontSize: 14), maxLines: 1),
                const SizedBox(height: 4),
                const Text('A 1.2 km de ti', style: TextStyle(color: TruequiColors.purpura, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: TruequiColors.amarillo.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                  child: const Text('Busca: Teclado Mecánico', style: TextStyle(color: Color(0xFFD48B00), fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TarjetaProductoVertical extends StatelessWidget {
  const TarjetaProductoVertical({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: const Center(child: Icon(Icons.menu_book_rounded, color: Colors.grey, size: 40)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Libro Clean Code', style: TextStyle(fontWeight: FontWeight.bold, color: TruequiColors.textoOscuro, fontSize: 13), maxLines: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Hace 2h', style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
                      const Icon(Icons.compare_arrows_rounded, color: TruequiColors.purpura, size: 16),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}