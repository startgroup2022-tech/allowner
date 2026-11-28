/// إتاحة وسائل الدفع كما يعلنها السيرفر (المتطلبان 7 و8 من المستند 06).
///
/// القاعدة: السيرفر هو المرجع الوحيد. التطبيق لا يُفعّل وسيلة دفع من عنده، ولا
/// يعرض وسيلة أوقفتها الإدارة، ولا يرسل وسيلة معطّلة في طلب الحجز.
///
/// الحالة الافتراضية عند غياب الإعداد (أو غياب المفتاح):
///   - «الدفع عند الوصول» (`at_hotel`): معطّل.
///   - «التحويل المباشر للمالك» (`owner_transfer`): معطّل.
///   - «الدفع الإلكتروني» (`online`): معطّل حتى يُعلن السيرفر رابط صفحة دفع
///     مستضافة عبر HTTPS (`payment_checkout_url`). لا دفع إلكتروني غير مُتحقَّق.
///
/// الصيغ المقروءة من `content/settings.php` (كلها اختيارية):
/// ```json
/// { "payment_methods": { "online": true, "at_hotel": false, "owner_transfer": false } }
/// ```
/// أو مسطّحة:
/// `payment_online_enabled`, `payment_at_hotel_enabled`,
/// `payment_owner_transfer_enabled`.
library;

import 'payment_security.dart';

/// وسائل الدفع التي يفهمها التطبيق — القيم تطابق حقل `payment_method` في
/// `POST /bookings/create.php`.
enum PaymentMethodKey { online, atHotel, ownerTransfer }

extension PaymentMethodKeyWire on PaymentMethodKey {
  /// القيمة المرسلة للسيرفر.
  String get wireName => switch (this) {
        PaymentMethodKey.online => 'online',
        PaymentMethodKey.atHotel => 'at_hotel',
        PaymentMethodKey.ownerTransfer => 'owner_transfer',
      };

  /// مفتاح الترجمة لاسم الوسيلة.
  String get labelKey => switch (this) {
        PaymentMethodKey.online => 'pay_online',
        PaymentMethodKey.atHotel => 'pay_at_hotel',
        PaymentMethodKey.ownerTransfer => 'pay_owner_transfer',
      };
}

/// نتيجة قراءة إعدادات وسائل الدفع.
class PaymentMethodAvailability {
  const PaymentMethodAvailability({
    required this.enabled,
    this.onlineCheckout,
  });

  /// الوسائل التي سمح بها السيرفر فعلًا.
  final Set<PaymentMethodKey> enabled;

  /// إعداد صفحة الدفع المستضافة عند المزوّد — `null` يعني غير مُفعَّل.
  final HostedCheckoutConfig? onlineCheckout;

  bool isEnabled(PaymentMethodKey method) => enabled.contains(method);

  /// هل توجد وسيلة واحدة على الأقل يمكن للضيف اختيارها؟
  bool get hasAny => enabled.isNotEmpty;

  /// الوسائل المتاحة بترتيب العرض الثابت.
  List<PaymentMethodKey> get available =>
      PaymentMethodKey.values.where(enabled.contains).toList();

  /// الوسيلة الافتراضية — أول وسيلة متاحة، أو `null` إن لم توجد.
  PaymentMethodKey? get defaultMethod {
    final list = available;
    return list.isEmpty ? null : list.first;
  }
}

bool? _parseBool(Object? raw) {
  if (raw is bool) return raw;
  if (raw is num) return raw != 0;
  if (raw is String) {
    switch (raw.trim().toLowerCase()) {
      case '1':
      case 'true':
      case 'yes':
      case 'on':
      case 'enabled':
        return true;
      case '0':
      case 'false':
      case 'no':
      case 'off':
      case 'disabled':
        return false;
    }
  }
  return null;
}

/// يقرأ علم وسيلة واحدة: خريطة `payment_methods` أولًا ثم المفتاح المسطّح.
bool? _readDeclaredFlag(Map<String, dynamic> data, PaymentMethodKey method) {
  final nested = data['payment_methods'];
  if (nested is Map) {
    final parsed = _parseBool(nested[method.wireName]);
    if (parsed != null) return parsed;
  }
  if (nested is List) {
    final names = nested.map((e) => e.toString().trim()).toSet();
    if (names.isNotEmpty) return names.contains(method.wireName);
  }
  return _parseBool(data['payment_${method.wireName}_enabled']);
}

/// يبني حالة إتاحة وسائل الدفع من استجابة الإعدادات.
///
/// لا يُفعّل الدفع الإلكتروني إلا إذا أعلن السيرفر رابط صفحة دفع مستضافة صالحًا
/// (`https` مطلق)، حتى لو حاول أحدهم تفعيله بعلم فقط.
PaymentMethodAvailability resolvePaymentMethods(
    Map<String, dynamic>? settings) {
  final data = settings ?? const <String, dynamic>{};
  final checkout = resolveHostedCheckout(data);

  final enabled = <PaymentMethodKey>{};
  if (checkout != null &&
      _readDeclaredFlag(data, PaymentMethodKey.online) != false) {
    enabled.add(PaymentMethodKey.online);
  }
  if (_readDeclaredFlag(data, PaymentMethodKey.atHotel) == true) {
    enabled.add(PaymentMethodKey.atHotel);
  }
  if (_readDeclaredFlag(data, PaymentMethodKey.ownerTransfer) == true) {
    enabled.add(PaymentMethodKey.ownerTransfer);
  }

  return PaymentMethodAvailability(
    enabled: enabled,
    onlineCheckout: checkout,
  );
}

/// هل تُقبل هذه الوسيلة الآن؟ يُرجع مفتاح رسالة الرفض أو `null` إن كانت متاحة.
///
/// تُستدعى قبل الإرسال مباشرة، فلا يخرج طلب حجز بوسيلة أوقفتها الإدارة.
String? paymentMethodBlockReason(
  PaymentMethodAvailability availability,
  String? wireMethod,
) {
  final method = PaymentMethodKey.values
      .where((m) => m.wireName == wireMethod)
      .firstOrNull;
  if (method == null) return 'payment_method_unavailable';
  return availability.isEnabled(method) ? null : 'payment_method_unavailable';
}
