import 'dart:convert';
import 'dart:typed_data';

import 'package:allowners/screens/home/home_screen.dart';
import 'package:allowners/screens/owner/owner_notifications_screen.dart';
import 'package:allowners/screens/services/service_request_screen.dart';
import 'package:allowners/services/api_client.dart';
import 'package:allowners/theme/app_theme.dart';
import 'package:allowners/widgets/app_logo.dart';
import 'package:allowners/widgets/cards.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// تغطية المتطلبات التي كانت بلا اختبار: 7، 17 (الرئيسية)، 59 (شاشة طلب خدمة
/// الضيف)، 71 (نص الإشعار الحقيقي بالعربية والإنجليزية).
class _Adapter implements HttpClientAdapter {
  _Adapter({this.empty = false, this.logoUrl});

  /// يعيد قوائم فارغة — مسار «لا نتائج» الذي يعرض `EmptyView`.
  final bool empty;

  /// رابط شعار تُعلنه لوحة التحكم، لاختبار مسار الشعار من الإعدادات.
  final String? logoUrl;

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
      // قسم «فنادق بوحدات ملاك» (21–23): نحترم فلتر المدينة ونعيد وحدتين
      // لفندقين مختلفين لاختبار عدد الوحدات وأقل سعر.
      final city = options.queryParameters['city']?.toString();
      final all = [
        {
          'id': 11,
          'hotel_id': 2,
          'hotel_name': 'فندق فيرمونت مكه',
          'name_ar': 'جناح عائلي',
          'name_en': 'Family Suite',
          'price_per_night': '450',
          'city_ar': 'مكة المكرمة',
          'city_en': 'Makkah',
        },
        {
          'id': 12,
          'hotel_id': 2,
          'hotel_name': 'فندق فيرمونت مكه',
          'name_ar': 'غرفة ديلوكس',
          'name_en': 'Deluxe Room',
          'price_per_night': '300',
          'city_ar': 'مكة المكرمة',
          'city_en': 'Makkah',
        },
        {
          'id': 13,
          'hotel_id': 3,
          'hotel_name': 'فندق العنوان جدة',
          'name_ar': 'استوديو',
          'name_en': 'Studio',
          'price_per_night': '700',
          'city_ar': 'جدة',
          'city_en': 'Jeddah',
        },
      ];
      final filtered = city == null
          ? all
          : all
              .where((u) => u['city_ar'] == city || u['city_en'] == city)
              .toList();
      body = {'success': true, 'units': empty ? [] : filtered};
    } else if (path.contains('/hotels/list.php')) {
      final city = options.queryParameters['city']?.toString();
      final all = [
        {
          'id': 2,
          'name': 'فندق فيرمونت مكه',
          'city_ar': 'مكة المكرمة',
          'city_en': 'Makkah',
          'rating': 4.5,
          'reviews_count': 120,
        },
        {
          'id': 3,
          'name': 'فندق العنوان جدة',
          'city_ar': 'جدة',
          'city_en': 'Jeddah',
          'rating': 4.2,
          'reviews_count': 88,
        },
      ];
      final filtered = city == null
          ? all
          : all
              .where((h) => h['city_ar'] == city || h['city_en'] == city)
              .toList();
      body = {'success': true, 'hotels': empty ? [] : filtered};
    } else if (path.contains('settings')) {
      // الشكل الحقيقي من content/settings.php: logo_url في الجذر لا داخل settings.
      body = {
        'success': true,
        if (logoUrl != null) 'logo_url': logoUrl,
      };
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

  group('الشعار (المتطلب 6)', () {
    Future<void> pumpLogo(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.light(isArabic: true),
          home: const Scaffold(body: AppLogo(width: 200, full: true)),
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('يُجلب من إعدادات الموقع الحقيقية عند إعلانه', (tester) async {
      ApiClient.instance.dio.httpClientAdapter =
          _Adapter(logoUrl: 'https://all-owner.online/assets/images/logo.png');
      await pumpLogo(tester);
      expect(tester.takeException(), isNull);
      // الرابط المُعلَن يُستخدم للشعار الكامل بدل النسخة المحلية.
      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });

    testWidgets('يرجع للنسخة المحلية عند غياب الرابط من الإعدادات',
        (tester) async {
      ApiClient.instance.dio.httpClientAdapter = _Adapter();
      await pumpLogo(tester);
      expect(tester.takeException(), isNull);
      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.byType(Image), findsWidgets);
    });
  });

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

  group('قسم فنادق بوحدات ملاك (المتطلبات 21–23)', () {
    testWidgets('المتطلب 21: القسم يظهر في الرئيسية بعنوانه', (tester) async {
      await pump(tester, const HomeScreen());
      expect(tester.takeException(), isNull);
      expect(find.text('فنادق بوحدات ملاك'), findsOneWidget);
      expect(find.byType(OwnerHotelCard), findsWidgets);
    });

    testWidgets('المتطلب 22: البطاقة تعرض عدد الوحدات والتقييم والمدينة',
        (tester) async {
      await pump(tester, const HomeScreen());
      expect(tester.takeException(), isNull);
      // فندق فيرمونت له وحدتان في بيانات الاختبار → «2 وحدة متاحة للحجز».
      expect(find.textContaining('2 وحدة متاحة للحجز'), findsWidgets);
      expect(find.textContaining('مكة المكرمة'), findsWidgets);
      // التقييم 4.5 يُعرض بمنزلة عشرية واحدة.
      expect(find.text('4.5'), findsWidgets);
    });

    testWidgets('المتطلب 23: اختيار مدينة يعيد التحميل مُفلترًا بالمدينة',
        (tester) async {
      await pump(tester, const HomeScreen());
      expect(tester.takeException(), isNull);
      // قبل الفلترة: فندقان (مكة وجدة).
      expect(find.textContaining('فندق العنوان جدة'), findsWidgets);

      // «كل المدن» لا يظهر إلا في شريط مدن قسم وحدات الملاك، فنستعمل قائمته
      // لتحديد شريحة «مكة المكرمة» الصحيحة (لا بطاقة وجهة أو قسم آخر).
      final cityBar = find.ancestor(
        of: find.text('كل المدن'),
        matching: find.byType(ListView),
      );
      final makkahChip = find.descendant(
        of: cityBar,
        matching: find.text('مكة المكرمة'),
      );
      expect(makkahChip, findsOneWidget);
      await tester.tap(makkahChip);
      await tester.pumpAndSettle();

      // بعد اختيار «مكة المكرمة»: يبقى فندق مكة ويختفي فندق جدة.
      expect(tester.takeException(), isNull);
      expect(find.textContaining('فندق فيرمونت مكه'), findsWidgets);
      expect(find.textContaining('فندق العنوان جدة'), findsNothing);
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
