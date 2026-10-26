import 'dart:ui';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'services/google_auth_service.dart';
import 'home_web.dart';
import 'detalle_producto_web.dart';

class PerfilWeb extends StatefulWidget {
  final Map<String, dynamic> usuario;
  const PerfilWeb({super.key, required this.usuario});

  @override
  State<PerfilWeb> createState() => _PerfilWebState();
}

class _PerfilWebState extends State<PerfilWeb> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _perfilData;
  List<dynamic> _misProductos = [];
  List<dynamic> _misFavoritosProductos = [];
  List<String> _favoritosIds = [];
  bool _isLoading = true;
  bool _isHoveringFoto = false;
  late AnimationController _bgController;

  int _menuSeleccionado = 0;

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
        final usuarioMap = data['usuario'] ?? {};
        _favoritosIds = usuarioMap['favoritos'] != null
            ? List<String>.from(usuarioMap['favoritos'].map((e) => e.toString()))
            : [];
        if (mounted) setState(() { _perfilData = usuarioMap; });
      }

      final urlProductos = Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/productos');
      final resProductos = await http.get(urlProductos);

      if (resProductos.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(resProductos.body);
        final List<dynamic> todosLosProductos = data['productos'] ?? [];

        if (mounted) {
          setState(() {
            _misProductos = todosLosProductos.where((p) => p['vendedorId'] == widget.usuario['correo']).toList();
            _misFavoritosProductos = todosLosProductos.where((p) => _favoritosIds.contains(p['id'].toString())).toList();
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

  Future<void> _quitarDeFavoritos(String idProducto) async {
    setState(() {
      _favoritosIds.remove(idProducto);
      _misFavoritosProductos.removeWhere((p) => p['id'].toString() == idProducto);
    });

    try {
      await http.put(
        Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/usuario/perfil'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'correo': widget.usuario['correo'], 'favoritos': _favoritosIds}),
      );
      if (mounted) _mostrarAlertaLiquid(context, 'Eliminado de tus favoritos.', tipo: 'info');
    } catch (e) {
      debugPrint('Error al quitar favorito: $e');
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
      if (resUrl.statusCode != 200) return;

      final urlData = jsonDecode(resUrl.body);
      final uploadRes = await http.put(Uri.parse(urlData['uploadUrl']), body: bytes);
      if (uploadRes.statusCode >= 400) return;

      final resUpdate = await http.put(
        Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/usuario/perfil'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'correo': widget.usuario['correo'], 'fotoUrl': urlData['publicUrl']}),
      );

      if (resUpdate.statusCode == 200) {
        if (mounted) _mostrarAlertaLiquid(context, '¡Foto actualizada!', tipo: 'exito');
        _cargarPerfil();
      }
    } catch (e) {
      if (mounted) _mostrarAlertaLiquid(context, 'Error al actualizar foto: $e', tipo: 'error');
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
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white, width: 2)),
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
    try { await GoogleAuthService().signOut(); } catch (_) {}
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeWeb()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: Color(0xFFF0F2F5), body: Center(child: CircularProgressIndicator(color: TruequiColors.purpura)));

    final nombre = _perfilData?['nombre'] ?? widget.usuario['nombre'] ?? 'Usuario';
    final telefono = _perfilData?['telefono'] ?? widget.usuario['telefono'];
    final foto = _perfilData?['fotoUrl'] ?? _perfilData?['foto'] ?? widget.usuario['fotoUrl'] ?? widget.usuario['foto'];

    String? fotoConCacheKiller = foto;
    if (foto != null && foto.toString().isNotEmpty) {
      fotoConCacheKiller = foto.toString().contains('?') ? '$foto&v=${DateTime.now().millisecondsSinceEpoch}' : '$foto?v=${DateTime.now().millisecondsSinceEpoch}';
    }

    // PUNTO 14: CONTADOR REAL DE TRUEQUES HECHOS POR EL USUARIO
    final promedio = _perfilData?['promedio']?.toString() ?? '5.0';
    final int truequesPorArticulos = _misProductos.where((p) => p['estado'] == 'Intercambiado' || p['estado'] == 'Completado').length;
    final int truequesEnPerfil = int.tryParse((_perfilData?['truequesCompletados'] ?? _perfilData?['totalCalificaciones'] ?? '0').toString()) ?? 0;
    final String truequesReales = math.max(truequesEnPerfil, truequesPorArticulos).toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        iconTheme: const IconThemeData(color: TruequiColors.textoOscuro),
        leading: Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), shape: BoxShape.circle, border: Border.all(color: Colors.white)),
            child: IconButton(icon: const Icon(Icons.arrow_back_rounded, size: 20), onPressed: () => Navigator.pop(context)),
          ),
        ),
      ),
      body: Stack(
        children: [
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (context, child) {
                return Stack(
                  children: [
                    Positioned(top: -100 + (math.sin(_bgController.value * 2 * math.pi) * 50), left: -100 + (math.cos(_bgController.value * 2 * math.pi) * 50), child: Container(width: 500, height: 500, decoration: BoxDecoration(shape: BoxShape.circle, color: TruequiColors.purpura.withOpacity(0.15)))),
                    Positioned(bottom: -50 + (math.cos(_bgController.value * 2 * math.pi) * 50), right: -50 + (math.sin(_bgController.value * 2 * math.pi) * 50), child: Container(width: 600, height: 600, decoration: BoxDecoration(shape: BoxShape.circle, color: TruequiColors.amarillo.withOpacity(0.12)))),
                  ],
                );
              },
            ),
          ),
          BackdropFilter(filter: ImageFilter.blur(sigmaX: 80.0, sigmaY: 80.0), child: Container(color: Colors.white.withOpacity(0.3))),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(40, 10, 40, 40),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 40, offset: const Offset(0, 10))]
                    ),
                    child: Row(
                      children: [
                        _buildMenuIzquierdo(nombre, telefono?.toString(), fotoConCacheKiller, promedio, truequesReales),
                        Container(width: 2, color: Colors.white.withOpacity(0.5)),
                        Expanded(
                          child: IndexedStack(
                            index: _menuSeleccionado,
                            children: [
                              _buildVistaGaleria(),
                              _buildVistaFavoritos(), // PUNTO 12: PANEL DE FAVORITOS
                              _buildVistaConfiguracion(),
                              _buildVistaPrivacidad(),
                              _buildVistaAyuda()
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuIzquierdo(String nombre, String? telefono, String? fotoUrl, String promedio, String truequesReales) {
    return Container(
      width: 340,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 25),
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
                width: 125, height: 125,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [BoxShadow(color: TruequiColors.purpura.withOpacity(_isHoveringFoto ? 0.3 : 0.1), blurRadius: _isHoveringFoto ? 30 : 15, spreadRadius: 5)],
                  image: fotoUrl != null ? DecorationImage(image: NetworkImage(fotoUrl), fit: BoxFit.cover) : null,
                  color: fotoUrl == null ? TruequiColors.purpura.withOpacity(0.1) : null,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (fotoUrl == null) const Icon(Icons.person, size: 60, color: TruequiColors.purpura),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _isHoveringFoto ? 1.0 : 0.0,
                      child: Container(
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.5)),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.camera_alt_rounded, color: Colors.white, size: 28),
                              SizedBox(height: 4),
                              Text('Actualizar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
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
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(child: Text(nombre, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: TruequiColors.textoOscuro, letterSpacing: -0.5), overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _editarNombreDialog,
                child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.edit_rounded, color: TruequiColors.amarillo, size: 16)),
              )
            ],
          ),
          const SizedBox(height: 4),
          Text(widget.usuario['correo'], style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
          if (telefono != null && telefono.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('📞 $telefono', style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
          ],
          const SizedBox(height: 20),

          // PUNTO 14: MÉTRICAS REALES CON TRUEQUES COMPLETADOS
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMetricaMini(Icons.star_rounded, promedio, 'Reputación', TruequiColors.amarillo),
                Container(width: 1, height: 30, color: Colors.grey.shade300),
                _buildMetricaMini(Icons.handshake_rounded, truequesReales, 'Trueques', Colors.teal),
                Container(width: 1, height: 30, color: Colors.grey.shade300),
                _buildMetricaMini(Icons.inventory_2_rounded, '${_misProductos.length}', 'Catálogo', TruequiColors.purpura),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                _buildBotonMenu(0, Icons.grid_view_rounded, 'Mis Publicaciones'),
                _buildBotonMenu(1, Icons.favorite_rounded, 'Mis Favoritos (${_misFavoritosProductos.length})'),
                _buildBotonMenu(2, Icons.settings_rounded, 'Configuración'),
                _buildBotonMenu(3, Icons.privacy_tip_rounded, 'Aviso de Privacidad'),
                _buildBotonMenu(4, Icons.report_problem_rounded, 'Ayuda y Denuncias'),
              ],
            ),
          ),

          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _cerrarSesion,
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Cerrar Sesión', style: TextStyle(fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: BorderSide(color: Colors.redAccent.withOpacity(0.3), width: 2),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: Colors.white
            )
          )
        ],
      ),
    );
  }

  Widget _buildMetricaMini(IconData icon, String valor, String titulo, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(valor, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: TruequiColors.textoOscuro)),
          ],
        ),
        Text(titulo, style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildBotonMenu(int index, IconData icon, String titulo) {
    final isSelected = _menuSeleccionado == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => setState(() => _menuSeleccionado = index),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: isSelected ? Colors.white : Colors.transparent,
        leading: Icon(icon, color: isSelected ? TruequiColors.purpura : Colors.grey.shade600),
        title: Text(titulo, style: TextStyle(color: isSelected ? TruequiColors.purpura : Colors.grey.shade700, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600)),
        trailing: isSelected ? const Icon(Icons.chevron_right_rounded, color: TruequiColors.purpura) : null,
      ),
    );
  }

  Widget _buildVistaGaleria() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Mi Galería de Trueques', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: TruequiColors.textoOscuro, letterSpacing: -1)),
              Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: TruequiColors.purpura.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Text('${_misProductos.length} artículos activos', style: const TextStyle(color: TruequiColors.purpura, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 30),
          Expanded(
            child: _misProductos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 20),
                      Text('Aún no tienes artículos en tu galería', style: TextStyle(fontSize: 20, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                    ],
                  ),
                )
              : GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 350, mainAxisSpacing: 25, crossAxisSpacing: 25, childAspectRatio: 0.8,
                  ),
                  itemCount: _misProductos.length,
                  itemBuilder: (context, index) => _buildTarjetaProductoGaleria(_misProductos[index]),
                ),
          )
        ],
      ),
    );
  }

  // PUNTO 12: VISTA DE FAVORITOS DENTRO DEL PERFIL
  Widget _buildVistaFavoritos() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Mis Artículos Favoritos ❤️', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: TruequiColors.textoOscuro, letterSpacing: -1)),
              Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Text('${_misFavoritosProductos.length} guardados', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 30),
          Expanded(
            child: _misFavoritosProductos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border_rounded, size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 20),
                      Text('Aún no has guardado artículos en favoritos', style: TextStyle(fontSize: 20, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                    ],
                  ),
                )
              : GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 350, mainAxisSpacing: 25, crossAxisSpacing: 25, childAspectRatio: 0.8,
                  ),
                  itemCount: _misFavoritosProductos.length,
                  itemBuilder: (context, index) {
                    final prod = _misFavoritosProductos[index];
                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetalleProductoWeb(producto: prod, usuarioActual: widget.usuario))),
                      child: _buildTarjetaFavorito(prod),
                    );
                  },
                ),
          )
        ],
      ),
    );
  }

  Widget _buildVistaConfiguracion() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Configuración del Perfil', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: TruequiColors.textoOscuro, letterSpacing: -1)),
          const SizedBox(height: 40),
          _buildTarjetaAccion(Icons.badge_rounded, 'Editar mi nombre público', 'Cambia cómo te ven otros usuarios en la plataforma.', _editarNombreDialog),
          const SizedBox(height: 20),
          _buildTarjetaAccion(Icons.face_retouching_natural_rounded, 'Actualizar fotografía', 'Sube una nueva foto desde tus archivos locales.', _editarFotoPerfil),
        ],
      ),
    );
  }

  Widget _buildVistaPrivacidad() {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Aviso de Privacidad', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: TruequiColors.textoOscuro, letterSpacing: -1)),
          SizedBox(height: 40),
          Text('En Truequi, valoramos tu privacidad y seguridad.', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: TruequiColors.purpura)),
          SizedBox(height: 15),
          Text('Toda tu información personal, número telefónico, ubicación de verificación ZMQ, imágenes y mensajes están protegidos por la infraestructura de Amazon Web Services (AWS).\n\nLos datos se emplean exclusivamente para validar intercambios seguros dentro de la Zona Metropolitana de Querétaro.', style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildVistaAyuda() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Centro de Ayuda y Moderación', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: TruequiColors.textoOscuro, letterSpacing: -1)),
          const SizedBox(height: 40),
          _buildTarjetaAccion(Icons.report_gmailerrorred_rounded, 'Denunciar un perfil o publicación ilícita', 'Nuestro filtro automático bloquea artículos prohibidos, pero puedes reportar manualmente cualquier anomalía.', () => _mostrarAlertaLiquid(context, 'Reporte enviado al equipo de moderación.', tipo: 'exito')),
          const SizedBox(height: 20),
          _buildTarjetaAccion(Icons.support_agent_rounded, 'Contactar soporte técnico', '¿Tienes problemas con la plataforma? Escríbenos.', () => _mostrarAlertaLiquid(context, 'Envía un correo a soporte@truequi.com.mx', tipo: 'info')),
        ],
      ),
    );
  }

  Widget _buildTarjetaAccion(IconData icono, String titulo, String subtitulo, VoidCallback accion) {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white, width: 2)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: TruequiColors.purpura.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icono, color: TruequiColors.purpura, size: 28)),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: TruequiColors.textoOscuro)),
        subtitle: Padding(padding: const EdgeInsets.only(top: 8), child: Text(subtitulo, style: TextStyle(color: Colors.grey.shade700))),
        trailing: ElevatedButton(onPressed: accion, style: ElevatedButton.styleFrom(backgroundColor: TruequiColors.purpura, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Gestionar')),
      ),
    );
  }

  Widget _buildTarjetaProductoGaleria(Map<String, dynamic> prod) {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white, width: 2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: Image.network(prod['imagenUrl'] ?? 'https://via.placeholder.com/300', fit: BoxFit.cover, width: double.infinity),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(prod['titulo'] ?? '', style: const TextStyle(color: TruequiColors.textoOscuro, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.1), foregroundColor: Colors.redAccent, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
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

  Widget _buildTarjetaFavorito(Map<String, dynamic> prod) {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white, width: 2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: Image.network(prod['imagenUrl'] ?? 'https://via.placeholder.com/300', fit: BoxFit.cover, width: double.infinity),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(prod['titulo'] ?? '', style: const TextStyle(color: TruequiColors.textoOscuro, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('\$${prod['precio'] ?? '0'} MXN', style: const TextStyle(color: TruequiColors.amarillo, fontWeight: FontWeight.w900)),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.1), foregroundColor: Colors.redAccent, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      icon: const Icon(Icons.heart_broken_rounded, size: 16),
                      label: const Text('Quitar favorito', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => _quitarDeFavoritos(prod['id'].toString()),
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