import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'home_page.dart';

class PerfilPublicoDialog extends StatefulWidget {
  final String correoUsuario;
  final Map<String, dynamic>? usuarioActual; // Agregado para saber quién reporta

  const PerfilPublicoDialog({
    super.key, 
    required this.correoUsuario,
    this.usuarioActual,
  });

  static void mostrar(BuildContext context, String correo, {Map<String, dynamic>? usuarioActual}) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (_) => PerfilPublicoDialog(correoUsuario: correo, usuarioActual: usuarioActual),
    );
  }

  @override
  State<PerfilPublicoDialog> createState() => _PerfilPublicoDialogState();
}

class _PerfilPublicoDialogState extends State<PerfilPublicoDialog> {
  static const String _baseUrl = 'https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev';

  Map<String, dynamic>? _perfilData;
  List<dynamic> _productos = [];
  List<dynamic> _resenas = [];
  bool _isLoading = true;
  int _tabActiva = 0; // 0 = Comentarios, 1 = Artículos

  @override
  void initState() {
    super.initState();
    _cargarPerfilPublico();
  }

  Future<void> _cargarPerfilPublico() async {
    try {
      final url = Uri.parse('$_baseUrl/usuario/perfil/${widget.correoUsuario}');
      final res = await http.get(url);
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final userMap = data['usuario'];
        final prods = data['misProductos'] is List ? List<dynamic>.from(data['misProductos']) : <dynamic>[];
        final resenasList = userMap != null && userMap['resenas'] is List ? List<dynamic>.from(userMap['resenas']) : <dynamic>[];

        if (mounted) {
          setState(() {
            _perfilData = userMap;
            _productos = prods;
            _resenas = resenasList;
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

  // ==========================================
  // MODAL DE DENUNCIA HOMOLOGADO CON WEB
  // ==========================================
  void _mostrarModalDenuncia() {
    String motivoSeleccionado = 'Artículos o servicios ilícitos';
    final detallesController = TextEditingController();
    bool enviando = false;

    final List<String> motivos = [
      'Artículos o servicios ilícitos',
      'Comportamiento ofensivo o acoso',
      'Intento de fraude o estafa',
      'Incumplimiento en el punto de encuentro',
      'Perfil falso o spam',
    ];

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            Future<void> enviarDenuncia() async {
              setModalState(() => enviando = true);
              try {
                final res = await http.put(
                  Uri.parse('$_baseUrl/usuario/calificar'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'tipo': 'denuncia',
                    'correoDenunciado': widget.correoUsuario,
                    'motivo': motivoSeleccionado,
                    'detalles': detallesController.text.trim(),
                    'denunciante': widget.usuarioActual?['correo'] ?? 'Usuario Móvil Truequi',
                  }),
                );

                if (!dialogCtx.mounted) return;
                Navigator.pop(dialogCtx);

                if (res.statusCode == 200 && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      content: const Row(
                        children: [
                          Icon(Icons.shield_rounded, color: Colors.white),
                          SizedBox(width: 12),
                          Expanded(child: Text('Denuncia enviada. El equipo revisará este perfil.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              }
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(36),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 35, sigmaY: 35),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E143A).withOpacity(0.95),
                      borderRadius: BorderRadius.circular(36),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.6), width: 1.5),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.2), shape: BoxShape.circle),
                              child: const Icon(Icons.gpp_bad_rounded, color: Colors.redAccent, size: 24),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(child: Text('Reportar Perfil', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900))),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const Text('Selecciona el motivo:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: motivoSeleccionado,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF2A1B54),
                              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              items: motivos.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                              onChanged: (v) => setModalState(() => motivoSeleccionado = v!),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: TextField(
                            controller: detallesController,
                            maxLines: 3,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Describe brevemente el problema...',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: enviando ? null : enviarDenuncia,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              icon: const Icon(Icons.flag_rounded, size: 18),
                              label: enviando
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('Enviar', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40), // Redondeo original
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.85, // Expande para contener las listas
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: TruequiColors.purpura.withOpacity(0.5), width: 2),
            ),
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: TruequiColors.amarillo))
              : _construirTarjetaPerfil(),
          ),
        ),
      ),
    );
  }

  Widget _construirTarjetaPerfil() {
    final nombre = _perfilData?['nombre'] ?? widget.correoUsuario.split('@')[0];
    final foto = _perfilData?['fotoUrl'] ?? _perfilData?['foto'];
    
    String? fotoConCacheKiller = foto;
    if (foto != null && foto.isNotEmpty) {
      fotoConCacheKiller = foto.contains('?') 
          ? '$foto&v=${DateTime.now().millisecondsSinceEpoch}' 
          : '$foto?v=${DateTime.now().millisecondsSinceEpoch}';
    }
    
    final promedio = _perfilData?['promedio']?.toString() ?? '5.0';
    final truequesCompletados = _perfilData?['truequesCompletados']?.toString() ?? '0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CABECERA (Avatar, Info, Botones)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 70, height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: TruequiColors.purpura, width: 2),
                boxShadow: [BoxShadow(color: TruequiColors.purpura.withOpacity(0.3), blurRadius: 10)],
                image: fotoConCacheKiller != null ? DecorationImage(image: NetworkImage(fotoConCacheKiller), fit: BoxFit.cover) : null,
                color: foto == null ? TruequiColors.purpura.withOpacity(0.2) : null,
              ),
              child: foto == null ? const Icon(Icons.person, size: 35, color: Colors.white) : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: Text(nombre, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.greenAccent.withOpacity(0.5))),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_rounded, color: Colors.greenAccent, size: 12),
                            SizedBox(width: 4),
                            Text('ZMQ', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(widget.correoUsuario, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _mostrarModalDenuncia,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.flag_rounded, color: Colors.redAccent, size: 14),
                        SizedBox(width: 4),
                        Text('Denunciar', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
        const SizedBox(height: 24),
        
        // MÉTRICAS (Adaptadas del original _metricaColumna)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1))
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _metricaColumna(Icons.star_rounded, promedio, 'Reputación', TruequiColors.amarillo),
              Container(height: 35, width: 1, color: Colors.white.withOpacity(0.2)),
              _metricaColumna(Icons.handshake_rounded, truequesCompletados, 'Trueques', Colors.greenAccent),
              Container(height: 35, width: 1, color: Colors.white.withOpacity(0.2)),
              _metricaColumna(Icons.inventory_2_rounded, '${_productos.length}', 'Catálogo', TruequiColors.purpura),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // SELECTOR DE PESTAÑAS
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildTabSelector(0, Icons.forum_rounded, 'Comentarios (${_resenas.length})'),
              const SizedBox(width: 10),
              _buildTabSelector(1, Icons.grid_view_rounded, 'Artículos (${_productos.length})'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // CONTENIDO DINÁMICO (Comentarios o Artículos)
        Expanded(
          child: _tabActiva == 0 ? _buildListaResenas() : _buildGridArticulos(),
        ),
      ],
    );
  }

  // MÉTODO ORIGINAL CONSERVADO
  Widget _metricaColumna(IconData icono, String valor, String titulo, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, color: color, size: 20),
            const SizedBox(width: 4),
            Text(valor, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        Text(titulo, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTabSelector(int index, IconData icon, String texto) {
    final bool activo = _tabActiva == index;
    return GestureDetector(
      onTap: () => setState(() => _tabActiva = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: activo ? TruequiColors.purpura : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(activo ? 0.5 : 0.2), width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(texto, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildListaResenas() {
    if (_resenas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review_outlined, size: 40, color: Colors.white.withOpacity(0.3)),
            const SizedBox(height: 10),
            Text('Aún no hay comentarios', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: _resenas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final r = _resenas[idx];
        final autor = (r['autorNombre'] ?? 'Usuario Truequi').toString();
        final estrellas = double.tryParse((r['estrellas'] ?? '5.0').toString()) ?? 5.0;
        final comentario = (r['comentario'] ?? '').toString();
        final fechaRaw = (r['fecha'] ?? '').toString();
        final fechaCorta = fechaRaw.length >= 10 ? fechaRaw.substring(0, 10) : '';

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(radius: 12, backgroundColor: TruequiColors.amarillo, child: Text(autor[0].toUpperCase(), style: const TextStyle(color: TruequiColors.textoOscuro, fontSize: 10, fontWeight: FontWeight.bold))),
                      const SizedBox(width: 8),
                      Text(autor, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  Text(fechaCorta, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: List.generate(5, (i) => Icon(i < estrellas.round() ? Icons.star_rounded : Icons.star_border_rounded, color: TruequiColors.amarillo, size: 14)),
              ),
              if (comentario.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(comentario, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildGridArticulos() {
    if (_productos.isEmpty) {
      return Center(
        child: Text('No tiene artículos activos.', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
      );
    }

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: _productos.length,
      itemBuilder: (context, i) {
        final p = _productos[i];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  child: Image.network(p['imagenUrl'] ?? 'https://via.placeholder.com/150', width: double.infinity, fit: BoxFit.cover),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p['titulo']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text('\$${p['precio'] ?? '0'} MXN', style: const TextStyle(color: TruequiColors.amarillo, fontWeight: FontWeight.w900, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}