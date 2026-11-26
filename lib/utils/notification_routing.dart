/// توجيه الإشعارات ونصوصها (المستند 06 §D — الإشعارات المدفوعة).
///
/// كل ما هنا نقي وقابل للاختبار: تحويل حمولة الإشعار (FCM data payload) إلى
/// وجهة داخل التطبيق، وإلى عنوان ونص بالعربية والإنجليزية، وإلى قرار «هل
/// نُظهر هذا الإشعار؟». لا يوجد أي اتصال شبكي ولا أي إشعار مُختلق: إن لم تصل
/// حمولة حقيقية من الخادم فلا شيء يُعرض.
library;

import 'app_strings.dart';

/// الوجهات التي يمكن أن يفتحها الإشعار.
enum NotificationTarget {
  booking,
  serviceRequest,
  payment,
  wallet,
  subscription,
  none,
}

/// نوع الحدث كما يُرسله الخادم في `type` / `event` / `kind`.
enum NotificationEvent {
  bookingCreated,
  bookingConfirmed,
  bookingRejected,
  bookingCancelled,
  serviceRequestCreated,
  serviceRequestApproved,
  serviceRequestRejected,
  paymentReceived,
  paymentLinkIssued,
  unknown;

  /// هل هذا الحدث «موافقة» أم «رفض»؟ يُستخدم لاختيار أيقونة/لون فقط.
  bool get isApproval => this == NotificationEvent.serviceRequestApproved;
  bool get isRejection =>
      this == NotificationEvent.bookingRejected ||
      this == NotificationEvent.serviceRequestRejected;
}

/// يقرأ نوع الحدث من الحمولة دون اختلاق قيمة.
NotificationEvent parseNotificationEvent(Map<String, dynamic> data) {
  final raw = (data['event'] ?? data['type'] ?? data['kind'] ?? '')
      .toString()
      .trim()
      .toLowerCase();
  switch (raw) {
    case 'booking':
    case 'booking_created':
    case 'new_booking':
      return NotificationEvent.bookingCreated;
    case 'booking_confirmed':
      return NotificationEvent.bookingConfirmed;
    case 'booking_rejected':
      return NotificationEvent.bookingRejected;
    case 'booking_cancelled':
    case 'booking_canceled':
      return NotificationEvent.bookingCancelled;
    case 'service':
    case 'service_request':
    case 'service_request_created':
    case 'cleaning':
    case 'maintenance':
    case 'meal':
    case 'extra_bed':
      return NotificationEvent.serviceRequestCreated;
    case 'service_approved':
    case 'request_approved':
      return NotificationEvent.serviceRequestApproved;
    case 'service_rejected':
    case 'request_rejected':
      return NotificationEvent.serviceRequestRejected;
    case 'payment':
    case 'payment_received':
      return NotificationEvent.paymentReceived;
    case 'payment_link':
    case 'payment_link_issued':
      return NotificationEvent.paymentLinkIssued;
    default:
      return NotificationEvent.unknown;
  }
}

/// الوجهة التي يُفتحها الإشعار عند الضغط عليه.
NotificationTarget targetForEvent(NotificationEvent event) {
  switch (event) {
    case NotificationEvent.bookingCreated:
    case NotificationEvent.bookingConfirmed:
    case NotificationEvent.bookingRejected:
    case NotificationEvent.bookingCancelled:
      return NotificationTarget.booking;
    case NotificationEvent.serviceRequestCreated:
    case NotificationEvent.serviceRequestApproved:
    case NotificationEvent.serviceRequestRejected:
      return NotificationTarget.serviceRequest;
    case NotificationEvent.paymentReceived:
    case NotificationEvent.paymentLinkIssued:
      return NotificationTarget.payment;
    case NotificationEvent.unknown:
      return NotificationTarget.none;
  }
}

/// مفتاح عنوان الإشعار بالعربية/الإنجليزية حسب نوع الحدث.
String notificationTitleKey(NotificationEvent event) {
  switch (event) {
    case NotificationEvent.bookingCreated:
      return 'notif_booking_created';
    case NotificationEvent.bookingConfirmed:
      return 'notif_booking_confirmed';
    case NotificationEvent.bookingRejected:
      return 'notif_booking_rejected';
    case NotificationEvent.bookingCancelled:
      return 'notif_booking_cancelled';
    case NotificationEvent.serviceRequestCreated:
      return 'notif_service_created';
    case NotificationEvent.serviceRequestApproved:
      return 'notif_service_approved';
    case NotificationEvent.serviceRequestRejected:
      return 'notif_service_rejected';
    case NotificationEvent.paymentReceived:
      return 'notif_payment_received';
    case NotificationEvent.paymentLinkIssued:
      return 'notif_payment_link';
    case NotificationEvent.unknown:
      return 'notifications';
  }
}

/// النص المعروض: نُفضّل نص الخادم للغة الجهاز (`title_ar`/`title_en`،
/// `body_ar`/`body_en`)، ثم العنوان المترجم محليًا. لا نُنشئ نصًا بلا بيانات.
({String title, String body}) notificationTexts(
  Map<String, dynamic> data, {
  required bool isArabic,
}) {
  final event = parseNotificationEvent(data);
  String pick(String base) {
    final localized =
        (data['${base}_${isArabic ? 'ar' : 'en'}'] ?? '').toString().trim();
    if (localized.isNotEmpty) return localized;
    final generic = (data[base] ?? '').toString().trim();
    return generic;
  }

  final title = pick('title');
  final body = pick('body');
  return (
    title: title.isNotEmpty
        ? title
        : AppStrings.t(isArabic, notificationTitleKey(event)),
    body: body,
  );
}

/// مفتاح الشاشة داخل التطبيق (للاستخدام في `Navigator` أو في فتح تبويب).
String notificationRouteKey(NotificationEvent event) {
  switch (targetForEvent(event)) {
    case NotificationTarget.booking:
      return 'bookings';
    case NotificationTarget.serviceRequest:
      return 'requests';
    case NotificationTarget.payment:
      return 'payments';
    case NotificationTarget.wallet:
      return 'wallet';
    case NotificationTarget.subscription:
      return 'subscription';
    case NotificationTarget.none:
      return 'notifications';
  }
}

/// هل الحمولة تحمل معرّفًا حقيقيًا يمكن فتح تفاصيله؟
int? notificationEntityId(Map<String, dynamic> data) {
  for (final key in const [
    'booking_id',
    'request_id',
    'payment_id',
    'entity_id',
  ]) {
    final value = data[key];
    if (value == null) continue;
    final parsed = int.tryParse(value.toString().trim());
    if (parsed != null && parsed > 0) return parsed;
  }
  return null;
}

/// مفتاح إزالة التكرار: نفس الحدث لنفس الكيان لا يُعرض مرتين في الجلسة نفسها
/// (FCM قد يُسلّم الرسالة مرتين، خصوصًا عند تجديد الرمز).
String? notificationDedupeKey(Map<String, dynamic> data) {
  final event = parseNotificationEvent(data);
  final id = notificationEntityId(data);
  final messageId = (data['message_id'] ?? data['id'] ?? '').toString().trim();
  if (messageId.isNotEmpty) return 'msg:$messageId';
  if (id != null) return '${event.name}:$id';
  return null;
}
