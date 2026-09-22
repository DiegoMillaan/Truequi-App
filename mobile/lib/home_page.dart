import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart'; 
import '../services/google_auth_service.dart';
import 'explorar_page.dart';
import 'publicar_page.dart';
import 'chats_page.dart';
import 'perfil_page.dart';
import 'detalle_producto_page.dart';

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

  // Variables para el backend
  List<dynamic> _productos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

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

    _entranceController.forward();
    _cargarProductos(); // Llamada a AWS
  }

  // ==========================================
  // CONEXIÓN AL MICROSERVICIO DE CATÁLOGO
  // ==========================================
  Future<void> _cargarProductos() async {
    try {
      final url = Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/productos');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _productos = data['productos'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error al cargar catálogo: $e");
    }
  }

  @override
  void dispose() {
    _bgController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _cerrarSesion() async {
    final googleAuth = GoogleAuthService();
    await googleAuth.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  // ==========================================
  // DISEÑO INTERNO: FEED DINÁMICO
  // ==========================================
  Widget _buildInicioTab(String nombreUsuario) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Descubre,', style: TextStyle(fontSize: 16, color: TruequiColors.textoOscuro.withValues(alpha: 0.6), fontWeight: FontWeight.w500)),
                    Text(nombreUsuario, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: TruequiColors.purpura, letterSpacing: -0.5)),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _cerrarSesion,
                      icon: const Icon(Icons.logout_rounded, color: TruequiColors.purpura),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
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
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_rounded, size: 16, color: TruequiColors.purpura),
                  const SizedBox(width: 8),
                  Text('Cerca de UAQ - Querétaro', style: TextStyle(fontSize: 13, color: TruequiColors.textoOscuro.withValues(alpha: 0.8), fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
            child: const Text('Para ti', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: TruequiColors.textoOscuro)),
          ),
        ),
        
        // CUADRÍCULA DINÁMICA DE PRODUCTOS DESDE AWS
        _isLoading 
          ? const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: TruequiColors.purpura)))
          : SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final producto = _productos[index];
                    // Se pasa el context a la función
                    return _buildProductoCard(context, producto); 
                  },
                  childCount: _productos.length,
                ),
              ),
            ),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  // AHORA RECIBE EL BUILDCONTEXT
  Widget _buildProductoCard(BuildContext context, Map<String, dynamic> producto) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetalleProductoPage(producto: producto),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 2),
          image: DecorationImage(
            image: NetworkImage(producto['imagenUrl']), 
            fit: BoxFit.cover,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Stack(
          children: [
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter, end: Alignment.topCenter,
                    colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 12, left: 12, right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: TruequiColors.amarillo, borderRadius: BorderRadius.circular(8)),
                    child: Text(producto['categoria'], style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    producto['titulo'], 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  Text('\$${producto['precio']}', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String nombreUsuario = widget.correo.split('@').first;
    nombreUsuario = nombreUsuario[0].toUpperCase() + nombreUsuario.substring(1);
    final size = MediaQuery.of(context).size;

    final List<Widget> pantallas = [
      _buildInicioTab(nombreUsuario),           
      const ExplorarPage(),                     
      const PublicarPage(),                     
      const ChatsPage(),                        
      PerfilPage(correo: widget.correo),        
    ];

    return Scaffold(
      backgroundColor: TruequiColors.fondoClaro,
      extendBody: true,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: size.height * 0.05 + (math.sin(_bgController.value * 2 * math.pi) * 40),
                    left: size.width * 0.2 + (math.cos(_bgController.value * 2 * math.pi) * 40),
                    child: Container(width: size.width * 0.7, height: size.width * 0.7, decoration: BoxDecoration(shape: BoxShape.circle, color: TruequiColors.purpura.withValues(alpha: 0.25))),
                  ),
                  Positioned(
                    bottom: size.height * 0.15 + (math.cos(_bgController.value * 2 * math.pi) * 60),
                    right: size.width * -0.1 + (math.sin(_bgController.value * 2 * math.pi) * 50),
                    child: Container(width: size.width * 0.85, height: size.width * 0.85, decoration: BoxDecoration(shape: BoxShape.circle, color: TruequiColors.amarillo.withValues(alpha: 0.15))),
                  ),
                ],
              );
            },
          ),
          BackdropFilter(filter: ImageFilter.blur(sigmaX: 70.0, sigmaY: 70.0), child: Container(color: Colors.white.withValues(alpha: 0.4))), 
          
          SafeArea(
            bottom: false,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: IndexedStack(index: _indiceNavegacion, children: pantallas),
              ),
            ),
          ),
          
          Positioned(
            bottom: 30, left: 30, right: 30,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                    boxShadow: [BoxShadow(color: TruequiColors.purpura.withValues(alpha: 0.1), blurRadius: 30, offset: const Offset(0, 10))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(Icons.home_filled, 0),
                      _buildNavItem(Icons.explore_rounded, 1),
                      GestureDetector(
                        onTap: () => setState(() => _indiceNavegacion = 2),
                        child: Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(
                            color: _indiceNavegacion == 2 ? TruequiColors.amarillo : TruequiColors.purpura,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: TruequiColors.purpura.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
                          ),
                          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                        ),
                      ),
                      _buildNavItem(Icons.chat_bubble_rounded, 3),
                      _buildNavItem(Icons.person_rounded, 4),
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

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = _indiceNavegacion == index;
    return GestureDetector(
      onTap: () => setState(() => _indiceNavegacion = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: isSelected ? TruequiColors.amarillo.withValues(alpha: 0.15) : Colors.transparent, borderRadius: BorderRadius.circular(20)),
        child: Icon(icon, color: isSelected ? TruequiColors.amarillo : Colors.grey.shade400, size: 26),
      ),
    );
  }
}