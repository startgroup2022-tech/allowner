/// خيارا سداد قيمة طلب النظافة عند تأكيده (المتطلب 10 من المستند 06).
///
/// المستند يطلب خيارين مطابقين لمسار الصيانة:
///   1. خصم من الرصيد.
///   2. الدفع عبر رابط بالواتساب.
///
/// لا يُنشئ التطبيق رصيدًا ولا رابط دفع. الخصم يُنفَّذ على السيرفر، ورابط الدفع
/// يُقرأ من استجابة السيرفر إن وُجد؛ وإلا تبقى رسالة واتساب طلب دفع بلا رابط.
library;

import 'maintenance_settlement.dart';

/// خيار سداد طلب النظافة.
enum HousekeepingSettlement { walletBalance, whatsappLink }

/// القيمة المُرسلة للسيرفر في حقل `settlement`.
String housekeepingSettlementPayload(HousekeepingSettlement option) =>
    switch (option) {
      HousekeepingSettlement.walletBalance => 'wallet_balance',
      HousekeepingSettlement.whatsappLink => 'whatsapp_link',
    };

/// مفتاح ترجمة اسم الخيار.
String housekeepingSettlementLabelKey(HousekeepingSettlement option) =>
    switch (option) {
      HousekeepingSettlement.walletBalance => 'settle_wallet_balance',
      HousekeepingSettlement.whatsappLink => 'settle_whatsapp_pay_link',
    };

/// السعر المعتمد لطلب النظافة كما وصل من السيرفر، أو `null` إن لم يُعتمد بعد.
double? approvedHousekeepingPrice(Map<String, dynamic> request) {
  for (final key in ['price', 'approved_price', 'total_price', 'cost']) {
    final raw = request[key];
    if (raw == null) continue;
    final value =
        raw is num ? raw.toDouble() : double.tryParse(raw.toString().trim());
    if (value != null && value > 0) return value;
  }
  return null;
}

/// هل سبق تسجيل سداد لهذا الطلب؟ يمنع الخصم المزدوج وطلب الدفع المكرر.
bool isHousekeepingSettlementRecorded(Map<String, dynamic> request) {
  const settledStates = {
    'paid',
    'settled',
    'deducted',
    'completed',
    'succeeded',
  };
  if ((request['settlement'] ?? '').toString().trim().isNotEmpty) return true;
  if (request['settled'] == true) return true;
  final paymentStatus =
      (request['payment_status'] ?? '').toString().trim().toLowerCase();
  if (settledStates.contains(paymentStatus)) return true;
  final settlementStatus =
      (request['settlement_status'] ?? '').toString().trim().toLowerCase();
  return settledStates.contains(settlementStatus);
}

/// صلاحية تأكيد طلب نظافة وتسجيل سداده — تُطابق صلاحيات لوحة الفندق.
bool canConfirmHousekeepingSettlement(String? role) =>
    role == 'hotel_manager' || role == 'owner' || role == 'unit_manager';

/// يتحقق من اكتمال بيانات تأكيد النظافة. يُرجع مفتاح رسالة الخطأ أو `null`.
String? validateHousekeepingSettlement({
  required Map<String, dynamic> request,
  required HousekeepingSettlement? choice,
  required double? price,
  required bool canConfirm,
}) {
  if (!canConfirm) return 'permission_denied';
  if (isHousekeepingSettlementRecorded(request)) {
    return 'settlement_already_recorded';
  }
  if (price == null || price <= 0) return 'housekeeping_price_missing';
  if (choice == null) return 'payment_method_required';
  return null;
}

/// رابط الدفع الحقيقي الذي أصدره السيرفر — `https` مطلق فقط، وإلا `null`.
///
/// لا يُبنى رابط دفع داخل التطبيق إطلاقًا.
String? extractServerPaymentLink(Map<String, dynamic>? response) {
  if (response == null) return null;
  for (final key in [
    'payment_link',
    'payment_url',
    'checkout_url',
    'invoice_url',
  ]) {
    final raw = response[key];
    if (raw == null) continue;
    final text = raw.toString().trim();
    if (text.isEmpty) continue;
    final uri = Uri.tryParse(text);
    if (uri != null && uri.isScheme('https') && uri.host.isNotEmpty) {
      return text;
    }
  }
  return null;
}

/// رابط واتساب لرسالة طلب سداد النظافة.
///
/// يُضاف رابط الدفع إلى الرسالة فقط إن كان قد وصل من السيرفر. غياب الرقم أو
/// الرابط لا يُنتج رابطًا مكسورًا ولا مبلغًا وهميًا.
Uri? buildHousekeepingWhatsAppUri({
  required String? phone,
  required bool isArabic,
  int? requestId,
  String? unitName,
  double? amount,
  String? paymentLink,
}) {
  final normalized = normalizeWhatsAppPhone(phone);
  if (normalized == null) return null;

  final lines = <String>[
    isArabic ? 'طلب سداد تكلفة نظافة' : 'Housekeeping payment request',
  ];
  if (requestId != null) {
    lines.add(isArabic ? 'رقم الطلب: $requestId' : 'Request #$requestId');
  }
  final unit = (unitName ?? '').trim();
  if (unit.isNotEmpty) {
    lines.add(isArabic ? 'الوحدة: $unit' : 'Unit: $unit');
  }
  if (amount != null && amount > 0) {
    final value = amount == amount.roundToDouble()
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
    lines.add(isArabic ? 'المبلغ: $value SAR' : 'Amount: $value SAR');
  }
  final link = (paymentLink ?? '').trim();
  if (link.isNotEmpty) lines.add(link);

  return Uri.parse('https://wa.me/$normalized').replace(
    queryParameters: {'text': lines.join('\n')},
  );
}
