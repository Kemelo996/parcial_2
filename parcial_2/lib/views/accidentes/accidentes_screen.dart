import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter/foundation.dart';
import '../../isolates/accidentes_isolate.dart';
import '../../models/accidente_model.dart';
import '../../services/accidentes_service.dart';

class AccidentesScreen extends StatefulWidget {
  const AccidentesScreen({super.key});

  @override
  State<AccidentesScreen> createState() => _AccidentesScreenState();
}

class _AccidentesScreenState extends State<AccidentesScreen> {
  Map<String, dynamic>? _estadisticas;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarYProcesar();
  }

  Future<void> _cargarYProcesar() async {
    setState(() {
      _cargando = true;
      _error = null;
      _estadisticas = null;
    });
    try {
      final service = AccidentesService();
      final accidentes = await service.fetchTodos();

      // ✅ Serializa a List<Map> ANTES de enviar al compute/isolate
      final listaMapas = accidentes
          .map((a) => <String, dynamic>{
                'clase_de_accidente': a.claseDeAccidente,
                'gravedad_del_accidente': a.gravedadDelAccidente,
                'barrio_hecho': a.barrioHecho,
                'dia': a.dia,
                'hora': a.hora,
                'area': a.area,
                'clase_de_vehiculo': a.claseDeVehiculo,
              })
          .toList();

      // ✅ compute() es la forma correcta en Flutter — evita capturar
      //    el contexto de Flutter en el closure (causa del error anterior)
      final resultado = await compute(
        calcularEstadisticasDesdeMapas,
        listaMapas,
      );

      if (!mounted) return;
      setState(() {
        _estadisticas = resultado;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas de Accidentes'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarYProcesar,
          )
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // ✅ Fix overflow: SingleChildScrollView envuelve también el estado de error
    if (_error != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error: $_error',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarYProcesar,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return Skeletonizer(
      enabled: _cargando,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_cargando && _estadisticas != null)
              _InfoBanner(total: _estadisticas!['total'] as int),
            const SizedBox(height: 16),
            _buildPieChartClase(),
            const SizedBox(height: 24),
            _buildPieChartGravedad(),
            const SizedBox(height: 24),
            _buildBarChartBarrios(),
            const SizedBox(height: 24),
            _buildBarChartDias(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── CHART 1: Clase de accidente ──────────────────────────────────────────
  Widget _buildPieChartClase() {
    final data = _cargando
        ? {'Choque': 40, 'Atropello': 30, 'Volcamiento': 20, 'Otros': 10}
        : (_estadisticas?['porClase'] as Map<String, int>? ?? {});

    return _ChartCard(
      titulo: 'Distribución por Clase de Accidente',
      child: SizedBox(
        height: 220,
        child: PieChart(
          PieChartData(
            sections: _toPieSections(data),
            sectionsSpace: 2,
            centerSpaceRadius: 40,
          ),
        ),
      ),
      leyenda: _buildLeyenda(data),
    );
  }

  // ── CHART 2: Gravedad ────────────────────────────────────────────────────
  Widget _buildPieChartGravedad() {
    final data = _cargando
        ? {'Con muertos': 15, 'Con heridos': 55, 'Solo daños': 30}
        : (_estadisticas?['porGravedad'] as Map<String, int>? ?? {});

    return _ChartCard(
      titulo: 'Distribución por Gravedad',
      child: SizedBox(
        height: 220,
        child: PieChart(
          PieChartData(
            sections: _toPieSections(data),
            sectionsSpace: 2,
            centerSpaceRadius: 40,
          ),
        ),
      ),
      leyenda: _buildLeyenda(data),
    );
  }

  // ── CHART 3: Top 5 barrios ───────────────────────────────────────────────
  Widget _buildBarChartBarrios() {
    final data = _cargando
        ? {
            'Centro': 120,
            'La Unión': 95,
            'Palermo': 80,
            'El Bosque': 70,
            'San Carlos': 60,
          }
        : (_estadisticas?['top5Barrios'] as Map<String, int>? ?? {});

    final entradas = data.entries.toList();
    final maxVal = entradas.isEmpty
        ? 1.0
        : entradas
            .map((e) => e.value)
            .reduce((a, b) => a > b ? a : b)
            .toDouble();

    return _ChartCard(
      titulo: 'Top 5 Barrios con Más Accidentes',
      child: SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            maxY: maxVal * 1.2,
            barTouchData: BarTouchData(enabled: true),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= entradas.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        entradas[idx].key.length > 8
                            ? '${entradas[idx].key.substring(0, 7)}…'
                            : entradas[idx].key,
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  },
                  reservedSize: 28,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: const FlGridData(show: true),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(entradas.length, (i) {
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: entradas[i].value.toDouble(),
                    color: Colors.orange,
                    width: 20,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4)),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  // ── CHART 4: Día de la semana ────────────────────────────────────────────
  Widget _buildBarChartDias() {
    final data = _cargando
        ? {
            'Lunes': 55,
            'Martes': 60,
            'Miércoles': 70,
            'Jueves': 65,
            'Viernes': 90,
            'Sábado': 80,
            'Domingo': 45,
          }
        : (_estadisticas?['porDia'] as Map<String, int>? ?? {});

    final entradas = data.entries.toList();
    final maxVal = entradas.isEmpty
        ? 1.0
        : entradas
            .map((e) => e.value)
            .reduce((a, b) => a > b ? a : b)
            .toDouble();

    return _ChartCard(
      titulo: 'Distribución por Día de la Semana',
      child: SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            maxY: maxVal * 1.2,
            barTouchData: BarTouchData(enabled: true),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= entradas.length) {
                      return const SizedBox.shrink();
                    }
                    final dia = entradas[idx].key;
                    final abrev =
                        dia.length >= 3 ? dia.substring(0, 3) : dia;
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(abrev,
                          style: const TextStyle(fontSize: 10)),
                    );
                  },
                  reservedSize: 28,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: const FlGridData(show: true),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(entradas.length, (i) {
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: entradas[i].value.toDouble(),
                    color: Colors.deepPurple,
                    width: 16,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4)),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  List<PieChartSectionData> _toPieSections(Map<String, int> data) {
    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.red,
      Colors.purple,
      Colors.teal,
      Colors.amber,
    ];
    final total = data.values.fold<int>(0, (a, b) => a + b);
    final entradas = data.entries.toList();
    return List.generate(entradas.length, (i) {
      final pct = total == 0 ? 0.0 : entradas[i].value / total * 100;
      return PieChartSectionData(
        value: entradas[i].value.toDouble(),
        color: colors[i % colors.length],
        title: '${pct.toStringAsFixed(1)}%',
        radius: 80,
        titleStyle: const TextStyle(
            fontSize: 11,
            color: Colors.white,
            fontWeight: FontWeight.bold),
      );
    });
  }

  Widget _buildLeyenda(Map<String, int> data) {
    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.red,
      Colors.purple,
      Colors.teal,
      Colors.amber,
    ];
    final entradas = data.entries.toList();
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: List.generate(entradas.length, (i) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colors[i % colors.length],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${entradas[i].key} (${entradas[i].value})',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }),
    );
  }
}

// ── Widgets auxiliares ───────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  final int total;
  const _InfoBanner({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Total de accidentes procesados: $total',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String titulo;
  final Widget child;
  final Widget? leyenda;

  const _ChartCard(
      {required this.titulo, required this.child, this.leyenda});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            child,
            if (leyenda != null) ...[
              const SizedBox(height: 12),
              leyenda!,
            ],
          ],
        ),
      ),
    );
  }
}