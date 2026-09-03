import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart' as web;
import 'package:http/http.dart' as http;

class TruequiColors {
  static const Color purpura = Color(0xFF6B42E0);
  static const Color amarillo = Color(0xFFFFA800);
  static const Color textoOscuro = Color(0xFF101828);
}

class HomeWeb extends StatefulWidget {
  const HomeWeb({super.key});

  @override
  State<HomeWeb> createState() => _HomeWebState();
}

class _HomeWebState extends State<HomeWeb>
    with SingleTickerProviderStateMixin {
  static const String _loginUrl =
      'https://16663yaped.execute-api.us-east-1.amazonaws.com/dev/login';

  static const String _googleLoginUrl =
      'https://16663yaped.execute-api.us-east-1.amazonaws.com/dev/login/google';

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  Timer? _timer;
  double _animationValue = 0;

  @override
  void initState() {
    super.initState();

    _inicializarGoogle();
    

    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted) return;

      setState(() {
        _animationValue += 0.008;

        if (_animationValue > 2 * math.pi) {
          _animationValue = 0;
        }
      });
    });
  }

  Future<void> _inicializarGoogle() async {
    try {
      await _googleSignIn.initialize();

      debugPrint('GOOGLE SIGN-IN INICIALIZADO CORRECTAMENTE');
    } catch (e) {
      debugPrint('ERROR INICIALIZANDO GOOGLE: $e');
    }
  }
  Future<void> _loginConGoogle(
  BuildContext dialogContext,
  GoogleSignInAccount usuarioGoogle,
) async {
  try {
    debugPrint(
      'GOOGLE: usuario autenticado: ${usuarioGoogle.email}',
    );

    final autenticacion = usuarioGoogle.authentication;

    final idToken = autenticacion.idToken;

    if (idToken == null || idToken.isEmpty) {
      throw Exception(
        'Google no devolvió el ID token.',
      );
    }

    debugPrint(
      'GOOGLE: ID TOKEN OBTENIDO CORRECTAMENTE',
    );

    final response = await http.post(
      Uri.parse(_googleLoginUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'token': idToken,
      }),
    );

    debugPrint(
      'GOOGLE BACKEND STATUS: ${response.statusCode}',
    );

    debugPrint(
      'GOOGLE BACKEND RESPONSE: ${response.body}',
    );

    Map<String, dynamic> data = {};

    try {
      if (response.body.isNotEmpty) {
        data = jsonDecode(response.body);
      }
    } catch (_) {}

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      final mensaje =
          data['message'] ??
          data['mensaje'] ??
          'Login con Google exitoso';

      if (!dialogContext.mounted) return;

      Navigator.of(dialogContext).pop();

      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(
          content: Text(
            mensaje.toString(),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      final mensaje =
          data['message'] ??
          data['mensaje'] ??
          data['error'] ??
          'No se pudo iniciar sesión con Google.';

      if (!dialogContext.mounted) return;

      ScaffoldMessenger.of(dialogContext).showSnackBar(
        SnackBar(
          content: Text(
            mensaje.toString(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    debugPrint(
      'ERROR LOGIN GOOGLE: $e',
    );

    if (!dialogContext.mounted) return;

    ScaffoldMessenger.of(dialogContext).showSnackBar(
      SnackBar(
        content: Text(
          'Error al iniciar sesión con Google: $e',
        ),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ============================================================
  // LOGIN TRADICIONAL
  // ============================================================

  void _mostrarLogin() {
    final correoController = TextEditingController();
    final passwordController = TextEditingController();

    bool cargando = false;
    bool cargandoGoogle = false;
    bool ocultarPassword = true;
    String? error;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> iniciarSesion() async {
  final correo = correoController.text.trim();
  final password = passwordController.text;

  if (correo.isEmpty || password.isEmpty) {
    setModalState(() {
      error = 'Completa todos los campos.';
    });
    return;
  }

  setModalState(() {
    cargando = true;
    error = null;
  });

  try {
    final response = await http.post(
      Uri.parse(_loginUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'correo': correo,
        'password': password,
      }),
    );

    Map<String, dynamic> data = {};

    try {
      if (response.body.isNotEmpty) {
        data = jsonDecode(response.body);
      }
    } catch (_) {
      data = {};
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      final mensaje =
          data['message'] ??
          data['mensaje'] ??
          data['msg'] ??
          'Inicio de sesión exitoso';

      // Primero terminamos el estado de carga.
     if (!dialogContext.mounted) return;

Navigator.of(dialogContext).pop();

if (mounted) {
  ScaffoldMessenger.of(this.context).showSnackBar(
    SnackBar(
      content: Text(mensaje.toString()),
      backgroundColor: Colors.green,
    ),
  );
}

      return;
    }

    final mensaje =
        data['message'] ??
        data['mensaje'] ??
        data['error'] ??
        'Correo o contraseña incorrectos.';

    if (dialogContext.mounted) {
      setModalState(() {
        error = mensaje.toString();
        cargando = false;
      });
    }
  } catch (e) {
    debugPrint('ERROR LOGIN: $e');

    if (dialogContext.mounted) {
      setModalState(() {
        error = 'No se pudo conectar con el servidor.';
        cargando = false;
      });
    }
  }
}

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 30,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 460,
                ),
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 35,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ==================================================
                        // ENCABEZADO
                        // ==================================================

                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: TruequiColors.purpura.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.swap_horiz_rounded,
                                color: TruequiColors.purpura,
                                size: 28,
                              ),
                            ),

                            const SizedBox(width: 14),

                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Iniciar sesión',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: TruequiColors.textoOscuro,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Bienvenido a Truequi',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            IconButton(
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                              },
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),

                        const SizedBox(height: 25),

                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Ingresa a tu cuenta para continuar.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ==================================================
                        // CORREO
                        // ==================================================

                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Correo electrónico',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: TruequiColors.textoOscuro,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        TextField(
                          controller: correoController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'correo@ejemplo.com',
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8F8FB),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: TruequiColors.purpura,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // ==================================================
                        // PASSWORD
                        // ==================================================

                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Contraseña',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: TruequiColors.textoOscuro,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        TextField(
                          controller: passwordController,
                          obscureText: ocultarPassword,
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setModalState(() {
                                  ocultarPassword = !ocultarPassword;
                                });
                              },
                              icon: Icon(
                                ocultarPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8F8FB),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: TruequiColors.purpura,
                                width: 1.5,
                              ),
                            ),
                          ),
                          onSubmitted: (_) {
                            if (!cargando) {
                              iniciarSesion();
                            }
                          },
                        ),

                        const SizedBox(height: 18),

                        // ==================================================
                        // ERROR
                        // ==================================================

                        if (error != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    error!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],

                        // ==================================================
                        // LOGIN TRADICIONAL
                        // ==================================================

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: cargando || cargandoGoogle
                                ? null
                                : iniciarSesion,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: TruequiColors.purpura,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: cargando
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Iniciar sesión',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        // ==================================================
                        // SEPARADOR "O"
                        // ==================================================

                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                color: Colors.grey.shade200,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              child: Text(
                                'o',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: Colors.grey.shade200,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // ==================================================
                        // GOOGLE LOGIN
                        // ==================================================

                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              IgnorePointer(
                                ignoring: cargando || cargandoGoogle,
                                child: web.renderButton(
                                  configuration:
                                      web.GSIButtonConfiguration(
                                    type: web.GSIButtonType.standard,
                                    theme: web.GSIButtonTheme.outline,
                                    size: web.GSIButtonSize.large,
                                    text: web.GSIButtonText.continueWith,
                                    shape: web.GSIButtonShape.pill,
                                    logoAlignment:
                                        web.GSIButtonLogoAlignment.left,
                                    minimumWidth: 360,
                                    locale: 'es',
                                  ),
                                ),
                              ),

                              if (cargandoGoogle)
                                Container(
                                  width: double.infinity,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.88),
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ==================================================
                        // REGISTRO
                        // ==================================================

                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                            children: [
                              const TextSpan(
                                text: '¿No tienes cuenta? ',
                              ),
                              TextSpan(
                                text: 'Regístrate',
                                style: const TextStyle(
                                  color: TruequiColors.purpura,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      correoController.dispose();
      passwordController.dispose();
    });
  }

  // ============================================================
  // LOGIN CON GOOGLE
  // ============================================================

  Future<void> _procesarLoginGoogle(
    BuildContext dialogContext,
    void Function(void Function()) setModalState,
  ) async {
    setModalState(() {
      // El estado visual se controla desde el botón.
    });

    try {
      debugPrint('GOOGLE: esperando autenticación...');

      GoogleSignInAccount? usuarioGoogle;

      final completer = Completer<GoogleSignInAccount?>();

      late StreamSubscription<GoogleSignInAuthenticationEvent>
          subscription;

      subscription = _googleSignIn.authenticationEvents.listen(
        (event) {
          if (event is GoogleSignInAuthenticationEventSignIn) {
            if (!completer.isCompleted) {
              completer.complete(event.user);
            }
          }
        },
        onError: (Object error) {
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        },
      );

      try {
        // El botón oficial de Google inicia el proceso.
        // Esperamos brevemente a que el evento de autenticación
        // llegue al stream.
        usuarioGoogle = await completer.future.timeout(
          const Duration(seconds: 120),
        );
      } finally {
        await subscription.cancel();
      }

      if (usuarioGoogle == null) {
        throw Exception('No se obtuvo la cuenta de Google.');
      }

      debugPrint(
        'GOOGLE: usuario autenticado: ${usuarioGoogle.email}',
      );

      final autenticacion = await usuarioGoogle.authentication;

      final idToken = autenticacion.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception(
          'Google no devolvió un ID token.',
        );
      }

      debugPrint('GOOGLE: ID token obtenido correctamente.');

      // ==========================================================
      // ENVIAR ID TOKEN AL BACKEND
      // ==========================================================

      final response = await http.post(
        Uri.parse(_googleLoginUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'token': idToken,
        }),
      );

      Map<String, dynamic> data = {};

      try {
        if (response.body.isNotEmpty) {
          data = jsonDecode(response.body);
        }
      } catch (_) {
        data = {};
      }

      debugPrint(
        'GOOGLE BACKEND STATUS: ${response.statusCode}',
      );

      debugPrint(
        'GOOGLE BACKEND RESPONSE: ${response.body}',
      );

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        final mensaje =
            data['message'] ??
            data['mensaje'] ??
            'Login con Google exitoso';

        if (!dialogContext.mounted) return;

        Navigator.of(dialogContext).pop();

        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(
            content: Text(
              mensaje.toString(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final mensaje =
            data['message'] ??
            data['mensaje'] ??
            data['error'] ??
            'No se pudo iniciar sesión con Google.';

        if (!dialogContext.mounted) return;

        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(
            content: Text(
              mensaje.toString(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on TimeoutException {
      if (!dialogContext.mounted) return;

      ScaffoldMessenger.of(dialogContext).showSnackBar(
        const SnackBar(
          content: Text(
            'La autenticación con Google tardó demasiado.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      debugPrint('ERROR GOOGLE LOGIN: $e');

      if (!dialogContext.mounted) return;

      ScaffoldMessenger.of(dialogContext).showSnackBar(
        SnackBar(
          content: Text(
            'Error al iniciar sesión con Google: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // HOME
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      body: Stack(
        children: [
          // ==========================================================
          // FONDOS ANIMADOS
          // ==========================================================

          Positioned(
            top: -180 + math.sin(_animationValue) * 30,
            right: -120 + math.cos(_animationValue) * 30,
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: TruequiColors.purpura.withOpacity(0.16),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 80,
                  sigmaY: 80,
                ),
                child: const SizedBox(),
              ),
            ),
          ),

          Positioned(
            bottom: -180 + math.cos(_animationValue) * 35,
            left: -120 + math.sin(_animationValue) * 35,
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: TruequiColors.amarillo.withOpacity(0.12),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 80,
                  sigmaY: 80,
                ),
                child: const SizedBox(),
              ),
            ),
          ),

          // ==========================================================
          // CONTENIDO
          // ==========================================================

          CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                elevation: 0,
                backgroundColor: Colors.white.withOpacity(0.86),
                surfaceTintColor: Colors.transparent,
                toolbarHeight: 82,
                titleSpacing: 30,
                title: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: TruequiColors.purpura,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.swap_horiz_rounded,
                        color: Colors.white,
                        size: 27,
                      ),
                    ),

                    const SizedBox(width: 12),

                    const Text(
                      'Truequi',
                      style: TextStyle(
                        color: TruequiColors.textoOscuro,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Explorar',
                      style: TextStyle(
                        color: TruequiColors.textoOscuro,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.add_circle_outline,
                      size: 19,
                    ),
                    label: const Text('Subir artículo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: TruequiColors.purpura,
                      side: BorderSide(
                        color: TruequiColors.purpura.withOpacity(0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Padding(
                    padding: const EdgeInsets.only(right: 30),
                    child: ElevatedButton(
                      onPressed: _mostrarLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TruequiColors.purpura,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Iniciar sesión',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // ========================================================
              // BUSCADOR
              // ========================================================

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    60,
                    50,
                    60,
                    20,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 800,
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText:
                              '¿Qué estás buscando?',
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.grey,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding:
                              const EdgeInsets.symmetric(
                            vertical: 18,
                            horizontal: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(18),
                            borderSide: const BorderSide(
                              color: TruequiColors.purpura,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ========================================================
              // HERO
              // ========================================================

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    60,
                    20,
                    60,
                    30,
                  ),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(
                      minHeight: 260,
                    ),
                    padding: const EdgeInsets.all(45),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF6B42E0),
                          Color(0xFF8A6BE8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Intercambia lo que ya no necesitas',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                  height: 1.15,
                                ),
                              ),

                              const SizedBox(height: 15),

                              Text(
                                'Encuentra nuevos artículos y dale una segunda vida a lo que ya tienes.',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                              ),

                              const SizedBox(height: 25),

                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Colors.white,
                                  foregroundColor:
                                      TruequiColors.purpura,
                                  elevation: 0,
                                  padding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 25,
                                    vertical: 16,
                                  ),
                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(
                                      13,
                                    ),
                                  ),
                                ),
                                child: const Text(
                                  'Explorar artículos',
                                  style: TextStyle(
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 40),

                        Container(
                          width: 210,
                          height: 170,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius:
                                BorderRadius.circular(25),
                          ),
                          child: const Icon(
                            Icons.swap_horizontal_circle_outlined,
                            color: Colors.white,
                            size: 110,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ========================================================
              // CATEGORÍAS
              // ========================================================

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 60,
                    vertical: 10,
                  ),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      'Todos',
                      'Electrónica',
                      'Hogar',
                      'Ropa',
                      'Coleccionables',
                      'Deportes',
                      'Libros',
                    ].map((categoria) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.grey.shade200,
                          ),
                        ),
                        child: Text(
                          categoria,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // ========================================================
              // TÍTULO PRODUCTOS
              // ========================================================

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    60,
                    45,
                    60,
                    20,
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Artículos recientes',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: TruequiColors.textoOscuro,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Ver todos',
                          style: TextStyle(
                            color: TruequiColors.purpura,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ========================================================
              // PRODUCTOS
              // ========================================================

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  60,
                  0,
                  60,
                  60,
                ),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final productos = [
                        ['Laptop', 'Electrónica'],
                        ['Bicicleta', 'Deportes'],
                        ['Libros', 'Libros'],
                        ['Videojuego', 'Entretenimiento'],
                        ['Audífonos', 'Electrónica'],
                        ['Mochila', 'Ropa'],
                        ['Cámara', 'Electrónica'],
                        ['Silla', 'Hogar'],
                        ['Colección', 'Coleccionables'],
                        ['Monitor', 'Electrónica'],
                        ['Balón', 'Deportes'],
                        ['Lámpara', 'Hogar'],
                      ];

                      return _TarjetaProductoWeb(
                        titulo: productos[index][0],
                        categoria: productos[index][1],
                      );
                    },
                    childCount: 12,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 290,
                    mainAxisExtent: 310,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ====================================================================
// TARJETA DE PRODUCTO
// ====================================================================

class _TarjetaProductoWeb extends StatefulWidget {
  final String titulo;
  final String categoria;

  const _TarjetaProductoWeb({
    required this.titulo,
    required this.categoria,
  });

  @override
  State<_TarjetaProductoWeb> createState() =>
      _TarjetaProductoWebState();
}

class _TarjetaProductoWebState
    extends State<_TarjetaProductoWeb> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          hover = true;
        });
      },
      onExit: (_) {
        setState(() {
          hover = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.identity()
          ..translate(0.0, hover ? -5.0 : 0.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                hover ? 0.12 : 0.05,
              ),
              blurRadius: hover ? 22 : 12,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1EFF8),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 65,
                    color: Color(0xFFB8B1CF),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(17),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.categoria,
                    style: const TextStyle(
                      color: TruequiColors.purpura,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    widget.titulo,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: TruequiColors.textoOscuro,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Icon(
                        Icons.swap_horiz,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'Disponible para intercambio',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class GoogleLoginButton extends StatefulWidget {
  final Future<void> Function(GoogleSignInAccount user) onLogin;

  const GoogleLoginButton({
    super.key,
    required this.onLogin,
  });

  @override
  State<GoogleLoginButton> createState() => _GoogleLoginButtonState();
}

class _GoogleLoginButtonState extends State<GoogleLoginButton> {
  StreamSubscription<GoogleSignInAuthenticationEvent>?
      _authenticationSubscription;

  bool procesando = false;

  @override
  void initState() {
    super.initState();

    _escucharGoogle();
  }

  void _escucharGoogle() {
    _authenticationSubscription =
        GoogleSignIn.instance.authenticationEvents.listen(
      (event) async {
        if (event is GoogleSignInAuthenticationEventSignIn) {
          if (procesando) return;

          setState(() {
            procesando = true;
          });

          try {
            await widget.onLogin(event.user);
          } finally {
            if (mounted) {
              setState(() {
                procesando = false;
              });
            }
          }
        }
      },
      onError: (Object error) {
        debugPrint(
          'ERROR EN AUTENTICACIÓN DE GOOGLE: $error',
        );

        if (mounted) {
          setState(() {
            procesando = false;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _authenticationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IgnorePointer(
          ignoring: procesando,
          child: web.renderButton(
            configuration: web.GSIButtonConfiguration(
              type: web.GSIButtonType.standard,
              theme: web.GSIButtonTheme.outline,
              size: web.GSIButtonSize.large,
              text: web.GSIButtonText.continueWith,
              shape: web.GSIButtonShape.pill,
              logoAlignment: web.GSIButtonLogoAlignment.left,
              minimumWidth: 360,
              locale: 'es',
            ),
          ),
        ),

        if (procesando)
          Container(
            width: 360,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}