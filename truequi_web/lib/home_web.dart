import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:web/web.dart' as web;

import 'services/google_auth_service.dart';
import 'services/ubicacion_zmq_service.dart';
import 'widgets/google_login_button.dart';
import 'perfil_web.dart';
import 'mensajes_web.dart';
import 'detalle_producto_web.dart';

class TruequiColors {
  static const Color purpura = Color(0xFF6B42E0);
  static const Color amarillo = Color(0xFFFFA800);
  static const Color textoOscuro = Color(0xFF101828);
}

class ImagenSeleccionadaWeb {
  final Uint8List bytes;
  final String extension;
  ImagenSeleccionadaWeb({required this.bytes, required this.extension});
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
  static const String _perfilUrl = 'https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/usuario/perfil';
  static const String _storageKeySesion = 'truequi_usuario_sesion';

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final ScrollController _scrollController = ScrollController();

  late AnimationController _bgController;
  late AnimationController _floatController;

  List<dynamic> _productos = [];
  bool _isLoadingCatalog = true;
  Map<String, dynamic>? _usuarioActual;
  List<String> _favoritosIds = [];
  bool _hoverLogo = false;

  String _busqueda = '';
  String _categoriaSeleccionadaFiltro = 'Todas';

  final List<String> _categorias = [
    'Todas',
    '❤️ Favoritos',
    'Hogar y Muebles',
    'Cocina y Electrodomésticos',
    'Electrónica y Cómputo',
    'Juguetes y Juegos',
    'Libros y Estudio',
    'Herramientas',
    'Salud y Equipo Médico',
    'Deportes y Fitness',
    'Instrumentos Musicales',
    'Arte y Papelería',
    'Ropa y Accesorios',
    'Vehículos y Movilidad'
  ];

  final List<String> _municipiosZMQ = [
    'Santiago de Querétaro',
    'Corregidora',
    'El Marqués',
    'Huimilpan',
  ];

  static const List<String> _palabrasIlicitas = [
    'droga', 'marihuana', 'weed', 'cocaína', 'cocaina', 'metanfetamina', 'cristal',
    'fentanilo', 'lsd', 'vape', 'vaper', 'wax', 'thc', 'cbd',
    'arma', 'pistola', 'revolver', 'rifle', 'escopeta', 'municiones', 'balas',
    'taser', 'explosivo', 'pirotecnia',
    'clonazepam', 'rivotril', 'alprazolam', 'xanax', 'receta medica',
    'hackeo', 'cuenta robada', 'tarjetas clonadas', 'billetes falsos', 'ine falsa',
    'factura falsa', 'prostitucion', 'escort', 'contenido adulto', 'onlyfans',
    'pirateria', 'animales exoticos'
  ];

  @override
  void initState() {
    super.initState();
    _restaurarSesionGuardada();
    _inicializarGoogle();
    _cargarProductos();
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 25))..repeat();
    _floatController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
  }

  // =========================================================
  // PERSISTENCIA DE SESIÓN EN NAVEGADOR (LOCAL STORAGE)
  // =========================================================
  void _restaurarSesionGuardada() {
    try {
      final raw = web.window.localStorage.getItem(_storageKeySesion);
      if (raw != null && raw.isNotEmpty) {
        final Map<String, dynamic> sesion = Map<String, dynamic>.from(jsonDecode(raw));
        if (sesion['correo'] != null) {
          setState(() {
            _usuarioActual = sesion;
            if (sesion['favoritos'] is List) {
              _favoritosIds = List<String>.from((sesion['favoritos'] as List).map((e) => e.toString()));
            }
          });
          _recargarUsuarioActual();
        }
      }
    } catch (e) {
      debugPrint('Error restaurando sesión: $e');
    }
  }

  void _guardarSesionLocal(Map<String, dynamic> usuario) {
    try {
      web.window.localStorage.setItem(_storageKeySesion, jsonEncode(usuario));
    } catch (e) {
      debugPrint('Error guardando sesión local: $e');
    }
  }

  Future<void> _inicializarGoogle() async {
    try { await _googleSignIn.initialize(); } catch (e) { debugPrint('ERROR GOOGLE: $e'); }
  }

  Future<void> _cargarProductos() async {
    try {
      final response = await http.get(Uri.parse(_productosUrl));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _productos = jsonDecode(response.body)['productos'] ?? [];
            _isLoadingCatalog = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCatalog = false);
    }
  }

  void _irAlInicioYRefrescar() {
    setState(() {
      _busqueda = '';
      _categoriaSeleccionadaFiltro = 'Todas';
    });
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
      );
    }
    _cargarProductos();
  }

  Future<void> _recargarUsuarioActual({String? nombreInicial, String? fotoInicial, String? telefonoInicial}) async {
    if (_usuarioActual == null || _usuarioActual!['correo'] == null) return;

    final String correo = _usuarioActual!['correo'].toString().trim();
    final String nombreRespaldo = (nombreInicial != null && nombreInicial.trim().isNotEmpty)
        ? nombreInicial.trim()
        : (_usuarioActual!['nombre']?.toString().trim().isNotEmpty == true
            ? _usuarioActual!['nombre'].toString().trim()
            : correo.split('@').first);

    try {
      final url = Uri.parse('$_perfilUrl/$correo');
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final Map<String, dynamic> usuarioDB = data['usuario'] != null
            ? Map<String, dynamic>.from(data['usuario'])
            : {};

        final String? nombreEnDB = usuarioDB['nombre']?.toString().trim();
        final String? fotoEnDB = (usuarioDB['fotoUrl'] ?? usuarioDB['foto'])?.toString().trim();
        final String? telefonoEnDB = usuarioDB['telefono']?.toString().trim();

        final String nombreFinal = (nombreEnDB != null && nombreEnDB.isNotEmpty) ? nombreEnDB : nombreRespaldo;
        final String? fotoFinal = (fotoEnDB != null && fotoEnDB.isNotEmpty)
            ? fotoEnDB
            : (fotoInicial ?? _usuarioActual!['fotoUrl'] ?? _usuarioActual!['foto']);
        final String? telefonoFinal = (telefonoEnDB != null && telefonoEnDB.isNotEmpty)
            ? telefonoEnDB
            : (telefonoInicial ?? _usuarioActual!['telefono']);

        final List<String> favs = usuarioDB['favoritos'] != null
            ? List<String>.from(usuarioDB['favoritos'].map((e) => e.toString()))
            : _favoritosIds;

        final Map<String, dynamic> nuevoEstadoUsuario = {
          ..._usuarioActual!,
          ...usuarioDB,
          'correo': correo,
          'nombre': nombreFinal,
          'foto': fotoFinal,
          'fotoUrl': fotoFinal,
          'telefono': telefonoFinal,
          'favoritos': favs,
        };

        if (mounted) {
          setState(() {
            _favoritosIds = favs;
            _usuarioActual = nuevoEstadoUsuario;
          });
        }
        _guardarSesionLocal(nuevoEstadoUsuario);

        if (nombreEnDB == null || nombreEnDB.isEmpty || (telefonoInicial != null && telefonoEnDB == null)) {
          await http.put(
            Uri.parse(_perfilUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'correo': correo,
              'nombre': nombreFinal,
              if (fotoFinal != null) 'fotoUrl': fotoFinal,
              if (telefonoFinal != null) 'telefono': telefonoFinal,
              'favoritos': favs,
            }),
          );
        }
      }
    } catch (e) {
      debugPrint('Error recargando usuario: $e');
    }
  }

  Future<void> _toggleFavorito(String productoId) async {
    if (_usuarioActual == null) {
      _mostrarAlertaLiquid(context, 'Inicia sesión para guardar artículos en tus favoritos ❤️', tipo: 'info');
      _mostrarLogin(iniciarEnRegistro: false);
      return;
    }

    final bool yaEsFavorito = _favoritosIds.contains(productoId);
    setState(() {
      if (yaEsFavorito) {
        _favoritosIds.remove(productoId);
      } else {
        _favoritosIds.add(productoId);
      }
      _usuarioActual!['favoritos'] = _favoritosIds;
    });
    _guardarSesionLocal(_usuarioActual!);

    try {
      await http.put(
        Uri.parse(_perfilUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'correo': _usuarioActual!['correo'],
          'favoritos': _favoritosIds,
        }),
      );
    } catch (e) {
      debugPrint('Error guardando favorito: $e');
    }
  }

  String? _detectarContenidoIlicito(String titulo, String descripcion) {
    final texto = '$titulo $descripcion'.toLowerCase();
    for (final palabra in _palabrasIlicitas) {
      final reg = RegExp(r'\b' + RegExp.escape(palabra) + r'\b', caseSensitive: false);
      if (reg.hasMatch(texto) || texto.contains(palabra)) {
        return palabra;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _bgController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  List<dynamic> get _productosFiltrados {
    return _productos.where((p) {
      final id = (p['id'] ?? '').toString();
      final titulo = (p['titulo'] ?? '').toString().toLowerCase();
      final descripcion = (p['descripcion'] ?? '').toString().toLowerCase();
      final matchBusqueda = titulo.contains(_busqueda.toLowerCase()) || descripcion.contains(_busqueda.toLowerCase());

      if (_categoriaSeleccionadaFiltro == '❤️ Favoritos') {
        return matchBusqueda && _favoritosIds.contains(id);
      }

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

  void _mostrarLogin({bool iniciarEnRegistro = false}) {
    final nombreController = TextEditingController();
    final telefonoController = TextEditingController();
    final correoController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmarPasswordController = TextEditingController();

    bool cargando = false;
    bool esRegistro = iniciarEnRegistro;
    bool ocultarPassword = true;
    bool ocultarConfirmarPassword = true;
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

                final String correoGoogle = (usuarioData['correo'] ?? '').toString().trim();
                final String nombreGoogle = (usuarioData['nombre'] != null && usuarioData['nombre'].toString().trim().isNotEmpty)
                    ? usuarioData['nombre'].toString().trim()
                    : (correoGoogle.isNotEmpty ? correoGoogle.split('@').first : 'Usuario');
                final String? fotoGoogle = (usuarioData['fotoUrl'] ?? usuarioData['foto'])?.toString();

                final Map<String, dynamic> userTemp = {
                  'nombre': nombreGoogle,
                  'correo': correoGoogle,
                  'foto': fotoGoogle,
                  'fotoUrl': fotoGoogle,
                };

                setState(() => _usuarioActual = userTemp);
                _guardarSesionLocal(userTemp);

                await _recargarUsuarioActual(nombreInicial: nombreGoogle, fotoInicial: fotoGoogle);
                if (mounted) _mostrarAlertaLiquid(this.context, '¡Acceso exitoso con Google!', tipo: 'exito');
              },
              onError: (mensaje) {
                if (dialogContext.mounted) {
                  setModalState(() { error = mensaje; cargando = false; });
                }
              }
            );

            Future<void> procesarFormulario() async {
              final nombre = nombreController.text.trim();
              final telefono = telefonoController.text.trim().replaceAll(RegExp(r'\s+|-'), '');
              final correo = correoController.text.trim();
              final password = passwordController.text;
              final confirmarPassword = confirmarPasswordController.text;

              if (esRegistro) {
                if (nombre.length < 3) {
                  setModalState(() => error = 'Ingresa tu nombre completo.');
                  return;
                }
                if (!RegExp(r'^\d{10}$').hasMatch(telefono)) {
                  setModalState(() => error = 'Ingresa un número telefónico válido de 10 dígitos.');
                  return;
                }
              }

              if (correo.isEmpty || password.isEmpty) {
                setModalState(() => error = 'Completa todos los campos.');
                return;
              }
              if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(correo)) {
                setModalState(() => error = 'Ingresa un correo electrónico válido.');
                return;
              }
              if (password.length < 6) {
                setModalState(() => error = 'La contraseña debe tener mínimo 6 caracteres.');
                return;
              }
              if (esRegistro && password != confirmarPassword) {
                setModalState(() => error = 'Las contraseñas no coinciden.');
                return;
              }

              setModalState(() { cargando = true; error = null; });
              try {
                final urlActual = esRegistro ? _registroUrl : _loginUrl;
                final response = await http.post(
                  Uri.parse(urlActual),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'nombre': nombre,
                    'telefono': telefono,
                    'correo': correo,
                    'password': password,
                    'rol': 'Usuario'
                  }),
                );

                if (response.statusCode >= 200 && response.statusCode < 300) {
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);

                  final String nombreSeguro = nombre.isNotEmpty ? nombre : correo.split('@').first;
                  final Map<String, dynamic> userTemp = {
                    'nombre': nombreSeguro,
                    'correo': correo,
                    'telefono': telefono.isNotEmpty ? telefono : null,
                    'foto': null,
                  };

                  setState(() => _usuarioActual = userTemp);
                  _guardarSesionLocal(userTemp);

                  await _recargarUsuarioActual(
                    nombreInicial: nombreSeguro,
                    telefonoInicial: telefono.isNotEmpty ? telefono : null,
                  );

                  if (mounted) {
                    _mostrarAlertaLiquid(
                      this.context,
                      esRegistro ? '¡Cuenta creada exitosamente! Bienvenido.' : '¡Acceso exitoso! Bienvenido de vuelta.',
                      tipo: 'exito',
                    );
                  }
                  return;
                }
                setModalState(() {
                  error = jsonDecode(response.body)['error'] ?? 'Credenciales incorrectas.';
                  cargando = false;
                });
              } catch (e) {
                setModalState(() {
                  error = 'Error de conexión.';
                  cargando = false;
                });
              }
            }

            return Dialog(
              backgroundColor: Colors.transparent, elevation: 0,
              child: SizedBox(
                width: 460, height: esRegistro ? 760 : 560,
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
                          width: 430, padding: const EdgeInsets.all(36),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(40), border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5)),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(esRegistro ? 'Crea tu cuenta' : 'Iniciar sesión', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                                const SizedBox(height: 24),
                                if (esRegistro) ...[
                                  _ConstruirCampoGlass('Nombre Completo', Icons.person_outline, nombreController, false),
                                  const SizedBox(height: 14),
                                  _ConstruirCampoGlass('Teléfono celular (10 dígitos)', Icons.phone_android_rounded, telefonoController, false, 1, TextInputType.phone),
                                  const SizedBox(height: 14),
                                ],
                                _ConstruirCampoGlass('Correo electrónico', Icons.email_outlined, correoController, false),
                                const SizedBox(height: 14),
                                _ConstruirCampoGlass(
                                  'Contraseña',
                                  Icons.lock_outline,
                                  passwordController,
                                  ocultarPassword,
                                  1,
                                  TextInputType.text,
                                  IconButton(
                                    onPressed: () => setModalState(() => ocultarPassword = !ocultarPassword),
                                    icon: Icon(ocultarPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.white70),
                                  ),
                                ),
                                if (esRegistro) ...[
                                  const SizedBox(height: 14),
                                  _ConstruirCampoGlass(
                                    'Confirmar contraseña',
                                    Icons.lock_reset_rounded,
                                    confirmarPasswordController,
                                    ocultarConfirmarPassword,
                                    1,
                                    TextInputType.text,
                                    IconButton(
                                      onPressed: () => setModalState(() => ocultarConfirmarPassword = !ocultarConfirmarPassword),
                                      icon: Icon(ocultarConfirmarPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.white70),
                                    ),
                                  ),
                                ],
                                if (error != null) Padding(padding: const EdgeInsets.only(top: 15), child: Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFFF6B6B), fontWeight: FontWeight.bold))),
                                const SizedBox(height: 24),
                                SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: cargando ? null : procesarFormulario, style: ElevatedButton.styleFrom(backgroundColor: TruequiColors.purpura, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: cargando ? const CircularProgressIndicator(color: Colors.white) : Text(esRegistro ? 'Registrarme' : 'Ingresar', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
                                const SizedBox(height: 16),
                                TextButton(onPressed: () => setModalState(() { esRegistro = !esRegistro; error = null; }), child: Text(esRegistro ? '¿Ya tienes cuenta? Inicia sesión' : '¿No tienes cuenta? Regístrate', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                                Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Row(children: [Expanded(child: Divider(color: Colors.white.withOpacity(0.3))), Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text('O', style: TextStyle(color: Colors.white.withOpacity(0.5)))), Expanded(child: Divider(color: Colors.white.withOpacity(0.3)))])),
                                Container(
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                                  child: const GoogleLoginButton()
                                ),
                              ],
                            ),
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

  Widget _ConstruirCampoGlass(
    String label,
    IconData icon,
    TextEditingController controller,
    bool isPass, [
    int lines = 1,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  ]) {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.3))),
      child: TextField(
        controller: controller,
        obscureText: isPass,
        maxLines: isPass ? 1 : lines,
        keyboardType: keyboardType,
        showCursor: true,
        cursorColor: TruequiColors.amarillo,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          prefixIcon: icon != Icons.abc ? Icon(icon, color: Colors.white.withOpacity(0.7)) : null,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  Future<void> _mostrarPublicar() async {
    if (_usuarioActual == null) { _mostrarLogin(iniciarEnRegistro: false); return; }

    _mostrarAlertaLiquid(context, 'Verificando ubicación en la Zona Metropolitana de Querétaro... 📍', tipo: 'info');
    final ubicacion = await UbicacionZmqService.verificarUbicacionActual();

    if (!mounted) return;
    if (!ubicacion.permitido) {
      _mostrarAlertaLiquid(context, ubicacion.mensaje, tipo: 'error');
      return;
    }

    final tituloController = TextEditingController();
    final descripcionController = TextEditingController();
    final precioController = TextEditingController();
    String categoriaSeleccionada = 'Hogar y Muebles';
    String municipioSeleccionado = _municipiosZMQ.contains(ubicacion.municipioDetectado)
        ? ubicacion.municipioDetectado
        : 'Santiago de Querétaro';

    List<ImagenSeleccionadaWeb> imagenesSeleccionadas = [];
    int indicePreview = 0;
    bool cargando = false;

    showDialog(
      context: context, barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {

            Future<void> seleccionarImagenes() async {
              if (imagenesSeleccionadas.length >= 5) {
                _mostrarAlertaLiquid(this.context, 'Máximo 5 imágenes permitidas por publicación.', tipo: 'info');
                return;
              }

              final List<XFile> pickedList = await ImagePicker().pickMultiImage();
              if (pickedList.isNotEmpty) {
                final cupoDisponible = 5 - imagenesSeleccionadas.length;
                final seleccion = pickedList.take(cupoDisponible);

                for (final img in seleccion) {
                  final bytes = await img.readAsBytes();
                  final ext = img.name.contains('.') ? img.name.split('.').last.toLowerCase() : 'png';
                  imagenesSeleccionadas.add(ImagenSeleccionadaWeb(bytes: bytes, extension: ext));
                }

                setModalState(() {
                  indicePreview = imagenesSeleccionadas.length - 1;
                });

                if (pickedList.length > cupoDisponible && mounted) {
                  _mostrarAlertaLiquid(this.context, 'Solo se agregaron las primeras fotos hasta completar el límite de 5.', tipo: 'info');
                }
              }
            }

            Future<void> publicarArticulo() async {
              final titulo = tituloController.text.trim();
              final descripcion = descripcionController.text.trim();

              if (titulo.length < 5 || descripcion.length < 15 || imagenesSeleccionadas.isEmpty) {
                _mostrarAlertaLiquid(this.context, 'Completa todos los campos y sube al menos 1 foto (máximo 5).', tipo: 'error');
                return;
              }

              final palabraProhibida = _detectarContenidoIlicito(titulo, descripcion);
              if (palabraProhibida != null) {
                _mostrarAlertaLiquid(
                  this.context,
                  'Publicación bloqueada por seguridad: No se permiten artículos ni servicios ilícitos ("$palabraProhibida").',
                  tipo: 'error',
                );
                return;
              }

              setModalState(() => cargando = true);

              try {
                List<String> urlsPublicas = [];
                for (final img in imagenesSeleccionadas) {
                  final resUrl = await http.get(Uri.parse('$_uploadUrlEndpoint?ext=${img.extension}'));
                  final urlData = jsonDecode(resUrl.body);
                  await http.put(Uri.parse(urlData['uploadUrl']), body: img.bytes);
                  urlsPublicas.add(urlData['publicUrl'].toString());
                }

                final resDB = await http.post(
                  Uri.parse(_productosUrl),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'titulo': titulo,
                    'descripcion': descripcion,
                    'precio': precioController.text.trim(),
                    'categoria': categoriaSeleccionada,
                    'municipio': municipioSeleccionado,
                    'latitud': ubicacion.latitud,
                    'longitud': ubicacion.longitud,
                    'imagenUrl': urlsPublicas.first,
                    'imagenesUrls': urlsPublicas,
                    'vendedorId': _usuarioActual!['correo'],
                    'vendedorNombre': _usuarioActual!['nombre'] ?? _usuarioActual!['correo'].toString().split('@').first,
                  }),
                );

                if (resDB.statusCode == 201) {
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  _mostrarAlertaLiquid(this.context, '¡Artículo verificado y publicado en la ZMQ! 🚀', tipo: 'exito');
                  _cargarProductos();
                } else {
                  final msgError = jsonDecode(resDB.body)['error'] ?? 'No se pudo publicar el artículo.';
                  _mostrarAlertaLiquid(this.context, msgError, tipo: 'error');
                }
              } finally {
                if (dialogContext.mounted) setModalState(() => cargando = false);
              }
            }

            return Dialog(
              backgroundColor: Colors.transparent, elevation: 0,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                  child: Container(
                    width: 860, padding: const EdgeInsets.all(36),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(40), border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5)),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Publicar en Truequi', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.verified_user_rounded, color: Colors.greenAccent, size: 16),
                                      const SizedBox(width: 6),
                                      Text('ZMQ Verificada: ${ubicacion.municipioDetectado}', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ],
                              ),
                              IconButton(onPressed: () => Navigator.of(dialogContext).pop(), icon: const Icon(Icons.close, color: Colors.white)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 1,
                                child: Column(
                                  children: [
                                    GestureDetector(
                                      onTap: cargando ? null : seleccionarImagenes,
                                      child: Container(
                                        height: 260,
                                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.4), width: 2)),
                                        child: imagenesSeleccionadas.isNotEmpty
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.circular(22),
                                                child: Image.memory(
                                                  imagenesSeleccionadas[indicePreview].bytes,
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                ),
                                              )
                                            : Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.add_photo_alternate_rounded, size: 54, color: Colors.white.withOpacity(0.85)),
                                                  const SizedBox(height: 12),
                                                  const Text('Añadir fotos (Máx. 5)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                                ],
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        ...List.generate(imagenesSeleccionadas.length, (idx) {
                                          final bool activa = idx == indicePreview;
                                          return Padding(
                                            padding: const EdgeInsets.only(right: 8),
                                            child: GestureDetector(
                                              onTap: () => setModalState(() => indicePreview = idx),
                                              child: Stack(
                                                clipBehavior: Clip.none,
                                                children: [
                                                  Container(
                                                    width: 54, height: 54,
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(color: activa ? TruequiColors.amarillo : Colors.white54, width: activa ? 2.5 : 1),
                                                    ),
                                                    child: ClipRRect(
                                                      borderRadius: BorderRadius.circular(10),
                                                      child: Image.memory(imagenesSeleccionadas[idx].bytes, fit: BoxFit.cover),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    top: -6, right: -6,
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        setModalState(() {
                                                          imagenesSeleccionadas.removeAt(idx);
                                                          if (indicePreview >= imagenesSeleccionadas.length) {
                                                            indicePreview = math.max(0, imagenesSeleccionadas.length - 1);
                                                          }
                                                        });
                                                      },
                                                      child: Container(
                                                        padding: const EdgeInsets.all(2),
                                                        decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                                                        child: const Icon(Icons.close, size: 12, color: Colors.white),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }),
                                        if (imagenesSeleccionadas.length < 5)
                                          GestureDetector(
                                            onTap: cargando ? null : seleccionarImagenes,
                                            child: Container(
                                              width: 54, height: 54,
                                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white54)),
                                              child: const Icon(Icons.add_rounded, color: Colors.white),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 30),
                              Expanded(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _ConstruirCampoGlass('¿Qué ofreces? (Ej. Cafetera, Libro)', Icons.inventory_2_outlined, tituloController, false),
                                    const SizedBox(height: 14),
                                    _ConstruirCampoGlass('Valor estimado (MXN)', Icons.attach_money, precioController, false, 1, TextInputType.number),
                                    const SizedBox(height: 14),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.3))),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: categoriaSeleccionada, isExpanded: true, dropdownColor: const Color(0xFF2A1B54), style: const TextStyle(color: Colors.white, fontSize: 16), icon: Icon(Icons.keyboard_arrow_down, color: Colors.white.withOpacity(0.7)),
                                          items: _categorias.where((c) => c != 'Todas' && c != '❤️ Favoritos').map((String valor) => DropdownMenuItem<String>(value: valor, child: Text(valor))).toList(),
                                          onChanged: (nuevoValor) => setModalState(() => categoriaSeleccionada = nuevoValor!),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.3))),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: municipioSeleccionado, isExpanded: true, dropdownColor: const Color(0xFF2A1B54), style: const TextStyle(color: Colors.white, fontSize: 16), icon: Icon(Icons.location_on_outlined, color: Colors.white.withOpacity(0.7)),
                                          items: _municipiosZMQ.map((String m) => DropdownMenuItem<String>(value: m, child: Text(m))).toList(),
                                          onChanged: (nuevoMuni) => setModalState(() => municipioSeleccionado = nuevoMuni!),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    _ConstruirCampoGlass('Descripción y qué buscas a cambio', Icons.abc, descripcionController, false, 3),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 26),
                          SizedBox(
                            width: double.infinity, height: 58,
                            child: ElevatedButton(
                              onPressed: cargando ? null : publicarArticulo,
                              style: ElevatedButton.styleFrom(backgroundColor: TruequiColors.amarillo, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                              child: cargando ? const CircularProgressIndicator(color: Colors.white) : const Text('Validar y Publicar Trueque', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
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

  // =========================================================
  // NUEVO LOGO CON FLECHAS EN CÍRCULO (CLICKABLE AL INICIO)
  // =========================================================
  Widget _buildLogoTruequiModerno() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoverLogo = true),
      onExit: (_) => setState(() => _hoverLogo = false),
      child: GestureDetector(
        onTap: _irAlInicioYRefrescar,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutBack,
          transform: Matrix4.identity()..scale(_hoverLogo ? 1.04 : 1.0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(_hoverLogo ? 0.85 : 0.5),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: _hoverLogo ? TruequiColors.purpura.withOpacity(0.4) : Colors.white,
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: TruequiColors.purpura.withOpacity(_hoverLogo ? 0.22 : 0.08),
                blurRadius: _hoverLogo ? 24 : 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // EMBLEMA DE FLECHAS EN CÍRCULO CON ANILLO DE CRISTAL Y ROTACIÓN SUAVE
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [TruequiColors.purpura, TruequiColors.amarillo],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: TruequiColors.purpura.withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(2.5),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF23154F), TruequiColors.purpura],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
                  ),
                  child: AnimatedRotation(
                    turns: _hoverLogo ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutBack,
                    child: const Icon(
                      Icons.sync_rounded,
                      color: TruequiColors.amarillo,
                      size: 28,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF1E143A), TruequiColors.purpura],
                ).createShader(bounds),
                child: const Text(
                  'Truequi',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1.2,
                  ),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(left: 3, top: 10),
                decoration: const BoxDecoration(
                  color: TruequiColors.amarillo,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _construirBentoGrid(List<dynamic> itemsFiltrados) {
    List<Widget> filas = [];
    for (int i = 0; i < itemsFiltrados.length; i++) {
      if (i % 3 == 0) {
        final prod = itemsFiltrados[i];
        final prodId = (prod['id'] ?? '').toString();
        filas.add(Padding(
          padding: const EdgeInsets.only(bottom: 30),
          child: SizedBox(
            width: double.infinity, height: 380,
            child: GestureDetector(
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => DetalleProductoWeb(producto: prod, usuarioActual: _usuarioActual)));
                _cargarProductos();
              },
              child: _TarjetaProductoWeb(
                producto: prod,
                tipoBento: 'Hero',
                esFavorito: _favoritosIds.contains(prodId),
                onToggleFavorito: () => _toggleFavorito(prodId),
              ),
            ),
          ),
        ));
      } else {
        if (i + 1 < itemsFiltrados.length) {
          final prod1 = itemsFiltrados[i];
          final prod2 = itemsFiltrados[i + 1];
          final id1 = (prod1['id'] ?? '').toString();
          final id2 = (prod2['id'] ?? '').toString();
          filas.add(Padding(
            padding: const EdgeInsets.only(bottom: 30),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 380,
                    child: GestureDetector(
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => DetalleProductoWeb(producto: prod1, usuarioActual: _usuarioActual)));
                        _cargarProductos();
                      },
                      child: _TarjetaProductoWeb(
                        producto: prod1,
                        tipoBento: 'Regular',
                        esFavorito: _favoritosIds.contains(id1),
                        onToggleFavorito: () => _toggleFavorito(id1),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 30),
                Expanded(
                  child: SizedBox(
                    height: 380,
                    child: GestureDetector(
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => DetalleProductoWeb(producto: prod2, usuarioActual: _usuarioActual)));
                        _cargarProductos();
                      },
                      child: _TarjetaProductoWeb(
                        producto: prod2,
                        tipoBento: 'Regular',
                        esFavorito: _favoritosIds.contains(id2),
                        onToggleFavorito: () => _toggleFavorito(id2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ));
          i++;
        } else {
          final prod = itemsFiltrados[i];
          final prodId = (prod['id'] ?? '').toString();
          filas.add(Padding(
            padding: const EdgeInsets.only(bottom: 30),
            child: SizedBox(
              width: double.infinity, height: 380,
              child: GestureDetector(
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => DetalleProductoWeb(producto: prod, usuarioActual: _usuarioActual)));
                  _cargarProductos();
                },
                child: _TarjetaProductoWeb(
                  producto: prod,
                  tipoBento: 'Hero',
                  esFavorito: _favoritosIds.contains(prodId),
                  onToggleFavorito: () => _toggleFavorito(prodId),
                ),
              ),
            ),
          ));
        }
      }
    }
    return filas;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final anchoContenido = math.min(size.width * 0.85, 1400.0);

    String? fotoUrlLimpia;
    String inicialAvatar = 'U';

    if (_usuarioActual != null) {
      final fotoOriginal = _usuarioActual!['fotoUrl'] ?? _usuarioActual!['foto'];
      if (fotoOriginal != null && fotoOriginal.toString().trim().isNotEmpty) {
        final fotoStr = fotoOriginal.toString().trim();
        fotoUrlLimpia = fotoStr.contains('?')
            ? '$fotoStr&v=${DateTime.now().millisecondsSinceEpoch}'
            : '$fotoStr?v=${DateTime.now().millisecondsSinceEpoch}';
      }

      final String nombreSeguro = (_usuarioActual!['nombre']?.toString().trim().isNotEmpty == true)
          ? _usuarioActual!['nombre'].toString().trim()
          : (_usuarioActual!['correo']?.toString().trim().isNotEmpty == true
              ? _usuarioActual!['correo'].toString().trim()
              : 'Usuario');
      inicialAvatar = nombreSeguro[0].toUpperCase();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Stack(
        children: [
          RepaintBoundary(
            child: AnimatedBuilder(
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
          ),
          BackdropFilter(filter: ImageFilter.blur(sigmaX: 100.0, sigmaY: 100.0), child: Container(color: Colors.white.withOpacity(0.1))),

          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
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
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // NUEVO LOGO CON FLECHAS EN CÍRCULO QUE LLEVA AL INICIO
                              _buildLogoTruequiModerno(),
                              const Spacer(),
                              if (_usuarioActual == null) ...[
                                TextButton(
                                  onPressed: () => _mostrarLogin(iniciarEnRegistro: true),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: const Text('Crear cuenta', style: TextStyle(color: TruequiColors.textoOscuro, fontWeight: FontWeight.bold, fontSize: 16)),
                                ),
                                const SizedBox(width: 15),
                                OutlinedButton.icon(
                                  onPressed: () => _mostrarLogin(iniciarEnRegistro: false),
                                  icon: const Icon(Icons.login_rounded, size: 20),
                                  label: const Text('Ingresar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: TruequiColors.purpura,
                                    backgroundColor: Colors.white.withOpacity(0.5),
                                    side: const BorderSide(color: TruequiColors.purpura, width: 2),
                                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 0,
                                  ),
                                ),
                              ] else ...[
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () async {
                                        await Navigator.push(context, MaterialPageRoute(builder: (_) => MensajesWeb(usuarioActual: _usuarioActual!)));
                                        // Refrescar catálogo por si se completó un trueque
                                        await _cargarProductos();
                                        await _recargarUsuarioActual();
                                      },
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
                                      // AL REGRESAR DEL PERFIL, RECARGAMOS EL CATÁLOGO Y EL USUARIO
                                      await _cargarProductos();
                                      await _recargarUsuarioActual();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: TruequiColors.purpura.withOpacity(0.3), width: 2), boxShadow: [BoxShadow(color: TruequiColors.purpura.withOpacity(0.1), blurRadius: 15)]),
                                      child: CircleAvatar(
                                        radius: 22,
                                        backgroundColor: TruequiColors.purpura.withOpacity(0.1),
                                        backgroundImage: fotoUrlLimpia != null ? NetworkImage(fotoUrlLimpia) : null,
                                        child: fotoUrlLimpia == null ? Text(inicialAvatar, style: const TextStyle(color: TruequiColors.purpura, fontWeight: FontWeight.bold, fontSize: 18)) : null
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
                                Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), decoration: BoxDecoration(color: TruequiColors.amarillo.withOpacity(0.2), borderRadius: BorderRadius.circular(20)), child: const Text('Exclusivo Zona Metropolitana de Querétaro', style: TextStyle(color: Color(0xFFD48B00), fontWeight: FontWeight.bold))),
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

              SliverPersistentHeader(
                pinned: true,
                delegate: _BuscadorDelegate(onChanged: (val) => setState(() => _busqueda = val)),
              ),

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
          showCursor: true,
          cursorColor: TruequiColors.purpura,
          style: const TextStyle(fontSize: 20, color: TruequiColors.textoOscuro, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'Buscar hogar, cocina, juguetes, libros...',
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

class _TarjetaProductoWeb extends StatefulWidget {
  final Map<String, dynamic> producto;
  final String tipoBento;
  final bool esFavorito;
  final VoidCallback onToggleFavorito;

  const _TarjetaProductoWeb({
    required this.producto,
    required this.tipoBento,
    required this.esFavorito,
    required this.onToggleFavorito,
  });

  @override
  State<_TarjetaProductoWeb> createState() => _TarjetaProductoWebState();
}

class _TarjetaProductoWebState extends State<_TarjetaProductoWeb> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    final isHero = widget.tipoBento == 'Hero';
    final List<dynamic> listaFotos = widget.producto['imagenesUrls'] is List
        ? widget.producto['imagenesUrls']
        : [widget.producto['imagenUrl'] ?? 'https://via.placeholder.com/600'];

    return MouseRegion(
      onEnter: (_) => setState(() => hover = true), onExit: (_) => setState(() => hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300), curve: Curves.easeOutExpo,
        transform: Matrix4.translationValues(0, hover ? -15 : 0, 0)..scale(hover ? 1.02 : 1.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(hover ? 0.8 : 0.5),
                    borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white.withOpacity(0.9), width: 2),
                    boxShadow: [BoxShadow(color: TruequiColors.purpura.withOpacity(hover ? 0.15 : 0.05), blurRadius: hover ? 40 : 20, offset: Offset(0, hover ? 20 : 10))]
                  ),
                  child: isHero ? _buildHeroLayout() : _buildRegularLayout(),
                ),
                if (listaFotos.length > 1)
                  Positioned(
                    top: 16, left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.65), borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        children: [
                          const Icon(Icons.collections_rounded, color: Colors.white, size: 14),
                          const SizedBox(width: 5),
                          Text('${listaFotos.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  top: 16, right: 16,
                  child: GestureDetector(
                    onTap: widget.onToggleFavorito,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]),
                      child: Icon(
                        widget.esFavorito ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: widget.esFavorito ? Colors.redAccent : TruequiColors.textoOscuro,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
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
    final String municipio = (widget.producto['municipio'] ?? 'Santiago de Querétaro').toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: TruequiColors.purpura.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Text(widget.producto['categoria'] ?? 'General', style: const TextStyle(color: TruequiColors.purpura, fontSize: 13, fontWeight: FontWeight.bold))),
            const SizedBox(width: 8),
            Flexible(
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded, size: 14, color: Colors.grey),
                  const SizedBox(width: 3),
                  Flexible(child: Text(municipio, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: grande ? 18 : 10),
        Text(widget.producto['titulo'] ?? 'Sin título', style: TextStyle(fontSize: grande ? 30 : 20, fontWeight: FontWeight.w900, color: TruequiColors.textoOscuro, height: 1.1), maxLines: 2, overflow: TextOverflow.ellipsis),
        SizedBox(height: grande ? 16 : 8),
        if (grande) Text(widget.producto['descripcion'] ?? '', style: TextStyle(fontSize: 16, color: Colors.grey.shade700), maxLines: 2, overflow: TextOverflow.ellipsis),
        if (grande) const SizedBox(height: 16),
        Row(children: [const Icon(Icons.attach_money_rounded, size: 24, color: TruequiColors.amarillo), const SizedBox(width: 5), Text(widget.producto['precio']?.toString() ?? '0.00', style: TextStyle(fontSize: grande ? 24 : 18, color: Colors.black87, fontWeight: FontWeight.w900))])
      ]
    );
  }
}