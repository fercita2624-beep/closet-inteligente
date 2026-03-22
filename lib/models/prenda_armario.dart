class PrendaArmario {
  final String id;
  final String nombre;
  final String categoria;
  final String imagePath;
  final double tempMin;
  final double tempMax;
  final String color;

  PrendaArmario({required this.id, required this.nombre, required this.categoria, required this.imagePath, required this.tempMin, required this.tempMax, required this.color});

  Map<String, dynamic> toJson() => {'id': id, 'nombre': nombre, 'categoria': categoria, 'imagePath': imagePath, 'tempMin': tempMin, 'tempMax': tempMax, 'color': color};

  factory PrendaArmario.fromJson(Map<String, dynamic> j) => PrendaArmario(id: j['id'], nombre: j['nombre'], categoria: j['categoria'], imagePath: j['imagePath'], tempMin: (j['tempMin'] as num).toDouble(), tempMax: (j['tempMax'] as num).toDouble(), color: j['color']);
}
