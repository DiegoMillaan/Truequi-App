import 'dart:ui';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'services/google_auth_service.dart'; 
import 'home_web.dart';

class PerfilWeb extends StatefulWidget {
  final Map<String, dynamic> usuario;
  const PerfilWeb({super.key, required this.usuario});

  @override
  State<PerfilWeb> createState() => _PerfilWebState();
}

class _PerfilWebState extends State<PerfilWeb> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _perfilData;
  List<dynamic> _misProductos = [];
  bool _isLoading = true;
  bool _isHoveringFoto = false; 
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 25))..repeat();
    _cargarPerfil();
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _cargarPerfil() async {
    try {
      final urlUsuario = Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/usuario/perfil/${widget.usuario['correo']}');
      final resUsuario = await http.get(urlUsuario);
      
      if (resUsuario.statusCode == 200) {
        final data = jsonDecode(resUsuario.body);
        if (mounted) setState(() { _perfilData = data['usuario']; });
      }

      final urlProductos = Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/productos');
      final resProductos = await http.get(urlProductos);

      if (resProductos.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(resProductos.body);
        final List<dynamic> todosLosProductos = data['productos'] ?? [];
        
        if (mounted) {
          setState(() {
            _misProductos = todosLosProductos.where((p) => p['vendedorId'] == widget.usuario['correo']).toList();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) { 
      if (mounted) setState(() => _isLoading = false); 
    }
  }

  void _mostrarAlertaLiquid(BuildContext context, String mensaje, {String tipo = 'exito'}) {
    Color colorBase = tipo == 'exito' ? TruequiColors.purpura : (tipo == 'error' ? Colors.redAccent : TruequiColors.amarillo);
    IconData icono = tipo == 'exito' ? Icons.check_circle_rounded : (tipo == 'error' ? Icons.error_rounded : Icons.info_rounded);
    final double margenLateral = math.max(20, (MediaQuery.of(context).size.width / 2) - 250); 

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0, behavior: SnackBarBehavior.floating, backgroundColor: Colors.transparent,
        margin: EdgeInsets.only(bottom: 40, left: margenLateral, right: margenLateral),
        duration: const Duration(seconds: 4), 
        content: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(24), border: Border.all(color: colorBase.withOpacity(0.3), width: 2), boxShadow: [BoxShadow(color: colorBase.withOpacity(0.15), blurRadius: 25, offset: const Offset(0, 10))]),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: colorBase.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icono, color: colorBase, size: 28)),
                  const SizedBox(width: 18),
                  Expanded(child: Text(mensaje, style: const TextStyle(color: TruequiColors.textoOscuro, fontWeight: FontWeight.bold, fontSize: 16))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _borrarProductoConfirmado(String id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar artículo', style: TextStyle(color: TruequiColors.textoOscuro, fontWeight: FontWeight.bold)),
        content: const Text('¿Estás seguro de que deseas retirar este artículo? Esta acción no se puede deshacer.', style: TextStyle(color: Colors.black54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Sí, eliminar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      final res = await http.delete(Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/productos/$id'));
      if (res.statusCode == 200) {
        if (mounted) _mostrarAlertaLiquid(context, 'Artículo retirado.', tipo: 'exito');
        _cargarPerfil();
      }
    } catch (e) { debugPrint('Error al borrar'); }
  }

  Future<void> _editarFotoPerfil() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null) return;
    
    if (mounted) _mostrarAlertaLiquid(context, 'Subiendo foto...', tipo: 'info');
    
    try {
      final bytes = await image.readAsBytes();
      final ext = image.name.split('.').last.toLowerCase();
      final validExt = ['jpg', 'jpeg', 'png', 'webp'].contains(ext) ? ext : 'jpg';
      
      final resUrl = await http.get(Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/productos/upload-url?ext=$validExt'));
      
      if (resUrl.statusCode != 200) {
        if (mounted) _mostrarAlertaLiquid(context, 'Error al conectar con el servidor de AWS.', tipo: 'error');
        return;
      }
      
      final urlData = jsonDecode(resUrl.body);
      
      final uploadRes = await http.put(Uri.parse(urlData['uploadUrl']), body: bytes);
      
      if (uploadRes.statusCode >= 400) {
        if (mounted) _mostrarAlertaLiquid(context, 'AWS S3 rechazó la subida de la imagen. Código: ${uploadRes.statusCode}', tipo: 'error');
        return;
      }
      
      final resUpdate = await http.put(
        Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/usuario/perfil'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'correo': widget.usuario['correo'], 'fotoUrl': urlData['publicUrl']}),
      );
      
      if (resUpdate.statusCode == 200) {
        if (mounted) _mostrarAlertaLiquid(context, '¡Foto actualizada!', tipo: 'exito');
        _cargarPerfil();
      } else {
        if (mounted) _mostrarAlertaLiquid(context, 'Error al guardar en base de datos. Código: ${resUpdate.statusCode}', tipo: 'error');
      }
    } catch (e) { 
      if (mounted) _mostrarAlertaLiquid(context, 'Error inesperado o de red: $e', tipo: 'error');
    }
  }

  Future<void> _editarNombreDialog() async {
    final nombreActual = _perfilData?['nombre'] ?? widget.usuario['nombre'] ?? '';
    final controller = TextEditingController(text: nombreActual);
    bool guardando = false;

    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: 400, padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 30)]),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Editar Nombre', style: TextStyle(color: TruequiColors.textoOscuro, fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade300)),
                          child: TextField(
                            controller: controller,
                            style: const TextStyle(color: TruequiColors.textoOscuro, fontSize: 18),
                            decoration: const InputDecoration(hintText: 'Tu nuevo nombre', border: InputBorder.none),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: TruequiColors.purpura, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              onPressed: guardando ? null : () async {
                                if (controller.text.trim().isEmpty) return;
                                setStateModal(() => guardando = true);
                                try {
                                  final res = await http.put(
                                    Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/usuario/perfil'),
                                    headers: {'Content-Type': 'application/json'},
                                    body: jsonEncode({'correo': widget.usuario['correo'], 'nombre': controller.text.trim()}),
                                  );
                                  if (res.statusCode == 200) {
                                    if (!context.mounted) return;
                                    Navigator.pop(context);
                                    _cargarPerfil();
                                    _mostrarAlertaLiquid(context, 'Nombre actualizado.', tipo: 'exito');
                                  }
                                } finally {
                                  setStateModal(() => guardando = false);
                                }
                              },
                              child: guardando ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Guardar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        );
      }
    );
  }

  Future<void> _cerrarSesion() async {
    try {
      await GoogleAuthService().signOut(); 
    } catch (e) {
      debugPrint('Limpiando sesión: $e');
    }
    
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeWeb()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: Color(0xFFF0F2F5), body: Center(child: CircularProgressIndicator(color: TruequiColors.purpura)));

    final nombre = _perfilData?['nombre'] ?? widget.usuario['nombre'] ?? 'Usuario';
    final foto = _perfilData?['fotoUrl'] ?? _perfilData?['foto'] ?? widget.usuario['fotoUrl'] ?? widget.usuario['foto'];
    
    // CORRECCIÓN EXACTA DE CACHÉ Y URLs DE GOOGLE
    String? fotoConCacheKiller = foto;
    if (foto != null && foto.isNotEmpty) {
      fotoConCacheKiller = foto.contains('?') 
          ? '$foto&v=${DateTime.now().millisecondsSinceEpoch}' 
          : '$foto?v=${DateTime.now().millisecondsSinceEpoch}';
    }

    final promedio = _perfilData?['promedio'] ?? '5.0';
    final size = MediaQuery.of(context).size;
    final anchoContenido = math.min(size.width * 0.85, 1200.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.7), 
        elevation: 0, 
        iconTheme: const IconThemeData(color: TruequiColors.purpura),
        title: const Text('Mi Perfil', style: TextStyle(color: TruequiColors.purpura, fontWeight: FontWeight.bold)),
        centerTitle: true,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(top: -100 + (math.sin(_bgController.value * 2 * math.pi) * 50), left: -100 + (math.cos(_bgController.value * 2 * math.pi) * 50), child: Container(width: 400, height: 400, decoration: BoxDecoration(shape: BoxShape.circle, color: TruequiColors.purpura.withOpacity(0.1)))),
                  Positioned(bottom: -50 + (math.cos(_bgController.value * 2 * math.pi) * 50), right: -50 + (math.sin(_bgController.value * 2 * math.pi) * 50), child: Container(width: 500, height: 500, decoration: BoxDecoration(shape: BoxShape.circle, color: TruequiColors.amarillo.withOpacity(0.1)))),
                ],
              );
            },
          ),
          BackdropFilter(filter: ImageFilter.blur(sigmaX: 80.0, sigmaY: 80.0), child: Container(color: Colors.white.withOpacity(0.5))),

          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(top: 120, bottom: 50, left: (size.width - anchoContenido) / 2, right: (size.width - anchoContenido) / 2),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(50),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7), 
                        borderRadius: BorderRadius.circular(40), 
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 40, offset: const Offset(0, 10))]
                      ),
                      child: Column(
                        children: [
                          MouseRegion(
                            onEnter: (_) => setState(() => _isHoveringFoto = true),
                            onExit: (_) => setState(() => _isHoveringFoto = false),
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: _editarFotoPerfil,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 160, height: 160,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 4),
                                  boxShadow: [BoxShadow(color: TruequiColors.purpura.withOpacity(_isHoveringFoto ? 0.3 : 0.1), blurRadius: _isHoveringFoto ? 30 : 15, spreadRadius: 5)],
                                  image: fotoConCacheKiller != null ? DecorationImage(image: NetworkImage(fotoConCacheKiller), fit: BoxFit.cover) : null,
                                  color: foto == null ? TruequiColors.purpura.withOpacity(0.1) : null,
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    if (foto == null) const Icon(Icons.person, size: 80, color: TruequiColors.purpura),
                                    AnimatedOpacity(
                                      duration: const Duration(milliseconds: 200),
                                      opacity: _isHoveringFoto ? 1.0 : 0.0,
                                      child: Container(
                                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.5)),
                                        child: const Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.camera_alt_rounded, color: Colors.white, size: 36),
                                              SizedBox(height: 4),
                                              Text('Actualizar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 25),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(nombre, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: TruequiColors.textoOscuro, letterSpacing: -1)),
                              const SizedBox(width: 10),
                              Container(
                                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                                child: IconButton(onPressed: _editarNombreDialog, icon: const Icon(Icons.edit_rounded, color: TruequiColors.amarillo, size: 20), tooltip: 'Editar nombre'),
                              )
                            ],
                          ),
                          Text(widget.usuario['correo'], style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                          
                          const SizedBox(height: 30),
                          
                          Wrap(
                            spacing: 20, runSpacing: 15, alignment: WrapAlignment.center,
                            children: [
                              _buildMetricaGlass(Icons.star_rounded, '$promedio', 'Calificación', TruequiColors.amarillo),
                              _buildMetricaGlass(Icons.inventory_2_rounded, '${_misProductos.length}', 'Publicaciones', TruequiColors.purpura),
                              _buildMetricaGlass(Icons.handshake_rounded, '12', 'Trueques Exitosos', Colors.teal),
                            ],
                          ),
                          
                          const SizedBox(height: 40),
                          OutlinedButton.icon(
                            onPressed: _cerrarSesion, 
                            icon: const Icon(Icons.logout, size: 20), 
                            label: const Text('Cerrar Sesión', style: TextStyle(fontWeight: FontWeight.bold)), 
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent, 
                              side: BorderSide(color: Colors.redAccent.withOpacity(0.3), width: 2),
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              backgroundColor: Colors.white
                            )
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 60),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Mi Galería', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: TruequiColors.textoOscuro, letterSpacing: -1)),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: TruequiColors.purpura.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Text('${_misProductos.length} artículos', style: const TextStyle(color: TruequiColors.purpura, fontWeight: FontWeight.bold))),
                  ],
                ),
                const SizedBox(height: 30),
                
                _misProductos.isEmpty 
                  ? Container(
                      width: double.infinity, padding: const EdgeInsets.all(50),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white, width: 2)),
                      child: Column(
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey.shade400),
                          const SizedBox(height: 15),
                          Text('Aún no tienes artículos en tu galería', style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 400,
                        mainAxisSpacing: 25,
                        crossAxisSpacing: 25,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: _misProductos.length,
                      itemBuilder: (context, index) {
                        final prod = _misProductos[index];
                        return _buildTarjetaProductoGaleria(prod);
                      },
                    )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricaGlass(IconData icon, String valor, String titulo, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))]
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 24)),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(valor, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: TruequiColors.textoOscuro)),
              Text(titulo, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTarjetaProductoGaleria(Map<String, dynamic> prod) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  child: Image.network(prod['imagenUrl'] ?? 'https://via.placeholder.com/300', fit: BoxFit.cover),
                ),
                Positioned(
                  top: 15, right: 15,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(15)),
                        child: Text(prod['estado'] ?? 'Disponible', style: TextStyle(color: prod['estado'] == 'Disponible' ? Colors.greenAccent : Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: TruequiColors.purpura.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(prod['categoria'] ?? 'General', style: const TextStyle(color: TruequiColors.purpura, fontSize: 11, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 10),
                  Text(prod['titulo'], style: const TextStyle(color: TruequiColors.textoOscuro, fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.1), foregroundColor: Colors.redAccent, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18), 
                      label: const Text('Retirar', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => _borrarProductoConfirmado(prod['id']),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}