import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/accidente_model.dart';

class AccidentesService {
  late final Dio _dio;

  AccidentesService() {
    _dio = Dio(BaseOptions(
      baseUrl: dotenv.env['ACCIDENTES_BASE_URL'] ?? '',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
    ));
  }

  Future<List<Accidente>> fetchTodos({int limit = 100000}) async {
    try {
      final response = await _dio.get('', queryParameters: {'\$limit': limit});
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Accidente.fromJson(json)).toList();
      }
      throw Exception('Error al obtener accidentes: ${response.statusCode}');
    } on DioException catch (e) {
      throw Exception('Error de red: ${e.message}');
    }
  }
}