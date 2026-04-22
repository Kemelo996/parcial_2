import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../models/establecimiento_model.dart';
import '../../services/establecimientos_service.dart';

class EstablecimientoDetalleScreen extends StatefulWidget {
  final String id;
  const EstablecimientoDetalleScreen({super.key, required this.id});

  @override
  State<EstablecimientoDetalleScreen> createState() =>
      _EstablecimientoDetalleScreenState();
}

class _EstablecimientoDetalleScreenState
    extends State<EstablecimientoDetalleScreen> {
  Establecimiento? _est;
  bool _cargando = true;
  String? _error;
  bool _eliminando = false;

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
      final est = await service.fetchUno(widget.id);
      if (!mounted) return;
      setState(() {
        _est = est;
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

  Future<void> _eliminar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar establecimiento'),
        content: Text(
            '¿Estás seguro de que deseas eliminar "${_est?.nombre}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    setState(() => _eliminando = true);
    try {
      await EstablecimientosService().eliminar(widget.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Establecimiento eliminado correctamente'),
            backgroundColor: Colors.green),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _eliminando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_est?.nombre ?? 'Detalle'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          if (!_cargando && _est != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                await context.pushNamed(
                  'establecimiento-editar',
                  pathParameters: {'id': widget.id},
                  extra: _est!.toJson(),
                );
                _cargar();
              },
            ),
          if (!_cargando && _est != null)
            IconButton(
              icon: _eliminando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: _eliminando ? null : _eliminar,
            ),
        ],
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
            Text('Error: $_error'),
            ElevatedButton(onPressed: _cargar, child: const Text('Reintentar')),
          ],
        ),
      );
    }

    final est = _est ??
        const Establecimiento(
          id: 0,
          nombre: 'Nombre del establecimiento',
          nit: '000.000.000-0',
          direccion: 'Dirección de ejemplo 123',
          telefono: '300 000 0000',
        );

    return Skeletonizer(
      enabled: _cargando,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: est.logoUrl != null && est.logoUrl!.isNotEmpty
                    ? Image.network(
                        est.logoUrl!,
                        width: 140,
                        height: 140,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _logoPlaceholder(),
                      )
                    : _logoPlaceholder(),
              ),
            ),
            const SizedBox(height: 28),
            _Campo(label: 'Nombre', valor: est.nombre),
            _Campo(label: 'NIT', valor: est.nit),
            _Campo(label: 'Dirección', valor: est.direccion),
            _Campo(label: 'Teléfono', valor: est.telefono),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _cargando
                        ? null
                        : () async {
                            await context.pushNamed(
                              'establecimiento-editar',
                              pathParameters: {'id': widget.id},
                              extra: est.toJson(),
                            );
                            _cargar();
                          },
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.teal,
                        side: const BorderSide(color: Colors.teal)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _cargando || _eliminando ? null : _eliminar,
                    icon: const Icon(Icons.delete),
                    label: const Text('Eliminar'),
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _logoPlaceholder() {
    return Container(
      width: 140,
      height: 140,
      color: Colors.teal.shade50,
      child: const Icon(Icons.store, size: 64, color: Colors.teal),
    );
  }
}

class _Campo extends StatelessWidget {
  final String label;
  final String valor;
  const _Campo({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(valor, style: const TextStyle(fontSize: 16)),
          const Divider(),
        ],
      ),
    );
  }
}