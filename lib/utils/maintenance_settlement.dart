/// خيارا تسوية تكلفة الصيانة عند تأكيد الطلب (المتطلبات 390–394).
///
/// المستند يطلب أن يظهر للمالك/إدارة الفندق عند تأكيد طلب الصيانة خياران:
///   1. خصم التكلفة من رصيد الوحدة.
///   2. إرسال رابط الدفع عبر واتساب.
///
/// الخصم الفعلي من الرصيد يحتاج تنفيذًا على السيرفر (الرصيد غير مُعرَّض لأي
/// endpoint)، لذلك نُرسل الخيار المختار ضمن الطلب ونعرض للمستخدم ما حدث. أما
/// رسالة واتساب فهي قدرة حقيقية على الجهاز: نبني رابط `wa.me` برسالة تحتوي
/// رقم الطلب والوحدة والمبلغ، ونفتحه بتطبيق واتساب. لا يُختلق رقم ولا مبلغ.
library;

/// الخيار الذي يختاره المستخدم عند تأكيد طلب الصيانة.
enum MaintenanceSettlement {
  /// خصم من رصيد الوحدة.
  unitBalance,

  /// إرسال رابط الدفع عبر واتساب.
  whatsappLink,
}

/// القيمة المُرسلة للسيرفر لكل خيار. السيرفر يتجاهل الحقول غير المعروفة، فلا
/// يكسر ذلك الطلبات القائمة.
String settlementPayload(MaintenanceSettlement option) {
  switch (option) {
    case MaintenanceSettlement.unitBalance:
      return 'unit_balance';
    case MaintenanceSettlement.whatsappLink:
      return 'whatsapp_link';
  }
}

/// يُنظّف رقم الهاتف ويُعيده بصيغة `wa.me` (أرقام فقط، بلا `+` أو مسافات).
/// يُرجع null إن لم يبقَ رقم صالح، فلا نفتح رابطًا بلا وجهة.
String? normalizeWhatsAppPhone(String? raw) {
  if (raw == null) return null;
  final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length < 8) return null;
  return digits;
}

/// يبني نص رسالة طلب الدفع. الحقول الناقصة تُحذف من الرسالة بدل عرض صفر أو
/// فراغ، فلا يظهر مبلغ وهمي.
String buildMaintenancePaymentMessage({
  required bool isArabic,
  int? requestId,
  String? unitName,
  double? amount,
  String? currency,
}) {
  final lines = <String>[
    isArabic ? 'طلب دفع تكلفة صيانة' : 'Maintenance payment request',
  ];
  if (requestId != null) {
    lines.add(isArabic ? 'رقم الطلب: $requestId' : 'Request #$requestId');
  }
  if (unitName != null && unitName.trim().isNotEmpty) {
    lines.add(
        isArabic ? 'الوحدة: ${unitName.trim()}' : 'Unit: ${unitName.trim()}');
  }
  if (amount != null && amount > 0) {
    final value = amount == amount.roundToDouble()
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
    lines.add(isArabic
        ? 'المبلغ: $value ${currency ?? 'SAR'}'
        : 'Amount: $value ${currency ?? 'SAR'}');
  }
  return lines.join('\n');
}

/// رابط واتساب الجاهز للفتح، أو null إذا تعذّر بناء وجهة صحيحة.
Uri? buildWhatsAppPaymentUri({
  required String? phone,
  required bool isArabic,
  int? requestId,
  String? unitName,
  double? amount,
  String? currency,
}) {
  final normalized = normalizeWhatsAppPhone(phone);
  if (normalized == null) return null;
  return Uri.parse('https://wa.me/$normalized').replace(
    queryParameters: {
      'text': buildMaintenancePaymentMessage(
        isArabic: isArabic,
        requestId: requestId,
        unitName: unitName,
        amount: amount,
        currency: currency,
      ),
    },
  );
}
