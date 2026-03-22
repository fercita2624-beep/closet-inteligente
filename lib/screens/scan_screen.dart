import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/prenda.dart';
import '../models/clima_data.dart';
import '../services/clima_service.dart';
import '../services/historial_service.dart';
import '../services/remove_bg_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  File? _imagen;
  bool _analizando = false;
  Map<String, dynamic>? _resultado;
  ClimaData? _clima;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() { super.initState(); _cargarClima(); }

  Future<void> _cargarClima() async {
    final c = await ClimaService.obtenerClima();
    if (mounted) setState(() => _clima = c);
  }

  Future<Map<String, dynamic>> _analizarImagen(File imagen) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    final idx = DateTime.now().millisecondsSinceEpoch % catalogoPrendas.length;
    return Map<String, dynamic>.from(catalogoPrendas[idx]);
  }

  Future<void> _tomarFoto(ImageSource fuente) async {
    try {
      final XFile? foto = await _picker.pickImage(source: fuente, imageQuality: 80, maxWidth: 800);
      if (foto == null) return;
      if (!mounted) return;

      setState(() { _imagen = File(foto.path); _analizando = true; _resultado = null; });

      // Quitar fondo automáticamente
      final sinFondo = await RemoveBgService.quitarFondo(foto.path);
      if (sinFondo != null && mounted) {
        setState(() => _imagen = File(sinFondo));
      }

      final analisis = await _analizarImagen(_imagen!);
      if (_clima != null) {
        final veredicto = evaluarPrenda(
          analisis['tempMin'] as double,
          analisis['tempMax'] as double,
          _clima!.temperatura,
        );
        analisis['veredicto'] = veredicto;
        await HistorialService.guardar(Prenda(
          nombre: analisis['nombre'] as String,
          emoji: analisis['emoji'] as String,
          tempMin: analisis['tempMin'] as double,
          tempMax: analisis['tempMax'] as double,
          categoria: analisis['categoria'] as String,
          fechaEscaneo: DateTime.now(),
          veredicto: veredicto,
        ));
      }
      if (mounted) setState(() { _resultado = analisis; _analizando = false; });
    } catch (e) {
      if (mounted) setState(() => _analizando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Escanear prenda', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            if (_clima != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(children: [
                  const Icon(Icons.thermostat, size: 14, color: Colors.purple),
                  const SizedBox(width: 4),
                  Text('${_clima!.temperatura.toStringAsFixed(1)}°C en ${_clima!.ciudad}',
                      style: TextStyle(fontSize: 13, color: Colors.purple.shade300)),
                ]),
              ),
            const SizedBox(height: 20),
            _imagen == null ? _buildZonaCaptura() : _buildImagenPreview(),
            const SizedBox(height: 16),
            if (_analizando) _buildCargando(),
            if (_resultado != null && !_analizando) _buildResultado(),
            if (_imagen != null) ...[
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.purple, side: const BorderSide(color: Colors.purple)),
                  onPressed: () => _tomarFoto(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt, size: 16),
                  label: const Text('Nueva foto'),
                )),
                const SizedBox(width: 10),
                Expanded(child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.purple, side: const BorderSide(color: Colors.purple)),
                  onPressed: () => _tomarFoto(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library, size: 16),
                  label: const Text('Galeria'),
                )),
              ]),
            ],
            const SizedBox(height: 28),
            Text('O elige del catalogo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple.shade100)),
            const SizedBox(height: 10),
            ...catalogoPrendas.map((p) {
              final veredicto = _clima != null
                  ? evaluarPrenda(p['tempMin'] as double, p['tempMax'] as double, _clima!.temperatura)
                  : 'recomendada';
              final color = veredicto == 'recomendada'
                  ? Colors.greenAccent
                  : veredicto == 'puede_servir'
                  ? Colors.orange
                  : Colors.redAccent;
              return GestureDetector(
                onTap: () async {
                  final prendaMap = Map<String, dynamic>.from(p);
                  prendaMap['veredicto'] = veredicto;
                  if (_clima != null) {
                    await HistorialService.guardar(Prenda(
                      nombre: p['nombre'] as String,
                      emoji: p['emoji'] as String,
                      tempMin: p['tempMin'] as double,
                      tempMax: p['tempMax'] as double,
                      categoria: p['categoria'] as String,
                      fechaEscaneo: DateTime.now(),
                      veredicto: veredicto,
                    ));
                  }
                  setState(() { _resultado = prendaMap; _imagen = null; });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
                  ),
                  child: Row(children: [
                    Text(p['emoji'] as String, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(p['nombre'] as String, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white))),
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('${(p['tempMin'] as double).toInt()}–${(p['tempMax'] as double).toInt()}°',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ]),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildZonaCaptura() {
    return GestureDetector(
      onTap: () => _tomarFoto(ImageSource.camera),
      child: Container(
        width: double.infinity, height: 200,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.purple.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.camera_alt, size: 52, color: Colors.purple.shade300),
          const SizedBox(height: 10),
          Text('Toca para tomar foto', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.purple.shade200)),
          Text('La IA quitara el fondo automaticamente', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ]),
      ),
    );
  }

  Widget _buildImagenPreview() {
    return Container(
      width: double.infinity, height: 220,
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.file(_imagen!, fit: BoxFit.contain),
      ),
    );
  }

  Widget _buildCargando() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.purple)),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Analizando prenda...', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
          Text('IA procesando imagen', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ]),
      ]),
    );
  }

  Widget _buildResultado() {
    final r = _resultado!;
    final veredicto = r['veredicto'] as String? ?? 'recomendada';
    final Color color;
    final String etiqueta;
    final IconData icono;
    switch (veredicto) {
      case 'recomendada':
        color = Colors.greenAccent; etiqueta = 'Perfecta para hoy'; icono = Icons.check_circle; break;
      case 'puede_servir':
        color = Colors.orange; etiqueta = 'Puede servir'; icono = Icons.info; break;
      default:
        color = Colors.redAccent; etiqueta = 'No recomendada'; icono = Icons.cancel;
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        Row(children: [
          Text(r['emoji'] as String, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r['nombre'] as String, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(r['categoria'] as String, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          ])),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Icon(icono, color: color, size: 20),
          const SizedBox(width: 8),
          Text(etiqueta, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
          if (_clima != null) ...[
            const Spacer(),
            Text('con ${_clima!.temperatura.toStringAsFixed(0)}°C', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ]),
      ]),
    );
  }
}