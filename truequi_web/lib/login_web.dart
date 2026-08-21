import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'dart:math' as math;
import 'home_web.dart'; // Crearemos este archivo en el siguiente paso

class TruequiColors {
  static const Color purpura = Color(0xFF6B42E0);
  static const Color amarillo = Color(0xFFFFA800);
  static const Color textoOscuro = Color(0xFF101828);
}

class LoginWeb extends StatefulWidget {
  const LoginWeb({super.key});

  @override
  State<LoginWeb> createState() => _LoginWebState();
}

class _LoginWebState extends State<LoginWeb> with SingleTickerProviderStateMixin {
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _cargando = false;
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    // Animación de los orbes para pantallas grandes
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

  // --- LÓGICA DE BACKEND AWS (Intacta) ---
  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);

    try {
      final correo = _correoController.text.trim().toLowerCase();
      final password = _passwordController.text.trim();
      final url = Uri.parse('https://16663yaped.execute-api.us-east-1.amazonaws.com/dev/login');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'correo': correo, 'password': password}),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        // Transición Hipnótica: El cristal se desvanece mientras la nueva pantalla hace zoom in
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 1200),
            pageBuilder: (context, animation, secondaryAnimation) => HomeWeb(correo: correo),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                  ),
                  child: child,
                ),
              );
            },
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error de autenticación')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error de conexión: $e')));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Stack(
        children: [
          // 1. FONDO VIVO PANORÁMICO
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: size.height * 0.2 + (math.sin(_bgController.value * 2 * math.pi) * 150),
                    left: size.width * 0.2 + (math.cos(_bgController.value * 2 * math.pi) * 100),
                    child: Container(
                      width: size.width * 0.4,
                      height: size.width * 0.4,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: TruequiColors.purpura.withOpacity(0.4)),
                    ),
                  ),
                  Positioned(
                    bottom: size.height * 0.1 + (math.cos(_bgController.value * 2 * math.pi) * 100),
                    right: size.width * 0.15 + (math.sin(_bgController.value * 2 * math.pi) * 150),
                    child: Container(
                      width: size.width * 0.35,
                      height: size.width * 0.35,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: TruequiColors.amarillo.withOpacity(0.3)),
                    ),
                  ),
                ],
              );
            },
          ),
          
          // Desenfoque global extremo para la web
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 100.0, sigmaY: 100.0),
            child: Container(color: Colors.white.withOpacity(0.2)),
          ),

          // 2. CONTENEDOR CENTRAL DE CRISTAL
          Center(
            child: Container(
              width: 450, // Ancho fijo para web
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 40, offset: const Offset(0, 20)),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sync_rounded, size: 60, color: TruequiColors.purpura),
                    const SizedBox(height: 16),
                    const Text('Bienvenido a truequi', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: TruequiColors.textoOscuro)),
                    const SizedBox(height: 8),
                    Text('Cambia algo, gana mucho.', style: TextStyle(fontSize: 16, color: TruequiColors.textoOscuro.withOpacity(0.7))),
                    const SizedBox(height: 40),
                    
                    TextFormField(
                      controller: _correoController,
                      decoration: InputDecoration(
                        labelText: 'Correo electrónico',
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.7),
                        prefixIcon: const Icon(Icons.email_outlined, color: TruequiColors.purpura),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.7),
                        prefixIcon: const Icon(Icons.lock_outline, color: TruequiColors.purpura),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _cargando ? null : _iniciarSesion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TruequiColors.purpura,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: _cargando
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Iniciar Sesión', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}