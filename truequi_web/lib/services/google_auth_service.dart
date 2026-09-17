import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class GoogleAuthService {
  // El Client ID exclusivo para la Web que configuramos en Google Cloud
  static const String clientId = '765285641470-jh7if1qr7a9hvfmofs6ume22vgu8v64m.apps.googleusercontent.com';

  // URL OFICIAL DE TU BACKEND DE AUTH EN AWS
  static const String loginUrl = 'https://16663yaped.execute-api.us-east-1.amazonaws.com/dev/login/google';

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

  // ==========================================
  // NUEVO: MÉTODO PARA CERRAR SESIÓN
  // ==========================================
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Error al cerrar sesión de Google: $e');
    }
  }

  Future<void> dispose() async {
    await _authSubscription?.cancel();
    _authSubscription = null;
  }
}