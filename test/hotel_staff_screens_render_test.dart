import 'dart:convert';
import 'dart:typed_data';

import 'package:allowners/screens/hotel_staff/hotel_bookings_screen.dart';
import 'package:allowners/screens/hotel_staff/hotel_arrivals_screen.dart';
import 'package:allowners/screens/hotel_staff/hotel_dashboard_screen.dart';
import 'package:allowners/screens/hotel_staff/hotel_meal_pricing_screen.dart';
import 'package:allowners/screens/hotel_staff/hotel_prices_screen.dart';
import 'package:allowners/screens/hotel_staff/hotel_requests_screen.dart';
import 'package:allowners/screens/hotel_staff/hotel_unit_pricing_screen.dart';
import 'package:allowners/services/api_client.dart';
import 'package:allowners/theme/app_theme.dart';
import 'package:allowners/utils/app_strings.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// اختبارات عرض شاشات إدارة الفندق (المتطلبات 29–33، 57، 58، 62).
///
/// تُبنى الشاشات عبر `HotelStaffService` الحقيقي بمحوّل Dio يخدم حمولات بشكل
/// استجابات الإنتاج، لإثبات أنها تُرسم بالبيانات الفعلية بلا استثناء ولا تجاوز
/// على العروض 360/390/768.
const _dashboardJson = {
  'success': true,
  'hotels': [
    {'id': 2, 'name': 'فندق فيرمونت مكه'},
  ],
  'pending': {'cleaning': 3, 'maintenance': 1, 'meal': 2, 'extra_bed': 0},
  'arrivals_today': 5,
  'departures_today': 4,
  'in_house': 12,
};

const _bookingsJson = {
  'success': true,
  'bookings': [
    {
      'id': 31,
      'guest_name': 'محمد علي',
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
  ],
};

const _cleaningRequest = {
  'id': 7,
  'type': 'cleaning',
  'description': 'تنظيف الغرفة 402',
  'status': 'open',
  'hotel_name': 'فندق فيرمونت مكه',
  'unit_name_ar': 'جناح عائلي',
  'unit_name_en': 'Family Suite',
  'requester_name': 'مالك الوحدة',
  'requester_phone': '0500000000',
  'owner_phone': '0500000000',
  'guest_phone': '0511111111',
  'price': '120',
};

const _mealRequest = {
  'id': 8,
  'type': 'meal',
  'description': 'فطور لغرفة 402',
  'status': 'pending',
  'hotel_name': 'فندق فيرمونت مكه',
  'unit_name_ar': 'جناح عائلي',
  'unit_name_en': 'Family Suite',
  'requester_name': 'مالك الوحدة',
  'guest_phone': '0511111111',
  'price': '150',
  'meal_types': ['breakfast', 'dinner'],
  'settlement': '',
};

const _extraBedRequest = {
  'id': 9,
  'type': 'extra_bed',
  'description': 'سرير إضافي',
  'status': 'pending',
  'hotel_name': 'فندق فيرمونت مكه',
  'unit_name_ar': 'جناح عائلي',
  'unit_name_en': 'Family Suite',
  'guest_phone': '0511111111',
  'price': '100',
  'beds': 2,
  'nights': 3,
};

const _requestsJson = {
  'success': true,
  'requests': [_cleaningRequest],
};

const _mealRequestsJson = {
  'success': true,
  'requests': [_mealRequest],
};

const _extraBedRequestsJson = {
  'success': true,
  'requests': [_extraBedRequest],
};

const _unitPricingJson = {
  'success': true,
  'units': [
    {
      'id': 1,
      'unit_type_ar': 'جناح',
      'unit_type_en': 'Suite',
    },
    {
      'id': 2,
      'unit_type_ar': 'غرفة',
      'unit_type_en': 'Room',
    },
  ],
  'records': [
    {
      'id': 4,
      'title': 'أسعار مارس',
      'pricing_date': '2026-03-09',
      'rows': [
        {'unit_type_ar': 'جناح', 'price': 400},
        {'unit_type_ar': 'غرفة', 'price': 250},
      ],
    },
  ],
};

const _mealPricingJson = {
  'success': true,
  'records': [
    {
      'id': 3,
      'title': 'وجبات مارس',
      'pricing_date': '2026-03-09',
      'meals': [
        {'name': 'فطور', 'price': 35},
        {'name': 'غداء', 'price': 60},
        {'name': 'عشاء', 'price': 50},
      ],
    },
  ],
};

const _pricesJson = {
  'success': true,
  'prices': [
    {
      'id': 5,
      'service_type': 'cleaning',
      'title_ar': 'تنظيف',
      'title_en': 'Cleaning',
      'unit_name_ar': 'جناح عائلي',
      'unit_name_en': 'Family Suite',
      'price': '120',
    },
  ],
};

/// مستخدم `/auth/me.php` الذي تستهلكه استعادة الجلسة في الاختبارات.
Map<String, dynamic> _meUser = const {
  'id': 9,
  'full_name': 'مستخدم تجريبي',
  'email': 'user@example.com',
  'role': 'guest',
};

class _Adapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    Object body;
    if (path.contains('auth/me')) {
      body = {'success': true, 'user': _meUser};
    } else if (path.contains('hotel/dashboard')) {
      body = _dashboardJson;
    } else if (path.contains('hotel/bookings')) {
      body = _bookingsJson;
    } else if (path.contains('hotel/requests')) {
      final type = options.uri.queryParameters['type'];
      body = switch (type) {
        'meal' => _mealRequestsJson,
        'extra_bed' => _extraBedRequestsJson,
        _ => _requestsJson,
      };
    } else if (path.contains('hotel/unit-pricing')) {
      body = _unitPricingJson;
    } else if (path.contains('hotel/meal-pricing')) {
      body = _mealPricingJson;
    } else if (path.contains('hotel/prices')) {
      body = _pricesJson;
    } else {
      body = {'success': true};
    }
    return ResponseBody.fromString(jsonEncode(body), 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }
}

Widget _wrap(Widget child, {bool isArabic = true}) => ProviderScope(
      child: MaterialApp(
        locale: Locale(isArabic ? 'ar' : 'en'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.light(isArabic: isArabic),
        home: child,
      ),
    );

void main() {
  late HttpClientAdapter _originalAdapter;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _originalAdapter = ApiClient.instance.dio.httpClientAdapter;
    ApiClient.instance.dio.httpClientAdapter = _Adapter();
  });

  tearDown(() {
    ApiClient.instance.dio.httpClientAdapter = _originalAdapter;
  });

  Future<void> _pump(WidgetTester tester, Widget screen,
      {double width = 390, bool isArabic = true, String? role}) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    if (role != null) {
      // جلسة مخزّنة حقيقية حتى تستعيدها `SessionNotifier` بالدور المطلوب.
      _meUser = {
        'id': 9,
        'full_name': 'مستخدم تجريبي',
        'email': 'user@example.com',
        'role': role,
      };
      SharedPreferences.setMockInitialValues({
        'auth_token': 'test-token',
        'user_json': jsonEncode(_meUser),
      });
    }
    await tester.pumpWidget(_wrap(screen, isArabic: isArabic));
    await tester.pumpAndSettle();
  }

  group('لوحة إدارة الفندق (المتطلبات 29–33، 80)', () {
    testWidgets('تعرض أرقام الوصول والمغادرة والنزلاء (المتطلب 80)',
        (tester) async {
      await _pump(tester, const HotelDashboardScreen());
      expect(tester.takeException(), isNull);
      expect(find.textContaining('فندق فيرمونت مكه'), findsWidgets);
      // المتطلب 80: أقسام اللوحة مفتوحة وتُعرض أرقامها الحقيقية.
      expect(find.textContaining('5'), findsWidgets); // arrivals_today
      expect(find.textContaining('4'), findsWidgets); // departures_today
      expect(find.textContaining('12'), findsWidgets); // in_house
    });

    for (final w in const [360.0, 768.0]) {
      testWidgets('بلا تجاوز على ${w.toInt()}px', (tester) async {
        await _pump(tester, const HotelDashboardScreen(), width: w);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('بطاقات اللوحة قابلة للنقر (المتطلبان 80 و81، المستند 06 §F)', () {
    testWidgets('بطاقة الوصولات تفتح شاشة الوصولات', (tester) async {
      await _pump(tester, const HotelDashboardScreen());
      await tester.tap(find.text(AppStrings.t(true, 'arrivals_today')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
          find.text(AppStrings.t(true, 'arrivals_today_title')), findsWidgets);
      // بيانات الضيف ورقم الوحدة ظاهرة داخل شاشة الوصولات.
      expect(find.textContaining('محمد علي'), findsWidgets);
      expect(find.textContaining('402'), findsWidgets);
    });

    testWidgets('بطاقة الطلبات المفتوحة تفتح شاشة الطلبات', (tester) async {
      await _pump(tester, const HotelDashboardScreen());
      await tester.tap(find.text(AppStrings.t(true, 'open_requests')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('بطاقة المغادرات تفتح شاشة المغادرات', (tester) async {
      await _pump(tester, const HotelDashboardScreen());
      await tester.tap(find.text(AppStrings.t(true, 'departures_today')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.t(true, 'departures_today_title')),
          findsWidgets);
    });

    testWidgets('البحث برقم الوحدة في الوصولات يرشّح ويُفرّغ', (tester) async {
      await _pump(tester, const HotelArrivalsScreen());
      expect(tester.takeException(), isNull);
      expect(find.textContaining('محمد علي'), findsWidgets);

      await tester.enterText(find.byType(TextField).first, '402');
      await tester.pumpAndSettle();
      expect(find.textContaining('محمد علي'), findsWidgets);

      await tester.enterText(find.byType(TextField).first, '9999');
      await tester.pumpAndSettle();
      expect(find.textContaining('محمد علي'), findsNothing);
      expect(find.text(AppStrings.t(true, 'no_arrivals')), findsWidgets);

      await tester.tap(find.byTooltip(AppStrings.t(true, 'clear_search')));
      await tester.pumpAndSettle();
      expect(find.textContaining('محمد علي'), findsWidgets);
    });
  });

  group('حجوزات الفندق (المتطلبات 57، 58)', () {
    testWidgets('تعرض الضيف والوحدة وحالة الوصول', (tester) async {
      await _pump(tester, const HotelBookingsScreen());
      expect(tester.takeException(), isNull);
      expect(find.textContaining('محمد علي'), findsWidgets);
    });
  });

  group('طلبات الفندق (المتطلب 62)', () {
    testWidgets('تبويبات الطلبات تُرسم ببياناتها', (tester) async {
      await _pump(tester, const HotelRequestsScreen());
      expect(tester.takeException(), isNull);
      expect(find.textContaining('تنظيف الغرفة 402'), findsWidgets);
    });
  });

  group('أسعار خدمات الفندق', () {
    testWidgets('تعرض الخدمة والسعر', (tester) async {
      await _pump(tester, const HotelPricesScreen());
      expect(tester.takeException(), isNull);
      expect(find.textContaining('تنظيف'), findsWidgets);
    });
  });

  group('تسعير الوحدات (المتطلبات 13–15 من المستند 06)', () {
    testWidgets('ستة صفوف أنواع وحدات وأسعار من بيانات الفندق', (tester) async {
      await _pump(tester, const HotelUnitPricingScreen());
      expect(tester.takeException(), isNull);
      // العنوان والتاريخ مطلوبان في النموذج.
      expect(find.text('العنوان'), findsOneWidget);
      expect(find.text('التاريخ'), findsWidgets);
      expect(find.text('ستة صفوف لأنواع الوحدات وأسعارها'), findsOneWidget);
      // أنواع الوحدات الحقيقية ظاهرة، والسجل المحفوظ يُسترجع.
      expect(find.text('جناح'), findsWidgets);
      expect(find.text('غرفة'), findsWidgets);
      expect(find.text('أسعار مارس'), findsWidgets);
      // ستة صفوف إدخال للنوع والسعر.
      final priceFields = find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == 'السعر');
      expect(tester.widgetList(priceFields).length, 6);
    });

    for (final w in const [360.0, 768.0]) {
      testWidgets('بلا تجاوز على ${w.toInt()}px', (tester) async {
        await _pump(tester, const HotelUnitPricingScreen(), width: w);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('الإنجليزية LTR', (tester) async {
      SharedPreferences.setMockInitialValues({'app_locale': 'en'});
      await _pump(tester, const HotelUnitPricingScreen(), isArabic: false);
      expect(tester.takeException(), isNull);
      expect(find.text('Unit pricing'), findsOneWidget);
      expect(find.text('Six unit-type and price rows'), findsOneWidget);
    });
  });

  group('تسعير الوجبات (المتطلب 16 من المستند 06)', () {
    testWidgets('ثلاث وجبات وأسعارها مع العنوان والتاريخ', (tester) async {
      await _pump(tester, const HotelMealPricingScreen());
      expect(tester.takeException(), isNull);
      expect(find.text('تسعير الوجبات'), findsWidgets);
      expect(find.text('ثلاث وجبات وأسعارها'), findsOneWidget);
      expect(find.text('وجبات مارس'), findsWidgets);
      final nameFields = find.byWidgetPredicate((w) =>
          w is TextField &&
          (w.decoration?.labelText ?? '').startsWith('اسم الوجبة'));
      expect(tester.widgetList(nameFields).length, 3);
    });

    testWidgets('بلا تجاوز على 360px', (tester) async {
      await _pump(tester, const HotelMealPricingScreen(), width: 360);
      expect(tester.takeException(), isNull);
    });
  });

  group('طلبات الوجبات والسرير الإضافي (المتطلبان 11 و12 من المستند 06)', () {
    testWidgets('بطاقة الوجبات تعرض السعر المعتمد وأنواع الوجبات',
        (tester) async {
      await _pump(tester, const HotelRequestsScreen());
      await tester.tap(find.text('الوجبات').first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('سعر الوجبات المعتمد'), findsWidgets);
      expect(find.textContaining('فطور'), findsWidgets);
    });

    testWidgets('بطاقة السرير الإضافي تعرض الأسرّة والليالي والإجمالي',
        (tester) async {
      await _pump(tester, const HotelRequestsScreen(), width: 768);
      await tester.tap(find.text('السرير الإضافي').first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('عدد الأسرّة'), findsWidgets);
      expect(find.textContaining('عدد الليالي'), findsWidgets);
      expect(find.textContaining('الإجمالي'), findsWidgets);
    });

    testWidgets('نافذة تأكيد الوجبات تعرض وسيلتي السداد', (tester) async {
      await _pump(tester, const HotelRequestsScreen(), role: 'hotel_manager');
      await tester.tap(find.text('الوجبات').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('تأكيد الطلب').first);
      await tester.pumpAndSettle();
      expect(find.text('خصم من الرصيد'), findsWidgets);
      expect(find.text('الدفع عبر رابط بالواتساب'), findsWidgets);
      expect(find.text('طريقة سداد قيمة الطلب'), findsOneWidget);
    });

    testWidgets('التأكيد بلا اختيار وسيلة يوقف الإرسال', (tester) async {
      await _pump(tester, const HotelRequestsScreen(), role: 'hotel_manager');
      await tester.tap(find.text('الوجبات').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('تأكيد الطلب').first);
      await tester.pumpAndSettle();
      // زر التأكيد داخل النافذة (آخر «تأكيد» في الشجرة).
      await tester.tap(find.text('تأكيد').last);
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.t(true, 'payment_method_required')),
          findsOneWidget);
    });

    testWidgets('دور غير مصرّح لا يستطيع تأكيد الوجبات', (tester) async {
      await _pump(tester, const HotelRequestsScreen(), role: 'customer');
      await tester.tap(find.text('الوجبات').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('تأكيد الطلب').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('خصم من الرصيد').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('تأكيد').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('لا تملك صلاحية'), findsOneWidget);
    });
  });

  group('اللغة الإنجليزية (LTR)', () {
    testWidgets('لوحة الإدارة تُرسم LTR بلا تجاوز', (tester) async {
      SharedPreferences.setMockInitialValues({'app_locale': 'en'});
      await _pump(tester, const HotelDashboardScreen(), isArabic: false);
      expect(tester.takeException(), isNull);
    });
  });
}
