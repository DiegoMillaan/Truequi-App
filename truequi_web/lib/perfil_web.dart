import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'services/google_auth_service.dart';
import 'home_web.dart';

class PerfilWeb extends StatefulWidget {
  final Map<String, dynamic> usuario;
  const PerfilWeb({super.key, required this.usuario});

  @override
  State<PerfilWeb> createState() => _PerfilWebState();
}

class _PerfilWebState extends State<PerfilWeb> {
  Map<String, dynamic>? _perfilData;
  List<dynamic> _misProductos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    try {
      final url = Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/usuario/perfil/${widget.usuario['correo']}');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) setState(() {
          _perfilData = data['usuario'];
          _misProductos = data['misProductos'];
          _isLoading = false;
        });
      }
    } catch (e) { setState(() => _isLoading = false); }
  }

  Future<void> _borrarProducto(String id) async {
    try {
      final res = await http.delete(Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/productos/$id'));
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Artículo eliminado'), backgroundColor: Colors.green));
        _cargarPerfil();
      }
    } catch (e) { debugPrint('Error al borrar'); }
  }

  Future<void> _editarPerfil() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null) return;
    
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subiendo nueva foto...')));
    try {
      final bytes = await image.readAsBytes();
      final ext = image.name.split('.').last.toLowerCase();
      final resUrl = await http.get(Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/productos/upload-url?ext=$ext'));
      final urlData = jsonDecode(resUrl.body);
      
      await http.put(Uri.parse(urlData['uploadUrl']), body: bytes);
      
      final resUpdate = await http.put(
        Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/usuario/perfil'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'correo': widget.usuario['correo'], 'fotoUrl': urlData['publicUrl']}),
      );
      
      if (resUpdate.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil Actualizado'), backgroundColor: Colors.green));
        _cargarPerfil();
      }
    } catch (e) { debugPrint('Error editando perfil'); }
  }

  Future<void> _cerrarSesion() async {
    await GoogleAuthService().signOut(); 
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeWeb()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: Color(0xFF0D0A15), body: Center(child: CircularProgressIndicator(color: TruequiColors.purpura)));

    final nombre = _perfilData?['nombre'] ?? widget.usuario['nombre'] ?? 'Usuario';
    final foto = _perfilData?['foto'] ?? widget.usuario['foto'];
    final promedio = _perfilData?['promedio'] ?? '5.0';

    return Scaffold(
      backgroundColor: const Color(0xFF0D0A15),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned(top: -100, right: -100, child: Container(width: 500, height: 500, decoration: BoxDecoration(shape: BoxShape.circle, color: TruequiColors.purpura.withOpacity(0.3)), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100), child: const SizedBox()))),
          
          SingleChildScrollView(
            padding: const EdgeInsets.all(50),
            child: Column(
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        width: 600, padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(40), border: Border.all(color: Colors.white.withOpacity(0.2))),
                        child: Column(
                          children: [
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                CircleAvatar(radius: 60, backgroundColor: TruequiColors.purpura.withOpacity(0.2), backgroundImage: foto != null ? NetworkImage(foto) : null, child: foto == null ? const Icon(Icons.person, size: 60, color: Colors.white) : null),
                                GestureDetector(
                                  onTap: _editarPerfil,
                                  child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: TruequiColors.amarillo, shape: BoxShape.circle), child: const Icon(Icons.camera_alt, color: Colors.white, size: 20)),
                                )
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(nombre, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
                            Text(widget.usuario['correo'], style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.5))),
                            const SizedBox(height: 25),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildStatBadge(Icons.star_rounded, '$promedio', TruequiColors.amarillo),
                                const SizedBox(width: 15),
                                _buildStatBadge(Icons.inventory_2_rounded, '${_misProductos.length} Publicaciones', TruequiColors.purpura),
                              ],
                            ),
                            const SizedBox(height: 30),
                            OutlinedButton.icon(onPressed: _cerrarSesion, icon: const Icon(Icons.logout), label: const Text('Cerrar Sesión'), style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: BorderSide(color: Colors.redAccent.withOpacity(0.5))))
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 50),
                const Align(alignment: Alignment.centerLeft, child: Text('Tus Artículos', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white))),
                const SizedBox(height: 20),
                
                _misProductos.isEmpty 
                  ? const Center(child: Text('No tienes artículos publicados.', style: TextStyle(color: Colors.grey)))
                  : GridView.builder(
                      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 400, mainAxisExtent: 100, crossAxisSpacing: 20, mainAxisSpacing: 20),
                      itemCount: _misProductos.length,
                      itemBuilder: (context, index) {
                        final prod = _misProductos[index];
                        return Container(
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.2))),
                          child: Center(
                            child: ListTile(
                              leading: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(prod['imagenUrl'] ?? 'https://via.placeholder.com/50', width: 50, height: 50, fit: BoxFit.cover)),
                              title: Text(prod['titulo'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 1),
                              subtitle: Text(prod['estado'], style: TextStyle(color: prod['estado'] == 'Disponible' ? Colors.greenAccent : Colors.orange)),
                              trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _borrarProducto(prod['id'])),
                            ),
                          ),
                        );
                      },
                    )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(children: [Icon(icon, color: color, size: 20), const SizedBox(width: 8), Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold))]),
    );
  }
}