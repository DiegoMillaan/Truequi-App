import 'package:flutter/material.dart';
import 'home_page.dart';
import 'chat_page.dart';
import 'services/mensaje_service.dart';
import 'services/auth_service.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  final MensajeService _mensajeService = MensajeService();
  String _miUsuarioId = '';
  bool _cargandoUsuario = true;
  Future<List<dynamic>>? _futureMensajes;

  @override
  void initState() {
    super.initState();
    _inicializarPantalla();
  }

  Future<void> _inicializarPantalla() async {
    // Obtener ID del usuario autenticado de forma dinámica
    final id = await AuthService.obtenerMiUsuarioId();
    if (!mounted) return;
    setState(() {
      _miUsuarioId = id;
      _cargandoUsuario = false;
      _futureMensajes = _mensajeService.obtenerMensajes(deUsuarioId: _miUsuarioId);
    });
  }

  void _recargarMensajes() {
    if (_miUsuarioId.isEmpty) return;
    setState(() {
      _futureMensajes = _mensajeService.obtenerMensajes(deUsuarioId: _miUsuarioId);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_cargandoUsuario) {
      return const Center(child: CircularProgressIndicator(color: TruequiColors.purpura));
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.chat_bubble_rounded, color: TruequiColors.purpura, size: 32),
                    SizedBox(width: 12),
                    Text(
                      'Mensajes',
                      style: TextStyle(
                        fontSize: 28, 
                        fontWeight: FontWeight.w900, 
                        color: TruequiColors.purpura, 
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Text(
                    'En vivo',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TruequiColors.purpura),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverFillRemaining(
          child: RefreshIndicator(
            onRefresh: () async => _recargarMensajes(),
            color: TruequiColors.purpura,
            child: FutureBuilder<List<dynamic>>(
              future: _futureMensajes,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: TruequiColors.purpura));
                }

                final mensajesRaw = snapshot.data ?? [];

                if (mensajesRaw.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 100),
                      Center(
                        child: Text(
                          'Aún no tienes conversaciones activas.',
                          style: TextStyle(color: TruequiColors.textoOscuro, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ],
                  );
                }

                // Agrupación dinámica de mensajes según interlocutor
                final Map<String, dynamic> conversaciones = {};
                for (var item in mensajesRaw) {
                  final deId = item['deUsuarioId']?.toString() ?? '';
                  final paraId = item['paraUsuarioId']?.toString() ?? '';
                  
                  final otroUsuarioId = (deId == _miUsuarioId) ? paraId : deId;
                  if (otroUsuarioId.isEmpty) continue;

                  if (!conversaciones.containsKey(otroUsuarioId)) {
                    conversaciones[otroUsuarioId] = item;
                  }
                }

                final listaConversaciones = conversaciones.entries.toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: listaConversaciones.length,
                  itemBuilder: (context, index) {
                    final entry = listaConversaciones[index];
                    final interlocutorId = entry.key;
                    final ultimoMsg = entry.value;

                    final texto = ultimoMsg['texto'] ?? ultimoMsg['mensaje'] ?? 'Nuevo mensaje';
                    final nombreInterlocutor = ultimoMsg['deUsuarioNombre'] ?? ultimoMsg['paraUsuarioNombre'] ?? 'Usuario';

                    return _buildChatCard(
                      context: context,
                      destinatarioId: interlocutorId,
                      nombre: nombreInterlocutor,
                      ultimoMensaje: texto,
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatCard({
    required BuildContext context,
    required String destinatarioId,
    required String nombre,
    required String ultimoMensaje,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ListTile(
        title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(ultimoMensaje, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatPage(
                miUsuarioId: _miUsuarioId,
                destinatarioId: destinatarioId,
                nombreDestinatario: nombre,
              ),
            ),
          ).then((_) => _recargarMensajes());
        },
      ),
    );
  }
}