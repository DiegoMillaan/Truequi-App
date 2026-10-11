import 'dart:ui';
import 'dart:convert';
import 'dart:async';
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
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 25))..repeat();
    _cargarMensajes(silencioso: false);
    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (_) => _cargarMensajes(silencioso: true));
  }

  @override
  void dispose() {
    _bgController.dispose();
    _respuestaController.dispose();
    _pollingTimer?.cancel();
    super.dispose();
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
        elevation: 0, behavior: SnackBarBehavior.floating, backgroundColor: Colors.transparent,
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
                boxShadow: [BoxShadow(color: colorBase.withOpacity(0.25), blurRadius: 25, offset: const Offset(0, 10))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: colorBase.withOpacity(0.2), shape: BoxShape.circle),
                    child: Icon(icono, color: colorBase, size: 28),
                  ),
                  const SizedBox(width: 18),
                  Expanded(child: Text(mensaje, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _cargarMensajes({bool silencioso = false}) async {
    if (!silencioso) setState(() => _isLoading = true);
    try {
      final correo = widget.usuarioActual['correo'];
      final url = Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/mensajes?usuario=$correo');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        if (mounted) setState(() {
          _mensajesBrutos = jsonDecode(response.body)['mensajes'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _actualizarEstado(String mensajeId, String nuevoEstado, {String? pin}) async {
    try {
      final url = Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/mensajes/$mensajeId');
      final body = {'estado': nuevoEstado};
      if (pin != null) body['pin'] = pin;

      final response = await http.put(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
      if (response.statusCode == 200) {
        _cargarMensajes(); 
        if (mounted && nuevoEstado != 'Completado') {
          _mostrarAlertaLiquid(context, 'Trueque $nuevoEstado', tipo: nuevoEstado == 'Aceptado' ? 'exito' : 'info');
        }
        return true;
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Error desconocido';
        if (mounted) _mostrarAlertaLiquid(context, error, tipo: 'error');
        return false;
      }
    } catch (e) { 
      debugPrint('Error: $e'); 
      return false;
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
          'conversacionId': primerMsj['conversacionId'], 'remitente': miCorreo, 'destinatario': destinatario,
          'productoId': primerMsj['productoId'], 'productoTitulo': primerMsj['productoTitulo'],
          'contenido': _respuestaController.text.trim(), 'estado': primerMsj['estado'] 
        }),
      );
      if (response.statusCode == 201) {
        _respuestaController.clear();
        await _cargarMensajes();
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _mostrarModalValidacionPin(String destinatarioCorreo, String mensajeId) {
    final pinController = TextEditingController();
    bool validando = false;

    showDialog(
      context: context, barrierColor: Colors.black.withOpacity(0.8),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (contextModal, setModalState) {
            Future<void> validarPIN() async {
              if (pinController.text.trim().length != 4) return;
              setModalState(() => validando = true);
              
              bool exito = await _actualizarEstado(mensajeId, 'Completado', pin: pinController.text.trim());
              
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    width: 400, padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(40), border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: TruequiColors.purpura.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(Icons.lock_outline_rounded, size: 50, color: TruequiColors.purpura)),
                        const SizedBox(height: 20),
                        const Text('Validación Zero-Trust', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
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
                _mostrarAlertaLiquid(context, '¡Trueque completado y calificado! 🎉', tipo: 'exito');
              } catch (e) { setModalState(() => procesando = false); }
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    width: 400, padding: const EdgeInsets.all(40),
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
    final size = MediaQuery.of(context).size;
    final miCorreo = widget.usuarioActual['correo'];

    Map<String, List<dynamic>> mapaHilos = {};
    for (var m in _mensajesBrutos) {
      mapaHilos.putIfAbsent(m['conversacionId'] ?? 'desconocido', () => []).add(m);
    }

    List<List<dynamic>> hilosRecibidos = [];
    List<List<dynamic>> hilosEnviados = [];

    for (var hilo in mapaHilos.values) {
      hilo.sort((a, b) => a['fecha'].compareTo(b['fecha']));
      if (hilo.first['destinatario'] == miCorreo) hilosRecibidos.add(hilo);
      else hilosEnviados.add(hilo);
    }

    List<dynamic>? hiloActivo;
    if (_conversacionActivaId != null && mapaHilos.containsKey(_conversacionActivaId)) {
      hiloActivo = mapaHilos[_conversacionActivaId];
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0A15),
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white), title: const Text('Centro de Negociaciones', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1))),
      body: Stack(
        children: [
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
                            Expanded(flex: 3, child: _construirListaHilos('Ofertas Recibidas', hilosRecibidos, Icons.call_received_rounded, TruequiColors.amarillo)),
                            VerticalDivider(color: Colors.white.withOpacity(0.2), width: 1),
                            Expanded(flex: 5, child: _construirPanelChat(hiloActivo, miCorreo)),
                            VerticalDivider(color: Colors.white.withOpacity(0.2), width: 1),
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

  Widget _construirListaHilos(String titulo, List<List<dynamic>> hilos, IconData icono, Color colorAcento) {
    return Container(
      color: Colors.white.withOpacity(0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(25),
            child: Row(children: [Icon(icono, color: colorAcento), const SizedBox(width: 10), Text(titulo, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))]),
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
                      final isSelected = _conversacionActivaId == primerMsj['conversacionId'];

                      return InkWell(
                        onTap: () => setState(() => _conversacionActivaId = primerMsj['conversacionId']),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200), padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent, border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05)), left: isSelected ? BorderSide(color: colorAcento, width: 4) : BorderSide.none)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(primerMsj['productoTitulo'], maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 16)),
                              const SizedBox(height: 8),
                              Text(hilo.last['contenido'], maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
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

  Widget _construirPanelChat(List<dynamic>? hilo, String miCorreo) {
    if (hilo == null || hilo.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.forum_outlined, size: 80, color: Colors.white.withOpacity(0.2)), const SizedBox(height: 20), Text('Selecciona una conversación', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 18))]));

    final primerMsj = hilo.first;
    final esMiArticulo = primerMsj['destinatario'] == miCorreo;
    final estado = primerMsj['estado'] ?? 'Pendiente';
    final otroUsuario = esMiArticulo ? primerMsj['remitente'] : primerMsj['destinatario'];
    final pinValidacion = primerMsj['pinValidacion'] ?? '0000';

    return Column(
      children: [
        // CABECERA DEL CHAT
        Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.2)))),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: TruequiColors.purpura.withOpacity(0.5), child: const Icon(Icons.person, color: Colors.white)), const SizedBox(width: 15),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(primerMsj['productoTitulo'], style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis), Text(otroUsuario, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14))])),
              
              // 🛡️ LÓGICA DE DOBLE CANDADO
              if (estado == 'Pendiente') ...[
                if (esMiArticulo) ...[
                  ElevatedButton.icon(onPressed: () => _actualizarEstado(primerMsj['id'], 'Rechazado'), style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.2), foregroundColor: Colors.redAccent, elevation: 0), icon: const Icon(Icons.close), label: const Text('Rechazar')), const SizedBox(width: 10),
                  ElevatedButton.icon(onPressed: () => _actualizarEstado(primerMsj['id'], 'Aceptado'), style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent.withOpacity(0.2), foregroundColor: Colors.greenAccent, elevation: 0), icon: const Icon(Icons.check), label: const Text('Aceptar')),
                ] else
                  Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: TruequiColors.amarillo.withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: TruequiColors.amarillo.withOpacity(0.5))), child: const Text('Esperando respuesta...', style: TextStyle(fontWeight: FontWeight.bold, color: TruequiColors.amarillo))),
              ] 
              else if (estado == 'Aceptado') ...[
                if (esMiArticulo)
                  ElevatedButton.icon(
                    onPressed: () => _mostrarModalValidacionPin(otroUsuario, primerMsj['id']), 
                    style: ElevatedButton.styleFrom(backgroundColor: TruequiColors.purpura.withOpacity(0.3), foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)), 
                    icon: const Icon(Icons.lock_open_rounded, color: TruequiColors.amarillo), label: const Text('Ingresar PIN para Completar')
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(color: TruequiColors.amarillo.withOpacity(0.15), borderRadius: BorderRadius.circular(15), border: Border.all(color: TruequiColors.amarillo.withOpacity(0.5), width: 2)),
                    child: Row(
                      children: [
                        const Icon(Icons.key_rounded, color: TruequiColors.amarillo), const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('TU PIN DE ENTREGA', style: TextStyle(color: TruequiColors.amarillo, fontSize: 10, fontWeight: FontWeight.bold)),
                            Text(pinValidacion, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 4)),
                          ],
                        )
                      ],
                    ),
                  )
              ] 
              else ...[
                Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: estado == 'Completado' ? TruequiColors.purpura.withOpacity(0.2) : Colors.redAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: estado == 'Completado' ? TruequiColors.purpura.withOpacity(0.5) : Colors.redAccent.withOpacity(0.5))), child: Text(estado, style: TextStyle(fontWeight: FontWeight.bold, color: estado == 'Completado' ? TruequiColors.purpura : Colors.redAccent)))
              ]
            ],
          ),
        ),

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
                  margin: const EdgeInsets.only(bottom: 15), constraints: const BoxConstraints(maxWidth: 400), padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: loEnvieYo ? TruequiColors.purpura.withOpacity(0.8) : Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(24).copyWith(bottomLeft: loEnvieYo ? const Radius.circular(24) : Radius.zero, bottomRight: loEnvieYo ? Radius.zero : const Radius.circular(24)), border: Border.all(color: Colors.white.withOpacity(0.2))),
                  child: Text(msj['contenido'], style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4)),
                ),
              );
            },
          ),
        ),

        if (estado != 'Completado' && estado != 'Rechazado')
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), border: Border(top: BorderSide(color: Colors.white.withOpacity(0.2)))),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1), 
                      borderRadius: BorderRadius.circular(30), 
                      border: Border.all(color: Colors.white.withOpacity(0.3))
                    ), 
                    child: TextField(
                      controller: _respuestaController, 
                      style: const TextStyle(color: Colors.white), 
                      decoration: InputDecoration(
                        hintText: 'Escribe tu respuesta...', 
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)), 
                        border: InputBorder.none, 
                        contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 18)
                      )
                    )
                  )
                ),
                const SizedBox(width: 15),
                Container(
                  decoration: BoxDecoration(
                    color: TruequiColors.purpura, 
                    shape: BoxShape.circle, 
                    boxShadow: [BoxShadow(color: TruequiColors.purpura.withOpacity(0.5), blurRadius: 20)]
                  ), 
                  child: IconButton(
                    onPressed: _enviando ? null : () => _enviarMensaje(hilo), 
                    icon: _enviando ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send_rounded, color: Colors.white), 
                    padding: const EdgeInsets.all(15)
                  )
                )
              ],
            ),
          ),
      ],
    );
  }
}