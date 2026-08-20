import 'package:flutter/material.dart';
import 'login_screen.dart';

// ==========================================
// PALETA DE COLORES TRAP/TRUEQUI
// ==========================================
class TruequiColors {
  static const Color menta = Color(0xFF00C896);
  static const Color purpura = Color(0xFF6B42E0);
  static const Color amarillo = Color(0xFFFFA800);
  static const Color textoOscuro = Color(0xFF101828);
  static const Color fondoClaro = Color(0xFFF8F9FA);
}

class HomePage extends StatefulWidget {
  final String correo;

  const HomePage({super.key, required this.correo});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TruequiColors.fondoClaro,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/logo.png',
              height: 32,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.swap_horizontal_circle,
                color: TruequiColors.menta,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Truequi',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: TruequiColors.textoOscuro,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: TruequiColors.textoOscuro),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: TruequiColors.purpura),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saludo de Bienvenida usando el parámetro widget.correo
            Text(
              '¡Hola, ${widget.correo.split('@').first}!',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: TruequiColors.textoOscuro,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.correo,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Barra de Búsqueda (Placeholder)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, color: Colors.grey),
                  SizedBox(width: 10),
                  Text(
                    'Busca artículos',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // SECCIÓN 1: PRODUCTOS DESTACADOS
            const Text(
              'Destacados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: TruequiColors.textoOscuro,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 190,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 4,
                itemBuilder: (context, index) {
                  return const TarjetaProductoHorizontalPlaceholder();
                },
              ),
            ),
            const SizedBox(height: 28),

            // SECCIÓN 2: AGREGADOS RECIENTEMENTE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recientes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: TruequiColors.textoOscuro,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Ver todo',
                    style: TextStyle(color: TruequiColors.purpura),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Grid para Recientes (Bosquejo)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
                return const TarjetaProductoVerticalPlaceholder();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// COMPONENTES DE BOSQUEJO (PLACEHOLDERS)
// ==========================================

class TarjetaProductoHorizontalPlaceholder extends StatelessWidget {
  const TarjetaProductoHorizontalPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: const Center(
                child: Icon(Icons.image_outlined, color: Colors.grey, size: 36),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 12,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 10,
                  width: 45,
                  decoration: BoxDecoration(
                    color: TruequiColors.menta.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TarjetaProductoVerticalPlaceholder extends StatelessWidget {
  const TarjetaProductoVerticalPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: const Center(
                child: Icon(Icons.add_a_photo_outlined, color: Colors.grey, size: 32),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 10,
                  width: 60,
                  decoration: BoxDecoration(
                    color: TruequiColors.purpura.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}