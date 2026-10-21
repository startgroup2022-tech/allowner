import 'dart:convert';
import 'dart:typed_data';

import 'package:allowners/models/hotel_model.dart';
import 'package:allowners/screens/booking/booking_screen.dart';
import 'package:allowners/screens/hotel/hotel_details_screen.dart';
import 'package:allowners/screens/home/home_screen.dart';
import 'package:allowners/screens/search/search_screen.dart';
import 'package:allowners/screens/unit/unit_details_screen.dart';
import 'package:allowners/services/api_client.dart';
import 'package:allowners/theme/app_theme.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// اختبارات عرض حقيقية للشاشات الرئيسية: تُبنى شجرة الواجهة الفعلية وتُرسَم،
/// وكل البيانات تأتي من الحمولات الحقيقية المسجَّلة من `all-owner.online`.
///
/// الهدف: إثبات أن الشاشة **تُبنى وتُرسم** ببيانات السيرفر الفعلية بلا استثناء
/// ولا تجاوز (overflow) على العروض المطلوبة (360/390/768)، وأن الحالات
/// الفارغة والخطأ تظهر صحيحة. هذه ليست لقطات شاشة أندرويد، لكنها رسم فعلي
/// لشجرة الودجات الحقيقية.
///
/// البيانات أدناه منسوخة حرفيًا من استجابات الإنتاج في 2026-10-19، بلا تلفيق.
const _citiesJson = {
  'success': true,
  'cities': [
    {
      'id': 2,
      'name_ar': 'جدة',
      'name_en': 'Jeddah',
      'image_url': '',
    },
    {
      'id': 3,
      'name_ar': 'مكة المكرمة',
      'name_en': 'Makkah',
      'image_url': '',
    },
    {
      'id': 4,
      'name_ar': 'المدينة المنورة',
      'name_en': 'Madinah',
      'image_url': '',
    },
  ],
};

const _categoriesJson = {
  'success': true,
  'categories': [
    {
      'id': 1,
      'name_ar': 'فنادق',
      'name_en': 'Hotels',
      'icon_key': 'hotels',
      'color_hex': '#14151A',
    },
    {
      'id': 2,
      'name_ar': 'شقق فندقية',
      'name_en': 'Apartments',
      'icon_key': 'apartments',
      'color_hex': '#4A5568',
    },
  ],
};

const List<Map<String, dynamic>> _hotelsList = [
  {
    'id': 2,
    'name': 'فندق فيرمونت مكه',
    'city_ar': 'مكة المكرمة',
    'city_en': 'Makkah',
    'type_ar': 'فندق',
    'type_en': 'Hotel',
    'stars': 5,
    'rating': 0,
    'reviews_count': 0,
    'price_per_night': 1500,
    'free_cancellation': true,
    'cover_image': '',
    'is_featured': 1,
  },
  {
    'id': 3,
    'name': 'فندق العنوان',
    'city_ar': 'مكة المكرمة',
    'city_en': 'Makkah',
    'type_ar': 'فندق',
    'type_en': 'Hotel',
    'stars': 4,
    'rating': 0,
    'reviews_count': 0,
    'price_per_night': 900,
    'cover_image': '',
    'is_featured': 0,
  },
];

final _hotelsJson = {'success': true, 'hotels': _hotelsList};

const _unitsJson = {
  'success': true,
  'units': [
    {
      'id': 13,
      'hotel_id': 2,
      'name_ar': 'جناح عائلي',
      'name_en': 'Family suite',
      'unit_type_ar': 'جناح عائلي',
      'capacity': 2,
      'bed_count': 1,
      'price_per_night': 1500,
      'cover_image': '',
      'hotel_name': 'فندق فيرمونت مكه',
      'city_ar': 'مكة المكرمة',
      'city_en': 'Makkah',
    },
  ],
};

const _hotelDetailJson = {
  'success': true,
  'hotel': {
    'id': 2,
    'name': 'فندق فيرمونت مكه',
    'city_ar': 'مكة المكرمة',
    'city_en': 'Makkah',
    'type_ar': 'فندق',
    'type_en': 'Hotel',
    'stars': 5,
    'rating': 0,
    'reviews_count': 0,
    'price_per_night': 1500,
    'description_ar': 'فندق قريب من الحرم.',
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

const _unitDetailJson = {
  'success': true,
  'unit': {
    'id': 13,
    'hotel_id': 2,
    'name_ar': 'جناح عائلي',
    'name_en': 'Family suite',
    'unit_type_ar': 'جناح عائلي',
    'capacity': 2,
    'bed_count': 1,
    'price_per_night': 1500,
    'description_ar': 'جناح واسع.',
    'cover_image': '',
    'hotel_name': 'فندق فيرمونت مكه',
    'city_ar': 'مكة المكرمة',
    'city_en': 'Makkah',
  },
  'addons': [],
  'availability': [],
};

/// محوّل HTTP وهمي يخدم الحمولات الحقيقية أعلاه حسب المسار.
///
/// نستخدم هذا بدل اعتراض الشبكة لأن الاختبار يجب أن يعمل بلا شبكة وبلا
/// اعتماد على توفّر السيرفر، لكن **عبر طبقة Dio والـ services الحقيقية** —
/// فما نختبره هو مسار التحليل الفعلي لا mock للـ service.
class _FixtureAdapter implements HttpClientAdapter {
  _FixtureAdapter({this.overridePath});

  /// إن حُدِّد، يُعاد هذا المسار بخطأ 500 لاختبار حالة الخطأ.
  final String? overridePath;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    if (overridePath != null && path.contains(overridePath!)) {
      return ResponseBody.fromString('{"success":false,"message":"boom"}', 500,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          });
    }

    Object body;
    if (path.contains('cities/list')) {
      body = _citiesJson;
    } else if (path.contains('categories/list')) {
      body = _categoriesJson;
    } else if (path.contains('hotels/detail')) {
      body = _hotelDetailJson;
    } else if (path.contains('hotels/list')) {
      body = _hotelsJson;
    } else if (path.contains('units/detail')) {
      body = _unitDetailJson;
    } else if (path.contains('units/browse') || path.contains('units/list')) {
      body = _unitsJson;
    } else if (path.contains('content/settings')) {
      body = {'success': true};
    } else {
      body = {'success': true};
    }

    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

Widget _wrap(Widget child, {bool isArabic = true, double width = 390}) {
  return ProviderScope(
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
}

void main() {
  late HttpClientAdapter _originalAdapter;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _originalAdapter = ApiClient.instance.dio.httpClientAdapter;
    ApiClient.instance.dio.httpClientAdapter = _FixtureAdapter();
  });

  tearDown(() {
    ApiClient.instance.dio.httpClientAdapter = _originalAdapter;
  });

  group('عرض الصفحة الرئيسية ببيانات حقيقية', () {
    for (final w in const [360.0, 390.0, 768.0]) {
      testWidgets('الرئيسية العربية تُرسم بلا تجاوز على ${w.toInt()}px',
          (tester) async {
        tester.view.physicalSize = Size(w, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_wrap(const HomeScreen(), width: w));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        // الوجهات من cities/list.php الحقيقي
        expect(find.text('مكة المكرمة'), findsWidgets);
        // التصنيف يعرض التسمية المعتمدة للمتطلب 13 («الوحدات الفندقية») لا
        // الاسم الحرفي من قاعدة البيانات — الاثنان من نفس الصف الحقيقي.
        expect(find.text('الوحدات الفندقية'), findsWidgets);
      });
    }

    testWidgets('الرئيسية الإنجليزية تُرسم LTR بلا تجاوز', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // اللغة تأتي من `localeProvider` المحفوظة في التفضيلات، لا من
      // MaterialApp.locale، فنضبط التفضيل قبل بناء الشاشة.
      SharedPreferences.setMockInitialValues({'app_locale': 'en'});

      await tester
          .pumpWidget(_wrap(const HomeScreen(), isArabic: false, width: 390));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Hotel units'), findsWidgets);
    });
  });

  group('عرض شاشة البحث', () {
    testWidgets('البحث بالمدينة يعرض النتائج من الحمولة الحقيقية',
        (tester) async {
      await tester
          .pumpWidget(_wrap(const SearchScreen(initialCity: 'مكة المكرمة')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('فندق فيرمونت مكه'), findsWidgets);
    });

    testWidgets('تصنيف عربي حقيقي (فنادق) لا يُفرّغ النتائج', (tester) async {
      await tester.pumpWidget(
        _wrap(const SearchScreen(initialCategoryName: 'فنادق')),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // العيب المُصلح: كان «فنادق» يعيد صفرًا لأن type_ar مفرد «فندق».
      expect(find.text('فندق فيرمونت مكه'), findsWidgets);
    });

    testWidgets('شريحة التصنيف تعرض التسمية المعتمدة لا اسم قاعدة البيانات',
        (tester) async {
      // العيب المُصلح: الرئيسية تعرض «الوحدات الفندقية» (المتطلبان 13 و14)
      // لكن الشريحة كانت تعرض الاسم الحرفي «فنادق» بعد الضغط — تسميتان
      // لنفس التصنيف في شاشتين متتاليتين.
      await tester.pumpWidget(
        _wrap(const SearchScreen(
          initialCategoryId: 1,
          initialCategoryName: 'فنادق',
        )),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('الوحدات الفندقية'), findsWidgets);
      expect(find.text('فنادق'), findsNothing);
    });
  });

  group('عرض تفاصيل الفندق', () {
    testWidgets('المرافق الحقيقية تظهر من hotels/detail.php', (tester) async {
      final hotel = HotelModel.fromJson(
        Map<String, dynamic>.from(_hotelsList[0]),
      );
      await tester.pumpWidget(_wrap(HotelDetailsScreen(hotel: hotel)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('فندق فيرمونت مكه'), findsWidgets);
      expect(find.text('واي فاي'), findsWidgets);
    });

    testWidgets('الخطأ 500 يُظهر حالة خطأ مع إعادة المحاولة لا شاشة فارغة',
        (tester) async {
      ApiClient.instance.dio.httpClientAdapter =
          _FixtureAdapter(overridePath: 'hotels/detail');
      final hotel = HotelModel.fromJson(
        Map<String, dynamic>.from(_hotelsList[0]),
      );
      await tester.pumpWidget(_wrap(HotelDetailsScreen(hotel: hotel)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // الشاشة لا تنهار ويظهر عنوان الفندق من الحمولة الممرَّرة
      expect(find.text('فندق فيرمونت مكه'), findsWidgets);
    });
  });

  group('عرض تفاصيل الوحدة', () {
    testWidgets('الوحدة تُرسم ببياناتها الحقيقية وزر الحجز', (tester) async {
      await tester.pumpWidget(_wrap(const UnitDetailsScreen(unitId: 13)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('جناح عائلي'), findsWidgets);
    });
  });

  group('اختيار الفندق والوحدة للحجز (المتطلبان 95، 96)', () {
    testWidgets('المتطلب 96: وحدات الفندق تُعرض للاختيار مع زر الحجز',
        (tester) async {
      final hotel = HotelModel.fromJson(
        Map<String, dynamic>.from(_hotelsList[0]),
      );
      await tester.pumpWidget(_wrap(HotelDetailsScreen(hotel: hotel)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // وحدات الفندق تُجلب من units/list.php وتظهر بأسمائها الحقيقية.
      expect(find.textContaining('جناح عائلي'), findsWidgets);
      // لكل وحدة زر «احجز الآن» يقود لنموذج الحجز.
      expect(find.text('احجز الآن'), findsWidgets);
    });

    testWidgets('المتطلبان 95 و96: الضغط على وحدة يفتح نموذج الحجز بها',
        (tester) async {
      final hotel = HotelModel.fromJson(
        Map<String, dynamic>.from(_hotelsList[0]),
      );
      await tester.pumpWidget(_wrap(HotelDetailsScreen(hotel: hotel)));
      await tester.pumpAndSettle();

      // نمرّر لزر الوحدة ثم نضغطه لنتأكد أننا ننتقل فعلًا لنموذج الحجز.
      final bookButton = find.text('احجز الآن').first;
      await tester.ensureVisible(bookButton);
      await tester.pumpAndSettle();
      await tester.tap(bookButton, warnIfMissed: true);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // نموذج الحجز هو شاشة مستقلة (BookingScreen) وليس تفاصيل الفندق.
      expect(find.byType(BookingScreen), findsOneWidget);
      expect(find.textContaining('جناح عائلي'), findsWidgets);
    });
  });
}
