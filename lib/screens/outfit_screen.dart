import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import '../models/prenda_armario.dart';
import '../services/clima_service.dart';
import '../models/clima_data.dart';

class OutfitScreen extends StatefulWidget {
  const OutfitScreen({super.key});
  @override
  State<OutfitScreen> createState() => _OutfitScreenState();
}

class _OutfitScreenState extends State<OutfitScreen> {
  List<PrendaArmario> _armario = [];
  ClimaData? _clima;
  bool _cargando = true;
  List<List<PrendaArmario>> _outfits = [];

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  Future<void> _cargarTodo() async {
    setState(() => _cargando = true);
    final clima = await ClimaService.obtenerClima();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('armario') ?? [];
    final armario = raw.map((e) => PrendaArmario.fromJson(jsonDecode(e))).toList();
    if (mounted) {
      setState(() {
        _clima = clima;
        _armario = armario;
        _outfits = _generarOutfits(armario, clima.temperatura);
        _cargando = false;
      });
    }
  }

  List<List<PrendaArmario>> _generarOutfits(List<PrendaArmario> armario, double temp) {
    final aptas = armario.where((p) => temp >= p.tempMin && temp <= p.tempMax).toList();
    final tops = aptas.where((p) => p.categoria == 'Tops').toList();
    final pants = aptas.where((p) => p.categoria == 'Pants').toList();
    final chamarras = aptas.where((p) => p.categoria == 'Chamarras').toList();
    final vestidos = aptas.where((p) => p.categoria == 'Vestidos').toList();

    final outfits = <List<PrendaArmario>>[];

    for (final top in tops) {
      for (final pant in pants) {
        final outfit = [top, pant];
        if (chamarras.isNotEmpty) outfit.add(chamarras.first);
        outfits.add(outfit);
        if (outfits.length >= 5) break;
      }
      if (outfits.length >= 5) break;
    }

    for (final vestido in vestidos) {
      if (outfits.length >= 5) break;
      outfits.add([vestido]);
    }

    return outfits;
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
                  const Text('Outfit del día',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.purple),
                    onPressed: _cargarTodo,
                  ),
                ],
              ),
              if (_clima != null)
                Row(children: [
                  const Icon(Icons.thermostat, size: 14, color: Colors.purple),
                  const SizedBox(width: 4),
                  Text('${_clima!.temperatura.toStringAsFixed(1)}°C · ${_clima!.ciudad}',
                      style: TextStyle(fontSize: 12, color: Colors.purple.shade300)),
                ]),
              const SizedBox(height: 16),
              Expanded(
                child: _cargando
                    ? const Center(child: CircularProgressIndicator(color: Colors.purple))
                    : _outfits.isEmpty
                    ? _buildVacio()
                    : RefreshIndicator(
                  onRefresh: _cargarTodo,
                  color: Colors.purple,
                  child: ListView.builder(
                    itemCount: _outfits.length,
                    itemBuilder: (_, i) => _buildOutfitCard(_outfits[i], i == 0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.checkroom, size: 64, color: Colors.purple.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('Sin outfits disponibles',
              style: TextStyle(fontSize: 18, color: Colors.purple.shade200)),
          const SizedBox(height: 8),
          Text(
            _armario.isEmpty
                ? 'Agrega prendas a tu armario primero'
                : 'Ninguna prenda es adecuada para ${_clima?.temperatura.toStringAsFixed(0)}°C',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOutfitCard(List<PrendaArmario> outfit, bool esPrincipal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: esPrincipal
            ? LinearGradient(
          colors: [Colors.purple.shade900, Colors.indigo.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : null,
        color: esPrincipal ? null : const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: esPrincipal
              ? Colors.purple.withValues(alpha: 0.6)
              : Colors.purple.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (esPrincipal) ...[
                const Text('✨', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
              ],
              Text(
                esPrincipal ? 'Combinación perfecta' : 'Opción ${_outfits.indexOf(outfit) + 1}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: esPrincipal ? Colors.white : Colors.purple.shade200,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: outfit.map((p) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  children: [
                    Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: File(p.imagePath).existsSync()
                            ? Image.file(File(p.imagePath), fit: BoxFit.cover, width: double.infinity)
                            : Icon(Icons.checkroom, color: Colors.purple.shade300, size: 32),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(p.nombre,
                        style: const TextStyle(fontSize: 10, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center),
                    Text(p.categoria,
                        style: TextStyle(fontSize: 9, color: Colors.purple.shade300),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '✓ Ideal para ${_clima?.temperatura.toStringAsFixed(0)}°C',
                  style: const TextStyle(color: Colors.greenAccent, fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}