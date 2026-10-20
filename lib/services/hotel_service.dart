import 'package:dio/dio.dart';
import '../models/hotel_model.dart';
import '../models/unit_model.dart';
import '../utils/safe_parse.dart';
import '../utils/arabic_text.dart';
import 'api_client.dart';

/// كل استدعاءات الـ API الخاصة بالضيوف: الفنادق، الوحدات، المفضلة، الحجوزات.
///
/// قواعد التحويل هنا:
/// - لا نستخدم `as List` / `as int` مباشرة — نستخدم `asMapList`/`asInt` لأن
///   السيرفر قد يعيد حقلًا مفقودًا أو نصًا بدل رقم.
/// - فشل الـ API يُرمى كـ [ApiException] مع [ApiErrorKind] — لا يُحوَّل بصمت
///   إلى قائمة فارغة (وإلا يظهر "لا توجد نتائج" عند انقطاع الشبكة).
class HotelService {
  final Dio _dio = ApiClient.instance.dio;

  /// يتحقق من نجاح الاستجابة ويرمي [ApiException] عند فشل السيرفر.
  /// بعض المسارات تعيد `success:false` مع HTTP 200.
  void _ensureSuccess(dynamic data) {
    if (data is Map && data['success'] == false) {
      throw ApiException(
        (data['message'] ?? 'Request failed').toString(),
        kind: ApiErrorKind.badResponse,
      );
    }
  }

  /// البحث/التصفح الموحّد للوحدات — يغطي البحث بالمدينة، اسم الفندق، النطاق
  /// السعري، السعة، ووحدات الملاك.
  ///
  /// ملاحظة مهمة عن الـ API: `units/browse.php` يدعم فعلًا `q` (يبحث في اسم
  /// الفندق واسم الوحدة معًا) و`city` (عربي أو إنجليزي). لذلك نمرّر نص البحث
  /// كما هو بدل إرسال طلبين منفصلين (اسم فندق + مدينة).
  Future<List<UnitModel>> browseUnits({
    String? search,
    String? city,
    bool ownerOnly = false,
    double? minPrice,
    double? maxPrice,
    int? minCapacity,
    String sort = 'newest',
    int limit = 20,
  }) async {
    try {
      final res = await _dio.get('/units/browse.php', queryParameters: {
        if (search != null && search.isNotEmpty) 'q': search,
        if (city != null && city.isNotEmpty) 'city': city,
        if (ownerOnly) 'owner_only': 1,
        if (minPrice != null) 'min_price': minPrice,
        if (maxPrice != null) 'max_price': maxPrice,
        if (minCapacity != null) 'min_capacity': minCapacity,
        'sort': sort,
        'limit': limit,
      });
      _ensureSuccess(res.data);
      return asMapList(res.data is Map ? res.data['units'] : null)
          .map(UnitModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// بحث الوحدات — يجمع نتائج السيرفر النصية (`q`) مع تصفية محلية على
  /// الاسم/الفندق/المدينة/النوع.
  ///
  /// السبب: `q` في `units/browse.php` يطابق **الأسماء فقط**، فالبحث باسم مدينة
  /// (مثل «مكة») يرجع صفرًا رغم وجود وحدات فيها (المتطلب 26). لذلك ندمج
  /// نتائج السيرفر مع تصفية محلية بنفس منطق [filterHotels]، بلا طلب مكرر
  /// وبلا `as List` غير آمن.
  Future<List<UnitModel>> searchUnits({
    String? query,
    String? city,
    double? minPrice,
    double? maxPrice,
    int? minCapacity,
    String sort = 'newest',
    int limit = 60,
  }) async {
    final q = query?.trim();
    if (q == null || q.isEmpty) {
      return browseUnits(
        city: city,
        minPrice: minPrice,
        maxPrice: maxPrice,
        minCapacity: minCapacity,
        sort: sort,
        limit: limit,
      );
    }
    final results = await Future.wait([
      // مطابقة الأسماء على السيرفر (تشمل وحدات قد تتجاوز حد التصفح المحلي).
      browseUnits(
        search: q,
        city: city,
        minPrice: minPrice,
        maxPrice: maxPrice,
        minCapacity: minCapacity,
        sort: sort,
        limit: limit,
      ),
      // القائمة الكاملة للتصفية المحلية على المدينة/الفندق/النوع.
      browseUnits(
        city: city,
        minPrice: minPrice,
        maxPrice: maxPrice,
        minCapacity: minCapacity,
        sort: sort,
        limit: limit,
      ),
    ]);
    final merged = <int, UnitModel>{};
    for (final unit in results[0]) {
      merged[unit.id] = unit;
    }
    for (final unit in filterUnits(results[1], query: q)) {
      merged[unit.id] = unit;
    }
    return merged.values.toList();
  }

  /// تصفية الوحدات نصيًا محليًا (دالة نقية قابلة للاختبار بلا شبكة).
  static List<UnitModel> filterUnits(List<UnitModel> units, {String? query}) {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery == null) return units;
    return units.where((u) {
      final haystack = [
        u.nameAr,
        u.nameEn,
        u.hotelName,
        u.cityAr,
        u.cityEn,
        u.unitTypeAr,
        u.unitTypeEn,
      ].map((v) => _normalize(v) ?? '').join(' ');
      return haystack.contains(normalizedQuery);
    }).toList();
  }

  /// قائمة الفنادق. يدعم السيرفر: `city`، `featured`، `stars`، `min_price`،
  /// `max_price`.
  ///
  /// مهم: `hotels/list.php` **لا يدعم** بحثًا نصيًا بالاسم (`q`/`search`/
  /// `name`/`keyword` كلها تُتجاهل وتُرجع كل الفنادق). لذلك لا نمرّر بحثًا
  /// نصيًا هنا — البحث بالاسم يتم عبر [searchHotels] الذي يُرشّح محليًا.
  Future<List<HotelModel>> listHotels({
    String? city,
    double? minPrice,
    double? maxPrice,
    int? stars,
    bool featuredOnly = false,
  }) async {
    try {
      final res = await _dio.get('/hotels/list.php', queryParameters: {
        if (city != null && city.isNotEmpty) 'city': city,
        if (minPrice != null) 'min_price': minPrice,
        if (maxPrice != null) 'max_price': maxPrice,
        if (stars != null) 'stars': stars,
        if (featuredOnly) 'featured': 1,
      });
      _ensureSuccess(res.data);
      return asMapList(res.data is Map ? res.data['hotels'] : null)
          .map((h) => HotelModel.fromJson(h))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// الفنادق المميزة الحقيقية من السيرفر (`featured=1`).
  Future<List<HotelModel>> featuredHotels() => listHotels(featuredOnly: true);

  /// بحث الفنادق بالاسم/المدينة/التصنيف.
  ///
  /// السيرفر لا يدعم بحثًا نصيًا على الفنادق، لذلك:
  /// 1. نجلب الفنادق (مُقيّدة بالمدينة على السيرفر عندما يكون متاحًا).
  /// 2. نُرشّح نصيًا محليًا على الاسم والمدينة والنوع (عربي + إنجليزي).
  ///
  /// هذا يضمن أن البحث عن "مكة" أو "فيرمونت" يرجع نتائج مطابقة فعلية من
  /// بيانات الـ API، وليس من قوائم ثابتة في الواجهة.
  Future<List<HotelModel>> searchHotels({
    String? query,
    String? city,
    String? categoryName,
  }) async {
    final hotels = await listHotels(city: city);
    return filterHotels(
      hotels,
      query: query,
      categoryName: categoryName,
    );
  }

  /// تصفية الفنادق نصيًا محليًا (دالة نقية قابلة للاختبار بلا شبكة).
  ///
  /// `hotels/list.php` لا يدعم بحثًا نصيًا ولا تصنيفًا على السيرفر، لذلك
  /// نُرشّح هنا على الاسم والمدينة والنوع (عربي + إنجليزي).
  static List<HotelModel> filterHotels(
    List<HotelModel> hotels, {
    String? query,
    String? categoryName,
  }) {
    final normalizedQuery = _normalize(query);
    final normalizedCategory = _normalize(categoryName);

    return hotels.where((h) {
      final typeAr = _normalize(h.typeAr) ?? '';
      final typeEn = _normalize(h.typeEn) ?? '';

      // ملاحظة: `'x'.contains('')` ترجع true، لذلك لا نسمح للنوع الفارغ
      // بمطابقة أي تصنيف — وإلا ظهر كل فندق بلا نوع تحت كل تصنيف.
      final matchesCategory = normalizedCategory == null ||
          (typeAr.isNotEmpty && typeAr.contains(normalizedCategory)) ||
          (typeEn.isNotEmpty && typeEn.contains(normalizedCategory)) ||
          (typeAr.isNotEmpty && normalizedCategory.contains(typeAr)) ||
          (typeEn.isNotEmpty && normalizedCategory.contains(typeEn));

      if (!matchesCategory) return false;
      if (normalizedQuery == null) return true;

      final haystack = [h.name, h.cityAr, h.cityEn, h.typeAr, h.typeEn]
          .map((v) => _normalize(v) ?? '')
          .join(' ');
      return haystack.contains(normalizedQuery);
    }).toList();
  }

  /// تفصيل فندق + معرض الصور + المرافق المرتبطة به فعليًا.
  Future<HotelDetail> getHotelDetail(String id) async {
    try {
      final res =
          await _dio.get('/hotels/detail.php', queryParameters: {'id': id});
      _ensureSuccess(res.data);
      final data = asMap(res.data);
      return HotelDetail(
        hotel: HotelModel.fromJson(
          asMap(data['hotel']),
          gallery: asStringList(data['gallery']),
        ),
        amenities: asMapList(data['amenities']),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// مرافق الفندق المرتبطة فعليًا (من نفس استجابة `hotels/detail.php`).
  Future<List<Map<String, dynamic>>> getHotelAmenities(String id) async {
    try {
      final res =
          await _dio.get('/hotels/detail.php', queryParameters: {'id': id});
      _ensureSuccess(res.data);
      return asMapList(res.data is Map ? res.data['amenities'] : null);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<bool> toggleFavorite(String hotelId) async {
    try {
      final res = await _dio.post('/favorites/toggle.php', data: {
        'hotel_id': asInt(hotelId),
      });
      _ensureSuccess(res.data);
      return res.data is Map && res.data['favorited'] == true;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<HotelModel>> myFavorites() async {
    try {
      final res = await _dio.get('/favorites/my.php');
      _ensureSuccess(res.data);
      return asMapList(res.data is Map ? res.data['hotels'] : null)
          .map((h) => HotelModel.fromJson(h, isFavorite: true))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// وحدات فندق معيّن من `units/list.php`.
  Future<List<UnitModel>> getUnits(String hotelId) async {
    try {
      final res = await _dio.get('/units/list.php', queryParameters: {
        'hotel_id': asInt(hotelId),
      });
      _ensureSuccess(res.data);
      return asMapList(res.data is Map ? res.data['units'] : null)
          .map(UnitModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// تفصيل وحدة — يشمل الصور، الإضافات، وفترات الإتاحة.
  Future<UnitModel> getUnitDetail(int unitId) async {
    try {
      final res =
          await _dio.get('/units/detail.php', queryParameters: {'id': unitId});
      _ensureSuccess(res.data);
      final data = asMap(res.data);
      return UnitModel.fromJson(asMap(data['unit']));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<UnitAddonModel>> getUnitAddons(int unitId) async {
    try {
      final res = await _dio
          .get('/units/addons.php', queryParameters: {'unit_id': unitId});
      _ensureSuccess(res.data);
      return asMapList(res.data is Map ? res.data['addons'] : null)
          .map(UnitAddonModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> createBooking({
    required String hotelId,
    int? unitId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guests,
    required String paymentMethod, // online | at_hotel
    String? cardNumber,
    List<String> mealTypes = const [], // يمكن اختيار أكثر من وجبة
    bool extraBed = false,
    List<int>? addonIds,
    String? guestIdNumber,
    String? customerName,
    String? customerPhone,
  }) async {
    try {
      final res = await _dio.post('/bookings/create.php', data: {
        'hotel_id': asInt(hotelId),
        if (unitId != null) 'unit_id': unitId,
        'check_in': _fmt(checkIn),
        'check_out': _fmt(checkOut),
        'guests': guests,
        'payment_method': paymentMethod,
        'meal_types': mealTypes,
        'extra_bed': extraBed,
        if (addonIds != null && addonIds.isNotEmpty) 'addon_ids': addonIds,
        if (cardNumber != null) 'card_number': cardNumber,
        'guest_id_number': guestIdNumber ?? '',
        if (customerName != null) 'customer_name': customerName,
        if (customerPhone != null) 'customer_phone': customerPhone,
      });
      _ensureSuccess(res.data);
      return asMap(res.data is Map ? res.data['booking'] : null);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> submitServiceRequest({
    int? bookingId,
    required String roomNumber,
    required String serviceType,
    String? description,
  }) async {
    try {
      final res = await _dio.post('/services/request.php', data: {
        if (bookingId != null) 'booking_id': bookingId,
        'room_number': roomNumber,
        'service_type': serviceType,
        if (description != null) 'description': description,
      });
      _ensureSuccess(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> submitMealRequest({
    required int bookingId,
    required String roomNumber,
    required List<String> mealTypes,
    String? notes,
  }) async {
    try {
      final res = await _dio.post('/services/meal-request.php', data: {
        'booking_id': bookingId,
        'room_number': roomNumber,
        'meal_types': mealTypes,
        if (notes != null) 'notes': notes,
      });
      _ensureSuccess(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Map<String, dynamic>>> myBookings() async {
    try {
      final res = await _dio.get('/bookings/my.php');
      _ensureSuccess(res.data);
      return asMapList(res.data is Map ? res.data['bookings'] : null);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> cancelMyBooking(int bookingId) async {
    try {
      final res = await _dio.post('/bookings/manage.php', data: {
        'booking_id': bookingId,
        'action': 'cancel',
      });
      _ensureSuccess(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> editMyBooking({
    required int bookingId,
    DateTime? checkIn,
    DateTime? checkOut,
    int? guests,
    String? guestName,
    String? guestPhone,
    String? notes,
  }) async {
    try {
      final res = await _dio.post('/bookings/manage.php', data: {
        'booking_id': bookingId,
        'action': 'update',
        if (checkIn != null) 'check_in': _fmt(checkIn),
        if (checkOut != null) 'check_out': _fmt(checkOut),
        if (guests != null) 'guests': guests,
        if (guestName != null) 'guest_name': guestName,
        if (guestPhone != null) 'guest_phone': guestPhone,
        if (notes != null) 'notes': notes,
      });
      _ensureSuccess(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// يوحّد النص العربي/الإنجليزي للمقارنة: يزيل التشكيل والهمزات والمسافات
  /// الزائدة، ويوحّد الألف/الهاء حتى يطابق "مكة" و"مكه" و"Makkah"/"makkah".
  static String? _normalize(String? value) => normalizeArabic(value);

  String _fmt(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}

/// نتيجة تفصيل الفندق: الفندق + مرافقه المرتبطة فعليًا.
class HotelDetail {
  final HotelModel hotel;
  final List<Map<String, dynamic>> amenities;

  const HotelDetail({required this.hotel, this.amenities = const []});
}
