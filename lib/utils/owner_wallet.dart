/// محفظة المالك وطلب تحويل المستحقات (المتطلبات 132–143).
///
/// المستند يطلب: حساب تحصيل مركزي للمنصة، حساب أستاذ (Ledger) لكل مالك، تسجيل
/// الحجوزات والعمولات والاستردادات والتسويات، محفظة تعرض الرصيد والحجوزات
/// والعمولة والمصروفات والقابل للتحويل، طلب تحويل المستحقات وتسويتها، دعم
/// Payouts عبر مزوّد مرخّص، عمولة 10% على المالك، إظهار السعر النهائي للضيف،
/// التسوية بعد انتهاء الإقامة، والدفع الأسبوعي.
///
/// كل هذا يحتاج تنفيذًا على السيرفر (لا يوجد أي endpoint للمحفظة أو الأرصدة).
/// ما هنا هو **الطبقة الحسابية والعرضية** فقط:
///   • نقرأ الأرقام من استجابة الـ API إن وُجدت، بلا اختراع أي رصيد.
///   • نحسب «القابل للتحويل» = الرصيد − المحجوز، ولا نسمح بقيمة سالبة.
///   • نبني حمولة طلب التحويل بحقول صريحة ومُختبَرة.
/// لا تُعرض أي عملية تحويل ناجحة قبل أن يؤكّدها السيرفر.
library;

import 'safe_parse.dart';

/// رصيد محفظة المالك كما يعيده الـ API. أي حقل غائب يبقى `null` لا صفرًا، حتى
/// نفرّق بين «الرصيد صفر» و«السيرفر لا يُعلن الرصيد».
class WalletBalance {
  final double? total;
  final double? commission;
  final double? expenses;
  final double? reserved;
  final double? withdrawable;

  const WalletBalance({
    this.total,
    this.commission,
    this.expenses,
    this.reserved,
    this.withdrawable,
  });

  /// هل يُعلن الـ API أي رقم على الأقل؟ إن لا، تُعرض حالة «غير متاح» بدل أصفار.
  bool get hasAnyValue =>
      total != null ||
      commission != null ||
      expenses != null ||
      reserved != null ||
      withdrawable != null;

  /// القابل للتحويل: نأخذ قيمة السيرفر إن أعلنها، وإلا نحسبها من الرصيد
  /// والمحجوز. لا تُرجع قيمة سالبة أبدًا (لا نعرض رصيدًا مستحقًا بالسالب).
  double? get computedWithdrawable {
    if (withdrawable != null) return withdrawable! < 0 ? 0 : withdrawable;
    if (total == null) return null;
    final base = total! - (reserved ?? 0) - (expenses ?? 0);
    return base < 0 ? 0 : base;
  }

  /// هل يوجد مبلغ قابل للتحويل فعلًا؟ يُستخدم لتعطيل زر الطلب بلا سبب.
  bool get canRequestTransfer {
    final amount = computedWithdrawable;
    return amount != null && amount > 0;
  }

  factory WalletBalance.fromMap(Map<String, dynamic>? map) {
    final d = map ?? const <String, dynamic>{};
    double? pick(List<String> keys) {
      for (final k in keys) {
        if (d[k] != null) return asDouble(d[k]);
      }
      return null;
    }

    return WalletBalance(
      total: pick(['balance', 'total_balance', 'wallet_balance']),
      commission: pick(['commission', 'commission_total']),
      expenses: pick(['expenses', 'expenses_total']),
      reserved: pick(['reserved', 'reserved_total', 'pending_total']),
      withdrawable: pick(['withdrawable', 'available', 'available_balance']),
    );
  }
}

/// سطر واحد في كشف حساب المحفظة (Ledger). النوع يُترجم عبر مفتاح نصي.
class WalletLedgerEntry {
  final String typeKey;
  final double amount;
  final String? date;
  final String? description;

  const WalletLedgerEntry({
    required this.typeKey,
    required this.amount,
    this.date,
    this.description,
  });

  /// يقرأ سطرًا من الـ API. السطر الذي بلا نوع معروف يُصنَّف `other` بدل
  /// إسقاطه أو اختلاق نوع له.
  factory WalletLedgerEntry.fromMap(Map<String, dynamic> map) {
    const known = {
      'booking': 'ledger_booking',
      'commission': 'ledger_commission',
      'refund': 'ledger_refund',
      'settlement': 'ledger_settlement',
      'payout': 'ledger_payout',
      'expense': 'ledger_expense',
      'subscription': 'ledger_subscription',
    };
    final rawType = asString(map['type'], 'other').toLowerCase();
    return WalletLedgerEntry(
      typeKey: known[rawType] ?? 'ledger_other',
      amount: asDouble(map['amount']),
      date: asStringOrNull(map['date'] ?? map['created_at']),
      description: asStringOrNull(map['description'] ?? map['note']),
    );
  }
}

/// يبني حمولة طلب تحويل المستحقات.
///
/// لا نحسب المبلغ في العميل ثم نرسله كحقيقة: نرسل **طلبًا** بالمبلغ المقترح،
/// والسيرفر هو من يتحقق من الرصيد الفعلي. المبلغ غير الصالح (صفر أو سالب أو
/// أكبر من القابل للتحويل) يُرفض محليًا قبل الإرسال.
Map<String, dynamic> buildTransferRequestPayload({
  required double amount,
  String? iban,
  String? note,
}) {
  final payload = <String, dynamic>{
    'action': 'request_transfer',
    'amount': amount,
  };
  final cleanIban = asStringOrNull(iban);
  if (cleanIban != null) payload['iban'] = cleanIban;
  final cleanNote = asStringOrNull(note);
  if (cleanNote != null) payload['note'] = cleanNote;
  return payload;
}

/// هل مبلغ طلب التحويل صالح مقابل الرصيد القابل للتحويل؟
///
/// يُستخدم لتعطيل الزر وإظهار سبب واضح. لا نسمح بمبلغ > القابل للتحويل، ولا
/// بمبلغ صفر أو سالب.
bool isValidTransferAmount(double? amount, WalletBalance balance) {
  if (amount == null || amount <= 0) return false;
  final available = balance.computedWithdrawable;
  if (available == null) return false;
  return amount <= available;
}
