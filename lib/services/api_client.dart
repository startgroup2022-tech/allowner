import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// عنوان الـ API — نفس السيرفر يلي عليه لوحة التحكم والموقع
class ApiConfig {
  static const String baseUrl = 'https://all-owner.online/api';
}

/// عميل HTTP مركزي يضيف التوكن تلقائياً لكل طلب بعد تسجيل الدخول
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();
  late final Dio _dio;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_json');
  }

  Dio get dio => _dio;
}

/// استثناء موحّد لأخطاء الـ API مع رسالة قابلة للعرض بالعربي/الإنجليزي
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;

  factory ApiException.fromDioError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return ApiException(data['message'].toString(), statusCode: e.response?.statusCode);
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return ApiException('تعذر الاتصال بالسيرفر، تحقق من اتصال الإنترنت / Could not connect to server');
    }
    return ApiException('حدث خطأ غير متوقع / An unexpected error occurred');
  }
}
