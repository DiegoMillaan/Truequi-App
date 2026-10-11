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

  String _busqueda = '';
  String _categoriaSeleccionadaFiltro = 'Todas';
  
  final List<String> _categorias = [
    'Todas', 'Herramientas', 'Electrónica', 'Salud y Equipo', 
    'Vehículos', 'Hogar y Muebles', 'Instrumentos', 'Arte y Papelería', 
    'Libros', 'Deportes'
  ];

  @override
  void initState() {
    super.initState();
    _inicializarGoogle(); 
    _cargarProductos();
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 25))..repeat();
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

  // ==========================================
  // FUNCIÓN PARA SINCRONIZAR LA FOTO DE PERFIL
  // ==========================================
  Future<void> _recargarUsuarioActual() async {
    if (_usuarioActual == null) return;
    try {
      final url = Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/usuario/perfil/${_usuarioActual!['correo']}');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) setState(() { _usuarioActual = data['usuario']; });
      }
    } catch (e) {
      debugPrint('Error recargando usuario: $e');
    }
  }

  @override
  void dispose() {
    _bgController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  List<dynamic> get _productosFiltrados {
    return _productos.where((p) {
      final titulo = p['titulo'].toString().toLowerCase();
      final descripcion = p['descripcion'].toString().toLowerCase();
      final matchBusqueda = titulo.contains(_busqueda.toLowerCase()) || descripcion.contains(_busqueda.toLowerCase());
      final matchCategoria = _categoriaSeleccionadaFiltro == 'Todas' || p['categoria'] == _categoriaSeleccionadaFiltro;
      return matchBusqueda && matchCategoria;
    }).toList();
  }

  void _mostrarAlertaLiquid(BuildContext context, String mensaje, {String tipo = 'exito'}) {
    Color colorBase = tipo == 'exito' ? TruequiColors.purpura : (tipo == 'error' ? Colors.redAccent : TruequiColors.amarillo);
    IconData icono = tipo == 'exito' ? Icons.check_circle_rounded : (tipo == 'error' ? Icons.error_rounded : Icons.info_rounded);
    final double margenLateral = math.max(20, (MediaQuery.of(context).size.width / 2) - 250); 

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0, behavior: SnackBarBehavior.floating, backgroundColor: Colors.transparent,
        margin: EdgeInsets.only(bottom: 40, left: margenLateral, right: margenLateral),
        duration: const Duration(seconds: 5), 
        content: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: BoxDecoration(color: const Color(0xFF1E143A).withOpacity(0.85), borderRadius: BorderRadius.circular(24), border: Border.all(color: colorBase.withOpacity(0.6), width: 2), boxShadow: [BoxShadow(color: colorBase.withOpacity(0.25), blurRadius: 25, offset: const Offset(0, 10))]),
              child: Row(
                children: [
                  Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: colorBase.withOpacity(0.2), shape: BoxShape.circle), child: Icon(icono, color: colorBase, size: 28)),
                  const SizedBox(width: 18),
                  Expanded(child: Text(mensaje, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

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
                _recargarUsuarioActual(); // Trae la foto real de la base de datos
                if (mounted) _mostrarAlertaLiquid(context, '¡Acceso exitoso con Google!', tipo: 'exito');
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
                  _recargarUsuarioActual(); // Trae la foto real de la base de datos
                  if (mounted) _mostrarAlertaLiquid(context, '¡Acceso exitoso! Bienvenido de vuelta.', tipo: 'exito');
                  return;
                }
                setModalState(() { error = jsonDecode(response.body)['error'] ?? 'Credenciales incorrectas.'; cargando = false; });
              } catch (e) { setModalState(() { error = 'Error de conexión.'; cargando = false; }); }
            }

            return Dialog(
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
                              
                              Container(
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), 
                                child: const GoogleLoginButton()
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
    String categoriaSeleccionada = 'Herramientas';
    
    Uint8List? imagenBytes;
    String? imagenExt;
    bool cargando = false;

    showDialog(
      context: context, barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {

            Future<void> seleccionarImagen() async {
              final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
              if (image != null) {
                final bytes = await image.readAsBytes(); 
                setModalState(() {
                  imagenBytes = bytes;
                  imagenExt = image.name.contains('.') ? image.name.split('.').last.toLowerCase() : 'png';
                });
              }
            }

            Future<void> publicarArticulo() async {
              if (tituloController.text.length < 5 || descripcionController.text.length < 15 || imagenBytes == null) {
                _mostrarAlertaLiquid(context, 'Por favor completa todos los campos y sube una foto.', tipo: 'error');
                return;
              }

              setModalState(() => cargando = true);

              try {
                final resUrl = await http.get(Uri.parse('$_uploadUrlEndpoint?ext=$imagenExt'));
                final urlData = jsonDecode(resUrl.body);
                await http.put(Uri.parse(urlData['uploadUrl']), body: imagenBytes);

                final resDB = await http.post(
                  Uri.parse(_productosUrl), headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({'titulo': tituloController.text.trim(), 'descripcion': descripcionController.text.trim(), 'precio': precioController.text.trim(), 'categoria': categoriaSeleccionada, 'imagenUrl': urlData['publicUrl'], 'vendedorId': _usuarioActual!['correo'], 'vendedorNombre': _usuarioActual!['nombre']}),
                );

                if (resDB.statusCode == 201) {
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext); 
                  _mostrarAlertaLiquid(context, '¡Artículo publicado en el catálogo universal! 🚀', tipo: 'exito');
                  _cargarProductos(); 
                }
              } finally {
                setModalState(() => cargando = false);
              }
            }

            return Dialog(
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
                            const Text('Publicar en Truequi', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
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
                                  height: 330, decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.4), width: 2)),
                                  child: imagenBytes != null
                                      ? ClipRRect(borderRadius: BorderRadius.circular(22), child: Image.memory(imagenBytes!, fit: BoxFit.cover, width: double.infinity, height: double.infinity))
                                      : Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo_rounded, size: 50, color: Colors.white.withOpacity(0.8)), const SizedBox(height: 12), const Text('Añadir foto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
                                ),
                              ),
                            ),
                            const SizedBox(width: 30),
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _ConstruirCampoGlass('¿Qué ofreces? (Ej. Rotomartillo, Laptop)', Icons.inventory_2_outlined, tituloController, false), const SizedBox(height: 15),
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
                        SizedBox(width: double.infinity, height: 60, child: ElevatedButton(onPressed: cargando ? null : publicarArticulo, style: ElevatedButton.styleFrom(backgroundColor: TruequiColors.amarillo, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: cargando ? const CircularProgressIndicator(color: Colors.white) : const Text('Publicar Trueque', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _construirBentoGrid(List<dynamic> itemsFiltrados) {
    List<Widget> filas = [];
    for (int i = 0; i < itemsFiltrados.length; i++) {
      if (i % 3 == 0) {
        filas.add(Padding(padding: const EdgeInsets.only(bottom: 30), child: SizedBox(width: double.infinity, height: 380, child: GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetalleProductoWeb(producto: itemsFiltrados[i], usuarioActual: _usuarioActual))), child: _TarjetaProductoWeb(producto: itemsFiltrados[i], tipoBento: 'Hero')))));
      } else {
        if (i + 1 < itemsFiltrados.length) {
          filas.add(Padding(padding: const EdgeInsets.only(bottom: 30), child: Row(children: [Expanded(child: SizedBox(height: 380, child: GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetalleProductoWeb(producto: itemsFiltrados[i], usuarioActual: _usuarioActual))), child: _TarjetaProductoWeb(producto: itemsFiltrados[i], tipoBento: 'Regular')))), const SizedBox(width: 30), Expanded(child: SizedBox(height: 380, child: GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetalleProductoWeb(producto: itemsFiltrados[i+1], usuarioActual: _usuarioActual))), child: _TarjetaProductoWeb(producto: itemsFiltrados[i+1], tipoBento: 'Regular'))))])));
          i++; 
        } else {
          filas.add(Padding(padding: const EdgeInsets.only(bottom: 30), child: SizedBox(width: double.infinity, height: 380, child: GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetalleProductoWeb(producto: itemsFiltrados[i], usuarioActual: _usuarioActual))), child: _TarjetaProductoWeb(producto: itemsFiltrados[i], tipoBento: 'Hero')))));
        }
      }
    }
    return filas;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final anchoContenido = math.min(size.width * 0.85, 1400.0);
    
    // CACHÉ KILLER PARA EL AVATAR DEL HEADER
    String? fotoUrlLimpia;
    if (_usuarioActual != null) {
      final fotoOriginal = _usuarioActual!['fotoUrl'] ?? _usuarioActual!['foto'];
      if (fotoOriginal != null && fotoOriginal.toString().isNotEmpty) {
        final fotoStr = fotoOriginal.toString();
        fotoUrlLimpia = fotoStr.contains('?') 
            ? '$fotoStr&v=${DateTime.now().millisecondsSinceEpoch}' 
            : '$fotoStr?v=${DateTime.now().millisecondsSinceEpoch}';
      }
    }

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
          BackdropFilter(filter: ImageFilter.blur(sigmaX: 100.0, sigmaY: 100.0), child: Container(color: Colors.white.withOpacity(0.1))),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. REDISEÑO DEL NAVBAR HEADER CENTRADO
              SliverAppBar(
                pinned: true, expandedHeight: 110, collapsedHeight: 110, backgroundColor: Colors.white.withOpacity(0.65),
                flexibleSpace: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                    child: Container(
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.8), width: 1.5))),
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 50),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center, // ALINEACIÓN VERTICAL PERFECTA
                            children: [
                              const Icon(Icons.sync_rounded, color: TruequiColors.purpura, size: 50), 
                              const SizedBox(width: 15),
                              const Text('truequi', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: TruequiColors.purpura, letterSpacing: -1.5)),
                              
                              const Spacer(),
                              
                              if (_usuarioActual == null) ...[
                                TextButton(
                                  onPressed: _mostrarLogin, 
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: const Text('Crear cuenta', style: TextStyle(color: TruequiColors.textoOscuro, fontWeight: FontWeight.bold, fontSize: 16))
                                ), 
                                const SizedBox(width: 15),
                                OutlinedButton.icon(
                                  onPressed: _mostrarLogin, 
                                  icon: const Icon(Icons.login_rounded, size: 20),
                                  label: const Text('Ingresar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: TruequiColors.purpura, 
                                    backgroundColor: Colors.white.withOpacity(0.5),
                                    side: const BorderSide(color: TruequiColors.purpura, width: 2), 
                                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20), 
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 0
                                  )
                                ),
                              ] else ...[
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MensajesWeb(usuarioActual: _usuarioActual!))), 
                                      icon: const Icon(Icons.forum_rounded, size: 20), 
                                      label: const Text('Negociaciones', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: TruequiColors.textoOscuro, 
                                        backgroundColor: Colors.white.withOpacity(0.5),
                                        side: BorderSide(color: Colors.grey.shade300, width: 2), 
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20), 
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                                      )
                                    ),
                                    Positioned(
                                      top: -5, right: -5,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.5), blurRadius: 10)]),
                                        child: const Text('!', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                    )
                                  ],
                                ), 
                                const SizedBox(width: 20),
                                ElevatedButton.icon(
                                  onPressed: _mostrarPublicar, 
                                  icon: const Icon(Icons.add_rounded, size: 22), 
                                  label: const Text('Publicar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), 
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: TruequiColors.purpura,
                                    foregroundColor: Colors.white, 
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20), 
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                                  )
                                ), 
                                const SizedBox(width: 25),
                                
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () async {
                                      await Navigator.push(context, MaterialPageRoute(builder: (_) => PerfilWeb(usuario: _usuarioActual!)));
                                      // Al cerrar el perfil, descargamos la foto nueva si se editó
                                      _recargarUsuarioActual();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4), 
                                      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: TruequiColors.purpura.withOpacity(0.3), width: 2), boxShadow: [BoxShadow(color: TruequiColors.purpura.withOpacity(0.1), blurRadius: 15)]), 
                                      child: CircleAvatar(
                                        radius: 22,
                                        backgroundColor: TruequiColors.purpura.withOpacity(0.1), 
                                        backgroundImage: fotoUrlLimpia != null ? NetworkImage(fotoUrlLimpia) : null, 
                                        child: fotoUrlLimpia == null ? Text(_usuarioActual!['nombre'][0].toUpperCase(), style: const TextStyle(color: TruequiColors.purpura, fontWeight: FontWeight.bold, fontSize: 18)) : null
                                      )
                                    )
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 2. HERO TEXTO (TUS FRASES ORIGINALES)
              SliverToBoxAdapter(
                child: Center(
                  child: SizedBox(
                    width: anchoContenido,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 80.0, bottom: 20),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                          child: Container(
                            width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 80),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(40), border: Border.all(color: Colors.white.withOpacity(0.6), width: 2), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 40, spreadRadius: 10)]),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), decoration: BoxDecoration(color: TruequiColors.amarillo.withOpacity(0.2), borderRadius: BorderRadius.circular(20)), child: const Text('Renueva tu ecosistema', style: TextStyle(color: Color(0xFFD48B00), fontWeight: FontWeight.bold))),
                                const SizedBox(height: 25),
                                const Text('Cambia lo que tienes.\nEncuentra lo que buscas.', style: TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: TruequiColors.textoOscuro, height: 1.05, letterSpacing: -2)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 3. BARRA DE BÚSQUEDA HIPNÓTICA (STICKY)
              SliverPersistentHeader(
                pinned: true,
                delegate: _BuscadorDelegate(onChanged: (val) => setState(() => _busqueda = val)),
              ),

              // 4. MENÚ DE CATEGORÍAS
              SliverToBoxAdapter(
                child: Center(
                  child: SizedBox(
                    width: anchoContenido,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Explorar Categorías', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: TruequiColors.textoOscuro, letterSpacing: -1)),
                          const SizedBox(height: 20),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: _categorias.map((cat) {
                                final bool isSelected = _categoriaSeleccionadaFiltro == cat;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 15),
                                  child: ChoiceChip(
                                    label: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), child: Text(cat, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isSelected ? Colors.white : TruequiColors.textoOscuro))),
                                    selected: isSelected, selectedColor: TruequiColors.purpura, backgroundColor: Colors.white.withOpacity(0.6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? TruequiColors.purpura : Colors.white.withOpacity(0.8), width: 1.5)),
                                    onSelected: (selected) => setState(() => _categoriaSeleccionadaFiltro = cat),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 5. GRID DE PRODUCTOS TIPO BENTO
              _isLoadingCatalog
                ? const SliverToBoxAdapter(child: SizedBox(height: 300, child: Center(child: CircularProgressIndicator(color: TruequiColors.purpura))))
                : _productosFiltrados.isEmpty
                    ? SliverToBoxAdapter(child: SizedBox(height: 300, child: Center(child: Text('No hay productos que coincidan con tu búsqueda 🔍', style: TextStyle(fontSize: 24, color: TruequiColors.textoOscuro.withOpacity(0.5))))))
                    : SliverToBoxAdapter(
                        child: Center(
                          child: SizedBox(
                            width: anchoContenido,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Column(
                                children: _construirBentoGrid(_productosFiltrados),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ],
      ),
    );
  }
}

// =========================================================
// DELEGADO MAGICO DE LA BARRA DE BUSQUEDA (Efecto Sticky)
// =========================================================
class _BuscadorDelegate extends SliverPersistentHeaderDelegate {
  final ValueChanged<String> onChanged;
  _BuscadorDelegate({required this.onChanged});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final width = 1000.0 - (progress * 400.0); 

    return Container(
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        width: width,
        height: 65,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5 + (progress * 0.45)), 
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
          boxShadow: [
            BoxShadow(
              color: TruequiColors.purpura.withOpacity(0.1 + (progress * 0.15)), 
              blurRadius: 20 + (progress * 15), 
              offset: const Offset(0, 10)
            )
          ]
        ),
        child: TextField(
          onChanged: onChanged,
          style: const TextStyle(fontSize: 20, color: TruequiColors.textoOscuro, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'Buscar herramientas, estetoscopios, libros...',
            hintStyle: TextStyle(color: TruequiColors.textoOscuro.withOpacity(0.5)),
            prefixIcon: const Padding(padding: EdgeInsets.symmetric(horizontal: 25), child: Icon(Icons.search_rounded, color: TruequiColors.purpura, size: 30)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 20),
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 110.0;
  @override
  double get minExtent => 85.0;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
}

// ==========================================
// TARJETA DE PRODUCTO BENTO GRID
// ==========================================
class _TarjetaProductoWeb extends StatefulWidget {
  final Map<String, dynamic> producto;
  final String tipoBento; 
  const _TarjetaProductoWeb({required this.producto, required this.tipoBento});
  @override
  State<_TarjetaProductoWeb> createState() => _TarjetaProductoWebState();
}

class _TarjetaProductoWebState extends State<_TarjetaProductoWeb> {
  bool hover = false;
  @override
  Widget build(BuildContext context) {
    final isHero = widget.tipoBento == 'Hero';

    return MouseRegion(
      onEnter: (_) => setState(() => hover = true), onExit: (_) => setState(() => hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300), curve: Curves.easeOutExpo,
        transform: Matrix4.translationValues(0, hover ? -15 : 0, 0)..scale(hover ? 1.02 : 1.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(hover ? 0.8 : 0.5), 
                borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white.withOpacity(0.9), width: 2), 
                boxShadow: [BoxShadow(color: TruequiColors.purpura.withOpacity(hover ? 0.15 : 0.05), blurRadius: hover ? 40 : 20, offset: Offset(0, hover ? 20 : 10))]
              ),
              child: isHero ? _buildHeroLayout() : _buildRegularLayout(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroLayout() {
    return Row(
      children: [
        Expanded(flex: 3, child: Container(decoration: BoxDecoration(image: DecorationImage(image: NetworkImage(widget.producto['imagenUrl'] ?? 'https://via.placeholder.com/600'), fit: BoxFit.cover)))),
        Expanded(flex: 4, child: Padding(padding: const EdgeInsets.all(40), child: _buildInfoColumn(size: 'grande'))),
      ],
    );
  }

  Widget _buildRegularLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 5, child: Container(decoration: BoxDecoration(image: DecorationImage(image: NetworkImage(widget.producto['imagenUrl'] ?? 'https://via.placeholder.com/400'), fit: BoxFit.cover)))),
        Expanded(flex: 4, child: Padding(padding: const EdgeInsets.all(24), child: _buildInfoColumn(size: 'normal'))),
      ],
    );
  }

  Widget _buildInfoColumn({required String size}) {
    final bool grande = size == 'grande';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: TruequiColors.purpura.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Text(widget.producto['categoria'] ?? 'General', style: const TextStyle(color: TruequiColors.purpura, fontSize: 14, fontWeight: FontWeight.bold))), 
        SizedBox(height: grande ? 20 : 10),
        Text(widget.producto['titulo'] ?? 'Sin título', style: TextStyle(fontSize: grande ? 32 : 20, fontWeight: FontWeight.w900, color: TruequiColors.textoOscuro, height: 1.1), maxLines: 2, overflow: TextOverflow.ellipsis), 
        SizedBox(height: grande ? 20 : 10),
        if (grande) Text(widget.producto['descripcion'] ?? '', style: TextStyle(fontSize: 16, color: Colors.grey.shade700), maxLines: 2, overflow: TextOverflow.ellipsis),
        if (grande) const SizedBox(height: 20),
        Row(children: [const Icon(Icons.attach_money_rounded, size: 24, color: TruequiColors.amarillo), const SizedBox(width: 5), Text(widget.producto['precio']?.toString() ?? '0.00', style: TextStyle(fontSize: grande ? 24 : 18, color: Colors.black87, fontWeight: FontWeight.w900))])
      ]
    );
  }
}