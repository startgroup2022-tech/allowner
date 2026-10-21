import '../utils/safe_parse.dart';

/// وحدة سكنية (جناح / غرفة / شقة) — موديل موحّد يغطي شكلين من استجابات الـ API:
///
/// 1. القائمة المبسّطة من `units/browse.php` و `units/list.php`:
///    id, hotel_id, hotel_name, name_ar/en, unit_type_ar/en, capacity,
///    bed_count, price_per_night, cover_image, city_ar/en
/// 2. التفصيل الكامل من `units/detail.php`:
///    يضيف description_ar/en, images, addons, availability, owner_bank,
///    price_per_week, price_per_month
///
/// كل الحقول الرقمية تُقرأ عبر `asInt`/`asDouble` لأن السيرفر يعيد أحيانًا
/// أرقامًا وأحيانًا نصوصًا لنفس العمود.
class UnitModel {
  final int id;
  final int hotelId;
  final String hotelName;
  final String nameAr;
  final String nameEn;
  final String? unitTypeAr;
  final String? unitTypeEn;
  final String? unitNumber;
  final String? descriptionAr;
  final String? descriptionEn;
  final String cityAr;
  final String cityEn;
  final int capacity;
  final int bedCount;
  final double pricePerNight;
  final double? pricePerWeek;
  final double? pricePerMonth;
  final String coverImage;
  final List<String> images;
  final List<UnitAddonModel> addons;
  final List<UnitAvailabilityModel> availability;

  /// مرافق الوحدة. الـ API الحالي لا يعيد هذا الحقل في `units/detail.php`،
  /// لكن الحقل موجود لأن بعض إصدارات الباكند قد تعيده — الشاشة تتعامل مع
  /// القائمة الفارغة بوضوح ولا تخترع مرافق.
  final List<Map<String, dynamic>> facilities;

  /// بيانات الحساب البنكي لمالك الوحدة — من `owner_bank` في `units/detail.php`.
  /// تُستخدم لعرض حساب المالك الصحيح عند اختيار «التحويل إلى المالك» (المتطلب 120).
  /// قد تكون null إن لم يُسجّل المالك بياناته بعد.
  final Map<String, dynamic>? ownerBank;

  const UnitModel({
    required this.id,
    required this.hotelId,
    this.hotelName = '',
    this.nameAr = '',
    this.nameEn = '',
    this.unitTypeAr,
    this.unitTypeEn,
    this.unitNumber,
    this.descriptionAr,
    this.descriptionEn,
    this.cityAr = '',
    this.cityEn = '',
    this.capacity = 1,
    this.bedCount = 1,
    this.pricePerNight = 0,
    this.pricePerWeek,
    this.pricePerMonth,
    this.coverImage = '',
    this.images = const [],
    this.addons = const [],
    this.availability = const [],
    this.facilities = const [],
    this.ownerBank,
  });

  /// يبني الموديل من أي من شكلَي الاستجابة (قائمة أو تفصيل).
  factory UnitModel.fromJson(Map<String, dynamic> json) {
    final images = asStringList(json['images']);
    final cover = asStringOrNull(json['cover_image']) ??
        (images.isNotEmpty ? images.first : '');

    return UnitModel(
      id: asInt(json['id']),
      hotelId: asInt(json['hotel_id']),
      hotelName: asString(json['hotel_name']),
      nameAr: asString(json['name_ar']),
      nameEn: asString(json['name_en']),
      unitTypeAr: asStringOrNull(json['unit_type_ar']),
      unitTypeEn: asStringOrNull(json['unit_type_en']),
      unitNumber: asStringOrNull(json['unit_number']),
      descriptionAr: asStringOrNull(json['description_ar']),
      descriptionEn: asStringOrNull(json['description_en']),
      cityAr: asString(json['city_ar']),
      cityEn: asString(json['city_en']),
      capacity: asInt(json['capacity'], 1),
      bedCount: asInt(json['bed_count'], 1),
      pricePerNight: asDouble(json['price_per_night']),
      pricePerWeek: asDoubleOrNull(json['price_per_week']),
      pricePerMonth: asDoubleOrNull(json['price_per_month']),
      coverImage: cover,
      images: images.isNotEmpty ? images : (cover.isEmpty ? const [] : [cover]),
      addons: asMapList(json['addons']).map(UnitAddonModel.fromJson).toList(),
      availability: asMapList(json['availability'])
          .map(UnitAvailabilityModel.fromJson)
          .toList(),
      facilities: asMapList(json['facilities'] ?? json['amenities']),
      ownerBank: json['owner_bank'] is Map
          ? Map<String, dynamic>.from(json['owner_bank'] as Map)
          : null,
    );
  }

  String name(bool isArabic) {
    final preferred = isArabic ? nameAr : nameEn;
    if (preferred.isNotEmpty) return preferred;
    // السيرفر يعيد أحيانًا name_en فارغًا — نرجع العربي بدلًا من نص فارغ
    return isArabic ? nameEn : nameAr;
  }

  String unitType(bool isArabic) {
    final preferred = isArabic ? unitTypeAr : unitTypeEn;
    if (preferred != null && preferred.isNotEmpty) return preferred;
    return (isArabic ? unitTypeEn : unitTypeAr) ?? '';
  }

  String city(bool isArabic) => isArabic ? cityAr : cityEn;

  String description(bool isArabic) {
    final preferred = isArabic ? descriptionAr : descriptionEn;
    if (preferred != null && preferred.isNotEmpty) return preferred;
    return (isArabic ? descriptionEn : descriptionAr) ?? '';
  }

  /// معرّف مستقر للـ Hero/widgets
  String get heroTag => 'unit_$id';
}

/// إضافة اختيارية على الوحدة (سرير إضافي / خطة وجبات / خدمة) — من `units/addons.php`
/// أو مصفوفة `addons` داخل `units/detail.php`.
class UnitAddonModel {
  final int id;
  final String category;
  final String nameAr;
  final String nameEn;
  final double price;
  final String? billing;

  const UnitAddonModel({
    required this.id,
    this.category = '',
    this.nameAr = '',
    this.nameEn = '',
    this.price = 0,
    this.billing,
  });

  factory UnitAddonModel.fromJson(Map<String, dynamic> json) {
    return UnitAddonModel(
      id: asInt(json['id']),
      category: asString(json['category']),
      nameAr: asString(json['name_ar']),
      nameEn: asString(json['name_en']),
      price: asDouble(json['price']),
      // السيرفر يُرسل `price_unit` (وهو ما تكتبه شاشة إضافة الوحدة أيضًا)،
      // وبعض الإصدارات القديمة تُرسل `billing`. نقرأ الاثنين وإلا فسقط
      // المضاعف دائمًا على القيمة الافتراضية وأخطأنا في حساب الإجمالي.
      billing: asStringOrNull(json['price_unit'] ?? json['billing']),
    );
  }

  String name(bool isArabic) {
    final preferred = isArabic ? nameAr : nameEn;
    if (preferred.isNotEmpty) return preferred;
    return isArabic ? nameEn : nameAr;
  }
}

/// فترة إتاحة للوحدة — من مصفوفة `availability` داخل `units/detail.php`.
class UnitAvailabilityModel {
  final DateTime? from;
  final DateTime? to;

  const UnitAvailabilityModel({this.from, this.to});

  factory UnitAvailabilityModel.fromJson(Map<String, dynamic> json) {
    return UnitAvailabilityModel(
      from: DateTime.tryParse(asString(json['date_from'])),
      to: DateTime.tryParse(asString(json['date_to'])),
    );
  }

  bool get isValid => from != null && to != null;
}
