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
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'estado': nuevoEstado}),
      );

      if (response.statusCode == 200) {
        _cargarMensajes(); // Recarga la bandeja
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Propuesta marcada como $nuevoEstado'), backgroundColor: nuevoEstado == 'Aceptado' ? Colors.green : Colors.orange));
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
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
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(20),
                                  leading: CircleAvatar(backgroundColor: esMio ? TruequiColors.amarillo : TruequiColors.purpura, child: Icon(esMio ? Icons.call_made : Icons.call_received, color: Colors.white)),
                                  title: Text(msj['productoTitulo'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 8),
                                      Text(msj['contenido'], style: const TextStyle(fontSize: 15)),
                                      const SizedBox(height: 8),
                                      Text(esMio ? 'Enviado a: ${msj['destinatario']}' : 'Recibido de: ${msj['remitente']}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                    ],
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(estado, style: TextStyle(fontWeight: FontWeight.bold, color: estado == 'Aceptado' ? Colors.green : (estado == 'Rechazado' ? Colors.red : TruequiColors.amarillo))),
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