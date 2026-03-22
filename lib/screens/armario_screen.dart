import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import '../models/prenda_armario.dart';

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
  void initState() { super.initState(); _cargar(); }

  Future<void> _cargar() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('armario') ?? [];
    if (mounted) setState(() {
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
    if (!mounted) return;
    final resultado = await Navigator.push<PrendaArmario>(
      context,
      MaterialPageRoute(
        builder: (_) => AgregarPrendaScreen(imagePath: foto.path),
      ),
    );
    if (resultado != null) {
      setState(() => _prendas.add(resultado));
      await _guardar();
    }
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
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
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
                        color: _filtro == c ? Colors.purple : Colors.purple.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(c, style: TextStyle(color: _filtro == c ? Colors.white : Colors.purple.shade200, fontSize: 12)),
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                _statCard('${_prendas.length}', 'prendas'),
                const SizedBox(width: 8),
                _statCard('${_categorias.length - 1}', 'categorias'),
              ]),
              const SizedBox(height: 16),
              Expanded(
                child: _prendasFiltradas.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.checkroom, size: 56, color: Colors.purple.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  Text('Tu armario esta vacio', style: TextStyle(color: Colors.purple.shade200, fontSize: 16)),
                  Text('Toca + Agregar para empezar', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ]))
                    : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.75),
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
          color: Colors.purple.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
        ),
        child: Column(children: [
          Text(num, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.purple.shade200)),
        ]),
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
          border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: File(p.imagePath).existsSync()
                  ? Image.file(File(p.imagePath), width: double.infinity, fit: BoxFit.cover)
                  : Container(color: Colors.purple.withValues(alpha: 0.2), child: const Icon(Icons.checkroom, color: Colors.purple)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(6),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.nombre, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('${p.tempMin.toInt()}-${p.tempMax.toInt()}C', style: TextStyle(fontSize: 9, color: Colors.purple.shade200)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class AgregarPrendaScreen extends StatefulWidget {
  final String imagePath;
  const AgregarPrendaScreen({super.key, required this.imagePath});
  @override
  State<AgregarPrendaScreen> createState() => _AgregarPrendaScreenState();
}

class _AgregarPrendaScreenState extends State<AgregarPrendaScreen> {
  final _nombreController = TextEditingController();
  String _categoria = 'Tops';
  double _tempMin = 15;
  double _tempMax = 30;

  @override
  void dispose() { _nombreController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Agregar prenda', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.purple),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(File(widget.imagePath), width: double.infinity, height: 220, fit: BoxFit.cover),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nombreController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Nombre de la prenda',
                labelStyle: TextStyle(color: Colors.purple.shade200),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.purple.shade800)),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.purple)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Categoria', style: TextStyle(color: Colors.purple.shade200, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: ['Tops', 'Pants', 'Chamarras', 'Vestidos', 'Zapatos'].map((c) =>
                  GestureDetector(
                    onTap: () => setState(() => _categoria = c),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _categoria == c ? Colors.purple : Colors.purple.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(c, style: TextStyle(color: _categoria == c ? Colors.white : Colors.purple.shade200)),
                    ),
                  ),
              ).toList(),
            ),
            const SizedBox(height: 20),
            Text('Temperatura minima: ${_tempMin.toInt()}C', style: TextStyle(color: Colors.purple.shade200)),
            Slider(value: _tempMin, min: 0, max: 40, divisions: 40, activeColor: Colors.purple, onChanged: (v) => setState(() => _tempMin = v)),
            Text('Temperatura maxima: ${_tempMax.toInt()}C', style: TextStyle(color: Colors.purple.shade200)),
            Slider(value: _tempMax, min: 0, max: 45, divisions: 45, activeColor: Colors.purple, onChanged: (v) => setState(() => _tempMax = v)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () {
                  if (_nombreController.text.isEmpty) return;
                  final prenda = PrendaArmario(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    nombre: _nombreController.text,
                    categoria: _categoria,
                    imagePath: widget.imagePath,
                    tempMin: _tempMin,
                    tempMax: _tempMax,
                    color: 'morado',
                  );
                  Navigator.pop(context, prenda);
                },
                child: const Text('Guardar en mi armario', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}