import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';
import '../utils/safe_parse.dart';
import 'api_client.dart';

class AuthService {
  final Dio _dio = ApiClient.instance.dio;

  Future<AppUser> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    String role = 'guest',
  }) async {
    try {
      final res = await _dio.post('/auth/register.php', data: {
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'password': password,
        'role': role,
      });
      return await _handleAuthResponse(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<AppUser> login(
      {required String email, required String password}) async {
    try {
      final res = await _dio.post('/auth/login.php', data: {
        'email': email,
        'password': password,
      });
      return await _handleAuthResponse(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<AppUser> updateProfile({
    required String fullName,
    String? phone,
    String? currentPassword,
    String? newPassword,
  }) async {
    try {
      final res = await _dio.post('/user/update-profile.php', data: {
        'full_name': fullName,
        'phone': phone ?? '',
        if (currentPassword != null) 'current_password': currentPassword,
        if (newPassword != null) 'new_password': newPassword,
      });
      final user = AppUser.fromJson(res.data['user']);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_json', jsonEncode(user.toJson()));
      return user;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<AppUser> updateAvatar({String? filePath, bool remove = false}) async {
    try {
      final formData = FormData.fromMap({
        if (remove) 'remove': '1',
        if (!remove && filePath != null)
          'avatar': await MultipartFile.fromFile(filePath),
      });
      final res = await _dio.post('/user/avatar.php', data: formData);
      final user = AppUser.fromJson(res.data['user']);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_json', jsonEncode(user.toJson()));
      return user;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout.php');
    } catch (_) {
      // نتجاهل أي خطأ بالشبكة أثناء تسجيل الخروج، المهم مسح التوكن محلياً
    }
    await ApiClient.instance.clearToken();
  }

  /// يحاول استرجاع المستخدم من التخزين المحلي، ويتحقق من صلاحية التوكن مع السيرفر.
  ///
  /// مهم: لا نمسح الجلسة عند انقطاع الشبكة — فقط عند رد السيرفر بأن التوكن غير
  /// صالح (401/403). النسخة السابقة كانت تمسح الجلسة عند أي خطأ شبكة، فيُطرد
  /// المستخدم لمجرد أنه بلا إنترنت لحظيًا.
  Future<AppUser?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null || token.isEmpty) return null;

    try {
      final res = await _dio.get('/auth/me.php');
      final user =
          AppUser.fromJson(asMap(res.data is Map ? res.data['user'] : null));
      await prefs.setString('user_json', jsonEncode(user.toJson()));
      return user;
    } on DioException catch (e) {
      final apiError = ApiException.fromDioError(e);
      if (apiError.isUnauthorized) {
        await ApiClient.instance.clearToken();
        return null;
      }
      // خطأ شبكة/سيرفر — نُرجع بيانات المستخدم المخزّنة محليًا بدل تسجيل الخروج
      return _cachedUser(prefs);
    }
  }

  /// يقرأ آخر مستخدم محفوظ محليًا (يُستخدم عند تعذّر الاتصال).
  AppUser? _cachedUser(SharedPreferences prefs) {
    final raw = prefs.getString('user_json');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return AppUser.fromJson(decoded.cast<String, dynamic>());
      }
    } catch (_) {
      // بيانات محلية تالفة — نتجاهلها ونعيد null
    }
    return null;
  }

  Future<AppUser> _handleAuthResponse(dynamic rawData) async {
    final data = asMap(rawData);
    final token = asStringOrNull(data['token']);
    if (token == null) {
      throw ApiException(
        (data['message'] ?? 'Login response is missing the token').toString(),
        kind: ApiErrorKind.badResponse,
      );
    }
    final user = AppUser.fromJson(asMap(data['user']));
    await ApiClient.instance.saveToken(token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_json', jsonEncode(user.toJson()));
    return user;
  }
}
