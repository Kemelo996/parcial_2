import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/establecimientos_service.dart';

class EstablecimientoFormScreen extends StatefulWidget {
  final String? id;
  final Map<String, dynamic>? datosIniciales;

  const EstablecimientoFormScreen({super.key, this.id, this.datosIniciales});

  bool get esEdicion => id != null;

  @override
  State<EstablecimientoFormScreen> createState() =>
      _EstablecimientoFormScreenState();
}

class _EstablecimientoFormScreenState
    extends State<EstablecimientoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _nitCtrl;
  late final TextEditingController _direccionCtrl;
  late final TextEditingController _telefonoCtrl;

  File? _logoFile;
  String? _logoUrlActual;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final d = widget.datosIniciales;
    _nombreCtrl = TextEditingController(text: d?['nombre'] ?? '');
    _nitCtrl = TextEditingController(text: d?['nit'] ?? '');
    _direccionCtrl = TextEditingController(text: d?['direccion'] ?? '');
    _telefonoCtrl = TextEditingController(text: d?['telefono'] ?? '');
    _logoUrlActual = d?['logo'];
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _nitCtrl.dispose();
    _direccionCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();
    final fuente = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (fuente == null) return;
    final picked = await picker.pickImage(source: fuente, imageQuality: 80);
    if (picked == null) return;

    setState(() => _logoFile = File(picked.path));
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);
    try {
      final service = EstablecimientosService();
      if (widget.esEdicion) {
        await service.editar(
          id: widget.id!,
          nombre: _nombreCtrl.text.trim(),
          nit: _nitCtrl.text.trim(),
          direccion: _direccionCtrl.text.trim(),
          telefono: _telefonoCtrl.text.trim(),
          logo: _logoFile,
        );
      } else {
        await service.crear(
          nombre: _nombreCtrl.text.trim(),
          nit: _nitCtrl.text.trim(),
          direccion: _direccionCtrl.text.trim(),
          telefono: _telefonoCtrl.text.trim(),
          logo: _logoFile,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.esEdicion
              ? 'Establecimiento actualizado'
              : 'Establecimiento creado'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.esEdicion
            ? 'Editar Establecimiento'
            : 'Nuevo Establecimiento'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo picker
              Center(
                child: GestureDetector(
                  onTap: _seleccionarImagen,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _logoFile != null
                            ? Image.file(_logoFile!,
                                width: 120, height: 120, fit: BoxFit.cover)
                            : (_logoUrlActual != null &&
                                    _logoUrlActual!.isNotEmpty
                                ? Image.network(_logoUrlActual!,
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _placeholderLogo())
                                : _placeholderLogo()),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.teal,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt,
                            size: 18, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text('Toca para seleccionar logo',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
              const SizedBox(height: 28),

              // Campos
              _CampoTexto(
                controller: _nombreCtrl,
                label: 'Nombre',
                icono: Icons.store,
                validar: (v) => v == null || v.trim().isEmpty
                    ? 'El nombre es requerido'
                    : null,
              ),
              const SizedBox(height: 16),
              _CampoTexto(
                controller: _nitCtrl,
                label: 'NIT',
                icono: Icons.badge,
                validar: (v) =>
                    v == null || v.trim().isEmpty ? 'El NIT es requerido' : null,
              ),
              const SizedBox(height: 16),
              _CampoTexto(
                controller: _direccionCtrl,
                label: 'Dirección',
                icono: Icons.location_on,
                validar: (v) => v == null || v.trim().isEmpty
                    ? 'La dirección es requerida'
                    : null,
              ),
              const SizedBox(height: 16),
              _CampoTexto(
                controller: _telefonoCtrl,
                label: 'Teléfono',
                icono: Icons.phone,
                teclado: TextInputType.phone,
                validar: (v) => v == null || v.trim().isEmpty
                    ? 'El teléfono es requerido'
                    : null,
              ),
              const SizedBox(height: 32),

              FilledButton.icon(
                onPressed: _guardando ? null : _guardar,
                icon: _guardando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save),
                label: Text(_guardando
                    ? 'Guardando…'
                    : widget.esEdicion
                        ? 'Actualizar'
                        : 'Crear'),
                style: FilledButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
          color: Colors.teal.shade50,
          borderRadius: BorderRadius.circular(16)),
      child: const Icon(Icons.store, size: 48, color: Colors.teal),
    );
  }
}

class _CampoTexto extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icono;
  final String? Function(String?)? validar;
  final TextInputType teclado;

  const _CampoTexto({
    required this.controller,
    required this.label,
    required this.icono,
    this.validar,
    this.teclado = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: teclado,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icono),
        border: const OutlineInputBorder(),
      ),
      validator: validar,
    );
  }
}