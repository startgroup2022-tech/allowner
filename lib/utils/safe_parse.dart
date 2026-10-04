/// المشكلة: أعمدة DECIMAL بقاعدة البيانات (السعر مثلاً) ترجع من PHP/PDO كنص
/// (String) أحيانًا مو رقم (num) — فيحصل انهيار كامل بالصفحة لو استخدمنا
/// `as num` مباشرة. هالدالة تتعامل مع الحالتين بأمان.
num asNum(dynamic value, [num fallback = 0]) {
  if (value == null) return fallback;
  if (value is num) return value;
  if (value is String) return num.tryParse(value) ?? fallback;
  return fallback;
}

int asInt(dynamic value, [int fallback = 0]) => asNum(value, fallback).toInt();

double asDouble(dynamic value, [double fallback = 0]) => asNum(value, fallback).toDouble();
