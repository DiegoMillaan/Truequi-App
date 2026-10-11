import 'dart:ui';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'services/google_auth_service.dart'; // USAMOS TU SERVICIO CORRECTO
import 'home_web.dart';

class PerfilWeb extends StatefulWidget {
  final Map<String, dynamic> usuario;
  const PerfilWeb({super.key, required this.usuario});

  @override
  State<PerfilWeb> createState() => _PerfilWebState();
}

class _PerfilWebState extends State<PerfilWeb> {
  Map<String, dynamic>? _perfilData;
  List<dynamic> _misProductos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    try {
      final url = Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/usuario/perfil/${widget.usuario['correo']}');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) setState(() {
          _perfilData = data['usuario'];
          _misProductos = data['misProductos'];
          _isLoading = false;
        });
      }
    } catch (e) { setState(() => _isLoading = false); }
  }

  // ==========================================
  // NOTIFICADOR LIQUID GLASS
  // ==========================================
  void _mostrarAlertaLiquid(BuildContext context, String mensaje, {String tipo = 'exito'}) {
    Color colorBase;
    IconData icono;

    if (tipo == 'exito') {
      colorBase = TruequiColors.purpura;
      icono = Icons.check_circle_rounded;
    } else if (tipo == 'error') {
      colorBase = Colors.redAccent;
      icono = Icons.error_rounded;
    } else {
      colorBase = TruequiColors.amarillo;
      icono = Icons.info_rounded;
    }

    final double anchuraPantalla = MediaQuery.of(context).size.width;
    final double margenLateral = math.max(20, (anchuraPantalla / 2) - 250); 

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        margin: EdgeInsets.only(bottom: 40, left: margenLateral, right: margenLateral),
        duration: const Duration(seconds: 4), 
        content: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFF1E143A).withOpacity(0.85),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colorBase.withOpacity(0.6), width: 2),
                boxShadow: [BoxShadow(color: colorBase.withOpacity(0.25), blurRadius: 25, offset: const Offset(0, 10))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: colorBase.withOpacity(0.2), shape: BoxShape.circle),
                    child: Icon(icono, color: colorBase, size: 28),
                  ),
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

  Future<void> _borrarProductoConfirmado(String id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E143A),
        title: const Text('Eliminar artículo', style: TextStyle(color: Colors.white)),
        content: const Text('¿Estás seguro de que deseas retirar este artículo de la plataforma? Esta acción no se puede deshacer.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
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
        if (mounted) _mostrarAlertaLiquid(context, 'Artículo retirado de la plataforma.', tipo: 'exito');
        _cargarPerfil();
      }
    } catch (e) { debugPrint('Error al borrar'); }
  }

  Future<void> _editarFotoPerfil() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null) return;
    
    if (mounted) _mostrarAlertaLiquid(context, 'Subiendo nueva foto...', tipo: 'info');
    try {
      final bytes = await image.readAsBytes();
      final ext = image.name.split('.').last.toLowerCase();
      final validExt = ['jpg', 'jpeg', 'png', 'webp'].contains(ext) ? ext : 'jpg';
      
      final resUrl = await http.get(Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/productos/upload-url?ext=$validExt'));
      final urlData = jsonDecode(resUrl.body);
      
      await http.put(Uri.parse(urlData['uploadUrl']), body: bytes);
      
      final resUpdate = await http.put(
        Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/usuario/perfil'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'correo': widget.usuario['correo'], 'fotoUrl': urlData['publicUrl']}),
      );
      
      if (resUpdate.statusCode == 200) {
        if (mounted) _mostrarAlertaLiquid(context, '¡Foto de perfil actualizada!', tipo: 'exito');
        _cargarPerfil();
      }
    } catch (e) { debugPrint('Error editando perfil'); }
  }

  Future<void> _editarNombreDialog() async {
    final nombreActual = _perfilData?['nombre'] ?? widget.usuario['nombre'] ?? '';
    final controller = TextEditingController(text: nombreActual);
    bool guardando = false;

    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
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
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white.withOpacity(0.2))),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Editar Nombre', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white.withOpacity(0.3))),
                          child: TextField(
                            controller: controller,
                            style: const TextStyle(color: Colors.white, fontSize: 18),
                            decoration: InputDecoration(hintText: 'Escribe tu nuevo nombre', hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)), border: InputBorder.none),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold))),
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
                                    _mostrarAlertaLiquid(context, 'Nombre actualizado correctamente.', tipo: 'exito');
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

  // ==========================================
  // CIERRE DE SESIÓN SEGURO
  // ==========================================
  Future<void> _cerrarSesion() async {
    try {
      await GoogleAuthService().signOut();
    } catch (e) {
      debugPrint('Error al cerrar sesión: $e');
    }
    
    if (!mounted) return;
    
    // Redirección inmediata sin temporizadores que rompan la navegación
    Navigator.pushAndRemoveUntil(
      context, 
      MaterialPageRoute(builder: (_) => const HomeWeb()), 
      (route) => false
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: Color(0xFF0D0A15), body: Center(child: CircularProgressIndicator(color: TruequiColors.purpura)));

    final nombre = _perfilData?['nombre'] ?? widget.usuario['nombre'] ?? 'Usuario';
    final foto = _perfilData?['foto'] ?? widget.usuario['foto'];
    final promedio = _perfilData?['promedio'] ?? '5.0';

    return Scaffold(
      backgroundColor: const Color(0xFF0D0A15),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: Container(width: 500, height: 500, decoration: BoxDecoration(shape: BoxShape.circle, color: TruequiColors.purpura.withOpacity(0.3)), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100), child: const SizedBox()))),
          
          SingleChildScrollView(
            padding: const EdgeInsets.all(50),
            child: Column(
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        width: 600, padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(40), border: Border.all(color: Colors.white.withOpacity(0.2))),
                        child: Column(
                          children: [
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: _editarFotoPerfil,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 70, backgroundColor: TruequiColors.purpura.withOpacity(0.2), 
                                      backgroundImage: foto != null ? NetworkImage(foto) : null, 
                                      child: foto == null ? const Icon(Icons.person, size: 70, color: Colors.white) : null
                                    ),
                                    Container(
                                      width: 140, height: 140,
                                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.5)),
                                      child: const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.camera_alt_rounded, color: Colors.white, size: 36),
                                          SizedBox(height: 5),
                                          Text('Cambiar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(nombre, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
                                const SizedBox(width: 10),
                                IconButton(onPressed: _editarNombreDialog, icon: const Icon(Icons.edit_rounded, color: TruequiColors.amarillo, size: 24), tooltip: 'Editar nombre')
                              ],
                            ),
                            Text(widget.usuario['correo'], style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.5))),
                            
                            const SizedBox(height: 25),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildStatBadge(Icons.star_rounded, '$promedio', TruequiColors.amarillo),
                                const SizedBox(width: 15),
                                _buildStatBadge(Icons.inventory_2_rounded, '${_misProductos.length} Publicaciones', TruequiColors.purpura),
                              ],
                            ),
                            const SizedBox(height: 30),
                            OutlinedButton.icon(onPressed: _cerrarSesion, icon: const Icon(Icons.logout), label: const Text('Cerrar Sesión'), style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: BorderSide(color: Colors.redAccent.withOpacity(0.5))))
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 50),
                const Align(alignment: Alignment.centerLeft, child: Text('Tus Artículos', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white))),
                const SizedBox(height: 20),
                
                _misProductos.isEmpty 
                  ? const Center(child: Text('No tienes artículos publicados.', style: TextStyle(color: Colors.grey, fontSize: 16)))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _misProductos.length,
                      itemBuilder: (context, index) {
                        final prod = _misProductos[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.2))),
                          child: Row(
                            children: [
                              ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(prod['imagenUrl'] ?? 'https://via.placeholder.com/80', width: 80, height: 80, fit: BoxFit.cover)),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(prod['titulo'], style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: TruequiColors.purpura.withOpacity(0.2), borderRadius: BorderRadius.circular(10)), child: Text(prod['categoria'], style: const TextStyle(color: TruequiColors.purpura, fontSize: 12, fontWeight: FontWeight.bold))),
                                        const SizedBox(width: 10),
                                        Text('Estado: ${prod['estado']}', style: TextStyle(color: prod['estado'] == 'Disponible' ? Colors.greenAccent : Colors.orange, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.15), foregroundColor: Colors.redAccent, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
                                icon: const Icon(Icons.delete_forever_rounded), label: const Text('Eliminar', style: TextStyle(fontWeight: FontWeight.bold)),
                                onPressed: () => _borrarProductoConfirmado(prod['id']),
                              )
                            ],
                          ),
                        );
                      },
                    )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(children: [Icon(icon, color: color, size: 20), const SizedBox(width: 8), Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold))]),
    );
  }
}