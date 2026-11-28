/// بحث أرقام الوحدات/الغرف (المتطلبان 2 و9 من المستند 06).
library;

/// يطبّع نص البحث: يقلّم الأطراف، ويحوّل الأرقام العربية-الهندية والفارسية إلى
/// لاتينية حتى يجد المستخدم وحدته بأي لوحة مفاتيح، ويوحّد المسافات.
String normalizeUnitSearchText(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '';
  final buffer = StringBuffer();
  for (final rune in raw.runes) {
    if (rune >= 0x0660 && rune <= 0x0669) {
      buffer.writeCharCode(0x30 + (rune - 0x0660));
    } else if (rune >= 0x06F0 && rune <= 0x06F9) {
      buffer.writeCharCode(0x30 + (rune - 0x06F0));
    } else {
      buffer.writeCharCode(rune);
    }
  }
  return buffer.toString().toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// فلترة الوحدات برقم الوحدة.
///
/// - بحث فارغ (أو مسافات فقط) يُرجع القائمة كما هي، فلا تتأثر الفلاتر والحجز.
/// - يدعم المطابقة الجزئية والكاملة، ويقدّم المطابقة الكاملة ثم البادئة.
List<T> filterUnitsByUnitNumber<T>({
  required List<T> units,
  required String query,
  required String? Function(T unit) unitNumberOf,
}) {
  final needle = normalizeUnitSearchText(query).replaceAll(' ', '');
  if (needle.isEmpty) return units;

  final exact = <T>[];
  final prefix = <T>[];
  final partial = <T>[];
  for (final unit in units) {
    final haystack =
        normalizeUnitSearchText(unitNumberOf(unit)).replaceAll(' ', '');
    if (haystack.isEmpty) continue;
    if (haystack == needle) {
      exact.add(unit);
    } else if (haystack.startsWith(needle)) {
      prefix.add(unit);
    } else if (haystack.contains(needle)) {
      partial.add(unit);
    }
  }
  return <T>[...exact, ...prefix, ...partial];
}

/// هل البحث الحالي بلا نتائج مع أن الوحدات موجودة؟ (لعرض حالة «لا نتائج» فقط).
bool hasNoUnitSearchMatch<T>({
  required List<T> units,
  required String query,
  required String? Function(T unit) unitNumberOf,
}) =>
    units.isNotEmpty &&
    filterUnitsByUnitNumber(
            units: units, query: query, unitNumberOf: unitNumberOf)
        .isEmpty;

/// يقرأ رقم الغرفة/الوحدة من سجل مغادرة قادم من الـ API دون اختلاق قيمة.
///
/// يقبل المفاتيح التي يستخدمها الباك إند فعليًا: `unit_number`, `room_number`,
/// `unit_no`, `room_no`، ثم `unit_name` كخيار أخير (بعض الفهارس تسمّي الوحدة
/// برقمها). يُرجع نصًا فارغًا إن لم يوجد رقم حقيقي.
String departureUnitNumber(Map<String, dynamic> record) {
  const keys = ['unit_number', 'room_number', 'unit_no', 'room_no'];
  for (final key in keys) {
    final value = record[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return '';
}
