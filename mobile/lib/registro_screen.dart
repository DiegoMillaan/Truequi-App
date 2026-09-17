import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../services/auth_service.dart'; 
import 'home_page.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> with SingleTickerProviderStateMixin {
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  
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
    _nombreController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    final esValido = _formKey.currentState!.validate();
    if (!esValido) return;

    setState(() => _cargando = true);

    bool exito = await _authService.registrarUsuario(
      _nombreController.text.trim(),
      _correoController.text.trim().toLowerCase(),
      _passwordController.text.trim(),
    );

    setState(() => _cargando = false);

    if (!mounted) return;

    if (exito) {
      _mostrarSnackBar('¡Cuenta creada con éxito!', TruequiColors.purpura);
      Navigator.pop(context); // Regresa al Login
    } else {
      _mostrarSnackBar('Error al crear la cuenta. Intenta de nuevo.', Colors.redAccent);
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

  // 🛡️ VALIDACIÓN ESTRICTA ANTI-CORREOS BASURA (como a@a.com)
  bool _validarEmail(String email) {
    final emailLimpio = email.trim();
    
    // 1. Regex formal para correos electrónicos válidos
    final regexFormal = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!regexFormal.hasMatch(emailLimpio)) return false;

    // 2. Filtro estricto para bloquear correos de prueba o basura comunes
    if (emailLimpio.startsWith('a@a') || 
        emailLimpio.contains('test@test') || 
        emailLimpio.length < 8) {
      return false;
    }

    return true;
  }

  String? _validarPassword(String? value) {
    if (value == null || value.trim().length < 6) {
      return 'La contraseña debe tener mínimo 6 caracteres';
    }
    return null;
  }

  String? _validarNombre(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingresa tu nombre';
    }
    if (value.trim().length < 3) {
      return 'El nombre es muy corto';
    }
    return null;
  }

  // LOGO ANIMADO IDÉNTICO AL LOGIN
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
              width: 130,
              height: 130,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
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
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15), 
                        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                      ),
                      child: Icon(Icons.sync_rounded, size: 65, color: TruequiColors.purpura.withValues(alpha: 0.95)),
                    ),
                  ),
                  Transform.rotate(
                    angle: anguloCliente,
                    child: Transform.translate(
                      offset: const Offset(0, -42),
                      child: Container(
                        width: 16,
                        height: 16,
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
                      offset: const Offset(0, 30),
                      child: Container(
                        width: 12,
                        height: 12,
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
                      const SizedBox(height: 12),
                      const Text(
                        'Crea tu cuenta',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: TruequiColors.purpura, letterSpacing: -1.0),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Únete a la comunidad de Truequi.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: TruequiColors.textoOscuro, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 30),
                      
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
                              controller: _nombreController,
                              decoration: InputDecoration(
                                labelText: 'Nombre Completo',
                                prefixIcon: const Icon(Icons.person_outline_rounded, color: TruequiColors.purpura),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.5),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: TruequiColors.purpura, width: 2)),
                                errorStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                              validator: _validarNombre,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _correoController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'Correo Electrónico',
                                prefixIcon: const Icon(Icons.alternate_email_rounded, color: TruequiColors.purpura),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.5),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: TruequiColors.purpura, width: 2)),
                                errorStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                              validator: (value) => _validarEmail(value ?? '') ? null : 'Ingresa un correo electrónico real válido',
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                prefixIcon: const Icon(Icons.lock_outline_rounded, color: TruequiColors.purpura),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.5),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: TruequiColors.purpura, width: 2)),
                                errorStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                              validator: _validarPassword,
                            ),
                            const SizedBox(height: 30),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _cargando ? null : _registrar,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: TruequiColors.amarillo,
                                  elevation: 5,
                                  shadowColor: TruequiColors.amarillo.withValues(alpha: 0.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: _cargando
                                    ? const CircularProgressIndicator(color: TruequiColors.textoOscuro, strokeWidth: 3)
                                    : const Text('Registrarme', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: TruequiColors.textoOscuro)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                '¿Ya tienes cuenta? Inicia sesión',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: TruequiColors.purpura,
                                ),
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