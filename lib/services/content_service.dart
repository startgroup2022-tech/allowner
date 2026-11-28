import 'package:dio/dio.dart';
import '../utils/safe_parse.dart';
import 'api_client.dart';

class ContentService {
  final Dio _dio = ApiClient.instance.dio;

  Future<Map<String, dynamic>> getContent(String key) async {
    try {
      final res =
          await _dio.get('/content/get.php', queryParameters: {'key': key});
      return asMap(res.data['content']);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> getSettings() async {
    try {
      final res = await _dio.get('/content/settings.php');
      return asMap(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
