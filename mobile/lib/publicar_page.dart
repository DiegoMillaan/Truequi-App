import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'home_page.dart';
import '/services/producto_service.dart'; // Importamos tu servicio de AWS
import '/services/auth_service.dart'; // Para obtener el ID del usuario dinámicamente

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
  
  // Variables para la imagen
  File? _imagenSeleccionada;
  final ImagePicker _picker = ImagePicker();

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

  // Método para capturar o seleccionar la imagen
  Future<void> _obtenerImagen(ImageSource origen) async {
    final XFile? imagen = await _picker.pickImage(
      source: origen,
      imageQuality: 80, // Comprimimos para facilitar subida a AWS
    );

    if (imagen != null) {
      setState(() {
        _imagenSeleccionada = File(imagen.path);
      });
    }
  }

  // Bottom Sheet para elegir entre Cámara o Galería
  void _mostrarOpcionesDeImagen(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded, color: TruequiColors.purpura),
                  title: const Text('Tomar Foto', style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    _obtenerImagen(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded, color: TruequiColors.purpura),
                  title: const Text('Elegir de Galería', style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    _obtenerImagen(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Enviar datos hacia AWS
  Future<void> _publicarTrueque() async {
    if (!_formKey.currentState!.validate()) {
      return; 
    }

    if (_imagenSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona una foto de tu artículo.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isPublishing = true);

    String textoPrecio = _precioController.text.replaceAll(RegExp(r'[^0-9.]'), '');
    double precioFinal = double.tryParse(textoPrecio) ?? 1.0;
    
    // Obtenemos tu ID dinámico
    final miUsuarioId = await AuthService.obtenerMiUsuarioId();

    // AQUÍ DEBERÍAS CONECTAR LA LÓGICA DE SUBIR LA IMAGEN A S3
    // Ejemplo: final imageUrlS3 = await servicio.subirImagenAWS(_imagenSeleccionada!);
    final String imagenUrlDummy = 'https://truequi-images-dm2026.s3.amazonaws.com/dummy/default.jpg';

    final productoData = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'titulo': _tituloController.text.trim(),
      'descripcion': _descripcionController.text.trim(),
      'precio': precioFinal,
      'categoria': _categoriaSeleccionada,
      'vendedorId': miUsuarioId.isNotEmpty ? miUsuarioId : '1', // ID Real
      'imagenUrl': imagenUrlDummy, // TODO: Cambiar por la URL real que te devuelva AWS S3
    };

    final servicio = ProductoService();
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
      setState(() {
        _imagenSeleccionada = null; // Limpiamos la imagen
      });
    } else {
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
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    // ==========================================
                    // COMPONENTE DE SELECCIÓN DE IMAGEN
                    // ==========================================
                    GestureDetector(
                      onTap: () => _mostrarOpcionesDeImagen(context),
                      child: Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: TruequiColors.purpura.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: TruequiColors.purpura.withValues(alpha: 0.3),
                            style: BorderStyle.solid,
                            width: 1.5,
                          ),
                        ),
                        child: _imagenSeleccionada != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: Image.file(
                                  _imagenSeleccionada!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              )
                            : Center(
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
                    ),
                    const SizedBox(height: 20),

                    // Campo: Título
                    const Text('¿Qué ofreces?', style: TextStyle(fontWeight: FontWeight.bold, color: TruequiColors.textoOscuro)),
                    const SizedBox(height: 8),
                    _buildTextFormField(
                      controller: _tituloController,
                      hintText: 'Ej. Calculadora Científica Casio',
                      icon: Icons.inventory_2_rounded,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Por favor ingresa un título';
                        if (value.trim().length < 5 || value.trim().length > 80) return 'El título debe tener entre 5 y 80 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Campo: Descripción
                    const Text('Descripción y qué buscas a cambio', style: TextStyle(fontWeight: FontWeight.bold, color: TruequiColors.textoOscuro)),
                    const SizedBox(height: 8),
                    _buildTextFormField(
                      controller: _descripcionController,
                      hintText: 'Ej. Ideal para ingeniería. Busco libro de Cálculo...',
                      icon: Icons.notes_rounded,
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Por favor ingresa una descripción';
                        if (value.trim().length < 10) return 'Describe un poco mejor (mínimo 10 caracteres)';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Campo: Precio
                    const Text('Valor estimado (MXN)', style: TextStyle(fontWeight: FontWeight.bold, color: TruequiColors.textoOscuro)),
                    const SizedBox(height: 8),
                    _buildTextFormField(
                      controller: _precioController,
                      hintText: 'Ej. 150.0',
                      icon: Icons.attach_money_rounded,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Por favor ingresa un valor estimado';
                        final numero = double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), ''));
                        if (numero == null || numero <= 0) return 'El precio debe ser positivo';
                        if (numero > 1000000) return 'El valor no puede superar 1,000,000 MXN';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Categoría
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
                          items: _categorias.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _categoriaSeleccionada = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botón Publicar
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
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

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