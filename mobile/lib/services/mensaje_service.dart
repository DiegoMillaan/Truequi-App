import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class MensajeService {
  final String _baseUrl = 'https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev';

  // Obtener historial de mensajes desde AWS DynamoDB
  Future<List<dynamic>> obtenerMensajes({required String deUsuarioId, String? paraUsuarioId}) async {
    try {
      final uri = Uri.parse('$_baseUrl/mensajes').replace(queryParameters: {
        'deUsuarioId': deUsuarioId,
        if (paraUsuarioId != null) 'paraUsuarioId': paraUsuarioId,
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Manejo seguro del envoltorio de DynamoDB
        if (data is Map<String, dynamic> && data.containsKey('Items')) {
          return data['Items'] as List<dynamic>;
        } else if (data is Map<String, dynamic> && data.containsKey('mensajes')) {
          return data['mensajes'] as List<dynamic>;
        } else if (data is List) {
          return data;
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error al obtener mensajes de AWS: $e');
      return [];
    }
  }

  // Enviar un nuevo mensaje a AWS
  Future<bool> enviarMensaje({
    required String deUsuarioId,
    required String paraUsuarioId,
    required String texto,
    String? productoId,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/mensajes');
      final payload = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'deUsuarioId': deUsuarioId,
        'paraUsuarioId': paraUsuarioId,
        'texto': texto.trim(),
        'timestamp': DateTime.now().toIso8601String(),
        if (productoId != null) 'productoId': productoId,
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error al enviar mensaje a AWS: $e');
      return false;
    }
  }
}