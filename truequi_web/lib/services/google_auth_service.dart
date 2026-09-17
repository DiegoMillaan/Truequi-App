import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class GoogleAuthService {
  // Client ID de Truequi
  static const String clientId = '675434790186-c149sqg826b8ki0tpv4dq4j778mcg2sh.apps.googleusercontent.com';

  // URL OFICIAL DE TU BACKEND BLINDADO EN AWS
  static const String loginUrl = 'https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/login/google';

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _authSubscription;

  Future<void> initialize() async {
    await _googleSignIn.initialize(clientId: clientId);
  }

  void listenToAuthentication({
    required void Function(Map<String, dynamic> usuario) onSuccess,
    required void Function(String mensaje) onError,
  }) {
    _authSubscription?.cancel();

    _authSubscription = _googleSignIn.authenticationEvents.listen((event) async {
      if (event is GoogleSignInAuthenticationEventSignIn) {
        try {
          final GoogleSignInAccount account = event.user;
          final GoogleSignInAuthentication authentication = await account.authentication;
          final String? idToken = authentication.idToken;

          if (idToken == null || idToken.isEmpty) {
            onError('Google no devolvió un ID Token.');
            return;
          }

          final response = await http.post(
            Uri.parse(loginUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'token': idToken}),
          );

          final Map<String, dynamic> data = jsonDecode(response.body);

          if (response.statusCode >= 200 && response.statusCode < 300) {
            onSuccess(Map<String, dynamic>.from(data['usuario'] ?? {}));
          } else {
            // Captura los errores 400 que configuraste en tu handler.py
            onError(data['error'] ?? data['message'] ?? 'Acceso denegado por el servidor.');
          }
        } catch (e) {
          debugPrint("Error de conexión: $e");
          onError('Ocurrió un error al conectar con el servidor AWS.');
        }
      }
    }, onError: (error) {
      onError('Se canceló o falló el inicio de sesión con Google.');
    });
  }

  Future<void> dispose() async {
    await _authSubscription?.cancel();
    _authSubscription = null;
  }
}