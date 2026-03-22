import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/clima_data.dart';

class ClimaService {
  static const String _apiKey = '90df881dcd10a7f25d45eb1055135db9';

  static Future<ClimaData> obtenerClima() async {
    try {
      // Pedir permiso de ubicación
      LocationPermission permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }

      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        return ClimaData.demo();
      }

      // Obtener ubicación actual
      final posicion = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Obtener clima por coordenadas GPS
      final uri = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather'
            '?lat=${posicion.latitude}&lon=${posicion.longitude}'
            '&appid=$_apiKey&units=metric&lang=es',
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        return ClimaData.fromJson(jsonDecode(response.body));
      } else {
        return ClimaData.demo();
      }
    } catch (e) {
      return ClimaData.demo();
    }
  }

  static String tipoClima(String descripcion) {
    final d = descripcion.toLowerCase();
    if (d.contains('lluvia') || d.contains('rain')) return 'lluvia';
    if (d.contains('nube') || d.contains('cloud')) return 'nublado';
    if (d.contains('sol') || d.contains('clear')) return 'soleado';
    if (d.contains('niebla') || d.contains('fog')) return 'niebla';
    if (d.contains('nieve') || d.contains('snow')) return 'nieve';
    if (d.contains('tormenta') || d.contains('storm')) return 'tormenta';
    return 'nublado';
  }
}