import 'dart:convert';
import 'dart:typed_data';

import 'package:allowners/screens/home/home_screen.dart';
import 'package:allowners/screens/owner/owner_notifications_screen.dart';
import 'package:allowners/screens/services/service_request_screen.dart';
import 'package:allowners/services/api_client.dart';
import 'package:allowners/theme/app_theme.dart';
import 'package:allowners/widgets/app_logo.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// تغطية المتطلبات التي كانت بلا اختبار: 7، 17 (الرئيسية)، 59 (شاشة طلب خدمة
/// الضيف)، 71 (نص الإشعار الحقيقي بالعربية والإنجليزية).
class _Adapter implements HttpClientAdapter {
  _Adapter({this.empty = false});

  /// يعيد قوائم فارغة — مسار «لا نتائج» الذي يعرض `EmptyView`.
  final bool empty;

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
    if (path.contains('/user/notifications.php')) {
      body = {
        'success': true,
        'notifications': [
          {
            'id': 1,
            'title': 'تأكيد حجز',
            'body_ar': 'تم تأكيد حجزك في فيرمونت مكة',
            'body_en': 'Your booking at Fairmont Makkah is confirmed',
            'created_at': '2026-10-18 10:00:00',
            'is_read': 0,
          },
        ],
      };
    } else if (path.contains('/categories/list.php')) {
      body = {
        'success': true,
        'categories': empty
            ? []
            : [
                {
                  'id': 1,
                  'name_ar': 'فنادق',
                  'name_en': 'Hotels',
                  'icon_key': 'hotel',
                },
                {'id': 2, 'name_ar': 'شقق مفروشة', 'name_en': 'Apartments'},
              ],
      };
    } else if (path.contains('/cities/list.php')) {
      body = {
        'success': true,
        'cities': empty
            ? []
            : [
                {'id': 1, 'name_ar': 'مكة المكرمة', 'name_en': 'Makkah'},
                {'id': 2, 'name_ar': 'جدة', 'name_en': 'Jeddah'},
              ],
      };
    } else if (path.contains('/units/browse.php')) {
      body = {
        'success': true,
        'units': empty
            ? []
            : [
                {
                  'id': 11,
                  'name_ar': 'جناح عائلي',
                  'name_en': 'Family Suite',
                  'price_per_night': '450',
                  'hotel_name': 'فندق فيرمونت مكه',
                  'city_name': 'مكة المكرمة',
                },
              ],
      };
    } else if (path.contains('/hotels/list.php')) {
      body = {
        'success': true,
        'hotels': empty
            ? []
            : [
                {
                  'id': 2,
                  'name_ar': 'فندق فيرمونت مكه',
                  'name_en': 'Fairmont Makkah',
                  'city_ar': 'مكة المكرمة',
                  'city_en': 'Makkah',
                },
              ],
      };
    } else if (path.contains('settings')) {
      body = {'success': true, 'settings': {}};
    } else {
      body = {'success': true};
    }
    return ResponseBody.fromString(jsonEncode(body), 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }
}

Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.light(isArabic: true),
        home: child,
      ),
    );

void main() {
  late HttpClientAdapter original;

  setUp(() {
    original = ApiClient.instance.dio.httpClientAdapter;
    ApiClient.instance.dio.httpClientAdapter = _Adapter();
  });

  tearDown(() {
    ApiClient.instance.dio.httpClientAdapter = original;
  });

  Future<void> pump(WidgetTester tester, Widget screen,
      {double width = 390, String locale = 'ar'}) async {
    SharedPreferences.setMockInitialValues({'app_locale': locale});
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_wrap(screen));
    await tester.pumpAndSettle();
  }

  group('الرئيسية (المتطلبات 7، 17)', () {
    testWidgets('المتطلب 7: شعار AO في منطقة الترحيب بعرض 80', (tester) async {
      await pump(tester, const HomeScreen());
      expect(tester.takeException(), isNull);
      final logos = tester.widgetList<AppLogo>(find.byType(AppLogo));
      expect(logos, isNotEmpty, reason: 'يجب أن يظهر الشعار في الرئيسية');
      expect(logos.any((l) => l.width == 80), isTrue,
          reason: 'المتطلب 7 يحدد عرض 80 لشعار الترحيب');
    });

    testWidgets('المتطلبات 17: الأقسام تُرسم كبطاقات فعلية', (tester) async {
      await pump(tester, const HomeScreen());
      expect(tester.takeException(), isNull);
      expect(find.textContaining('فنادق'), findsWidgets);
      expect(find.textContaining('مكة المكرمة'), findsWidgets);
    });

    testWidgets('الرئيسية بلا تجاوز على 360px و768px', (tester) async {
      for (final w in const [360.0, 768.0]) {
        await pump(tester, const HomeScreen(), width: w);
        expect(tester.takeException(), isNull, reason: 'تجاوز على ${w}px');
      }
    });

    testWidgets('الرئيسية الإنجليزية تُرسم LTR بلا تجاوز', (tester) async {
      await pump(tester, const HomeScreen(), locale: 'en');
      expect(tester.takeException(), isNull);
    });

    testWidgets('حالة «لا نتائج» لا تتجاوز الارتفاع الثابت للشرائح',
        (tester) async {
      // انحدار: كانت `EmptyView` عمودية بارتفاع ~134px داخل شريحة 104px،
      // فيظهر "RenderFlex overflowed by 70 pixels" على مسار الفراغ.
      ApiClient.instance.dio.httpClientAdapter = _Adapter(empty: true);
      for (final w in const [360.0, 390.0, 768.0]) {
        await pump(tester, const HomeScreen(), width: w);
        expect(tester.takeException(), isNull,
            reason: 'تجاوز في حالة الفراغ على ${w}px');
      }
    });
  });

  group('المتطلب 71: نص الإشعار الحقيقي', () {
    testWidgets('يعرض body_ar في العربية', (tester) async {
      await pump(tester, const OwnerNotificationsScreen());
      expect(tester.takeException(), isNull);
      expect(find.textContaining('تم تأكيد حجزك في فيرمونت مكة'), findsWidgets);
    });

    testWidgets('يعرض body_en في الإنجليزية', (tester) async {
      await pump(tester, const OwnerNotificationsScreen(), locale: 'en');
      expect(tester.takeException(), isNull);
      expect(
          find.textContaining('Your booking at Fairmont Makkah is confirmed'),
          findsWidgets);
    });
  });

  group('المتطلب 59: شاشة طلب خدمة الضيف', () {
    testWidgets('تُرسم ببياناتها بلا استثناء', (tester) async {
      await pump(
        tester,
        const ServiceRequestScreen(
          icon: Icons.cleaning_services,
          title: 'طلب نظافة',
          description: 'طلب نظافة الغرفة',
          serviceType: 'housekeeping',
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(ServiceRequestScreen), findsOneWidget);
    });
  });
}
