// armario
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import '../models/prenda_armario.dart';

class PrendaArmario {
  final String id;
  final String nombre;
  final String categoria;
  final String imagePath;
  final double tempMin;
  final double tempMax;
  final String color;

  PrendaArmario({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.imagePath,
    required this.tempMin,
    required this.tempMax,
    required this.color,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'nombre': nombre, 'categoria': categoria,
    'imagePath': imagePath, 'tempMin': tempMin,
    'tempMax': tempMax, 'color': color,
  };

  factory PrendaArmario.fromJson(Map<String, dynamic> j) => PrendaArmario(
    id: j['id'], nombre: j['nombre'], categoria: j['categoria'],
    imagePath: j['imagePath'], tempMin: j['tempMin'],
    tempMax: j['tempMax'], color: j['color'],
  );
}

class ArmarioScreen extends StatefulWidget {
  const ArmarioScreen({super.key});
  @override
  State<ArmarioScreen> createState() => _ArmarioScreenState();
}

class _ArmarioScreenState extends State<ArmarioScreen> {
  List<PrendaArmario> _prendas = [];
  String _filtro = 'Toda';
  final _categorias = ['Toda', 'Tops', 'Pants', 'Chamarras', 'Vestidos', 'Zapatos'];
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('armario') ?? [];
    setState(() {
      _prendas = raw.map((e) => PrendaArmario.fromJson(jsonDecode(e))).toList();
    });
  }

  Future<void> _guardar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('armario', _prendas.map((p) => jsonEncode(p.toJson())).toList());
  }

  Future<void> _agregarPrenda() async {
    final foto = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (foto == null) return;
    _mostrarDialogoAgregar(foto.path);
  }

  void _mostrarDialogoAgregar(String imagePath) {
    String nombre = '';
    String categoria = 'Tops';
    double tempMin = 15;
    double tempMax = 30;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text('Agregar prenda', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(imagePath), height: 120, width: double.infinity, fit: BoxFit.cover),
                ),
                const SizedBox(height: 12),
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Nombre de la prenda',
                    labelStyle: TextStyle(color: Colors.purple.shade200),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.purple.shade800)),
                    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.purple)),
                  ),
                  onChanged: (v) => nombre = v,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: categoria,
                  dropdownColor: const Color(0xFF1A1A2E),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Categoría',
                    labelStyle: TextStyle(color: Colors.purple.shade200),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.purple.shade800)),
                  ),
                  items: ['Tops', 'Pants', 'Chamarras', 'Vestidos', 'Zapatos']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setS(() => categoria = v!),
                ),
                const SizedBox(height: 12),
                Text('Temp. mínima: ${tempMin.toInt()}°C', style: TextStyle(color: Colors.purple.shade200, fontSize: 12)),
                Slider(
                  value: tempMin, min: 0, max: 40, divisions: 40,
                  activeColor: Colors.purple,
                  onChanged: (v) => setS(() => tempMin = v),
                ),
                Text('Temp. máxima: ${tempMax.toInt()}°C', style: TextStyle(color: Colors.purple.shade200, fontSize: 12)),
                Slider(
                  value: tempMax, min: 0, max: 45, divisions: 45,
                  activeColor: Colors.purple,
                  onChanged: (v) => setS(() => tempMax = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              onPressed: () {
                if (nombre.isEmpty) return;
                final prenda = PrendaArmario(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  nombre: nombre, categoria: categoria,
                  imagePath: imagePath, tempMin: tempMin,
                  tempMax: tempMax, color: 'morado',
                );
                setState(() => _prendas.add(prenda));
                _guardar();
                Navigator.pop(ctx);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  List<PrendaArmario> get _prendasFiltradas => _filtro == 'Toda'
      ? _prendas
      : _prendas.where((p) => p.categoria == _filtro).toList();

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
                  const Text('Mi armario', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    icon: const Icon(Icons.add, size: 16, color: Colors.white),
                    label: const Text('Agregar', style: TextStyle(color: Colors.white, fontSize: 12)),
                    onPressed: _agregarPrenda,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 32,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _categorias.map((c) => GestureDetector(
                    onTap: () => setState(() => _filtro = c),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: _filtro == c ? Colors.purple : Colors.purple.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(c, style: TextStyle(color: _filtro == c ? Colors.white : Colors.purple.shade200, fontSize: 12)),
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _statCard('${_prendas.length}', 'prendas'),
                  const SizedBox(width: 8),
                  _statCard('${_categorias.length - 1}', 'categorías'),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _prendasFiltradas.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.checkroom, size: 56, color: Colors.purple.withOpacity(0.4)),
                      const SizedBox(height: 12),
                      Text('Tu armario está vacío', style: TextStyle(color: Colors.purple.shade200, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('Toca + Agregar para empezar', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ],
                  ),
                )
                    : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.75,
                  ),
                  itemCount: _prendasFiltradas.length,
                  itemBuilder: (_, i) => _prendaCard(_prendasFiltradas[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String num, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.purple.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.purple.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(num, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.purple.shade200)),
          ],
        ),
      ),
    );
  }

  Widget _prendaCard(PrendaArmario p) {
    return GestureDetector(
      onLongPress: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            title: Text(p.nombre, style: const TextStyle(color: Colors.white)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
              TextButton(
                onPressed: () {
                  setState(() => _prendas.removeWhere((x) => x.id == p.id));
                  _guardar();
                  Navigator.pop(context);
                },
                child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.purple.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: File(p.imagePath).existsSync()
                    ? Image.file(File(p.imagePath), width: double.infinity, fit: BoxFit.cover)
                    : Container(color: Colors.purple.withOpacity(0.2), child: const Icon(Icons.checkroom, color: Colors.purple)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.nombre, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('${p.tempMin.toInt()}-${p.tempMax.toInt()}°C', style: TextStyle(fontSize: 9, color: Colors.purple.shade200)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
