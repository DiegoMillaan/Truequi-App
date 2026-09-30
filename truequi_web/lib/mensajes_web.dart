import 'dart:ui';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'home_web.dart';

class MensajesWeb extends StatefulWidget {
  final Map<String, dynamic> usuarioActual;

  const MensajesWeb({super.key, required this.usuarioActual});

  @override
  State<MensajesWeb> createState() => _MensajesWebState();
}

class _MensajesWebState extends State<MensajesWeb> with SingleTickerProviderStateMixin {
  List<dynamic> _mensajesBrutos = [];
  bool _isLoading = true;
  String? _conversacionActivaId;
  final TextEditingController _respuestaController = TextEditingController();
  bool _enviando = false;
  
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 25))..repeat();
    _cargarMensajes();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _respuestaController.dispose();
    super.dispose();
  }

  Future<void> _cargarMensajes() async {
    setState(() => _isLoading = true);
    try {
      final correo = widget.usuarioActual['correo'];
      final url = Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/mensajes?usuario=$correo');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          _mensajesBrutos = jsonDecode(response.body)['mensajes'];
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

  Future<void> _enviarMensaje(List<dynamic> hiloActivo) async {
    if (_respuestaController.text.trim().isEmpty) return;
    setState(() => _enviando = true);
    
    final primerMsj = hiloActivo.first;
    final miCorreo = widget.usuarioActual['correo'];
    final destinatario = primerMsj['remitente'] == miCorreo ? primerMsj['destinatario'] : primerMsj['remitente'];

    try {
      final response = await http.post(
        Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/mensajes'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'conversacionId': primerMsj['conversacionId'],
          'remitente': miCorreo,
          'destinatario': destinatario,
          'productoId': primerMsj['productoId'],
          'productoTitulo': primerMsj['productoTitulo'],
          'contenido': _respuestaController.text.trim(),
          'estado': primerMsj['estado'] // Heredamos el estado original
        }),
      );
      if (response.statusCode == 201) {
        _respuestaController.clear();
        await _cargarMensajes();
      }
    } finally {
      setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final miCorreo = widget.usuarioActual['correo'];

    // LÓGICA DE AGRUPACIÓN POR HILOS (CHATS)
    Map<String, List<dynamic>> mapaHilos = {};
    for (var m in _mensajesBrutos) {
      final cid = m['conversacionId'] ?? 'desconocido';
      mapaHilos.putIfAbsent(cid, () => []).add(m);
    }

    List<List<dynamic>> hilosRecibidos = [];
    List<List<dynamic>> hilosEnviados = [];

    for (var hilo in mapaHilos.values) {
      // Ordenar mensajes del hilo cronológicamente
      hilo.sort((a, b) => a['fecha'].compareTo(b['fecha']));
      // El primer mensaje define de quién es el artículo
      if (hilo.first['destinatario'] == miCorreo) {
        hilosRecibidos.add(hilo);
      } else {
        hilosEnviados.add(hilo);
      }
    }

    List<dynamic>? hiloActivo;
    if (_conversacionActivaId != null && mapaHilos.containsKey(_conversacionActivaId)) {
      hiloActivo = mapaHilos[_conversacionActivaId];
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0A15),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Centro de Negociaciones', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ),
      body: Stack(
        children: [
          // FONDO LÍQUIDO GLASS
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(top: size.height * 0.1 + (math.sin(_bgController.value * 2 * math.pi) * 150), left: size.width * 0.2 + (math.cos(_bgController.value * 2 * math.pi) * 100), child: Container(width: 600, height: 600, decoration: BoxDecoration(shape: BoxShape.circle, color: TruequiColors.purpura.withOpacity(0.2)), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120), child: const SizedBox()))),
                  Positioned(bottom: size.height * 0.05 + (math.cos(_bgController.value * 2 * math.pi) * 100), right: size.width * 0.1 + (math.sin(_bgController.value * 2 * math.pi) * 150), child: Container(width: 700, height: 700, decoration: BoxDecoration(shape: BoxShape.circle, color: TruequiColors.amarillo.withOpacity(0.15)), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120), child: const SizedBox()))),
                ],
              );
            },
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(40), border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5)),
                    child: _isLoading 
                      ? const Center(child: CircularProgressIndicator(color: TruequiColors.amarillo))
                      : Row(
                          children: [
                            // 1. COLUMNA IZQUIERDA: RECIBIDOS
                            Expanded(flex: 3, child: _construirListaHilos('Ofertas Recibidas', hilosRecibidos, Icons.call_received_rounded, TruequiColors.amarillo)),
                            VerticalDivider(color: Colors.white.withOpacity(0.2), width: 1),
                            
                            // 2. COLUMNA CENTRAL: CHAT ACTIVO
                            Expanded(flex: 5, child: _construirPanelChat(hiloActivo, miCorreo)),
                            VerticalDivider(color: Colors.white.withOpacity(0.2), width: 1),
                            
                            // 3. COLUMNA DERECHA: ENVIADOS
                            Expanded(flex: 3, child: _construirListaHilos('Tus Propuestas', hilosEnviados, Icons.call_made_rounded, TruequiColors.purpura)),
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

  // ========================================================
  // WIDGET: LISTA DE HILOS LATERAL
  // ========================================================
  Widget _construirListaHilos(String titulo, List<List<dynamic>> hilos, IconData icono, Color colorAcento) {
    return Container(
      color: Colors.white.withOpacity(0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(25),
            child: Row(
              children: [
                Icon(icono, color: colorAcento), const SizedBox(width: 10),
                Text(titulo, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Divider(color: Colors.white.withOpacity(0.1), height: 1),
          Expanded(
            child: hilos.isEmpty
                ? Center(child: Text('Nada por aquí...', style: TextStyle(color: Colors.white.withOpacity(0.4))))
                : ListView.builder(
                    itemCount: hilos.length,
                    itemBuilder: (context, index) {
                      final hilo = hilos[index];
                      final primerMsj = hilo.first;
                      final ultimoMsj = hilo.last;
                      final isSelected = _conversacionActivaId == primerMsj['conversacionId'];

                      return InkWell(
                        onTap: () => setState(() => _conversacionActivaId = primerMsj['conversacionId']),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
                            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
                            border: isSelected ? Border(left: BorderSide(color: colorAcento, width: 4)) : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(primerMsj['productoTitulo'], maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 16)),
                              const SizedBox(height: 8),
                              Text(ultimoMsj['contenido'], maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // WIDGET: PANEL CENTRAL DE CHAT
  // ========================================================
  Widget _construirPanelChat(List<dynamic>? hilo, String miCorreo) {
    if (hilo == null || hilo.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined, size: 80, color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 20),
            Text('Selecciona una conversación', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 18)),
          ],
        ),
      );
    }

    final primerMsj = hilo.first;
    final esMiArticulo = primerMsj['destinatario'] == miCorreo;
    final estado = primerMsj['estado'] ?? 'Pendiente';
    final otroUsuario = esMiArticulo ? primerMsj['remitente'] : primerMsj['destinatario'];

    return Column(
      children: [
        // CABECERA DEL CHAT (CON BOTONES DE ACEPTAR/RECHAZAR)
        Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.2)))),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: TruequiColors.purpura.withOpacity(0.5), child: const Icon(Icons.person, color: Colors.white)),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(primerMsj['productoTitulo'], style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    Text(otroUsuario, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
                  ],
                ),
              ),
              // BOTONES DE DECISIÓN (Solo si es tu artículo y está Pendiente)
              if (esMiArticulo && estado == 'Pendiente') ...[
                ElevatedButton.icon(onPressed: () => _actualizarEstado(primerMsj['id'], 'Rechazado'), style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.2), foregroundColor: Colors.redAccent, elevation: 0), icon: const Icon(Icons.close), label: const Text('Rechazar')),
                const SizedBox(width: 10),
                ElevatedButton.icon(onPressed: () => _actualizarEstado(primerMsj['id'], 'Aceptado'), style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent.withOpacity(0.2), foregroundColor: Colors.greenAccent, elevation: 0), icon: const Icon(Icons.check), label: const Text('Aceptar')),
              ] else ...[
                // ETIQUETA DE ESTADO
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: estado == 'Aceptado' ? Colors.greenAccent.withOpacity(0.2) : (estado == 'Rechazado' ? Colors.redAccent.withOpacity(0.2) : TruequiColors.amarillo.withOpacity(0.2)), borderRadius: BorderRadius.circular(20), border: Border.all(color: estado == 'Aceptado' ? Colors.greenAccent.withOpacity(0.5) : (estado == 'Rechazado' ? Colors.redAccent.withOpacity(0.5) : TruequiColors.amarillo.withOpacity(0.5)))),
                  child: Text(estado, style: TextStyle(fontWeight: FontWeight.bold, color: estado == 'Aceptado' ? Colors.greenAccent : (estado == 'Rechazado' ? Colors.redAccent : TruequiColors.amarillo))),
                )
              ]
            ],
          ),
        ),

        // HISTORIAL DE MENSAJES (BURBUJAS)
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(30),
            itemCount: hilo.length,
            itemBuilder: (context, index) {
              final msj = hilo[index];
              final loEnvieYo = msj['remitente'] == miCorreo;

              return Align(
                alignment: loEnvieYo ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: loEnvieYo ? TruequiColors.purpura.withOpacity(0.8) : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.only(topLeft: const Radius.circular(24), topRight: const Radius.circular(24), bottomLeft: loEnvieYo ? const Radius.circular(24) : const Radius.circular(0), bottomRight: loEnvieYo ? const Radius.circular(0) : const Radius.circular(24)),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Text(msj['contenido'], style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4)),
                ),
              );
            },
          ),
        ),

        // BARRA PARA ENVIAR RESPUESTA
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), border: Border(top: BorderSide(color: Colors.white.withOpacity(0.2)))),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white.withOpacity(0.3))),
                  child: TextField(
                    controller: _respuestaController, style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(hintText: 'Escribe tu respuesta...', hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 18)),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Container(
                decoration: BoxDecoration(color: TruequiColors.purpura, shape: BoxShape.circle, boxShadow: [BoxShadow(color: TruequiColors.purpura.withOpacity(0.5), blurRadius: 20)]),
                child: IconButton(
                  onPressed: _enviando ? null : () => _enviarMensaje(hilo),
                  icon: _enviando ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send_rounded, color: Colors.white),
                  padding: const EdgeInsets.all(15),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}