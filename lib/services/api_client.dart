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

/// نوع الخطأ — يسمح للشاشات بالتفريق بين "غير مصرّح" و"انقطاع الشبكة" و"خطأ سيرفر"
/// وتقديم حالة خطأ مناسبة مع زر إعادة المحاولة بدل رسالة عامة.
enum ApiErrorKind {
  network,
  timeout,
  unauthorized,
  notFound,
  server,
  badResponse,
  unknown
}

/// استثناء موحّد لأخطاء الـ API مع رسالة قابلة للعرض بالعربي/الإنجليزي
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final ApiErrorKind kind;

  ApiException(this.message,
      {this.statusCode, this.kind = ApiErrorKind.unknown});

  @override
  String toString() => message;

  /// هل الخطأ ناتج عن انقطاع شبكة/مهلة؟ (مفيد لتحديد إمكانية إعادة المحاولة)
  bool get isRetryable =>
      kind == ApiErrorKind.network ||
      kind == ApiErrorKind.timeout ||
      kind == ApiErrorKind.server;

  /// هل انتهت الجلسة؟ (يجب مسح التوكن وإعادة تسجيل الدخول)
  bool get isUnauthorized => kind == ApiErrorKind.unauthorized;

  factory ApiException.fromDioError(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    // السيرفر يرسل رسالة عربية/إنجليزية واضحة داخل حقل message
    if (data is Map && data['message'] != null) {
      final kind = _kindForStatus(status);
      return ApiException(data['message'].toString(),
          statusCode: status, kind: kind);
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          'انتهت مهلة الاتصال بالسيرفر، حاول مرة أخرى / Server timed out, please retry',
          statusCode: status,
          kind: ApiErrorKind.timeout,
        );
      case DioExceptionType.connectionError:
        return ApiException(
          'تعذر الاتصال بالسيرفر، تحقق من اتصال الإنترنت / Could not connect to server',
          statusCode: status,
          kind: ApiErrorKind.network,
        );
      case DioExceptionType.badResponse:
        return ApiException(
          _messageForStatus(status),
          statusCode: status,
          kind: _kindForStatus(status),
        );
      case DioExceptionType.cancel:
        return ApiException(
          'تم إلغاء الطلب / Request cancelled',
          statusCode: status,
          kind: ApiErrorKind.unknown,
        );
      case DioExceptionType.unknown:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.badCertificate:
        return ApiException(
          'حدث خطأ غير متوقع / An unexpected error occurred',
          statusCode: status,
          kind: ApiErrorKind.unknown,
        );
    }
  }

  static ApiErrorKind _kindForStatus(int? status) {
    if (status == null) return ApiErrorKind.unknown;
    if (status == 401 || status == 403) return ApiErrorKind.unauthorized;
    if (status == 404) return ApiErrorKind.notFound;
    if (status >= 500) return ApiErrorKind.server;
    if (status >= 400) return ApiErrorKind.badResponse;
    return ApiErrorKind.unknown;
  }

  static String _messageForStatus(int? status) {
    if (status == 401 || status == 403) {
      return 'انتهت الجلسة، الرجاء تسجيل الدخول من جديد / Session expired, please log in again';
    }
    if (status == 404) {
      return 'العنصر المطلوب غير موجود / The requested item was not found';
    }
    if (status != null && status >= 500) {
      return 'خطأ في السيرفر، حاول لاحقًا / Server error, please try again later';
    }
    return 'حدث خطأ غير متوقع / An unexpected error occurred';
  }
}
