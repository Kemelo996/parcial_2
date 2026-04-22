import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../services/accidentes_service.dart';
import '../../services/establecimientos_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int? _totalAccidentes;
  int? _totalEstablecimientos;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarResumen();
  }

  Future<void> _cargarResumen() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final accService = AccidentesService();
      final estService = EstablecimientosService();

      final results = await Future.wait([
        accService.fetchTodos(limit: 1000),
        estService.fetchTodos(),
      ]);

      if (!mounted) return;
      setState(() {
        _totalAccidentes = (results[0] as List).length;
        _totalEstablecimientos = (results[1] as List).length;
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: RefreshIndicator(
        onRefresh: _cargarResumen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bienvenido',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Selecciona un módulo para continuar',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),

              // Resumen skeleton
              if (_error != null)
                Card(
                  color: colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Error al cargar resumen: $_error',
                      style: TextStyle(color: colorScheme.onErrorContainer),
                    ),
                  ),
                )
              else
                Skeletonizer(
                  enabled: _cargando,
                  child: Row(
                    children: [
                      _ResumenCard(
                        titulo: 'Accidentes',
                        valor: _totalAccidentes?.toString() ?? '---',
                        icono: Icons.car_crash,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      _ResumenCard(
                        titulo: 'Establecimientos',
                        valor: _totalEstablecimientos?.toString() ?? '---',
                        icono: Icons.store,
                        color: Colors.teal,
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 32),
              const Text(
                'Módulos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),

              // Card accidentes
              _ModuloCard(
                titulo: 'Estadísticas de Accidentes',
                descripcion:
                    'Visualiza distribución por clase, gravedad, barrios y días de la semana',
                icono: Icons.bar_chart,
                color: Colors.orange,
                onTap: () => context.pushNamed('accidentes'),
              ),
              const SizedBox(height: 12),

              // Card establecimientos
              _ModuloCard(
                titulo: 'Gestión de Establecimientos',
                descripcion:
                    'Crea, consulta, edita y elimina establecimientos del parqueadero',
                icono: Icons.store,
                color: Colors.teal,
                onTap: () => context.pushNamed('establecimientos'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResumenCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color color;

  const _ResumenCard({
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icono, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                valor,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(titulo, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuloCard extends StatelessWidget {
  final String titulo;
  final String descripcion;
  final IconData icono;
  final Color color;
  final VoidCallback onTap;

  const _ModuloCard({
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icono, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descripcion,
                      style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}