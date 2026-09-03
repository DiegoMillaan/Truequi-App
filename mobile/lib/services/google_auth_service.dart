import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  bool _isInitialized = false;

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await GoogleSignIn.instance.initialize(
        serverClientId: '675434790186-c149sqg826b8ki0tpv4dq4j778mcg2sh.apps.googleusercontent.com',
      );
      _isInitialized = true;
    }
  }

  Future<dynamic> signInWithGoogle() async {
    await _ensureInitialized();
    try {
      print("DEBUG: Limpiando sesión anterior...");
      await GoogleSignIn.instance.signOut();

      print("DEBUG: Intentando abrir el selector de Google...");
      final googleUser = await GoogleSignIn.instance.authenticate();
      
      if (googleUser != null) {
        print("DEBUG: Usuario seleccionado: ${googleUser.email}");
        final googleAuth = googleUser.authentication;
        final String? idToken = googleAuth.idToken;
        print("DEBUG: ID Token obtenido correctamente");
        return googleUser;
      } else {
        print("DEBUG: El usuario canceló el selector o devolvió null.");
        return null;
      }
    } catch (error) {
      print("DEBUG ERROR CRÍTICO: $error");
      return null;
    }
  }

  Future<void> signOut() async {
    await _ensureInitialized();
    await GoogleSignIn.instance.signOut();
  }
}