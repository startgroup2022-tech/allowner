import 'package:dio/dio.dart';
import 'api_client.dart';

/// كل استدعاءات الـ API الخاصة بحساب "إدارة الفندق" (وصول/مغادرة الضيوف،
/// طلبات النظافة/الصيانة/الوجبات/السرير الإضافي، وأسعار الخدمات لكل جناح)
class HotelStaffService {
  final Dio _dio = ApiClient.instance.dio;

  Future<Map<String, dynamic>> getDashboard() async {
    try {
      final res = await _dio.get('/hotel/dashboard.php');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ===== حجوزات الفندق: تأكيد دخول/خروج الضيف =====

  Future<List<Map<String, dynamic>>> getBookings({String scope = 'active'}) async {
    try {
      final res = await _dio.get('/hotel/bookings.php', queryParameters: {'scope': scope});
      return (res.data['bookings'] as List).cast<Map<String, dynamic>>();
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
      return (res.data['requests'] as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// action: confirm | done | reject | preparing | delivered
  Future<void> actOnRequest({
    required String type,
    required int id,
    required String action,
    String? note,
    double? price,
  }) async {
    try {
      await _dio.post('/hotel/requests.php', data: {
        'type': type,
        'id': id,
        'action': action,
        if (note != null) 'note': note,
        if (price != null) 'price': price,
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
        'prices': (res.data['prices'] as List).cast<Map<String, dynamic>>(),
        'units': (res.data['units'] as List).cast<Map<String, dynamic>>(),
        'hotels': (res.data['hotels'] as List).cast<Map<String, dynamic>>(),
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
