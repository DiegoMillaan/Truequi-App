import 'dart:ui';
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'login_screen.dart';
import '../services/google_auth_service.dart';

class PerfilPage extends StatelessWidget {
  final String correo;
  
  const PerfilPage({super.key, required this.correo});

  Future<void> _cerrarSesion(BuildContext context) async {
    await GoogleAuthService().signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    String nombreUsuario = correo.split('@').first;
    nombreUsuario = nombreUsuario[0].toUpperCase() + nombreUsuario.substring(1);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
            child: Row(
              children: [
                const Icon(Icons.person_rounded, color: TruequiColors.amarillo, size: 32),
                const SizedBox(width: 12),
                const Text('Mi Perfil', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
              ],
            ),
          ),
        ),

        // TARJETA PRINCIPAL
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(40), border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5)),
                  child: Column(
                    children: [
                      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: TruequiColors.purpura.withOpacity(0.5), width: 2)), child: const CircleAvatar(radius: 45, backgroundColor: TruequiColors.purpura, child: Icon(Icons.person_rounded, size: 45, color: Colors.white))),
                      const SizedBox(height: 20),
                      Text(nombreUsuario, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(correo, style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5))),
                      const SizedBox(height: 20),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: TruequiColors.amarillo.withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: TruequiColors.amarillo.withOpacity(0.5))), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.location_on_rounded, size: 16, color: TruequiColors.amarillo), SizedBox(width: 6), Text('Querétaro, Qro.', style: TextStyle(fontWeight: FontWeight.bold, color: TruequiColors.amarillo, fontSize: 13))])),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),

        // ESTADÍSTICAS BENTO GRID
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(child: _buildStatCard('Trueques', '12', Icons.swap_horiz_rounded, TruequiColors.purpura)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Valoración', '4.9', Icons.star_rounded, TruequiColors.amarillo)),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),

        // MENÚ DE OPCIONES
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5)),
                  child: Column(
                    children: [
                      _buildMenuOption(context, 'Mis Artículos', Icons.inventory_2_rounded, () {}),
                      Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                      _buildMenuOption(context, 'Favoritos', Icons.favorite_border_rounded, () {}),
                      Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                      _buildMenuOption(context, 'Configuración', Icons.settings_rounded, () {}),
                      Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                      _buildMenuOption(context, 'Cerrar Sesión', Icons.logout_rounded, () => _cerrarSesion(context), isDestructive: true),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 140)),
      ],
    );
  }

  Widget _buildStatCard(String titulo, String valor, IconData icono, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icono, color: color, size: 30),
              const SizedBox(height: 15),
              Text(valor, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
              Text(titulo, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.6), fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuOption(BuildContext context, String titulo, IconData icono, VoidCallback onTap, {bool isDestructive = false}) {
    final color = isDestructive ? Colors.redAccent : Colors.white;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: isDestructive ? Colors.red.withOpacity(0.2) : Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(14)), child: Icon(icono, size: 22, color: color)),
            const SizedBox(width: 16),
            Expanded(child: Text(titulo, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color))),
            Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }
}