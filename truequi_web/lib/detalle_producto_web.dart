import 'dart:ui';
import 'package:flutter/material.dart';
import 'home_web.dart';

class DetalleProductoWeb extends StatelessWidget {
  final Map<String, dynamic> producto;

  const DetalleProductoWeb({super.key, required this.producto});

  @override
  Widget build(BuildContext context) {
    final titulo = producto['titulo'] ?? 'Sin título';
    final descripcion = producto['descripcion'] ?? 'Sin descripción';
    final precio = producto['precio']?.toString() ?? '0.0';
    final categoria = producto['categoria'] ?? 'General';
    final imagenUrl = producto['imagenUrl'];

    return Scaffold(
      backgroundColor: const Color(0xFF0D0A15), // Fondo oscuro para resaltar el cristal
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), 
          onPressed: () => Navigator.pop(context)
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border_rounded, color: Colors.white),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Artículo guardado en favoritos ❤️'), backgroundColor: TruequiColors.purpura)
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Enlace copiado al portapapeles 📋'), backgroundColor: TruequiColors.amarillo)
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: Stack(
        children: [
          // Orbes de luz de fondo
          Positioned(top: -100, right: -100, child: Container(width: 500, height: 500, decoration: BoxDecoration(shape: BoxShape.circle, color: TruequiColors.purpura.withOpacity(0.3)), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100), child: const SizedBox()))),
          Positioned(bottom: -100, left: -100, child: Container(width: 500, height: 500, decoration: BoxDecoration(shape: BoxShape.circle, color: TruequiColors.amarillo.withOpacity(0.2)), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100), child: const SizedBox()))),
          
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 600),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(40), border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5)),
                    child: Row(
                      children: [
                        // Mitad Izquierda: Imagen
                        Expanded(
                          flex: 5,
                          child: Container(
                            decoration: BoxDecoration(
                              image: imagenUrl != null ? DecorationImage(image: NetworkImage(imagenUrl), fit: BoxFit.cover) : null,
                              color: Colors.white.withOpacity(0.05),
                            ),
                            child: imagenUrl == null ? const Center(child: Icon(Icons.inventory_2_rounded, size: 100, color: Colors.white54)) : null,
                          ),
                        ),
                        // Mitad Derecha: Info
                        Expanded(
                          flex: 6,
                          child: Padding(
                            padding: const EdgeInsets.all(50.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: TruequiColors.amarillo.withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: TruequiColors.amarillo.withOpacity(0.5))), child: Text(categoria, style: const TextStyle(color: TruequiColors.amarillo, fontWeight: FontWeight.bold))),
                                const SizedBox(height: 20),
                                Text(titulo, style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1)),
                                const SizedBox(height: 15),
                                Text('Valor est: \$ $precio MXN', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: TruequiColors.purpura)),
                                const SizedBox(height: 30),
                                const Text('¿Qué ofrezco y qué busco?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70)),
                                const SizedBox(height: 10),
                                Text(descripcion, style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.8), height: 1.6)),
                                const Spacer(),
                                SizedBox(width: double.infinity, height: 60, child: ElevatedButton(onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Pronto podrás enviar ofertas!'))); }, style: ElevatedButton.styleFrom(backgroundColor: TruequiColors.purpura, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 15, shadowColor: TruequiColors.purpura.withOpacity(0.5)), child: const Text('Proponer Trueque', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
                              ],
                            ),
                          ),
                        ),
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
}