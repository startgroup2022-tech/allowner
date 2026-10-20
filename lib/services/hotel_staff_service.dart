import 'package:dio/dio.dart';
import '../utils/safe_parse.dart';
import 'api_client.dart';

/// كل استدعاءات الـ API الخاصة بحساب "إدارة الفندق" (وصول/مغادرة الضيوف،
/// طلبات النظافة/الصيانة/الوجبات/السرير الإضافي، وأسعار الخدمات لكل جناح)
class HotelStaffService {
  final Dio _dio = ApiClient.instance.dio;

  Future<Map<String, dynamic>> getDashboard() async {
    try {
      final res = await _dio.get('/hotel/dashboard.php');
      return asMap(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ===== حجوزات الفندق: تأكيد دخول/خروج الضيف =====

  Future<List<Map<String, dynamic>>> getBookings({String scope = 'active'}) async {
    try {
      final res = await _dio.get('/hotel/bookings.php', queryParameters: {'scope': scope});
      return asMapList(res.data['bookings']);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> checkIn(int bookingId) async {
    try {
      await _dio.post('/hotel/bookings.php', data: {'booking_id': bookingId, 'action': 'check_in'});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> checkOut(int bookingId) async {
    try {
      await _dio.post('/hotel/bookings.php', data: {'booking_id': bookingId, 'action': 'check_out'});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ===== طلبات الخدمة: نظافة | صيانة | وجبات | سرير إضافي =====
  // type: cleaning | maintenance | meal | extra_bed

  Future<List<Map<String, dynamic>>> getRequests({required String type, String status = 'open'}) async {
    try {
      final res = await _dio.get('/hotel/requests.php', queryParameters: {'type': type, 'status': status});
      return asMapList(res.data['requests']);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// action: confirm | done | reject | preparing | delivered
  ///
  /// [settlement] (المتطلبات 390–394): عند تأكيد طلب الصيانة يختار المستخدم
  /// «خصم من رصيد الوحدة» أو «إرسال رابط الدفع عبر واتساب». القيمة تُرسل في
  /// الحقل `settlement`؛ إن لم يعرفها السيرفر بعد فلا يضر وجودها.
  Future<void> actOnRequest({
    required String type,
    required int id,
    required String action,
    String? note,
    double? price,
    String? imagePath,
    String? settlement,
  }) async {
    try {
      // المتطلب 92: صورة اختيارية لطلب الصيانة من حساب إدارة الفندق.
      if (imagePath != null) {
        final form = FormData.fromMap({
          'type': type,
          'id': id.toString(),
          'action': action,
          if (note != null) 'note': note,
          if (price != null) 'price': price.toString(),
          if (settlement != null) 'settlement': settlement,
          'image': await MultipartFile.fromFile(imagePath),
        });
        await _dio.post('/hotel/requests.php', data: form);
        return;
      }
      await _dio.post('/hotel/requests.php', data: {
        'type': type,
        'id': id,
        'action': action,
        if (note != null) 'note': note,
        if (price != null) 'price': price,
        if (settlement != null) 'settlement': settlement,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ===== أسعار خدمات الفندق (لكل جناح/نوع خدمة) =====

  Future<Map<String, dynamic>> getPrices() async {
    try {
      final res = await _dio.get('/hotel/prices.php');
      return {
        'prices': asMapList(res.data['prices']),
        'units': asMapList(res.data['units']),
        'hotels': asMapList(res.data['hotels']),
      };
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> savePrice({
    int? id,
    required int hotelId,
    int? unitId,
    required String serviceType,
    String? titleAr,
    String? titleEn,
    required double price,
    bool isActive = true,
  }) async {
    try {
      await _dio.post('/hotel/prices.php', data: {
        'action': 'save',
        if (id != null) 'id': id,
        'hotel_id': hotelId,
        if (unitId != null) 'unit_id': unitId,
        'service_type': serviceType,
        if (titleAr != null) 'title_ar': titleAr,
        if (titleEn != null) 'title_en': titleEn,
        'price': price,
        'is_active': isActive,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deletePrice(int id) async {
    try {
      await _dio.post('/hotel/prices.php', data: {'action': 'delete', 'id': id});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
