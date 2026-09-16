import 'package:flutter/material.dart';
import 'home_page.dart';
import '/SERVICES/producto_service.dart'; 
import 'detalle_producto_page.dart';

class ExplorarPage extends StatefulWidget {
  const ExplorarPage({super.key});

  @override
  State<ExplorarPage> createState() => _ExplorarPageState();
}

class _ExplorarPageState extends State<ExplorarPage> {
  String _categoriaSeleccionada = 'Todos';
  List<dynamic> _articulos = []; 
  bool _isLoading = true; 

  final List<String> _categorias = [
    'Todos', 'Electrónica', 'Libros', 'Accesorios', 'Hogar y Cocina', 'Mascotas'
  ];

  @override
  void initState() {
    super.initState();
    _cargarProductos(); 
  }

  Future<void> _cargarProductos() async {
    final servicio = ProductoService();
    final productos = await servicio.obtenerProductos();
    
    if (mounted) {
      setState(() {
        _articulos = productos;
        _isLoading = false;
      });
    }
  }

  Color _obtenerColor(String? categoria) {
    if (categoria == 'Electrónica' || categoria == 'Libros') return TruequiColors.purpura;
    return TruequiColors.amarillo;
  }

  IconData _obtenerIcono(String? categoria) {
    switch (categoria) {
      case 'Electrónica': return Icons.devices_rounded;
      case 'Libros': return Icons.menu_book_rounded;
      case 'Accesorios': return Icons.watch_rounded;
      case 'Hogar y Cocina': return Icons.rice_bowl_rounded;
      case 'Mascotas': return Icons.pets_rounded;
      default: return Icons.inventory_2_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final articulosFiltrados = _categoriaSeleccionada == 'Todos'
        ? _articulos
        : _articulos.where((item) => item['categoria'] == _categoriaSeleccionada).toList();

    return RefreshIndicator(
      color: TruequiColors.purpura,
      backgroundColor: Colors.white,
      onRefresh: _cargarProductos,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Row(
                children: [
                  const Icon(Icons.explore_rounded, color: TruequiColors.purpura, size: 32),
                  const SizedBox(width: 12),
                  const Text('Explorar', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: TruequiColors.purpura, letterSpacing: -0.5)),
                ],
              ),
            ),
          ),
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
                    onTap: () => setState(() => _categoriaSeleccionada = categoria),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? TruequiColors.purpura : Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? TruequiColors.purpura : Colors.white, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          categoria,
                          style: TextStyle(color: isSelected ? Colors.white : TruequiColors.textoOscuro, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          if (_isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 60), 
                child: Center(child: CircularProgressIndicator(color: TruequiColors.purpura))
              ),
            )
          else if (articulosFiltrados.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 60),
                child: Center(child: Text('No hay artículos disponibles', style: TextStyle(color: Colors.grey.shade600, fontSize: 16))),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = articulosFiltrados[index];
                    final titulo = item['titulo'] ?? 'Sin título';
                    final descripcion = item['descripcion'] ?? 'Abierto a ofertas'; 
                    final ubicacion = item['ubicacion'] ?? 'Querétaro';
                    final categoria = item['categoria'];

                    return _buildArticuloCard(
                      titulo: titulo,
                      subtitulo: descripcion,
                      ubicacion: ubicacion,
                      icono: _obtenerIcono(categoria),
                      color: _obtenerColor(categoria),
                      onTap: () {
                        // 👇 AQUÍ ESTÁ LA MAGIA: Navegación real a los detalles del producto 👇
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetalleProductoPage(producto: item),
                          ),
                        );
                      },
                    );
                  },
                  childCount: articulosFiltrados.length,
                ),
              ),
            ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildArticuloCard({
    required String titulo, required String subtitulo, required String ubicacion, required IconData icono, required Color color, required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white, width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: const BorderRadius.vertical(top: Radius.circular(22))),
                child: Center(child: Icon(icono, size: 48, color: color)),
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
                    Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(child: Text(ubicacion, style: const TextStyle(color: Colors.grey, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(color: TruequiColors.fondoClaro, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 12, color: TruequiColors.purpura),
                          const SizedBox(width: 4),
                          Expanded(child: Text(subtitulo, style: TextStyle(color: TruequiColors.textoOscuro.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
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