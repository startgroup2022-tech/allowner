/// حساب إجمالي الحجز في مكان واحد.
///
/// كان الحساب مكرَّرًا حرفيًا في مكانين داخل شاشة الحجز (نافذة التأكيد وملخص
/// الصفحة)، وأي تعديل في أحدهما كان يُنتج رقمين مختلفين لنفس الحجز. الآن دالة
/// نقية واحدة تُستخدم في المكانين ومُختبَرة.
library;

/// نسبة الضريبة/الرسوم المعروضة قبل إنشاء الحجز. السيرفر لا يُرجع نسبة ولا
/// مبلغًا للضريبة في `hotels/list.php` أو `hotels/detail.php`، فهذه قيمة عرض
/// تقديرية. الإجمالي المعتمد هو الذي يعيده السيرفر بعد إنشاء الحجز ويُعرض في
/// شاشة نجاح الحجز.
const double kDisplayedTaxRate = 0.15;

class BookingTotals {
  final double roomPrice;
  final double addonsTotal;
  final double extraBedCharge;
  final double taxes;
  final double total;

  const BookingTotals({
    required this.roomPrice,
    required this.addonsTotal,
    required this.extraBedCharge,
    required this.taxes,
    required this.total,
  });
}

BookingTotals computeBookingTotals({
  required double basePricePerNight,
  required int nights,
  double addonsTotal = 0,
  double extraBedCharge = 0,
  double taxRate = kDisplayedTaxRate,
}) {
  final n = nights < 1 ? 1 : nights;
  final roomPrice = basePricePerNight * n;
  final taxable = roomPrice + addonsTotal + extraBedCharge;
  final taxes = taxable * taxRate;
  return BookingTotals(
    roomPrice: roomPrice,
    addonsTotal: addonsTotal,
    extraBedCharge: extraBedCharge,
    taxes: taxes,
    total: taxable + taxes,
  );
}
