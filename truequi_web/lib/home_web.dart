import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart' as web;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

// Rutas corregidas a las carpetas dentro de lib
import 'services/google_auth_service.dart';
import 'widgets/google_login_button.dart';

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

class _HomeWebState extends State<HomeWeb> with SingleTickerProviderStateMixin {
  // ==========================================
  // 1. URLS OFICIALES DE TU BACKEND (AWS)
  // ==========================================
  // Auth apunta a 16663yaped
  static const String _loginUrl = 'https://16663yaped.execute-api.us-east-1.amazonaws.com/dev/login';
  static const String _registroUrl = 'https://16663yaped.execute-api.us-east-1.amazonaws.com/dev/registro';
  
  // Catálogo apunta a y3cokge8sa
  static const String _productosUrl = 'https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/productos';
  static const String _uploadUrlEndpoint = 'https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/productos/upload-url';

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  Timer? _timer;
  double _animationValue = 0;

  List<dynamic> _productos = [];
  bool _isLoadingCatalog = true;

  @override
  void initState() {
    super.initState();
    _inicializarGoogle();
    _cargarProductos(); // Petición a AWS al abrir la página
    
    // Animación fluida de fondo
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted) return;
      setState(() {
        _animationValue += 0.008;
        if (_animationValue > 2 * math.pi) _animationValue = 0;
      });
    });
  }

  Future<void> _inicializarGoogle() async {
    try { await _googleSignIn.initialize(); } catch (e) { debugPrint('ERROR GOOGLE: $e'); }
  }

  // ==========================================
  // 2. CONSUMO DE API: CATÁLOGO DE DYNAMODB
  // ==========================================
  Future<void> _cargarProductos() async {
    try {
      final response = await http.get(Uri.parse(_productosUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _productos = data['productos'];
          _isLoadingCatalog = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingCatalog = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ============================================================
  // 3. MODAL DE LOGIN / REGISTRO (CON DEFENSAS FRONTEND)
  // ============================================================
  void _mostrarLogin() {
    final nombreController = TextEditingController(); // <-- NUEVO CAMPO
    final correoController = TextEditingController();
    final passwordController = TextEditingController();
    bool cargando = false;
    bool ocultarPassword = true;
    bool esRegistro = false; 
    String? error;

    final googleAuth = GoogleAuthService();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {

            googleAuth.listenToAuthentication(
              onSuccess: (usuario) {
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Acceso con Google exitoso'), backgroundColor: Colors.green)
                  );
                }
              },
              onError: (mensaje) {
                setModalState(() { error = mensaje; cargando = false; });
              }
            );

            Future<void> procesarFormulario() async {
              final nombre = nombreController.text.trim();
              final correo = correoController.text.trim();
              final password = passwordController.text;

              // Validaciones Frontend
              if (esRegistro && nombre.isEmpty) { setModalState(() => error = 'Por favor ingresa tu nombre.'); return; }
              if (correo.isEmpty || password.isEmpty) { setModalState(() => error = 'Completa todos los campos.'); return; }
              
              final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
              if (!emailRegex.hasMatch(correo)) { setModalState(() => error = 'Ingresa un correo electrónico válido.'); return; }
              if (password.length < 5) { setModalState(() => error = 'La contraseña debe tener al menos 5 caracteres.'); return; }

              setModalState(() { cargando = true; error = null; });

              try {
                final urlActual = esRegistro ? _registroUrl : _loginUrl;
                
                final response = await http.post(
                  Uri.parse(urlActual),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'nombre': nombre, // Se envía el nombre (aunque tu backend actual solo guarda correo/pass, es buena práctica mandarlo)
                    'correo': correo, 
                    'password': password,
                    'rol': 'Usuario' 
                  }),
                );

                Map<String, dynamic> data = {};
                if (response.body.isNotEmpty) data = jsonDecode(response.body);

                if (response.statusCode >= 200 && response.statusCode < 300) {
                  if (!dialogContext.mounted) return;
                  Navigator.of(dialogContext).pop();
                  if (mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(content: Text(data['message'] ?? 'Éxito'), backgroundColor: Colors.green)
                    );
                  }
                  return;
                }
                setModalState(() { error = data['error'] ?? 'Credenciales incorrectas o usuario ya existe.'; cargando = false; });
              } catch (e) {
                setModalState(() { error = 'Error de conexión con AWS.'; cargando = false; });
              }
            }

            return Dialog(
              backgroundColor: Colors.white, 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              child: Container(
                width: 400, 
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                      children: [
                        Text(esRegistro ? 'Crea tu cuenta' : 'Iniciar sesión', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: TruequiColors.purpura)), 
                        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))
                      ]
                    ),
                    const SizedBox(height: 25),

                    // CAMPO NOMBRE COMPLETO (Solo aparece en Registro)
                    if (esRegistro) ...[
                      TextField(
                        controller: nombreController, 
                        decoration: const InputDecoration(labelText: 'Nombre Completo', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline_rounded))
                      ),
                      const SizedBox(height: 15),
                    ],

                    TextField(
                      controller: correoController, 
                      decoration: const InputDecoration(labelText: 'Correo electrónico', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email_outlined))
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: passwordController, 
                      obscureText: ocultarPassword, 
                      decoration: InputDecoration(
                        labelText: 'Contraseña', border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(icon: Icon(ocultarPassword ? Icons.visibility : Icons.visibility_off), onPressed: () => setModalState(() => ocultarPassword = !ocultarPassword))
                      )
                    ),
                    if (error != null) Padding(padding: const EdgeInsets.only(top: 15), child: Text(error!, style: const TextStyle(color: Colors.red, fontSize: 13))),
                    const SizedBox(height: 25),
                    
                    SizedBox(
                      width: double.infinity, height: 50, 
                      child: ElevatedButton(
                        onPressed: cargando ? null : procesarFormulario, 
                        style: ElevatedButton.styleFrom(backgroundColor: TruequiColors.amarillo, foregroundColor: TruequiColors.textoOscuro, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), 
                        child: cargando 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: TruequiColors.textoOscuro, strokeWidth: 2)) 
                          : Text(esRegistro ? 'Registrarme' : 'Ingresar', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
                      )
                    ),
                    const SizedBox(height: 15),

                    TextButton(
                      onPressed: () => setModalState(() { esRegistro = !esRegistro; error = null; }),
                      child: Text(esRegistro ? '¿Ya tienes cuenta? Inicia sesión' : '¿No tienes cuenta? Regístrate', style: const TextStyle(color: TruequiColors.purpura, fontWeight: FontWeight.bold)),
                    ),

                    const Divider(height: 30),
                    const Text('O continúa con', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 15),

                    const GoogleLoginButton(),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      googleAuth.dispose(); 
    });
  }

  // ============================================================
  // 4. MODAL: SUBIR ARTÍCULO (CREAR TRUEQUE CON S3)
  // ============================================================
  void _mostrarPublicar() {
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
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {

            Future<void> seleccionarImagen() async {
              final XFile? image = await picker.pickImage(source: ImageSource.gallery);
              if (image != null) {
                final bytes = await image.readAsBytes();
                setModalState(() {
                  imagenBytes = bytes;
                  imagenExt = image.name.split('.').last.toLowerCase();
                  error = null;
                });
              }
            }

            Future<void> publicarArticulo() async {
              final titulo = tituloController.text.trim();
              final descripcion = descripcionController.text.trim();
              final precioRaw = precioController.text.trim();
              final precio = double.tryParse(precioRaw);

              // Validaciones Frontend
              if (titulo.length < 5 || titulo.length > 80) { setModalState(() => error = 'El título debe tener entre 5 y 80 caracteres.'); return; }
              if (descripcion.length < 15) { setModalState(() => error = 'La descripción es muy corta. Mínimo 15 caracteres.'); return; }
              if (precio == null || precio <= 0 || precio > 100000) { setModalState(() => error = 'El valor debe ser numérico entre \$1 y \$100,000 MXN.'); return; }
              if (imagenBytes == null) { setModalState(() => error = 'Debes subir una fotografía del artículo.'); return; }
              if (imagenExt != 'jpg' && imagenExt != 'jpeg' && imagenExt != 'png' && imagenExt != 'webp') { setModalState(() => error = 'Formato de imagen inválido (solo JPG, PNG o WEBP).'); return; }

              setModalState(() { cargando = true; error = null; });

              try {
                // Paso A: Pedir URL pre-firmada a AWS API Gateway
                final resUrl = await http.get(Uri.parse('$_uploadUrlEndpoint?ext=$imagenExt'));
                if (resUrl.statusCode != 200) throw Exception('Error al obtener URL de S3');
                
                final urlData = jsonDecode(resUrl.body);
                final uploadUrl = urlData['uploadUrl'];
                final publicUrl = urlData['publicUrl'];

                // Paso B: Subir los bytes de la imagen directamente a S3
                final resS3 = await http.put(Uri.parse(uploadUrl), body: imagenBytes);
                if (resS3.statusCode != 200) throw Exception('Error al subir imagen a S3');

                // Paso C: Registrar el producto en DynamoDB
                final resDB = await http.post(
                  Uri.parse(_productosUrl),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'titulo': titulo,
                    'descripcion': descripcion,
                    'precio': precio,
                    'categoria': categoriaSeleccionada,
                    'imagenUrl': publicUrl,
                    'vendedorId': '1' // ID temporal para propósitos del sprint
                  }),
                );

                if (resDB.statusCode == 201) {
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext); // Cierra modal
                  if (mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('¡Artículo publicado exitosamente!'), backgroundColor: Colors.green));
                  }
                  _cargarProductos(); // Refresca el feed automáticamente
                } else {
                  throw Exception('Error al guardar en DynamoDB');
                }
              } catch (e) {
                setModalState(() { error = 'Hubo un error al publicar el artículo: $e'; cargando = false; });
              }
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Container(
                width: 800, padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 35, offset: const Offset(0, 15))]),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Crear Trueque', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: TruequiColors.textoOscuro)),
                        IconButton(onPressed: () => Navigator.of(dialogContext).pop(), icon: const Icon(Icons.close)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Columna Izquierda: Imagen
                        Expanded(
                          flex: 1,
                          child: GestureDetector(
                            onTap: cargando ? null : seleccionarImagen,
                            child: Container(
                              height: 300,
                              decoration: BoxDecoration(color: const Color(0xFFF8F8FB), borderRadius: BorderRadius.circular(16), border: Border.all(color: TruequiColors.purpura.withOpacity(0.3), width: 2, style: BorderStyle.solid)),
                              child: imagenBytes != null
                                  ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.memory(imagenBytes!, fit: BoxFit.cover, width: double.infinity, height: double.infinity))
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_a_photo_rounded, size: 48, color: TruequiColors.purpura.withOpacity(0.6)),
                                        const SizedBox(height: 12),
                                        Text('Añadir foto del artículo', style: TextStyle(color: TruequiColors.purpura.withOpacity(0.8), fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 30),
                        // Columna Derecha: Formulario
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(controller: tituloController, decoration: const InputDecoration(labelText: '¿Qué ofreces? (Título)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.inventory_2_outlined))),
                              const SizedBox(height: 15),
                              TextField(controller: precioController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Valor estimado (MXN)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.attach_money))),
                              const SizedBox(height: 15),
                              DropdownButtonFormField<String>(
                                value: categoriaSeleccionada,
                                decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder(), prefixIcon: Icon(Icons.category_outlined)),
                                items: ['Electrónica', 'Hogar', 'Ropa', 'Coleccionables', 'Deportes', 'Libros', 'Accesorios'].map((String valor) {
                                  return DropdownMenuItem<String>(value: valor, child: Text(valor));
                                }).toList(),
                                onChanged: (nuevoValor) { setModalState(() { categoriaSeleccionada = nuevoValor!; }); },
                              ),
                              const SizedBox(height: 15),
                              TextField(controller: descripcionController, maxLines: 3, decoration: const InputDecoration(labelText: 'Descripción y qué buscas a cambio', border: OutlineInputBorder(), alignLabelWithHint: true)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (error != null) ...[
                      Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.withOpacity(0.2))), child: Text(error!, style: const TextStyle(color: Colors.red, fontSize: 13))),
                      const SizedBox(height: 15),
                    ],
                    SizedBox(
                      width: double.infinity, height: 52,
                      child: ElevatedButton(
                        onPressed: cargando ? null : publicarArticulo,
                        style: ElevatedButton.styleFrom(backgroundColor: TruequiColors.amarillo, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        child: cargando ? const CircularProgressIndicator(color: Colors.white) : const Text('Publicar Trueque', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  // ============================================================
  // 5. DISEÑO DE LA PÁGINA PRINCIPAL
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      body: Stack(
        children: [
          // Capas de fondo animadas
          Positioned(top: -180 + math.sin(_animationValue) * 30, right: -120 + math.cos(_animationValue) * 30, child: Container(width: 420, height: 420, decoration: BoxDecoration(shape: BoxShape.circle, color: TruequiColors.purpura.withOpacity(0.16)), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: const SizedBox()))),
          Positioned(bottom: -180 + math.cos(_animationValue) * 35, left: -120 + math.sin(_animationValue) * 35, child: Container(width: 420, height: 420, decoration: BoxDecoration(shape: BoxShape.circle, color: TruequiColors.amarillo.withOpacity(0.12)), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: const SizedBox()))),
          
          CustomScrollView(
            slivers: [
              // Navbar
              SliverAppBar(
                pinned: true, elevation: 0, backgroundColor: Colors.white.withOpacity(0.86), toolbarHeight: 82, titleSpacing: 30,
                title: Row(children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: TruequiColors.purpura, borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 27)), const SizedBox(width: 12), const Text('Truequi', style: TextStyle(color: TruequiColors.textoOscuro, fontSize: 24, fontWeight: FontWeight.bold))]),
                actions: [
                  OutlinedButton.icon(
                    onPressed: _mostrarPublicar, 
                    icon: const Icon(Icons.add_circle_outline, size: 19), label: const Text('Subir artículo'),
                    style: OutlinedButton.styleFrom(foregroundColor: TruequiColors.purpura, side: BorderSide(color: TruequiColors.purpura.withOpacity(0.3)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(right: 30),
                    child: ElevatedButton(
                      onPressed: _mostrarLogin,
                      style: ElevatedButton.styleFrom(backgroundColor: TruequiColors.purpura, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text('Iniciar sesión', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
              
              // Hero Banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(60, 40, 60, 30),
                  child: Container(
                    width: double.infinity, padding: const EdgeInsets.all(45),
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6B42E0), Color(0xFF8A6BE8)]), borderRadius: BorderRadius.circular(30)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Intercambia lo que ya no necesitas', style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 15),
                        Text('Descubre miles de artículos y dales una segunda vida.', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.fromLTRB(60, 10, 60, 20), child: Text('Catálogo en Vivo', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: TruequiColors.textoOscuro)))),

              // ==========================================
              // 6. GRID DINÁMICO DE PRODUCTOS DESDE AWS
              // ==========================================
              _isLoadingCatalog
                ? const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(60.0), child: Center(child: CircularProgressIndicator(color: TruequiColors.purpura))))
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(60, 0, 60, 60),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) { return _TarjetaProductoWeb(producto: _productos[index]); },
                        childCount: _productos.length,
                      ),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 290, mainAxisExtent: 310, crossAxisSpacing: 20, mainAxisSpacing: 20),
                    ),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}

// ====================================================================
// COMPONENTE: TARJETA DE PRODUCTO
// ====================================================================
class _TarjetaProductoWeb extends StatefulWidget {
  final Map<String, dynamic> producto;
  const _TarjetaProductoWeb({required this.producto});
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
        duration: const Duration(milliseconds: 180), transform: Matrix4.identity()..translate(0.0, hover ? -5.0 : 0.0),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(hover ? 0.12 : 0.05), blurRadius: hover ? 22 : 12, offset: const Offset(0, 7))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Container(width: double.infinity, decoration: BoxDecoration(color: const Color(0xFFF1EFF8), borderRadius: const BorderRadius.vertical(top: Radius.circular(20)), image: DecorationImage(image: NetworkImage(widget.producto['imagenUrl'] ?? 'https://via.placeholder.com/200'), fit: BoxFit.cover)))),
            Padding(
              padding: const EdgeInsets.all(17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: TruequiColors.amarillo.withOpacity(0.2), borderRadius: BorderRadius.circular(6)), child: Text(widget.producto['categoria'] ?? 'General', style: const TextStyle(color: TruequiColors.amarillo, fontSize: 10, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 8), Text(widget.producto['titulo'] ?? 'Sin título', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: TruequiColors.textoOscuro), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12), Row(children: [const Icon(Icons.attach_money_rounded, size: 18, color: TruequiColors.purpura), const SizedBox(width: 5), Text(widget.producto['precio']?.toString() ?? '0.00', style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600))]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}