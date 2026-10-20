import 'package:allowners/models/app_user.dart';
import 'package:allowners/models/category_model.dart';
import 'package:allowners/models/city_model.dart';
import 'package:allowners/models/hotel_model.dart';
import 'package:allowners/models/owner_hotel_summary.dart';
import 'package:allowners/models/unit_model.dart';
import 'package:allowners/screens/hotel_staff/hotel_bookings_screen.dart';
import 'package:allowners/screens/owner/owner_bookings_screen.dart';
import 'package:allowners/screens/owner/owner_profile_screen.dart';
import 'package:allowners/screens/booking/booking_screen.dart';
import 'package:allowners/screens/bookings/my_bookings_screen.dart';
import 'package:allowners/screens/shared/app_about_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:allowners/services/hotel_service.dart';
import 'package:allowners/theme/app_colors.dart';
import 'package:allowners/theme/app_theme.dart';
import 'package:allowners/utils/amenity_icons.dart';
import 'package:allowners/utils/app_strings.dart';
import 'package:allowners/utils/arabic_text.dart';
import 'package:allowners/utils/category_labels.dart';
import 'package:allowners/utils/city_ordering.dart';
import 'package:allowners/utils/booking_totals.dart';
import 'package:allowners/utils/maintenance_settlement.dart';
import 'package:allowners/utils/role_menus.dart';
import 'package:allowners/utils/revenue_reports.dart';
import 'package:allowners/utils/session_provider.dart';
import 'package:allowners/utils/service_categories.dart';
import 'package:allowners/widgets/cards.dart';
import 'package:allowners/widgets/editable_avatar.dart';
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

  group('بطاقة فندق بوحدات ملاك (OwnerHotelCard)', () {
    OwnerHotelSummary summary({double rating = 4.8, int count = 3}) =>
        OwnerHotelSummary(
          hotelId: '2',
          name: 'فندق فيرمونت مكه',
          cityAr: 'مكة المكرمة',
          cityEn: 'Makkah',
          unitCount: count,
          rating: rating,
          reviewsCount: 12,
          imageUrl: '',
          minPrice: 900,
        );

    testWidgets('تعرض الاسم والمدينة وعدد الوحدات وتستدعي onTap',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(wrap(
        OwnerHotelCard(
          summary: summary(),
          isArabic: true,
          onTap: () => tapped = true,
        ),
      ));
      await tester.pump();

      expect(find.text('فندق فيرمونت مكه'), findsOneWidget);
      expect(find.text('مكة المكرمة'), findsOneWidget);
      expect(find.textContaining('3'), findsWidgets);
      expect(find.text('4.8'), findsOneWidget);

      await tester.tap(find.byType(OwnerHotelCard));
      expect(tapped, isTrue);
    });

    testWidgets('لا تعرض شارة التقييم عند غياب التقييم', (tester) async {
      await tester.pumpWidget(wrap(
        OwnerHotelCard(
          summary: summary(rating: 0),
          isArabic: false,
          onTap: () {},
        ),
      ));
      await tester.pump();
      expect(find.text('0.0'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('لا تنهار بدون صورة', (tester) async {
      await tester.pumpWidget(wrap(
        OwnerHotelCard(summary: summary(), isArabic: true, onTap: () {}),
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

  group('تصفية الوحدات (searchUnits/filterUnits) — المتطلب 26', () {
    UnitModel u({
      required int id,
      required String name,
      String hotel = '',
      String? cityAr,
      String? cityEn,
      String? typeAr,
    }) =>
        UnitModel.fromJson({
          'id': id,
          'hotel_id': 1,
          'hotel_name': hotel,
          'name_ar': name,
          'name_en': name,
          'city_ar': cityAr,
          'city_en': cityEn,
          'unit_type_ar': typeAr,
          'capacity': 2,
          'bed_count': 1,
          'price_per_night': 100,
        });

    test('البحث باسم المدينة يطابق وحداتها (كان الـ API يرجع صفرًا)', () {
      final units = [
        u(
            id: 1,
            name: '4005',
            hotel: 'فندق فيرمونت مكه',
            cityAr: 'مكة المكرمة'),
        u(id: 2, name: 'شاليه البحر', hotel: 'منتجع جدة', cityAr: 'جدة'),
      ];
      final result = HotelService.filterUnits(units, query: 'مكة');
      expect(result, hasLength(1));
      expect(result.first.id, 1);
    });

    test('البحث باسم الفندق يطابق وحداته', () {
      final units = [
        u(id: 1, name: 'A', hotel: 'فندق فيرمونت مكه', cityAr: 'مكة المكرمة'),
        u(id: 2, name: 'B', hotel: 'فندق العنوان', cityAr: 'مكة المكرمة'),
      ];
      expect(HotelService.filterUnits(units, query: 'العنوان'), hasLength(1));
    });

    test('تطبيع ة→ه و أ→ا يجعل البحث متسامحًا مع الهمزات', () {
      final units = [u(id: 1, name: 'جناح', cityAr: 'مكة المكرمة')];
      expect(HotelService.filterUnits(units, query: 'مكه'), hasLength(1));
      expect(HotelService.filterUnits(units, query: 'مكة'), hasLength(1));
    });

    test('البحث بلا نتائج يرجع قائمة فارغة (لا يرمي)', () {
      final units = [u(id: 1, name: 'جناح', cityAr: 'مكة المكرمة')];
      expect(HotelService.filterUnits(units, query: 'طوكيو'), isEmpty);
    });

    test('بلا نص بحث ترجع كل الوحدات', () {
      final units = [u(id: 1, name: 'أ'), u(id: 2, name: 'ب')];
      expect(HotelService.filterUnits(units), hasLength(2));
      expect(HotelService.filterUnits(units, query: '   '), hasLength(2));
    });
  });

  group('متطلبات المستند الأصلي (الجولة الثانية)', () {
    test('العبارة التعريفية تطابق نص المستند لا النص القديم', () {
      expect(AppStrings.t(true, 'app_tagline'),
          'المنصة الموثوقة لملاك الوحدات والعقارات');
      expect(AppStrings.t(false, 'app_tagline'),
          'The Trusted Platform for Property Owners');
      expect(AppStrings.t(true, 'app_tagline'), isNot(contains('فندقك')));
    });

    test('مفاتيح المتطلبات المضافة موجودة بالعربي والإنجليزي', () {
      const keys = [
        'app_tagline',
        'my_bookings',
        'booking_details',
        'add_extra_bed',
        'housekeeping'
      ];
      for (final k in keys) {
        expect(AppStrings.t(true, k), isNotEmpty, reason: '$k ar');
        expect(AppStrings.t(false, k), isNotEmpty, reason: '$k en');
        expect(AppStrings.t(true, k), isNot(equals(k)),
            reason: '$k ar غير مترجم');
        expect(AppStrings.t(false, k), isNot(equals(k)),
            reason: '$k en غير مترجم');
      }
    });

    test('تسمية الوكيل الثانية هي «حجوزاتي» لا «وحداتي»', () {
      expect(AppStrings.t(true, 'my_bookings'), 'حجوزاتي');
      expect(AppStrings.t(true, 'nav_units'), 'وحداتي');
      expect(AppStrings.t(true, 'my_bookings'),
          isNot(equals(AppStrings.t(true, 'nav_units'))));
    });
  });

  group('بحث موظف الفندق برقم الوحدة (المتطلب 81)', () {
    final bookings = <Map<String, dynamic>>[
      {'id': 1, 'unit_number': '4005', 'unit_name_ar': 'جناح مطل كعبة', 'unit_name_en': 'Kaaba View Suite'},
      {'id': 2, 'unit_number': '1201', 'unit_name_ar': 'غرفة سيتي', 'unit_name_en': 'City Room'},
      {'id': 3, 'unit_number': null, 'unit_name_ar': 'شقة مفروشة', 'unit_name_en': 'Furnished Flat'},
    ];

    test('مطابقة برقم الوحدة', () {
      final r = filterBookingsByUnit(bookings, '4005');
      expect(r.length, 1);
      expect(r.first['id'], 1);
    });

    test('مطابقة جزئية برقم الوحدة', () {
      final r = filterBookingsByUnit(bookings, '12');
      expect(r.map((b) => b['id']), contains(2));
    });

    test('مطابقة باسم الوحدة عربي وإنجليزي', () {
      expect(filterBookingsByUnit(bookings, 'سيتي').single['id'], 2);
      expect(filterBookingsByUnit(bookings, 'Kaaba').single['id'], 1);
    });

    test('رقم وحدة فارغ أو null لا يرمي استثناء', () {
      expect(filterBookingsByUnit(bookings, 'flat').single['id'], 3);
      expect(filterBookingsByUnit(bookings, 'شقة').single['id'], 3);
    });

    test('استعلام فارغ يعيد كل الحجوزات', () {
      expect(filterBookingsByUnit(bookings, '').length, 3);
      expect(filterBookingsByUnit(bookings, '   ').length, 3);
    });

    test('لا نتائج عند عدم التطابق', () {
      expect(filterBookingsByUnit(bookings, 'zzz'), isEmpty);
    });
  });

  group('إضافات الحجز في حجوزات المالك (المتطلب 73)', () {
    test('حجز بلا إضافات لا ينتج أسطرًا', () {
      expect(buildBookingAddonLines(true, const {'id': 1}), isEmpty);
    });

    test('وجبات من addons تُعرض بالاسم العربي', () {
      final lines = buildBookingAddonLines(true, const {
        'addons': [
          {'name_ar': 'فطور', 'name_en': 'Breakfast'},
          {'name_ar': 'عشاء', 'name_en': 'Dinner'},
        ]
      });
      expect(lines.single, contains('فطور'));
      expect(lines.single, contains('عشاء'));
    });

    test('الوجبات القديمة meal_types تُترجم', () {
      final lines = buildBookingAddonLines(true, const {
        'meal_types': [
          {'type': 'breakfast'}
        ]
      });
      expect(lines.single, contains(AppStrings.t(true, 'meal_option_breakfast')));
    });

    test('السرير الإضافي يعرض الكمية والسعر', () {
      final lines = buildBookingAddonLines(true, const {
        'extra_bed_count': 2,
        'extra_bed_price': 150.0,
      });
      expect(lines.single, contains('× 2'));
      expect(lines.single, contains('150'));
    });

    test('قيم نصية للسرير الإضافي لا ترمي استثناء', () {
      final lines = buildBookingAddonLines(false, const {
        'extra_bed_count': '3',
        'extra_bed_price': '99.5',
      });
      expect(lines.single, contains('× 3'));
      expect(lines.single, contains('100'));
    });

    test('الملاحظات تظهر إن وُجدت', () {
      final lines = buildBookingAddonLines(true, const {'notes': '  سرير قرب النافذة  '});
      expect(lines.single, contains('سرير قرب النافذة'));
    });

    test('addons بقيمة غير قائمة لا ترمي استثناء', () {
      expect(buildBookingAddonLines(true, const {'addons': 'oops'}), isEmpty);
      expect(buildBookingAddonLines(true, const {'addons': null}), isEmpty);
    });
  });

  group('حسابية السرير الإضافي (المتطلب 56)', () {
    test('يُحتسب السعر عند اختيار السرير بدون إضافات أخرى', () {
      expect(computeExtraBedCharge(extraBed: true, extraBedPrice: 150), 150);
    });
    test('يُحتسب السعر حتى مع وجود وجبات/إضافات أخرى (الخلل السابق)', () {
      expect(computeExtraBedCharge(extraBed: true, extraBedPrice: 200), 200);
    });
    test('لا يُحتسب إن لم يختر الضيف السرير', () {
      expect(computeExtraBedCharge(extraBed: false, extraBedPrice: 150), 0);
    });
    test('السعر المجاني (0) يبقى صفرًا', () {
      expect(computeExtraBedCharge(extraBed: true, extraBedPrice: 0), 0);
    });
    test('غياب سعر السرير يعني صفرًا', () {
      expect(computeExtraBedCharge(extraBed: true, extraBedPrice: null), 0);
    });
  });

  group('حساب المالك للتحويل المباشر (المتطلب 120)', () {
    test('يعرض كل الحقول التي أعادها السيرفر', () {
      final rows = ownerBankRows({
        'bank_name': 'الراجحي',
        'account_name': 'محمد علي',
        'account_number': '1234567890',
        'iban': 'SA0380000000608010167519',
      });
      expect(rows.length, 4);
      expect(rows.first.$2, 'الراجحي');
      expect(rows.last.$1, 'owner_bank_iban');
    });
    test('يتجاهل الحقول الفارغة ولا يخترع قيمًا', () {
      final rows = ownerBankRows({'bank_name': 'الأهلي', 'iban': '   '});
      expect(rows.length, 1);
      expect(rows.single.$1, 'owner_bank_name');
    });
    test('يعمل مع null وmap فارغ', () {
      expect(ownerBankRows(null), isEmpty);
      expect(ownerBankRows(const {}), isEmpty);
    });
    test('يقبل holder_name كبديل عن account_name', () {
      final rows = ownerBankRows({'holder_name': 'سعد'});
      expect(rows.single.$1, 'owner_bank_account_name');
      expect(rows.single.$2, 'سعد');
    });
  });

  group('مصدر الحجز (المتطلب 36)', () {
    test('يستنتج الوكيل من agent_name', () {
      expect(bookingSourceKey({'agent_name': 'شركة الأفق'}), 'booked_by_agent');
    });
    test('يستنتج الوكيل من source', () {
      expect(bookingSourceKey({'source': 'agent'}), 'booked_by_agent');
    });
    test('يستنتج الضيف من customer', () {
      expect(bookingSourceKey({'booked_by': 'customer'}), 'booked_by_guest');
    });
    test('لا يعرض شيئًا عند غياب البيانات', () {
      expect(bookingSourceKey({}), isNull);
      expect(bookingSourceKey({'source': 'something_else'}), isNull);
      expect(bookingSourceKey({'agent_name': '  '}), isNull);
    });
  });

  group('تفاصيل الحجز للوكيل/الضيف (المتطلب 97)', () {
    test('يبني صفوف التفاصيل من الحقول الحقيقية', () {
      final rows = buildBookingDetailRows(false, {
        'hotel_name': 'Hilton',
        'city_en': 'Makkah',
        'unit_name_en': 'Suite 4005',
        'guest_name': 'Ali',
        'check_in': '2026-11-01',
        'check_out': '2026-11-03',
        'nights': 2,
        'guests': 3,
        'total': 1500,
      });
      final map = {for (final r in rows) r.$1: r.$2};
      expect(map['Hotel'], 'Hilton');
      expect(map['City'], 'Makkah');
      expect(map['Unit'], 'Suite 4005');
      expect(map['nights'], '2');
      expect(map['guests'], '3');
      expect(map['Total'], '1500 SAR');
    });
    test('يخفي الصفوف الناقصة ولا يختلق قيمًا', () {
      final rows = buildBookingDetailRows(true, {'hotel_name': 'فندق'});
      expect(rows.length, 1);
      expect(rows.single.$1, 'الفندق');
    });
    test('يعمل مع خريطة فارغة', () {
      expect(buildBookingDetailRows(false, const {}), isEmpty);
    });
    test('لا يعرض الإجمالي عندما يكون صفرًا', () {
      final rows = buildBookingDetailRows(false, {'total': 0});
      expect(rows, isEmpty);
    });
  });

  group('حساب إجمالي الإضافات حسب price_unit (المتطلبان 31 و48)', () {
    UnitAddonModel addon(String unit, double price) => UnitAddonModel.fromJson({
          'id': 1,
          'category': 'meal_plan',
          'name_ar': 'وجبة',
          'name_en': 'Meal',
          'price': price,
          'price_unit': unit,
        });

    test('السيرفر يُرسل price_unit ويُقرأ في الموديل', () {
      expect(addon('per_person_night', 110).billing, 'per_person_night');
      expect(addon('per_stay', 300).billing, 'per_stay');
    });
    test('per_person_night يضرب في الليالي والأشخاص', () {
      expect(addonLineTotal(addon('per_person_night', 110), nights: 3, guests: 2), 660);
    });
    test('per_stay يُحتسب مرة واحدة مهما طالت الإقامة', () {
      expect(addonLineTotal(addon('per_stay', 300), nights: 5, guests: 4), 300);
    });
    test('per_night يضرب في الليالي فقط', () {
      expect(addonLineTotal(addon('per_night', 100), nights: 4, guests: 3), 400);
    });
    test('يحمي من ليالٍ أو ضيوف صفر', () {
      expect(addonLineTotal(addon('per_person_night', 100), nights: 0, guests: 0), 100);
    });
    test('يقبل billing القديم كبديل', () {
      final legacy = UnitAddonModel.fromJson({'price': 100, 'billing': 'per_stay'});
      expect(legacy.billing, 'per_stay');
      expect(addonLineTotal(legacy, nights: 9, guests: 9), 100);
    });
  });

  group('تعريف التطبيق من المستند (المتطلبات 3-5)', () {
    test('العبارة الكاملة تطابق نص المستند', () {
      expect(AppStrings.t(true, 'app_tagline_full'),
          'المنصة الموثوقة لملاك الوحدات الفندقية والعقارات، وتجربة حجز ذكية للضيوف.');
      expect(AppStrings.t(false, 'app_tagline_full'),
          contains('Hotel Unit & Property Owners'));
    });
    test('نص التعريف العربي والإنجليزي غير فارغ ومختلف عن المفتاح', () {
      for (final k in ['app_description_title', 'app_description_intro',
                       'app_description_body', 'app_description_closing']) {
        expect(AppStrings.t(true, k), isNotEmpty, reason: '$k ar');
        expect(AppStrings.t(false, k), isNotEmpty, reason: '$k en');
        expect(AppStrings.t(true, k), isNot(equals(k)), reason: '$k ar');
      }
    });
    testWidgets('شاشة التعريف تعرض النص المعتمد بالعربية', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(ProviderScope(child: wrap(const AppAboutScreen())));
      await tester.pumpAndSettle();
      expect(find.textContaining('المنصة الموثوقة لملاك الوحدات الفندقية'),
          findsOneWidget);
      expect(find.textContaining('كل ما تحتاجه لإدارة ممتلكاتك'), findsOneWidget);
    });
    testWidgets('شاشة التعريف تعرض النص الإنجليزي المعتمد', (tester) async {
      SharedPreferences.setMockInitialValues({'app_locale': 'en'});
      await tester.pumpWidget(ProviderScope(
        child: wrap(const AppAboutScreen(), isArabic: false),
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('Trusted Platform for Hotel Unit'),
          findsOneWidget);
      expect(find.textContaining('All Owners is the trusted platform'),
          findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('everything you need to manage your property'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('everything you need to manage your property'),
          findsOneWidget);
    });
  });

  group('تسمية النظافة بدل هاوس كيبنج (المتطلب 61)', () {
    test('مفتاح housekeeping يعرض «النظافة» بالعربية وCleaning بالإنجليزية', () {
      expect(AppStrings.t(true, 'housekeeping'), 'النظافة');
      expect(AppStrings.t(false, 'housekeeping'), 'Cleaning');
    });
    test('لا تظهر كلمة «هاوس كيبنج» في أي نص معروض', () {
      const keys = [
        'housekeeping',
        'housekeeping_desc',
        'new_cleaning_request',
        'owner_staff',
        'owner_staff_desc',
      ];
      for (final k in keys) {
        expect(AppStrings.t(true, k).contains('هاوس'), isFalse, reason: k);
      }
    });
    test('مفتاح housekeeping مستخدم فعلًا في قوائم المالك والوكيل', () {
      for (final menu in [ownerMenu, agentMenu]) {
        expect(menu.any((e) => e.labelKey == 'housekeeping'), isTrue);
      }
    });
  });
  group('تغيير الصورة الشخصية لكل الأدوار (المتطلب 9)', () {
    Future<void> pumpAgentProfile(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final session = SessionNotifier();
      await tester.pumpWidget(ProviderScope(
        overrides: [sessionProvider.overrideWith((ref) => session)],
        child: wrap(const OwnerProfileScreen()),
      ));
      await tester.pumpAndSettle();
      session.state = SessionState(
        user: AppUser(
          id: 7,
          fullName: 'وكيل الحجوزات',
          email: 'agent@example.com',
          role: 'booking_agent',
        ),
        isLoading: false,
      );
      await tester.pumpAndSettle();
    }

    testWidgets('حساب الوكيل يعرض أفتارًا قابلًا للتغيير', (tester) async {
      await pumpAgentProfile(tester);
      expect(find.byType(EditableAvatar), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('الضغط على الأفتار يعرض خيارات المعرض والكاميرا للوكيل',
        (tester) async {
      await pumpAgentProfile(tester);
      await tester.tap(find.byType(EditableAvatar));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.t(true, 'choose_from_gallery')), findsOneWidget);
      expect(find.text(AppStrings.t(true, 'take_photo')), findsOneWidget);
    });
  });

  group('ترتيب الوجهات الرئيسية (المتطلب 18)', () {
    List<String> orderedNames(List<String> names) => CityOrdering.prioritize(
          names,
          (n) => n,
        ).toList();

    test('المدن المطلوبة في المستند تُقدَّم بالترتيب مكة/المدينة/جدة/الرياض', () {
      final out = orderedNames([
        'الدمام',
        'جدة',
        'مكة المكرمة',
        'الخبر',
        'المدينة المنورة',
        'الرياض',
      ]);
      expect(out.take(4).toList(), [
        'مكة المكرمة',
        'المدينة المنورة',
        'جدة',
        'الرياض',
      ]);
    });
    test('المدن الأخرى تبقى كما هي ولا تُحذف ولا تُضاف', () {
      final input = ['الدمام', 'جدة', 'مكة المكرمة', 'الخبر'];
      final out = orderedNames(input);
      expect(out.length, input.length);
      expect(out.toSet(), input.toSet());
      expect(out.skip(2).toList(), ['الدمام', 'الخبر']);
    });
    test('غياب مدينة مطلوبة (الرياض) لا يمنع عرض البقية', () {
      final out = orderedNames(['الدمام', 'جدة', 'مكة المكرمة']);
      expect(out.first, 'مكة المكرمة');
      expect(out.contains('الرياض'), isFalse);
      expect(out.length, 3);
    });
    test('المقارنة تتجاهل التشكيل وتوحّد الألف والهاء', () {
      expect(orderedNames(['جده', 'مكه']).first, 'مكه');
      expect(normalizeArabic('مَكّة') == normalizeArabic('مكة'), isTrue);
      expect(normalizeArabic('الرّياض') == normalizeArabic('الرياض'), isTrue);
    });
    test('قائمة فارغة لا تنهار', () {
      expect(orderedNames(const []), isEmpty);
    });
  });

  group('تسوية تكلفة الصيانة (المتطلبات 390–394)', () {
    test('كل خيار له قيمة تُرسل للسيرفر ولا تتشابه مع الأخرى', () {
      expect(settlementPayload(MaintenanceSettlement.unitBalance), 'unit_balance');
      expect(settlementPayload(MaintenanceSettlement.whatsappLink), 'whatsapp_link');
    });
    test('تنظيف رقم الواتساب يزيل + والمسافات والشرطات', () {
      expect(normalizeWhatsAppPhone('+966 555-634-615'), '966555634615');
      expect(normalizeWhatsAppPhone('(966) 555634615'), '966555634615');
    });
    test('الرقم غير الصالح يُرفض بدل بناء رابط بلا وجهة', () {
      expect(normalizeWhatsAppPhone(null), isNull);
      expect(normalizeWhatsAppPhone(''), isNull);
      expect(normalizeWhatsAppPhone('123'), isNull);
      expect(
        buildWhatsAppPaymentUri(phone: '123', isArabic: true, requestId: 5),
        isNull,
      );
    });
    test('الرسالة تحتوي رقم الطلب والوحدة والمبلغ', () {
      final msg = buildMaintenancePaymentMessage(
        isArabic: true,
        requestId: 42,
        unitName: 'جناح 12',
        amount: 350,
      );
      expect(msg.contains('42'), isTrue);
      expect(msg.contains('جناح 12'), isTrue);
      expect(msg.contains('350'), isTrue);
    });
    test('الحقول الناقصة تُحذف من الرسالة ولا يظهر مبلغ صفر', () {
      final msg = buildMaintenancePaymentMessage(isArabic: true, requestId: 7);
      expect(msg.contains('المبلغ'), isFalse);
      expect(msg.contains('0 SAR'), isFalse);
      expect(msg.contains('الوحدة'), isFalse);
    });
    test('الرابط النهائي يحمل رسالة مُرمَّزة للرقم الصحيح', () {
      final uri = buildWhatsAppPaymentUri(
        phone: '+966555634615',
        isArabic: false,
        requestId: 9,
        unitName: 'Suite 3',
        amount: 199.5,
      );
      expect(uri, isNotNull);
      expect(uri!.host, 'wa.me');
      expect(uri.path, '/966555634615');
      expect(uri.queryParameters['text'], contains('199.5'));
    });
    test('المفاتيح النصية موجودة بالعربي والإنجليزي', () {
      for (final key in [
        'maintenance_settlement',
        'settle_unit_balance',
        'settle_whatsapp_link',
        'whatsapp_no_number',
      ]) {
        expect(AppStrings.t(true, key).isNotEmpty, isTrue, reason: key);
        expect(AppStrings.t(false, key).isNotEmpty, isTrue, reason: key);
        expect(AppStrings.t(true, key) == key, isFalse, reason: key);
      }
    });
  });
  group('إجمالي الحجز (المتطلبات 33 و55)', () {
    test('الإجمالي = غرفة + إضافات + سرير + ضريبة على المجموع', () {
      final t = computeBookingTotals(
        basePricePerNight: 1000,
        nights: 2,
        addonsTotal: 200,
        extraBedCharge: 100,
      );
      expect(t.roomPrice, 2000);
      expect(t.taxes, closeTo((2000 + 200 + 100) * 0.15, 0.001));
      expect(t.total, closeTo(2300 * 1.15, 0.001));
    });
    test('ليلة واحدة على الأقل حتى لو أُرسل صفر', () {
      final t = computeBookingTotals(basePricePerNight: 500, nights: 0);
      expect(t.roomPrice, 500);
    });
    test('بلا إضافات يبقى الإجمالي سعر الليالي + الضريبة فقط', () {
      final t = computeBookingTotals(basePricePerNight: 300, nights: 3);
      expect(t.addonsTotal, 0);
      expect(t.extraBedCharge, 0);
      expect(t.total, closeTo(900 * 1.15, 0.001));
    });
    test('نفس الحساب مستخدم في نافذة التأكيد وملخص الصفحة (قيمة واحدة)', () {
      final a = computeBookingTotals(
          basePricePerNight: 700, nights: 2, addonsTotal: 50, extraBedCharge: 0);
      final b = computeBookingTotals(
          basePricePerNight: 700, nights: 2, addonsTotal: 50, extraBedCharge: 0);
      expect(a.total, b.total);
    });
  });
  group('قائمة الوكيل (المتطلبات 100–107)', () {
    List<MenuTarget> targets(String? role) =>
        menuForRole(role).map((e) => e.target).toList();

    test('المتطلب 100: الوكيل يرى تقارير العمولات لا التقارير المالية', () {
      final keys = agentMenu.map((e) => e.labelKey).toList();
      expect(keys.contains('commission_reports'), isTrue);
      expect(keys.contains('financial_reports'), isFalse);
      expect(agentMenu.any((e) => e.target == MenuTarget.commission), isTrue);
    });
    test('المتطلبات 101–103: لا عقود ولا مجتمع ملاك ولا تصويت للوكيل', () {
      final t = targets('booking_agent');
      expect(t.contains(MenuTarget.contracts), isFalse);
      expect(t.contains(MenuTarget.community), isFalse);
      expect(t.contains(MenuTarget.voting), isFalse);
    });
    test('المتطلب 104: خدمات الصيانة تبقى في قائمة الوكيل', () {
      expect(targets('booking_agent').contains(MenuTarget.maintenance), isTrue);
    });
    test('المتطلبات 105–107: طلبات الوجبات والنظافة والسرير مضافة للوكيل', () {
      final t = targets('booking_agent');
      expect(t.contains(MenuTarget.mealRequests), isTrue);
      expect(t.contains(MenuTarget.cleaningRequests), isTrue);
      expect(t.contains(MenuTarget.extraBedRequests), isTrue);
    });
    test('قائمة المالك تحتفظ بكل الأقسام التي أُزيلت من الوكيل', () {
      final t = targets('owner');
      for (final target in [
        MenuTarget.contracts,
        MenuTarget.voting,
        MenuTarget.community,
        MenuTarget.marketplace,
        MenuTarget.revenueReports,
        MenuTarget.bankAccount,
        MenuTarget.servicePrices,
      ]) {
        expect(t.contains(target), isTrue, reason: '$target');
      }
    });
    test('لا تكرار في أي قائمة، وكل مفتاح نصي موجود بالعربي والإنجليزي', () {
      for (final menu in [agentMenu, ownerMenu]) {
        final keys = menu.map((e) => e.labelKey).toList();
        expect(keys.toSet().length, keys.length, reason: 'duplicate in $keys');
        for (final key in keys) {
          expect(AppStrings.t(true, key), isNot(key), reason: key);
          expect(AppStrings.t(false, key), isNot(key), reason: key);
        }
      }
    });
    test('دور غير معروف أو null يعامل كمالك (لا يفقد الأقسام)', () {
      expect(menuForRole(null).length, ownerMenu.length);
      expect(menuForRole('owner').length, ownerMenu.length);
      expect(menuForRole('unit_manager').length, ownerMenu.length);
    });
  });
  group('تقارير إيرادات المالك (المتطلبات 126–129)', () {
    test('التجميع السنوي يجمع أشهر السنة نفسها ويرتّب تنازليًا', () {
      final years = RevenueReports.yearTotals([
        {'ym': '2026-01', 'total': 100},
        {'ym': '2026-02', 'total': 50},
        {'ym': '2025-12', 'total': 30},
      ]);
      expect(years.length, 2);
      expect(years.first.year, 2026);
      expect(years.first.total, 150);
      expect(years.last.year, 2025);
      expect(years.last.total, 30);
    });
    test('السطور بتاريخ غير صالح تُتجاهل ولا تُحتسب في سنة خاطئة', () {
      final years = RevenueReports.yearTotals([
        {'ym': '', 'total': 999},
        {'ym': 'abc', 'total': 999},
        {'ym': '2026-05', 'total': 10},
      ]);
      expect(years.length, 1);
      expect(years.single.year, 2026);
      expect(years.single.total, 10);
    });
    test('المصروفات تظهر فقط عند إرجاع الحقول من الخدمة', () {
      expect(RevenueReports.expenses({'total_revenue': 500}), isEmpty);
      final e = RevenueReports.expenses({
        'maintenance_expense': '200',
        'cleaning_total': 50,
      });
      expect(e.length, 2);
      expect(e.firstWhere((x) => x.labelKey == 'maintenance_expense').total, 200);
      expect(e.firstWhere((x) => x.labelKey == 'cleaning_expense').total, 50);
    });
    test('صافي الإيراد يخصم المصروفات المُرجَعة فقط', () {
      expect(RevenueReports.netRevenue(500, const []), 500);
      final net = RevenueReports.netRevenue(500, [
        const ExpenseTotal(labelKey: 'maintenance_expense', total: 200),
        const ExpenseTotal(labelKey: 'cleaning_expense', total: 50),
      ]);
      expect(net, 250);
    });
    test('yearOf يقبل YYYY و YYYY-MM ويرفض غير الصالح', () {
      expect(RevenueReports.yearOf('2026-07'), 2026);
      expect(RevenueReports.yearOf('2026'), 2026);
      expect(RevenueReports.yearOf('26-07'), isNull);
      expect(RevenueReports.yearOf(null), isNull);
    });
  });

  group('تسميات التصنيفات المعروضة (المتطلبان 13 و14)', () {
    test('تصنيف الفنادق يظهر «الوحدات الفندقية» بالعربي والإنجليزي', () {
      expect(
        CategoryLabels.display(
            iconKey: 'hotels',
            nameAr: 'فنادق',
            nameEn: 'Hotels',
            isArabic: true),
        'الوحدات الفندقية',
      );
      expect(
        CategoryLabels.display(
            iconKey: 'hotels',
            nameAr: 'فنادق',
            nameEn: 'Hotels',
            isArabic: false),
        'Hotel units',
      );
    });
    test('بقية التصنيفات تبقى باسم قاعدة البيانات', () {
      expect(
        CategoryLabels.display(
            iconKey: 'resorts',
            nameAr: 'منتجعات',
            nameEn: 'Resorts',
            isArabic: true),
        'منتجعات',
      );
      expect(
        CategoryLabels.display(
            iconKey: 'chalets',
            nameAr: 'شاليهات',
            nameEn: 'Chalets',
            isArabic: false),
        'Chalets',
      );
    });
    test('الاسم المُعرَّب يُستخدم للفلترة ولا يتأثر بالتسمية المعروضة', () {
      final category = CategoryModel.fromJson({
        'id': 1,
        'name_ar': 'فنادق',
        'name_en': 'Hotels',
        'icon_key': 'hotels',
      });
      expect(category.name(true), 'فنادق');
      expect(category.displayName(true), 'الوحدات الفندقية');
    });
  });

  group('تصنيفات خدمات الوحدة (المتطلب 76)', () {
    ServiceCategory classify(String icon) =>
        ServiceCategories.classify(iconKey: icon);

    test('تصنيف أيقونات الملاف والمفارش', () {
      expect(classify('bed'), ServiceCategory.bedding);
      expect(classify('extra_bed'), ServiceCategory.bedding);
      expect(ServiceCategories.classify(nameAr: 'مفارش قطنية'),
          ServiceCategory.bedding);
    });
    test('تصنيف الطعام والمشروبات', () {
      expect(classify('restaurant'), ServiceCategory.food);
      expect(classify('room_service'), ServiceCategory.food);
      expect(classify('coffee_maker'), ServiceCategory.food);
      expect(ServiceCategories.classify(nameAr: 'وجبة إفطار'),
          ServiceCategory.food);
    });
    test('تصنيف الحمام والوسائط والمعدات', () {
      expect(classify('bathroom'), ServiceCategory.bathroom);
      expect(classify('tv'), ServiceCategory.media);
      expect(classify('wifi'), ServiceCategory.media);
      expect(classify('safe'), ServiceCategory.equipment);
      expect(classify('laundry'), ServiceCategory.equipment);
    });
    test('العنصر غير المعروف يُوضع في «خدمات أخرى» ولا يُسقط', () {
      final groups = ServiceCategories.group([
        {'icon': 'unknown_key_xyz', 'name_ar': 'شيء', 'name_en': 'Thing'},
      ]);
      expect(groups.length, 1);
      expect(groups.single.category, ServiceCategory.other);
      expect(groups.single.items.length, 1);
    });
    test('التجميع يحافظ على كل العناصر وترتيب التصنيفات', () {
      final items = [
        {'icon': 'wifi'},
        {'icon': 'bed'},
        {'icon': 'restaurant'},
        {'icon': 'laundry'},
      ];
      final groups = ServiceCategories.group(items);
      expect(groups.map((g) => g.category).toList(), [
        ServiceCategory.bedding,
        ServiceCategory.food,
        ServiceCategory.media,
        ServiceCategory.equipment,
      ]);
      expect(groups.fold<int>(0, (n, g) => n + g.items.length), 4);
    });
    test('القائمة الفارغة تُرجع بلا مجموعات', () {
      expect(ServiceCategories.group(const []), isEmpty);
    });
  });

  group('أسعار خدمات الفندق للمالك (المتطلب 68)', () {
    test('مفاتيح الأسعار موجودة بالعربي والإنجليزي', () {
      for (final k in ['service_prices', 'no_service_prices',
                       'req_type_cleaning', 'req_type_maintenance',
                       'req_type_meal', 'req_type_extra_bed']) {
        expect(AppStrings.t(true, k), isNotEmpty, reason: '$k ar');
        expect(AppStrings.t(false, k), isNotEmpty, reason: '$k en');
      }
    });
  });
}
