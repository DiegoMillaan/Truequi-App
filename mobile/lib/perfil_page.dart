import 'package:flutter/material.dart';
import 'home_page.dart';
import 'login_screen.dart';
import '../services/google_auth_service.dart';

class PerfilPage extends StatelessWidget {
  final String correo;
  
  const PerfilPage({super.key, required this.correo});

  // Función para cerrar sesión desde el perfil
  Future<void> _cerrarSesion(BuildContext context) async {
    final googleAuth = GoogleAuthService();
    await googleAuth.signOut();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Extraemos el nombre del correo y lo capitalizamos
    String nombreUsuario = correo.split('@').first;
    nombreUsuario = nombreUsuario[0].toUpperCase() + nombreUsuario.substring(1);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ==========================================
        // HEADER: TÍTULO
        // ==========================================
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: Row(
              children: [
                const Icon(Icons.person_rounded, color: TruequiColors.purpura, size: 32),
                const SizedBox(width: 12),
                const Text(
                  'Mi Perfil',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: TruequiColors.purpura,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ==========================================
        // TARJETA PRINCIPAL DEL USUARIO
        // ==========================================
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: TruequiColors.fondoClaro,
                      shape: BoxShape.circle,
                      border: Border.all(color: TruequiColors.purpura.withValues(alpha: 0.3), width: 2),
                    ),
                    child: const CircleAvatar(
                      radius: 40,
                      backgroundColor: TruequiColors.amarillo,
                      child: Icon(Icons.person_rounded, size: 40, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Nombre y Correo
                  Text(
                    nombreUsuario,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: TruequiColors.textoOscuro),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    correo,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  
                  // Ubicación
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: TruequiColors.purpura.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on_rounded, size: 16, color: TruequiColors.purpura),
                        const SizedBox(width: 6),
                        Text(
                          'Querétaro, Qro.',
                          style: TextStyle(fontWeight: FontWeight.bold, color: TruequiColors.purpura.withValues(alpha: 0.8), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // ==========================================
        // ESTADÍSTICAS (Bento Grid)
        // ==========================================
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    titulo: 'Trueques',
                    valor: '12',
                    icono: Icons.swap_horiz_rounded,
                    color: TruequiColors.purpura,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    titulo: 'Valoración',
                    valor: '4.9',
                    icono: Icons.star_rounded,
                    color: TruequiColors.amarillo,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // ==========================================
        // MENÚ DE OPCIONES
        // ==========================================
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Column(
                children: [
                  _buildMenuOption(context, 'Mis Artículos', Icons.inventory_2_rounded, onTap: () {}),
                  Divider(height: 1, color: Colors.grey.withValues(alpha: 0.2)),
                  _buildMenuOption(context, 'Favoritos', Icons.favorite_border_rounded, onTap: () {}),
                  Divider(height: 1, color: Colors.grey.withValues(alpha: 0.2)),
                  _buildMenuOption(context, 'Configuración', Icons.settings_rounded, onTap: () {}),
                  Divider(height: 1, color: Colors.grey.withValues(alpha: 0.2)),
                  _buildMenuOption(
                    context, 
                    'Cerrar Sesión', 
                    Icons.logout_rounded, 
                    isDestructive: true,
                    onTap: () => _cerrarSesion(context),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Espacio para la barra flotante inferior
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  // ==========================================
  // WIDGETS REUTILIZABLES
  // ==========================================
  Widget _buildStatCard({required String titulo, required String valor, required IconData icono, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: color, size: 28),
          const SizedBox(height: 12),
          Text(valor, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: TruequiColors.textoOscuro)),
          Text(titulo, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildMenuOption(BuildContext context, String titulo, IconData icono, {required VoidCallback onTap, bool isDestructive = false}) {
    final color = isDestructive ? Colors.redAccent : TruequiColors.textoOscuro;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDestructive ? Colors.red.withValues(alpha: 0.1) : TruequiColors.fondoClaro,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icono, size: 20, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                titulo,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}