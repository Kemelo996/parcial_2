class Accidente {
  final String claseDeAccidente;
  final String gravedadDelAccidente;
  final String barrioHecho;
  final String dia;
  final String hora;
  final String area;
  final String claseDeVehiculo;

  const Accidente({
    required this.claseDeAccidente,
    required this.gravedadDelAccidente,
    required this.barrioHecho,
    required this.dia,
    required this.hora,
    required this.area,
    required this.claseDeVehiculo,
  });

  factory Accidente.fromJson(Map<String, dynamic> json) {
    return Accidente(
      claseDeAccidente: json['clase_de_accidente']?.toString() ?? 'Sin datos',
      gravedadDelAccidente:
          json['gravedad_del_accidente']?.toString() ?? 'Sin datos',
      barrioHecho: json['barrio_hecho']?.toString() ?? 'Sin datos',
      dia: json['dia']?.toString() ?? 'Sin datos',
      hora: json['hora']?.toString() ?? '00:00:00',
      area: json['area']?.toString() ?? 'Sin datos',
      claseDeVehiculo: json['clase_de_vehiculo']?.toString() ?? 'Sin datos',
    );
  }
}