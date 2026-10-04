import 'dart:convert';
import 'package:dio/dio.dart';
import 'api_client.dart';

/// كل استدعاءات الـ API الخاصة بلوحة المالك (الوحدات، الحجوزات، الإيرادات، الصيانة)
class OwnerService {
  final Dio _dio = ApiClient.instance.dio;

  Future<Map<String, dynamic>> getDashboard() async {
    try {
      final res = await _dio.get('/user/owner-dashboard.php');
      return (res.data['stats'] as Map).cast<String, dynamic>();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getHotels() async {
    try {
      final res = await _dio.get('/user/owner-dashboard.php');
      return (res.data['hotels'] as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getUnits() async {
    try {
      final res = await _dio.get('/user/owner-units.php');
      return (res.data['units'] as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> getBookings() async {
    try {
      final res = await _dio.get('/user/owner-bookings.php');
      return {
        'bookings': (res.data['bookings'] as List).cast<Map<String, dynamic>>(),
        'revenue': (res.data['revenue'] as num).toDouble(),
      };
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> cancelBooking(int bookingId) async {
    try {
      await _dio.post('/user/owner-bookings.php', data: {'booking_id': bookingId, 'action': 'cancel'});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// تأكيد حجز بانتظار المالك — يُبلَّغ الفندق والعميل تلقائياً بإيميل
  Future<void> confirmBooking(int bookingId) async {
    try {
      await _dio.post('/user/owner-bookings.php', data: {'booking_id': bookingId, 'action': 'confirm'});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// تعديل بيانات حجز (تواريخ / عدد ضيوف / اسم أو جوال الضيف / ملاحظات)
  Future<double?> editBooking({
    required int bookingId,
    DateTime? checkIn,
    DateTime? checkOut,
    int? guests,
    String? guestName,
    String? guestPhone,
    String? notes,
  }) async {
    try {
      final res = await _dio.post('/user/owner-bookings.php', data: {
        'booking_id': bookingId,
        'action': 'update',
        if (checkIn != null) 'check_in': _fmt(checkIn),
        if (checkOut != null) 'check_out': _fmt(checkOut),
        if (guests != null) 'guests': guests,
        if (guestName != null) 'guest_name': guestName,
        if (guestPhone != null) 'guest_phone': guestPhone,
        if (notes != null) 'notes': notes,
      });
      final total = res.data['total'];
      return total is num ? total.toDouble() : null;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ===== طلبات المالك للفندق: النظافة + السرير الإضافي =====
  // type: cleaning | extra_bed

  Future<List<Map<String, dynamic>>> getOwnerHotelRequests({required String type}) async {
    try {
      final res = await _dio.get('/user/owner-requests.php', queryParameters: {'type': type});
      return (res.data['requests'] as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> createOwnerHotelRequest({
    required String type,
    required int hotelId,
    required int unitId,
    String? description,
  }) async {
    try {
      await _dio.post('/user/owner-requests.php', data: {
        'type': type,
        'hotel_id': hotelId,
        'unit_id': unitId,
        if (description != null) 'description': description,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> cancelOwnerHotelRequest(int id) async {
    try {
      await _dio.post('/user/owner-requests.php', data: {'action': 'cancel', 'id': id});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> getRevenue() async {
    try {
      final res = await _dio.get('/user/owner-revenue.php');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ===== عملاء الوكيل / مندوب التسويق =====

  Future<List<Map<String, dynamic>>> getAgentClients() async {
    try {
      final res = await _dio.get('/user/agent-clients.php');
      return (res.data['clients'] as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> getAgentClientDetail(int id) async {
    try {
      final res = await _dio.get('/user/agent-clients.php', queryParameters: {'id': id});
      return {
        'client': (res.data['client'] as Map).cast<String, dynamic>(),
        'bookings': (res.data['bookings'] as List).cast<Map<String, dynamic>>(),
      };
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> saveAgentClient({
    int? id,
    required String fullName,
    required String phone,
    String? email,
    String? idNumber,
    String? notes,
  }) async {
    try {
      await _dio.post('/user/agent-clients.php', data: {
        'action': id == null ? 'add' : 'update',
        if (id != null) 'id': id,
        'full_name': fullName,
        'phone': phone,
        if (email != null) 'email': email,
        if (idNumber != null) 'id_number': idNumber,
        if (notes != null) 'notes': notes,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteAgentClient(int id) async {
    try {
      await _dio.post('/user/agent-clients.php', data: {'action': 'delete', 'id': id});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> getMyCommission() async {
    try {
      final res = await _dio.get('/user/agent-commission.php');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getMaintenanceRequests() async {
    try {
      final res = await _dio.get('/user/owner-maintenance.php');
      return (res.data['requests'] as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getMealRequests() async {
    try {
      final res = await _dio.get('/user/owner-meals.php');
      return (res.data['requests'] as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> updateMealRequestStatus({required int requestId, required String status}) async {
    try {
      await _dio.post('/user/owner-meals.php', data: {'request_id': requestId, 'status': status});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> createMaintenanceRequest({
    required int hotelId,
    int? unitId,
    required String title,
    String? description,
  }) async {
    try {
      await _dio.post('/user/owner-maintenance.php', data: {
        'hotel_id': hotelId,
        if (unitId != null) 'unit_id': unitId,
        'title': title,
        if (description != null) 'description': description,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getDocuments() async {
    try {
      final res = await _dio.get('/documents/list.php');
      return (res.data['documents'] as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getDecisions() async {
    try {
      final res = await _dio.get('/decisions/list.php');
      return (res.data['decisions'] as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> castVote({required int decisionId, required int optionId}) async {
    try {
      await _dio.post('/decisions/vote.php', data: {'decision_id': decisionId, 'option_id': optionId});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> createDecision({
    required int hotelId,
    required String title,
    String? description,
    required List<String> options,
  }) async {
    try {
      await _dio.post('/decisions/create.php', data: {
        'hotel_id': hotelId,
        'title': title,
        if (description != null) 'description': description,
        'options': options,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getCommunityPosts() async {
    try {
      final res = await _dio.get('/community/list.php');
      return (res.data['posts'] as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> createCommunityPost(String content) async {
    try {
      await _dio.post('/community/post.php', data: {'content': content});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> toggleCommunityLike(int postId) async {
    try {
      await _dio.post('/community/like.php', data: {'post_id': postId});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getPostComments(int postId) async {
    try {
      final res = await _dio.get('/community/comments.php', queryParameters: {'post_id': postId});
      return (res.data['comments'] as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> addComment(int postId, String content) async {
    try {
      await _dio.post('/community/comments.php', data: {'post_id': postId, 'content': content});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getMarketplaceListings() async {
    try {
      final res = await _dio.get('/marketplace/list.php');
      return (res.data['listings'] as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> createListing({
    required int unitId,
    required double price,
    String? description,
    String? contactPhone,
  }) async {
    try {
      await _dio.post('/marketplace/create.php', data: {
        'unit_id': unitId,
        'price': price,
        if (description != null && description.isNotEmpty) 'description': description,
        if (contactPhone != null && contactPhone.isNotEmpty) 'contact_phone': contactPhone,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> expressInterest(int listingId, {String? message}) async {
    try {
      await _dio.post('/marketplace/interest.php', data: {'listing_id': listingId, if (message != null) 'message': message});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final res = await _dio.get('/messages/conversations.php');
      return (res.data['conversations'] as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getOwnerDirectory() async {
    try {
      final res = await _dio.get('/messages/directory.php');
      return (res.data['owners'] as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getThread(int conversationId) async {
    try {
      final res = await _dio.get('/messages/thread.php', queryParameters: {'conversation_id': conversationId});
      return (res.data['messages'] as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<int> sendMessage({int? conversationId, int? recipientId, required String body}) async {
    try {
      final res = await _dio.post('/messages/send.php', data: {
        if (conversationId != null) 'conversation_id': conversationId,
        if (recipientId != null) 'recipient_id': recipientId,
        'body': body,
      });
      return res.data['conversation_id'] as int;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final res = await _dio.get('/user/notifications.php');
      return (res.data['notifications'] as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> markAllNotificationsRead() async {
    try {
      await _dio.post('/user/notifications.php', data: {'mark_all_read': true});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ===== الموظفون (مدراء الوحدات) =====

  Future<List<Map<String, dynamic>>> getStaff() async {
    try {
      final res = await _dio.get('/user/owner-staff.php');
      return (res.data['staff'] as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> createUnitManager({
    required String fullName,
    required String email,
    String? phone,
    required String password,
  }) async {
    try {
      await _dio.post('/user/owner-staff.php', data: {
        'action': 'create_unit_manager',
        'full_name': fullName,
        'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        'password': password,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> toggleStaffStatus(int staffId) async {
    try {
      await _dio.post('/user/owner-staff.php', data: {'action': 'toggle_status', 'id': staffId});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> resetStaffPassword(int staffId, String newPassword) async {
    try {
      await _dio.post('/user/owner-staff.php', data: {
        'action': 'reset_password',
        'id': staffId,
        'new_password': newPassword,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ===== الوحدات =====

  Future<Map<String, dynamic>> getUnitsFull() async {
    try {
      final res = await _dio.get('/user/owner-units.php');
      return {
        'units': (res.data['units'] as List).cast<Map<String, dynamic>>(),
        'hotels': (res.data['hotels'] as List).cast<Map<String, dynamic>>(),
        'can_create': res.data['can_create'] == true,
      };
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> createUnit({
    required int hotelId,
    required String nameAr,
    required String nameEn,
    String? unitTypeAr,
    String? unitTypeEn,
    int bedCount = 1,
    String? descriptionAr,
    String? descriptionEn,
    String? unitNumber,
    required int capacity,
    required double pricePerNight,
    double? pricePerWeek,
    double? pricePerMonth,
    String? coverImagePath,
    List<String>? galleryPaths,
    List<Map<String, dynamic>>? addons,
    List<Map<String, String>>? availabilityPeriods,
  }) async {
    try {
      final formData = FormData.fromMap({
        'action': 'create',
        'hotel_id': hotelId.toString(),
        'name_ar': nameAr,
        'name_en': nameEn,
        'unit_type_ar': unitTypeAr ?? '',
        'unit_type_en': unitTypeEn ?? '',
        'bed_count': bedCount.toString(),
        'description_ar': descriptionAr ?? '',
        'description_en': descriptionEn ?? '',
        'unit_number': unitNumber ?? '',
        'capacity': capacity.toString(),
        'price_per_night': pricePerNight.toString(),
        if (pricePerWeek != null) 'price_per_week': pricePerWeek.toString(),
        if (pricePerMonth != null) 'price_per_month': pricePerMonth.toString(),
        if (coverImagePath != null) 'cover_image': await MultipartFile.fromFile(coverImagePath),
        if (galleryPaths != null)
          'gallery[]': [for (final p in galleryPaths) await MultipartFile.fromFile(p)],
        if (addons != null && addons.isNotEmpty) 'addons': jsonEncode(addons),
        if (availabilityPeriods != null && availabilityPeriods.isNotEmpty)
          'avail_from[]': [for (final p in availabilityPeriods) p['from']!],
        if (availabilityPeriods != null && availabilityPeriods.isNotEmpty)
          'avail_to[]': [for (final p in availabilityPeriods) p['to']!],
      });
      await _dio.post('/user/owner-units.php', data: formData);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ===== تبديل حالة الوحدة (متاحة/موقوفة) =====

  Future<void> toggleUnitStatus(int unitId) async {
    try {
      await _dio.post('/user/owner-units.php', data: {'unit_id': unitId});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
