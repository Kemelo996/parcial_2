import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/establecimiento_model.dart';

class EstablecimientosService {
  late final Dio _dio;

  EstablecimientosService() {
    _dio = Dio(BaseOptions(
      baseUrl: dotenv.env['PARKING_BASE_URL'] ?? '',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));
  }

  // GET /establecimientos
  Future<List<Establecimiento>> fetchTodos() async {
    try {
      final response = await _dio.get('/establecimientos');
      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> lista;
        if (data is List) {
          lista = data;
        } else if (data is Map && data.containsKey('data')) {
          lista = data['data'];
        } else {
          lista = [];
        }
        return lista.map((json) => Establecimiento.fromJson(json)).toList();
      }
      throw Exception('Error al listar establecimientos');
    } on DioException catch (e) {
      throw Exception('Error de red: ${e.message}');
    }
  }

  // GET /establecimientos/{id}
  Future<Establecimiento> fetchUno(String id) async {
    try {
      final response = await _dio.get('/establecimientos/$id');
      if (response.statusCode == 200) {
        final data = response.data;
        final json = data is Map && data.containsKey('data')
            ? data['data']
            : data;
        return Establecimiento.fromJson(json);
      }
      throw Exception('No se encontró el establecimiento');
    } on DioException catch (e) {
      throw Exception('Error de red: ${e.message}');
    }
  }

  // POST /establecimientos (multipart)
  Future<void> crear({
    required String nombre,
    required String nit,
    required String direccion,
    required String telefono,
    File? logo,
  }) async {
    try {
      final formData = FormData.fromMap({
        'nombre': nombre,
        'nit': nit,
        'direccion': direccion,
        'telefono': telefono,
        if (logo != null)
          'logo': await MultipartFile.fromFile(
            logo.path,
            filename: logo.path.split('/').last,
          ),
      });
      final response = await _dio.post('/establecimientos', data: formData);
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Error al crear establecimiento');
      }
    } on DioException catch (e) {
      throw Exception('Error de red: ${e.message}');
    }
  }

  // POST /establecimiento-update/{id} con _method=PUT (multipart)
  Future<void> editar({
    required String id,
    required String nombre,
    required String nit,
    required String direccion,
    required String telefono,
    File? logo,
  }) async {
    try {
      final formData = FormData.fromMap({
        '_method': 'PUT',
        'nombre': nombre,
        'nit': nit,
        'direccion': direccion,
        'telefono': telefono,
        if (logo != null)
          'logo': await MultipartFile.fromFile(
            logo.path,
            filename: logo.path.split('/').last,
          ),
      });
      final response =
          await _dio.post('/establecimiento-update/$id', data: formData);
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Error al editar establecimiento');
      }
    } on DioException catch (e) {
      throw Exception('Error de red: ${e.message}');
    }
  }

  // DELETE /establecimientos/{id}
  Future<void> eliminar(String id) async {
    try {
      final response = await _dio.delete('/establecimientos/$id');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Error al eliminar establecimiento');
      }
    } on DioException catch (e) {
      throw Exception('Error de red: ${e.message}');
    }
  }
}