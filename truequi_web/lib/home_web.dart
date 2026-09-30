import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'services/google_auth_service.dart';
import 'widgets/google_login_button.dart';
import 'perfil_web.dart';
import 'mensajes_web.dart';
import 'detalle_producto_web.dart'; 

class TruequiColors {
  static const Color purpura = Color(0xFF6B42E0);
  static const Color amarillo = Color(0xFFFFA800);
  static const Color textoOscuro = Color(0xFF101828);
}

class HomeWeb extends StatefulWidget {
  const HomeWeb({super.key});

  @override
  State<HomeWeb> createState() => _HomeWebState();
}

class _HomeWebState extends State<HomeWeb> with TickerProviderStateMixin {
  static const String _loginUrl = 'https://16663yaped.execute-api.us-east-1.amazonaws.com/dev/login';
  static const String _registroUrl = 'https://16663yaped.execute-api.us-east-1.amazonaws.com/dev/registro';
  static const String _productosUrl = 'https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/productos';
  static const String _uploadUrlEndpoint = 'https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/productos/upload-url';

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  late AnimationController _bgController;
  late AnimationController _floatController;

  List<dynamic> _productos = [];
  bool _isLoadingCatalog = true;
  Map<String, dynamic>? _usuarioActual;

  // NUEVO: Variables para Exploración y Búsqueda
  String _busqueda = '';
  String _categoriaSeleccionadaFiltro = 'Todas';
  final List<String> _categorias = ['Todas', 'Electrónica', 'Hogar', 'Ropa', 'Coleccionables', 'Deportes', 'Libros', 'Accesorios'];

  @override
  void initState() {
    super.initState();
    _inicializarGoogle();
    _cargarProductos();
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
    _floatController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
  }

  Future<void> _inicializarGoogle() async {
    try { await _googleSignIn.initialize(); } catch (e) { debugPrint('ERROR GOOGLE: $e'); }
  }

  Future<void> _cargarProductos() async {
    try {
      final response = await http.get(Uri.parse(_productosUrl));
      if (response.statusCode == 200) setState(() { _productos = jsonDecode(response.body)['productos']; _isLoadingCatalog = false; });
    } catch (e) { setState(() => _isLoadingCatalog = false); }
  }

  @override
  void dispose() {
    _bgController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  // ==========================================
  // LÓGICA DE FILTRADO DINÁMICO
  // ==========================================
  List<dynamic> get _productosFiltrados {
    return _productos.where((p) {
      final titulo = p['titulo'].toString().toLowerCase();
      final descripcion = p['descripcion'].toString().toLowerCase();
      final matchBusqueda = titulo.contains(_busqueda.toLowerCase()) || descripcion.contains(_busqueda.toLowerCase());
      final matchCategoria = _categoriaSeleccionadaFiltro == 'Todas' || p['categoria'] == _categoriaSeleccionadaFiltro;
      return matchBusqueda && matchCategoria;
    }).toList();
  }

  List<dynamic> get _productosDestacados {
    // Simulamos destacados tomando los 5 más recientes o de mayor valor
    if (_productos.length <= 5) return _productos;
    return _productos.take(5).toList(); 
  }

  // ==========================================
  // MODALES (Mantiene tu lógica intacta)
  // ==========================================
  void _mostrarLogin() {
    final nombreController = TextEditingController(); 
    final correoController = TextEditingController();
    final passwordController = TextEditingController();
    bool cargando = false;
    bool esRegistro = false; 
    String? error;

    showDialog(
      context: context, barrierColor: Colors.black.withOpacity(0.6), 
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            GoogleAuthService().listenToAuthentication(
              onSuccess: (usuarioData) async {
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                setState(() { _usuarioActual = { 'nombre': usuarioData['correo'].split('@')[0], 'correo': usuarioData['correo'], 'foto': null }; });
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Acceso exitoso'), backgroundColor: Colors.green));
              },
              onError: (mensaje) { setModalState(() { error = mensaje; cargando = false; }); }
            );

            Future<void> procesarFormulario() async {
              final nombre = nombreController.text.trim();
              final correo = correoController.text.trim();
              final password = passwordController.text;

              if (esRegistro && nombre.isEmpty) { setModalState(() => error = 'Ingresa tu nombre.'); return; }
              if (correo.isEmpty || password.isEmpty) { setModalState(() => error = 'Completa todos los campos.'); return; }
              if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(correo)) { setModalState(() => error = 'Correo inválido.'); return; }
              if (password.length < 5) { setModalState(() => error = 'Mínimo 5 caracteres.'); return; }

              setModalState(() { cargando = true; error = null; });
              try {
                final urlActual = esRegistro ? _registroUrl : _loginUrl;
                final response = await http.post(Uri.parse(urlActual), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'nombre': nombre, 'correo': correo, 'password': password, 'rol': 'Usuario'}));

                if (response.statusCode >= 200 && response.statusCode < 300) {
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  setState(() { _usuarioActual = { 'nombre': nombre.isNotEmpty ? nombre : correo.split('@')[0], 'correo': correo }; });
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Acceso exitoso'), backgroundColor: Colors.green));
                  return;
                }
                setModalState(() { error = jsonDecode(response.body)['error'] ?? 'Credenciales incorrectas.'; cargando = false; });
              } catch (e) { setModalState(() { error = 'Error de conexión.'; cargando = false; }); }
            }

            return TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1), duration: const Duration(milliseconds: 700), curve: Curves.easeOutExpo,
              builder: (context, double val, child) {
                return Transform.scale(
                  scale: val,
                  child: Dialog(
                    backgroundColor: Colors.transparent, elevation: 0,
                    child: SizedBox(
                      width: 450, height: esRegistro ? 650 : 550,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedBuilder(animation: _floatController, builder: (context, child) {
                            return Transform.translate(offset: Offset(math.cos(_floatController.value * math.pi) * 40, math.sin(_floatController.value * math.pi) * 40), child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const RadialGradient(colors: [TruequiColors.purpura, Colors.transparent]), boxShadow: [BoxShadow(color: TruequiColors.purpura.withOpacity(0.8), blurRadius: 80, spreadRadius: 20)])));
                          }),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30), 
                              child: Container(
                                width: 420, padding: const EdgeInsets.all(40), decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(40), border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5)),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(esRegistro ? 'Crea tu cuenta' : 'Iniciar sesión', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)), const SizedBox(height: 30),
                                    if (esRegistro) ...[ _ConstruirCampoGlass('Nombre Completo', Icons.person_outline, nombreController, false), const SizedBox(height: 15) ],
                                    _ConstruirCampoGlass('Correo electrónico', Icons.email_outlined, correoController, false), const SizedBox(height: 15),
                                    _ConstruirCampoGlass('Contraseña', Icons.lock_outline, passwordController, true), 
                                    if (error != null) Padding(padding: const EdgeInsets.only(top: 15), child: Text(error!, style: const TextStyle(color: Color(0xFFFF6B6B), fontWeight: FontWeight.bold))),
                                    const SizedBox(height: 30),
                                    SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: cargando ? null : procesarFormulario, style: ElevatedButton.styleFrom(backgroundColor: TruequiColors.purpura, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: cargando ? const CircularProgressIndicator(color: Colors.white) : Text(esRegistro ? 'Registrarme' : 'Ingresar', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
                                    const SizedBox(height: 20),
                                    TextButton(onPressed: () => setModalState(() { esRegistro = !esRegistro; error = null; }), child: Text(esRegistro ? '¿Ya tienes cuenta? Inicia sesión' : '¿No tienes cuenta? Regístrate', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                                    Padding(padding: const EdgeInsets.symmetric(vertical: 15), child: Row(children: [Expanded(child: Divider(color: Colors.white.withOpacity(0.3))), Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text('O', style: TextStyle(color: Colors.white.withOpacity(0.5)))), Expanded(child: Divider(color: Colors.white.withOpacity(0.3)))]),),
                                    Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: const GoogleLoginButton()),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
            );
          },
        );
      },
    );
  }

  Widget _ConstruirCampoGlass(String label, IconData icon, TextEditingController controller, bool isPass, [int lines = 1]) {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.3))),
      child: TextField(controller: controller, obscureText: isPass, maxLines: lines, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: label, labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), prefixIcon: icon != Icons.abc ? Icon(icon, color: Colors.white.withOpacity(0.7)) : null)),
    );
  }

  void _mostrarPublicar() {
    if (_usuarioActual == null) { _mostrarLogin(); return; }
    
    final tituloController = TextEditingController();
    final descripcionController = TextEditingController();
    final precioController = TextEditingController();
    String categoriaSeleccionada = 'Electrónica';
    
    Uint8List? imagenBytes;
    String? imagenExt;
    bool cargando = false;
    String? error;
    final picker = ImagePicker();

    showDialog(
      context: context, barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {

            Future<void> seleccionarImagen() async {
              try {
                setModalState(() => error = null); 
                final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  final bytes = await image.readAsBytes(); 
                  setModalState(() {
                    imagenBytes = bytes;
                    if (image.name.contains('.')) {
                      imagenExt = image.name.split('.').last.toLowerCase();
                    } else if (image.mimeType != null && image.mimeType!.contains('/')) {
                      imagenExt = image.mimeType!.split('/').last.toLowerCase();
                    } else {
                      imagenExt = 'png'; 
                    }
                    error = null;
                  });
                }
              } catch (e) { setModalState(() => error = 'Fallo en navegador: $e'); }
            }

            Future<void> publicarArticulo() async {
              final titulo = tituloController.text.trim();
              final descripcion = descripcionController.text.trim();
              final precio = double.tryParse(precioController.text.trim());

              if (titulo.length < 5 || titulo.length > 80) { setModalState(() => error = 'El título debe tener entre 5 y 80 caracteres.'); return; }
              if (descripcion.length < 15) { setModalState(() => error = 'La descripción es muy corta. Mínimo 15 caracteres.'); return; }
              if (precio == null || precio <= 0 || precio > 100000) { setModalState(() => error = 'El valor debe ser numérico entre \$1 y \$100,000 MXN.'); return; }
              if (imagenBytes == null) { setModalState(() => error = 'Debes subir una fotografía del artículo.'); return; }

              setModalState(() { cargando = true; error = null; });

              try {
                final resUrl = await http.get(Uri.parse('$_uploadUrlEndpoint?ext=$imagenExt'));
                if (resUrl.statusCode != 200) throw Exception('Error AWS S3');
                
                final urlData = jsonDecode(resUrl.body);
                final resS3 = await http.put(Uri.parse(urlData['uploadUrl']), body: imagenBytes);
                if (resS3.statusCode != 200) throw Exception('Fallo subida a S3');

                final resDB = await http.post(
                  Uri.parse(_productosUrl), headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({'titulo': titulo, 'descripcion': descripcion, 'precio': precio, 'categoria': categoriaSeleccionada, 'imagenUrl': urlData['publicUrl'], 'vendedorId': _usuarioActual!['correo'], 'vendedorNombre': _usuarioActual!['nombre']}),
                );

                if (resDB.statusCode == 201) {
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext); 
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Artículo publicado!'), backgroundColor: Colors.green));
                  _cargarProductos(); 
                } else throw Exception('Fallo en DB');
              } catch (e) {
                setModalState(() { error = 'Hubo un error al publicar el artículo.'; cargando = false; });
              }
            }

            return TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1), duration: const Duration(milliseconds: 500), curve: Curves.easeOutExpo,
              builder: (context, double val, child) {
                return Transform.scale(
                  scale: val,
                  child: Dialog(
                    backgroundColor: Colors.transparent, elevation: 0,
                    insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                        child: Container(
                          width: 800, padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(40), border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5)),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Crear Trueque', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                                  IconButton(onPressed: () => Navigator.of(dialogContext).pop(), icon: const Icon(Icons.close, color: Colors.white)),
                                ],
                              ),
                              const SizedBox(height: 30),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: GestureDetector(
                                      onTap: cargando ? null : seleccionarImagen,
                                      child: Container(
                                        height: 330, decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.4), width: 2, style: BorderStyle.solid)),
                                        child: imagenBytes != null
                                            ? ClipRRect(borderRadius: BorderRadius.circular(22), child: Image.memory(imagenBytes!, fit: BoxFit.cover, width: double.infinity, height: double.infinity))
                                            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo_rounded, size: 50, color: Colors.white.withOpacity(0.8)), const SizedBox(height: 12), const Text('Añadir foto del artículo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 30),
                                  Expanded(
                                    flex: 1,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _ConstruirCampoGlass('¿Qué ofreces? (Título)', Icons.inventory_2_outlined, tituloController, false), const SizedBox(height: 15),
                                        _ConstruirCampoGlass('Valor estimado (MXN)', Icons.attach_money, precioController, false), const SizedBox(height: 15),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.3))),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              value: categoriaSeleccionada, isExpanded: true, dropdownColor: const Color(0xFF2A1B54), style: const TextStyle(color: Colors.white, fontSize: 16), icon: Icon(Icons.keyboard_arrow_down, color: Colors.white.withOpacity(0.7)),
                                              items: _categorias.where((c) => c != 'Todas').map((String valor) => DropdownMenuItem<String>(value: valor, child: Text(valor))).toList(),
                                              onChanged: (nuevoValor) { setModalState(() { categoriaSeleccionada = nuevoValor!; }); },
                                            ),
                                          ),
                                        ), const SizedBox(height: 15),
                                        _ConstruirCampoGlass('Descripción y qué buscas a cambio', Icons.abc, descripcionController, false, 3),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 30),
                              if (error != null) ...[Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.redAccent.withOpacity(0.5))), child: Text(error!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))), const SizedBox(height: 15)],
                              SizedBox(width: double.infinity, height: 60, child: ElevatedButton(onPressed: cargando ? null : publicarArticulo, style: ElevatedButton.styleFrom(backgroundColor: TruequiColors.amarillo, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: cargando ? const CircularProgressIndicator(color: Colors.white) : const Text('Publicar Trueque', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }
            );
          },
        );
      },
    );
  }

  // ============================================================
  // CONSTRUCCIÓN DE LA PANTALLA PRINCIPAL
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(top: size.height * 0.05 + (math.sin(_bgController.value * 2 * math.pi) * 100), left: size.width * 0.1 + (math.cos(_bgController.value * 2 * math.pi) * 80), child: Container(width: size.width * 0.4, height: size.width * 0.4, decoration: BoxDecoration(shape: BoxShape.circle, color: TruequiColors.purpura.withOpacity(0.2)))),
                  Positioned(bottom: size.height * 0.1 + (math.cos(_bgController.value * 2 * math.pi) * 120), right: size.width * 0.05 + (math.sin(_bgController.value * 2 * math.pi) * 90), child: Container(width: size.width * 0.5, height: size.width * 0.5, decoration: BoxDecoration(shape: BoxShape.circle, color: TruequiColors.amarillo.withOpacity(0.15)))),
                ],
              );
            },
          ),
          BackdropFilter(filter: ImageFilter.blur(sigmaX: 80.0, sigmaY: 80.0), child: Container(color: Colors.white.withOpacity(0.1))),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. NAVBAR
              SliverAppBar(
                pinned: true, expandedHeight: 90, collapsedHeight: 90, backgroundColor: Colors.white.withOpacity(0.5),
                flexibleSpace: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.5), width: 1.5))),
                      child: Row(
                        children: [
                          const Icon(Icons.sync_rounded, color: TruequiColors.purpura, size: 40),
                          const SizedBox(width: 15),
                          const Text('truequi', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: TruequiColors.purpura, letterSpacing: -1)),
                          const Spacer(),
                          
                          if (_usuarioActual == null) ...[
                            TextButton.icon(onPressed: _mostrarLogin, icon: const Icon(Icons.person_outline, color: TruequiColors.textoOscuro), label: const Text('Ingresar', style: TextStyle(color: TruequiColors.textoOscuro, fontWeight: FontWeight.bold))),
                            const SizedBox(width: 20),
                            ElevatedButton(onPressed: _mostrarLogin, style: ElevatedButton.styleFrom(backgroundColor: TruequiColors.purpura, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 10, shadowColor: TruequiColors.purpura.withOpacity(0.4)), child: const Text('Iniciar sesión', style: TextStyle(fontWeight: FontWeight.bold))),
                          ] else ...[
                            TextButton.icon(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MensajesWeb(usuarioActual: _usuarioActual!))), 
                              icon: const Icon(Icons.chat_bubble_outline, color: TruequiColors.textoOscuro), 
                              label: const Text('Mensajes', style: TextStyle(color: TruequiColors.textoOscuro, fontWeight: FontWeight.bold))
                            ),
                            const SizedBox(width: 20),
                            OutlinedButton.icon(onPressed: _mostrarPublicar, icon: const Icon(Icons.add), label: const Text('Subir artículo'), style: OutlinedButton.styleFrom(foregroundColor: TruequiColors.purpura, side: BorderSide(color: TruequiColors.purpura.withOpacity(0.5), width: 2), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
                            const SizedBox(width: 20),
                            GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PerfilWeb(usuario: _usuarioActual!))),
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), shape: BoxShape.circle, border: Border.all(color: TruequiColors.purpura.withOpacity(0.5), width: 2), boxShadow: [BoxShadow(color: TruequiColors.purpura.withOpacity(0.2), blurRadius: 10)]),
                                child: CircleAvatar(
                                  backgroundColor: TruequiColors.purpura.withOpacity(0.2),
                                  backgroundImage: _usuarioActual!['foto'] != null ? NetworkImage(_usuarioActual!['foto']) : null,
                                  child: _usuarioActual!['foto'] == null ? Text(_usuarioActual!['nombre'][0].toUpperCase(), style: const TextStyle(color: TruequiColors.purpura, fontWeight: FontWeight.bold)) : null,
                                ),
                              ),
                            )
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 2. HERO BANNER + BUSCADOR INTEGRADO
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(50.0),
                  child: AnimatedBuilder(
                    animation: _floatController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, math.sin(_floatController.value * math.pi) * 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(40),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                            child: Container(
                              width: double.infinity, padding: const EdgeInsets.all(60),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(40), border: Border.all(color: Colors.white.withOpacity(0.6), width: 2), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 40, spreadRadius: 10)]),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), decoration: BoxDecoration(color: TruequiColors.amarillo.withOpacity(0.2), borderRadius: BorderRadius.circular(20)), child: const Text('El futuro del intercambio', style: TextStyle(color: Color(0xFFD48B00), fontWeight: FontWeight.bold))),
                                  const SizedBox(height: 25),
                                  const Text('Cambia lo que tienes.\nEncuentra lo que buscas.', style: TextStyle(fontSize: 54, fontWeight: FontWeight.w900, color: TruequiColors.textoOscuro, height: 1.1, letterSpacing: -2)),
                                  const SizedBox(height: 40),
                                  
                                  // BARRA DE BÚSQUEDA DE CRISTAL
                                  Container(
                                    width: 600,
                                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.4), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white.withOpacity(0.8), width: 2), boxShadow: [BoxShadow(color: TruequiColors.purpura.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))]),
                                    child: TextField(
                                      onChanged: (val) => setState(() => _busqueda = val),
                                      style: const TextStyle(fontSize: 18, color: TruequiColors.textoOscuro, fontWeight: FontWeight.w600),
                                      decoration: InputDecoration(
                                        hintText: 'Explora artículos, tecnología, libros...', hintStyle: TextStyle(color: TruequiColors.textoOscuro.withOpacity(0.5)),
                                        prefixIcon: const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Icon(Icons.search_rounded, color: TruequiColors.purpura, size: 28)),
                                        border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 20),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                  ),
                ),
              ),

              // 3. VITRINA DE DESTACADOS (El "Estante de Vidrio")
              if (!_isLoadingCatalog && _busqueda.isEmpty && _categoriaSeleccionadaFiltro == 'Todas') ...[
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                    child: Text('Novedades', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: TruequiColors.textoOscuro, letterSpacing: -1)),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 420,
                    child: Stack(
                      children: [
                        // ESTANTE BRILLANTE (Luz de neón proyectada en cristal)
                        Positioned(
                          bottom: 30, left: 50, right: 50,
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(100),
                              boxShadow: [BoxShadow(color: TruequiColors.purpura.withOpacity(0.3), blurRadius: 20, spreadRadius: 5, offset: const Offset(0, 5))],
                            ),
                          ),
                        ),
                        // OBJETOS EN LA VITRINA
                        ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 50),
                          scrollDirection: Axis.horizontal,
                          itemCount: _productosDestacados.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 30, bottom: 40),
                              child: SizedBox(
                                width: 320,
                                child: GestureDetector(
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetalleProductoWeb(producto: _productosDestacados[index], usuarioActual: _usuarioActual))),
                                  child: _TarjetaProductoWeb(producto: _productosDestacados[index], destacada: true),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // 4. PÍLDORAS DE CATEGORÍAS (Filtros Glass)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  child: Row(
                    children: [
                      const Text('Explorar Catálogo', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: TruequiColors.textoOscuro, letterSpacing: -1)),
                      const Spacer(),
                      Wrap(
                        spacing: 10,
                        children: _categorias.map((cat) {
                          final bool isSelected = _categoriaSeleccionadaFiltro == cat;
                          return ChoiceChip(
                            label: Text(cat, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : TruequiColors.textoOscuro)),
                            selected: isSelected,
                            selectedColor: TruequiColors.purpura,
                            backgroundColor: Colors.white.withOpacity(0.4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? TruequiColors.purpura : Colors.white.withOpacity(0.8), width: 1.5)),
                            onSelected: (selected) => setState(() => _categoriaSeleccionadaFiltro = cat),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              // 5. GRID DE PRODUCTOS FILTRADOS
              _isLoadingCatalog
                ? const SliverToBoxAdapter(child: SizedBox(height: 300, child: Center(child: CircularProgressIndicator(color: TruequiColors.purpura))))
                : _productosFiltrados.isEmpty
                    ? SliverToBoxAdapter(child: SizedBox(height: 300, child: Center(child: Text('No hay productos que coincidan con tu búsqueda 🔍', style: TextStyle(fontSize: 20, color: TruequiColors.textoOscuro.withOpacity(0.5))))))
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                        sliver: SliverGrid(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return GestureDetector(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetalleProductoWeb(producto: _productosFiltrados[index], usuarioActual: _usuarioActual))),
                                child: _TarjetaProductoWeb(producto: _productosFiltrados[index], destacada: false),
                              );
                            },
                            childCount: _productosFiltrados.length
                          ),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 320, mainAxisExtent: 380, crossAxisSpacing: 30, mainAxisSpacing: 30),
                        ),
                      ),
                      
              const SliverToBoxAdapter(child: SizedBox(height: 100)), // Espaciador final
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================
// TARJETA DE PRODUCTO LIQUID GLASS
// ==========================================
class _TarjetaProductoWeb extends StatefulWidget {
  final Map<String, dynamic> producto;
  final bool destacada;
  const _TarjetaProductoWeb({required this.producto, this.destacada = false});
  @override
  State<_TarjetaProductoWeb> createState() => _TarjetaProductoWebState();
}
class _TarjetaProductoWebState extends State<_TarjetaProductoWeb> {
  bool hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => hover = true), onExit: (_) => setState(() => hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutExpo,
        transform: Matrix4.translationValues(0, hover ? -15 : 0, 0)..scale(hover ? 1.03 : 1.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: widget.destacada ? 25 : 15, sigmaY: widget.destacada ? 25 : 15),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(hover ? 0.7 : (widget.destacada ? 0.5 : 0.4)), 
                borderRadius: BorderRadius.circular(30), 
                border: Border.all(color: Colors.white.withOpacity(0.9), width: widget.destacada ? 2 : 1.5), 
                boxShadow: [BoxShadow(color: TruequiColors.purpura.withOpacity(hover ? 0.2 : (widget.destacada ? 0.1 : 0.05)), blurRadius: hover ? 40 : 20, offset: Offset(0, hover ? 20 : 10))]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: Stack(
                    children: [
                      Container(decoration: BoxDecoration(borderRadius: const BorderRadius.vertical(top: Radius.circular(30)), image: DecorationImage(image: NetworkImage(widget.producto['imagenUrl'] ?? 'https://via.placeholder.com/200'), fit: BoxFit.cover))),
                      if (widget.destacada) Positioned(top: 15, left: 15, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: TruequiColors.amarillo, borderRadius: BorderRadius.circular(20)), child: const Row(children: [Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 16), SizedBox(width: 5), Text('HOT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))]))),
                    ],
                  )),
                  Expanded(flex: 4, child: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: TruequiColors.purpura.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Text(widget.producto['categoria'] ?? 'General', style: const TextStyle(color: TruequiColors.purpura, fontSize: 12, fontWeight: FontWeight.bold))), Text(widget.producto['titulo'] ?? 'Sin título', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: TruequiColors.textoOscuro), maxLines: 2, overflow: TextOverflow.ellipsis), Row(children: [const Icon(Icons.attach_money_rounded, size: 20, color: TruequiColors.amarillo), const SizedBox(width: 5), Text(widget.producto['precio']?.toString() ?? '0.00', style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w900))])]))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}