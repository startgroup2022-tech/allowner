import '../utils/safe_parse.dart';

/// مدينة من `cities/list.php` — تُستخدم في الوجهات المميزة وصفحة البحث.
class CityModel {
  final int id;
  final String nameAr;
  final String nameEn;
  final String imageUrl;

  const CityModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.imageUrl = '',
  });

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id: asInt(json['id']),
      nameAr: asString(json['name_ar']),
      nameEn: asString(json['name_en']),
      imageUrl: asString(json['image_url']),
    );
  }

  String name(bool isArabic) {
    final preferred = isArabic ? nameAr : nameEn;
    if (preferred.isNotEmpty) return preferred;
    return isArabic ? nameEn : nameAr;
  }

  /// معرّف فريد للـ widget keys
  String get slug => 'city_$id';
}
