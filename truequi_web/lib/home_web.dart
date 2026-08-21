import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;

class TruequiColors {
  static const Color purpura = Color(0xFF6B42E0);
  static const Color amarillo = Color(0xFFFFA800);
  static const Color textoOscuro = Color(0xFF101828);
}

class HomeWeb extends StatefulWidget {
  final String correo;
  const HomeWeb({super.key, required this.correo});

  @override
  State<HomeWeb> createState() => _HomeWebState();
}

class _HomeWebState extends State<HomeWeb> with SingleTickerProviderStateMixin {
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    // Los orbes del login ahora se expanden y se mueven más lento
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
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
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // ==========================================
          // CAPA 1: FONDO LÍQUIDO EXPANDIDO
          // ==========================================
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: size.height * 0.1 + (math.sin(_bgController.value * 2 * math.pi) * 80),
                    left: size.width * 0.1 + (math.cos(_bgController.value * 2 * math.pi) * 80),
                    child: Container(
                      width: size.width * 0.5,
                      height: size.width * 0.5,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: TruequiColors.purpura.withOpacity(0.15)),
                    ),
                  ),
                  Positioned(
                    bottom: size.height * 0.1 + (math.cos(_bgController.value * 2 * math.pi) * 100),
                    right: size.width * 0.05 + (math.sin(_bgController.value * 2 * math.pi) * 120),
                    child: Container(
                      width: size.width * 0.6,
                      height: size.width * 0.6,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: TruequiColors.amarillo.withOpacity(0.10)),
                    ),
                  ),
                ],
              );
            },
          ),
          
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 90.0, sigmaY: 90.0),
            child: Container(color: Colors.white.withOpacity(0.3)),
          ),

          // ==========================================
          // CAPA 2: CONTENIDO SCROLLABLE (Feed)
          // ==========================================
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // NAVBAR DE CRISTAL (Estilo Vinted pero premium)
              SliverAppBar(
                pinned: true,
                floating: false,
                expandedHeight: 80,
                collapsedHeight: 80,
                backgroundColor: Colors.white.withOpacity(0.7),
                flexibleSpace: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.5), width: 1.5))),
                      child: Row(
                        children: [
                          // Logo
                          const Icon(Icons.sync_rounded, color: TruequiColors.purpura, size: 36),
                          const SizedBox(width: 12),
                          const Text('truequi', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: TruequiColors.purpura, letterSpacing: -1)),
                          
                          const SizedBox(width: 48),
                          
                          // Buscador Central Gigante
                          Expanded(
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.search_rounded, color: Colors.grey),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      decoration: InputDecoration(hintText: 'Buscar artículos, libros, tecnología...', border: InputBorder.none),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: 48),
                          
                          // Acciones de Usuario
                          Row(
                            children: [
                              TextButton(onPressed: () {}, child: const Text('Explorar', style: TextStyle(color: TruequiColors.textoOscuro, fontWeight: FontWeight.w600))),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: TruequiColors.purpura, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
                                onPressed: () {}, 
                                child: const Text('Subir artículo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 24),
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(color: TruequiColors.amarillo, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                                child: Center(child: Text(nombreUsuario[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // SUBMENU DE CATEGORÍAS
              SliverToBoxAdapter(
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 16, color: TruequiColors.purpura),
                      const SizedBox(width: 8),
                      const Text('Campus UAQ', style: TextStyle(fontWeight: FontWeight.bold, color: TruequiColors.textoOscuro)),
                      const VerticalDivider(indent: 15, endIndent: 15, color: Colors.grey),
                      _BotonCategoria('Tecnología'),
                      _BotonCategoria('Libros Universitarios'),
                      _BotonCategoria('Videojuegos'),
                      _BotonCategoria('Mobiliario'),
                    ],
                  ),
                ),
              ),

              // HERO BANNER (Estilo Depop)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                  child: Container(
                    height: 350,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 30, offset: const Offset(0, 15))],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(48.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(color: TruequiColors.amarillo.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                                  child: const Text('Renueva tu ecosistema', style: TextStyle(color: Color(0xFFD48B00), fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(height: 24),
                                const Text('Cambia lo que tienes.\nEncuentra lo que buscas.', style: TextStyle(fontSize: 48, height: 1.1, fontWeight: FontWeight.w900, color: TruequiColors.textoOscuro, letterSpacing: -1.5)),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: TruequiColors.textoOscuro, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20)),
                                  onPressed: () {}, 
                                  child: const Text('Ver Top Matches', style: TextStyle(color: Colors.white, fontSize: 16)),
                                )
                              ],
                            ),
                          ),
                        ),
                        // Área visual del banner
                        Expanded(
                          flex: 1,
                          child: Stack(
                            children: [
                              Positioned(
                                right: -50, top: -50,
                                child: Icon(Icons.change_circle_rounded, size: 400, color: TruequiColors.purpura.withOpacity(0.1)),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),

              // GRID DE PRODUCTOS (Estilo Vinted - Adaptable a web)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 280, // Ancho máximo de tarjeta
                    mainAxisSpacing: 24,
                    crossAxisSpacing: 24,
                    childAspectRatio: 0.70, // Proporción vertical
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _TarjetaProductoWeb(index: index),
                    childCount: 12,
                  ),
                ),
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 100)), // Margen final
            ],
          ),
        ],
      ),
    );
  }

  Widget _BotonCategoria(String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextButton(
        onPressed: () {},
        child: Text(texto, style: TextStyle(color: TruequiColors.textoOscuro.withOpacity(0.7), fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ==========================================
// TARJETA INTERACTIVA CON HOVER (Web Exclusive)
// ==========================================
class _TarjetaProductoWeb extends StatefulWidget {
  final int index;
  const _TarjetaProductoWeb({required this.index});

  @override
  State<_TarjetaProductoWeb> createState() => _TarjetaProductoWebState();
}

class _TarjetaProductoWebState extends State<_TarjetaProductoWeb> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _isHovered ? -10 : 0, 0), // Se eleva al pasar el mouse
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: TruequiColors.purpura.withOpacity(_isHovered ? 0.15 : 0.03),
              blurRadius: _isHovered ? 30 : 15,
              offset: Offset(0, _isHovered ? 15 : 8),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placeholder de imagen
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: const BorderRadius.vertical(top: Radius.circular(22))),
                child: const Center(child: Icon(Icons.laptop_chromebook_rounded, size: 64, color: Colors.grey)),
              ),
            ),
            // Detalles
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Monitor Curvo 24"', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: TruequiColors.textoOscuro), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const Text('Hace 2 horas', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: TruequiColors.purpura.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Text('Busca: iPad o Tablet', style: TextStyle(color: TruequiColors.purpura, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        CircleAvatar(radius: 12, backgroundColor: TruequiColors.amarillo.withOpacity(0.5), child: const Icon(Icons.person, size: 14, color: Colors.white)),
                        const SizedBox(width: 8),
                        const Text('Usuario', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}