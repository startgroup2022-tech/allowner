import 'package:allowners/models/category_model.dart';
import 'package:allowners/models/city_model.dart';
import 'package:allowners/models/hotel_model.dart';
import 'package:allowners/models/unit_model.dart';
import 'package:allowners/services/api_client.dart';
import 'package:allowners/services/catalog_service.dart';
import 'package:allowners/services/content_service.dart';
import 'package:allowners/services/hotel_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// اختبارات تكامل حقيقية ضد الباك إند الحيّ `https://all-owner.online/api`.
///
/// **ليست اختبارات وحدة.** تمرّ عبر `CatalogService` / `HotelService` /
/// `ContentService` الفعلية وشبكة Dio الحقيقية، فتُثبت أن التطبيق يفهم ما
/// يرسله السيرفر فعلًا — لا ما نظنّ أنه يرسله.
///
/// التشغيل:
/// ```
/// flutter test test/integration/live_backend_test.dart --dart-define=RUN_LIVE_TESTS=1
/// ```
/// بدون `RUN_LIVE_TESTS=1` تُتخطّى كل الحالات (skip) حتى لا يعتمد بناء
/// Codemagic على توفر الشبكة. لا نُعلن نجاحًا لم يُنفَّذ.
const bool kRunLive =
    bool.fromEnvironment('RUN_LIVE_TESTS', defaultValue: false);

void main() {
  final live = kRunLive ? test : _skipAll;

  setUp(() {
    // العميل المركزي يقرأ التوكن من SharedPreferences في كل طلب؛ في بيئة
    // الاختبار لا توجد قناة أصلية، فنُهيّئ قيمًا وهمية فارغة حتى يعمل الطلب
    // بلا توثيق (وهو ما نريد لمسارات القراءة العامة).
    SharedPreferences.setMockInitialValues({});
  });

  group('باك إند حيّ — الكتالوج (المتطلبات 12، 13، 18)', () {
    live('cities/list.php يُرجع مدنًا حقيقية عبر CityModel', () async {
      final cities = await CatalogService().listCities();
      expect(cities, isNotEmpty, reason: 'قاعدة البيانات فيها مدن فعلية');
      for (final CityModel c in cities) {
        expect(c.id, greaterThan(0));
        expect(c.name(true), isNotEmpty, reason: 'كل مدينة لها اسم عربي');
      }
    });

    live('categories/list.php يُرجع تصنيفات حقيقية عبر CategoryModel',
        () async {
      final cats = await CatalogService().listCategories();
      expect(cats, isNotEmpty);
      for (final CategoryModel c in cats) {
        expect(c.id, greaterThan(0));
        expect(c.iconKey, isNotEmpty);
      }
    });

    live('hotels/list.php يُرجع فنادق ويُحلَّل كل حقل بلا استثناء', () async {
      final hotels = await HotelService().listHotels();
      expect(hotels, isNotEmpty, reason: 'الصفحة الرئيسية تعتمد على هذا');
      for (final HotelModel h in hotels) {
        expect(int.parse(h.id), greaterThan(0));
        expect(h.name, isNotEmpty);
        // السعر والنجوم قد تكون صفرًا لكن يجب ألا تفشل القراءة
        expect(h.stars, greaterThanOrEqualTo(0));
        expect(h.pricePerNight, greaterThanOrEqualTo(0));
      }
    });

    live('featured=1 يعمل ويُرجع مجموعة فرعية', () async {
      final all = await HotelService().listHotels();
      final feat = await HotelService().featuredHotels();
      expect(feat.length, lessThanOrEqualTo(all.length));
    });
  });

  group('باك إند حيّ — البحث والتصفية (المتطلبات 19، 24–30)', () {
    live('بحث الوحدات بالمدينة يُرجع نتائج مطابقة فعلية', () async {
      final cities = await CatalogService().listCities();
      final target = cities.first;
      final units = await HotelService().browseUnits(city: target.nameAr);
      // قد لا تكون لكل مدينة وحدات، لكن كل نتيجة يجب أن تكون وحدة صحيحة
      for (final UnitModel u in units) {
        expect(u.id, greaterThan(0));
        expect(u.name(true), isNotEmpty);
      }
    });

    live('بحث بالاسم (q) يعمل على units/browse.php', () async {
      final units = await HotelService().searchUnits(query: 'ف');
      for (final UnitModel u in units) {
        expect(u.id, greaterThan(0));
      }
    });

    live('مكة المكرمة: وحدات مطابقة إن وُجدت في قاعدة البيانات', () async {
      final units = await HotelService().browseUnits(city: 'مكة المكرمة');
      // نُثبت أن الطلب لا يفشل وأن كل نتيجة صحيحة. لا ندّعي وجود عدد معيّن.
      for (final UnitModel u in units) {
        expect(u.id, greaterThan(0));
      }
    });

    live('نتيجة فارغة لا تُحوَّل إلى نجاح كاذب', () async {
      final units =
          await HotelService().searchUnits(query: 'zzz-no-such-unit-zzz');
      expect(units, isEmpty);
    });
  });

  group('باك إند حيّ — التفاصيل (المتطلبات 40–50)', () {
    live('hotels/detail.php: gallery و amenities في الجذر لا داخل hotel',
        () async {
      final hotels = await HotelService().listHotels();
      expect(hotels, isNotEmpty);
      final detail = await HotelService().getHotelDetail('${hotels.first.id}');
      expect(detail.hotel.id, hotels.first.id);
      expect(detail.hotel.name, isNotEmpty);
      // amenities قد تكون فارغة لكن يجب أن تُقرأ كقائمة لا أن تفشل
      expect(detail.amenities, isA<List>());
    });

    live('units/detail.php يُحلَّل عبر UnitModel بلا استثناء', () async {
      final units = await HotelService().browseUnits();
      expect(units, isNotEmpty, reason: 'نحتاج وحدة واحدة على الأقل للاختبار');
      final detail = await HotelService().getUnitDetail(units.first.id);
      expect(detail.id, units.first.id);
      expect(detail.name(true), isNotEmpty);
    });

    live('وحدة غير موجودة تُرفع استثناءً واضحًا لا نتيجة فارغة', () async {
      await expectLater(
        HotelService().getUnitDetail(99999999),
        throwsA(isA<ApiException>()),
      );
    });

    live('hotel → units: getUnits(hotelId) يُرجع وحدات الفندق المطابقة',
        () async {
      final hotels = await HotelService().listHotels();
      expect(hotels, isNotEmpty);
      // نبحث عن فندق له وحدات فعلية عبر units/browse.php?hotel_id=
      HotelModel? withUnits;
      for (final h in hotels) {
        final units = await HotelService().getUnits(h.id);
        if (units.isNotEmpty) {
          withUnits = h;
          // كل وحدة تُنسب للفندق الصحيح
          for (final u in units) {
            expect(u.hotelId, int.parse(h.id),
                reason: 'الوحدة ${u.id} تنتمي لفندق آخر');
          }
          break;
        }
      }
      expect(withUnits, isNotNull,
          reason: 'يجب وجود فندق واحد على الأقل له وحدات في قاعدة البيانات');
    });

    live('units/addons.php يُرجع إضافات قابلة للتحليل عبر UnitAddonModel',
        () async {
      final units = await HotelService().browseUnits();
      expect(units, isNotEmpty);
      final addons = await HotelService().getUnitAddons(units.first.id);
      // قد لا توجد إضافات لهذه الوحدة، لكن القراءة يجب ألا تفشل
      for (final a in addons) {
        expect(a.id, greaterThan(0));
        expect(a.price, greaterThanOrEqualTo(0));
      }
    });
  });

  group('باك إند حيّ — الإعدادات (المتطلبات 8، 34)', () {
    live('content/settings.php يُرجع بيانات التواصل الحقيقية', () async {
      final settings = await ContentService().getSettings();
      expect(settings, isNotNull);
      expect(settings['contact_email'] ?? settings['email'], isNotNull);
    });

    live('payment_checkout_url: إن وُجد فيجب أن يكون https مطلقًا', () async {
      final settings = await ContentService().getSettings();
      final url = settings['payment_checkout_url'];
      // نُثبت الوضع الحقيقي: إمّا غائب (فالتطبيق يقول "غير مُفعَّل")
      // أو موجود فيجب أن يكون https مطلقًا
      if (url != null && url.toString().isNotEmpty) {
        final uri = Uri.parse(url.toString());
        expect(uri.isAbsolute, isTrue, reason: 'رابط الدفع يجب أن يكون مطلقًا');
        expect(uri.scheme, 'https', reason: 'لا دفع على http');
      }
    });
  });

  group('باك إند حيّ — معالجة الأخطاء (المتطلبات 100–110)', () {
    live('حجز بلا توثيق يُرفع خطأً لا نجاحًا', () async {
      await expectLater(
        HotelService().createBooking(
          hotelId: '1',
          checkIn: DateTime.now().add(const Duration(days: 30)),
          checkOut: DateTime.now().add(const Duration(days: 32)),
          guests: 1,
          paymentMethod: 'at_hotel',
        ),
        throwsA(isA<ApiException>()),
      );
    });
  });
}

/// يستبدل `test` بـ `skip` عندما لا يكون الوضع الحيّ مُفعَّلًا.
void _skipAll(String description, dynamic Function() body) {
  test(description, body, skip: 'يحتاج RUN_LIVE_TESTS=1 واتصالًا بالباك إند');
}
