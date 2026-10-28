import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_page.dart'; 
import 'chat_page.dart';
import 'login_screen.dart';
import 'perfil_publico_dialog.dart';

class DetalleProductoPage extends StatefulWidget {
  final Map<String, dynamic> producto;
  final String miCorreo; 

  const DetalleProductoPage({super.key, required this.producto, required this.miCorreo});

  @override
  State<DetalleProductoPage> createState() => _DetalleProductoPageState();
}

class _DetalleProductoPageState extends State<DetalleProductoPage> {
  String _nombreVendedor = '';
  String? _fotoVendedorUrl;
  bool _esFavorito = false;
  bool _cargandoFavorito = false;
  List<dynamic> _favoritosUsuario = [];

  @override
  void initState() {
    super.initState();
    _nombreVendedor = widget.producto['vendedorNombre']?.toString() ?? 'Propietario';
    _cargarDatosVendedorReal();
    _cargarEstadoFavorito();
  }

  Future<void> _cargarEstadoFavorito() async {
    final miId = widget.miCorreo.trim().toLowerCase();
    if (miId.isEmpty || miId == 'invitado') return;

    try {
      final url = Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/usuario/perfil/$miId');
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['usuario'];
        final List<dynamic> favs = data['favoritos'] ?? [];
        final prodId = widget.producto['id']?.toString() ?? '';

        if (mounted) {
          setState(() {
            _favoritosUsuario = favs;
            _esFavorito = favs.contains(prodId);
          });
        }
      }
    } catch (e) {
      debugPrint('Error al verificar estado de favorito: $e');
    }
  }

  Future<void> _toggleFavorito() async {
    final miId = widget.miCorreo.trim().toLowerCase();
    if (miId.isEmpty || miId == 'invitado') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para guardar favoritos.', style: TextStyle(fontWeight: FontWeight.bold, color: TruequiColors.textoOscuro)),
          backgroundColor: TruequiColors.amarillo,
        ),
      );
      return;
    }

    if (_cargandoFavorito) return;
    setState(() => _cargandoFavorito = true);

    final prodId = widget.producto['id']?.toString() ?? '';
    List<dynamic> favsActualizados = List.from(_favoritosUsuario);

    if (_esFavorito) {
      favsActualizados.remove(prodId);
    } else {
      if (!favsActualizados.contains(prodId)) {
        favsActualizados.add(prodId);
      }
    }

    try {
      final res = await http.put(
        Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/usuario/perfil'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'correo': miId,
          'favoritos': favsActualizados,
        }),
      );

      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            _favoritosUsuario = favsActualizados;
            _esFavorito = !_esFavorito;
            _cargandoFavorito = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_esFavorito ? 'Guardado en favoritos' : 'Eliminado de favoritos', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              backgroundColor: _esFavorito ? TruequiColors.purpura : Colors.grey[800],
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) setState(() => _cargandoFavorito = false);
      }
    } catch (e) {
      debugPrint('Error al actualizar favorito: $e');
      if (mounted) setState(() => _cargandoFavorito = false);
    }
  }

  Future<void> _cargarDatosVendedorReal() async {
    final vendedorId = widget.producto['vendedorId']?.toString() ?? '';
    if (vendedorId.isEmpty) return;

    try {
      final url = Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/usuario/perfil/$vendedorId');
      final res = await http.get(url);
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['usuario'];
        if (mounted) {
          setState(() {
            String nombreDB = data['nombre'] ?? _nombreVendedor;
            _nombreVendedor = nombreDB[0].toUpperCase() + nombreDB.substring(1);
            
            String? fotoDB = data['fotoUrl'] ?? data['foto'];
            if (fotoDB != null && fotoDB.isNotEmpty) {
              _fotoVendedorUrl = fotoDB.contains('?') 
                  ? '$fotoDB&v=${DateTime.now().millisecondsSinceEpoch}' 
                  : '$fotoDB?v=${DateTime.now().millisecondsSinceEpoch}';
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error cargando perfil del vendedor: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final titulo = widget.producto['titulo'] ?? 'Sin título';
    final descripcion = widget.producto['descripcion'] ?? 'Sin descripción';
    final precio = widget.producto['precio']?.toString() ?? '0.0';
    final categoria = widget.producto['categoria'] ?? 'General';
    final ubicacion = widget.producto['ubicacion'] ?? 'Querétaro';
    final imagenUrl = widget.producto['imagenUrl'];
    final vendedorId = widget.producto['vendedorId']?.toString() ?? '';

    final String heroTag = 'img_${widget.producto['id']}';
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: TruequiColors.fondoClaro, 
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
            child: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
              child: IconButton(
                icon: _cargandoFavorito
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Icon(
                        _esFavorito ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: _esFavorito ? Colors.redAccent : Colors.white,
                        size: 22,
                      ),
                onPressed: _toggleFavorito,
              ),
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          Positioned(top: -50, right: -50, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: TruequiColors.purpura.withOpacity(0.3)), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: const SizedBox()))),
          Positioned(bottom: -50, left: -50, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: TruequiColors.amarillo.withOpacity(0.2)), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: const SizedBox()))),
          
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                Hero(
                  tag: heroTag,
                  child: SizedBox(
                    height: size.height * 0.45,
                    width: double.infinity,
                    child: imagenUrl != null && imagenUrl.startsWith('http')
                        ? Image.network(imagenUrl, fit: BoxFit.cover)
                        : Container(color: TruequiColors.purpura.withOpacity(0.2), child: const Center(child: Icon(Icons.inventory_2_rounded, size: 100, color: Colors.white54))),
                  ),
                ),
                
                Transform.translate(
                  offset: const Offset(0, -40),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(30, 40, 30, 80),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.3), width: 1.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: TruequiColors.amarillo.withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: TruequiColors.amarillo.withOpacity(0.5))), child: Text(categoria, style: const TextStyle(color: TruequiColors.amarillo, fontWeight: FontWeight.bold, fontSize: 12))),
                                Row(children: [const Icon(Icons.location_on_rounded, color: Colors.white54, size: 16), const SizedBox(width: 4), Text(ubicacion, style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold))]),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(titulo, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1)),
                            const SizedBox(height: 10),
                            Text('Valor est: \$ $precio MXN', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: TruequiColors.purpura)),
                            const SizedBox(height: 30),
                            
                            const Text('Descripción', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 10),
                            Text(descripcion, style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.7), height: 1.5)),
                            const SizedBox(height: 30),
                            Divider(color: Colors.white.withOpacity(0.1)),
                            const SizedBox(height: 20),
                            
                            GestureDetector(
                              onTap: () {
                                if (vendedorId.isNotEmpty) {
                                  PerfilPublicoDialog.mostrar(context, vendedorId);
                                }
                              },
                              child: Container(
                                color: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 5),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24, 
                                      backgroundColor: TruequiColors.purpura.withOpacity(0.5), 
                                      backgroundImage: _fotoVendedorUrl != null ? NetworkImage(_fotoVendedorUrl!) : null,
                                      child: _fotoVendedorUrl == null ? const Icon(Icons.person, color: Colors.white) : null,
                                    ),
                                    const SizedBox(width: 15),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start, 
                                      children: [
                                        const Text('Publicado por:', style: TextStyle(color: Colors.white54, fontSize: 13)), 
                                        Text(
                                          _nombreVendedor, 
                                          style: const TextStyle(
                                            color: Colors.white, 
                                            fontWeight: FontWeight.bold, 
                                            fontSize: 17,
                                            decoration: TextDecoration.underline,
                                            decorationColor: Colors.white54
                                          )
                                        )
                                      ]
                                    )
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                            
                            SizedBox(
                              width: double.infinity,
                              height: 60,
                              child: ElevatedButton(
                                onPressed: () {
                                  final miId = widget.miCorreo.trim().toLowerCase();
                                  final vendedorNormalizado = vendedorId.trim().toLowerCase();
                                  
                                  if (miId.isEmpty || miId == 'invitado') {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes iniciar sesión para proponer un trueque.', style: TextStyle(fontWeight: FontWeight.bold, color: TruequiColors.textoOscuro)), backgroundColor: TruequiColors.amarillo));
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                                    return;
                                  }

                                  if (miId == vendedorNormalizado) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Este es tu propio artículo.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), backgroundColor: Colors.redAccent));
                                    return;
                                  }

                                  if (vendedorId.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se encontró al vendedor.')));
                                    return;
                                  }

                                  final participantes = [miId, vendedorNormalizado]..sort();
                                  final conversacionId = "${widget.producto['id']}_${participantes[0]}_${participantes[1]}";

                                  Navigator.push(context, MaterialPageRoute(builder: (context) => ChatPage(miCorreo: miId, otroCorreo: vendedorNormalizado, productoId: widget.producto['id'].toString(), productoTitulo: titulo, conversacionId: conversacionId, esMiArticulo: false, estadoPropuesta: 'Pendiente')));
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: TruequiColors.purpura, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 10, shadowColor: TruequiColors.purpura.withOpacity(0.5)),
                                child: const Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 28), SizedBox(width: 12), Text('Proponer Trueque', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}