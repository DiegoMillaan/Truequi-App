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
  const HomePage({super.key, this.correo = ''}); 

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

  bool get isGuest => widget.correo.isEmpty;

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

  // ==========================================
  // ALGORITMO DE LAYOUT ASIMÉTRICO (ESTILO AMAZON)
  // ==========================================
  List<Widget> _construirGridDinamico() {
    List<Widget> filas = [];
    for (int i = 0; i < _productos.length; i++) {
      // Patrón: 1 Grande, 2 Pequeñas
      if (i % 3 == 0) {
        filas.add(Padding(padding: const EdgeInsets.only(bottom: 20), child: _buildCardGranFormato(context, _productos[i])));
      } else {
        if (i + 1 < _productos.length) {
          filas.add(Padding(padding: const EdgeInsets.only(bottom: 20), child: Row(
            children: [
              Expanded(child: _buildCardPequena(context, _productos[i])),
              const SizedBox(width: 20),
              Expanded(child: _buildCardPequena(context, _productos[i + 1])),
            ]
          )));
          i++; // Saltamos el siguiente porque ya lo agrupamos en esta fila
        } else {
          filas.add(Padding(padding: const EdgeInsets.only(bottom: 20), child: _buildCardGranFormato(context, _productos[i])));
        }
      }
    }
    return filas;
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
        const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 25), child: Text('Te podria gustar...', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)))),
        
        _isLoading 
          ? const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: TruequiColors.amarillo)))
          : SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              // Aquí inyectamos el nuevo layout asimétrico
              sliver: SliverList(delegate: SliverChildListDelegate(_construirGridDinamico())),
            ),
        const SliverToBoxAdapter(child: SizedBox(height: 140)),
      ],
    );
  }

  // ==========================================
  // TARJETA GIGANTE (MÁS INMERSIVA)
  // ==========================================
  Widget _buildCardGranFormato(BuildContext context, Map<String, dynamic> producto) {
    final String heroTag = 'img_${producto['id']}';
    
    return GestureDetector(
      onTap: () => Navigator.push(context, PageRouteBuilder(transitionDuration: const Duration(milliseconds: 600), reverseTransitionDuration: const Duration(milliseconds: 600), pageBuilder: (context, animation, secondaryAnimation) => DetalleProductoPage(producto: producto, miCorreo: widget.correo), transitionsBuilder: (context, animation, secondaryAnimation, child) { return FadeTransition(opacity: animation, child: child); })),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Container(
          height: 320, // Altura inmersiva
          decoration: BoxDecoration(border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5), borderRadius: BorderRadius.circular(32)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // IMAGEN DE FONDO CON ANIMACIÓN HERO
              Hero(tag: heroTag, child: Image.network(producto['imagenUrl'] ?? 'https://via.placeholder.com/400', fit: BoxFit.cover)),
              
              // GRADIENTE DE OSCURECIMIENTO
              Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.8)], stops: const [0.4, 1.0]))),
              
              // PANEL INFERIOR GLASSMORPHISM INTEGRADO
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), border: Border(top: BorderSide(color: Colors.white.withOpacity(0.2)))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: TruequiColors.amarillo.withOpacity(0.9), borderRadius: BorderRadius.circular(12)), child: Text(producto['categoria'], style: const TextStyle(color: TruequiColors.textoOscuro, fontSize: 11, fontWeight: FontWeight.w900))),
                          const SizedBox(height: 12),
                          Text(producto['titulo'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.white, height: 1.1), maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 8),
                          Row(children: [const Icon(Icons.attach_money_rounded, color: TruequiColors.amarillo, size: 20), Text('${producto['precio']} MXN', style: const TextStyle(color: TruequiColors.amarillo, fontSize: 18, fontWeight: FontWeight.bold))]),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TARJETAS PEQUEÑAS (EVITANDO AMONTONAMIENTO)
  // ==========================================
  Widget _buildCardPequena(BuildContext context, Map<String, dynamic> producto) {
    final String heroTag = 'img_${producto['id']}';
    
    return GestureDetector(
      onTap: () => Navigator.push(context, PageRouteBuilder(transitionDuration: const Duration(milliseconds: 600), reverseTransitionDuration: const Duration(milliseconds: 600), pageBuilder: (context, animation, secondaryAnimation) => DetalleProductoPage(producto: producto, miCorreo: widget.correo), transitionsBuilder: (context, animation, secondaryAnimation, child) { return FadeTransition(opacity: animation, child: child); })),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 260,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: Hero(tag: heroTag, child: Container(decoration: BoxDecoration(borderRadius: const BorderRadius.vertical(top: Radius.circular(26)), image: DecorationImage(image: NetworkImage(producto['imagenUrl'] ?? 'https://via.placeholder.com/150'), fit: BoxFit.cover))))),
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: TruequiColors.purpura.withOpacity(0.4), borderRadius: BorderRadius.circular(8)), child: Text(producto['categoria'], style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        Text(producto['titulo'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                        Text('\$${producto['precio']}', style: const TextStyle(color: TruequiColors.amarillo, fontSize: 16, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                )
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
      ExplorarPage(miCorreo: widget.correo),                     
      PublicarPage(miCorreo: widget.correo),                     
      ChatsPage(miCorreo: widget.correo),                        
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
          SafeArea(bottom: false, child: FadeTransition(opacity: _fadeAnimation, child: SlideTransition(position: _slideAnimation, child: IndexedStack(index: _indiceNavegacion, children: pantallas)))),
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
                        onTap: () { if (isGuest) { Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())); return; } setState(() => _indiceNavegacion = 2); },
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
      onTap: () { if (isGuest && (index == 2 || index == 3 || index == 4)) { Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())); return; } setState(() => _indiceNavegacion = index); },
      child: AnimatedContainer(duration: const Duration(milliseconds: 300), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent, borderRadius: BorderRadius.circular(20)), child: Icon(icon, color: isSelected ? TruequiColors.amarillo : Colors.white.withOpacity(0.5), size: 28)),
    );
  }
}