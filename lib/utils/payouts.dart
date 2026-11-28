/// احتساب عمولة المنصة وتسوية المستحقات (المتطلبات 139–142).
///
///   • 139: احتساب عمولة 10% على المالك.
///   • 140: إظهار السعر النهائي للضيف.
///   • 141: التسوية بعد انتهاء الإقامة.
///   • 142: دفع مستحقات المالك أسبوعيًا.
///
/// هذه دوال حسابية نقية: تأخذ الأرقام الحقيقية القادمة من الـ API وتُعيد
/// النتيجة. لا تُنشئ أي حجز ولا تؤكّد أي دفع. التسوية الفعلية والدفع يحتاجان
/// تنفيذًا على السيرفر.
library;

/// تفصيل احتساب العمولة لرحلة واحدة.
class CommissionBreakdown {
  /// إجمالي ما دفعه الضيف (السعر النهائي).
  final double grossAmount;

  /// نسبة العمولة المطبَّقة.
  final double percent;

  /// قيمة العمولة.
  final double commission;

  /// صافي المالك بعد خصم العمولة.
  final double ownerNet;

  const CommissionBreakdown({
    required this.grossAmount,
    required this.percent,
    required this.commission,
    required this.ownerNet,
  });
}

/// نسبة العمولة الافتراضية المذكورة في المستند (10%).
const double defaultCommissionPercent = 10;

/// يحسب العمولة والصافي من الإجمالي ونسبة العمولة.
///
/// النسبة تُقيَّد بين 0 و100 حتى لا تُنتج قيمة سالبة لو أعاد السيرفر رقمًا
/// خاطئًا. الإجمالي السالب يُعامل كصفر (لا عمولة على مبلغ سالب).
CommissionBreakdown computeCommission(
  double grossAmount, {
  double percent = defaultCommissionPercent,
}) {
  final safeGross = grossAmount < 0 ? 0.0 : grossAmount;
  final safePercent = percent < 0 ? 0.0 : (percent > 100 ? 100.0 : percent);
  final commission = safeGross * safePercent / 100;
  return CommissionBreakdown(
    grossAmount: safeGross,
    percent: safePercent,
    commission: commission,
    ownerNet: safeGross - commission,
  );
}

/// تاريخ التسوية: هل انتهت الإقامة؟ تُقارَن تواريخ `YYYY-MM-DD` فقط.
///
/// يُرجع `false` لأي تاريخ غير صالح بدل اعتبار الحجز منتهيًا بالخطأ. [today]
/// يُمرَّر للاختبار حتى تكون الدالة نقية.
bool isStayCompleted(String? checkOut, {DateTime? today}) {
  final date = parseIsoDate(checkOut);
  if (date == null) return false;
  final now = today ?? DateTime.now();
  final todayOnly = DateTime(now.year, now.month, now.day);
  return !date.isAfter(todayOnly);
}

/// يحلّل تاريخ `YYYY-MM-DD` أو `YYYY-MM-DD HH:MM:SS` أو ISO كامل.
/// يُرجع null لأي شكل غير مفهوم.
DateTime? parseIsoDate(String? raw) {
  final text = (raw ?? '').trim();
  if (text.isEmpty) return null;
  final datePart = text.split(' ').first.split('T').first;
  final parts = datePart.split('-');
  if (parts.length != 3) return null;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return null;
  if (m < 1 || m > 12 || d < 1 || d > 31) return null;
  final parsed = DateTime(y, m, d);
  // يرفض التواريخ المستحيلة مثل 2025-02-31 (تُطبَّع إلى مارس)
  if (parsed.month != m || parsed.day != d) return null;
  return parsed;
}

/// يوم الدفع الأسبوعي (المتطلب 142): هل يحق للمالك طلب/استلام دفعة اليوم؟
///
/// المستند يذكر دفعًا أسبوعيًا دون تحديد يوم. لا نخترع يومًا: نُعيد `true`
/// لأي يوم ما لم يُحدَّد [payoutWeekday] صراحةً من الإعدادات، وعندها فقط
/// نقيّد. هذا يمنع تعطيل الدفع بسبب يوم مُخترع.
bool isPayoutDay({int? payoutWeekday, DateTime? today}) {
  if (payoutWeekday == null) return true;
  if (payoutWeekday < 1 || payoutWeekday > 7) return true;
  final now = today ?? DateTime.now();
  return now.weekday == payoutWeekday;
}

/// نص مبسّط لعرض السعر النهائي للضيف (المتطلب 140).
///
/// يُرجع نصًا بأرقام صحيحة (بلا كسور عشرية زائدة) مع رمز العملة المحلي.
String formatFinalPrice(double amount, {bool isArabic = true}) {
  final rounded = amount.isFinite ? amount.round() : 0;
  final currency = isArabic ? 'ريال' : 'SAR';
  return '$rounded $currency';
}
