import 'dart:async';
import 'dart:math' as math;
import 'dart:js_interop';
import 'package:web/web.dart' as web;

class ResultadoUbicacionZMQ {
  final bool permitido;
  final double? latitud;
  final double? longitud;
  final String municipioDetectado;
  final String mensaje;

  ResultadoUbicacionZMQ({
    required this.permitido,
    this.latitud,
    this.longitud,
    required this.municipioDetectado,
    required this.mensaje,
  });
}

class UbicacionZmqService {
  // Centro geográfico de la Zona Metropolitana de Querétaro
  static const double _latCentroQro = 20.5888;
  static const double _lngCentroQro = -100.3899;
  static const double _radioMaximoKm = 35.0; // Cubre Querétaro, Corregidora, El Marqués y Huimilpan

  static double _calcularDistanciaKm(double lat1, double lon1, double lat2, double lon2) {
    const double radioTierra = 6371.0;
    final double dLat = (lat2 - lat1) * (math.pi / 180.0);
    final double dLon = (lon2 - lon1) * (math.pi / 180.0);
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * (math.pi / 180.0)) *
            math.cos(lat2 * (math.pi / 180.0)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return radioTierra * c;
  }

  static String _estimarMunicipio(double lat, double lng) {
    if (lat < 20.55 && lng < -100.40) return 'Corregidora';
    if (lng > -100.32) return 'El Marqués';
    if (lat < 20.45) return 'Huimilpan';
    return 'Santiago de Querétaro';
  }

  static Future<ResultadoUbicacionZMQ> verificarUbicacionActual() async {
    final completer = Completer<ResultadoUbicacionZMQ>();

    try {
      final geolocation = web.window.navigator.geolocation;
      geolocation.getCurrentPosition(
        ((web.GeolocationPosition pos) {
          final double lat = pos.coords.latitude.toDouble();
          final double lng = pos.coords.longitude.toDouble();
          final double distancia = _calcularDistanciaKm(_latCentroQro, _lngCentroQro, lat, lng);

          if (distancia <= _radioMaximoKm) {
            final muni = _estimarMunicipio(lat, lng);
            completer.complete(ResultadoUbicacionZMQ(
              permitido: true,
              latitud: lat,
              longitud: lng,
              municipioDetectado: muni,
              mensaje: 'Ubicación verificada en $muni (${distancia.toStringAsFixed(1)} km del centro).',
            ));
          } else {
            completer.complete(ResultadoUbicacionZMQ(
              permitido: false,
              latitud: lat,
              longitud: lng,
              municipioDetectado: 'Fuera de ZMQ',
              mensaje: 'Estás a ${distancia.toStringAsFixed(1)} km de Querétaro. Solo se permiten publicaciones dentro de la Zona Metropolitana de Querétaro.',
            ));
          }
        }).toJS,
        ((web.GeolocationPositionError err) {
          completer.complete(ResultadoUbicacionZMQ(
            permitido: false,
            municipioDetectado: 'Sin permiso GPS',
            mensaje: 'Debes permitir el acceso a tu ubicación en el navegador para comprobar que estás en la Zona Metropolitana de Querétaro.',
          ));
        }).toJS,
      );
    } catch (e) {
      completer.complete(ResultadoUbicacionZMQ(
        permitido: false,
        municipioDetectado: 'Error GPS',
        mensaje: 'No se pudo verificar tu ubicación GPS.',
      ));
    }

    return completer.future;
  }
}