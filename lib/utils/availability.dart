/// التحقق من ملاءمة تواريخ الإقامة لفترات إتاحة الوحدة (المتطلب 45).
///
/// المتطلب 45 يمنع الحجز المزدوج لنفس الوحدة والتواريخ. المنع الحقيقي يحتاج
/// فحصًا على السيرفر لأن التطبيق لا يعرف الحجوزات المؤكدة للآخرين. لكن جزءًا
/// حقيقيًا متاح لنا: `units/detail.php` يُرجع `availability` = الفترات التي
/// أعلن المالك أن الوحدة متاحة فيها. إذا اختار الضيف تواريخ خارج كل الفترات
/// فالحجز لن ينجح، فنُنبّهه قبل الدفع بدل أن يفشل الطلب لاحقًا.
///
/// لا نخترع قيودًا: إذا لم يُرجع السيرفر أي فترة (أو كانت كلها غير صالحة) فلا
/// نمنع ولا نُحذّر — نترك القرار للسيرفر.
library;

import '../models/unit_model.dart';

/// نتيجة فحص الإتاحة المحلي.
enum AvailabilityVerdict {
  /// لا توجد فترات مُعلنة — لا قيد محلي.
  unknown,

  /// الإقامة كاملة داخل فترة إتاحة واحدة.
  inside,

  /// الإقامة خارج كل فترات الإتاحة المُعلنة.
  outside,
}

/// يفحص هل تقع الإقامة `[checkIn, checkOut)` داخل فترة إتاحة واحدة على الأقل.
///
/// الإقامة تُقبل فقط إذا غطّتها فترة واحدة بالكامل (الليلة الأخيرة هي ليلة
/// المغادرة، لذا نقارن `checkOut` بحد الفترة العُلوي مباشرة). لا نعتبر جمع
/// فترتين متجاورتين تغطية كاملة لأن الحجز الواحد لا يُقسَّم.
AvailabilityVerdict checkAvailability({
  required DateTime checkIn,
  required DateTime checkOut,
  required List<UnitAvailabilityModel> periods,
}) {
  final valid = periods.where((p) => p.isValid).toList();
  if (valid.isEmpty) return AvailabilityVerdict.unknown;
  if (!checkOut.isAfter(checkIn)) return AvailabilityVerdict.outside;

  final inDay = DateTime(checkIn.year, checkIn.month, checkIn.day);
  final outDay = DateTime(checkOut.year, checkOut.month, checkOut.day);

  for (final p in valid) {
    final from = DateTime(p.from!.year, p.from!.month, p.from!.day);
    final to = DateTime(p.to!.year, p.to!.month, p.to!.day);
    if (!inDay.isBefore(from) && !outDay.isAfter(to)) {
      return AvailabilityVerdict.inside;
    }
  }
  return AvailabilityVerdict.outside;
}

/// هل يجوز للضيف اختيار هذا اليوم في منتقي التاريخ؟
///
/// يمنع اختيار أي يوم خارج كل فترات الإتاحة المُعلنة للوحدة. إن لم يُعلن
/// السيرفر أي فترة (أو كانت كلها غير صالحة) فلا قيد محلي، تمامًا مثل
/// [checkAvailability] — لا نخترع قيودًا من عندنا.
bool isDaySelectable({
  required DateTime day,
  required List<UnitAvailabilityModel> periods,
}) {
  final valid = periods.where((p) => p.isValid).toList();
  if (valid.isEmpty) return true;
  final target = DateTime(day.year, day.month, day.day);
  for (final p in valid) {
    final from = DateTime(p.from!.year, p.from!.month, p.from!.day);
    final to = DateTime(p.to!.year, p.to!.month, p.to!.day);
    if (!target.isBefore(from) && !target.isAfter(to)) return true;
  }
  return false;
}

/// مفتاح الترجمة للتحذير المعروض، أو null إذا لا حاجة لتحذير.
String? availabilityWarningKey(AvailabilityVerdict verdict) {
  switch (verdict) {
    case AvailabilityVerdict.unknown:
    case AvailabilityVerdict.inside:
      return null;
    case AvailabilityVerdict.outside:
      return 'dates_outside_availability';
  }
}
