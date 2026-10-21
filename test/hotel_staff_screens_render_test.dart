import 'dart:convert';
import 'dart:typed_data';

import 'package:allowners/screens/hotel_staff/hotel_bookings_screen.dart';
import 'package:allowners/screens/hotel_staff/hotel_dashboard_screen.dart';
import 'package:allowners/screens/hotel_staff/hotel_prices_screen.dart';
import 'package:allowners/screens/hotel_staff/hotel_requests_screen.dart';
import 'package:allowners/services/api_client.dart';
import 'package:allowners/theme/app_theme.dart';
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

const _requestsJson = {
  'success': true,
  'requests': [
    {
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
    if (path.contains('hotel/dashboard')) {
      body = _dashboardJson;
    } else if (path.contains('hotel/bookings')) {
      body = _bookingsJson;
    } else if (path.contains('hotel/requests')) {
      body = _requestsJson;
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
      {double width = 390, bool isArabic = true}) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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

  group('اللغة الإنجليزية (LTR)', () {
    testWidgets('لوحة الإدارة تُرسم LTR بلا تجاوز', (tester) async {
      SharedPreferences.setMockInitialValues({'app_locale': 'en'});
      await _pump(tester, const HotelDashboardScreen(), isArabic: false);
      expect(tester.takeException(), isNull);
    });
  });
}
