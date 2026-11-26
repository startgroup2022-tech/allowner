/// نماذج تسعير الفندق: تسعير الوحدات (المتطلبات 13–15 من المستند 06) وتسعير
/// الوجبات (المتطلب 16).
///
/// القواعد هنا نقية وقابلة للاختبار:
///   - نموذج تسعير الوحدات يحمل عنوانًا وتاريخًا وستة صفوف (نوع وحدة + سعر).
///     أنواع الوحدات تُقرأ من بيانات الفندق الحقيقية (`unit_type_ar/en`) أو من
///     السجل المحفوظ، ولا تُكتب أسماء ثابتة في الكود.
///   - نموذج تسعير الوجبات يحمل عنوانًا وتاريخًا وثلاث وجبات بأسعارها.
///   - التحقق يمنع الحفظ بلا عنوان أو تاريخ أو سعر صحيح، ويمنع تكرار نوع الوحدة.
///   - السجلات المحفوظة تُقرأ كما هي عند التعديل، فلا تُفقد أسعار قائمة.
library;

/// عدد صفوف تسعير الوحدات المطلوب في المستند.
const int kUnitPricingRowCount = 6;

/// عدد صفوف تسعير الوجبات المطلوب في المستند.
const int kMealPricingRowCount = 3;

double? _asPositiveDouble(Object? raw) {
  final value = raw is num
      ? raw.toDouble()
      : double.tryParse(raw?.toString().trim() ?? '');
  return value != null && value > 0 ? value : null;
}

/// تاريخ التسعير كما يصل من السيرفر (`pricing_date`, `date`, ISO أو yyyy-MM-dd).
DateTime? parsePricingDate(Object? raw) {
  final text = (raw ?? '').toString().trim();
  if (text.isEmpty) return null;
  return DateTime.tryParse(text);
}

/// صيغة التاريخ المرسلة للسيرفر (`yyyy-MM-dd`) — بلا أجزاء وقت أو منطقة زمنية.
String formatPricingDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// صف تسعير وحدة: نوع الوحدة (عربي/إنجليزي) وسعرها.
class UnitPricingRow {
  const UnitPricingRow({
    this.unitTypeAr = '',
    this.unitTypeEn = '',
    this.price,
  });

  final String unitTypeAr;
  final String unitTypeEn;
  final double? price;

  /// الصف فارغ تمامًا (لا نوع ولا سعر) — يُسمح بوجوده ضمن الستة.
  bool get isBlank =>
      unitTypeAr.trim().isEmpty && unitTypeEn.trim().isEmpty && price == null;

  bool get isComplete =>
      (unitTypeAr.trim().isNotEmpty || unitTypeEn.trim().isNotEmpty) &&
      price != null &&
      price! > 0;

  /// الاسم المعروض، مع الرجوع إلى الآخر إن غاب أحدهما.
  String label(bool isArabic) {
    final preferred = (isArabic ? unitTypeAr : unitTypeEn).trim();
    if (preferred.isNotEmpty) return preferred;
    return (isArabic ? unitTypeEn : unitTypeAr).trim();
  }

  UnitPricingRow copyWith(
          {String? unitTypeAr, String? unitTypeEn, double? price}) =>
      UnitPricingRow(
        unitTypeAr: unitTypeAr ?? this.unitTypeAr,
        unitTypeEn: unitTypeEn ?? this.unitTypeEn,
        price: price ?? this.price,
      );
}

/// صف تسعير وجبة: اسم الوجبة وسعرها.
class MealPricingRow {
  const MealPricingRow({this.name = '', this.price});

  final String name;
  final double? price;

  bool get isBlank => name.trim().isEmpty && price == null;

  bool get isComplete => name.trim().isNotEmpty && price != null && price! > 0;

  MealPricingRow copyWith({String? name, double? price}) =>
      MealPricingRow(name: name ?? this.name, price: price ?? this.price);
}

List<Map<String, dynamic>> _asRows(Object? raw) {
  if (raw is List) {
    return raw.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }
  return const <Map<String, dynamic>>[];
}

/// أنواع الوحدات الحقيقية المسجّلة في الفندق، بلا تكرار وبلا أسماء مُختلقة.
List<(String, String)> unitTypesFromUnits(List<Map<String, dynamic>> units) {
  final seen = <String>{};
  final result = <(String, String)>[];
  for (final unit in units) {
    final ar = (unit['unit_type_ar'] ?? '').toString().trim();
    final en = (unit['unit_type_en'] ?? '').toString().trim();
    if (ar.isEmpty && en.isEmpty) continue;
    final key = (ar.isNotEmpty ? ar : en).toLowerCase();
    if (!seen.add(key)) continue;
    result.add((ar, en));
  }
  return result;
}

/// يبني صفوف تسعير الوحدات الستة.
///
/// الأولوية: صفوف السجل المحفوظ (كما هي عند التعديل)، ثم أنواع الوحدات الحقيقية
/// في الفندق، ثم صفوف فارغة حتى يكتمل العدد ستة. لا يُخترع اسم نوع وحدة.
List<UnitPricingRow> buildUnitPricingRows({
  List<Map<String, dynamic>> units = const [],
  Map<String, dynamic>? saved,
}) {
  final rows = <UnitPricingRow>[];
  final seen = <String>{};

  void addRow(String ar, String en, double? price) {
    if (rows.length >= kUnitPricingRowCount) return;
    final key = (ar.trim().isNotEmpty ? ar.trim() : en.trim()).toLowerCase();
    if (key.isEmpty) {
      rows.add(UnitPricingRow(unitTypeAr: ar, unitTypeEn: en, price: price));
      return;
    }
    if (!seen.add(key)) return;
    rows.add(UnitPricingRow(unitTypeAr: ar, unitTypeEn: en, price: price));
  }

  for (final item in _asRows(saved?['rows'])) {
    addRow(
      (item['unit_type_ar'] ?? item['unit_type'] ?? '').toString(),
      (item['unit_type_en'] ?? '').toString(),
      _asPositiveDouble(item['price']),
    );
  }
  for (final (ar, en) in unitTypesFromUnits(units)) {
    addRow(ar, en, null);
  }
  while (rows.length < kUnitPricingRowCount) {
    rows.add(const UnitPricingRow());
  }
  return rows;
}

/// يبني صفوف تسعير الوجبات الثلاثة من سجل محفوظ (أو صفوف فارغة).
List<MealPricingRow> buildMealPricingRows({Map<String, dynamic>? saved}) {
  final rows = <MealPricingRow>[];
  for (final item in _asRows(saved?['meals'])) {
    if (rows.length >= kMealPricingRowCount) break;
    rows.add(MealPricingRow(
      name: (item['name'] ?? item['name_ar'] ?? item['meal_name'] ?? '')
          .toString(),
      price: _asPositiveDouble(item['price']),
    ));
  }
  while (rows.length < kMealPricingRowCount) {
    rows.add(const MealPricingRow());
  }
  return rows;
}

/// يتحقق من نموذج تسعير الوحدات. يُرجع مفتاح رسالة الخطأ أو `null`.
String? validateUnitPricing({
  required String title,
  required DateTime? date,
  required List<UnitPricingRow> rows,
}) {
  if (title.trim().isEmpty) return 'pricing_title_required';
  if (date == null) return 'pricing_date_required';
  final filled = rows.where((r) => !r.isBlank).toList();
  if (filled.isEmpty) return 'pricing_row_required';
  final labels = <String>{};
  for (final row in filled) {
    if (!row.isComplete) return 'pricing_price_invalid';
    final key = row.label(true).toLowerCase();
    if (!labels.add(key)) return 'pricing_row_required';
  }
  return null;
}

/// يتحقق من نموذج تسعير الوجبات. يُرجع مفتاح رسالة الخطأ أو `null`.
String? validateMealPricing({
  required String title,
  required DateTime? date,
  required List<MealPricingRow> rows,
}) {
  if (title.trim().isEmpty) return 'pricing_title_required';
  if (date == null) return 'pricing_date_required';
  final filled = rows.where((r) => !r.isBlank).toList();
  if (filled.isEmpty) return 'pricing_row_required';
  final names = <String>{};
  for (final row in filled) {
    if (!row.isComplete) return 'pricing_price_invalid';
    final key = row.name.trim().toLowerCase();
    if (!names.add(key)) return 'pricing_row_required';
  }
  return null;
}

/// جسم طلب حفظ تسعير الوحدات.
Map<String, dynamic> unitPricingPayload({
  int? id,
  required String title,
  required DateTime date,
  required List<UnitPricingRow> rows,
}) =>
    {
      'action': 'save',
      if (id != null) 'id': id,
      'title': title.trim(),
      'pricing_date': formatPricingDate(date),
      'rows': [
        for (final row in rows.where((r) => !r.isBlank))
          {
            if (row.unitTypeAr.trim().isNotEmpty)
              'unit_type_ar': row.unitTypeAr.trim(),
            if (row.unitTypeEn.trim().isNotEmpty)
              'unit_type_en': row.unitTypeEn.trim(),
            'unit_type': row.label(true),
            'price': row.price,
          },
      ],
    };

/// جسم طلب حفظ تسعير الوجبات.
Map<String, dynamic> mealPricingPayload({
  int? id,
  required String title,
  required DateTime date,
  required List<MealPricingRow> rows,
}) =>
    {
      'action': 'save',
      if (id != null) 'id': id,
      'title': title.trim(),
      'pricing_date': formatPricingDate(date),
      'meals': [
        for (final row in rows.where((r) => !r.isBlank))
          {'name': row.name.trim(), 'price': row.price},
      ],
    };
