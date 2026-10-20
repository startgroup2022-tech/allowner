import 'package:allowners/models/category_model.dart';
import 'package:allowners/models/city_model.dart';
import 'package:allowners/models/hotel_model.dart';
import 'package:allowners/models/unit_model.dart';
import 'package:allowners/services/hotel_service.dart';
import 'package:allowners/theme/app_colors.dart';
import 'package:allowners/theme/app_theme.dart';
import 'package:allowners/utils/amenity_icons.dart';
import 'package:allowners/utils/app_strings.dart';
import 'package:allowners/widgets/cards.dart';
import 'package:allowners/widgets/state_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// يغلّف أي widget بتطبيق كامل مع اتجاه اللغة المطلوبة — لاختبار RTL/LTR
/// والعرض على عروض شاشات مختلفة.
Widget wrap(Widget child, {bool isArabic = true, double width = 390}) {
  return MaterialApp(
    locale: Locale(isArabic ? 'ar' : 'en'),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: AppTheme.light(isArabic: isArabic),
    home: Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: MediaQuery(
        data: MediaQueryData(size: Size(width, 844)),
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

HotelModel hotel() => HotelModel.fromJson({
      'id': 4,
      'name': 'فيرمونت مكة',
      'city_ar': 'مكة المكرمة',
      'city_en': 'Makkah',
      'type_ar': 'فندق',
      'type_en': 'Hotel',
      'stars': 5,
      'price_per_night': 1500,
      'cover_image': '',
      'free_cancellation': 1,
    });

UnitModel unit() => UnitModel.fromJson({
      'id': 13,
      'hotel_id': 2,
      'hotel_name': 'فندق فيرمونت مكه',
      'name_ar': 'جناح عائلي',
      'unit_type_ar': 'جناح',
      'capacity': 2,
      'bed_count': 1,
      'price_per_night': 1500,
      'cover_image': '',
      'city_ar': 'مكة المكرمة',
    });

void main() {
  group('الحالات (Loading/Error/Empty)', () {
    testWidgets('LoadingView يعرض مؤشر تحميل', (tester) async {
      await tester.pumpWidget(wrap(const LoadingView()));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('ErrorView يعرض الرسالة وزر إعادة المحاولة ويعمل',
        (tester) async {
      var retried = false;
      await tester.pumpWidget(wrap(ErrorView(
        message: 'تعذّر الاتصال',
        isArabic: true,
        onRetry: () => retried = true,
      )));

      expect(find.text('تعذّر الاتصال'), findsOneWidget);
      await tester.tap(find.text(AppStrings.t(true, 'retry')));
      expect(retried, isTrue);
    });

    testWidgets('EmptyView يعرض رسالة الفراغ وزر الإجراء', (tester) async {
      var acted = false;
      await tester.pumpWidget(wrap(EmptyView(
        message: 'لا توجد نتائج مطابقة',
        actionLabel: 'مسح البحث',
        onAction: () => acted = true,
      )));

      expect(find.text('لا توجد نتائج مطابقة'), findsOneWidget);
      await tester.tap(find.text('مسح البحث'));
      expect(acted, isTrue);
    });
  });

  group('بطاقة الفندق', () {
    testWidgets('تعرض الاسم والمدينة والسعر وتستدعي onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(wrap(
        HotelCard(hotel: hotel(), isArabic: true, onTap: () => tapped = true),
      ));
      await tester.pump();

      expect(find.text('فيرمونت مكة'), findsOneWidget);
      expect(find.text('مكة المكرمة'), findsOneWidget);
      expect(find.text('1500'), findsOneWidget);

      await tester.tap(find.text('فيرمونت مكة'));
      expect(tapped, isTrue);
    });

    testWidgets('تعرض "السعر عند الطلب" بدل صفر', (tester) async {
      final free =
          HotelModel.fromJson({'id': 1, 'name': 'فندق', 'price_per_night': 0});
      await tester.pumpWidget(wrap(
        HotelCard(hotel: free, isArabic: true, onTap: () {}),
      ));
      await tester.pump();
      expect(find.text(AppStrings.t(true, 'price_on_request')), findsOneWidget);
    });

    testWidgets('لا تعرض خطأ عند غياب الصورة', (tester) async {
      await tester.pumpWidget(wrap(
        HotelCard(hotel: hotel(), isArabic: false, onTap: () {}),
      ));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('بطاقة الوحدة', () {
    testWidgets('تعرض الاسم والفندق والسعة والأسرّة', (tester) async {
      await tester.pumpWidget(wrap(
        UnitCard(unit: unit(), isArabic: true, onTap: () {}),
      ));
      await tester.pump();

      expect(find.text('جناح عائلي'), findsOneWidget);
      expect(find.text('فندق فيرمونت مكه'), findsOneWidget);
      expect(find.text('2'), findsWidgets);
    });

    testWidgets('UnitListCard لا تنهار بدون صور', (tester) async {
      await tester.pumpWidget(wrap(
        UnitListCard(unit: unit(), isArabic: false, onTap: () {}),
      ));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('بطاقة التصنيف والوجهة', () {
    testWidgets('CategoryCard تعرض الاسم من قاعدة البيانات', (tester) async {
      final category = CategoryModel.fromJson({
        'id': 1,
        'name_ar': 'شاليهات',
        'name_en': 'Chalets',
        'icon_key': 'chalets',
        'color_hex': '#0F7A42',
      });
      await tester.pumpWidget(wrap(
        CategoryCard(category: category, isArabic: true, onTap: () {}),
      ));
      expect(find.text('شاليهات'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CategoryCard لا تنهار مع color_hex غير صالح', (tester) async {
      final category = CategoryModel.fromJson(
          {'id': 2, 'name_ar': 'منتجعات', 'color_hex': 'bad'});
      await tester.pumpWidget(wrap(
        CategoryCard(category: category, isArabic: true, onTap: () {}),
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('DestinationCard تعرض اسم المدينة', (tester) async {
      final city = CityModel.fromJson(
          {'id': 3, 'name_ar': 'مكة المكرمة', 'name_en': 'Makkah'});
      await tester.pumpWidget(wrap(
        DestinationCard(city: city, isArabic: true, onTap: () {}),
      ));
      await tester.pump();
      expect(find.text('مكة المكرمة'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('عرض السعر', () {
    testWidgets('يظهر بالعملة ولمدة الليلة', (tester) async {
      await tester.pumpWidget(wrap(
        const PriceText(amount: 1500, isArabic: true),
      ));
      expect(find.text('1500'), findsOneWidget);
      expect(find.text(AppStrings.t(true, 'sar')), findsOneWidget);
      expect(
          find.textContaining(AppStrings.t(true, 'per_night')), findsOneWidget);
    });

    testWidgets('يعرض كسور عشرية عند وجودها', (tester) async {
      await tester.pumpWidget(wrap(
        const PriceText(amount: 2300.75, isArabic: false),
      ));
      expect(find.text('2300.75'), findsOneWidget);
    });
  });

  group('الاتجاه والعرض المتجاوب', () {
    testWidgets('البطاقة تعمل في RTL و LTR', (tester) async {
      for (final arabic in [true, false]) {
        await tester.pumpWidget(wrap(
          HotelCard(hotel: hotel(), isArabic: arabic, onTap: () {}),
          isArabic: arabic,
        ));
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('لا يوجد overflow على عرض 360px', (tester) async {
      await tester.pumpWidget(wrap(
        UnitCard(unit: unit(), isArabic: true, onTap: () {}),
        width: 360,
      ));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('لا يوجد overflow على عرض 768px', (tester) async {
      await tester.pumpWidget(wrap(
        HotelCard(hotel: hotel(), isArabic: false, onTap: () {}),
        width: 768,
      ));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('أيقونات المرافق (من قاعدة البيانات)', () {
    test('تحوّل مفاتيح الأيقونات الحقيقية القادمة من الـ API', () {
      expect(AmenityIcons.resolve(iconKey: 'wifi'), Icons.wifi_rounded);
      expect(AmenityIcons.resolve(iconKey: 'local_parking'),
          Icons.local_parking_outlined);
      expect(AmenityIcons.resolve(iconKey: 'fitness_center'),
          Icons.fitness_center_outlined);
      expect(AmenityIcons.resolve(iconKey: 'ac_unit'), Icons.ac_unit_rounded);
      expect(AmenityIcons.resolve(iconKey: 'restaurant'),
          Icons.restaurant_outlined);
      expect(AmenityIcons.resolve(iconKey: 'room_service'),
          Icons.room_service_outlined);
      expect(AmenityIcons.resolve(iconKey: 'coffee_maker'),
          Icons.coffee_maker_outlined);
    });

    test('ترجع أيقونة عامة لمفتاح غير معروف (لا انهيار)', () {
      expect(AmenityIcons.resolve(iconKey: 'brand_new_amenity_xyz'),
          Icons.check_circle_outline_rounded);
      expect(AmenityIcons.resolve(iconKey: null),
          Icons.check_circle_outline_rounded);
      expect(AmenityIcons.resolve(iconKey: '  '),
          Icons.check_circle_outline_rounded);
    });

    test('تستنتج الأيقونة من الاسم عندما لا يوجد مفتاح', () {
      expect(AmenityIcons.resolve(nameEn: 'Free WiFi'), Icons.wifi_rounded);
      expect(AmenityIcons.resolve(nameEn: 'Air Conditioning'),
          Icons.ac_unit_rounded);
    });
  });

  group('مرافق الوحدة مقابل مرافق الفندق المشتركة', () {
    // الـ API الحالي (`units/detail.php`) لا يعيد أي حقل مرافق. الوحدة يجب أن
    // تُقرأ بلا مرافق بدل أن تنهار، ومرافق الفندق تُعرض منفصلة عنها.
    test('غياب حقل المرافق في الوحدة يعطي قائمة فارغة (لا انهيار)', () {
      final unit = UnitModel.fromJson({
        'id': 13,
        'name_ar': 'جناح عائلي',
        'hotel_id': 2,
      });
      expect(unit.facilities, isEmpty);
    });

    test('يقرأ مرافق الوحدة من `facilities` عند وجودها', () {
      final unit = UnitModel.fromJson({
        'id': 13,
        'name_ar': 'جناح عائلي',
        'facilities': [
          {
            'id': 1,
            'name_ar': 'واي فاي',
            'name_en': 'Free WiFi',
            'icon': 'wifi'
          },
        ],
      });
      expect(unit.facilities, hasLength(1));
      expect(unit.facilities.first['name_ar'], 'واي فاي');
    });

    test('يقبل `amenities` كبديل عن `facilities` (توافق مع شكل الاستجابة)', () {
      final unit = UnitModel.fromJson({
        'id': 13,
        'name_ar': 'جناح عائلي',
        'amenities': [
          {'id': 2, 'name_ar': 'تكييف', 'name_en': 'AC', 'icon': 'ac_unit'},
        ],
      });
      expect(unit.facilities, hasLength(1));
      expect(unit.facilities.first['name_en'], 'AC');
    });

    test('مرافق الوحدة والفندق المشتركة تُعرض بعنوانين مختلفين', () {
      // مفاتيح مستقلة حتى لا يختلط ما يخص الوحدة بما هو مشترك في الفندق.
      final unitTitle = AppStrings.t(true, 'unit_facilities');
      final sharedTitle = AppStrings.t(true, 'hotel_shared_facilities');
      expect(unitTitle, isNot(sharedTitle));
      expect(AppStrings.t(false, 'unit_facilities'),
          isNot(AppStrings.t(false, 'hotel_shared_facilities')));
      // ملاحظة الوحدة الفارغة تحيل صراحةً إلى قسم الفندق بدل أن تبدو معطّلة.
      expect(AppStrings.t(true, 'unit_facilities_empty_note'), isNotEmpty);
      expect(AppStrings.t(true, 'hotel_shared_facilities_note'), isNotEmpty);
    });

    test('بطاقة المرفق تعرض الاسم حسب اللغة', () {
      final ar = AppStrings.t(true, 'unit_facilities');
      final en = AppStrings.t(false, 'unit_facilities');
      expect(ar, 'مرافق الوحدة');
      expect(en, 'Unit facilities');
    });
  });

  group('الترجمة (ar/en)', () {
    test('كل المفاتيح المستخدمة في الشاشات الجديدة موجودة بالعربي والإنجليزي',
        () {
      const usedKeys = [
        'retry',
        'featured_hotels',
        'featured_destinations',
        'recently_added_units',
        'browse_by_category',
        'search_city_or_hotel',
        'search_hotels_tab',
        'search_units_tab',
        'all_categories',
        'clear_search',
        'price_on_request',
        'no_description',
        'no_amenities',
        'about_unit',
        'unit_facilities',
        'availability_period',
        'no_availability_info',
        'not_available',
        'view_hotel',
        'load_failed_title',
        'session_expired',
        'hotels_with_owner_units',
        'no_units',
        'available_units',
        'amenities',
        'about_property',
        'unit_facilities',
        'hotel_shared_facilities',
        'hotel_shared_facilities_note',
        'unit_facilities_empty_note',
      ];

      for (final key in usedKeys) {
        final ar = AppStrings.t(true, key);
        final en = AppStrings.t(false, key);
        expect(ar, isNotEmpty, reason: 'مفتاح عربي مفقود: $key');
        expect(en, isNotEmpty, reason: 'مفتاح إنجليزي مفقود: $key');
        expect(ar, isNot(key), reason: 'مفتاح غير مُترجم (عربي): $key');
        expect(en, isNot(key), reason: 'مفتاح غير مُترجم (إنجليزي): $key');
      }
    });
  });

  group('لوحة الألوان', () {
    test('الألوان الأساسية معرّفة', () {
      expect(AppColors.gold, isNotNull);
      expect(AppColors.ink, isNotNull);
      expect(AppColors.background, isNotNull);
      expect(AppColors.surface, isNotNull);
    });
  });

  group('منع المحتوى الوهمي', () {
    test('بناء HotelModel مباشرة يعمل بدون بيانات وهمية', () {
      // كانت النسخة السابقة تحقن فنادق تجريبية (Ritz Carlton Riyadh،
      // Jeddah Hilton…) داخل HotelModel. يجب أن تبقى البيانات من الـ API فقط.
      expect(
        () => HotelModel(
          id: 'x',
          name: 'x',
          cityAr: 'x',
          cityEn: 'x',
          typeAr: 'x',
          typeEn: 'x',
          rating: 0,
          reviewsCount: 0,
          pricePerNight: 0,
          stars: 0,
          imageUrl: '',
          galleryUrls: const [],
          freeCancellation: false,
          breakfastIncluded: false,
          isFavorite: false,
          extraBedPrice: 0,
        ),
        returnsNormally,
      );
    });

    test('الحقول الرقمية تُقرأ كنصوص أو أرقام بأمان', () {
      // نصوص DECIMAL القادمة من PDO/PHP يجب ألا تُسقط التحليل.
      final hotel = HotelModel.fromJson(const {
        'id': '9',
        'name': 'فندق اختبار',
        'city_ar': 'مكة المكرمة',
        'city_en': 'Makkah',
        'price_per_night': '1234.50',
        'rating': '4.5',
        'stars': '5',
        'reviews_count': '12',
      });
      expect(hotel.id, '9');
      expect(hotel.pricePerNight, closeTo(1234.5, 0.001));
      expect(hotel.rating, closeTo(4.5, 0.001));
      expect(hotel.stars, 5);
      expect(hotel.reviewsCount, 12);
    });

    test('غياب الحقول الاختيارية لا يسبب انهيارًا', () {
      final hotel = HotelModel.fromJson(const {'id': 1});
      expect(hotel.id, '1');
      expect(hotel.galleryUrls, isEmpty);
      expect(hotel.pricePerNight, 0);
      expect(hotel.name, isEmpty);
    });
  });

  group('تصفية الفنادق (searchHotels) — تصحيح عيوب حقيقية', () {
    HotelModel h({
      required String name,
      String? typeAr,
      String? typeEn,
      String? cityAr,
      String? cityEn,
    }) =>
        HotelModel.fromJson({
          'id': name,
          'name': name,
          'type_ar': typeAr,
          'type_en': typeEn,
          'city_ar': cityAr,
          'city_en': cityEn,
        });

    test('فندق بلا نوع لا يطابق أي تصنيف (كان يطابق الكل بسبب contains(""))',
        () {
      final noType = h(name: 'بلا نوع');
      for (final cat in ['Hotels', 'Resorts', 'Apartments', 'Chalets']) {
        expect(
          HotelService.filterHotels([noType], categoryName: cat),
          isEmpty,
          reason: 'الفندق بلا نوع يجب ألا يظهر تحت "$cat"',
        );
      }
    });

    test('فندق من نوع فندق يطابق تصنيف Hotels ولا يطابق Resorts', () {
      final hotel = h(name: 'فيرمونت', typeAr: 'فندق', typeEn: 'Hotel');
      expect(
        HotelService.filterHotels([hotel], categoryName: 'Hotels'),
        hasLength(1),
      );
      expect(
        HotelService.filterHotels([hotel], categoryName: 'Resorts'),
        isEmpty,
      );
    });

    test('البحث بالاسم العربي يطابق (بعد تطبيع الهمزات والتاء المربوطة)', () {
      final hotel = h(name: 'فندق فيرمونت مكة', cityAr: 'مكة المكرمة');
      expect(
        HotelService.filterHotels([hotel], query: 'فيرمونت'),
        hasLength(1),
      );
      expect(
        HotelService.filterHotels([hotel], query: 'مكه'),
        hasLength(1),
        reason: 'تطبيع ة→ه و أ→ا يجعل البحث متسامحًا',
      );
    });

    test('البحث بلا نتائج يرجع قائمة فارغة (لا يرمي)', () {
      final hotel = h(name: 'فندق العنوان', cityAr: 'مكة المكرمة');
      expect(
        HotelService.filterHotels([hotel], query: 'شرم الشيخ'),
        isEmpty,
      );
    });

    test('بلا معايير ترجع كل الفنادق', () {
      final list = [h(name: 'أ'), h(name: 'ب', typeAr: 'فندق')];
      expect(HotelService.filterHotels(list), hasLength(2));
    });
  });

  group('متطلبات المستند الأصلي (الجولة الثانية)', () {
    test('العبارة التعريفية تطابق نص المستند لا النص القديم', () {
      expect(AppStrings.t(true, 'app_tagline'), 'المنصة الموثوقة لملاك الوحدات والعقارات');
      expect(AppStrings.t(false, 'app_tagline'), 'The Trusted Platform for Property Owners');
      expect(AppStrings.t(true, 'app_tagline'), isNot(contains('فندقك')));
    });

    test('مفاتيح المتطلبات المضافة موجودة بالعربي والإنجليزي', () {
      const keys = ['app_tagline', 'my_bookings', 'booking_details', 'add_extra_bed', 'housekeeping'];
      for (final k in keys) {
        expect(AppStrings.t(true, k), isNotEmpty, reason: '$k ar');
        expect(AppStrings.t(false, k), isNotEmpty, reason: '$k en');
        expect(AppStrings.t(true, k), isNot(equals(k)), reason: '$k ar غير مترجم');
        expect(AppStrings.t(false, k), isNot(equals(k)), reason: '$k en غير مترجم');
      }
    });

    test('تسمية الوكيل الثانية هي «حجوزاتي» لا «وحداتي»', () {
      expect(AppStrings.t(true, 'my_bookings'), 'حجوزاتي');
      expect(AppStrings.t(true, 'nav_units'), 'وحداتي');
      expect(AppStrings.t(true, 'my_bookings'), isNot(equals(AppStrings.t(true, 'nav_units'))));
    });
  });
}
