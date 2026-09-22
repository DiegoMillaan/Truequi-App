import 'dart:ui';
import 'package:flutter/material.dart';
import 'services/google_auth_service.dart';
import 'home_web.dart';

class PerfilWeb extends StatelessWidget {
  final Map<String, dynamic> usuario;

  const PerfilWeb({super.key, required this.usuario});

  Future<void> _cerrarSesion(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cerrando sesión...'), duration: Duration(seconds: 1))
    );
    await GoogleAuthService().signOut(); 
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeWeb()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final nombre = usuario['nombre'] ?? usuario['correo'].toString().split('@')[0];
    final correo = usuario['correo'] ?? '';
    final foto = usuario['foto'];

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: TruequiColors.textoOscuro)),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: RadialGradient(colors: [Color(0xFFE5DFFF), Color(0xFFF0F2F5)], radius: 1.5))),
          BackdropFilter(filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50), child: Container(color: Colors.transparent)),
          Center(
            // Añadimos un ScrollView para evitar problemas en monitores pequeños
            child: SingleChildScrollView(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: 600, 
                    // 1. ELIMINAMOS la propiedad 'height' fija
                    padding: const EdgeInsets.all(50),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.4), borderRadius: BorderRadius.circular(40), border: Border.all(color: Colors.white.withOpacity(0.8), width: 2), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30)]),
                    child: Column(
                      // 2. INDICAMOS que la tarjeta mida lo necesario para sus elementos
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: TruequiColors.purpura, width: 3)),
                          child: CircleAvatar(radius: 60, backgroundColor: TruequiColors.purpura.withOpacity(0.2), backgroundImage: foto != null ? NetworkImage(foto) : null, child: foto == null ? const Icon(Icons.person, size: 60, color: TruequiColors.purpura) : null),
                        ),
                        const SizedBox(height: 20),
                        Text(nombre, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: TruequiColors.textoOscuro)),
                        Text(correo, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                        
                        const SizedBox(height: 25),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildStatBadge(Icons.star_rounded, '4.9', TruequiColors.amarillo),
                            const SizedBox(width: 15),
                            _buildStatBadge(Icons.handshake_rounded, '12 Trueques', TruequiColors.purpura),
                          ],
                        ),
                        const SizedBox(height: 25),
                        TextButton.icon(
                          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Modo edición activado ✏️'))), 
                          icon: const Icon(Icons.edit_rounded, color: TruequiColors.purpura), 
                          label: const Text('Editar Perfil', style: TextStyle(color: TruequiColors.purpura, fontWeight: FontWeight.bold))
                        ),
                        
                        // 3. REEMPLAZAMOS Spacer() por un SizedBox exacto
                        const SizedBox(height: 40),
                        
                        OutlinedButton.icon(onPressed: () => _cerrarSesion(context), icon: const Icon(Icons.logout), label: const Text('Cerrar Sesión'), style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent, width: 2), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))))
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}