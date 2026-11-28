/// خيارا سداد طلب خدمة عند تأكيده من لوحة الفندق (المتطلبات 10 و11 و12 من
/// المستند 06).
///
/// الطلبات الثلاثة — النظافة، الوجبات، السرير الإضافي — تشترك في نفس المسار:
///   1. خصم من الرصيد (`wallet_balance`).
///   2. الدفع عبر رابط بالواتساب (`whatsapp_link`).
///
/// القواعد المشتركة موجودة هنا مرة واحدة بدل تكرارها في كل شاشة:
///   - لا يُنشئ التطبيق رصيدًا ولا رابط دفع؛ الخصم يُنفَّذ على السيرفر ورابط
///     الدفع يُقرأ من استجابة السيرفر إن وُجد.
///   - لا يُرسل الطلب بلا سعر معتمد ولا بلا اختيار وسيلة.
///   - لا يُسوّى الطلب مرتين (منع الخصم المزدوج وطلب الدفع المكرر).
///   - التأكيد محصور بأدوار لوحة الفندق.
library;

import 'maintenance_settlement.dart' show normalizeWhatsAppPhone;

/// وسيلة سداد طلب خدمة.
enum RequestSettlement { walletBalance, whatsappLink }

/// القيمة المُرسلة للسيرفر في حقل `settlement`.
String requestSettlementPayload(RequestSettlement option) => switch (option) {
      RequestSettlement.walletBalance => 'wallet_balance',
      RequestSettlement.whatsappLink => 'whatsapp_link',
    };

/// مفتاح ترجمة اسم الوسيلة.
String requestSettlementLabelKey(RequestSettlement option) => switch (option) {
      RequestSettlement.walletBalance => 'settle_wallet_balance',
      RequestSettlement.whatsappLink => 'settle_whatsapp_pay_link',
    };

/// نوع الطلب الذي يُسوّى — يحدد مفاتيح الترجمة ورسالة السعر المفقود.
enum SettlementRequestKind { cleaning, meal, extraBed }

extension SettlementRequestKindKeys on SettlementRequestKind {
  /// مفتاح تسمية السعر المعتمد.
  String get priceLabelKey => switch (this) {
        SettlementRequestKind.cleaning => 'approved_housekeeping_price',
        SettlementRequestKind.meal => 'approved_meal_price',
        SettlementRequestKind.extraBed => 'approved_extra_bed_price',
      };

  /// مفتاح رسالة «لا يوجد سعر معتمد».
  String get priceMissingKey => switch (this) {
        SettlementRequestKind.cleaning => 'housekeeping_price_missing',
        SettlementRequestKind.meal => 'meal_price_missing',
        SettlementRequestKind.extraBed => 'extra_bed_price_missing',
      };
}

/// نوع الطلب كما يصل من السيرفر (`type`) إلى نوع التسوية، أو `null` إن كان
/// النوع لا يحتاج تسوية (الصيانة لها مسارها القائم).
SettlementRequestKind? settlementKindForRequestType(String? type) =>
    switch ((type ?? '').trim()) {
      'cleaning' => SettlementRequestKind.cleaning,
      'meal' => SettlementRequestKind.meal,
      'extra_bed' => SettlementRequestKind.extraBed,
      _ => null,
    };

/// السعر المعتمد للطلب كما وصل من السيرفر، أو `null` إن لم يُعتمد بعد.
double? approvedRequestPrice(Map<String, dynamic> request) {
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
bool isRequestSettlementRecorded(Map<String, dynamic> request) {
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

/// صلاحية تأكيد الطلب وتسجيل سداده — تُطابق صلاحيات لوحة الفندق.
bool canConfirmRequestSettlement(String? role) =>
    role == 'hotel_manager' || role == 'owner' || role == 'unit_manager';

/// يتحقق من اكتمال بيانات التأكيد. يُرجع مفتاح رسالة الخطأ أو `null`.
String? validateRequestSettlement({
  required Map<String, dynamic> request,
  required RequestSettlement? choice,
  required double? price,
  required bool canConfirm,
  required SettlementRequestKind kind,
}) {
  if (!canConfirm) return 'permission_denied';
  if (isRequestSettlementRecorded(request)) {
    return 'settlement_already_recorded';
  }
  if (price == null || price <= 0) return kind.priceMissingKey;
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

String _amountLabel(bool isArabic) => isArabic ? 'المبلغ' : 'Amount';
String _unitLabel(bool isArabic) => isArabic ? 'الوحدة' : 'Unit';

String _formatAmount(double amount) => amount == amount.roundToDouble()
    ? amount.toStringAsFixed(0)
    : amount.toStringAsFixed(2);

/// رابط واتساب لرسالة طلب سداد. يُضاف رابط الدفع إلى الرسالة فقط إن كان قد وصل
/// من السيرفر. غياب الرقم أو الرابط لا يُنتج رابطًا مكسورًا ولا مبلغًا وهميًا.
Uri? buildSettlementWhatsAppUri({
  required String? phone,
  required bool isArabic,
  required SettlementRequestKind kind,
  int? requestId,
  String? unitName,
  double? amount,
  String? paymentLink,
  List<String> details = const [],
}) {
  final normalized = normalizeWhatsAppPhone(phone);
  if (normalized == null) return null;

  final lines = <String>[
    isArabic ? _waTitleAr(kind) : _waTitleEn(kind),
  ];
  if (requestId != null) {
    lines.add(isArabic ? 'رقم الطلب: $requestId' : 'Request #$requestId');
  }
  final unit = (unitName ?? '').trim();
  if (unit.isNotEmpty) lines.add('${_unitLabel(isArabic)}: $unit');
  for (final detail in details) {
    final text = detail.trim();
    if (text.isNotEmpty) lines.add(text);
  }
  if (amount != null && amount > 0) {
    lines.add('${_amountLabel(isArabic)}: ${_formatAmount(amount)} SAR');
  }
  final link = (paymentLink ?? '').trim();
  if (link.isNotEmpty) lines.add(link);

  return Uri.parse('https://wa.me/$normalized').replace(
    queryParameters: {'text': lines.join('\n')},
  );
}

String _waTitleAr(SettlementRequestKind kind) => switch (kind) {
      SettlementRequestKind.cleaning => 'طلب سداد تكلفة نظافة',
      SettlementRequestKind.meal => 'طلب سداد تكلفة وجبات',
      SettlementRequestKind.extraBed => 'طلب سداد تكلفة سرير إضافي',
    };

String _waTitleEn(SettlementRequestKind kind) => switch (kind) {
      SettlementRequestKind.cleaning => 'Housekeeping payment request',
      SettlementRequestKind.meal => 'Meal payment request',
      SettlementRequestKind.extraBed => 'Extra bed payment request',
    };

/// أسماء الوجبات في الطلب كما أرسلها السيرفر — تُعرض كما هي إن لم تكن معروفة.
///
/// المصادر المقروءة: `meal_types` (قائمة أو نص مفصول بفواصل)، `meals`
/// (قائمة كائنات فيها اسم الوجبة)، ثم `meal_type`. لا تُختلق وجبة غير موجودة.
List<String> requestMealLabels(Map<String, dynamic> request) {
  final labels = <String>[];
  void add(Object? raw) {
    final text = (raw ?? '').toString().trim();
    if (text.isEmpty) return;
    for (final part in text.split(RegExp(r'[,،|]'))) {
      final value = part.trim();
      if (value.isEmpty) continue;
      if (!labels.any((e) => e.toLowerCase() == value.toLowerCase())) {
        labels.add(value);
      }
    }
  }

  final types = request['meal_types'];
  if (types is List) {
    for (final item in types) {
      add(item);
    }
  } else {
    add(types);
  }
  final meals = request['meals'];
  if (meals is List) {
    for (final item in meals) {
      if (item is Map) {
        add(item['name_ar'] ?? item['name'] ?? item['title'] ?? item['meal']);
      } else {
        add(item);
      }
    }
  }
  add(request['meal_type']);
  return labels;
}

/// مفتاح الترجمة لاسم وجبة معروف، أو `null` إن كان الاسم من السيرفر كما هو.
String? mealLabelKey(String label) {
  switch (label.trim().toLowerCase()) {
    case 'breakfast':
    case 'فطور':
      return 'meal_breakfast';
    case 'lunch':
    case 'غداء':
      return 'meal_lunch';
    case 'dinner':
    case 'عشاء':
      return 'meal_dinner';
    case 'all':
    case 'all meals':
    case 'جميع الوجبات':
      return 'meal_option_all';
  }
  return null;
}

int? _asPositiveInt(Object? raw) {
  final value =
      raw is num ? raw.toInt() : int.tryParse(raw?.toString().trim() ?? '');
  return value != null && value > 0 ? value : null;
}

/// عدد الأسرّة الإضافية المطلوبة كما ورد في الطلب، أو `null` إن لم يصل.
int? extraBedCount(Map<String, dynamic> request) {
  for (final key in [
    'beds',
    'extra_beds',
    'beds_count',
    'quantity',
    'qty',
    'count',
  ]) {
    final value = _asPositiveInt(request[key]);
    if (value != null) return value;
  }
  return null;
}

/// عدد الليالي: من الطلب إن أرسله السيرفر، وإلا محسوبًا من تاريخي الوصول
/// والمغادرة الحقيقيين، وإلا `null`.
int? extraBedNights(Map<String, dynamic> request) {
  for (final key in ['nights', 'nights_count', 'duration']) {
    final value = _asPositiveInt(request[key]);
    if (value != null) return value;
  }
  final checkIn = DateTime.tryParse((request['check_in'] ?? '').toString());
  final checkOut = DateTime.tryParse((request['check_out'] ?? '').toString());
  if (checkIn == null || checkOut == null) return null;
  final nights = checkOut.difference(checkIn).inDays;
  return nights > 0 ? nights : null;
}

/// إجمالي تكلفة السرير الإضافي.
///
/// الأولوية لإجمالي السيرفر (`total` / `total_price`, مع `approved_price`/
/// `cost` كسعر السطر إن جاءا معًا). وإلا يُحسب من السعر المعتمد × عدد الأسرّة
/// × عدد الليالي حين تكون القيم الثلاث كلها حقيقية. أي قيمة ناقصة تُرجع `null`
/// بدل اختلاق رقم.
double? extraBedTotal(Map<String, dynamic> request, double? approvedPrice) {
  for (final key in ['total', 'grand_total']) {
    final raw = request[key];
    if (raw == null) continue;
    final value =
        raw is num ? raw.toDouble() : double.tryParse(raw.toString().trim());
    if (value != null && value > 0) return value;
  }
  final explicitTotal = request['total_price'];
  if (explicitTotal != null &&
      !request.containsKey('price') &&
      !request.containsKey('approved_price') &&
      !request.containsKey('cost')) {
    final value = explicitTotal is num
        ? explicitTotal.toDouble()
        : double.tryParse(explicitTotal.toString().trim());
    if (value != null && value > 0) return value;
  }
  if (approvedPrice == null || approvedPrice <= 0) return null;
  final beds = extraBedCount(request);
  final nights = extraBedNights(request);
  if (beds == null || nights == null) return null;
  return approvedPrice * beds * nights;
}
