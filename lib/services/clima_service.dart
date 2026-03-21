import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/clima_data.dart';

class ClimaService {
  // INSTRUCCIONES PARA OBTENER TU API KEY GRATIS:
  // 1. Ve a https://openweathermap.org/api
  // 2. Crea una cuenta gratuita
  // 3. Ve a "My API Keys" y copia tu key
  // 4. Pégala aquí abajo
  static const String _apiKey = 'TU_API_KEY_AQUI';

  // Cambia esto por tu ciudad
  static const String _ciudad = 'Mexico City,MX';

  static bool get _tieneApiKey => _apiKey != 'TU_API_KEY_AQUI';

  static Future<ClimaData> obtenerClima() async {
    // Si no hay API key, usa datos demo realistas
    if (!_tieneApiKey) {
      await Future.delayed(const Duration(milliseconds: 800)); // Simula carga
      return ClimaData.demo();
    }

    try {
      final uri = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather'
        '?q=$_ciudad&appid=$_apiKey&units=metric&lang=es',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        return ClimaData.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Error ${response.statusCode}');
      }
    } catch (e) {
      // Si falla la API, regresa demo
      return ClimaData.demo();
    }
  }

  // Detecta tipo de clima para el icono animado
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
