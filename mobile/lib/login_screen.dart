import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui'; 
import 'dart:math' as math; 
import 'home_page.dart';
import 'services/google_auth_service.dart';
import 'services/auth_service.dart'; 
import 'registro_screen.dart';

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
  final AuthService _authService = AuthService(); 

  bool _cargando = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);

    try {
      final correo = _correoController.text.trim().toLowerCase();
      final password = _passwordController.text.trim();
      final response = await http.post(
        Uri.parse('https://16663yaped.execute-api.us-east-1.amazonaws.com/dev/login'),
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
              var scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
              var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut));
              return FadeTransition(opacity: fadeAnimation, child: ScaleTransition(scale: scaleAnimation, child: child));
            },
          ),
        );
      } else {
        _mostrarSnackBar(data['error'] ?? data['message'] ?? 'Error de autenticación', Colors.redAccent);
      }
    } catch (e) {
      _mostrarSnackBar('Error de conexión: $e', TruequiColors.amarillo);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mostrarSnackBar(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), backgroundColor: color, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
  }

  bool _validarEmail(String email) {
    final emailLimpio = email.trim();
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(emailLimpio)) return false;
    if (emailLimpio.startsWith('a@a') || emailLimpio.contains('test@test') || emailLimpio.length < 8) return false;
    return true;
  }

  Widget _buildLogoBiologico() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final avance = _animationController.value * 2 * math.pi; 
        final latido = 1.0 + (math.sin(avance * 6) * 0.04); 
        final levitacion = math.sin(avance) * 8.0; 

        return Transform.translate(
          offset: Offset(0, levitacion),
          child: Transform.scale(
            scale: latido,
            child: SizedBox(
              width: 150, height: 150,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(width: 90, height: 90, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: TruequiColors.purpura.withOpacity(0.5), blurRadius: 35, spreadRadius: 5, offset: const Offset(0, 15))])),
                  Transform.rotate(angle: avance, child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1), border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5)), child: Icon(Icons.sync_rounded, size: 75, color: TruequiColors.purpura.withOpacity(0.95)))),
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
                  Positioned(top: size.height * 0.1 + (math.sin(_animationController.value * 2 * math.pi) * 80), left: size.width * 0.1 + (math.cos(_animationController.value * 2 * math.pi) * 50), child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: TruequiColors.purpura.withOpacity(0.4)))),
                  Positioned(bottom: size.height * 0.1 + (math.cos(_animationController.value * 2 * math.pi) * 60), right: size.width * 0.1 + (math.sin(_animationController.value * 2 * math.pi) * 70), child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: TruequiColors.amarillo.withOpacity(0.3)))),
                ],
              );
            },
          ),
          BackdropFilter(filter: ImageFilter.blur(sigmaX: 80.0, sigmaY: 80.0), child: Container(color: Colors.black.withOpacity(0.2))),
          
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
                      const Text('truequi', textAlign: TextAlign.center, style: TextStyle(fontSize: 46, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1.5)),
                      const SizedBox(height: 8),
                      Text('Cambia algo, gana mucho.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w600, height: 1.3)),
                      const SizedBox(height: 40),
                      
                      ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                          child: Container(
                            padding: const EdgeInsets.all(30),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(40), border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5)),
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _correoController, keyboardType: TextInputType.emailAddress, style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(labelText: 'Truequi Email', labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)), prefixIcon: const Icon(Icons.alternate_email_rounded, color: TruequiColors.amarillo), filled: true, fillColor: Colors.white.withOpacity(0.1), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.5), width: 1.5))),
                                  validator: (value) => _validarEmail(value ?? '') ? null : 'Ingresa un correo real válido',
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _passwordController, obscureText: true, style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(labelText: 'Truequi Password', labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)), prefixIcon: const Icon(Icons.lock_outline_rounded, color: TruequiColors.amarillo), filled: true, fillColor: Colors.white.withOpacity(0.1), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.5), width: 1.5))),
                                  validator: (v) => v != null && v.length >= 6 ? null : 'Mínimo 6 caracteres',
                                ),
                                const SizedBox(height: 30),
                                
                                SizedBox(
                                  width: double.infinity, height: 56,
                                  child: ElevatedButton(
                                    onPressed: _cargando ? null : _iniciarSesion,
                                    style: ElevatedButton.styleFrom(backgroundColor: TruequiColors.purpura, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                                    child: _cargando ? const CircularProgressIndicator(color: Colors.white) : const Text('Comenzar a truequiar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                SizedBox(
                                  width: double.infinity, height: 56,
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.05), side: BorderSide(color: Colors.white.withOpacity(0.3), width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                                    onPressed: () async {
                                      final user = await _googleAuthService.signInWithGoogle();
                                      if (user != null) {
                                        final idToken = (await user.authentication).idToken;
                                        if (idToken != null && await _authService.loginConGoogle(idToken) && mounted) {
                                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage(correo: user.email)));
                                          return;
                                        }
                                      }
                                      if (mounted) _mostrarSnackBar('No se pudo completar el acceso', Colors.redAccent);
                                    },
                                    icon: const Icon(Icons.g_mobiledata, size: 32, color: Colors.white),
                                    label: const Text('Continuar con Google', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('¿No tienes cuenta?', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                                    TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegistroScreen())), child: const Text('Regístrate', style: TextStyle(fontWeight: FontWeight.bold, color: TruequiColors.amarillo))),
                                  ],
                                ),
                              ],
                            ),
                          ),
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