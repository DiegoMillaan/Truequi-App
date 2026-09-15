import 'package:flutter/material.dart';
import 'home_page.dart';

class PublicarPage extends StatefulWidget {
  const PublicarPage({super.key});

  @override
  State<PublicarPage> createState() => _PublicarPageState();
}

class _PublicarPageState extends State<PublicarPage> {
  final _tituloController = TextEditingController();
  final _buscanController = TextEditingController();
  final _descripcionController = TextEditingController();
  
  String _categoriaSeleccionada = 'Tecnología';
  final List<String> _categorias = [
    'Tecnología',
    'Hogar y Cocina',
    'Juegos de Mesa',
    'Mascotas',
    'Libros y Educación',
  ];

  @override
  void dispose() {
    _tituloController.dispose();
    _buscanController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  void _publicarTrueque() {
    if (_tituloController.text.trim().isEmpty || _buscanController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa qué ofreces y qué buscas')),
      );
      return;
    }

    // Aquí conectarás con tu backend de AWS API Gateway más adelante con Millán
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('¡Trueque "${_tituloController.text}" publicado con éxito!')),
    );

    // Limpiar campos
    _tituloController.clear();
    _buscanController.clear();
    _descripcionController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ==========================================
        // HEADER: TÍTULO
        // ==========================================
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 15),
            child: Row(
              children: [
                const Icon(Icons.add_photo_alternate_rounded, color: TruequiColors.purpura, size: 32),
                const SizedBox(width: 12),
                const Text(
                  'Crear Trueque',
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
        // FORMULARIO CON GLASSMORPHISM
        // ==========================================
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Simulación de carga de foto
                  Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: TruequiColors.purpura.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: TruequiColors.purpura.withValues(alpha: 0.3),
                        style: BorderStyle.solid,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_rounded, size: 40, color: TruequiColors.purpura.withValues(alpha: 0.7)),
                          const SizedBox(height: 8),
                          Text(
                            'Añadir foto del artículo',
                            style: TextStyle(
                              color: TruequiColors.purpura.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Campo: Título (Qué ofreces)
                  const Text('¿Qué ofreces?', style: TextStyle(fontWeight: FontWeight.bold, color: TruequiColors.textoOscuro)),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _tituloController,
                    hintText: 'Ej. MacBook Air M1 / Arrocera Chefman',
                    icon: Icons.inventory_2_rounded,
                  ),
                  const SizedBox(height: 16),

                  // Campo: Qué buscas a cambio
                  const Text('¿Qué buscas a cambio?', style: TextStyle(fontWeight: FontWeight.bold, color: TruequiColors.textoOscuro)),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _buscanController,
                    hintText: 'Ej. iPad Pro / Parrilla eléctrica',
                    icon: Icons.swap_horiz_rounded,
                  ),
                  const SizedBox(height: 16),

                  // Selector de Categoría
                  const Text('Categoría', style: TextStyle(fontWeight: FontWeight.bold, color: TruequiColors.textoOscuro)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _categoriaSeleccionada,
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        style: const TextStyle(color: TruequiColors.textoOscuro, fontSize: 14, fontWeight: FontWeight.w500),
                        items: _categorias.map((cat) {
                          return DropdownMenuItem(value: cat, child: Text(cat));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _categoriaSeleccionada = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Descripción opcional
                  const Text('Descripción adicional', style: TextStyle(fontWeight: FontWeight.bold, color: TruequiColors.textoOscuro)),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _descripcionController,
                    hintText: 'Estado del producto, detalles de entrega...',
                    icon: Icons.notes_rounded,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  // Botón de Publicar
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _publicarTrueque,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TruequiColors.purpura,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.publish_rounded),
                          SizedBox(width: 8),
                          Text('Publicar Trueque', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          prefixIcon: Icon(icon, color: TruequiColors.purpura, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}