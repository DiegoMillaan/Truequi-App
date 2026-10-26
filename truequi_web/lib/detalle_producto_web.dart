import 'dart:ui';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'home_web.dart';
import 'perfil_publico_dialog.dart';

class DetalleProductoWeb extends StatefulWidget {
  final Map<String, dynamic> producto;
  final Map<String, dynamic>? usuarioActual;

  const DetalleProductoWeb({
    super.key,
    required this.producto,
    this.usuarioActual,
  });

  @override
  State<DetalleProductoWeb> createState() => _DetalleProductoWebState();
}

class _DetalleProductoWebState extends State<DetalleProductoWeb> {
  int _fotoSeleccionadaIndex = 0;

  List<String> get _galeriaImagenes {
    final rawList = widget.producto['imagenesUrls'];
    if (rawList is List && rawList.isNotEmpty) {
      return rawList
          .map((e) => e?.toString() ?? '')
          .where((url) => url.trim().isNotEmpty)
          .take(5)
          .toList();
    }
    final singleUrl = widget.producto['imagenUrl']?.toString();
    if (singleUrl != null && singleUrl.trim().isNotEmpty) {
      return [singleUrl];
    }
    return [];
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
                boxShadow: [
                  BoxShadow(
                    color: colorBase.withOpacity(0.25),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorBase.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icono, color: colorBase, size: 28),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Text(
                      mensaje,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
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

  void _mostrarModalPropuesta(BuildContext context) {
    if (widget.usuarioActual == null) {
      _mostrarAlertaLiquid(context, 'Inicia sesión para proponer un trueque.', tipo: 'info');
      return;
    }

    final mensajeController = TextEditingController();
    bool enviando = false;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (contextModal, setModalState) {
            Future<void> enviarPropuesta() async {
              final texto = mensajeController.text.trim();
              if (texto.length < 5) {
                _mostrarAlertaLiquid(context, 'Escribe una propuesta más detallada.', tipo: 'info');
                return;
              }

              setModalState(() => enviando = true);

              try {
                final url = Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/mensajes');
                final destinatario = widget.producto['vendedorId']?.toString() ?? 'admin@gmail.com';

                final response = await http.post(
                  url,
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'remitente': widget.usuarioActual!['correo'],
                    'destinatario': destinatario,
                    'productoId': widget.producto['id']?.toString() ?? '',
                    'productoTitulo': widget.producto['titulo']?.toString() ?? 'Artículo',
                    'contenido': texto,
                  }),
                );

                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);

                if (response.statusCode == 201 || response.statusCode == 200) {
                  _mostrarAlertaLiquid(context, '¡Propuesta enviada al vendedor! 🤝', tipo: 'exito');
                } else {
                  _mostrarAlertaLiquid(context, 'Error al enviar la propuesta', tipo: 'error');
                }
              } catch (e) {
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                _mostrarAlertaLiquid(context, 'Error de red: $e', tipo: 'error');
              }
            }

            return TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutExpo,
              builder: (contextAnim, double val, child) {
                return Transform.scale(
                  scale: val,
                  child: Dialog(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                        child: Container(
                          width: 500,
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Proponer Trueque',
                                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Artículo: ${widget.producto['titulo']}',
                                style: const TextStyle(fontSize: 16, color: TruequiColors.amarillo, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 25),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                                ),
                                child: TextField(
                                  controller: mensajeController,
                                  maxLines: 4,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'Hola, me interesa tu artículo. Te ofrezco a cambio...',
                                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(20),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 30),
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: enviando ? null : enviarPropuesta,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: TruequiColors.purpura,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                  child: enviando
                                      ? const CircularProgressIndicator(color: Colors.white)
                                      : const Text(
                                          'Enviar Propuesta',
                                          style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final titulo = widget.producto['titulo'] ?? 'Sin título';
    final descripcion = widget.producto['descripcion'] ?? 'Sin descripción';
    final precio = widget.producto['precio']?.toString() ?? '0.0';
    final categoria = widget.producto['categoria'] ?? 'General';
    final municipio = widget.producto['municipio']?.toString() ?? 'Santiago de Querétaro';
    final vendedor = widget.producto['vendedorNombre'] ?? widget.producto['vendedorId'] ?? 'Comunidad UAQ';

    final galeria = _galeriaImagenes;
    final int idxSeguro = galeria.isEmpty
        ? 0
        : _fotoSeleccionadaIndex.clamp(0, galeria.length - 1);

    final bool esMiProducto = widget.usuarioActual != null &&
        widget.usuarioActual!['correo'] == widget.producto['vendedorId'];

    return Scaffold(
      backgroundColor: const Color(0xFF0D0A15),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: TruequiColors.purpura.withOpacity(0.3),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: const SizedBox(),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: TruequiColors.amarillo.withOpacity(0.2),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: const SizedBox(),
              ),
            ),
          ),

          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1050, maxHeight: 640),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        // ==========================================
                        // PUNTO 13: GALERÍA DE HASTA 5 IMÁGENES
                        // ==========================================
                        Expanded(
                          flex: 5,
                          child: Container(
                            color: Colors.white.withOpacity(0.05),
                            child: galeria.isEmpty
                                ? const Center(
                                    child: Icon(Icons.inventory_2_rounded, size: 100, color: Colors.white54),
                                  )
                                : Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.network(
                                        galeria[idxSeguro],
                                        fit: BoxFit.cover,
                                      ),
                                      // Flechas de navegación si hay más de 1 imagen
                                      if (galeria.length > 1) ...[
                                        Positioned(
                                          left: 14,
                                          top: 0,
                                          bottom: 0,
                                          child: Center(
                                            child: IconButton(
                                              style: IconButton.styleFrom(
                                                backgroundColor: Colors.black.withOpacity(0.5),
                                                foregroundColor: Colors.white,
                                              ),
                                              icon: const Icon(Icons.chevron_left_rounded, size: 28),
                                              onPressed: () {
                                                setState(() {
                                                  _fotoSeleccionadaIndex =
                                                      (idxSeguro - 1 + galeria.length) % galeria.length;
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          right: 14,
                                          top: 0,
                                          bottom: 0,
                                          child: Center(
                                            child: IconButton(
                                              style: IconButton.styleFrom(
                                                backgroundColor: Colors.black.withOpacity(0.5),
                                                foregroundColor: Colors.white,
                                              ),
                                              icon: const Icon(Icons.chevron_right_rounded, size: 28),
                                              onPressed: () {
                                                setState(() {
                                                  _fotoSeleccionadaIndex = (idxSeguro + 1) % galeria.length;
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                        // Miniaturas inferiores
                                        Positioned(
                                          bottom: 18,
                                          left: 16,
                                          right: 16,
                                          child: Center(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.55),
                                                borderRadius: BorderRadius.circular(18),
                                              ),
                                              child: SingleChildScrollView(
                                                scrollDirection: Axis.horizontal,
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: List.generate(galeria.length, (idx) {
                                                    final bool activa = idx == idxSeguro;
                                                    return Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 5),
                                                      child: GestureDetector(
                                                        onTap: () => setState(() => _fotoSeleccionadaIndex = idx),
                                                        child: AnimatedContainer(
                                                          duration: const Duration(milliseconds: 200),
                                                          width: 54,
                                                          height: 54,
                                                          decoration: BoxDecoration(
                                                            borderRadius: BorderRadius.circular(12),
                                                            border: Border.all(
                                                              color: activa ? TruequiColors.amarillo : Colors.white38,
                                                              width: activa ? 2.5 : 1,
                                                            ),
                                                          ),
                                                          child: ClipRRect(
                                                            borderRadius: BorderRadius.circular(9),
                                                            child: Image.network(galeria[idx], fit: BoxFit.cover),
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  }),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                          ),
                        ),

                        // ==========================================
                        // INFORMACIÓN DEL ARTÍCULO
                        // ==========================================
                        Expanded(
                          flex: 6,
                          child: Padding(
                            padding: const EdgeInsets.all(45.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Wrap(
                                        spacing: 10,
                                        runSpacing: 8,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                            decoration: BoxDecoration(
                                              color: TruequiColors.amarillo.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(color: TruequiColors.amarillo.withOpacity(0.5)),
                                            ),
                                            child: Text(
                                              categoria,
                                              style: const TextStyle(color: TruequiColors.amarillo, fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.location_on_rounded, color: Colors.greenAccent, size: 15),
                                                const SizedBox(width: 4),
                                                Text(
                                                  municipio,
                                                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                        onTap: () {
                                          if (widget.producto['vendedorId'] != null) {
                                            PerfilPublicoDialog.mostrar(context, widget.producto['vendedorId']);
                                          }
                                        },
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor: TruequiColors.purpura.withOpacity(0.5),
                                              child: const Icon(Icons.person, size: 18, color: Colors.white),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              'Vendedor: $vendedor',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  titulo,
                                  style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 15),
                                Text(
                                  'Valor est: \$ $precio MXN',
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: TruequiColors.purpura),
                                ),
                                const SizedBox(height: 25),
                                const Text(
                                  'Descripción y qué busca a cambio',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70),
                                ),
                                const SizedBox(height: 10),
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Text(
                                      descripcion,
                                      style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.85), height: 1.6),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  height: 60,
                                  child: ElevatedButton(
                                    onPressed: esMiProducto ? null : () => _mostrarModalPropuesta(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: esMiProducto ? Colors.white.withOpacity(0.1) : TruequiColors.purpura,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    ),
                                    child: Text(
                                      esMiProducto ? 'Este es tu artículo' : 'Proponer Trueque',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: esMiProducto ? Colors.white54 : Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
}