import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../models/establecimiento_model.dart';
import '../../services/establecimientos_service.dart';

class EstablecimientosScreen extends StatefulWidget {
  const EstablecimientosScreen({super.key});

  @override
  State<EstablecimientosScreen> createState() => _EstablecimientosScreenState();
}

class _EstablecimientosScreenState extends State<EstablecimientosScreen> {
  List<Establecimiento> _establecimientos = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final service = EstablecimientosService();
      final lista = await service.fetchTodos();
      if (!mounted) return;
      setState(() {
        _establecimientos = lista;
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
        title: const Text('Establecimientos'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.pushNamed('establecimiento-crear');
          _cargar();
        },
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_cargando && _error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: _cargar, child: const Text('Reintentar')),
          ],
        ),
      );
    }

    // Lista fake para skeleton
    final itemsRender = _cargando
        ? List.generate(6, (_) => _fakeEstablecimiento())
        : _establecimientos;

    if (!_cargando && itemsRender.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_mall_directory_outlined, size: 60, color: Colors.grey),
            SizedBox(height: 12),
            Text('No hay establecimientos registrados'),
          ],
        ),
      );
    }

    return Skeletonizer(
      enabled: _cargando,
      child: RefreshIndicator(
        onRefresh: _cargar,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
          itemCount: itemsRender.length,
          itemBuilder: (context, index) {
            final est = itemsRender[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: _LogoWidget(logoUrl: est.logoUrl),
                title: Text(
                  est.nombre,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NIT: ${est.nit}'),
                    Text(est.direccion),
                    Text('Tel: ${est.telefono}'),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  await context.pushNamed(
                    'establecimiento-detalle',
                    pathParameters: {'id': est.id.toString()},
                  );
                  _cargar();
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Establecimiento _fakeEstablecimiento() => const Establecimiento(
        id: 0,
        nombre: 'Nombre del establecimiento',
        nit: '000.000.000-0',
        direccion: 'Dirección de ejemplo 123',
        telefono: '300 000 0000',
      );
}

class _LogoWidget extends StatelessWidget {
  final String? logoUrl;
  const _LogoWidget({this.logoUrl});

  @override
  Widget build(BuildContext context) {
    if (logoUrl != null && logoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          logoUrl!,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.store, color: Colors.teal),
    );
  }
}