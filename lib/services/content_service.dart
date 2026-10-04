import 'package:dio/dio.dart';
import 'api_client.dart';

class ContentService {
  final Dio _dio = ApiClient.instance.dio;

  Future<Map<String, dynamic>> getContent(String key) async {
    try {
      final res = await _dio.get('/content/get.php', queryParameters: {'key': key});
      return (res.data['content'] as Map).cast<String, dynamic>();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> getSettings() async {
    try {
      final res = await _dio.get('/content/settings.php');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
