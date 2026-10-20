/// أدوات تحويل آمنة لاستجابات الـ API.
///
/// المشكلة: أعمدة DECIMAL/INT في قاعدة البيانات (السعر، السعة، المعرّف) ترجع من
/// PHP/PDO أحيانًا كنص (String) وأحيانًا كرقم (num) — فالتحويل المباشر
/// (`as num` / `as int`) يسبب انهيارًا كاملاً بالصفحة. نفس المبدأ ينطبق على
/// القوائم والمصفوفات التي قد ترجع مفقودة أو null من السيرفر.
///
/// كل الدوال هنا لا ترمي استثناءً أبدًا: تُرجع قيمة افتراضية عند أي شكل غير متوقع.
library;

num asNum(dynamic value, [num fallback = 0]) {
  if (value == null) return fallback;
  if (value is num) return value;
  if (value is String) return num.tryParse(value.trim()) ?? fallback;
  if (value is bool) return value ? 1 : 0;
  return fallback;
}

int asInt(dynamic value, [int fallback = 0]) => asNum(value, fallback).toInt();

double asDouble(dynamic value, [double fallback = 0]) =>
    asNum(value, fallback).toDouble();

/// نص آمن: يحوّل أي قيمة إلى نص، ويُرجع [fallback] للقيم الفارغة/null.
String asString(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

/// نص غير فارغ أو null — مفيد للحقول الاختيارية (الوصف، الصورة، النوع).
String? asStringOrNull(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

/// تعامل مع الأعلام التي ترجع أحيانًا `true/false` وأحيانًا `1/0` وأحيانًا `"1"`.
bool asBool(dynamic value, [bool fallback = false]) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final v = value.trim().toLowerCase();
    if (v == 'true' || v == '1' || v == 'yes') return true;
    if (v == 'false' || v == '0' || v == 'no') return false;
  }
  return fallback;
}

/// يحوّل قيمة غير معروفة إلى قائمة نصوص، ويتجاهل القيم الفارغة.
List<String> asStringList(dynamic value) {
  if (value is! List) return const <String>[];
  final out = <String>[];
  for (final item in value) {
    final text = asStringOrNull(item);
    if (text != null) out.add(text);
  }
  return out;
}

/// يحوّل قيمة غير معروفة إلى قائمة خرائط، ويتجاهل أي عنصر غير صالح.
List<Map<String, dynamic>> asMapList(dynamic value) {
  if (value is! List) return const <Map<String, dynamic>>[];
  final out = <Map<String, dynamic>>[];
  for (final item in value) {
    if (item is Map) out.add(item.cast<String, dynamic>());
  }
  return out;
}

/// يحوّل قيمة غير معروفة إلى خريطة نصية، ويُرجع خريطة فارغة عند أي شكل آخر.
Map<String, dynamic> asMap(dynamic value) {
  if (value is Map) return value.cast<String, dynamic>();
  return const <String, dynamic>{};
}

/// تحويل آمن لعنصر قد يكون مفقودًا أو فارغًا (معرّفات العناصر).
int? asIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return num.tryParse(trimmed)?.toInt();
  }
  return null;
}

double? asDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return num.tryParse(trimmed)?.toDouble();
  }
  return null;
}

/// يجلب حقلًا نصيًا من خريطة JSON مع دعم البديل عربي/إنجليزي.
String localized(Map<String, dynamic> json, String baseKey, bool isArabic) {
  final suffix = isArabic ? 'ar' : 'en';
  final primary = asStringOrNull(json['${baseKey}_$suffix']);
  if (primary != null) return primary;
  final other = asStringOrNull(json[isArabic ? '${baseKey}_en' : '${baseKey}_ar']);
  if (other != null) return other;
  return asString(json[baseKey]);
}
