import 'package:flutter/material.dart';
import 'home_page.dart';
import 'chat_page.dart';
import 'services/mensaje_service.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  final MensajeService _mensajeService = MensajeService();
  late Future<List<dynamic>> _futureMensajes;

  // ID del usuario actual (puedes ajustar según tu sistema de sesión)
  final String _miUsuarioId = '1';

  @override
  void initState() {
    super.initState();
    _cargarConversaciones();
  }

  void _cargarConversaciones() {
    setState(() {
      _futureMensajes = _mensajeService.obtenerMensajes(deUsuarioId: _miUsuarioId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ==========================================
        // HEADER: TÍTULO DE MENSAJES
        // ==========================================
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
                    style: TextStyle(
                      fontSize: 12, 
                      fontWeight: FontWeight.bold, 
                      color: TruequiColors.purpura,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ==========================================
        // ESTRUCTURA DINÁMICA CONECTADA A AWS
        // ==========================================
        SliverFillRemaining(
          child: RefreshIndicator(
            onRefresh: () async => _cargarConversaciones(),
            color: TruequiColors.purpura,
            child: FutureBuilder<List<dynamic>>(
              future: _futureMensajes,
              builder: (context, snapshot) {
                // 1. Estado de carga
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: TruequiColors.purpura),
                  );
                }

                // 2. Estado de error
                if (snapshot.hasError) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 100),
                      Center(
                        child: Text(
                          'Error al conectar con AWS. Desliza para reintentar.',
                          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  );
                }

                final mensajesRaw = snapshot.data ?? [];

                // 3. Estado sin mensajes / Lista vacía
                if (mensajesRaw.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 100),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.mark_chat_read_rounded, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Aún no tienes conversaciones activas.',
                              style: TextStyle(color: TruequiColors.textoOscuro, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Propón un trueque desde el catálogo para iniciar un chat.',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                // 4. Agrupar mensajes en conversaciones por usuario
                final Map<String, dynamic> conversaciones = {};
                for (var item in mensajesRaw) {
                  final deId = item['deUsuarioId']?.toString() ?? '';
                  final paraId = item['paraUsuarioId']?.toString() ?? '';
                  
                  // Identificar el ID del interlocutor
                  final otroUsuarioId = (deId == _miUsuarioId) ? paraId : deId;
                  if (otroUsuarioId.isEmpty) continue;

                  // Guardar el mensaje más reciente de esa conversación
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
                    final destinatarioId = entry.key;
                    final ultimoMsg = entry.value;

                    final texto = ultimoMsg['texto'] ?? ultimoMsg['mensaje'] ?? 'Nuevo mensaje';
                    final producto = ultimoMsg['productoId'] != null ? 'Trueque en curso' : 'Consulta general';

                    return _buildChatCard(
                      context: context,
                      destinatarioId: destinatarioId,
                      nombre: 'Usuario #$destinatarioId',
                      articulo: producto,
                      ultimoMensaje: texto,
                      colorAvatar: TruequiColors.purpura,
                      icono: Icons.person_rounded,
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

  // ==========================================
  // WIDGET DE TARJETA DE CHAT REAL
  // ==========================================
  Widget _buildChatCard({
    required BuildContext context,
    required String destinatarioId,
    required String nombre,
    required String articulo,
    required String ultimoMensaje,
    required Color colorAvatar,
    required IconData icono,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(
                  miUsuarioId: _miUsuarioId,
                  destinatarioId: destinatarioId,
                  nombreDestinatario: nombre,
                  productoTitulo: articulo,
                ),
              ),
            ).then((_) => _cargarConversaciones()); // Recargar mensajes al volver del chat
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: colorAvatar.withValues(alpha: 0.15),
                  child: Icon(icono, color: colorAvatar, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: TruequiColors.textoOscuro,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        articulo,
                        style: TextStyle(
                          color: TruequiColors.purpura.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        ultimoMensaje,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}