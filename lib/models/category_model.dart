import '../utils/safe_parse.dart';

/// تصنيف إقامة من `categories/list.php` (فنادق / شقق فندقية / منتجعات / شاليهات).
///
/// القائمة تأتي من قاعدة البيانات — لا نضع تصنيفات ثابتة في الواجهة.
/// `icon_key` نص يحدد الأيقونة، و`color_hex` لون اختياري من الإدارة.
class CategoryModel {
  final int id;
  final String nameAr;
  final String nameEn;
  final String iconKey;
  final String colorHex;

  const CategoryModel({
    required this.id,
    this.nameAr = '',
    this.nameEn = '',
    this.iconKey = '',
    this.colorHex = '',
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: asInt(json['id']),
      nameAr: asString(json['name_ar']),
      nameEn: asString(json['name_en']),
      iconKey: asString(json['icon_key']),
      colorHex: asString(json['color_hex']),
    );
  }

  String name(bool isArabic) {
    final preferred = isArabic ? nameAr : nameEn;
    if (preferred.isNotEmpty) return preferred;
    return isArabic ? nameEn : nameAr;
  }
}
