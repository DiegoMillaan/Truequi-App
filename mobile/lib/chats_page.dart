import 'package:flutter/material.dart';
import 'home_page.dart';

class ChatsPage extends StatelessWidget {
  const ChatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Lista de chats simulados con un diseño moderno
    final List<Map<String, dynamic>> chatsFalsos = [
      {
        'nombre': 'Carlos Mendoza',
        'articulo': 'MacBook Air M1',
        'ultimoMensaje': '¿Aún tienes disponible la laptop para el trueque?',
        'tiempo': '10:45 AM',
        'noLeidos': 2,
        'colorAvatar': TruequiColors.purpura,
        'icono': Icons.devices_rounded,
      },
      {
        'nombre': 'Sofía Rangel',
        'articulo': 'Arrocera Chefman',
        'ultimoMensaje': 'Te parece si nos vemos mañana cerca de la UAQ?',
        'tiempo': 'Ayer',
        'noLeidos': 0,
        'colorAvatar': TruequiColors.amarillo,
        'icono': Icons.rice_bowl_rounded,
      },
      {
        'nombre': 'Alejandro Torres',
        'articulo': 'Rompecabezas Negro',
        'ultimoMensaje': '¡Gracias por el intercambio!',
        'tiempo': '02/09/2026',
        'noLeidos': 0,
        'colorAvatar': TruequiColors.purpura,
        'icono': Icons.extension_rounded,
      },
    ];

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
                        letterSpacing: -0.5
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
                    '3 Activos',
                    style: TextStyle(
                      fontSize: 12, 
                      fontWeight: FontWeight.bold, 
                      color: TruequiColors.purpura
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ==========================================
        // LISTA DE CONVERSACIONES MODERNAS
        // ==========================================
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final chat = chatsFalsos[index];
                return _buildChatCard(
                  context: context,
                  nombre: chat['nombre'],
                  articulo: chat['articulo'],
                  ultimoMensaje: chat['ultimoMensaje'],
                  tiempo: chat['tiempo'],
                  noLeidos: chat['noLeidos'],
                  colorAvatar: chat['colorAvatar'],
                  icono: chat['icono'],
                );
              },
              childCount: chatsFalsos.length,
            ),
          ),
        ),

        // Espacio al final para que la barra flotante no estorbe
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  // ==========================================
  // WIDGET DE TARJETA DE CHAT INDIVIDUAL
  // ==========================================
  Widget _buildChatCard({
    required BuildContext context,
    required String nombre,
    required String articulo,
    required String ultimoMensaje,
    required String tiempo,
    required int noLeidos,
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
            // Acción simulada al abrir un chat específico
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Abriendo chat con $nombre')),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Avatar con insignia del artículo
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: colorAvatar.withValues(alpha: 0.15),
                      child: Icon(icono, color: colorAvatar, size: 28),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: TruequiColors.amarillo,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.swap_horiz_rounded, size: 10, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                
                // Textos del chat (Nombre, Artículo y Mensaje)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            nombre,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: TruequiColors.textoOscuro,
                            ),
                          ),
                          Text(
                            tiempo,
                            style: TextStyle(
                              color: noLeidos > 0 ? TruequiColors.purpura : Colors.grey,
                              fontSize: 12,
                              fontWeight: noLeidos > 0 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Trueque: $articulo',
                        style: TextStyle(
                          color: TruequiColors.purpura.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ultimoMensaje,
                              style: TextStyle(
                                color: noLeidos > 0 ? TruequiColors.textoOscuro : Colors.grey.shade600,
                                fontSize: 13,
                                fontWeight: noLeidos > 0 ? FontWeight.w600 : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (noLeidos > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: TruequiColors.purpura,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$noLeidos',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}