import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui'; // Para el efecto de cristal (BackdropFilter)
import 'dart:math' as math; // Para la animación fluida
import 'home_page.dart';

// ==========================================
// PALETA TRUEQUI
// ==========================================
class TruequiColors {
  static const Color purpura = Color(0xFF6B42E0);
  static const Color amarillo = Color(0xFFFFA800);
  static const Color textoOscuro = Color(0xFF101828);
  static const Color fondoClaro = Color(0xFFF8F9FA);
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// Agregamos SingleTickerProviderStateMixin para poder usar animaciones a 60fps
class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _cargando = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    // Controlador de la animación de fondo (dura 10 segundos y se repite infinito)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE BACKEND INTACTA ---
  Future<void> _iniciarSesion() async {
    final esValido = _formKey.currentState!.validate();
    if (!esValido) return;

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

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 800), // Lenta y fluida
            pageBuilder: (context, animation, secondaryAnimation) => HomePage(correo: correo),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              // Animación de Zoom in
              var scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );
              // Animación de desvanecimiento cruzado
              var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              );

              return FadeTransition(
                opacity: fadeAnimation,
                child: ScaleTransition(
                  scale: scaleAnimation,
                  child: child,
                ),
              );
            },
          ),
        );
      } else {
        final mensajeError = data['error'] ?? data['message'] ?? 'Error de autenticación';
        _mostrarSnackBar(mensajeError, Colors.redAccent);
      }
    } catch (e) {
      _mostrarSnackBar('Error de conexión: $e', TruequiColors.amarillo);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mostrarSnackBar(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  bool _validarEmail(String email) => RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  String? _validarPassword(String? value) => (value == null || value.trim().isEmpty) ? 'Ingresa tu contraseña' : null;

  // --- INTERFAZ PREMIUM (GLASSMORPHISM) ---
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: TruequiColors.fondoClaro,
      // Usamos un Stack para poner capas una sobre otra
      body: Stack(
        children: [
          // CAPA 1: Fondo dinámico animado
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Stack(
                children: [
                  // Orbe Morado
                  Positioned(
                    top: size.height * 0.1 + (math.sin(_animationController.value * 2 * math.pi) * 80),
                    left: size.width * 0.1 + (math.cos(_animationController.value * 2 * math.pi) * 50),
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: TruequiColors.purpura.withOpacity(0.5),
                      ),
                    ),
                  ),
                  // Orbe Amarillo
                  Positioned(
                    bottom: size.height * 0.1 + (math.cos(_animationController.value * 2 * math.pi) * 60),
                    right: size.width * 0.1 + (math.sin(_animationController.value * 2 * math.pi) * 70),
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: TruequiColors.amarillo.withOpacity(0.4),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // CAPA 2: Desenfoque de cristal (Magia pura)
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 60.0, sigmaY: 60.0),
            child: Container(color: Colors.white.withOpacity(0.1)),
          ),

          // CAPA 3: Interfaz de Usuario
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo
                      const Icon(Icons.swap_horizontal_circle_rounded, size: 80, color: TruequiColors.purpura),
                      const SizedBox(height: 16),
                      const Text(
                        'truequi',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 46, fontWeight: FontWeight.w900, color: TruequiColors.purpura, letterSpacing: -1.5),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Cambia algo, gana mucho.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: TruequiColors.textoOscuro, fontWeight: FontWeight.w600, height: 1.3),
                      ),
                      const SizedBox(height: 40),

                      // Tarjeta de Formulario (Efecto Vidrio)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.6), // Semitransparente
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Input Correo
                            TextFormField(
                              controller: _correoController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'Truequi Email',
                                prefixIcon: const Icon(Icons.alternate_email_rounded, color: TruequiColors.purpura),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.5),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: TruequiColors.purpura, width: 2)),
                              ),
                              validator: (value) => _validarEmail(value ?? '') ? null : 'Ingresa un correo válido',
                            ),
                            const SizedBox(height: 16),
                            // Input Contraseña
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'Truequi Password',
                                prefixIcon: const Icon(Icons.lock_outline_rounded, color: TruequiColors.purpura),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.5),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: TruequiColors.purpura, width: 2)),
                              ),
                              validator: _validarPassword,
                            ),
                            const SizedBox(height: 30),
                            // Botón Ingresar
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _cargando ? null : _iniciarSesion,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: TruequiColors.amarillo,
                                  elevation: 5,
                                  shadowColor: TruequiColors.amarillo.withOpacity(0.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: _cargando
                                    ? const CircularProgressIndicator(color: TruequiColors.textoOscuro, strokeWidth: 3)
                                    : const Text('Comenzar a truequiar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: TruequiColors.textoOscuro)),
                              ),
                            ),
                          ],
                        ),
                      ),
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
}