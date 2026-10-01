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
  static const Color fondoClaro = Color(0xFF0D0A15);
}

class HomePage extends StatefulWidget {
  final String correo;
  const HomePage({super.key, this.correo = ''}); // Si está vacío, es modo Invitado

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _indiceNavegacion = 0;
  late AnimationController _bgController;
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<dynamic> _productos = [];
  bool _isLoading = true;

  bool get isGuest => widget.correo.isEmpty; // 🛡️ BANDERA DE SEGURIDAD

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
    _entranceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _entranceController, curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic)));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: _entranceController, curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic)));

    _entranceController.forward();
    _cargarProductos(); 
  }

  Future<void> _cargarProductos() async {
    try {
      final url = Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/productos');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() { _productos = json.decode(response.body)['productos']; _isLoading = false; });
      }
    } catch (e) { setState(() => _isLoading = false); }
  }

  @override
  void dispose() {
    _bgController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _cerrarSesion() async {
    await GoogleAuthService().signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (Route<dynamic> route) => false);
  }

  Widget _buildInicioTab(String nombreUsuario) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Descubre,', style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w500)),
                    Text(nombreUsuario, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                  ],
                ),
                GestureDetector(
                  // 🛡️ Si es invitado, el botón manda a Login. Si es usuario, cierra sesión.
                  onTap: isGuest ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())) : _cerrarSesion,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5)),
                    child: CircleAvatar(radius: 22, backgroundColor: TruequiColors.purpura, child: Icon(isGuest ? Icons.login_rounded : Icons.person_rounded, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_rounded, size: 18, color: TruequiColors.amarillo),
                  const SizedBox(width: 8),
                  Text('UAQ - Querétaro', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 25), child: Text('Podria gustarte', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)))),
        
        _isLoading 
          ? const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: TruequiColors.amarillo)))
          : SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 20, crossAxisSpacing: 20, childAspectRatio: 0.65),
                delegate: SliverChildBuilderDelegate((context, index) => _buildProductoCardGlass(context, _productos[index]), childCount: _productos.length),
              ),
            ),
        const SliverToBoxAdapter(child: SizedBox(height: 140)),
      ],
    );
  }

  Widget _buildProductoCardGlass(BuildContext context, Map<String, dynamic> producto) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DetalleProductoPage(producto: producto))),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: Container(decoration: BoxDecoration(borderRadius: const BorderRadius.vertical(top: Radius.circular(28)), image: DecorationImage(image: NetworkImage(producto['imagenUrl'] ?? 'https://via.placeholder.com/150'), fit: BoxFit.cover)))),
                Expanded(flex: 4, child: Padding(padding: const EdgeInsets.all(16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: TruequiColors.purpura.withOpacity(0.3), borderRadius: BorderRadius.circular(8), border: Border.all(color: TruequiColors.purpura.withOpacity(0.5))), child: Text(producto['categoria'], style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))), Text(producto['titulo'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis), Text('\$${producto['precio']}', style: const TextStyle(color: TruequiColors.amarillo, fontSize: 16, fontWeight: FontWeight.w900))]))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String nombreUsuario = isGuest ? 'Invitado' : widget.correo.split('@').first;
    if (!isGuest) nombreUsuario = nombreUsuario[0].toUpperCase() + nombreUsuario.substring(1);
    
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
                  Positioned(top: size.height * 0.1 + (math.sin(_bgController.value * 2 * math.pi) * 100), left: size.width * -0.2 + (math.cos(_bgController.value * 2 * math.pi) * 80), child: Container(width: size.width * 0.8, height: size.width * 0.8, decoration: BoxDecoration(shape: BoxShape.circle, color: TruequiColors.purpura.withOpacity(0.3)))),
                  Positioned(bottom: size.height * 0.2 + (math.cos(_bgController.value * 2 * math.pi) * 120), right: size.width * -0.2 + (math.sin(_bgController.value * 2 * math.pi) * 90), child: Container(width: size.width * 0.9, height: size.width * 0.9, decoration: BoxDecoration(shape: BoxShape.circle, color: TruequiColors.amarillo.withOpacity(0.2)))),
                ],
              );
            },
          ),
          BackdropFilter(filter: ImageFilter.blur(sigmaX: 100.0, sigmaY: 100.0), child: Container(color: Colors.black.withOpacity(0.2))), 
          
          SafeArea(
            bottom: false,
            child: FadeTransition(opacity: _fadeAnimation, child: SlideTransition(position: _slideAnimation, child: IndexedStack(index: _indiceNavegacion, children: pantallas))),
          ),
          
          Positioned(
            bottom: 30, left: 24, right: 24,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  height: 75,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(40), border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 10))]),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(Icons.home_rounded, 0),
                      _buildNavItem(Icons.explore_rounded, 1),
                      GestureDetector(
                        onTap: () {
                          if (isGuest) { Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())); return; }
                          setState(() => _indiceNavegacion = 2);
                        },
                        child: Container(width: 55, height: 55, decoration: BoxDecoration(gradient: const LinearGradient(colors: [TruequiColors.purpura, Color(0xFF8A62FF)], begin: Alignment.topLeft, end: Alignment.bottomRight), shape: BoxShape.circle, boxShadow: [BoxShadow(color: TruequiColors.purpura.withOpacity(0.5), blurRadius: 15, offset: const Offset(0, 5))]), child: const Icon(Icons.add_rounded, color: Colors.white, size: 32)),
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
      onTap: () {
        // 🛡️ BLOQUEO DE SEGURIDAD PARA INVITADOS EN PESTAÑAS PRIVADAS
        if (isGuest && (index == 2 || index == 3 || index == 4)) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
          return;
        }
        setState(() => _indiceNavegacion = index);
      },
      child: AnimatedContainer(duration: const Duration(milliseconds: 300), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent, borderRadius: BorderRadius.circular(20)), child: Icon(icon, color: isSelected ? TruequiColors.amarillo : Colors.white.withOpacity(0.5), size: 28)),
    );
  }
}