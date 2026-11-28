import 'dart:convert';
import 'dart:typed_data';

import 'package:allowners/screens/hotel_staff/hotel_prices_screen.dart';
import 'package:allowners/screens/owner/owner_clients_screen.dart';
import 'package:allowners/screens/owner/owner_decisions_screen.dart';
import 'package:allowners/screens/owner/owner_messages_screen.dart';
import 'package:allowners/screens/owner/owner_units_screen.dart';
import 'package:allowners/services/api_client.dart';
import 'package:allowners/theme/app_theme.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// انحدار: حقول PDO الرقمية تصل كنصوص (`"8"` لا `8`) فتُسقط التحويلات المباشرة
/// (`as num` / `as int` / `as String`) الشاشة كاملة. هذه الاختبارات تُشغّل كل
/// شاشة بحمولة **نصية الأرقام بالكامل** — وهي الحالة التي كانت تنهار.
///
/// تُثبِّت الإصلاحات في: owner_decisions_screen (total_votes/votes + مقارنة
/// my_vote)، owner_messages_screen (unread_count)، owner_units_screen
/// (cover_image)، hotel_prices_screen (hotel_id/unit_id/id)، owner_clients_screen
/// (client كخريطة).
const _stringyDecisions = {
  'success': true,
  'decisions': [
    {
      'id': '8',
      'title': 'تحديث لائحة الرسوم',
      'description': 'تصويت على نسبة العمولة',
      'status': 'open',
      'total_votes': '12',
      'my_vote': '3',
      'options': [
        {'id': '3', 'label': 'موافق', 'votes': '8'},
        {'id': '4', 'label': 'غير موافق', 'votes': '4'},
      ],
    },
  ],
  'hotels': [
    {'id': '2', 'name': 'فندق فيرمونت مكه'},
  ],
};

const _stringyConversations = {
  'success': true,
  'conversations': [
    {
      'id': '5',
      'other_name': 'إدارة الفندق',
      'full_name': 'إدارة الفندق',
      'last_body': 'تم تأكيد الحجز',
      'unread_count': '3',
    },
  ],
};

const _stringyUnits = {
  'success': true,
  'units': [
    {
      'id': '11',
      'name_ar': 'جناح عائلي',
      'name_en': 'Family Suite',
      'price_per_night': '450',
      'cover_image': 'https://example.test/unit.jpg',
      'hotel_name': 'فندق فيرمونت مكه',
      'status': 'active',
    },
  ],
  'hotels': [
    {'id': '2', 'name': 'فندق فيرمونت مكه'},
  ],
};

const _stringyPrices = {
  'success': true,
  'prices': [
    {
      'id': '5',
      'hotel_id': '2',
      'unit_id': '11',
      'service_type': 'cleaning',
      'title_ar': 'تنظيف',
      'title_en': 'Cleaning',
      'price': '120',
    },
  ],
  'units': [
    {'id': '11', 'hotel_id': '2', 'name_ar': 'جناح عائلي', 'name_en': 'Suite'},
  ],
  'hotels': [
    {'id': '2', 'name': 'فندق فيرمونت مكه'},
  ],
};

const _stringyClientDetail = {
  'success': true,
  'client': {'id': '7', 'full_name': 'أحمد', 'phone': '0500000000'},
  'bookings': [
    {'id': '31', 'total': '900', 'check_in': '2026-11-01'},
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
    if (path.contains('decisions/list')) {
      body = _stringyDecisions;
    } else if (path.contains('messages/conversations')) {
      body = _stringyConversations;
    } else if (path.contains('owner-units')) {
      body = _stringyUnits;
    } else if (path.contains('hotel/prices')) {
      body = _stringyPrices;
    } else if (path.contains('agent-clients')) {
      body = _stringyClientDetail;
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
  late HttpClientAdapter original;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    original = ApiClient.instance.dio.httpClientAdapter;
    ApiClient.instance.dio.httpClientAdapter = _Adapter();
  });

  tearDown(() {
    ApiClient.instance.dio.httpClientAdapter = original;
  });

  Future<void> pump(WidgetTester tester, Widget screen,
      {double width = 390, bool isArabic = true}) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_wrap(screen, isArabic: isArabic));
    await tester.pumpAndSettle();
  }

  group('أرقام PDO النصية لا تُسقط الشاشات', () {
    testWidgets('القرارات: total_votes/votes نصوص وتُعرض بلا استثناء',
        (tester) async {
      await pump(tester, const OwnerDecisionsScreen());
      expect(tester.takeException(), isNull);
      expect(find.textContaining('تحديث لائحة الرسوم'), findsWidgets);
      // 8 أصوات من 12 = 67%
      expect(find.textContaining('67%'), findsWidgets);
    });

    testWidgets('الرسائل: unread_count نص', (tester) async {
      await pump(tester, const OwnerMessagesScreen());
      expect(tester.takeException(), isNull);
      expect(find.textContaining('تم تأكيد الحجز'), findsWidgets);
    });

    testWidgets('وحدات المالك: price_per_night وcover_image', (tester) async {
      await pump(tester, const OwnerUnitsScreen());
      expect(tester.takeException(), isNull);
      expect(find.textContaining('جناح عائلي'), findsWidgets);
    });

    testWidgets('أسعار الفندق: hotel_id/unit_id/id نصوص', (tester) async {
      await pump(tester, const HotelPricesScreen());
      expect(tester.takeException(), isNull);
      expect(find.textContaining('تنظيف'), findsWidgets);
    });

    testWidgets('تفاصيل العميل: client خريطة وأرقام نصية', (tester) async {
      await pump(tester, const OwnerClientsScreen());
      expect(tester.takeException(), isNull);
    });

    for (final w in const [360.0, 768.0]) {
      testWidgets('القرارات بلا تجاوز على ${w.toInt()}px', (tester) async {
        await pump(tester, const OwnerDecisionsScreen(), width: w);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
