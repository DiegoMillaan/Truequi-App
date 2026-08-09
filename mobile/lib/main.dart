import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MiApp());
}

class MiApp extends StatelessWidget {
  const MiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: EstadoBackendScreen(),
    );
  }
}

class EstadoBackendScreen extends StatefulWidget {
  const EstadoBackendScreen({super.key});

  @override
  State<EstadoBackendScreen> createState() => _EstadoBackendScreenState();
}

class _EstadoBackendScreenState extends State<EstadoBackendScreen> {
  String _mensaje = 'Da clic en el botón para verificar la conexión';
  bool _cargando = false;

  Future<void> _verificarConexion() async {
    setState(() {
      _cargando = true;
      _mensaje = 'Conectando con AWS...';
    });

    try {
      // Reemplazar con la URL real que te dé AWS API Gateway
      final url = Uri.parse('https://iqe7v3bpy4.execute-api.us-east-1.amazonaws.com/dev/health');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _mensaje = data['message'];
        });
      } else {
        setState(() {
          _mensaje = 'Error en el servidor: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _mensaje = 'Error de red. No se pudo conectar a AWS.';
      });
    } finally {
      setState(() {
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test de conexión'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _mensaje,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _cargando ? null : _verificarConexion,
                child: _cargando 
                  ? const CircularProgressIndicator() 
                  : const Text('Comprobar conexión'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}