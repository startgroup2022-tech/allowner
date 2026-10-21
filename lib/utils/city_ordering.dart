/// ترتيب الوجهات المعروضة في الرئيسية (المتطلب 18).
///
/// المستند يطلب إبراز مكة وجدة والمدينة والرياض في قسم «الوجهات الرئيسية».
/// القائمة نفسها تبقى قادمة من `cities/list.php` بالكامل — لا نُنشئ مدينة غير
/// موجودة ولا نحذف مدينة أضافها الأدمن. كل ما نفعله هو تقديم المدن المطلوبة
/// في المستند إلى مقدمة القائمة، ثم نُبقي بقية المدن بترتيب الـ API.
///
/// المقارنة تتم بعد تطبيع الاسم (إزالة التشكيل والتطويل، توحيد الألف والهاء
/// والتاء المربوطة) لأن الـ API قد يُرجع «مكة المكرمة» بينما المستند يكتب
/// «مكة».
library;

import 'arabic_text.dart';

class CityOrdering {
  CityOrdering._();

  /// المدن التي يطلب المستند إبرازها، بترتيب الظهور المطلوب.
  static const List<String> featuredOrder = [
    'مكة',
    'المدينة',
    'جدة',
    'الرياض',
  ];

  /// يُعيد قائمة جديدة: المدن المطلوبة أولًا (بترتيب [featuredOrder])، ثم بقية
  /// المدن بترتيبها الأصلي. لا يحذف ولا يُضيف أي عنصر.
  static List<T> prioritize<T>(
    List<T> cities,
    String Function(T city) nameOf,
  ) {
    final remaining = List<T>.from(cities);
    final ordered = <T>[];
    for (final wanted in featuredOrder) {
      final target = _normalize(wanted);
      if (target == null) continue;
      final index = remaining.indexWhere((city) {
        final name = _normalize(nameOf(city));
        if (name == null) return false;
        return name == target || name.startsWith(target);
      });
      if (index != -1) {
        ordered.add(remaining.removeAt(index));
      }
    }
    return [...ordered, ...remaining];
  }

  static String? _normalize(String value) => normalizeArabic(value);
}
