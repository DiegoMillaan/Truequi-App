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
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
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
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);

    bool exito = await _authService.registrarUsuario(_nombreController.text.trim(), _correoController.text.trim().toLowerCase(), _passwordController.text.trim());
    setState(() => _cargando = false);

    if (!mounted) return;
    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('¡Cuenta creada con éxito!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: TruequiColors.purpura));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al crear la cuenta.'), backgroundColor: Colors.redAccent));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: TruequiColors.fondoClaro,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: Padding(padding: const EdgeInsets.only(left: 10), child: Container(margin: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle), child: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)))),
      ),
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
                      const Text('Crea tu cuenta', textAlign: TextAlign.center, style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1.0)),
                      const SizedBox(height: 6),
                      Text('Únete a la comunidad de Truequi.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w600)),
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
                                _buildGlassField(controller: _nombreController, label: 'Nombre Completo', icon: Icons.person_outline_rounded, validator: (v) => v != null && v.length >= 3 ? null : 'Nombre muy corto'),
                                const SizedBox(height: 16),
                                _buildGlassField(controller: _correoController, label: 'Correo Electrónico', icon: Icons.alternate_email_rounded, isEmail: true, validator: (v) => v != null && v.contains('@') ? null : 'Correo inválido'),
                                const SizedBox(height: 16),
                                _buildGlassField(controller: _passwordController, label: 'Contraseña', icon: Icons.lock_outline_rounded, isPass: true, validator: (v) => v != null && v.length >= 6 ? null : 'Mínimo 6 caracteres'),
                                const SizedBox(height: 30),
                                
                                SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: _cargando ? null : _registrar, style: ElevatedButton.styleFrom(backgroundColor: TruequiColors.purpura, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: _cargando ? const CircularProgressIndicator(color: Colors.white) : const Text('Registrarme', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)))),
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

  Widget _buildGlassField({required TextEditingController controller, required String label, required IconData icon, bool isEmail = false, bool isPass = false, required String? Function(String?) validator}) {
    return TextFormField(
      controller: controller, obscureText: isPass, keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text, style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(labelText: label, labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)), prefixIcon: Icon(icon, color: TruequiColors.amarillo), filled: true, fillColor: Colors.white.withOpacity(0.1), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.5), width: 1.5))),
      validator: validator,
    );
  }
}