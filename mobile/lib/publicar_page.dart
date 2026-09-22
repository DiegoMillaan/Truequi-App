import 'package:flutter/material.dart';
import 'home_page.dart';
import '/services/producto_service.dart'; // Importamos tu servicio de AWS

class PublicarPage extends StatefulWidget {
  const PublicarPage({super.key});

  @override
  State<PublicarPage> createState() => _PublicarPageState();
}

class _PublicarPageState extends State<PublicarPage> {
  // Llave global para controlar y validar el formulario
  final _formKey = GlobalKey<FormState>();

  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioController = TextEditingController();
  
  // Categorías sincronizadas con el backend
  String _categoriaSeleccionada = 'Electrónica';
  final List<String> _categorias = [
    'Electrónica',
    'Libros',
    'Accesorios',
    'Hogar y Cocina',
    'Mascotas',
  ];

  bool _isPublishing = false;

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  // Enviar datos usando ProductoService hacia AWS con validación profesional
  Future<void> _publicarTrueque() async {
    if (!_formKey.currentState!.validate()) {
      return; 
    }

    setState(() => _isPublishing = true);

    String textoPrecio = _precioController.text.replaceAll(RegExp(r'[^0-9.]'), '');
    double precioFinal = double.tryParse(textoPrecio) ?? 1.0;

    final productoData = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'titulo': _tituloController.text.trim(),
      'descripcion': _descripcionController.text.trim(),
      'precio': precioFinal,
      'categoria': _categoriaSeleccionada,
      'vendedorId': '1',
      'imagenUrl': 'https://truequi-images-dm2026.s3.amazonaws.com/dummy/default.jpg',
    };

    final servicio = ProductoService();
    // Ahora recibimos un mapa con 'exito' y 'mensaje'
    final resultado = await servicio.crearProducto(productoData);

    if (!mounted) return;
    setState(() => _isPublishing = false);

    if (resultado['exito'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('¡Trueque "${_tituloController.text}" publicado con éxito!'), backgroundColor: Colors.green),
      );
      
      _formKey.currentState!.reset();
      _tituloController.clear();
      _descripcionController.clear();
      _precioController.clear();
    } else {
      // Mostramos el mensaje exacto que nos devolvió el servidor
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resultado['mensaje']), backgroundColor: Colors.redAccent),
      );
    }
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
        // FORMULARIO CON GLASSMORPHISM Y FORM
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
              child: Form(
                key: _formKey, // Enlazamos la llave global del formulario
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Simulación de carga de foto
                    Container(
                      height: 120,
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
                            Icon(Icons.camera_alt_rounded, size: 36, color: TruequiColors.purpura.withValues(alpha: 0.7)),
                            const SizedBox(height: 6),
                            Text(
                              'Añadir foto del artículo',
                              style: TextStyle(
                                color: TruequiColors.purpura.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Campo: Título con validador profesional
                    const Text('¿Qué ofreces?', style: TextStyle(fontWeight: FontWeight.bold, color: TruequiColors.textoOscuro)),
                    const SizedBox(height: 8),
                    _buildTextFormField(
                      controller: _tituloController,
                      hintText: 'Ej. Calculadora Científica Casio',
                      icon: Icons.inventory_2_rounded,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingresa un título';
                        }
                        // Sincronizado con la regla de AWS (5 a 80 caracteres)
                        if (value.trim().length < 5 || value.trim().length > 80) {
                          return 'El título debe tener entre 5 y 80 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Campo: Descripción / Qué buscas con validador
                    const Text('Descripción y qué buscas a cambio', style: TextStyle(fontWeight: FontWeight.bold, color: TruequiColors.textoOscuro)),
                    const SizedBox(height: 8),
                    _buildTextFormField(
                      controller: _descripcionController,
                      hintText: 'Ej. Ideal para ingeniería. Busco libro de Cálculo...',
                      icon: Icons.notes_rounded,
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingresa una descripción';
                        }
                        if (value.trim().length < 10) {
                          return 'Describe un poco mejor (mínimo 10 caracteres)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Campo: Valor / Precio estimado con validación estricta de números y límites
                    const Text('Valor estimado (MXN)', style: TextStyle(fontWeight: FontWeight.bold, color: TruequiColors.textoOscuro)),
                    const SizedBox(height: 8),
                    _buildTextFormField(
                      controller: _precioController,
                      hintText: 'Ej. 150.0',
                      icon: Icons.attach_money_rounded,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingresa un valor estimado';
                        }
                        final textoLimpio = value.replaceAll(RegExp(r'[^0-9.]'), '');
                        final numero = double.tryParse(textoLimpio);
                        
                        if (numero == null || numero <= 0) {
                          return 'El precio debe ser un número positivo mayor a 0';
                        }
                        if (numero > 1000000) {
                          return 'El valor no puede superar 1,000,000 MXN'; // Bloquea precios absurdos
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Selector de Categoría (Sincronizado con DynamoDB)
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
                    const SizedBox(height: 24),

                    // Botón de Publicar
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isPublishing ? null : _publicarTrueque,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TruequiColors.purpura,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: _isPublishing
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Row(
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
        ),

        // Espacio para la barra flotante inferior
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  // Método actualizado a TextFormField para soportar validadores profesionales
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          prefixIcon: Icon(icon, color: TruequiColors.purpura, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          errorStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 11),
        ),
      ),
    );
  }
}