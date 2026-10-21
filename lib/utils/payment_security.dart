/// أمان الدفع — منع مرور بيانات البطاقة الخام عبر خوادمنا.
///
/// كانت شاشة الحجز تجمع رقم البطاقة وتاريخ الانتهاء وCVV واسم الحامل وترسل
/// `card_number` إلى `bookings/create.php`. ذلك يُدخل المنصة في نطاق PCI-DSS
/// ويجعل الخادم يرى بيانات البطاقة الكاملة، وهو ما لا يجوز.
///
/// القاعدة الآن: لا يُرسل التطبيق أي حقل بطاقة إلى أي نقطة نهاية يملكها
/// التطبيق. الدفع الإلكتروني لا يعمل إلا عبر صفحة دفع مستضافة عند مزوّد مرخّص،
/// ويُفعَّل فقط عندما تُرجع الإعدادات عنوان تلك الصفحة. حتى ذلك الحين يظهر خيار
/// «الدفع الإلكتروني» معطّلًا مع سبب صريح، ولا نخترع نجاحًا وهميًا.
library;

/// إعداد صفحة الدفع المستضافة كما تُعلنها إعدادات الموقع (`content/settings.php`).
///
/// لا يوجد افتراضي ولا رابط مُخترع: إن لم تُرجع الإعدادات `checkout_url` صالحًا
/// فالقيمة `null`، ومعناها أن الدفع الإلكتروني غير مُفعَّل بعد.
class HostedCheckoutConfig {
  /// عنوان صفحة الدفع عند المزوّد المرخّص (يجب أن يكون https).
  final String checkoutUrl;

  /// اسم المزوّد للعرض فقط (مثل «Moyasar» أو «HyperPay») — قد يكون فارغًا.
  final String provider;

  const HostedCheckoutConfig({required this.checkoutUrl, this.provider = ''});

  /// هل الإعداد صالح للاستخدام؟ يجب أن يكون https ومطلقًا.
  bool get isUsable {
    final uri = Uri.tryParse(checkoutUrl);
    return uri != null && uri.isAbsolute && uri.scheme == 'https';
  }
}

/// يقرأ إعداد الدفع المستضاف من استجابة الإعدادات، أو `null` إن لم يكن مُعلنًا.
///
/// المفاتيح المقروءة: `payment_checkout_url` (إلزامي) و`payment_provider`
/// (اختياري). لا نُخمّن مزوّدًا ولا نبني رابطًا بأنفسنا.
HostedCheckoutConfig? resolveHostedCheckout(Map<String, dynamic>? settings) {
  final data = settings ?? const <String, dynamic>{};
  final raw = (data['payment_checkout_url'] ?? '').toString().trim();
  if (raw.isEmpty) return null;
  final cfg = HostedCheckoutConfig(
    checkoutUrl: raw,
    provider: (data['payment_provider'] ?? '').toString().trim(),
  );
  return cfg.isUsable ? cfg : null;
}

/// هل الرقم المحتمل يطابق خوارزمية Luhn (أي يبدو رقم بطاقة فعليًا)؟
///
/// تُستخدم كحاجز دفاع أخير: حتى لو أضاف أحدهم حقل بطاقة مستقبلًا، لا نسمح
/// بخروج قيمة تبدو كرقم بطاقة إلى السيرفر.
bool looksLikeCardNumber(String? value) {
  if (value == null) return false;
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 12 || digits.length > 19) return false;
  var sum = 0;
  var alternate = false;
  for (var i = digits.length - 1; i >= 0; i--) {
    var n = int.parse(digits[i]);
    if (alternate) {
      n *= 2;
      if (n > 9) n -= 9;
    }
    sum += n;
    alternate = !alternate;
  }
  return sum % 10 == 0;
}

/// أسماء الحقول التي لا يجوز أن تخرج من التطبيق أبدًا.
const Set<String> kForbiddenPaymentFields = {
  'card_number',
  'cardNumber',
  'cvv',
  'cvc',
  'card_cvv',
  'expiry',
  'expiry_date',
  'card_expiry',
  'cardholder_name',
  'card_holder',
  'pan',
};

/// يرجع أي مفتاح محظور أو قيمة تبدو كرقم بطاقة داخل جسم الطلب.
///
/// تُستدعى قبل الإرسال في `HotelService.createBooking`، وتُختبَر مباشرة. القائمة
/// الفارغة تعني أن الجسم نظيف.
List<String> findPaymentDataLeaks(Map<String, dynamic> payload) {
  final found = <String>[];
  for (final entry in payload.entries) {
    if (kForbiddenPaymentFields.contains(entry.key)) {
      found.add(entry.key);
      continue;
    }
    if (looksLikeCardNumber(entry.value?.toString())) {
      found.add(entry.key);
    }
  }
  return found;
}

/// مفتاح الترجمة لرسالة سبب تعطيل الدفع الإلكتروني.
const String kOnlinePaymentUnavailableKey = 'online_payment_unavailable';

/// مفتاح الترجمة لرسالة التوجيه إلى صفحة الدفع المستضافة.
const String kOnlinePaymentRedirectKey = 'online_payment_redirect_notice';

/// يبني رابط صفحة الدفع المستضافة مع رقم الحجز كمعامل استعلام.
///
/// المزوّد هو من يعرف مبلغ الحجز وبيانات العميل من جانبه بعد أن يتحقق من رقم
/// الحجز عند السيرفر؛ التطبيق لا يمرّر مبلغًا ولا بيانات بطاقة. نضيف `ref`
/// فقط. لا نضيف المبلغ لأن ذلك قابل للتلاعب من العميل.
Uri buildCheckoutUri(HostedCheckoutConfig config,
    {required String bookingRef}) {
  final base = Uri.parse(config.checkoutUrl);
  return base.replace(queryParameters: {
    ...base.queryParameters,
    'ref': bookingRef,
  });
}
