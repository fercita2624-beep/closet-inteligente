import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/prenda.dart';
import '../services/historial_service.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  List<Prenda> _historial = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final h = await HistorialService.cargar();
    if (mounted) setState(() { _historial = h; _cargando = false; });
  }

  Future<void> _limpiar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Limpiar historial'),
        content: const Text('¿Eliminar todo el historial de prendas?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmar == true) {
      await HistorialService.limpiar();
      _cargar();
    }
  }

  Color _getVeredictoColor(String v) {
    switch (v) {
      case 'recomendada': return Colors.green;
      case 'puede_servir': return Colors.orange;
      default: return Colors.red;
    }
  }

  String _getVeredictoLabel(String v) {
    switch (v) {
      case 'recomendada': return 'Recomendada';
      case 'puede_servir': return 'Puede servir';
      default: return 'No recomendada';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '📋 Historial',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                if (_historial.isNotEmpty)
                  TextButton(
                    onPressed: _limpiar,
                    child: const Text('Limpiar', style: TextStyle(color: Colors.red)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${_historial.length} prendas analizadas',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _cargando
                  ? const Center(child: CircularProgressIndicator())
                  : _historial.isEmpty
                      ? _buildVacio()
                      : RefreshIndicator(
                          onRefresh: _cargar,
                          child: ListView.builder(
                            itemCount: _historial.length,
                            itemBuilder: (_, i) => _buildItem(_historial[i]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('👕', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            'Sin prendas aún',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[600]),
          ),
          Text(
            'Escanea tu primera prenda',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(Prenda p) {
    final color = _getVeredictoColor(p.veredicto);
    final fmt = DateFormat('dd MMM · HH:mm', 'es_MX');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Text(p.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                Text(
                  fmt.format(p.fechaEscaneo),
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getVeredictoLabel(p.veredicto),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
