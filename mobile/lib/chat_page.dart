import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'home_page.dart';

class ChatPage extends StatefulWidget {
  final String miCorreo;
  final String otroCorreo;
  final String productoId;
  final String productoTitulo;
  final String conversacionId;
  
  // Datos adicionales para controlar la lógica de negocio
  final bool esMiArticulo;
  final String estadoPropuesta;
  final String? idPrimerMensaje;

  const ChatPage({
    super.key,
    required this.miCorreo,
    required this.otroCorreo,
    required this.productoId,
    required this.productoTitulo,
    required this.conversacionId,
    this.esMiArticulo = false,
    this.estadoPropuesta = 'Pendiente',
    this.idPrimerMensaje,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<dynamic> _mensajes = [];
  bool _cargando = true;
  bool _enviando = false;
  final TextEditingController _mensajeController = TextEditingController();
  late String _estadoActual;

  @override
  void initState() {
    super.initState();
    _estadoActual = widget.estadoPropuesta;
    _cargarMensajes();
  }

  @override
  void dispose() {
    _mensajeController.dispose();
    super.dispose();
  }

  Future<void> _cargarMensajes() async {
    setState(() => _cargando = true);
    try {
      final url = Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/mensajes?conversacionId=${widget.conversacionId}');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          _mensajes = jsonDecode(response.body)['mensajes'];
          // Orden cronológico para leer de arriba hacia abajo
          _mensajes.sort((a, b) => a['fecha'].compareTo(b['fecha']));
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _enviar() async {
    final texto = _mensajeController.text.trim();
    if (texto.isEmpty) return;
    setState(() => _enviando = true);

    try {
      final response = await http.post(
        Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/mensajes'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'conversacionId': widget.conversacionId,
          'remitente': widget.miCorreo,
          'destinatario': widget.otroCorreo,
          'productoId': widget.productoId,
          'productoTitulo': widget.productoTitulo,
          'contenido': texto,
          'estado': _estadoActual,
        }),
      );

      if (response.statusCode == 201) {
        _mensajeController.clear();
        await _cargarMensajes();
      }
    } finally {
      setState(() => _enviando = false);
    }
  }

  Future<void> _actualizarEstado(String nuevoEstado) async {
    if (widget.idPrimerMensaje == null) return;
    try {
      final url = Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/mensajes/${widget.idPrimerMensaje}');
      final response = await http.put(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'estado': nuevoEstado}));
      if (response.statusCode == 200) {
        setState(() => _estadoActual = nuevoEstado);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Trueque $nuevoEstado'), backgroundColor: nuevoEstado == 'Aceptado' ? Colors.green : Colors.orange));
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TruequiColors.fondoClaro,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.05),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1)))),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.productoTitulo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('Con: ${widget.otroCorreo}', style: TextStyle(color: TruequiColors.amarillo.withOpacity(0.8), fontSize: 12)),
          ],
        ),
      ),
      body: Stack(
        children: [
          // ORBES DE FONDO
          Positioned(top: 100, left: -50, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: TruequiColors.purpura.withOpacity(0.2)), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: const SizedBox()))),
          Positioned(bottom: 50, right: -50, child: Container(width: 350, height: 350, decoration: BoxDecoration(shape: BoxShape.circle, color: TruequiColors.amarillo.withOpacity(0.15)), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: const SizedBox()))),
          
          Column(
            children: [
              const SizedBox(height: 100), // Espacio para el AppBar
              
              // PANEL DE DECISIÓN (Si es tu artículo y está pendiente)
              if (widget.esMiArticulo && _estadoActual == 'Pendiente')
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.2))),
                  child: Column(
                    children: [
                      const Text('Esta es una oferta por tu artículo.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: ElevatedButton.icon(onPressed: () => _actualizarEstado('Rechazado'), style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.2), foregroundColor: Colors.redAccent, elevation: 0), icon: const Icon(Icons.close), label: const Text('Rechazar'))),
                          const SizedBox(width: 10),
                          Expanded(child: ElevatedButton.icon(onPressed: () => _actualizarEstado('Aceptado'), style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent.withOpacity(0.2), foregroundColor: Colors.greenAccent, elevation: 0), icon: const Icon(Icons.check), label: const Text('Aceptar'))),
                        ],
                      ),
                    ],
                  ),
                )
              else if (_estadoActual != 'Pendiente')
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: _estadoActual == 'Aceptado' ? Colors.greenAccent.withOpacity(0.2) : Colors.redAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: _estadoActual == 'Aceptado' ? Colors.greenAccent.withOpacity(0.5) : Colors.redAccent.withOpacity(0.5))),
                  child: Text('Trueque $_estadoActual', style: TextStyle(fontWeight: FontWeight.bold, color: _estadoActual == 'Aceptado' ? Colors.greenAccent : Colors.redAccent)),
                ),

              // ÁREA DE BURBUJAS DE CHAT
              Expanded(
                child: _cargando
                    ? const Center(child: CircularProgressIndicator(color: TruequiColors.purpura))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        physics: const BouncingScrollPhysics(),
                        itemCount: _mensajes.length,
                        itemBuilder: (context, index) {
                          final msj = _mensajes[index];
                          final loEnvieYo = msj['remitente'] == widget.miCorreo;

                          return Align(
                            alignment: loEnvieYo ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: loEnvieYo ? TruequiColors.purpura.withOpacity(0.9) : Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.only(topLeft: const Radius.circular(20), topRight: const Radius.circular(20), bottomLeft: loEnvieYo ? const Radius.circular(20) : const Radius.circular(0), bottomRight: loEnvieYo ? const Radius.circular(0) : const Radius.circular(20)),
                                border: Border.all(color: Colors.white.withOpacity(0.1)),
                              ),
                              child: Text(msj['contenido'], style: const TextStyle(color: Colors.white, fontSize: 15)),
                            ),
                          );
                        },
                      ),
              ),

              // BARRA INFERIOR DE ENVÍO DE MENSAJES (Glass)
              ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 10, top: 10, left: 20, right: 20),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1)))),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.2))),
                            child: TextField(
                              controller: _mensajeController, style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(hintText: 'Escribe tu mensaje...', hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _enviando ? null : _enviar,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: TruequiColors.amarillo, shape: BoxShape.circle, boxShadow: [BoxShadow(color: TruequiColors.amarillo.withOpacity(0.4), blurRadius: 10)]),
                            child: _enviando 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                                : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}