import '../utils/safe_parse.dart';

/// مرفق/خدمة (واي فاي، مكيف، مطعم...) من `hotels/detail.php` ← `amenities`.
///
/// مهم: هذه قائمة المرافق *المرتبطة فعليًا بهذا الفندق*، وليست كل الجدول العام.
/// `iconKey` من قاعدة البيانات يُترجم إلى أيقونة Material عبر `AmenityIcons`.
class AmenityModel {
  final int id;
  final String nameAr;
  final String nameEn;
  final String iconKey;

  const AmenityModel({
    required this.id,
    this.nameAr = '',
    this.nameEn = '',
    this.iconKey = '',
  });

  factory AmenityModel.fromJson(Map<String, dynamic> json) {
    return AmenityModel(
      id: asInt(json['id']),
      nameAr: asString(json['name_ar']),
      nameEn: asString(json['name_en']),
      iconKey: asString(json['icon']),
    );
  }

  String name(bool isArabic) {
    final preferred = isArabic ? nameAr : nameEn;
    if (preferred.isNotEmpty) return preferred;
    return isArabic ? nameEn : nameAr;
  }
}
