import 'dart:async';
import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class GoogleAuthService {
  static const String clientId =
      '675434790186-c149sqg826b8ki0tpv4dq4j778mcg2sh.apps.googleusercontent.com';

  static const String loginUrl =
      'https://16663yaped.execute-api.us-east-1.amazonaws.com/dev/login/google';

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  StreamSubscription<GoogleSignInAuthenticationEvent>? _authSubscription;

  Future<void> initialize() async {
    await _googleSignIn.initialize(
      clientId: clientId,
    );
  }

  void listenToAuthentication({
    required void Function(Map<String, dynamic> usuario) onSuccess,
    required void Function(String mensaje) onError,
  }) {
    _authSubscription?.cancel();

    _authSubscription =
        _googleSignIn.authenticationEvents.listen((event) async {
      if (event is GoogleSignInAuthenticationEventSignIn) {
        try {
          final GoogleSignInAccount account = event.user;

          final GoogleSignInAuthentication authentication =
              account.authentication;

          final String? idToken = authentication.idToken;

          if (idToken == null || idToken.isEmpty) {
            onError('Google no devolvió un ID Token.');
            return;
          }

          final response = await http.post(
            Uri.parse(loginUrl),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'token': idToken,
            }),
          );

          if (response.statusCode >= 200 &&
              response.statusCode < 300) {
            final Map<String, dynamic> data =
                jsonDecode(response.body);

            if (data['status'] == 'success') {
              final usuario =
                  Map<String, dynamic>.from(data['usuario'] ?? {});

              onSuccess(usuario);
            } else {
              onError(
                data['message'] ??
                    'El servidor rechazó el inicio de sesión.',
              );
            }
          } else {
            onError(
              'Error del servidor (${response.statusCode}).',
            );
          }
        } catch (e) {
          onError(
            'Ocurrió un error al iniciar sesión con Google.',
          );
        }
      }
    }, onError: (error) {
      onError(
        'No se pudo iniciar sesión con Google.',
      );
    });
  }

  Future<void> dispose() async {
    await _authSubscription?.cancel();
    _authSubscription = null;
  }
}