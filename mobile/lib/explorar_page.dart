import 'package:flutter/material.dart';
import 'home_page.dart'; // Importamos para usar los TruequiColors

class ExplorarPage extends StatelessWidget {
  const ExplorarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ==========================================
        // HEADER: TÍTULO
        // ==========================================
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: Row(
              children: [
                const Icon(Icons.explore_rounded, color: TruequiColors.purpura, size: 32),
                const SizedBox(width: 12),
                const Text(
                  'Explorar',
                  style: TextStyle(
                    fontSize: 28, 
                    fontWeight: FontWeight.w900, 
                    color: TruequiColors.purpura, 
                    letterSpacing: -0.5
                  ),
                ),
              ],
            ),
          ),
        ),

        // ==========================================
        // CATEGORÍAS TIPO PÍLDORA (Glassmorphism)
        // ==========================================
        SliverToBoxAdapter(
          child: SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                _buildCategoriaChip('Todos', isSelected: true),
                _buildCategoriaChip('Tecnología'),
                _buildCategoriaChip('Hogar y Cocina'),
                _buildCategoriaChip('Juegos de Mesa'),
                _buildCategoriaChip('Mascotas'),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // ==========================================
        // GRID DE ARTÍCULOS
        // ==========================================
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75, // Ajusta la proporción de las tarjetas (más altas)
            ),
            delegate: SliverChildListDelegate([
              _buildArticuloCard(
                titulo: 'Arrocera Chefman',
                busca: 'Parrilla eléctrica',
                ubicacion: 'Centro, Qro',
                icono: Icons.rice_bowl_rounded,
                color: TruequiColors.amarillo,
              ),
              _buildArticuloCard(
                titulo: 'Rompecabezas Negro',
                busca: 'Juego de investigación',
                ubicacion: 'Cerca de UAQ',
                icono: Icons.extension_rounded,
                color: TruequiColors.purpura,
              ),
              _buildArticuloCard(
                titulo: 'Juego de Investigación',
                busca: 'Libros en inglés',
                ubicacion: 'Juriquilla',
                icono: Icons.search_rounded,
                color: TruequiColors.purpura,
              ),
              _buildArticuloCard(
                titulo: 'Alimento Nupec (Gato)',
                busca: 'Accesorios mascota',
                ubicacion: 'El Refugio',
                icono: Icons.pets_rounded,
                color: TruequiColors.amarillo,
              ),
            ]),
          ),
        ),
        
        // Espacio al final para que la barra flotante no tape el contenido
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  // ==========================================
  // WIDGETS REUTILIZABLES
  // ==========================================

  Widget _buildCategoriaChip(String texto, {bool isSelected = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? TruequiColors.purpura : Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? TruequiColors.purpura : Colors.white, width: 1.5),
      ),
      child: Center(
        child: Text(
          texto,
          style: TextStyle(
            color: isSelected ? Colors.white : TruequiColors.textoOscuro,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildArticuloCard({
    required String titulo, 
    required String busca, 
    required String ubicacion, 
    required IconData icono, 
    required Color color
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Área de la imagen (placeholder de ícono con fondo suave)
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Center(
                child: Icon(icono, size: 48, color: color),
              ),
            ),
          ),
          // Detalles del artículo
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          ubicacion,
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: TruequiColors.fondoClaro,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.swap_horiz_rounded, size: 12, color: TruequiColors.purpura),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            busca,
                            style: TextStyle(
                              color: TruequiColors.textoOscuro.withValues(alpha: 0.8), 
                              fontSize: 10, 
                              fontWeight: FontWeight.bold
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}