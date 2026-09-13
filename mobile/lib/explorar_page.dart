import 'package:flutter/material.dart';
import 'home_page.dart';

class ExplorarPage extends StatefulWidget {
  const ExplorarPage({super.key});

  @override
  State<ExplorarPage> createState() => _ExplorarPageState();
}

class _ExplorarPageState extends State<ExplorarPage> {
  // Categoría seleccionada por defecto
  String _categoriaSeleccionada = 'Todos';

  // Lista de categorías disponibles
  final List<String> _categorias = [
    'Todos',
    'Tecnología',
    'Hogar y Cocina',
    'Juegos de Mesa',
    'Mascotas'
  ];

  // Lista completa de artículos de ejemplo
  final List<Map<String, dynamic>> _articulos = [
    {
      'titulo': 'Arrocera Chefman',
      'busca': 'Parrilla eléctrica',
      'ubicacion': 'Centro, Qro',
      'icono': Icons.rice_bowl_rounded,
      'color': TruequiColors.amarillo,
      'categoria': 'Hogar y Cocina',
    },
    {
      'titulo': 'Rompecabezas Negro',
      'busca': 'Juego de investigación',
      'ubicacion': 'Cerca de UAQ',
      'icono': Icons.extension_rounded,
      'color': TruequiColors.purpura,
      'categoria': 'Juegos de Mesa',
    },
    {
      'titulo': 'Juego de Investigación',
      'busca': 'Libros en inglés',
      'ubicacion': 'Juriquilla',
      'icono': Icons.search_rounded,
      'color': TruequiColors.purpura,
      'categoria': 'Juegos de Mesa',
    },
    {
      'titulo': 'Alimento Nupec (Gato)',
      'busca': 'Accesorios mascota',
      'ubicacion': 'El Refugio',
      'icono': Icons.pets_rounded,
      'color': TruequiColors.amarillo,
      'categoria': 'Mascotas',
    },
    {
      'titulo': 'MacBook Air M1',
      'busca': 'iPad Pro',
      'ubicacion': 'Centro, Qro',
      'icono': Icons.devices_rounded,
      'color': TruequiColors.purpura,
      'categoria': 'Tecnología',
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Filtramos los artículos dinámicamente según la categoría seleccionada
    final articulosFiltrados = _categoriaSeleccionada == 'Todos'
        ? _articulos
        : _articulos.where((item) => item['categoria'] == _categoriaSeleccionada).toList();

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
        // CATEGORÍAS INTERACTIVAS (Filtros)
        // ==========================================
        SliverToBoxAdapter(
          child: SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _categorias.length,
              itemBuilder: (context, index) {
                final categoria = _categorias[index];
                final isSelected = _categoriaSeleccionada == categoria;
                return GestureDetector(
                  onTap: () {
                    // Actualizamos el estado para refrescar los elementos filtrados
                    setState(() {
                      _categoriaSeleccionada = categoria;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? TruequiColors.purpura : Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? TruequiColors.purpura : Colors.white, 
                        width: 1.5
                      ),
                    ),
                    child: Center(
                      child: Text(
                        categoria,
                        style: TextStyle(
                          color: isSelected ? Colors.white : TruequiColors.textoOscuro,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // ==========================================
        // GRID DE ARTÍCULOS DINÁMICO
        // ==========================================
        articulosFiltrados.isEmpty
            ? SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Center(
                    child: Text(
                      'No hay artículos en esta categoría',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                    ),
                  ),
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = articulosFiltrados[index];
                      return _buildArticuloCard(
                        titulo: item['titulo'],
                        busca: item['busca'],
                        ubicacion: item['ubicacion'],
                        icono: item['icono'],
                        color: item['color'],
                        onTap: () {
                          // Acción interactiva al tocar cualquier tarjeta de artículo
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Seleccionaste: ${item['titulo']}')),
                          );
                        },
                      );
                    },
                    childCount: articulosFiltrados.length,
                  ),
                ),
              ),
        
        // Espacio al final para la barra flotante
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  // ==========================================
  // WIDGET TARJETA INTERACTIVA
  // ==========================================
  Widget _buildArticuloCard({
    required String titulo, 
    required String busca, 
    required String ubicacion, 
    required IconData icono, 
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
      ),
    );
  }
}