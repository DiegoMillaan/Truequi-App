import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'home_web.dart';

class DetalleProductoWeb extends StatelessWidget {
  final Map<String, dynamic> producto;
  final Map<String, dynamic>? usuarioActual; 

  const DetalleProductoWeb({super.key, required this.producto, this.usuarioActual});

  void _mostrarModalPropuesta(BuildContext context) {
    if (usuarioActual == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inicia sesión para proponer un trueque.'), backgroundColor: TruequiColors.amarillo));
      return;
    }

    final mensajeController = TextEditingController();
    bool enviando = false;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> enviarPropuesta() async {
              final texto = mensajeController.text.trim();
              if (texto.length < 5) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escribe una propuesta más detallada.')));
                return;
              }

              setModalState(() => enviando = true);

              try {
                final url = Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/mensajes');
                final destinatario = producto['vendedorId']?.toString() ?? 'admin@gmail.com';

                final response = await http.post(
                  url,
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'remitente': usuarioActual!['correo'],
                    'destinatario': destinatario,
                    'productoId': producto['id']?.toString() ?? '',
                    'productoTitulo': producto['titulo']?.toString() ?? 'Artículo',
                    'contenido': texto,
                  }),
                );

                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);

                if (response.statusCode == 201 || response.statusCode == 200) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Propuesta enviada al vendedor! 🤝'), backgroundColor: Colors.green));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al enviar la propuesta'), backgroundColor: Colors.red));
                }
              } catch (e) {
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error de red: $e'), backgroundColor: Colors.red));
              }
            }

            return TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutExpo,
              builder: (context, double val, child) {
                return Transform.scale(
                  scale: val,
                  child: Dialog(
                    backgroundColor: Colors.transparent, elevation: 0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                        child: Container(
                          width: 500, padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(40), border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5)),
                          child: Column(
                            mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Proponer Trueque', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(height: 10),
                              Text('Artículo: ${producto['titulo']}', style: const TextStyle(fontSize: 16, color: TruequiColors.amarillo, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 25),
                              Container(
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.2))),
                                child: TextField(controller: mensajeController, maxLines: 4, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: 'Hola, me interesa tu artículo. Te ofrezco a cambio...', hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)), border: InputBorder.none, contentPadding: const EdgeInsets.all(20))),
                              ),
                              const SizedBox(height: 30),
                              SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: enviando ? null : enviarPropuesta, style: ElevatedButton.styleFrom(backgroundColor: TruequiColors.purpura, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: enviando ? const CircularProgressIndicator(color: Colors.white) : const Text('Enviar Propuesta', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)))),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final titulo = producto['titulo'] ?? 'Sin título';
    final descripcion = producto['descripcion'] ?? 'Sin descripción';
    final precio = producto['precio']?.toString() ?? '0.0';
    final categoria = producto['categoria'] ?? 'General';
    final imagenUrl = producto['imagenUrl'];
    final vendedor = producto['vendedorNombre'] ?? producto['vendedorId'] ?? 'Comunidad UAQ';

    // VALIDACIÓN: ¿Es mi propio artículo?
    final bool esMiProducto = usuarioActual != null && usuarioActual!['correo'] == producto['vendedorId'];

    return Scaffold(
      backgroundColor: const Color(0xFF0D0A15),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: Container(width: 500, height: 500, decoration: BoxDecoration(shape: BoxShape.circle, color: TruequiColors.purpura.withOpacity(0.3)), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100), child: const SizedBox()))),
          Positioned(bottom: -100, left: -100, child: Container(width: 500, height: 500, decoration: BoxDecoration(shape: BoxShape.circle, color: TruequiColors.amarillo.withOpacity(0.2)), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100), child: const SizedBox()))),
          
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 600),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(40), border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5)),
                    child: Row(
                      children: [
                        Expanded(flex: 5, child: Container(decoration: BoxDecoration(image: imagenUrl != null ? DecorationImage(image: NetworkImage(imagenUrl), fit: BoxFit.cover) : null, color: Colors.white.withOpacity(0.05)), child: imagenUrl == null ? const Center(child: Icon(Icons.inventory_2_rounded, size: 100, color: Colors.white54)) : null)),
                        Expanded(
                          flex: 6,
                          child: Padding(
                            padding: const EdgeInsets.all(50.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: TruequiColors.amarillo.withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: TruequiColors.amarillo.withOpacity(0.5))), child: Text(categoria, style: const TextStyle(color: TruequiColors.amarillo, fontWeight: FontWeight.bold))),
                                    Text('Publicado por: $vendedor', style: TextStyle(color: Colors.white.withOpacity(0.6), fontStyle: FontStyle.italic)),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Text(titulo, style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1)),
                                const SizedBox(height: 15),
                                Text('Valor est: \$ $precio MXN', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: TruequiColors.purpura)),
                                const SizedBox(height: 30),
                                const Text('Descripción', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70)),
                                const SizedBox(height: 10),
                                Text(descripcion, style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.8), height: 1.6)),
                                const Spacer(),
                                
                                SizedBox(
                                  width: double.infinity, height: 60, 
                                  child: ElevatedButton(
                                    // BLOQUEO DINÁMICO
                                    onPressed: esMiProducto ? null : () => _mostrarModalPropuesta(context), 
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: esMiProducto ? Colors.white.withOpacity(0.1) : TruequiColors.purpura, 
                                      foregroundColor: Colors.white, 
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                                    ), 
                                    child: Text(
                                      esMiProducto ? 'Este es tu artículo' : 'Proponer Trueque', 
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: esMiProducto ? Colors.white54 : Colors.white)
                                    )
                                  )
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