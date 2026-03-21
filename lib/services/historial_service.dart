import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prenda.dart';

class HistorialService {
  static const String _key = 'historial_prendas';

  static Future<List<Prenda>> cargar() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((e) => Prenda.fromJson(jsonDecode(e)))
        .toList()
        .reversed
        .toList();
  }

  static Future<void> guardar(Prenda prenda) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.add(jsonEncode(prenda.toJson()));
    // Máximo 50 entradas
    if (raw.length > 50) raw.removeAt(0);
    await prefs.setStringList(_key, raw);
  }

  static Future<void> limpiar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
