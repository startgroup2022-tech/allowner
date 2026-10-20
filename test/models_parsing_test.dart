import 'package:allowners/models/amenity_model.dart';
import 'package:allowners/models/app_user.dart';
import 'package:allowners/models/category_model.dart';
import 'package:allowners/models/city_model.dart';
import 'package:allowners/models/hotel_model.dart';
import 'package:allowners/models/owner_hotel_summary.dart';
import 'package:allowners/models/unit_model.dart';
import 'package:allowners/utils/safe_parse.dart';
import 'package:flutter_test/flutter_test.dart';

/// اختبارات التحويل الآمن — تحمي من الانهيارات التي كانت تحدث عند تغيّر شكل
/// استجابة الـ API (نص بدل رقم، حقل مفقود، مصفوفة فارغة).
void main() {
  group('safe_parse', () {
    test('asInt يتعامل مع النص والرقم والقيم المفقودة', () {
      expect(asInt(5), 5);
      expect(asInt('5'), 5);
      expect(asInt('5.9'), 5);
      expect(asInt(null), 0);
      expect(asInt('غير رقمي'), 0);
      expect(asInt('', 7), 7);
      expect(asInt(true), 1);
    });

    test('asDouble يتعامل مع النص العشري (أعمدة DECIMAL)', () {
      expect(asDouble('1500.50'), 1500.50);
      expect(asDouble(1500), 1500.0);
      expect(asDouble(null), 0.0);
      expect(asDouble('abc', 1.5), 1.5);
    });

    test('asString/asStringOrNull يفرّقان بين الفارغ والمفقود', () {
      expect(asString('  مرحبا  '), 'مرحبا');
      expect(asString(null), '');
      expect(asStringOrNull(''), isNull);
      expect(asStringOrNull('x'), 'x');
    });

    test('asBool يتعامل مع true/1/"1" و false/0', () {
      expect(asBool(true), isTrue);
      expect(asBool(1), isTrue);
      expect(asBool('1'), isTrue);
      expect(asBool('yes'), isTrue);
      expect(asBool(0), isFalse);
      expect(asBool('false'), isFalse);
      expect(asBool(null, true), isTrue);
    });

    test('asMapList يتجاهل العناصر غير الصالحة ولا يرمي استثناء', () {
      expect(asMapList(null), isEmpty);
      expect(asMapList('not a list'), isEmpty);
      expect(asMapList([1, 'x', null]), isEmpty);
      final list = asMapList([
        {'id': 1},
        'bad',
        {'id': 2},
      ]);
      expect(list.length, 2);
      expect(list[1]['id'], 2);
    });

    test('asStringList يتجاهل الفوارغ', () {
      expect(asStringList(['a', '', null, 'b']), ['a', 'b']);
      expect(asStringList(null), isEmpty);
    });

    test('asIntOrNull/asDoubleOrNull يفرّقان بين صفر ومفقود', () {
      expect(asIntOrNull(0), 0);
      expect(asIntOrNull(''), isNull);
      expect(asIntOrNull(null), isNull);
      expect(asDoubleOrNull('0'), 0.0);
      expect(asDoubleOrNull('abc'), isNull);
    });

    test('localized يفضّل اللغة المطلوبة ثم يرجع للأخرى', () {
      final json = {'name_ar': 'فندق', 'name_en': ''};
      expect(localized(json, 'name', true), 'فندق');
      expect(localized(json, 'name', false), 'فندق');
    });
  });

  group('HotelModel.fromJson — استجابة حقيقية من hotels/list.php', () {
    test('يحوّل الصف الكامل بشكل صحيح', () {
      final hotel = HotelModel.fromJson({
        'id': 4,
        'name': 'فيرمونت مكة',
        'city_ar': 'مكة المكرمة',
        'city_en': 'Makkah',
        'type_ar': 'فندق',
        'type_en': 'Hotel',
        'description_ar': 'وصف حقيقي',
        'description_en': '',
        'address': 'مكة المكرمة برج الساعة',
        'stars': 5,
        'rating': 0,
        'reviews_count': 0,
        'price_per_night': 1500,
        'free_cancellation': 1,
        'breakfast_included': 0,
        'cover_image': 'https://all-owner.online/x.jpg',
        'is_featured': 1,
      });

      expect(hotel.id, '4');
      expect(hotel.name, 'فيرمونت مكة');
      expect(hotel.city(true), 'مكة المكرمة');
      expect(hotel.city(false), 'Makkah');
      expect(hotel.stars, 5);
      expect(hotel.pricePerNight, 1500.0);
      expect(hotel.freeCancellation, isTrue);
      expect(hotel.breakfastIncluded, isFalse);
      expect(hotel.isFeatured, isTrue);
      expect(hotel.description(true), 'وصف حقيقي');
      // لا وصف إنجليزي → يرجع للعربي بدل نص مُصاغ آليًا
      expect(hotel.description(false), 'وصف حقيقي');
      expect(hotel.galleryUrls, ['https://all-owner.online/x.jpg']);
    });

    test('لا ينهار عند غياب الحقول الاختيارية', () {
      final hotel = HotelModel.fromJson({'id': 1, 'name': 'X'});
      expect(hotel.city(true), '');
      expect(hotel.pricePerNight, 0.0);
      expect(hotel.stars, 0);
      expect(hotel.description(true), '');
      expect(hotel.galleryUrls, isEmpty);
    });

    test('يتعامل مع السعر كنص (DECIMAL من PDO)', () {
      final hotel = HotelModel.fromJson({
        'id': '7',
        'name': 'H',
        'price_per_night': '2300.75',
      });
      expect(hotel.pricePerNight, 2300.75);
    });

    test('copyWith يحافظ على باقي الحقول', () {
      final hotel =
          HotelModel.fromJson({'id': 1, 'name': 'A', 'price_per_night': 100});
      final updated = hotel.copyWith(isFavorite: true);
      expect(updated.isFavorite, isTrue);
      expect(updated.name, 'A');
      expect(updated.pricePerNight, 100.0);
    });
  });

  group('UnitModel.fromJson — استجابات browse و detail', () {
    test('صف قائمة browse.php', () {
      final unit = UnitModel.fromJson({
        'id': 13,
        'hotel_id': 2,
        'hotel_name': 'فندق فيرمونت مكه',
        'name_ar': '4005',
        'name_en': '4005',
        'unit_type_ar': 'جناح عائلي',
        'unit_type_en': null,
        'capacity': 2,
        'bed_count': 1,
        'price_per_night': 1500,
        'cover_image': 'https://all-owner.online/u.jpg',
        'city_ar': 'مكة المكرمة',
        'city_en': 'Makkah',
      });

      expect(unit.id, 13);
      expect(unit.hotelId, 2);
      expect(unit.name(true), '4005');
      expect(unit.unitType(true), 'جناح عائلي');
      // unit_type_en فارغ → يرجع للعربي
      expect(unit.unitType(false), 'جناح عائلي');
      expect(unit.capacity, 2);
      expect(unit.pricePerNight, 1500.0);
      expect(unit.images, ['https://all-owner.online/u.jpg']);
    });

    test('تفصيل detail.php مع الإتاحة والإضافات', () {
      final unit = UnitModel.fromJson({
        'id': 13,
        'hotel_id': 2,
        'hotel_name': 'فندق فيرمونت مكه',
        'name_ar': '4005',
        'name_en': '4005',
        'description_ar': 'جناح غرفة وصاله كعبه',
        'capacity': 2,
        'bed_count': 1,
        'price_per_night': 1500,
        'images': ['a.jpg', 'b.jpg'],
        'addons': [
          {
            'id': 1,
            'category': 'meal_plan',
            'name_ar': 'فطور',
            'price': '75.5'
          },
        ],
        'availability': [
          {'date_from': '2026-10-05', 'date_to': '2026-10-31'},
        ],
      });

      expect(unit.images, ['a.jpg', 'b.jpg']);
      expect(unit.coverImage, 'a.jpg');
      expect(unit.addons.single.price, 75.5);
      expect(unit.addons.single.category, 'meal_plan');
      expect(unit.availability.single.isValid, isTrue);
      expect(unit.availability.single.from, DateTime(2026, 10, 5));
    });

    test('لا ينهار عند غياب images/addons/availability', () {
      final unit = UnitModel.fromJson({'id': 1, 'hotel_id': 1});
      expect(unit.images, isEmpty);
      expect(unit.addons, isEmpty);
      expect(unit.availability, isEmpty);
      expect(unit.capacity, 1);
      expect(unit.bedCount, 1);
    });

    test('availability غير صالحة عند غياب التاريخين', () {
      final period =
          UnitAvailabilityModel.fromJson({'date_from': '2026-01-01'});
      expect(period.isValid, isFalse);
    });

    test('unitType يرجع نصًا فارغًا (وليس null) عند غياب النوعين', () {
      final unit = UnitModel.fromJson({'id': 1, 'hotel_id': 1});
      expect(unit.unitType(true), '');
      expect(unit.unitType(false), '');
    });
  });

  group('OwnerHotelSummary.build — قسم فنادق بوحدات ملاك (المتطلب 21–22)', () {
    test('يجمع الوحدات حسب الفندق ويحسب العدد وأقل سعر', () {
      final units = [
        UnitModel.fromJson({
          'id': 13,
          'hotel_id': 2,
          'hotel_name': 'فندق فيرمونت مكه',
          'name_ar': '4005',
          'price_per_night': 1500,
          'city_ar': 'مكة المكرمة',
          'city_en': 'Makkah',
        }),
        UnitModel.fromJson({
          'id': 9,
          'hotel_id': 2,
          'hotel_name': 'فندق فيرمونت مكه',
          'name_ar': 'جناح',
          'price_per_night': 900,
          'city_ar': 'مكة المكرمة',
          'city_en': 'Makkah',
        }),
        UnitModel.fromJson({
          'id': 12,
          'hotel_id': 3,
          'hotel_name': 'فندق العنوان',
          'name_ar': 'غرفة',
          'price_per_night': 1200,
          'city_ar': 'مكة المكرمة',
          'city_en': 'Makkah',
        }),
      ];
      final hotels = [
        HotelModel.fromJson({
          'id': 2,
          'name': 'فندق فيرمونت مكه',
          'city_ar': 'مكة المكرمة',
          'city_en': 'Makkah',
          'rating': 4.8,
          'reviews_count': 12,
          'cover_image': 'https://x/h2.jpg',
        }),
        HotelModel.fromJson({
          'id': 3,
          'name': 'فندق العنوان',
          'city_ar': 'مكة المكرمة',
          'city_en': 'Makkah',
          'cover_image': 'https://x/h3.jpg',
        }),
      ];

      final summaries = OwnerHotelSummary.build(units, hotels);
      expect(summaries.length, 2);

      final first = summaries.first;
      expect(first.hotelId, '2');
      expect(first.unitCount, 2);
      expect(first.minPrice, 900.0);
      expect(first.rating, 4.8);
      expect(first.reviewsCount, 12);
      expect(first.imageUrl, 'https://x/h2.jpg');
      expect(first.hotel, isNotNull);

      final second = summaries[1];
      expect(second.hotelId, '3');
      expect(second.unitCount, 1);
      expect(second.rating, 0);
    });

    test('يرجع لبيانات الوحدة عند غياب بيانات الفندق', () {
      final units = [
        UnitModel.fromJson({
          'id': 13,
          'hotel_id': 2,
          'hotel_name': 'فندق فيرمونت مكه',
          'name_ar': '4005',
          'price_per_night': 1500,
          'cover_image': 'https://x/u.jpg',
          'city_ar': 'مكة المكرمة',
          'city_en': 'Makkah',
        }),
      ];

      final summaries = OwnerHotelSummary.build(units, const []);
      expect(summaries.single.name, 'فندق فيرمونت مكه');
      expect(summaries.single.imageUrl, 'https://x/u.jpg');
      expect(summaries.single.hotel, isNull);
      expect(summaries.single.city(true), 'مكة المكرمة');
    });

    test('قائمة فارغة عند عدم وجود وحدات ملاك', () {
      expect(OwnerHotelSummary.build(const [], const []), isEmpty);
    });
  });

  group('CityModel و CategoryModel', () {
    test('CityModel يحوّل أسماء المدن العربية والإنجليزية', () {
      final city = CityModel.fromJson({
        'id': 3,
        'name_ar': 'مكة المكرمة',
        'name_en': 'Makkah',
        'image_url': 'https://all-owner.online/assets/images/logo.png',
      });
      expect(city.id, 3);
      expect(city.name(true), 'مكة المكرمة');
      expect(city.name(false), 'Makkah');
      expect(city.imageUrl, contains('logo.png'));
    });

    test('CityModel لا ينهار بدون صورة', () {
      final city =
          CityModel.fromJson({'id': 1, 'name_ar': 'جدة', 'name_en': 'Jeddah'});
      expect(city.imageUrl, '');
      expect(city.name(false), 'Jeddah');
    });

    test('CategoryModel يحوّل icon_key و color_hex', () {
      final category = CategoryModel.fromJson({
        'id': 1,
        'name_ar': 'فنادق',
        'name_en': 'Hotels',
        'icon_key': 'hotels',
        'color_hex': '#14151A',
      });
      expect(category.id, 1);
      expect(category.name(true), 'فنادق');
      expect(category.iconKey, 'hotels');
      expect(category.colorHex, '#14151A');
    });
  });

  group('AmenityModel', () {
    test('يحوّل حقل icon من قاعدة البيانات', () {
      final amenity = AmenityModel.fromJson({
        'id': 1,
        'name_ar': 'واي فاي مجاني',
        'name_en': 'Free WiFi',
        'icon': 'wifi',
      });
      expect(amenity.name(true), 'واي فاي مجاني');
      expect(amenity.name(false), 'Free WiFi');
      expect(amenity.iconKey, 'wifi');
    });

    test('يرجع للغة الأخرى عند غياب الترجمة', () {
      final amenity =
          AmenityModel.fromJson({'id': 2, 'name_ar': 'موقف سيارات'});
      expect(amenity.name(false), 'موقف سيارات');
    });
  });

  group('AppUser.fromJson', () {
    test('يحوّل معرّفًا نصيًا', () {
      final user = AppUser.fromJson({
        'id': '42',
        'full_name': 'محمد',
        'email': 'a@b.com',
        'phone': '',
        'role': 'owner',
      });
      expect(user.id, 42);
      expect(user.fullName, 'محمد');
      // الهاتف اختياري — النص الفارغ يصبح null (وليس سلسلة فارغة)
      expect(user.phone, isNull);
      expect(user.role, 'owner');
    });

    test('الدور الافتراضي guest عند الغياب', () {
      final user = AppUser.fromJson({'id': 1, 'full_name': 'x'});
      expect(user.role, 'guest');
    });
  });
}
