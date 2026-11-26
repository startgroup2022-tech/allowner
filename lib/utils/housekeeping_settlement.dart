/// خيارا سداد قيمة طلب النظافة عند تأكيده (المتطلب 10 من المستند 06).
///
/// القواعد الفعلية تعيش في `request_settlement.dart` وتُشاركها طلبات النظافة
/// والوجبات والسرير الإضافي (المتطلبات 11 و12) بدل تكرارها. هذه الواجهة تبقى
/// للتوافق مع شاشة الطلبات والاختبارات القائمة.
library;

import 'request_settlement.dart';

export 'request_settlement.dart' show extractServerPaymentLink;

/// خيار سداد طلب النظافة.
enum HousekeepingSettlement { walletBalance, whatsappLink }

RequestSettlement _shared(HousekeepingSettlement option) => switch (option) {
      HousekeepingSettlement.walletBalance => RequestSettlement.walletBalance,
      HousekeepingSettlement.whatsappLink => RequestSettlement.whatsappLink,
    };

/// القيمة المُرسلة للسيرفر في حقل `settlement`.
String housekeepingSettlementPayload(HousekeepingSettlement option) =>
    requestSettlementPayload(_shared(option));

/// مفتاح ترجمة اسم الخيار.
String housekeepingSettlementLabelKey(HousekeepingSettlement option) =>
    requestSettlementLabelKey(_shared(option));

/// السعر المعتمد لطلب النظافة كما وصل من السيرفر، أو `null` إن لم يُعتمد بعد.
double? approvedHousekeepingPrice(Map<String, dynamic> request) =>
    approvedRequestPrice(request);

/// هل سبق تسجيل سداد لهذا الطلب؟ يمنع الخصم المزدوج وطلب الدفع المكرر.
bool isHousekeepingSettlementRecorded(Map<String, dynamic> request) =>
    isRequestSettlementRecorded(request);

/// صلاحية تأكيد طلب نظافة وتسجيل سداده — تُطابق صلاحيات لوحة الفندق.
bool canConfirmHousekeepingSettlement(String? role) =>
    canConfirmRequestSettlement(role);

/// يتحقق من اكتمال بيانات تأكيد النظافة. يُرجع مفتاح رسالة الخطأ أو `null`.
String? validateHousekeepingSettlement({
  required Map<String, dynamic> request,
  required HousekeepingSettlement? choice,
  required double? price,
  required bool canConfirm,
}) =>
    validateRequestSettlement(
      request: request,
      choice: choice == null ? null : _shared(choice),
      price: price,
      canConfirm: canConfirm,
      kind: SettlementRequestKind.cleaning,
    );

/// رابط واتساب لرسالة طلب سداد النظافة.
Uri? buildHousekeepingWhatsAppUri({
  required String? phone,
  required bool isArabic,
  int? requestId,
  String? unitName,
  double? amount,
  String? paymentLink,
}) =>
    buildSettlementWhatsAppUri(
      phone: phone,
      isArabic: isArabic,
      kind: SettlementRequestKind.cleaning,
      requestId: requestId,
      unitName: unitName,
      amount: amount,
      paymentLink: paymentLink,
    );
