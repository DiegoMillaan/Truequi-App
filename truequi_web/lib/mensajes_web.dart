import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'home_web.dart';

class MensajesWeb extends StatefulWidget {
  final Map<String, dynamic> usuarioActual;

  const MensajesWeb({super.key, required this.usuarioActual});

  @override
  State<MensajesWeb> createState() => _MensajesWebState();
}

class _MensajesWebState extends State<MensajesWeb> {
  List<dynamic> _mensajes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarMensajes();
  }

  Future<void> _cargarMensajes() async {
    setState(() => _isLoading = true);
    try {
      final correo = widget.usuarioActual['correo'];
      final url = Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/mensajes?usuario=$correo');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          _mensajes = jsonDecode(response.body)['mensajes'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _actualizarEstado(String mensajeId, String nuevoEstado) async {
    try {
      final url = Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/mensajes/$mensajeId');
      final response = await http.put(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'estado': nuevoEstado}));
      if (response.statusCode == 200) {
        _cargarMensajes(); 
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Trueque $nuevoEstado'), backgroundColor: nuevoEstado == 'Aceptado' ? Colors.green : Colors.orange));
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void _abrirSalaDeChat(Map<String, dynamic> msj) {
    final conversacionId = msj['conversacionId'];
    final esMio = msj['remitente'] == widget.usuarioActual['correo'];
    final otroUsuario = esMio ? msj['destinatario'] : msj['remitente'];
    final respuestaController = TextEditingController();
    bool enviando = false;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> responder() async {
              if (respuestaController.text.trim().isEmpty) return;
              setModalState(() => enviando = true);
              try {
                final response = await http.post(
                  Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/mensajes'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'conversacionId': conversacionId,
                    'remitente': widget.usuarioActual['correo'],
                    'destinatario': otroUsuario, // Corrección de destinatario
                    'productoId': msj['productoId'],
                    'productoTitulo': msj['productoTitulo'],
                    'contenido': respuestaController.text.trim(),
                    'estado': 'Pendiente'
                  }),
                );
                if (response.statusCode == 201) {
                  respuestaController.clear();
                  Navigator.pop(dialogContext);
                  _cargarMensajes();
                }
              } catch (e) {
                setModalState(() => enviando = false);
              }
            }

            return TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutExpo,
              builder: (context, double val, child) {
                return Transform.scale(
                  scale: val,
                  child: Dialog(
                    backgroundColor: Colors.transparent, elevation: 0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                        child: Container(
                          width: 500, padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(40), border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 40)]),
                          child: Column(
                            mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text('Chat: ${msj['productoTitulo']}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis)),
                                  IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(dialogContext))
                                ],
                              ),
                              Text('Con: $otroUsuario', style: const TextStyle(color: TruequiColors.amarillo, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 20),
                              
                              Container(
                                padding: const EdgeInsets.all(20), width: double.infinity,
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.2))),
                                child: Text('"${msj['contenido']}"', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.white, fontSize: 16)),
                              ),
                              const SizedBox(height: 25),
                              
                              Container(
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.2))),
                                child: TextField(controller: respuestaController, maxLines: 3, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: 'Escribe tu respuesta...', hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)), border: InputBorder.none, contentPadding: const EdgeInsets.all(20))),
                              ),
                              const SizedBox(height: 30),
                              SizedBox(width: double.infinity, height: 55, child: ElevatedButton.icon(onPressed: enviando ? null : responder, style: ElevatedButton.styleFrom(backgroundColor: TruequiColors.purpura, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), icon: enviando ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send_rounded), label: const Text('Responder', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
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
    return Scaffold(
      backgroundColor: const Color(0xFF0D0A15),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Bandeja de Entrada', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          Positioned(top: 100, left: -100, child: Container(width: 400, height: 400, decoration: BoxDecoration(shape: BoxShape.circle, color: TruequiColors.purpura.withOpacity(0.2)), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100), child: const SizedBox()))),
          Positioned(bottom: -50, right: -50, child: Container(width: 500, height: 500, decoration: BoxDecoration(shape: BoxShape.circle, color: TruequiColors.amarillo.withOpacity(0.15)), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100), child: const SizedBox()))),
          
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  width: 900, height: 700, padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(40), border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5)),
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator(color: TruequiColors.amarillo))
                    : _mensajes.isEmpty
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.mark_chat_unread_rounded, size: 100, color: Colors.white.withOpacity(0.5)),
                              const SizedBox(height: 20),
                              const Text('Bandeja vacía', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          )
                        : ListView.builder(
                            itemCount: _mensajes.length,
                            itemBuilder: (context, index) {
                              final msj = _mensajes[index];
                              final esMio = msj['remitente'] == widget.usuarioActual['correo'];
                              final estado = msj['estado'] ?? 'Pendiente';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 15),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.2))),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(24),
                                  onTap: () => _abrirSalaDeChat(msj), 
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Row(
                                      children: [
                                        CircleAvatar(backgroundColor: esMio ? TruequiColors.amarillo.withOpacity(0.8) : TruequiColors.purpura.withOpacity(0.8), child: Icon(esMio ? Icons.call_made : Icons.call_received, color: Colors.white)),
                                        const SizedBox(width: 20),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(msj['productoTitulo'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                                              const SizedBox(height: 8),
                                              Text(msj['contenido'], maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.8))),
                                              const SizedBox(height: 8),
                                              Text(esMio ? 'Enviado a: ${msj['destinatario']}' : 'Recibido de: ${msj['remitente']}', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: estado == 'Aceptado' ? Colors.green.withOpacity(0.2) : (estado == 'Rechazado' ? Colors.red.withOpacity(0.2) : TruequiColors.amarillo.withOpacity(0.2)), borderRadius: BorderRadius.circular(12), border: Border.all(color: estado == 'Aceptado' ? Colors.green.withOpacity(0.5) : (estado == 'Rechazado' ? Colors.red.withOpacity(0.5) : TruequiColors.amarillo.withOpacity(0.5)))), child: Text(estado, style: TextStyle(fontWeight: FontWeight.bold, color: estado == 'Aceptado' ? Colors.greenAccent : (estado == 'Rechazado' ? Colors.redAccent : TruequiColors.amarillo)))),
                                            if (!esMio && estado == 'Pendiente') ...[
                                              const SizedBox(height: 10),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(icon: const Icon(Icons.check_circle, color: Colors.greenAccent, size: 28), onPressed: () => _actualizarEstado(msj['id'], 'Aceptado')),
                                                  IconButton(icon: const Icon(Icons.cancel, color: Colors.redAccent, size: 28), onPressed: () => _actualizarEstado(msj['id'], 'Rechazado')),
                                                ],
                                              )
                                            ]
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
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