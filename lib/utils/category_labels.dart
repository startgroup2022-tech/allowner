/// تسميات تصنيفات الإقامة المعروضة في الواجهة.
///
/// المستند الأصلي (المتطلبان 13 و14) يطلب أن يكون التصنيف الرئيسي
/// «الوحدات الفندقية» بدل «فنادق»، لأن التطبيق منصة لوحدات يملكها أفراد داخل
/// الفنادق لا تطبيق حجز فنادق. التصنيفات نفسها تبقى قادمة من قاعدة البيانات
/// (`categories/list.php`) — لا نُنشئ صفوفًا وهمية.
///
/// نُطبّق التسمية المطلوبة فقط على التصنيف المطابق لـ `icon_key`، وبقية
/// التصنيفات تبقى بأسماء الإدارة حرفيًا. الاسم من قاعدة البيانات يبقى مصدر
/// الحقيقة للفلترة، والتسمية هنا عرض فقط.
class CategoryLabels {
  CategoryLabels._();

  static const Map<String, Map<String, String>> _overrides = {
    'hotels': {'ar': 'الوحدات الفندقية', 'en': 'Hotel units'},
    'properties': {'ar': 'عقارات', 'en': 'Properties'},
  };

  /// الاسم المعروض للتصنيف: التسمية المطلوبة إن وُجدت لـ `icon_key`، وإلا
  /// الاسم القادم من قاعدة البيانات (مع الاحتياط للغة الأخرى إن كانت فارغة).
  static String display({
    required String iconKey,
    required String nameAr,
    required String nameEn,
    required bool isArabic,
  }) {
    final override = _overrides[iconKey.trim().toLowerCase()];
    if (override != null) {
      final value = override[isArabic ? 'ar' : 'en']!;
      if (value.isNotEmpty) return value;
    }
    final preferred = isArabic ? nameAr : nameEn;
    if (preferred.isNotEmpty) return preferred;
    return isArabic ? nameEn : nameAr;
  }
}
