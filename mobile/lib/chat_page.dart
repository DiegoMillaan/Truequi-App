import 'dart:ui';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'home_page.dart';

class ChatPage extends StatefulWidget {
  final String miCorreo;
  final String otroCorreo;
  final String productoId;
  final String productoTitulo;
  final String conversacionId;
  
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
  
  final ScrollController _scrollController = ScrollController();
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _estadoActual = widget.estadoPropuesta;
    _cargarMensajes(silencioso: false);
    
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      _cargarMensajes(silencioso: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _scrollController.dispose();
    _mensajeController.dispose();
    super.dispose();
  }

  // 🛡️ CORRECCIÓN AQUÍ: Buscamos por usuario y filtramos por conversación
  Future<void> _cargarMensajes({bool silencioso = false}) async {
    if (!silencioso && mounted) setState(() => _cargando = true);
    
    try {
      final url = Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/mensajes?usuario=${widget.miCorreo}');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final todosLosMensajes = jsonDecode(response.body)['mensajes'] as List<dynamic>;
        
        // Filtramos localmente para quedarnos solo con esta conversación
        final nuevosMensajes = todosLosMensajes
            .where((m) => m['conversacionId'] == widget.conversacionId)
            .toList();
            
        nuevosMensajes.sort((a, b) => a['fecha'].compareTo(b['fecha']));
        
        if (mounted) {
          bool hayNuevos = nuevosMensajes.length > _mensajes.length;
          
          setState(() {
            _mensajes = nuevosMensajes;
            _cargando = false;
            
            // Sincronizar el estado en tiempo real si el otro usuario lo cambió
            if (_mensajes.isNotEmpty) {
              final estadoRemoto = _mensajes.first['estado'] ?? _estadoActual;
              if (_estadoActual != estadoRemoto) {
                _estadoActual = estadoRemoto;
              }
            }
          });

          if (hayNuevos && _scrollController.hasClients) {
            Future.delayed(const Duration(milliseconds: 100), () {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            });
          }
        }
      }
    } catch (e) {
      debugPrint(e.toString());
      if (!silencioso && mounted) setState(() => _cargando = false);
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
        await _cargarMensajes(silencioso: true); 
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<bool> _actualizarEstado(String nuevoEstado, {String? pin}) async {
    final idMensaje = widget.idPrimerMensaje ?? (_mensajes.isNotEmpty ? _mensajes.first['id'] : null);
    if (idMensaje == null) return false;

    try {
      final url = Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/mensajes/$idMensaje');
      final body = {'estado': nuevoEstado};
      if (pin != null) body['pin'] = pin;

      final response = await http.put(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
      
      if (response.statusCode == 200) {
        setState(() => _estadoActual = nuevoEstado);
        if (mounted && nuevoEstado != 'Completado') {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Trueque $nuevoEstado'), backgroundColor: nuevoEstado == 'Aceptado' ? Colors.green : Colors.orange));
        }
        return true;
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Error desconocido';
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent));
        return false;
      }
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }

  void _mostrarModalValidacionPin(String destinatarioCorreo, String mensajeId) {
    final pinController = TextEditingController();
    bool validando = false;

    showDialog(
      context: context, 
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (contextModal, setModalState) {
            Future<void> validarPIN() async {
              if (pinController.text.trim().length != 4) return;
              setModalState(() => validando = true);
              
              bool exito = await _actualizarEstado('Completado', pin: pinController.text.trim());
              
              if (exito) {
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                _mostrarModalCalificacion(destinatarioCorreo);
              } else {
                setModalState(() => validando = false);
              }
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    width: double.infinity, 
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(40), border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: TruequiColors.purpura.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(Icons.lock_outline_rounded, size: 50, color: TruequiColors.purpura)),
                        const SizedBox(height: 20),
                        const Text('Validación mediante PIN', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        const SizedBox(height: 10),
                        Text('Pídele el código de 4 dígitos a la otra persona al momento de intercambiar el artículo.', style: TextStyle(color: Colors.white.withOpacity(0.7)), textAlign: TextAlign.center),
                        const SizedBox(height: 30),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: TruequiColors.purpura.withOpacity(0.5), width: 2)),
                          child: TextField(
                            controller: pinController, maxLength: 4, textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 15),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(counterText: "", border: InputBorder.none, hintText: "0000", hintStyle: TextStyle(color: Colors.white24)),
                          ),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: validando ? null : validarPIN, style: ElevatedButton.styleFrom(backgroundColor: TruequiColors.purpura, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: validando ? const CircularProgressIndicator(color: Colors.white) : const Text('Verificar Trueque', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)))),
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

  void _mostrarModalCalificacion(String destinatarioCorreo) {
    double estrellas = 5.0;
    bool procesando = false;

    showDialog(
      context: context, barrierColor: Colors.black.withOpacity(0.7),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (contextModal, setModalState) {
            Future<void> enviarCalificacion() async {
              setModalState(() => procesando = true);
              try {
                await http.put(Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/usuario/calificar'),
                    headers: {'Content-Type': 'application/json'}, body: jsonEncode({'correo': destinatarioCorreo, 'estrellas': estrellas}));
                
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Trueque completado y calificado! 🎉', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: Colors.green));
              } catch (e) { 
                setModalState(() => procesando = false); 
              }
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    width: double.infinity, padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(40), border: Border.all(color: TruequiColors.amarillo.withOpacity(0.5), width: 1.5)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.handshake_rounded, size: 60, color: TruequiColors.amarillo),
                        const SizedBox(height: 20),
                        const Text('¡Trato Cerrado!', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Text('Califica la experiencia con $destinatarioCorreo', style: TextStyle(color: Colors.white.withOpacity(0.7)), textAlign: TextAlign.center),
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) => IconButton(icon: Icon(index < estrellas ? Icons.star_rounded : Icons.star_border_rounded, color: TruequiColors.amarillo, size: 40), onPressed: () => setModalState(() => estrellas = index + 1.0))),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: procesando ? null : enviarCalificacion, style: ElevatedButton.styleFrom(backgroundColor: TruequiColors.amarillo, foregroundColor: TruequiColors.textoOscuro, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: procesando ? const CircularProgressIndicator(color: TruequiColors.textoOscuro) : const Text('Guardar Reputación', style: TextStyle(fontWeight: FontWeight.bold)))),
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
    String pinValidacion = '0000';
    String idPrimerMensaje = widget.idPrimerMensaje ?? '';
    if (_mensajes.isNotEmpty) {
      pinValidacion = _mensajes.first['pinValidacion']?.toString() ?? '0000';
      if (idPrimerMensaje.isEmpty) {
        idPrimerMensaje = _mensajes.first['id']?.toString() ?? '';
      }
    }

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
          Positioned(top: 100, left: -50, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: TruequiColors.purpura.withOpacity(0.2)), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: const SizedBox()))),
          Positioned(bottom: 50, right: -50, child: Container(width: 350, height: 350, decoration: BoxDecoration(shape: BoxShape.circle, color: TruequiColors.amarillo.withOpacity(0.15)), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: const SizedBox()))),
          
          Column(
            children: [
              const SizedBox(height: 100), 
              
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
              else if (_estadoActual == 'Aceptado')
                if (widget.esMiArticulo)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _mostrarModalValidacionPin(widget.otroCorreo, idPrimerMensaje),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TruequiColors.purpura.withOpacity(0.5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.lock_open_rounded, color: TruequiColors.amarillo),
                      label: const Text('Ingresar PIN para Completar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  )
                else
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    decoration: BoxDecoration(
                      color: TruequiColors.amarillo.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: TruequiColors.amarillo.withOpacity(0.5), width: 2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.key_rounded, color: TruequiColors.amarillo, size: 30),
                        const SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('TU PIN DE ENTREGA', style: TextStyle(color: TruequiColors.amarillo, fontSize: 10, fontWeight: FontWeight.bold)),
                            Text(pinValidacion, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 8)),
                          ],
                        )
                      ],
                    ),
                  )
              else if (_estadoActual != 'Pendiente')
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _estadoActual == 'Completado' ? TruequiColors.purpura.withOpacity(0.2) : Colors.redAccent.withOpacity(0.2), 
                    borderRadius: BorderRadius.circular(20), 
                    border: Border.all(color: _estadoActual == 'Completado' ? TruequiColors.purpura.withOpacity(0.5) : Colors.redAccent.withOpacity(0.5))
                  ),
                  child: Text('Trueque $_estadoActual', style: TextStyle(fontWeight: FontWeight.bold, color: _estadoActual == 'Completado' ? TruequiColors.purpura : Colors.redAccent)),
                ),

              Expanded(
                child: _cargando
                    ? const Center(child: CircularProgressIndicator(color: TruequiColors.purpura))
                    : ListView.builder(
                        controller: _scrollController, 
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