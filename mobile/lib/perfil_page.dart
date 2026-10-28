import 'dart:ui';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'home_page.dart';
import 'login_screen.dart';
import '../services/google_auth_service.dart';

class PerfilPage extends StatefulWidget {
  final String correo;
  
  const PerfilPage({super.key, required this.correo});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  Map<String, dynamic>? _perfilData;
  List<dynamic> _misProductos = [];
  List<dynamic> _favoritosProductos = [];
  bool _isLoading = true;
  int _menuSeleccionado = 0; // 0: Galería, 1: Favoritos, 2: Configuración

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  // ==========================================
  // LÓGICA DE API Y AWS
  // ==========================================
  Future<void> _cargarPerfil() async {
    try {
      final urlUsuario = Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/usuario/perfil/${widget.correo}');
      final resUsuario = await http.get(urlUsuario);
      
      Map<String, dynamic>? usuarioMap;
      if (resUsuario.statusCode == 200) {
        final data = jsonDecode(resUsuario.body);
        usuarioMap = data['usuario'];
        if (mounted) setState(() { _perfilData = usuarioMap; });
      }

      final urlProductos = Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/productos');
      final resProductos = await http.get(urlProductos);

      if (resProductos.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(resProductos.body);
        final List<dynamic> todosLosProductos = data['productos'] ?? [];
        
        final List<dynamic> idsFavoritos = usuarioMap?['favoritos'] ?? [];

        if (mounted) {
          setState(() {
            _misProductos = todosLosProductos.where((p) => p['vendedorId'] == widget.correo).toList();
            _favoritosProductos = todosLosProductos.where((p) => idsFavoritos.contains(p['id'])).toList();
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

  Future<void> _removerFavorito(String productoId) async {
    try {
      List<dynamic> actuales = List.from(_perfilData?['favoritos'] ?? []);
      actuales.remove(productoId);

      final res = await http.put(
        Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/usuario/perfil'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'correo': widget.correo,
          'favoritos': actuales,
        }),
      );

      if (res.statusCode == 200) {
        if (mounted) {
          _mostrarAlertaLiquid(context, 'Eliminado de favoritos.', tipo: 'exito');
          _cargarPerfil();
        }
      }
    } catch (e) {
      debugPrint('Error al remover favorito: $e');
    }
  }

  void _mostrarAlertaLiquid(BuildContext context, String mensaje, {String tipo = 'exito'}) {
    Color colorBase = tipo == 'exito' ? TruequiColors.amarillo : Colors.redAccent;
    IconData icono = tipo == 'exito' ? Icons.check_circle_rounded : Icons.error_rounded;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0, behavior: SnackBarBehavior.floating, backgroundColor: Colors.transparent,
        margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
        duration: const Duration(seconds: 3), 
        content: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), 
                border: Border.all(color: colorBase.withValues(alpha: 0.5), width: 1.5)
              ),
              child: Row(
                children: [
                  Icon(icono, color: colorBase, size: 24),
                  const SizedBox(width: 14),
                  Expanded(child: Text(mensaje, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // MODAL DE REPORTE DE USUARIO / CONTENIDO (ISSUE #119)
  // ==========================================
  void _mostrarDialogoDenuncia() {
    final razonController = TextEditingController();
    bool enviando = false;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E143A).withOpacity(0.95),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.5), width: 1.5),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.report_problem_rounded, color: Colors.redAccent, size: 28),
                            const SizedBox(width: 10),
                            const Text(
                              'Denunciar o Reportar',
                              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Escribe las razones del reporte sobre algún perfil, comportamiento o contenido inapropiado:',
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        
                        // CASILLA PARA ESCRIBIR LAS RAZONES DEL REPORTE
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: TextField(
                            controller: razonController,
                            maxLines: 4,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(hintText: 'Escribe aquí los motivos detallados...', hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13), border: InputBorder.none),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: enviando ? null : () async {
                                final razon = razonController.text.trim();
                                if (razon.isEmpty) {
                                  _mostrarAlertaLiquid(context, 'Por favor escribe el motivo del reporte.', tipo: 'error');
                                  return;
                                }

                                setModalState(() => enviando = true);

                                try {
                                  await http.post(
                                    Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/reportes'),
                                    headers: {'Content-Type': 'application/json'},
                                    body: jsonEncode({
                                      'reportadorId': widget.correo,
                                      'motivo': razon,
                                      'fecha': DateTime.now().toIso8601String(),
                                    }),
                                  );
                                } catch (_) {}

                                if (!dialogContext.mounted) return;
                                Navigator.pop(dialogContext);

                                _mostrarAlertaLiquid(this.context, 'Reporte enviado al equipo de moderación.', tipo: 'exito');
                              },
                              child: enviando
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('Enviar Reporte', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        )
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

  void _mostrarAvisoPrivacidad() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E143A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.privacy_tip_rounded, color: TruequiColors.amarillo),
            SizedBox(width: 10),
            Text('Aviso de Privacidad', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            'En Truequi, valoramos tu privacidad y seguridad.\n\nToda tu información personal, número telefónico, ubicación de verificación ZMQ, imágenes y mensajes están protegidos por la infraestructura de Amazon Web Services (AWS).\n\nLos datos se emplean exclusivamente para validar intercambios seguros dentro de la Zona Metropolitana de Querétaro.',
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: TruequiColors.purpura, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _editarFotoPerfil() async {
    final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null) return;
    
    if (mounted) _mostrarAlertaLiquid(context, 'Comprimiendo foto...', tipo: 'exito');
    
    try {
      final File archivoOriginal = File(image.path);
      final String outPath = "${archivoOriginal.absolute.path.replaceAll(RegExp(r'\.[^\.]+$'), '')}_comprimida.jpg";
      
      final XFile? archivoComprimido = await FlutterImageCompress.compressAndGetFile(
        archivoOriginal.absolute.path, outPath,
        quality: 60, minWidth: 512, minHeight: 512, format: CompressFormat.jpeg,
      );

      final bytes = await (archivoComprimido ?? image).readAsBytes();
      final resUrl = await http.get(Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/productos/upload-url?ext=jpg'));
      if (resUrl.statusCode != 200) return;
      
      final urlData = jsonDecode(resUrl.body);
      final uploadRes = await http.put(Uri.parse(urlData['uploadUrl']), body: bytes);
      if (uploadRes.statusCode >= 400) return;
      
      final resUpdate = await http.put(
        Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/usuario/perfil'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'correo': widget.correo, 'fotoUrl': urlData['publicUrl']}),
      );
      
      if (resUpdate.statusCode == 200) {
        if (mounted) _mostrarAlertaLiquid(context, '¡Foto actualizada!', tipo: 'exito');
        _cargarPerfil();
      }
    } catch (e) { 
      debugPrint('Error de red: $e');
    }
  }

  Future<void> _editarNombreDialog() async {
    final nombreActual = _perfilData?['nombre'] ?? widget.correo.split('@').first;
    final controller = TextEditingController(text: nombreActual);
    bool guardando = false;

    await showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateModal) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Editar Nombre', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.3))),
                        child: TextField(
                          controller: controller,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          decoration: InputDecoration(hintText: 'Tu nuevo nombre', hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)), border: InputBorder.none),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: TruequiColors.amarillo, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            onPressed: guardando ? null : () async {
                              if (controller.text.trim().isEmpty) return;
                              setStateModal(() => guardando = true);
                              final res = await http.put(
                                Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/usuario/perfil'),
                                headers: {'Content-Type': 'application/json'},
                                body: jsonEncode({'correo': widget.correo, 'nombre': controller.text.trim()}),
                              );
                              if (res.statusCode == 200) {
                                if (!context.mounted) return;
                                Navigator.pop(context);
                                _cargarPerfil();
                                _mostrarAlertaLiquid(context, 'Nombre actualizado.');
                              }
                            },
                            child: guardando ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: TruequiColors.textoOscuro, strokeWidth: 2)) : const Text('Guardar', style: TextStyle(color: TruequiColors.textoOscuro, fontWeight: FontWeight.bold)),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          );
        });
      }
    );
  }

  Future<void> _borrarProductoConfirmado(String id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar artículo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('¿Deseas retirar este artículo? Esta acción no se puede deshacer.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Eliminar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
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

  Future<void> _cerrarSesion() async {
    await GoogleAuthService().signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
  }

  // ==========================================
  // UI BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: TruequiColors.amarillo));
    }

    String nombreUsuario = _perfilData?['nombre'] ?? widget.correo.split('@').first;
    nombreUsuario = nombreUsuario[0].toUpperCase() + nombreUsuario.substring(1);
    
    final foto = _perfilData?['fotoUrl'] ?? _perfilData?['foto'];
    String? fotoUrl = foto != null && foto.isNotEmpty ? (foto.contains('?') ? '$foto&v=${DateTime.now().millisecondsSinceEpoch}' : '$foto?v=${DateTime.now().millisecondsSinceEpoch}') : null;

    final promedio = _perfilData?['promedio']?.toString() ?? '5.0';
    final truequesCompletados = _perfilData?['truequesCompletados']?.toString() ?? '0';

    return RefreshIndicator(
      color: TruequiColors.amarillo,
      backgroundColor: const Color(0xFF1E143A),
      onRefresh: _cargarPerfil,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
              child: Row(
                children: [
                  const Icon(Icons.person_rounded, color: TruequiColors.amarillo, size: 32),
                  const SizedBox(width: 12),
                  const Text('Mi Perfil', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                ],
              ),
            ),
          ),

          // TARJETA PRINCIPAL (GLASSMORPHISM)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(40), border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5)),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _editarFotoPerfil,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6), 
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: TruequiColors.purpura.withOpacity(0.5), width: 2)), 
                                child: CircleAvatar(
                                  radius: 45, backgroundColor: TruequiColors.purpura, 
                                  backgroundImage: fotoUrl != null ? NetworkImage(fotoUrl) : null,
                                  child: fotoUrl == null ? const Icon(Icons.person_rounded, size: 45, color: Colors.white) : null
                                )
                              ),
                              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: TruequiColors.amarillo, shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 2)), child: const Icon(Icons.camera_alt_rounded, color: TruequiColors.textoOscuro, size: 14)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        GestureDetector(
                          onTap: _editarNombreDialog,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(child: Text(nombreUsuario, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis)),
                              const SizedBox(width: 8),
                              const Icon(Icons.edit_rounded, color: TruequiColors.amarillo, size: 16),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(widget.correo, style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5))),
                        const SizedBox(height: 20),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: TruequiColors.amarillo.withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: TruequiColors.amarillo.withOpacity(0.5))), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.location_on_rounded, size: 16, color: TruequiColors.amarillo), SizedBox(width: 6), Text('Querétaro, Qro.', style: TextStyle(fontWeight: FontWeight.bold, color: TruequiColors.amarillo, fontSize: 13))])),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ESTADÍSTICAS BENTO GRID
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(child: _buildStatCard('Artículos', '${_misProductos.length}', Icons.inventory_2_rounded, TruequiColors.purpura)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildStatCard('Trueques', truequesCompletados, Icons.handshake_rounded, Colors.greenAccent)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildStatCard('Reputación', promedio, Icons.star_rounded, TruequiColors.amarillo)),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // MENÚ HORIZONTAL (CHIPS CON NAVEGACIÓN A FAVORITOS)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 45,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildMenuChip(0, 'Galería', Icons.grid_view_rounded),
                  const SizedBox(width: 10),
                  _buildMenuChip(1, 'Favoritos', Icons.favorite_rounded),
                  const SizedBox(width: 10),
                  _buildMenuChip(2, 'Configuración', Icons.settings_rounded),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // CONTENIDO DINÁMICO
          if (_menuSeleccionado == 0) 
            _buildVistaGaleria() 
          else if (_menuSeleccionado == 1) 
            _buildVistaFavoritos() 
          else 
            _buildVistaConfiguracion(),

          const SliverToBoxAdapter(child: SizedBox(height: 140)),
        ],
      ),
    );
  }

  // ==========================================
  // WIDGETS AUXILIARES
  // ==========================================
  
  Widget _buildStatCard(String titulo, String valor, IconData icono, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icono, color: color, size: 24),
              const SizedBox(height: 10),
              Text(valor, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 2),
              Text(titulo, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6), fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuChip(int index, String titulo, IconData icon) {
    bool isSelected = _menuSeleccionado == index;
    return GestureDetector(
      onTap: () => setState(() => _menuSeleccionado = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? TruequiColors.amarillo : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: isSelected ? TruequiColors.amarillo : Colors.white.withOpacity(0.2), width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? TruequiColors.textoOscuro : Colors.white.withOpacity(0.7)),
            const SizedBox(width: 8),
            Text(titulo, style: TextStyle(color: isSelected ? TruequiColors.textoOscuro : Colors.white.withOpacity(0.7), fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildVistaGaleria() {
    if (_misProductos.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.inventory_2_outlined, size: 60, color: Colors.white.withOpacity(0.3)),
              const SizedBox(height: 16),
              Text('Aún no tienes artículos activos', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 0.7),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final prod = _misProductos[index];
            return ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                          child: Image.network(prod['imagenUrl'] ?? 'https://via.placeholder.com/150', fit: BoxFit.cover, width: double.infinity),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(prod['titulo'], style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const Spacer(),
                              SizedBox(
                                width: double.infinity, height: 32,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.2), foregroundColor: Colors.redAccent, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                  onPressed: () => _borrarProductoConfirmado(prod['id']),
                                  child: const Text('Retirar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              )
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
          },
          childCount: _misProductos.length,
        ),
      ),
    );
  }

  Widget _buildVistaFavoritos() {
    if (_favoritosProductos.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.favorite_border_rounded, size: 60, color: Colors.white.withOpacity(0.3)),
              const SizedBox(height: 16),
              Text('No tienes favoritos guardados', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 0.7),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final prod = _favoritosProductos[index];
            return ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                              child: Image.network(prod['imagenUrl'] ?? 'https://via.placeholder.com/150', fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => _removerFavorito(prod['id']),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                                  child: const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 18),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(prod['titulo'], style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text(prod['categoria'] ?? 'General', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                              const Spacer(),
                              Text(prod['estado'] ?? 'Usado', style: const TextStyle(color: TruequiColors.amarillo, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
          },
          childCount: _favoritosProductos.length,
        ),
      ),
    );
  }

  Widget _buildVistaConfiguracion() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5)),
              child: Column(
                children: [
                  _buildMenuOption(context, 'Editar mi nombre', Icons.badge_rounded, _editarNombreDialog),
                  Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                  _buildMenuOption(context, 'Actualizar foto', Icons.face_retouching_natural_rounded, _editarFotoPerfil),
                  Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                  _buildMenuOption(context, 'Aviso de Privacidad', Icons.privacy_tip_rounded, _mostrarAvisoPrivacidad),
                  Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                  _buildMenuOption(context, 'Ayuda y Denuncias', Icons.report_problem_rounded, _mostrarDialogoDenuncia),
                  Divider(height: 1, color: Colors.white.withOpacity(0.1)),
                  _buildMenuOption(context, 'Cerrar Sesión', Icons.logout_rounded, _cerrarSesion, isDestructive: true),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuOption(BuildContext context, String titulo, IconData icono, VoidCallback onTap, {bool isDestructive = false}) {
    final color = isDestructive ? Colors.redAccent : Colors.white;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: isDestructive ? Colors.red.withOpacity(0.2) : Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(14)), child: Icon(icono, size: 22, color: color)),
            const SizedBox(width: 16),
            Expanded(child: Text(titulo, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color))),
            Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }
}