import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';
import 'notification_routing.dart';
import 'safe_parse.dart';

export '../services/notification_service.dart' show PushRegistrationResult;

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
  static const tokenUserKey = 'push_device_token_user';

  /// رمز تعذّر إلغاؤه على الخادم؛ يبقى هنا حتى يُلغى فعلًا.
  static const pendingUnregisterKey = 'push_pending_unregister';

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
  Future<String?> storedToken() async =>
      (await _prefsOrNull())?.getString(tokenKey);

  /// معرّف الحساب الذي يملك الرمز المحفوظ.
  Future<String?> storedTokenOwner() async =>
      (await _prefsOrNull())?.getString(tokenUserKey);

  /// رمز بانتظار إلغاء تسجيله على الخادم (فشل سابقًا).
  Future<String?> pendingUnregister() async =>
      (await _prefsOrNull())?.getString(pendingUnregisterKey);

  /// يُلغي الرمز ويحتفظ به «معلّقًا» عند الفشل كي يُعاد لاحقًا.
  Future<bool> _unregisterWithRecovery(String token) async {
    final prefs = await _prefsOrNull();
    final ok = await _service.unregister(token: token);
    if (ok) {
      if (prefs?.getString(pendingUnregisterKey) == token) {
        await prefs?.remove(pendingUnregisterKey);
      }
      return true;
    }
    await prefs?.setString(pendingUnregisterKey, token);
    return false;
  }

  /// يعيد محاولة إلغاء أي رمز معلّق (عند الإقلاع أو قبل تسجيل جديد).
  Future<bool> flushPendingUnregister() async {
    final prefs = await _prefsOrNull();
    final token = prefs?.getString(pendingUnregisterKey);
    if (token == null || token.isEmpty) return true;
    final ok = await _service.unregister(token: token);
    if (ok) await prefs?.remove(pendingUnregisterKey);
    return ok;
  }

  /// تسجيل الجهاز لحساب دخل للتوّ.
  ///
  /// تبديل الحساب على نفس الجهاز: الرمز نفسه قد يخصّ حسابًا سابقًا، فالسيرفر
  /// يجب أن يعيد إسناده لا أن يضيف صفًا ثانيًا. لذلك نُبطل الرمز المحفوظ أولًا
  /// إذا كان يخصّ حسابًا آخر أو جهازًا سابقًا (رمز مختلف عن رمز المزوّد الآن).
  Future<PushRegistrationResult> onLogin(
      {required String locale, String? userId}) async {
    final prefs = await _prefsOrNull();
    await flushPendingUnregister();

    final previousToken = prefs?.getString(tokenKey);
    final previousOwner = prefs?.getString(tokenUserKey);
    final providerToken = await _service.currentProviderToken();
    final ownerChanged =
        previousOwner != null && userId != null && previousOwner != userId;
    final tokenReplaced = previousToken != null &&
        providerToken != null &&
        previousToken != providerToken;

    if (previousToken != null &&
        previousToken.isNotEmpty &&
        (ownerChanged || tokenReplaced)) {
      await _unregisterWithRecovery(previousToken);
      await prefs?.remove(tokenKey);
      await prefs?.remove(tokenUserKey);
    }

    final result = await _service.register(locale: locale);
    lastResult = result;
    lastReason = result.registered ? null : result.reason;
    if (result.registered) {
      final token = await _service.currentProviderToken();
      if (token != null) {
        await prefs?.setString(tokenKey, token);
        if (userId != null) {
          await prefs?.setString(tokenUserKey, userId);
        } else {
          await prefs?.remove(tokenUserKey);
        }
      }
    }
    return result;
  }

  /// تجديد الرمز: يُبطل القديم على الخادم أولًا ثم يسجّل الجديد.
  /// تجديد الرمز: يُبطل القديم على الخادم أولًا ثم يسجّل الجديد.
  ///
  /// إن فشل إلغاء القديم يبقى محفوظًا في «المعلّق» كي يُعاد لاحقًا؛ وإلا صار
  /// الجهاز يستقبل إشعارات الحساب نفسه مرتين على رمزين.
  Future<PushRegistrationResult> onTokenRefresh(String token,
      {required String locale}) async {
    final prefs = await _prefsOrNull();
    final previous = prefs?.getString(tokenKey);
    if (previous != null && previous != token.trim()) {
      await _unregisterWithRecovery(previous);
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
      // عند الفشل يبقى الرمز معلّقًا ويُعاد عند أول إقلاع/دخول تالٍ.
      await _unregisterWithRecovery(token);
    }
    await prefs?.remove(tokenKey);
    await prefs?.remove(tokenUserKey);
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
