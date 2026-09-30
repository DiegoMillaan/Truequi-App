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
      barrierColor: Colors.black.withOpacity(0.6),
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
                    'destinatario': otroUsuario,
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

            return Dialog(
              backgroundColor: Colors.transparent, elevation: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    width: 500, padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white, width: 2)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Chat: ${msj['productoTitulo']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: TruequiColors.textoOscuro)),
                            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(dialogContext))
                          ],
                        ),
                        Text('Con: $otroUsuario', style: const TextStyle(color: TruequiColors.purpura, fontWeight: FontWeight.bold)),
                        const Divider(height: 30),
                        
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
                          child: Text('"${msj['contenido']}"', style: const TextStyle(fontStyle: FontStyle.italic)),
                        ),
                        const SizedBox(height: 20),
                        
                        TextField(
                          controller: respuestaController, maxLines: 2,
                          decoration: InputDecoration(
                            hintText: 'Escribe tu respuesta...', filled: true, fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(onPressed: enviando ? null : responder, style: ElevatedButton.styleFrom(backgroundColor: TruequiColors.purpura, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), icon: enviando ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send_rounded), label: const Text('Responder'))),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.5), elevation: 0,
        iconTheme: const IconThemeData(color: TruequiColors.purpura),
        title: const Text('Bandeja de Entrada', style: TextStyle(color: TruequiColors.textoOscuro, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFE5DFFF), Color(0xFFFFF3E0)], begin: Alignment.topLeft, end: Alignment.bottomRight))),
          BackdropFilter(filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60), child: Container(color: Colors.transparent)),
          
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                child: Container(
                  width: 900, height: 700, padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(40), border: Border.all(color: Colors.white.withOpacity(0.9), width: 2)),
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator(color: TruequiColors.purpura))
                    : _mensajes.isEmpty
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.mark_chat_unread_rounded, size: 100, color: TruequiColors.amarillo.withOpacity(0.8)),
                              const SizedBox(height: 20),
                              const Text('Bandeja vacía', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: TruequiColors.textoOscuro)),
                            ],
                          )
                        : ListView.builder(
                            itemCount: _mensajes.length,
                            itemBuilder: (context, index) {
                              final msj = _mensajes[index];
                              final esMio = msj['remitente'] == widget.usuarioActual['correo'];
                              final estado = msj['estado'] ?? 'Pendiente';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () => _abrirSalaDeChat(msj), // ABRE EL MODAL DE CHAT
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Row(
                                      children: [
                                        CircleAvatar(backgroundColor: esMio ? TruequiColors.amarillo : TruequiColors.purpura, child: Icon(esMio ? Icons.call_made : Icons.call_received, color: Colors.white)),
                                        const SizedBox(width: 20),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(msj['productoTitulo'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: TruequiColors.textoOscuro)),
                                              const SizedBox(height: 8),
                                              Text(msj['contenido'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15)),
                                              const SizedBox(height: 8),
                                              Text(esMio ? 'Enviado a: ${msj['destinatario']}' : 'Recibido de: ${msj['remitente']}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: estado == 'Aceptado' ? Colors.green.withOpacity(0.1) : (estado == 'Rechazado' ? Colors.red.withOpacity(0.1) : TruequiColors.amarillo.withOpacity(0.1)), borderRadius: BorderRadius.circular(12)), child: Text(estado, style: TextStyle(fontWeight: FontWeight.bold, color: estado == 'Aceptado' ? Colors.green : (estado == 'Rechazado' ? Colors.red : TruequiColors.amarillo)))),
                                            if (!esMio && estado == 'Pendiente') ...[
                                              const SizedBox(height: 10),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () => _actualizarEstado(msj['id'], 'Aceptado')),
                                                  IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => _actualizarEstado(msj['id'], 'Rechazado')),
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