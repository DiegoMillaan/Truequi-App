import 'package:flutter/material.dart';
import 'home_page.dart';
import 'services/mensaje_service.dart';

class ChatPage extends StatefulWidget {
  final String miUsuarioId;
  final String destinatarioId;
  final String nombreDestinatario;
  final String? productoTitulo;

  const ChatPage({
    super.key,
    required this.miUsuarioId,
    required this.destinatarioId,
    required this.nombreDestinatario,
    this.productoTitulo,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final MensajeService _mensajeService = MensajeService();
  final TextEditingController _mensajeController = TextEditingController();
  
  List<dynamic> _mensajes = [];
  bool _cargando = true;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _cargarMensajes();
  }

  @override
  void dispose() {
    _mensajeController.dispose();
    super.dispose();
  }

  Future<void> _cargarMensajes() async {
    setState(() => _cargando = true);
    final msgs = await _mensajeService.obtenerMensajes(
      deUsuarioId: widget.miUsuarioId,
      paraUsuarioId: widget.destinatarioId,
    );
    if (!mounted) return;
    setState(() {
      _mensajes = msgs;
      _cargando = false;
    });
  }

  Future<void> _enviar() async {
    final texto = _mensajeController.text.trim();
    if (texto.isEmpty) return;

    setState(() => _enviando = true);

    final exito = await _mensajeService.enviarMensaje(
      deUsuarioId: widget.miUsuarioId,
      paraUsuarioId: widget.destinatarioId,
      texto: texto,
    );

    if (!mounted) return;
    setState(() => _enviando = false);

    if (exito) {
      _mensajeController.clear();
      _cargarMensajes();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo enviar el mensaje. Intenta de nuevo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TruequiColors.fondoClaro,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.nombreDestinatario,
              style: const TextStyle(color: TruequiColors.textoOscuro, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (widget.productoTitulo != null)
              Text(
                'Sobre: ${widget.productoTitulo}',
                style: TextStyle(color: TruequiColors.purpura.withValues(alpha: 0.8), fontSize: 12),
              ),
          ],
        ),
        iconTheme: const IconThemeData(color: TruequiColors.purpura),
      ),
      body: Column(
        children: [
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator(color: TruequiColors.purpura))
                : RefreshIndicator(
                    onRefresh: _cargarMensajes,
                    color: TruequiColors.purpura,
                    child: _mensajes.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 100),
                              Center(
                                child: Text(
                                  'Aún no hay mensajes. ¡Inicia la conversación!',
                                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: _mensajes.length,
                            itemBuilder: (context, index) {
                              final item = _mensajes[index];
                              final esMio = item['deUsuarioId'] == widget.miUsuarioId;
                              final texto = item['texto'] ?? item['mensaje'] ?? '';

                              return Align(
                                alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: esMio ? TruequiColors.purpura : Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                                    ],
                                  ),
                                  child: Text(
                                    texto,
                                    style: TextStyle(
                                      color: esMio ? Colors.white : TruequiColors.textoOscuro,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2)),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mensajeController,
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      filled: true,
                      fillColor: TruequiColors.fondoClaro,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _enviando ? null : _enviar,
                  icon: _enviando
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: TruequiColors.purpura))
                      : const Icon(Icons.send_rounded, color: TruequiColors.purpura, size: 28),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}