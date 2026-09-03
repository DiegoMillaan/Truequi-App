import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  // Base URL para Registro y Login Google
  static const String baseUrl = 'https://16663yaped.execute-api.us-east-1.amazonaws.com/dev';

  // 1. POST - Registro tradicional con correo y contraseña
  Future<bool> registrarUsuario(String nombre, String correo, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/registro'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': nombre,
          'correo': correo,
          'password': password
        }), 
      );
      
      return response.statusCode == 200 || response.statusCode == 201;
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
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error en login con Google: $e');
      return false;
    }
  }

  // 3. GET - Health Check (Nueva URL independiente)
  Future<bool> healthCheck() async {
    try {
      // Usamos directamente la URL con el dominio iqe7v3bpy4 que indicó Millán
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