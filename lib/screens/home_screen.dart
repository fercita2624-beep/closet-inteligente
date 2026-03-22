import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import '../models/clima_data.dart';
import '../services/clima_service.dart';
import '../models/prenda.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/prenda_armario.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ClimaData? _clima;
  bool _cargando = true;
  Timer? _timer;
  List<PrendaArmario> _armario = [];

  @override
  void initState() {
    super.initState();
    _cargarClima();
    _cargarArmario();
    _timer = Timer.periodic(const Duration(minutes: 10), (_) => _cargarClima());
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  Future<void> _cargarClima() async {
    setState(() => _cargando = true);
    final clima = await ClimaService.obtenerClima();
    if (mounted) setState(() { _clima = clima; _cargando = false; });
  }

  Future<void> _cargarArmario() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('armario') ?? [];
    if (mounted) setState(() {
      _armario = raw.map((e) => PrendaArmario.fromJson(jsonDecode(e))).toList();
    });
  }

  List<PrendaArmario> _getOutfit(double temp) {
    return _armario.where((p) => temp >= p.tempMin && temp <= p.tempMax).take(3).toList();
  }

  String _getClimaEmoji(String desc) {
    final d = desc.toLowerCase();
    if (d.contains('lluvia') || d.contains('rain')) return '🌧️';
    if (d.contains('nube') || d.contains('cloud')) return '☁️';
    if (d.contains('sol') || d.contains('clear')) return '☀️';
    if (d.contains('nieve') || d.contains('snow')) return '❄️';
    if (d.contains('tormenta') || d.contains('storm')) return '⛈️';
    return '🌤️';
  }

  String _getRecomendacion(double temp) {
    if (temp < 5) return 'Frio extremo — abrigo grueso';
    if (temp < 12) return 'Muy frio — chamarra y sueter';
    if (temp < 18) return 'Fresco — sueter o sudadera';
    if (temp < 24) return 'Templado — jeans y camiseta';
    if (temp < 30) return 'Calido — ropa ligera';
    return 'Calor — camiseta y shorts';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final clima = _clima!;
    final outfit = _getOutfit(clima.temperatura);
    return RefreshIndicator(
      onRefresh: () async { await _cargarClima(); await _cargarArmario(); },
      color: Colors.purple,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Mi Closet', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  Row(children: [
                    const Icon(Icons.location_on, size: 12, color: Colors.purple),
                    const SizedBox(width: 2),
                    Text(clima.ciudad, style: TextStyle(fontSize: 12, color: Colors.purple.shade200)),
                  ]),
                ]),
                IconButton(icon: const Icon(Icons.refresh, color: Colors.purple), onPressed: _cargarClima),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade900, Colors.indigo.shade900],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.purple.withValues(alpha: 0.4)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_getClimaEmoji(clima.descripcion), style: const TextStyle(fontSize: 44)),
                const SizedBox(height: 8),
                Text('${clima.temperatura.toStringAsFixed(1)}°C',
                    style: const TextStyle(fontSize: 52, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(clima.descripcion.toUpperCase(),
                    style: TextStyle(fontSize: 12, color: Colors.purple.shade200, letterSpacing: 1.5)),
                const SizedBox(height: 14),
                Wrap(spacing: 8, runSpacing: 6, children: [
                  _chip('💧 ${clima.humedad.toInt()}%'),
                  _chip('🌡️ ${clima.sensacionTermica.toStringAsFixed(0)}°'),
                  _chip('💨 ${clima.viento.toStringAsFixed(1)} m/s'),
                ]),
              ]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                const Text('💡', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(child: Text(_getRecomendacion(clima.temperatura),
                    style: TextStyle(fontSize: 14, color: Colors.purple.shade100))),
              ]),
            ),
            const SizedBox(height: 20),
            Text('✨ Outfit sugerido para hoy',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple.shade100)),
            const SizedBox(height: 10),
            outfit.isEmpty
                ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                Icon(Icons.checkroom, color: Colors.purple.shade300),
                const SizedBox(width: 10),
                Expanded(child: Text('Agrega prendas a tu armario para ver outfits',
                    style: TextStyle(color: Colors.purple.shade200, fontSize: 13))),
              ]),
            )
                : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade900.withValues(alpha: 0.8), Colors.indigo.shade900.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.purple.withValues(alpha: 0.5)),
              ),
              child: Column(children: [
                Row(
                  children: outfit.map((p) => Expanded(
                    child: Column(children: [
                      Container(
                        height: 70,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: File(p.imagePath).existsSync()
                              ? Image.file(File(p.imagePath), fit: BoxFit.cover, width: double.infinity)
                              : Icon(Icons.checkroom, color: Colors.purple.shade300),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(p.nombre,
                          style: const TextStyle(fontSize: 9, color: Colors.white),
                          maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                    ]),
                  )).toList(),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                  ),
                  child: const Text('✓ De tu armario', style: TextStyle(color: Colors.greenAccent, fontSize: 11)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            Text('Prendas para ${clima.temperatura.toStringAsFixed(0)}°C',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 10),
            ...catalogoPrendas.map((p) {
              final v = evaluarPrenda(p['tempMin'] as double, p['tempMax'] as double, clima.temperatura);
              if (v == 'no_recomendada') return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
                ),
                child: Row(children: [
                  Text(p['emoji'] as String, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p['nombre'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white)),
                    Text(p['categoria'] as String, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: v == 'recomendada' ? Colors.green.withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      v == 'recomendada' ? '✓ Ideal' : '~ Ok',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                          color: v == 'recomendada' ? Colors.greenAccent : Colors.orange),
                    ),
                  ),
                ]),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    );
  }
}