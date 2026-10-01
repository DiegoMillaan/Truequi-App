import 'dart:io';
import 'dart:ui';
import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'home_page.dart'; // Para TruequiColors
import '/services/auth_service.dart';

class PublicarPage extends StatefulWidget {
  const PublicarPage({super.key});

  @override
  State<PublicarPage> createState() => _PublicarPageState();
}

class _PublicarPageState extends State<PublicarPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioController = TextEditingController();
  
  File? _imagenSeleccionada;
  final ImagePicker _picker = ImagePicker();

  String _categoriaSeleccionada = 'Electrónica';
  final List<String> _categorias = ['Electrónica', 'Libros', 'Accesorios', 'Hogar y Cocina', 'Mascotas'];

  bool _isPublishing = false;
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 25))..repeat();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _obtenerImagen(ImageSource origen) async {
    try {
      final XFile? imagen = await _picker.pickImage(source: origen, imageQuality: 80);
      if (imagen != null) {
        setState(() => _imagenSeleccionada = File(imagen.path));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al acceder a la cámara/galería')));
    }
  }

  void _mostrarOpcionesDeImagen(BuildContext context) {
    showModalBottomSheet(
      context: context, backgroundColor: const Color(0xFF1E143A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded, color: TruequiColors.amarillo),
                  title: const Text('Tomar Foto', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  onTap: () { Navigator.pop(context); _obtenerImagen(ImageSource.camera); },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded, color: TruequiColors.amarillo),
                  title: const Text('Elegir de Galería', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  onTap: () { Navigator.pop(context); _obtenerImagen(ImageSource.gallery); },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =======================================================
  // LÓGICA DE SUBIDA A AWS S3 Y DYNAMODB
  // =======================================================
  Future<void> _publicarTrueque() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imagenSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, selecciona una foto de tu artículo.'), backgroundColor: Colors.redAccent));
      return;
    }

    setState(() => _isPublishing = true);

    try {
      final miUsuarioId = await AuthService.obtenerMiUsuarioId();
      String textoPrecio = _precioController.text.replaceAll(RegExp(r'[^0-9.]'), '');
      double precioFinal = double.tryParse(textoPrecio) ?? 1.0;

      // 1. Obtener URL firmada de S3
      final extensionArchivo = _imagenSeleccionada!.path.split('.').last.toLowerCase();
      final extensionValida = ['jpg', 'jpeg', 'png', 'webp'].contains(extensionArchivo) ? extensionArchivo : 'jpg';
      
      final resUrl = await http.get(Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/productos/upload-url?ext=$extensionValida'));
      if (resUrl.statusCode != 200) throw Exception('Error al contactar S3');
      
      final urlData = jsonDecode(resUrl.body);
      final uploadUrl = urlData['uploadUrl'];
      final publicUrl = urlData['publicUrl'];

      // 2. Subir imagen a S3
      final bytes = await _imagenSeleccionada!.readAsBytes();
      final resS3 = await http.put(Uri.parse(uploadUrl), body: bytes);
      if (resS3.statusCode != 200) throw Exception('Fallo al subir la imagen');

      // 3. Guardar registro en DynamoDB
      final responseDb = await http.post(
        Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/productos'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'titulo': _tituloController.text.trim(),
          'descripcion': _descripcionController.text.trim(),
          'precio': precioFinal,
          'categoria': _categoriaSeleccionada,
          'vendedorId': miUsuarioId,
          'vendedorNombre': miUsuarioId.split('@')[0], 
          'imagenUrl': publicUrl,
        }),
      );

      if (responseDb.statusCode == 201) {
        _formKey.currentState!.reset();
        _tituloController.clear(); _descripcionController.clear(); _precioController.clear();
        setState(() => _imagenSeleccionada = null);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Trueque publicado con éxito! 🎉'), backgroundColor: Colors.green));
      } else {
        throw Exception('Fallo al guardar en base de datos');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.transparent, // Hereda del stack principal
      body: Stack(
        children: [
          // ORBES DE FONDO ANIMADOS
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(top: size.height * 0.2 + (math.sin(_bgController.value * 2 * math.pi) * 100), left: size.width * -0.1 + (math.cos(_bgController.value * 2 * math.pi) * 80), child: Container(width: size.width * 0.8, height: size.width * 0.8, decoration: BoxDecoration(shape: BoxShape.circle, color: TruequiColors.purpura.withOpacity(0.3)))),
                  Positioned(bottom: size.height * 0.3 + (math.cos(_bgController.value * 2 * math.pi) * 120), right: size.width * -0.2 + (math.sin(_bgController.value * 2 * math.pi) * 90), child: Container(width: size.width * 0.9, height: size.width * 0.9, decoration: BoxDecoration(shape: BoxShape.circle, color: TruequiColors.amarillo.withOpacity(0.2)))),
                ],
              );
            },
          ),
          
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
                  child: Row(
                    children: [
                      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.add_photo_alternate_rounded, color: TruequiColors.amarillo, size: 28)),
                      const SizedBox(width: 15),
                      const Text('Crear Trueque', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                      child: Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(40), border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5)),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ZONA DE FOTO
                              GestureDetector(
                                onTap: () => _mostrarOpcionesDeImagen(context),
                                child: Container(
                                  height: 200, width: double.infinity,
                                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5)),
                                  child: _imagenSeleccionada != null
                                      ? ClipRRect(borderRadius: BorderRadius.circular(22), child: Image.file(_imagenSeleccionada!, fit: BoxFit.cover, width: double.infinity))
                                      : Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.camera_alt_rounded, size: 40, color: Colors.white.withOpacity(0.8)),
                                              const SizedBox(height: 10),
                                              Text('Añadir foto del artículo', style: TextStyle(color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 25),

                              _buildLabel('¿Qué ofreces? (Título)'),
                              _buildTextFormField(controller: _tituloController, hintText: 'Ej. Mochila para Laptop...', icon: Icons.inventory_2_outlined),
                              const SizedBox(height: 20),

                              _buildLabel('Descripción y qué buscas'),
                              _buildTextFormField(controller: _descripcionController, hintText: 'Ej. Busco teclado mecánico...', icon: Icons.notes_rounded, maxLines: 3),
                              const SizedBox(height: 20),

                              _buildLabel('Valor estimado (MXN)'),
                              _buildTextFormField(controller: _precioController, hintText: 'Ej. 500.0', icon: Icons.attach_money_rounded, isNumeric: true),
                              const SizedBox(height: 20),

                              _buildLabel('Categoría'),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.2))),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _categoriaSeleccionada, isExpanded: true, dropdownColor: const Color(0xFF1E143A),
                                    icon: Icon(Icons.keyboard_arrow_down, color: Colors.white.withOpacity(0.5)),
                                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                                    items: _categorias.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                                    onChanged: (val) { if (val != null) setState(() => _categoriaSeleccionada = val); },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 35),

                              // BOTÓN DE PUBLICAR
                              SizedBox(
                                width: double.infinity, height: 55,
                                child: ElevatedButton(
                                  onPressed: _isPublishing ? null : _publicarTrueque,
                                  style: ElevatedButton.styleFrom(backgroundColor: TruequiColors.amarillo, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                                  child: _isPublishing
                                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.publish_rounded), SizedBox(width: 8),
                                            Text('Publicar Trueque', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }

  Widget _buildTextFormField({required TextEditingController controller, required String hintText, required IconData icon, int maxLines = 1, bool isNumeric = false}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.2))),
      child: TextFormField(
        controller: controller, maxLines: maxLines, keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hintText, hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.5), size: 20),
          border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return 'Campo requerido';
          return null;
        },
      ),
    );
  }
}