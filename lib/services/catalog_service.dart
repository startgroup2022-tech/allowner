import 'package:dio/dio.dart';
import '../models/category_model.dart';
import '../models/city_model.dart';
import '../utils/safe_parse.dart';
import 'api_client.dart';

/// كتالوج الواجهة الرئيسية: المدن والتصنيفات — كلها من قاعدة البيانات.
///
/// سبب وجود هذا الـ service: الصفحة الرئيسية السابقة كانت تحتوي قائمة مدن
/// ثابتة في الكود (`['مكة المكرمة', 'المدينة المنورة', 'الرياض', 'جدة']`) وقائمة
/// تصنيفات ثابتة أيضًا. هذا يعني أن أي مدينة أو تصنيف يضيفه الأدمن من لوحة
/// التحكم لا يظهر في التطبيق. الآن نقرأها من `cities/list.php` و
/// `categories/list.php`.
class CatalogService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<CityModel>> listCities() async {
    try {
      final res = await _dio.get('/cities/list.php');
      _ensureSuccess(res.data);
      return asMapList(res.data is Map ? res.data['cities'] : null)
          .map(CityModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<CategoryModel>> listCategories() async {
    try {
      final res = await _dio.get('/categories/list.php');
      _ensureSuccess(res.data);
      return asMapList(res.data is Map ? res.data['categories'] : null)
          .map(CategoryModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  void _ensureSuccess(dynamic data) {
    if (data is Map && data['success'] == false) {
      throw ApiException(
        (data['message'] ?? 'Request failed').toString(),
        kind: ApiErrorKind.badResponse,
      );
    }
  }
}
