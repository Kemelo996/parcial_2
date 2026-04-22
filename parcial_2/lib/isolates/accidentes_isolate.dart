import '../models/accidente_model.dart';

/// Punto de entrada desde la pantalla.
/// Recibe List<Map> (serializable entre isolates) y delega a [calcularEstadisticas].
Map<String, dynamic> calcularEstadisticasDesdeMapas(
    List<Map<String, dynamic>> mapas) {
  final accidentes = mapas.map((m) => Accidente.fromJson(m)).toList();
  return calcularEstadisticas(accidentes);
}

/// Función principal que corre en el Isolate secundario.
/// Recibe la lista completa de accidentes y devuelve las 4 estadísticas.
Map<String, dynamic> calcularEstadisticas(List<Accidente> accidentes) {
  final inicio = DateTime.now();
  final n = accidentes.length;
  print('[Isolate] Iniciado — $n registros recibidos');

  // 1. Distribución por clase de accidente
  final Map<String, int> porClase = {};
  for (final a in accidentes) {
    final clave = a.claseDeAccidente.trim().isEmpty
        ? 'Sin datos'
        : _normalizarClase(a.claseDeAccidente);
    porClase[clave] = (porClase[clave] ?? 0) + 1;
  }

  // 2. Distribución por gravedad
  final Map<String, int> porGravedad = {};
  for (final a in accidentes) {
    final clave = a.gravedadDelAccidente.trim().isEmpty
        ? 'Sin datos'
        : a.gravedadDelAccidente.trim();
    porGravedad[clave] = (porGravedad[clave] ?? 0) + 1;
  }

  // 3. Top 5 barrios con más accidentes
  final Map<String, int> porBarrio = {};
  for (final a in accidentes) {
    final clave =
        a.barrioHecho.trim().isEmpty ? 'Sin datos' : a.barrioHecho.trim();
    porBarrio[clave] = (porBarrio[clave] ?? 0) + 1;
  }
  final top5Barrios = Map.fromEntries(
    (porBarrio.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(5),
  );

  // 4. Distribución por día de la semana
  final Map<String, int> porDia = {};
  const diasOrden = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];
  for (final a in accidentes) {
    final clave = a.dia.trim().isEmpty ? 'Sin datos' : a.dia.trim();
    porDia[clave] = (porDia[clave] ?? 0) + 1;
  }

  // Ordenar por día de semana canónico primero, luego los demás
  final porDiaOrdenado = <String, int>{};
  for (final d in diasOrden) {
    if (porDia.containsKey(d)) porDiaOrdenado[d] = porDia[d]!;
  }
  porDia.forEach((k, v) {
    if (!porDiaOrdenado.containsKey(k)) porDiaOrdenado[k] = v;
  });

  final fin = DateTime.now();
  final ms = fin.difference(inicio).inMilliseconds;
  print('[Isolate] Completado en $ms ms');

  return {
    'total': n,
    'porClase': porClase,
    'porGravedad': porGravedad,
    'top5Barrios': top5Barrios,
    'porDia': porDiaOrdenado,
  };
}

String _normalizarClase(String clase) {
  final c = clase.trim().toUpperCase();
  if (c.contains('CHOQUE')) return 'Choque';
  if (c.contains('ATROPELLO')) return 'Atropello';
  if (c.contains('VOLCAMIENTO') || c.contains('VOLCADO')) return 'Volcamiento';
  if (c.contains('CAÍDA') || c.contains('CAIDA')) return 'Caída';
  if (c.contains('INCENDIO')) return 'Incendio';
  return 'Otros';
}