class Prenda {
  final String nombre;
  final String emoji;
  final double tempMin;
  final double tempMax;
  final String categoria;
  final DateTime fechaEscaneo;
  final String veredicto; // 'recomendada', 'puede_servir', 'no_recomendada'

  Prenda({
    required this.nombre,
    required this.emoji,
    required this.tempMin,
    required this.tempMax,
    required this.categoria,
    required this.fechaEscaneo,
    required this.veredicto,
  });

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'emoji': emoji,
        'tempMin': tempMin,
        'tempMax': tempMax,
        'categoria': categoria,
        'fechaEscaneo': fechaEscaneo.toIso8601String(),
        'veredicto': veredicto,
      };

  factory Prenda.fromJson(Map<String, dynamic> json) => Prenda(
        nombre: json['nombre'],
        emoji: json['emoji'],
        tempMin: json['tempMin'],
        tempMax: json['tempMax'],
        categoria: json['categoria'],
        fechaEscaneo: DateTime.parse(json['fechaEscaneo']),
        veredicto: json['veredicto'],
      );
}

// Catalogo de prendas conocidas
const catalogoPrendas = [
  {'nombre': 'Camiseta', 'emoji': '👕', 'tempMin': 22.0, 'tempMax': 45.0, 'categoria': 'Verano'},
  {'nombre': 'Jeans', 'emoji': '👖', 'tempMin': 14.0, 'tempMax': 30.0, 'categoria': 'Casual'},
  {'nombre': 'Chamarra', 'emoji': '🧥', 'tempMin': 0.0, 'tempMax': 15.0, 'categoria': 'Invierno'},
  {'nombre': 'Suéter', 'emoji': '🧶', 'tempMin': 8.0, 'tempMax': 20.0, 'categoria': 'Otoño'},
  {'nombre': 'Short', 'emoji': '🩳', 'tempMin': 26.0, 'tempMax': 45.0, 'categoria': 'Verano'},
  {'nombre': 'Vestido', 'emoji': '👗', 'tempMin': 23.0, 'tempMax': 45.0, 'categoria': 'Verano'},
  {'nombre': 'Abrigo', 'emoji': '🥼', 'tempMin': 0.0, 'tempMax': 10.0, 'categoria': 'Invierno'},
  {'nombre': 'Sudadera', 'emoji': '🩱', 'tempMin': 12.0, 'tempMax': 22.0, 'categoria': 'Otoño'},
];

String evaluarPrenda(double tempMin, double tempMax, double tempActual) {
  if (tempActual >= tempMin && tempActual <= tempMax) return 'recomendada';
  final distancia = tempActual < tempMin
      ? tempMin - tempActual
      : tempActual - tempMax;
  if (distancia <= 5) return 'puede_servir';
  return 'no_recomendada';
}
