/// بنية توليد لقطات الشاشة الحقيقية (المستندان 05 و06).
///
/// هذا الملف ليس اختبارًا: إنه حمولات الـ API (بنفس شكل استجابات الإنتاج) +
/// محوّل Dio + أدوات التقاط تطابق المخرجات. تُستخدم من
/// `test/screenshot_export_test.dart` عبر `flutter test --update-goldens`،
/// فتُنتج PNG حقيقية من رسم شجرة الودجات الإنتاجية — لا صور مُعاد رسمها.
///
/// قاعدة صريحة: الحمولات هنا **بيانات اختبار موسومة** (فندق «فيرمونت مكه»،
/// ضيف «محمد علي»)، ولا تُستخدم في كود الإنتاج، ولا تُمثّل عملية مالية ناجحة.
library;

import 'dart:convert';
import 'dart:io';

import 'package:allowners/services/api_client.dart';
import 'package:allowners/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'image_diff.dart';

/// مسار مجلد اللقطات، نسبيًا لملف الاختبار (`test/`).
const String kShotDir = '../docs/evidence/final-acceptance';

/// يحمّل خطوط العلامة الحقيقية داخل بيئة الاختبار حتى تُرسم النصوص العربية
/// والأيقونات بلا مربعات (الحالة الافتراضية في flutter_test هي خط Ahem).
Future<void> loadBrandFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  // الشاشات التي تستخدم `cached_network_image` تطلب مجلدات النظام عبر
  // `path_provider`، ولا إضافة منصّة في بيئة الاختبار — نوجّهها إلى /tmp.
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (call) async => Directory.systemTemp.path,
  );
  // لا شبكة في الاختبار: نمنع google_fonts من محاولة التنزيل (يفشل ويُسقط
  // اللقطة) ونعتمد على الخطوط المحمّلة أدناه من `test/screenshot_assets`.
  GoogleFonts.config.allowRuntimeFetching = false;
  const base = 'test/screenshot_assets/fonts';
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    var added = false;
    for (final file in files) {
      final f = File('$base/$file');
      if (!f.existsSync()) continue;
      final bytes = await f.readAsBytes();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
      added = true;
    }
    if (added) await loader.load();
  }

  const arabic = [
    'IBMPlexSansArabic-Regular.ttf',
    'IBMPlexSansArabic-SemiBold.ttf',
    'IBMPlexSansArabic-Bold.ttf',
  ];
  await load('IBM Plex Sans Arabic', arabic);
  await load('Inter', ['Inter-Regular.ttf']);
  await load('Roboto', [...arabic, 'Inter-Regular.ttf']);
  await load('MaterialIcons', ['MaterialIcons-Regular.otf']);
}

// ===== الحمولات =====

const citiesJson = {
  'success': true,
  'cities': [
    {'id': 2, 'name_ar': 'جدة', 'name_en': 'Jeddah', 'image_url': ''},
    {'id': 3, 'name_ar': 'مكة المكرمة', 'name_en': 'Makkah', 'image_url': ''},
    {
      'id': 4,
      'name_ar': 'المدينة المنورة',
      'name_en': 'Madinah',
      'image_url': ''
    },
  ],
};

const categoriesJson = {
  'success': true,
  'categories': [
    {
      'id': 1,
      'name_ar': 'فنادق',
      'name_en': 'Hotels',
      'icon_key': 'hotels',
      'color_hex': '#14151A'
    },
    {
      'id': 2,
      'name_ar': 'شقق فندقية',
      'name_en': 'Apartments',
      'icon_key': 'apartments',
      'color_hex': '#4A5568'
    },
  ],
};

const hotelsJson = {
  'success': true,
  'hotels': [
    {
      'id': 2,
      'name': 'فندق فيرمونت مكه',
      'city_ar': 'مكة المكرمة',
      'city_en': 'Makkah',
      'type_ar': 'فندق',
      'type_en': 'Hotel',
      'stars': 5,
      'rating': 4.8,
      'reviews_count': 12,
      'price_per_night': 1500,
      'free_cancellation': true,
      'cover_image': '',
      'is_featured': 1,
      'units_count': 12,
    },
    {
      'id': 3,
      'name': 'فندق العنوان',
      'city_ar': 'مكة المكرمة',
      'city_en': 'Makkah',
      'type_ar': 'فندق',
      'type_en': 'Hotel',
      'stars': 4,
      'rating': 4.2,
      'reviews_count': 8,
      'price_per_night': 900,
      'cover_image': '',
      'is_featured': 0,
      'units_count': 6,
    },
  ],
};

const unitsJson = {
  'success': true,
  'units': [
    {
      'id': 13,
      'hotel_id': 2,
      'name_ar': 'جناح عائلي',
      'name_en': 'Family suite',
      'unit_type_ar': 'جناح عائلي',
      'unit_number': '402',
      'capacity': 2,
      'bed_count': 1,
      'price_per_night': 1500,
      'cover_image': '',
      'hotel_name': 'فندق فيرمونت مكه',
      'city_ar': 'مكة المكرمة',
      'city_en': 'Makkah',
    },
    {
      'id': 14,
      'hotel_id': 2,
      'name_ar': 'غرفة مزدوجة',
      'name_en': 'Double room',
      'unit_type_ar': 'غرفة مزدوجة',
      'unit_number': '1205',
      'capacity': 2,
      'bed_count': 2,
      'price_per_night': 900,
      'cover_image': '',
      'hotel_name': 'فندق فيرمونت مكه',
      'city_ar': 'مكة المكرمة',
      'city_en': 'Makkah',
    },
  ],
};

const hotelDetailJson = {
  'success': true,
  'hotel': {
    'id': 2,
    'name': 'فندق فيرمونت مكه',
    'city_ar': 'مكة المكرمة',
    'city_en': 'Makkah',
    'type_ar': 'فندق',
    'type_en': 'Hotel',
    'stars': 5,
    'rating': 4.8,
    'reviews_count': 12,
    'price_per_night': 1500,
    'description_ar': 'فندق قريب من الحرم، وحدات مملوكة لأفراد.',
    'extra_bed_price': 150,
    'description_en': 'A hotel near the Haram with individually owned units.',
    'cover_image': '',
  },
  'gallery': [],
  'amenities': [
    {'id': 1, 'name_ar': 'واي فاي', 'name_en': 'Wi-Fi', 'icon_key': 'wifi'},
    {
      'id': 2,
      'name_ar': 'موقف سيارات',
      'name_en': 'Parking',
      'icon_key': 'parking'
    },
  ],
  'reviews': [],
};

const unitDetailJson = {
  'success': true,
  'unit': {
    'id': 13,
    'hotel_id': 2,
    'name_ar': 'جناح عائلي',
    'name_en': 'Family suite',
    'unit_type_ar': 'جناح عائلي',
    'unit_number': '402',
    'capacity': 2,
    'bed_count': 1,
    'price_per_night': 1500,
    'description_ar': 'جناح واسع بإطلالة على الحرم.',
    'description_en': 'A spacious suite overlooking the Haram.',
    'cover_image': '',
    'hotel_name': 'فندق فيرمونت مكه',
    'city_ar': 'مكة المكرمة',
    'city_en': 'Makkah',
    'extra_bed_price': 150,
  },
  'addons': [
    {
      'id': 5,
      'name_ar': 'إفطار',
      'name_en': 'Breakfast',
      'category': 'meal_plan',
      'price': 60,
      'price_unit': 'per_person_per_night',
    },
    {
      'id': 6,
      'name_ar': 'غداء',
      'name_en': 'Lunch',
      'category': 'meal_plan',
      'price': 80,
      'price_unit': 'per_person_per_night',
    },
  ],
  'availability': [
    {'date_from': '2026-11-01', 'date_to': '2026-12-31'},
  ],
};

const hotelDashboardJson = {
  'success': true,
  'hotels': [
    {'id': 2, 'name': 'فندق فيرمونت مكه'},
  ],
  'pending': {'cleaning': 3, 'maintenance': 1, 'meal': 2, 'extra_bed': 1},
  'arrivals_today': 5,
  'departures_today': 4,
  'in_house': 12,
};

const hotelBookingsJson = {
  'success': true,
  'bookings': [
    {
      'id': 31,
      'guest_name': 'محمد علي',
      'guest_phone': '0500000000',
      'hotel_name': 'فندق فيرمونت مكه',
      'unit_name_ar': 'جناح عائلي',
      'unit_name_en': 'Family Suite',
      'unit_number': '402',
      'check_in': '2026-11-01',
      'check_out': '2026-11-03',
      'guests': 2,
      'status': 'confirmed',
      'can_check_in': true,
      'can_check_out': false,
    },
    {
      'id': 32,
      'guest_name': 'سارة أحمد',
      'hotel_name': 'فندق فيرمونت مكه',
      'unit_name_ar': 'غرفة مزدوجة',
      'unit_name_en': 'Double Room',
      'unit_number': '1205',
      'check_in': '2026-11-20',
      'check_out': '2026-11-22',
      'guests': 1,
      'status': 'confirmed',
      'can_check_in': false,
      'can_check_out': true,
    },
  ],
};

const hotelRequestsJson = {
  'success': true,
  'requests': [
    {
      'id': 7,
      'type': 'cleaning',
      'guest_name': 'محمد علي',
      'unit_name_ar': 'جناح عائلي',
      'unit_name_en': 'Family Suite',
      'unit_number': '402',
      'description': 'تنظيف بعد المغادرة',
      'status': 'pending',
      'price': '120',
      'approved_price': '120',
      'can_confirm': true,
    },
  ],
};

const hotelMealRequestsJson = {
  'success': true,
  'requests': [
    {
      'id': 41,
      'type': 'meal',
      'guest_name': 'محمد علي',
      'unit_name_ar': 'جناح عائلي',
      'unit_name_en': 'Family Suite',
      'unit_number': '402',
      'meal_types': ['breakfast', 'lunch'],
      'status': 'pending',
      'price': '140',
      'approved_price': '140',
      'can_confirm': true,
    },
  ],
};

const hotelExtraBedRequestsJson = {
  'success': true,
  'requests': [
    {
      'id': 51,
      'type': 'extra_bed',
      'guest_name': 'محمد علي',
      'unit_name_ar': 'جناح عائلي',
      'unit_name_en': 'Family Suite',
      'unit_number': '402',
      'beds': 2,
      'nights': 3,
      'approved_price': '150',
      'status': 'pending',
      'can_confirm': true,
    },
  ],
};

const hotelPricesJson = {
  'success': true,
  'prices': [
    {
      'id': 9,
      'service_type': 'cleaning',
      'title_ar': 'تنظيف',
      'title_en': 'Cleaning',
      'unit_id': 13,
      'price': '120',
    },
    {
      'id': 10,
      'service_type': 'maintenance',
      'title_ar': 'صيانة',
      'title_en': 'Maintenance',
      'unit_id': 13,
      'price': '250',
    },
  ],
  'units': [
    {'id': 13, 'name_ar': 'جناح عائلي', 'name_en': 'Family Suite'},
  ],
};

const unitPricingJson = {
  'success': true,
  'units': [
    {'unit_type_ar': 'جناح عائلي', 'unit_type_en': 'Family suite'},
    {'unit_type_ar': 'غرفة مزدوجة', 'unit_type_en': 'Double room'},
  ],
  'records': [
    {
      'id': 3,
      'title': 'أسعار نوفمبر',
      'pricing_date': '2026-11-01',
      'rows': [
        {
          'unit_type': 'جناح عائلي',
          'unit_type_ar': 'جناح عائلي',
          'unit_type_en': 'Family suite',
          'price': '1500'
        },
        {
          'unit_type': 'غرفة مزدوجة',
          'unit_type_ar': 'غرفة مزدوجة',
          'unit_type_en': 'Double room',
          'price': '900'
        },
      ],
    },
  ],
};

const mealPricingJson = {
  'success': true,
  'records': [
    {
      'id': 4,
      'title': 'أسعار الوجبات',
      'pricing_date': '2026-11-01',
      'meals': [
        {'name': 'إفطار', 'price': '60'},
        {'name': 'غداء', 'price': '80'},
        {'name': 'عشاء', 'price': '70'},
      ],
    },
  ],
};

const ownerDashboardJson = {
  'success': true,
  'stats': {
    'units_count': 3,
    'bookings_count': 12,
    'pending_bookings': 2,
    'revenue': '12000',
    'total_bookings': 4,
    'total_commission': '600',
    'paid': '400',
    'unpaid': '200',
  },
};

const ownerBookingsJson = {
  'success': true,
  'bookings': [
    {
      'id': 31,
      'booking_ref': 'BK-1001',
      'guest_name': 'محمد علي',
      'guest_phone': '0500000000',
      'guest_id_number': '1234567890',
      'hotel_name': 'فندق فيرمونت مكه',
      'unit_name': 'جناح عائلي',
      'unit_number': '402',
      'check_in': '2026-11-01',
      'check_out': '2026-11-03',
      'total': '1500',
      'status': 'confirmed',
      'can_cancel': true,
      'can_confirm': false,
      'can_edit': true,
      'booking_source': 'app',
      'meal_types': ['breakfast', 'lunch'],
      'extra_bed_count': 2,
      'extra_bed_price': 150,
      'notes': 'وصول متأخر',
    },
  ],
};

const ownerCleaningJson = {
  'success': true,
  'requests': [
    {
      'id': 11,
      'description': 'تنظيف بعد المغادرة',
      'status': 'closed',
      'hotel_name': 'فندق فيرمونت مكه',
      'unit_name_ar': 'جناح عائلي',
      'unit_name_en': 'Family Suite',
      'hotel_note': 'تم التنظيف',
      'price': '120',
      'can_cancel': false,
    },
  ],
};

const ownerMealsJson = {
  'success': true,
  'requests': [
    {
      'id': 21,
      'guest_name': 'محمد علي',
      'hotel_name': 'فندق فيرمونت مكه',
      'room_number': '402',
      'meal_type': 'إفطار',
      'notes': 'بدون سكر',
      'status': 'pending',
      'price': '60',
    },
  ],
};

const ownerMaintenanceJson = {
  'success': true,
  'requests': [
    {
      'id': 7,
      'title': 'تسريب ماء',
      'description': 'الحنفية تسرّب',
      'status': 'in_progress',
      'hotel_name': 'فندق فيرمونت مكه',
      'unit_name': 'جناح عائلي',
      'hotel_note': 'الفني في الطريق',
      'price': 250,
    },
  ],
};

const ownerRevenueJson = {
  'success': true,
  'total_revenue': '12000',
  'maintenance_expense': '500',
  'cleaning_expense': '300',
  'monthly': [
    {'month': '2025-01', 'total': '5000'},
    {'month': '2026-01', 'total': '7000'},
  ],
  'units': [
    {'unit_name': 'جناح عائلي', 'revenue': '7000'},
  ],
};

const ownerWalletJson = {
  'success': true,
  'balance': '4200',
  'available_for_transfer': '3600',
  'pending_settlement': '600',
  'total_commission': '600',
  'expenses': '800',
  'transactions': [
    {
      'id': 1,
      'type': 'credit',
      'amount': '1500',
      'description': 'حجز BK-1001',
      'created_at': '2026-11-02',
      'status': 'completed',
    },
    {
      'id': 2,
      'type': 'debit',
      'amount': '120',
      'description': 'تنظيف الوحدة 402',
      'created_at': '2026-11-03',
      'status': 'completed',
    },
  ],
};

const ownerServicePricesJson = {
  'success': true,
  'prices': [
    {
      'id': 9,
      'service_type': 'cleaning',
      'title_ar': 'تنظيف',
      'title_en': 'Cleaning',
      'unit_id': 13,
      'price': '120',
    },
    {
      'id': 10,
      'service_type': 'maintenance',
      'title_ar': 'صيانة',
      'title_en': 'Maintenance',
      'unit_id': 13,
      'price': '250',
    },
  ],
  'units': [
    {'id': 13, 'name_ar': 'جناح عائلي', 'name_en': 'Family Suite'},
  ],
  'hotels': [
    {'id': 2, 'name': 'فندق فيرمونت مكه'},
  ],
};

const ownerStaffJson = {
  'success': true,
  'staff': [
    {
      'id': 6,
      'full_name': 'مدير الوحدات',
      'email': 'manager@example.com',
      'phone': '0522222222',
      'role': 'unit_manager',
      'status': 'active',
    },
  ],
};

const ownerUnitsJson = {
  'success': true,
  'can_create': true,
  'units': [
    {
      'id': 13,
      'name_ar': 'جناح عائلي',
      'name_en': 'Family Suite',
      'hotel_name': 'فندق فيرمونت مكه',
      'unit_number': '402',
      'price_per_night': 750,
      'is_active': 1,
    },
  ],
  'hotels': [
    {'id': 2, 'name': 'فندق فيرمونت مكه'},
  ],
};

const agentClientsJson = {
  'success': true,
  'clients': [
    {
      'id': 1,
      'full_name': 'عميل الوكيل',
      'phone': '0511111111',
      'bookings_count': 2,
      'total_spent': '3000',
    },
  ],
};

const agentCommissionJson = {
  'success': true,
  'commission_type': 'percentage',
  'commission_rate': '10',
  'total_bookings': 4,
  'total_commission': '600',
  'paid': '400',
  'unpaid': '200',
  'items': [
    {
      'booking_ref': 'BK-1001',
      'guest_name': 'محمد علي',
      'hotel_name': 'فندق فيرمونت مكه',
      'booking_total': '1500',
      'amount': '150',
      'status': 'paid',
      'booking_status': 'confirmed',
    },
  ],
};

const notificationsJson = {
  'success': true,
  'notifications': [
    {
      'id': 1,
      'type': 'maintenance',
      'title_ar': 'طلب صيانة جديد',
      'title_en': 'New maintenance request',
      'body_ar': 'تم إنشاء طلب صيانة للوحدة 402',
      'body_en': 'A maintenance request was created for unit 402',
      'created_at': '2026-10-19 10:00:00',
      'is_read': false,
    },
    {
      'id': 2,
      'type': 'booking',
      'title_ar': 'حجز جديد',
      'title_en': 'New booking',
      'body_ar': 'حجز جديد على جناح عائلي من 1 إلى 3 نوفمبر',
      'body_en': 'A new booking on Family suite, 1–3 November',
      'created_at': '2026-10-18 09:00:00',
      'is_read': true,
    },
  ],
};

const myBookingsJson = {
  'success': true,
  'bookings': [
    {
      'id': 61,
      'booking_ref': 'BK-2088',
      'hotel_name': 'فندق فيرمونت مكه',
      'unit_name': 'جناح عائلي',
      'unit_number': '402',
      'check_in': '2026-11-01',
      'check_out': '2026-11-03',
      'guests': 2,
      'total': '1500',
      'status': 'confirmed',
      'can_cancel': true,
      'can_edit': true,
      'meal_types': ['breakfast'],
      'extra_bed_count': 1,
      'extra_bed_price': 150,
    },
  ],
};

const paymentSettingsJson = {
  'success': true,
  'methods': {
    'at_hotel': {'enabled': false},
    'owner_transfer': {'enabled': false},
    'online': {'enabled': false},
  },
};

/// محوّل Dio يخدم الحمولات أعلاه حسب المسار.
class ShotAdapter implements HttpClientAdapter {
  ShotAdapter({this.failPath, this.emptyAddons = false});

  /// عند تحديده، يُعاد المسار بخطأ 500 (لتصوير حالة الخطأ).
  final String? failPath;

  /// يجعل `units/addons.php` بلا إضافات — لتصوير مسار الحجز التقليدي
  /// (اختيار الوجبات + بطاقة السرير الإضافي بعدّاد الكمية).
  final bool emptyAddons;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    if (failPath != null && path.contains(failPath!)) {
      return ResponseBody.fromString('{"success":false,"message":"boom"}', 500,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType]
          });
    }

    Object body;
    if (path.contains('auth/me')) {
      body = {'success': true, 'user': currentUserJson ?? {}}
          as Map<String, dynamic>;
    } else if (path.contains('payment-settings')) {
      body = paymentSettingsJson;
    } else if (path.contains('cities/list')) {
      body = citiesJson;
    } else if (path.contains('categories/list')) {
      body = categoriesJson;
    } else if (path.contains('hotels/detail')) {
      body = hotelDetailJson;
    } else if (path.contains('hotels/list')) {
      body = hotelsJson;
    } else if (path.contains('units/detail')) {
      body = unitDetailJson;
    } else if (path.contains('units/addons')) {
      body = {
        'success': true,
        'addons': emptyAddons ? const <Object>[] : unitDetailJson['addons'],
      };
    } else if (path.contains('units/browse') || path.contains('units/list')) {
      body = unitsJson;
    } else if (path.contains('hotel/dashboard')) {
      body = hotelDashboardJson;
    } else if (path.contains('hotel/bookings')) {
      body = hotelBookingsJson;
    } else if (path.contains('hotel/requests')) {
      final type = options.uri.queryParameters['type'];
      body = switch (type) {
        'meal' => hotelMealRequestsJson,
        'extra_bed' => hotelExtraBedRequestsJson,
        _ => hotelRequestsJson,
      };
    } else if (path.contains('hotel/unit-pricing')) {
      body = unitPricingJson;
    } else if (path.contains('hotel/meal-pricing')) {
      body = mealPricingJson;
    } else if (path.contains('hotel/prices')) {
      body = hotelPricesJson;
    } else if (path.contains('owner-dashboard')) {
      body = ownerDashboardJson;
    } else if (path.contains('owner-bookings')) {
      body = ownerBookingsJson;
    } else if (path.contains('owner-requests')) {
      body = ownerCleaningJson;
    } else if (path.contains('owner-meals')) {
      body = ownerMealsJson;
    } else if (path.contains('owner-maintenance')) {
      body = ownerMaintenanceJson;
    } else if (path.contains('owner-revenue')) {
      body = ownerRevenueJson;
    } else if (path.contains('owner-wallet')) {
      body = ownerWalletJson;
    } else if (path.contains('owner-staff')) {
      body = ownerStaffJson;
    } else if (path.contains('owner-units')) {
      body = ownerUnitsJson;
    } else if (path.contains('agent-clients')) {
      body = agentClientsJson;
    } else if (path.contains('agent-commission')) {
      body = agentCommissionJson;
    } else if (path.contains('notifications')) {
      body = notificationsJson;
    } else if (path.contains('bookings/my')) {
      body = myBookingsJson;
    } else if (path.contains('content/settings')) {
      body = {'success': true};
    } else {
      body = {'success': true};
    }

    return ResponseBody.fromString(jsonEncode(body), 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }
}

/// المستخدم الحالي لحمولة `auth/me.php` (يُضبط قبل كل لقطة بدورها).
Map<String, dynamic>? currentUserJson;

/// يضبط جلسة مخزّنة حقيقية حتى تستعيدها `SessionNotifier` بالدور المطلوب.
void setSession({
  String role = 'customer',
  String name = 'محمد علي',
  String locale = 'ar',
}) {
  currentUserJson = {
    'id': 9,
    'full_name': name,
    'email': 'user@example.com',
    'phone': '0500000000',
    'role': role,
  };
  SharedPreferences.setMockInitialValues({
    'auth_token': 'test-token',
    'user_json': jsonEncode(currentUserJson),
    'app_locale': locale,
  });
}

Widget wrapShot(Widget child, {required bool isArabic}) {
  // الثيم الحقيقي للتطبيق يستخدم `GoogleFonts`، وهي لا تعمل بلا شبكة داخل
  // الاختبار (تعود بلا عائلة خط ⇒ خط Ahem ⇒ مربّعات). نُبقي الثيم كما هو
  // ونستبدل عائلة الخط فقط بالخطوط الحقيقية المحمّلة من `screenshot_assets`.
  final family = isArabic ? 'IBM Plex Sans Arabic' : 'Inter';
  final theme = AppTheme.light(isArabic: isArabic, fontFamilyOverride: family);
  return ProviderScope(
    child: RepaintBoundary(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: Locale(isArabic ? 'ar' : 'en'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: theme,
        home: child,
      ),
    ),
  );
}

/// يضبط المخوّل ويسجّل الجلسة (يُنادى في بداية كل اختبار لقطة).
void installShotAdapter({String? failPath, bool emptyAddons = false}) {
  ApiClient.instance.dio.httpClientAdapter =
      ShotAdapter(failPath: failPath, emptyAddons: emptyAddons);
}

void restoreShotAdapter(HttpClientAdapter original) {
  ApiClient.instance.dio.httpClientAdapter = original;
}

/// مقارن لقطات متسامح مع فروق التنعيم بين إصدارات محرّك الرسم فقط.
///
/// المشكلة الحقيقية: PNG المرجعية تُولَّد على إصدار Flutter محدد، وأي تغيير في
/// إصدار المحرّك (حتى ضمن stable) يغيّر تنعيم الحروف بكسليًا، فيفشل
/// `flutter test` في Codemagic بلا أي تغيير في التطبيق. القياس الفعلي بين
/// 3.44.9 و3.32.0: 2.35% من البكسلات مختلفة بمقدار صغير جدًا.
///
/// لذلك نرفض فقط ما يتجاوز **حدّين معًا**: نسبة بكسلات مختلفة > 3% أو متوسط
/// فرق قناة > 12 من 255. تحريك زر أو تغيير نص/لون يتجاوز الحدّين بكثير، أما
/// انزياح التنعيم فلا يقترب منهما.
class ScreenshotComparator extends LocalFileComparator {
  ScreenshotComparator()
      : super(
            Uri.file('${Directory.current.path}/test/screenshot_support.dart'));

  /// القرار الافتراضي: **مساواة بكسلية تامة**. أي فرق — حرف واحد أو أيقونة أو
  /// لون أو إزاحة — يُفشل الاختبار. هذا ممكن لأن سلسلة الأدوات مثبّتة على
  /// Flutter 3.44.9 (انظر `docs/SCREENSHOT_TOOLCHAIN.md`).
  ///
  /// `SCREENSHOT_TOLERANT=1` يُفعّل وضع التشخيص عبر إصدار Flutter آخر، ويقبل
  /// فروقًا في حدود `RasterDriftLimits` فقط (فحص موضعي بمربّعات + مساحة حبر،
  /// لا عتبة كلية واحدة). لا يُستخدم في أي بوابة قبول.
  static bool get tolerant =>
      Platform.environment['SCREENSHOT_TOLERANT'] == '1';

  /// الحكم على صورتين: مطابقة، أو انحراف رسم مقبول (وضع التشخيص فقط)، أو رفض.
  static Future<DiffVerdict> verdict(
    Uint8List actualPng,
    Uint8List goldenPng, {
    bool tolerant = false,
  }) async {
    if (_sameBytes(actualPng, goldenPng)) return DiffVerdict.identical;
    final a = await decodePng(actualPng);
    final b = await decodePng(goldenPng);
    if (a == null || b == null) return DiffVerdict.rejected;
    if (a.$1 != b.$1 || a.$2 != b.$2) return DiffVerdict.rejected;
    final diff = analyzeRgba(a.$3, b.$3, a.$1, a.$2);
    if (diff == null) return DiffVerdict.rejected;
    if (diff.isIdentical) return DiffVerdict.identical;
    if (tolerant && isRasterDriftOnly(diff)) return DiffVerdict.driftAccepted;
    return DiffVerdict.rejected;
  }

  static bool _sameBytes(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final goldenBytes = Uint8List.fromList(await getGoldenBytes(golden));
    final result =
        await GoldenFileComparator.compareLists(imageBytes, goldenBytes);
    if (result.passed) return true;

    final diff = await _report(imageBytes, goldenBytes);
    if (tolerant && isRasterDriftOnly(diff)) {
      // وضع التشخيص فقط: نُمرّر مع تسجيل صريح بالفرق المقبول.
      // ignore: avoid_print
      print('screenshot drift accepted (diagnostic mode): ${golden.path} '
          '${diff.toString()}');
      return true;
    }

    final error = await generateFailureOutput(result, golden, basedir);
    throw FlutterError(
      '$error\n'
      '${diff == null ? 'أبعاد مختلفة أو صورة غير قابلة للفك.' : 'تحليل الفرق: $diff'}\n'
      'المرجع معتمد على Flutter 3.44.9. إن كان الإصدار مختلفًا استخدم '
      'SCREENSHOT_TOLERANT=1 للتشخيص فقط، أو أعد توليد اللقطات بعد موافقة '
      'المالك على التغيير البصري.',
    );
  }

  Future<RgbaDiff?> _report(Uint8List a, Uint8List b) async {
    final first = await decodePng(a);
    final second = await decodePng(b);
    if (first == null || second == null) return null;
    if (first.$1 != second.$1 || first.$2 != second.$2) return null;
    return analyzeRgba(first.$3, second.$3, first.$1, first.$2);
  }
}

/// نتيجة مقارنة لقطة بلقطة مرجعية.
enum DiffVerdict {
  /// لا فرق بكسل واحد.
  identical,

  /// فرق في حدود انحراف محرّك الرسم — مقبول في وضع التشخيص فقط.
  driftAccepted,

  /// فرق حقيقي: نص أو أيقونة أو زر أو لون أو موضع أو تخطيط.
  rejected,
}

/// يُثبّت المقارن المتسامح مرة واحدة لكل ملف اختبار لقطات.
void useScreenshotComparator() {
  if (goldenFileComparator is ScreenshotComparator) return;
  goldenFileComparator = ScreenshotComparator();
}

/// يبني الشاشة بالحجم واللغة المطلوبين ثم يلتقط PNG حقيقية باسم [fileName].
///
/// [dir] مجلد فرعي داخل `docs/evidence/final-acceptance/` (مثل `document-06`
/// أو `hotel-staff/arabic`). الملف يُكتب فقط عند التشغيل بـ
/// `flutter test --update-goldens`.
Future<void> capture(
  WidgetTester tester,
  Widget screen,
  String relativePath, {
  bool isArabic = true,
  double width = 390,
  double height = 844,
  Future<void> Function(WidgetTester tester)? interact,
}) async {
  useScreenshotComparator();
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(wrapShot(screen, isArabic: isArabic));
  await tester.pumpAndSettle();
  if (interact != null) {
    await interact(tester);
    await tester.pumpAndSettle();
  }

  await expectLater(
    find.byType(RepaintBoundary).first,
    matchesGoldenFile('$kShotDir/$relativePath'),
  );
}
