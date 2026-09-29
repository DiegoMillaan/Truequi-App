import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Base URL para Registro y Login Google
  static const String baseUrl = 'https://16663yaped.execute-api.us-east-1.amazonaws.com/dev';

  // ==========================================
  // GESTIÓN DE SESIÓN LOCAL (SharedPreferences)
  // ==========================================

  // Guardar datos del usuario tras un login/registro exitoso
  static Future<void> guardarSesionUsuario({
    required String usuarioId,
    required String correo,
    String? nombre,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('usuarioId', usuarioId);
    await prefs.setString('correo', correo);
    if (nombre != null) {
      await prefs.setString('nombre', nombre);
    }
  }

  // Obtener el ID del usuario logueado actualmente
  static Future<String> obtenerMiUsuarioId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('usuarioId') ?? '';
  }

  // Obtener el nombre del usuario logueado
  static Future<String> obtenerMiNombre() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('nombre') ?? 'Usuario';
  }

  // Cerrar sesión limpiando la memoria
  static Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ==========================================
  // METODOS HTTP CONECTADOS A AWS
  // ==========================================

  // 1. POST - Registro tradicional con correo y contraseña
  Future<bool> registrarUsuario(String nombre, String correo, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/registro'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': nombre,
          'correo': correo,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        // Extraemos el ID dinámico que retorna AWS (o usamos el correo si AWS no envía ID)
        final usuarioId = data['usuarioId'] ?? data['id'] ?? correo;
        
        // Guardamos la sesión localmente
        await guardarSesionUsuario(
          usuarioId: usuarioId.toString(),
          correo: correo,
          nombre: nombre,
        );
        return true;
      }
      return false;
    } catch (e) {
      print('Error en el registro: $e');
      return false;
    }
  }

  // 2. POST - Login con Google
  Future<bool> loginConGoogle(String idToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': idToken}),
      );

      print('CÓDIGO DE AWS: ${response.statusCode}');
      print('RESPUESTA DE AWS: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Guardamos la sesión con la respuesta dinámica de AWS
        await guardarSesionUsuario(
          usuarioId: (data['usuarioId'] ?? data['id'] ?? data['sub'] ?? 'google_user').toString(),
          correo: (data['correo'] ?? data['email'] ?? '').toString(),
          nombre: (data['nombre'] ?? data['name'] ?? 'Usuario').toString(),
        );
        return true;
      }
      return false;
    } catch (e) {
      print('Error en login con Google: $e');
      return false;
    }
  }

  // 3. GET - Health Check (Nueva URL independiente)
  Future<bool> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('https://iqe7v3bpy4.execute-api.us-east-1.amazonaws.com/dev/health'),
      );

      if (response.statusCode == 200) {
        print('Health Check OK: ${response.body}');
        return true;
      } else {
        print('Health Check Falló con código: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error en healthCheck: $e');
      return false;
    }
  }
}