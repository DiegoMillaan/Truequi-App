import 'dart:convert';
import 'package:http/http.dart' as http;

class ProductoService {

  // 1. GET - Obtener productos
  Future<List<dynamic>> obtenerProductos() async {
    try {
      final response = await http.get(Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/productos'));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al cargar productos: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en obtenerProductos: $e');
      return [];
    }
  }

  // 2. POST - Crear producto
  Future<bool> crearProducto(Map<String, dynamic> productoData) async {
    try {
      final response = await http.post(
        Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/productos'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(productoData),
      );
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error en crearProducto: $e');
      return false;
    }
  }

  // 3. GET - Obtener URL para subir imágenes
  Future<String?> obtenerUploadUrl() async {
    try {
      final response = await http.get(Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/productos/upload-url'));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['uploadUrl']; 
      }
      return null;
    } catch (e) {
      print('Error en obtenerUploadUrl: $e');
      return null;
    }
  }

  // 4. GET - Health Check (Verificar conexión)
  Future<bool> healthCheck() async {
    try {
      final response = await http.get(Uri.parse('https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/health'));
      
      if (response.statusCode == 200) {
        print('Backend conectado y funcionando (Health Check OK)');
        return true;
      }
      return false;
    } catch (e) {
      print('Error en healthCheck: $e');
      return false;
    }
  }
}