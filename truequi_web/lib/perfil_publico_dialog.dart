import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'home_web.dart';

class PerfilPublicoDialog extends StatefulWidget {
  final String correoUsuario;
  final Map<String, dynamic>? usuarioActual;

  const PerfilPublicoDialog({
    super.key,
    required this.correoUsuario,
    this.usuarioActual,
  });

  static Future<void> mostrar(
    BuildContext context,
    String correoUsuario, {
    Map<String, dynamic>? usuarioActual,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (_) => PerfilPublicoDialog(
        correoUsuario: correoUsuario,
        usuarioActual: usuarioActual,
      ),
    );
  }

  @override
  State<PerfilPublicoDialog> createState() => _PerfilPublicoDialogState();
}

class _PerfilPublicoDialogState extends State<PerfilPublicoDialog> with SingleTickerProviderStateMixin {
  static const String _baseUrl = 'https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev';

  late AnimationController _orbController;
  Map<String, dynamic>? _usuario;
  List<dynamic> _productos = [];
  List<dynamic> _resenas = [];
  bool _cargando = true;
  int _tabActiva = 0; // 0 = Reseñas Públicas, 1 = Artículos

  @override
  void initState() {
    super.initState();
    _orbController = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat(reverse: true);
    _cargarPerfilPublico();
  }

  @override
  void dispose() {
    _orbController.dispose();
    super.dispose();
  }

  Future<void> _cargarPerfilPublico() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/usuario/perfil/${widget.correoUsuario}'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final userMap = data['usuario'] != null ? Map<String, dynamic>.from(data['usuario']) : <String, dynamic>{};
        final prods = data['misProductos'] is List ? List<dynamic>.from(data['misProductos']) : <dynamic>[];
        final resenasList = userMap['resenas'] is List ? List<dynamic>.from(userMap['resenas']) : <dynamic>[];

        if (mounted) {
          setState(() {
            _usuario = userMap;
            _productos = prods;
            _resenas = resenasList;
            _cargando = false;
          });
        }
      } else {
        if (mounted) setState(() => _cargando = false);
      }
    } catch (e) {
      if (mounted) setState(() => _cargando = false);
    }
  }

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
                    'denunciante': widget.usuarioActual?['correo'] ?? 'Usuario Comunidad UAQ',
                  }),
                );

                if (!dialogCtx.mounted) return;
                Navigator.pop(dialogCtx);

                if (res.statusCode == 200 && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      content: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.redAccent.withOpacity(0.6), width: 1.5),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.shield_rounded, color: Colors.redAccent),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Denuncia enviada. El equipo de seguridad revisará este perfil.',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(36),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 35, sigmaY: 35),
                  child: Container(
                    width: 450,
                    padding: const EdgeInsets.all(34),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.22),
                          Colors.white.withOpacity(0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(36),
                      border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.5),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: const Color(0xFFFF6B6B).withOpacity(0.25), shape: BoxShape.circle),
                              child: const Icon(Icons.gpp_bad_rounded, color: Color(0xFFFF6B6B), size: 28),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Text(
                                'Reportar Perfil',
                                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(dialogCtx),
                              icon: const Icon(Icons.close, color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const Text('Selecciona el motivo:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white.withOpacity(0.35)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: motivoSeleccionado,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF2A1B54),
                              style: const TextStyle(color: Colors.white, fontSize: 15),
                              items: motivos.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                              onChanged: (v) => setModalState(() => motivoSeleccionado = v!),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white.withOpacity(0.35)),
                          ),
                          child: TextField(
                            controller: detallesController,
                            maxLines: 3,
                            showCursor: true,
                            cursorColor: TruequiColors.amarillo,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Describe brevemente el comportamiento o artículo ilícito...',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: enviando ? null : enviarDenuncia,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF5E62),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            ),
                            icon: const Icon(Icons.flag_rounded),
                            label: enviando
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Enviar Reporte', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
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
    final String nombre = (_usuario?['nombre']?.toString().trim().isNotEmpty == true)
        ? _usuario!['nombre'].toString()
        : widget.correoUsuario.split('@').first;
    final String? foto = (_usuario?['fotoUrl'] ?? _usuario?['foto'])?.toString();
    final String promedio = (_usuario?['promedio'] ?? '5.0').toString();
    final String totalCalif = (_usuario?['totalCalificaciones'] ?? _resenas.length).toString();
    final String truequesRealizados = (_usuario?['truequesCompletados'] ?? '0').toString();

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: SizedBox(
        width: 780,
        height: 640,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ORBES DE LUZ FLOTANTES PARA DAR EL EFECTO LIQUID GLASS AUTÉNTICO
            AnimatedBuilder(
              animation: _orbController,
              builder: (context, _) {
                return Stack(
                  children: [
                    Positioned(
                      top: 20 + (math.sin(_orbController.value * math.pi) * 35),
                      left: 40 + (math.cos(_orbController.value * math.pi) * 35),
                      child: Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [TruequiColors.purpura.withOpacity(0.85), Colors.transparent]),
                          boxShadow: [BoxShadow(color: TruequiColors.purpura.withOpacity(0.6), blurRadius: 90, spreadRadius: 20)],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20 + (math.cos(_orbController.value * math.pi) * 35),
                      right: 40 + (math.sin(_orbController.value * math.pi) * 35),
                      child: Container(
                        width: 260,
                        height: 260,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [TruequiColors.amarillo.withOpacity(0.75), Colors.transparent]),
                          boxShadow: [BoxShadow(color: TruequiColors.amarillo.withOpacity(0.45), blurRadius: 90, spreadRadius: 15)],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            // CONTENEDOR DE CRISTAL ESMERILADO TRANSLÚCIDO
            ClipRRect(
              borderRadius: BorderRadius.circular(42),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 35, sigmaY: 35),
                child: Container(
                  width: 760,
                  height: 620,
                  padding: const EdgeInsets.all(36),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.22),
                        Colors.white.withOpacity(0.09),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(42),
                    border: Border.all(color: Colors.white.withOpacity(0.38), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 40, offset: const Offset(0, 20)),
                    ],
                  ),
                  child: _cargando
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // CABECERA CON AVATAR, NOMBRE VERIFICADO Y BOTÓN REPORTAR
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(colors: [TruequiColors.amarillo, TruequiColors.purpura]),
                                    boxShadow: [BoxShadow(color: TruequiColors.purpura.withOpacity(0.4), blurRadius: 20)],
                                  ),
                                  child: CircleAvatar(
                                    radius: 38,
                                    backgroundColor: Colors.white.withOpacity(0.2),
                                    backgroundImage: (foto != null && foto.isNotEmpty) ? NetworkImage(foto) : null,
                                    child: (foto == null || foto.isEmpty)
                                        ? Text(nombre[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900))
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              nombre,
                                              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF00E676).withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: const Color(0xFF00E676).withOpacity(0.5)),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.verified_rounded, color: Color(0xFF69F0AE), size: 15),
                                                SizedBox(width: 4),
                                                Text('ZMQ', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(widget.correoUsuario, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _mostrarModalDenuncia,
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF6B6B).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.5), width: 1.5),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.flag_rounded, color: Color(0xFFFF8A80), size: 18),
                                          SizedBox(width: 6),
                                          Text('Denunciar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // TARJETAS GLASS DE MÉTRICAS
                            Row(
                              children: [
                                Expanded(child: _buildChipMetrica(Icons.star_rounded, '$promedio ★ ($totalCalif)', 'Reputación', TruequiColors.amarillo)),
                                const SizedBox(width: 14),
                                Expanded(child: _buildChipMetrica(Icons.handshake_rounded, truequesRealizados, 'Trueques Hechos', const Color(0xFF69F0AE))),
                                const SizedBox(width: 14),
                                Expanded(child: _buildChipMetrica(Icons.inventory_2_rounded, '${_productos.length}', 'En Catálogo', const Color(0xFFD1C4E9))),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // SELECTOR DE PESTAÑAS LIQUID GLASS
                            Row(
                              children: [
                                _buildTabSelector(0, Icons.forum_rounded, 'Comentarios Públicos (${_resenas.length})'),
                                const SizedBox(width: 12),
                                _buildTabSelector(1, Icons.grid_view_rounded, 'Artículos Activos (${_productos.length})'),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // CONTENIDO DE LA PESTAÑA
                            Expanded(
                              child: _tabActiva == 0 ? _buildListaResenas() : _buildGridArticulos(),
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
  }

  Widget _buildChipMetrica(IconData icon, String valor, String etiqueta, Color colorIcono) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.32), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colorIcono.withOpacity(0.22), shape: BoxShape.circle),
            child: Icon(icon, color: colorIcono, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(valor, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                Text(etiqueta, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector(int index, IconData icon, String texto) {
    final bool activo = _tabActiva == index;
    return GestureDetector(
      onTap: () => setState(() => _tabActiva = index),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: activo
                ? const LinearGradient(colors: [TruequiColors.purpura, Color(0xFF8E54E9)])
                : null,
            color: activo ? null : Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(activo ? 0.5 : 0.25), width: 1.2),
            boxShadow: activo ? [BoxShadow(color: TruequiColors.purpura.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))] : [],
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text(texto, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
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
            Icon(Icons.rate_review_outlined, size: 54, color: Colors.white.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text(
              'Aún no hay comentarios públicos para este perfil.',
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _resenas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final r = _resenas[idx];
        final autor = (r['autorNombre'] ?? 'Usuario Truequi').toString();
        final estrellas = double.tryParse((r['estrellas'] ?? '5.0').toString()) ?? 5.0;
        final comentario = (r['comentario'] ?? '').toString();
        final fechaRaw = (r['fecha'] ?? '').toString();
        final fechaCorta = fechaRaw.length >= 10 ? fechaRaw.substring(0, 10) : '';

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.14),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: TruequiColors.purpura,
                        child: Text(autor[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 10),
                      Text(autor, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
                      const SizedBox(width: 10),
                      Text(fechaCorta, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                    ],
                  ),
                  Row(
                    children: List.generate(5, (i) {
                      return Icon(
                        i < estrellas.round() ? Icons.star_rounded : Icons.star_border_rounded,
                        color: TruequiColors.amarillo,
                        size: 19,
                      );
                    }),
                  ),
                ],
              ),
              if (comentario.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  comentario,
                  style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4, fontWeight: FontWeight.w500),
                ),
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
        child: Text(
          'No tiene artículos publicados en este momento.',
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.w600),
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.9,
      ),
      itemCount: _productos.length,
      itemBuilder: (context, i) {
        final p = _productos[i];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.32)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                  child: Image.network(
                    p['imagenUrl'] ?? 'https://via.placeholder.com/300',
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p['titulo']?.toString() ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${p['precio'] ?? '0'} MXN',
                      style: const TextStyle(color: TruequiColors.amarillo, fontWeight: FontWeight.w900, fontSize: 13),
                    ),
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