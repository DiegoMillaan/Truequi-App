import 'package:flutter/material.dart';
import 'home_page.dart';

class DetalleProductoPage extends StatelessWidget {
  final Map<String, dynamic> producto;

  const DetalleProductoPage({super.key, required this.producto});

  @override
  Widget build(BuildContext context) {
    // Extraemos los datos de AWS
    final titulo = producto['titulo'] ?? 'Sin título';
    final descripcion = producto['descripcion'] ?? 'Sin descripción';
    final precio = producto['precio']?.toString() ?? '0.0';
    final categoria = producto['categoria'] ?? 'General';
    final ubicacion = producto['ubicacion'] ?? 'Querétaro';
    final imagenUrl = producto['imagenUrl'];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: TruequiColors.purpura),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del producto
            Container(
              height: 350,
              width: double.infinity,
              decoration: BoxDecoration(
                color: TruequiColors.purpura.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: SafeArea(
                child: Center(
                  // Si hay URL real intenta cargarla, si no, muestra el icono
                  child: imagenUrl != null && imagenUrl.startsWith('http')
                      ? Image.network(imagenUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.inventory_2_rounded, size: 100, color: TruequiColors.purpura))
                      : const Icon(Icons.inventory_2_rounded, size: 100, color: TruequiColors.purpura),
                ),
              ),
            ),
            
            // Detalles del producto
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categoría y Ubicación
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: TruequiColors.purpura, borderRadius: BorderRadius.circular(20)),
                        child: Text(categoria, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: Colors.grey, size: 16),
                          const SizedBox(width: 4),
                          Text(ubicacion, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Título
                  Text(titulo, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: TruequiColors.textoOscuro, height: 1.1)),
                  const SizedBox(height: 8),
                  
                  // Precio Estimado
                  Text('Valor est: \$ $precio MXN', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: TruequiColors.amarillo)),
                  const SizedBox(height: 24),
                  
                  // Descripción
                  const Text('Descripción', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: TruequiColors.textoOscuro)),
                  const SizedBox(height: 8),
                  Text(descripcion, style: TextStyle(fontSize: 15, color: Colors.grey.shade700, height: 1.5)),
                  const SizedBox(height: 40),
                  
                  // Botón de Acción
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Pronto podrás enviar ofertas!')));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TruequiColors.purpura,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                      child: const Text('Proponer Trueque', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}