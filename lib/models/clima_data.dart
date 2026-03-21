class ClimaData {
  final double temperatura;
  final double sensacionTermica;
  final double humedad;
  final String descripcion;
  final String icono;
  final String ciudad;
  final double viento;
  final DateTime fechaActualizacion;

  ClimaData({
    required this.temperatura,
    required this.sensacionTermica,
    required this.humedad,
    required this.descripcion,
    required this.icono,
    required this.ciudad,
    required this.viento,
    required this.fechaActualizacion,
  });

  factory ClimaData.fromJson(Map<String, dynamic> json) {
    return ClimaData(
      temperatura: (json['main']['temp'] as num).toDouble(),
      sensacionTermica: (json['main']['feels_like'] as num).toDouble(),
      humedad: (json['main']['humidity'] as num).toDouble(),
      descripcion: json['weather'][0]['description'] as String,
      icono: json['weather'][0]['icon'] as String,
      ciudad: json['name'] as String,
      viento: (json['wind']['speed'] as num).toDouble(),
      fechaActualizacion: DateTime.now(),
    );
  }

  // Para demo sin API key
  factory ClimaData.demo() {
    return ClimaData(
      temperatura: 18,
      sensacionTermica: 16,
      humedad: 65,
      descripcion: 'nublado',
      icono: '04d',
      ciudad: 'Ciudad de México',
      viento: 3.2,
      fechaActualizacion: DateTime.now(),
    );
  }
}
