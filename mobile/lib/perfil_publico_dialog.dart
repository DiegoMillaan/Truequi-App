import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'home_page.dart'; // Importamos tus colores de TruequiColors

class PerfilPublicoDialog extends StatefulWidget {
  final String correoUsuario;

  const PerfilPublicoDialog({super.key, required this.correoUsuario});

  static void mostrar(BuildContext context, String correo) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (_) => PerfilPublicoDialog(correoUsuario: correo),
    );
  }

  @override
  State<PerfilPublicoDialog> createState() => _PerfilPublicoDialogState();
}

class _PerfilPublicoDialogState extends State<PerfilPublicoDialog> {
  Map<String, dynamic>? _perfilData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarPerfilPublico();
  }

  Future<void> _cargarPerfilPublico() async {
    try {
      final url = Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/usuario/perfil/${widget.correoUsuario}');
      final res = await http.get(url);
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _perfilData = data['usuario'];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20), // Margen para pantallas móviles
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            width: double.infinity, // Se adapta al ancho del celular
            constraints: const BoxConstraints(maxWidth: 450), // Límite máximo
            padding: const EdgeInsets.all(30), // Padding ligeramente reducido para móviles
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: TruequiColors.purpura.withOpacity(0.5), width: 2),
            ),
            child: _isLoading 
              ? const SizedBox(height: 300, child: Center(child: CircularProgressIndicator(color: TruequiColors.amarillo)))
              : _construirTarjetaPerfil(),
          ),
        ),
      ),
    );
  }

  Widget _construirTarjetaPerfil() {
    final nombre = _perfilData?['nombre'] ?? widget.correoUsuario.split('@')[0];
    final foto = _perfilData?['fotoUrl'] ?? _perfilData?['foto'];
    
    // CORRECCIÓN EXACTA DE CACHÉ Y URLs DE GOOGLE
    String? fotoConCacheKiller = foto;
    if (foto != null && foto.isNotEmpty) {
      fotoConCacheKiller = foto.contains('?') 
          ? '$foto&v=${DateTime.now().millisecondsSinceEpoch}' 
          : '$foto?v=${DateTime.now().millisecondsSinceEpoch}';
    }
    
    final promedio = _perfilData?['promedio']?.toString() ?? '5.0';
    final totalCalificaciones = _perfilData?['totalCalificaciones']?.toString() ?? '0';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            )
          ],
        ),
        Container(
          width: 120, height: 120, // Ligeramente más pequeño para celular
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: TruequiColors.purpura, width: 4),
            boxShadow: [BoxShadow(color: TruequiColors.purpura.withOpacity(0.3), blurRadius: 30)],
            image: fotoConCacheKiller != null ? DecorationImage(image: NetworkImage(fotoConCacheKiller), fit: BoxFit.cover) : null,
            color: foto == null ? TruequiColors.purpura.withOpacity(0.2) : null,
          ),
          child: foto == null ? const Icon(Icons.person, size: 60, color: Colors.white) : null,
        ),
        const SizedBox(height: 20),
        Text(nombre, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
        const SizedBox(height: 5),
        Text(widget.correoUsuario, style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6)), textAlign: TextAlign.center),
        const SizedBox(height: 25),
        
        // Métricas del usuario público
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1))
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _metricaColumna(Icons.star_rounded, promedio, 'Reputación', TruequiColors.amarillo),
              Container(height: 40, width: 1, color: Colors.white.withOpacity(0.2)),
              _metricaColumna(Icons.reviews_rounded, totalCalificaciones, 'Reseñas', TruequiColors.purpura),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity, height: 50,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: TruequiColors.purpura,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
            ),
            child: const Text('Cerrar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        )
      ],
    );
  }

  Widget _metricaColumna(IconData icono, String valor, String titulo, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, color: color, size: 24),
            const SizedBox(width: 5),
            Text(valor, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 5),
        Text(titulo, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}