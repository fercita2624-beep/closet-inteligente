import 'package:flutter/material.dart';
import 'dart:async';
import '../models/clima_data.dart';
import '../services/clima_service.dart';
import '../models/prenda.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ClimaData? _clima;
  bool _cargando = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _cargarClima();
    // Actualizar cada 10 minutos
    _timer = Timer.periodic(const Duration(minutes: 10), (_) => _cargarClima());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _cargarClima() async {
    setState(() => _cargando = true);
    final clima = await ClimaService.obtenerClima();
    if (mounted) setState(() { _clima = clima; _cargando = false; });
  }

  String _getClimaEmoji(String descripcion) {
    final tipo = ClimaService.tipoClima(descripcion);
    switch (tipo) {
      case 'lluvia': return '🌧️';
      case 'nublado': return '☁️';
      case 'soleado': return '☀️';
      case 'niebla': return '🌫️';
      case 'nieve': return '❄️';
      case 'tormenta': return '⛈️';
      default: return '🌤️';
    }
  }

  Color _getTempColor(double temp) {
    if (temp < 10) return const Color(0xFF5C9BD6);
    if (temp < 18) return const Color(0xFF7FB3D3);
    if (temp < 25) return const Color(0xFF4CAF50);
    if (temp < 32) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  String _getRecomendacion(double temp) {
    if (temp < 5) return 'Frío extremo — abrigo grueso y bufanda';
    if (temp < 12) return 'Muy frío — chamarra y suéter';
    if (temp < 18) return 'Fresco — sudadera o suéter ligero';
    if (temp < 24) return 'Templado — jeans y camiseta';
    if (temp < 30) return 'Cálido — ropa ligera';
    return 'Calor — camiseta y shorts';
  }

  List<Map<String, dynamic>> _getPrendasRecomendadas(double temp) {
    return catalogoPrendas.map((p) {
      final v = evaluarPrenda(p['tempMin'] as double, p['tempMax'] as double, temp);
      return {...p, 'veredicto': v};
    }).where((p) => p['veredicto'] != 'no_recomendada')
      .toList()
      ..sort((a, b) {
        const orden = {'recomendada': 0, 'puede_servir': 1};
        return (orden[a['veredicto']] ?? 2).compareTo(orden[b['veredicto']] ?? 2);
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final clima = _clima!;
    final tempColor = _getTempColor(clima.temperatura);

    return RefreshIndicator(
      onRefresh: _cargarClima,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '👗 Mi Closet',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      clima.ciudad,
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _cargarClima,
                  color: Colors.grey[600],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tarjeta de clima principal
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: tempColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getClimaEmoji(clima.descripcion),
                    style: const TextStyle(fontSize: 48),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${clima.temperatura.toStringAsFixed(1)}°C',
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    clima.descripcion.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _climaChip('💧 ${clima.humedad.toInt()}%'),
                      const SizedBox(width: 8),
                      _climaChip('🌡️ Sensación ${clima.sensacionTermica.toStringAsFixed(0)}°'),
                      const SizedBox(width: 8),
                      _climaChip('💨 ${clima.viento.toStringAsFixed(1)} m/s'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Recomendación de outfit
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Text('💡', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getRecomendacion(clima.temperatura),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Prendas sugeridas
            Text(
              'Prendas para hoy',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            ..._getPrendasRecomendadas(clima.temperatura)
                .map((p) => _prendaItem(p)),
          ],
        ),
      ),
    );
  }

  Widget _climaChip(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(texto, style: const TextStyle(color: Colors.white, fontSize: 11)),
    );
  }

  Widget _prendaItem(Map<String, dynamic> prenda) {
    final esRecomendada = prenda['veredicto'] == 'recomendada';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: esRecomendada ? Colors.green.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Row(
        children: [
          Text(prenda['emoji'] as String, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prenda['nombre'] as String,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                Text(
                  prenda['categoria'] as String,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: esRecomendada ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              esRecomendada ? '✓ Ideal' : '~ Ok',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: esRecomendada ? Colors.green.shade700 : Colors.orange.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
