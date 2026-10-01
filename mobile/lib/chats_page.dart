import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'home_page.dart'; // Para TruequiColors
import 'chat_page.dart';
import 'services/auth_service.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> with SingleTickerProviderStateMixin {
  String _miCorreo = '';
  bool _isLoading = true;
  List<dynamic> _mensajesBrutos = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _inicializarPantalla();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _inicializarPantalla() async {
    final id = await AuthService.obtenerMiUsuarioId();
    if (!mounted) return;
    setState(() => _miCorreo = id);
    _cargarMensajes();
  }

  Future<void> _cargarMensajes() async {
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/mensajes?usuario=$_miCorreo');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          _mensajesBrutos = jsonDecode(response.body)['mensajes'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Agrupar mensajes exactamente como en Web
    Map<String, List<dynamic>> mapaHilos = {};
    for (var m in _mensajesBrutos) {
      final cid = m['conversacionId'] ?? 'desconocido';
      mapaHilos.putIfAbsent(cid, () => []).add(m);
    }

    List<List<dynamic>> hilosRecibidos = [];
    List<List<dynamic>> hilosEnviados = [];

    for (var hilo in mapaHilos.values) {
      hilo.sort((a, b) => a['fecha'].compareTo(b['fecha']));
      // El primer mensaje define de quién es el artículo
      if (hilo.first['destinatario'] == _miCorreo) {
        hilosRecibidos.add(hilo);
      } else {
        hilosEnviados.add(hilo);
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent, // Hereda el fondo de HomePage
      body: Column(
        children: [
          // CABECERA Y TABS DE CRISTAL
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 50, 24, 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.2), width: 1.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Centro de Negocios', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.2))),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(color: TruequiColors.purpura, borderRadius: BorderRadius.circular(20)),
                        labelColor: Colors.white, unselectedLabelColor: Colors.white.withOpacity(0.5),
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        dividerColor: Colors.transparent,
                        tabs: const [
                          Tab(text: 'Recibidas (Tus artículos)'),
                          Tab(text: 'Tus Propuestas'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // VISTAS DE LAS LISTAS
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: TruequiColors.amarillo))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _construirLista(hilosRecibidos, esRecibido: true),
                      _construirLista(hilosEnviados, esRecibido: false),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _construirLista(List<List<dynamic>> hilos, {required bool esRecibido}) {
    if (hilos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined, size: 80, color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text('No hay mensajes aquí', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 120), // Padding inferior por la navbar
      itemCount: hilos.length,
      itemBuilder: (context, index) {
        final hilo = hilos[index];
        final primerMsj = hilo.first;
        final ultimoMsj = hilo.last;
        final estado = primerMsj['estado'] ?? 'Pendiente';
        final otroUsuario = esRecibido ? primerMsj['remitente'] : primerMsj['destinatario'];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.2))),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(backgroundColor: esRecibido ? TruequiColors.amarillo.withOpacity(0.8) : TruequiColors.purpura.withOpacity(0.8), child: Icon(esRecibido ? Icons.call_received : Icons.call_made, color: Colors.white)),
            title: Text(primerMsj['productoTitulo'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text('"${ultimoMsj['contenido']}"', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.7), fontStyle: FontStyle.italic)),
                const SizedBox(height: 6),
                Text('Con: $otroUsuario', style: TextStyle(color: TruequiColors.amarillo.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: estado == 'Aceptado' ? Colors.greenAccent.withOpacity(0.2) : (estado == 'Rechazado' ? Colors.redAccent.withOpacity(0.2) : TruequiColors.amarillo.withOpacity(0.2)), borderRadius: BorderRadius.circular(12), border: Border.all(color: estado == 'Aceptado' ? Colors.greenAccent.withOpacity(0.5) : (estado == 'Rechazado' ? Colors.redAccent.withOpacity(0.5) : TruequiColors.amarillo.withOpacity(0.5)))), child: Text(estado, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: estado == 'Aceptado' ? Colors.greenAccent : (estado == 'Rechazado' ? Colors.redAccent : TruequiColors.amarillo)))),
                const SizedBox(height: 8),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 14)
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(
                    miCorreo: _miCorreo,
                    otroCorreo: otroUsuario,
                    productoId: primerMsj['productoId'],
                    productoTitulo: primerMsj['productoTitulo'],
                    conversacionId: primerMsj['conversacionId'],
                    esMiArticulo: esRecibido,
                    estadoPropuesta: estado,
                    idPrimerMensaje: primerMsj['id'],
                  ),
                ),
              ).then((_) => _cargarMensajes());
            },
          ),
        );
      },
    );
  }
}