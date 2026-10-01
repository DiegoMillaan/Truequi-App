import 'dart:ui';
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
  final List<String> _categorias = ['Todos', 'Electrónica', 'Accesorios', 'Libros'];

  @override
  void initState() {
    super.initState();
    _cargarProductos(); 
  }

  Future<void> _cargarProductos() async {
    final productos = await ProductoService().obtenerProductos();
    if (mounted) setState(() { _articulos = productos; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final articulosFiltrados = _categoriaSeleccionada == 'Todos' ? _articulos : _articulos.where((item) => item['categoria'] == _categoriaSeleccionada).toList();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
            child: Row(
              children: [
                const Icon(Icons.explore_rounded, color: TruequiColors.amarillo, size: 32),
                const SizedBox(width: 12),
                const Text('Explorar', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 45,
            child: ListView.builder(
              scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _categorias.length,
              itemBuilder: (context, index) {
                final categoria = _categorias[index];
                final isSelected = _categoriaSeleccionada == categoria;
                return GestureDetector(
                  onTap: () => setState(() => _categoriaSeleccionada = categoria),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(color: isSelected ? TruequiColors.purpura : Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: isSelected ? TruequiColors.purpura : Colors.white.withOpacity(0.2), width: 1.5)),
                    child: Center(child: Text(categoria, style: TextStyle(color: Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 15))),
                  ),
                );
              },
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        if (_isLoading)
          const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.only(top: 60), child: Center(child: CircularProgressIndicator(color: TruequiColors.purpura))))
        else if (articulosFiltrados.isEmpty)
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.only(top: 60), child: Center(child: Text('No hay artículos', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 18)))))
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.65),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = articulosFiltrados[index];
                  return _buildArticuloCardGlass(
                    titulo: item['titulo'] ?? 'Sin título', precio: item['precio']?.toString() ?? '0.0', imagenUrl: item['imagenUrl'] ?? '',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetalleProductoPage(producto: item))),
                  );
                },
                childCount: articulosFiltrados.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 140)),
      ],
    );
  }

  Widget _buildArticuloCardGlass({required String titulo, required String precio, required String imagenUrl, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: Container(decoration: BoxDecoration(borderRadius: const BorderRadius.vertical(top: Radius.circular(28)), image: DecorationImage(image: NetworkImage(imagenUrl.isNotEmpty ? imagenUrl : 'https://via.placeholder.com/150'), fit: BoxFit.cover)))),
                Expanded(flex: 4, child: Padding(padding: const EdgeInsets.all(16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis), Text('\$$precio', style: const TextStyle(color: TruequiColors.amarillo, fontSize: 16, fontWeight: FontWeight.w900))]))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}