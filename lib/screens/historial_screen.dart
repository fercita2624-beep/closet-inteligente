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
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    final h = await HistorialService.cargar();
    if (mounted) setState(() { _historial = h; _cargando = false; });
  }

  Future<void> _limpiar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Limpiar historial', style: TextStyle(color: Colors.white)),
        content: const Text('Eliminar todo el historial?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmar == true) { await HistorialService.limpiar(); _cargar(); }
  }

  Color _getColor(String v) {
    if (v == 'recomendada') return Colors.greenAccent;
    if (v == 'puede_servir') return Colors.orange;
    return Colors.redAccent;
  }

  String _getLabel(String v) {
    if (v == 'recomendada') return 'Recomendada';
    if (v == 'puede_servir') return 'Puede servir';
    return 'No recomendada';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Historial', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  if (_historial.isNotEmpty)
                    TextButton(onPressed: _limpiar, child: const Text('Limpiar', style: TextStyle(color: Colors.redAccent))),
                ],
              ),
              Text('${_historial.length} prendas analizadas', style: TextStyle(fontSize: 13, color: Colors.purple.shade300)),
              const SizedBox(height: 16),
              Expanded(
                child: _cargando
                    ? const Center(child: CircularProgressIndicator(color: Colors.purple))
                    : _historial.isEmpty
                    ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 56, color: Colors.purple.withValues(alpha: 0.4)),
                    const SizedBox(height: 12),
                    Text('Sin prendas aun', style: TextStyle(fontSize: 18, color: Colors.purple.shade200)),
                    Text('Escanea tu primera prenda', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                  ],
                ))
                    : RefreshIndicator(
                  onRefresh: _cargar,
                  color: Colors.purple,
                  child: ListView.builder(
                    itemCount: _historial.length,
                    itemBuilder: (_, i) {
                      final p = _historial[i];
                      final color = _getColor(p.veredicto);
                      final fmt = DateFormat('dd MMM HH:mm', 'es_MX');
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A2E),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
                        ),
                        child: Row(children: [
                          Text(p.emoji, style: const TextStyle(fontSize: 28)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.white)),
                            Text(fmt.format(p.fechaEscaneo), style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                          ])),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(_getLabel(p.veredicto), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                          ),
                        ]),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}