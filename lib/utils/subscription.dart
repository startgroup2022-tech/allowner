/// اشتراك المالك السنوي (المتطلبات 121–125).
///
/// المستند يطلب أن يكون الاشتراك السنوي للمالك فقط، وأن يستطيع المالك غير
/// المشترك الاستعراض دون تنفيذ عمليات، وأن يُمنع من إضافة الوحدات والطلبات حتى
/// يُفعّل الاشتراك، مع صفحة تفعيل/دفع، وعرض شروط الاشتراك ونسبة العمولة.
///
/// لا يوجد على السيرفر أي endpoint للاشتراك، لذلك كل ما هنا **قراءة من
/// الإعدادات** (`content/settings.php`) و**حساب محلي شفّاف**: لا نُخترع حالة
/// اشتراك ولا مبلغًا. إن لم تُعلن الإعدادات نسبة العمولة تبقى `null` وتُعرض
/// رسالة «غير معلنة» بدل رقم مُخترع.
library;

import 'safe_parse.dart';

/// حالة اشتراك المالك كما تُعلنها الإعدادات أو استجابة الملف الشخصي.
class SubscriptionState {
  /// هل الاشتراك مُفعَّل؟ لا افتراضي «مُفعَّل» ولا «غير مُفعَّل» بلا دليل:
  /// غياب الحقل يعني `unknown`، ويُعامل في الواجهة كاستعراض-فقط احتياطًا.
  final bool? active;

  /// تاريخ انتهاء الاشتراك إن أُعلن (نص حر كما يرد من السيرفر).
  final String? expiresAt;

  /// نسبة عمولة المنصة على المالك (مثل 10 تعني 10%).
  final double? commissionPercent;

  /// رسم الاشتراك السنوي إن أُعلن.
  final double? annualFee;

  /// عملة الرسم كما ترد من السيرفر (افتراضيًا ريال).
  final String currency;

  const SubscriptionState({
    this.active,
    this.expiresAt,
    this.commissionPercent,
    this.annualFee,
    this.currency = 'SAR',
  });

  /// هل نعرف حالة الاشتراك يقينًا؟
  bool get isKnown => active != null;

  /// هل يُسمح بعمليات الكتابة (إضافة وحدة/طلب)؟
  ///
  /// القاعدة: لا نسمح إلا إذا أكّد السيرفر أن الاشتراك مُفعَّل. حالة «غير
  /// معروفة» تُمنع احتياطًا حتى لا يبني مالك غير مشترك بيانات ثم تُرفض.
  bool get canPerformOperations => active == true;

  /// هل نعرف **يقينًا** أن الاشتراك غير مُفعَّل؟
  ///
  /// تُستخدم كحاجز واجهة غير مُدمِّر: نحجب العملية فقط عند تأكيد السيرفر أن
  /// الاشتراك غير مُفعَّل. حالة «غير معروفة» تمرّ ولا تُحجب، حتى لا نكسر تدفّق
  /// إضافة الوحدات العامل (السيرفر يفرض القيد عبر `can_create`).
  bool get isExplicitlyInactive => active == false;

  /// هل المالك في وضع الاستعراض فقط؟
  bool get isBrowseOnly => active != true;

  /// يقرأ الحالة من خريطة إعدادات/ملف شخصي. المفاتيح المقروءة صريحة، ولا
  /// يوجد تخمين لأسماء بديلة لتجنّب قراءة قيمة خاطئة على أنها اشتراك.
  factory SubscriptionState.fromMap(Map<String, dynamic>? map) {
    final data = map ?? const <String, dynamic>{};

    bool? active;
    final rawActive = data['subscription_active'];
    if (rawActive != null) active = asBool(rawActive);

    final percent = data['commission_percent'] ?? data['commission_rate'];

    return SubscriptionState(
      active: active,
      expiresAt: asStringOrNull(data['subscription_expires_at']),
      commissionPercent: percent == null ? null : asDouble(percent),
      annualFee: data['subscription_annual_fee'] == null
          ? null
          : asDouble(data['subscription_annual_fee']),
      currency: asString(data['currency'], 'SAR'),
    );
  }
}

/// نص حالة الاشتراك المعروض. يُرجع مفتاح ترجمة لا نصًا جاهزًا حتى يبقى
/// الاستدعاء على `AppStrings`.
String subscriptionStatusKey(SubscriptionState state) {
  if (state.active == true) return 'subscription_active';
  if (state.active == false) return 'subscription_inactive';
  return 'subscription_unknown';
}

/// يبني رسالة منع العملية عند كون المالك غير مشترك.
///
/// تُستخدم في شاشة إضافة الوحدة وأي إجراء كتابي. تُرجع `null` عندما يُسمح
/// بالعملية، فلا يُعرض تحذير بلا سبب.
String? subscriptionBlockMessageKey(SubscriptionState state) =>
    state.canPerformOperations ? null : 'subscription_required_to_operate';

/// يتحقق من صحة مبلغ الاشتراك قبل عرض زر الدفع.
///
/// لا نبني رابط دفع ولا نُخترع سعرًا: إن لم يُعلن السيرفر الرسم (`annualFee`
/// == null) نُعيد `false` فتظهر حالة «الرسم غير معلن» بدل مبلغ وهمي.
bool canPaySubscription(SubscriptionState state) =>
    state.annualFee != null && state.annualFee! > 0;
