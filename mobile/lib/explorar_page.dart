import 'package:flutter/material.dart';
import 'home_page.dart';
import '/services/producto_service.dart';
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
    'Todos', 'Electrónica', 'Accesorios', 'Libros'
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

  @override
  Widget build(BuildContext context) {
    final articulosFiltrados = _categoriaSeleccionada == 'Todos'
        ? _articulos
        : _articulos.where((item) => item['categoria'] == _categoriaSeleccionada).toList();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
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
              padding: const EdgeInsets.only(top: 60),
              child: Center(child: Text('No hay artículos en esta categoría', style: TextStyle(color: Colors.grey.shade600, fontSize: 16))),
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
                  // Se extrae la URL de la imagen en lugar del icono
                  final imagenUrl = item['imagenUrl'] ?? ''; 
                  final precio = item['precio'] ?? '0.0';

                  return _buildArticuloCard(
                    titulo: titulo,
                    precio: precio,
                    imagenUrl: imagenUrl,
                    onTap: () {
                      // Se reemplaza el SnackBar por la navegación a la pantalla de detalles
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
    );
  }

  // Tarjeta rediseñada para usar imágenes (NetworkImage)
  Widget _buildArticuloCard({
    required String titulo, required String precio, required String imagenUrl, required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 2),
          image: DecorationImage(
            // Carga la imagen desde S3, si está vacía pone un color base
            image: NetworkImage(imagenUrl.isNotEmpty ? imagenUrl : 'https://via.placeholder.com/150'),
            fit: BoxFit.cover,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Stack(
          children: [
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter, end: Alignment.topCenter,
                    colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 12, left: 12, right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('\$$precio', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}