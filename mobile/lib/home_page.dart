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
  static const Color fondoClaro = Color(0xFF0D0A15); // NUEVO: Modo Oscuro Profundo
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

  List<dynamic> _productos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
    _entranceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic)),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic)),
    );

    _entranceController.forward();
    _cargarProductos(); 
  }

  Future<void> _cargarProductos() async {
    try {
      final url = Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/productos');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          _productos = json.decode(response.body)['productos'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
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
  // FEED DINÁMICO: VITRINA LIQUID GLASS
  // ==========================================
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
                  onTap: _cerrarSesion,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5)),
                    child: const CircleAvatar(radius: 22, backgroundColor: TruequiColors.purpura, child: Icon(Icons.person_rounded, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Píldora Glass de ubicación
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
              ),
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

        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 25),
            child: Text('Top Matches 🔥', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
        
        // CUADRÍCULA DE CRISTAL
        _isLoading 
          ? const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: TruequiColors.amarillo)))
          : SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 20, crossAxisSpacing: 20, childAspectRatio: 0.65),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildProductoCardGlass(context, _productos[index]),
                  childCount: _productos.length,
                ),
              ),
            ),
        const SliverToBoxAdapter(child: SizedBox(height: 140)),
      ],
    );
  }