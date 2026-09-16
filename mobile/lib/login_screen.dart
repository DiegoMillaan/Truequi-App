import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui'; 
import 'dart:math' as math; 
import 'home_page.dart';
import 'services/google_auth_service.dart';
import 'services/auth_service.dart'; // Importado para conectar con el backend de AWS
import 'registro_screen.dart';

// ==========================================
// PALETA TRUEQUI
// ==========================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  final AuthService _authService = AuthService(); // Instancia del servicio AWS para autenticación

  bool _cargando = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
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
            transitionDuration: const Duration(milliseconds: 800),
            pageBuilder: (context, animation, secondaryAnimation) => HomePage(correo: correo),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              var scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );
              var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              );

              return FadeTransition(
                opacity: fadeAnimation,
                child: ScaleTransition(scale: scaleAnimation, child: child),
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

  // NUEVO LOGO ANIMADO
  Widget _buildLogoBiologico() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final avance = _animationController.value * 2 * math.pi; 
        
        final anguloBase = avance; 
        final anguloCliente = avance * 2.0; 
        final anguloLimpiador = avance * -3.0; 
        
        final latido = 1.0 + (math.sin(avance * 6) * 0.04); 
        final levitacion = math.sin(avance) * 8.0; 

        return Transform.translate(
          offset: Offset(0, levitacion),
          child: Transform.scale(
            scale: latido,
            child: SizedBox(
              width: 150,
              height: 150,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: TruequiColors.purpura.withValues(alpha: 0.5),
                          blurRadius: 35,
                          spreadRadius: 5,
                          offset: const Offset(0, 15), 
                        ),
                        BoxShadow(
                          color: TruequiColors.amarillo.withValues(alpha: 0.3),
                          blurRadius: 25,
                          spreadRadius: -5,
                          offset: const Offset(0, -5), 
                        ),
                      ],
                    ),
                  ),
                  Transform.rotate(
                    angle: anguloBase,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15), 
                        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                      ),
                      child: Icon(Icons.sync_rounded, size: 75, color: TruequiColors.purpura.withValues(alpha: 0.95)),
                    ),
                  ),
                  Transform.rotate(
                    angle: anguloCliente,
                    child: Transform.translate(
                      offset: const Offset(0, -50),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: TruequiColors.amarillo, 
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: TruequiColors.amarillo.withValues(alpha: 0.8), blurRadius: 10)],
                        ),
                      ),
                    ),
                  ),
                  Transform.rotate(
                    angle: anguloLimpiador,
                    child: Transform.translate(
                      offset: const Offset(0, 35),
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: TruequiColors.purpura, 
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5), 
                          boxShadow: [BoxShadow(color: TruequiColors.purpura, blurRadius: 8)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: TruequiColors.fondoClaro,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: size.height * 0.1 + (math.sin(_animationController.value * 2 * math.pi) * 80),
                    left: size.width * 0.1 + (math.cos(_animationController.value * 2 * math.pi) * 50),
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: TruequiColors.purpura.withValues(alpha: 0.5)),
                    ),
                  ),
                  Positioned(
                    bottom: size.height * 0.1 + (math.cos(_animationController.value * 2 * math.pi) * 60),
                    right: size.width * 0.1 + (math.sin(_animationController.value * 2 * math.pi) * 70),
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: TruequiColors.amarillo.withValues(alpha: 0.4)),
                    ),
                  ),
                ],
              );
            },
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 60.0, sigmaY: 60.0),
            child: Container(color: Colors.white.withValues(alpha: 0.1)),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildLogoBiologico(),
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
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.6), 
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10)),
                          ],
                        ),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _correoController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'Truequi Email',
                                prefixIcon: const Icon(Icons.alternate_email_rounded, color: TruequiColors.purpura),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.5),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: TruequiColors.purpura, width: 2)),
                              ),
                              validator: (value) => _validarEmail(value ?? '') ? null : 'Ingresa un correo válido',
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'Truequi Password',
                                prefixIcon: const Icon(Icons.lock_outline_rounded, color: TruequiColors.purpura),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.5),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: TruequiColors.purpura, width: 2)),
                              ),
                              validator: _validarPassword,
                            ),
                            const SizedBox(height: 30),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _cargando ? null : _iniciarSesion,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: TruequiColors.amarillo,
                                  elevation: 5,
                                  shadowColor: TruequiColors.amarillo.withValues(alpha: 0.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: _cargando
                                    ? const CircularProgressIndicator(color: TruequiColors.textoOscuro, strokeWidth: 3)
                                    : const Text('Comenzar a truequiar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: TruequiColors.textoOscuro)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Botón de Google Integrado con AWS
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                onPressed: () async {
                                  // 1. Obtener usuario de Google
                                  final user = await _googleAuthService.signInWithGoogle();
                                  
                                  if (user != null) {
                                    // 2. Extraer el idToken y enviarlo a AWS
                                    final googleAuth = await user.authentication;
                                    final idToken = googleAuth.idToken;

                                    if (idToken != null) {
                                      bool backendExito = await _authService.loginConGoogle(idToken);

                                      if (backendExito && mounted) {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => HomePage(correo: user.email),
                                          ),
                                        );
                                        return;
                                      }
                                    }
                                  }
                                  
                                  if (mounted) {
                                    _mostrarSnackBar('No se pudo completar el acceso con Google o AWS', Colors.redAccent);
                                  }
                                },
                                icon: const Icon(Icons.g_mobiledata, size: 32, color: TruequiColors.purpura),
                                label: const Text(
                                  'Continuar con Google',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: TruequiColors.textoOscuro),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Enlace para ir a la Pantalla de Registro
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  '¿No tienes una cuenta?',
                                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const RegistroScreen()),
                                    );
                                  },
                                  child: const Text(
                                    'Regístrate aquí',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: TruequiColors.purpura,
                                    ),
                                  ),
                                ),
                              ],
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