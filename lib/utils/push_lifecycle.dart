import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';

export '../services/notification_service.dart' show PushRegistrationResult;
import 'notification_routing.dart';
import 'safe_parse.dart';

/// دورة حياة إشعارات الدفع على جهاز المستخدم (القسم 10 من موجز القبول).
///
/// قبل هذا الملف كانت `NotificationService` موجودة ومُختبَرة لكن **لا شيء
/// يستدعيها**: لا تسجيل عند الدخول، لا إلغاء عند الخروج، لا معالجة لتجديد
/// الرمز، ولا ربط لضغطات الإشعارات. هذا الملف هو الطبقة التي تربطها فعليًا:
///
///   • `onLogin`   — يطلب الإذن ويسجّل الرمز، ويحفظه محليًا فقط إذا نجح.
///   • `onTokenRefresh` — يرسل الجديد ويُبطل القديم على الخادم قبل استبداله.
///   • `onLogout`  — يُلغي تسجيل الرمز المحفوظ ويمسحه.
///   • `start`     — يربط بثّ المزوّد: رسائل المقدمة وضغطات الإشعارات.
///
/// لا يُختلق أي نجاح: كل نتيجة تعود من الخدمة كما هي، ورمز لم يوافق عليه
/// الخادم لا يُحفظ، فلا يُلغى لاحقًا رمز لم يُسجَّل.
class PushLifecycle {
  PushLifecycle(
      {NotificationService? service, Future<SharedPreferences>? prefs})
      : _service = service ?? NotificationService(),
        _prefs = prefs ?? SharedPreferences.getInstance();

  static const tokenKey = 'push_device_token';

  final NotificationService _service;
  final Future<SharedPreferences> _prefs;

  StreamSubscription<String>? _refreshSub;
  StreamSubscription<Map<String, dynamic>>? _tapSub;
  StreamSubscription<Map<String, dynamic>>? _inAppSub;

  PushRegistrationResult? lastResult;
  String? lastReason;

  /// التخزين المحلي ليس شرطًا لعمل الإشعارات: غيابه (كاختبار بلا إضافات
  /// منصّة) لا يجوز أن يُسقط تسجيل الدخول أو الخروج.
  Future<SharedPreferences?> _prefsOrNull() async {
    try {
      return await _prefs;
    } catch (_) {
      return null;
    }
  }

  bool get isConfigured => _service.isConfigured;

  /// الرمز المسجَّل على الخادم حاليًا (من التخزين المحلي).
  Future<String?> storedToken() async => (await _prefs).getString(tokenKey);

  Future<PushRegistrationResult> onLogin({required String locale}) async {
    final result = await _service.register(locale: locale);
    lastResult = result;
    lastReason = result.registered ? null : result.reason;
    if (result.registered) {
      final token = await _service.currentProviderToken();
      if (token != null) {
        await (await _prefsOrNull())?.setString(tokenKey, token);
      }
    }
    return result;
  }

  /// تجديد الرمز: يُبطل القديم على الخادم أولًا ثم يسجّل الجديد.
  Future<PushRegistrationResult> onTokenRefresh(String token,
      {required String locale}) async {
    final prefs = await _prefsOrNull();
    final previous = prefs?.getString(tokenKey);
    if (previous != null && previous != token.trim()) {
      await _service.unregister(token: previous);
    }
    final result = await _service.refreshToken(token, locale: locale);
    lastResult = result;
    lastReason = result.registered ? null : result.reason;
    if (result.registered) {
      await prefs?.setString(tokenKey, token.trim());
    }
    return result;
  }

  Future<void> onLogout() async {
    final prefs = await _prefsOrNull();
    final token = prefs?.getString(tokenKey);
    if (token != null && token.isNotEmpty) {
      await _service.unregister(token: token);
    }
    await prefs?.remove(tokenKey);
    lastResult = null;
    lastReason = null;
  }

  /// يبدأ الاستماع لبثّ المزوّد. بلا مزوّد مهيّأ تبقى البثوث فارغة، فلا أثر.
  void start({
    void Function(Map<String, dynamic> data)? onForeground,
    void Function(NotificationEvent event, Map<String, dynamic> data)? onTap,
  }) {
    _service.attach();
    _refreshSub ??= _service.tokenRefreshes.listen((token) async {
      await onTokenRefresh(token, locale: await storedLocale());
    });
    _tapSub ??= _service.onNotificationTap.listen((data) {
      final event = parseNotificationEvent(data);
      onTap?.call(event, data);
    });
    if (onForeground != null) {
      _inAppSub ??= _service.inAppMessages.listen(onForeground);
    }
  }

  /// حمولة تعريفية لاختبارات العقد (رمز + منصة + لغة فقط).
  Map<String, dynamic> payloadFor(String token, {required String locale}) =>
      _service.tokenPayload(token, locale: locale);

  Future<void> dispose() async {
    await _refreshSub?.cancel();
    await _tapSub?.cancel();
    await _inAppSub?.cancel();
    _refreshSub = null;
    _tapSub = null;
    _inAppSub = null;
  }
}

/// يقرأ اللغة المحفوظة كي يُرسل الرمز مع لغة الجهاز الفعلية.
Future<String> storedLocale() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return asStringOrNull(prefs.getString('app_locale')) ?? 'ar';
  } catch (_) {
    return 'ar';
  }
}
