import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'notification_service.dart';

/// معالج رسائل الخلفية — يجب أن يكون دالة عليا ومُعلَّمة بـ`vm:entry-point`
/// كي يستدعيه محرّك فلاتر في isolate منفصل والتطبيق مُصغَّر أو مغلق.
///
/// لا يعرض شيئًا بنفسه: رسالة خلفية تحمل مقطع `notification` يعرضها نظام
/// التشغيل. الرسالة التي تحمل `data` فقط تحتاج إشعارًا محليًا (قناة أندرويد +
/// `flutter_local_notifications`)، وهو متطلب منصّة موثَّق في
/// `docs/FIREBASE_SETUP_REQUIREMENTS.md` ولم يُضَف بعد.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // التسجيل نفسه هو المطلوب: بدونه لا يستيقظ التطبيق لرسائل data-only ولا
  // تصل ضغطة الإشعار من حالة الإغلاق الكامل.
}

/// المزوّد الحقيقي المبني على `firebase_messaging`.
///
/// لا شيء هنا يعمل قبل `Firebase.initializeApp` بمشروع حقيقي: [isConfigured]
/// يقرأ `Firebase.apps` فيرجع false إن لم يُهيَّأ، فتبقى كل المسارات صامتة كما
/// في [UnavailablePushProvider] — بلا رمز مُختلق ولا ادّعاء تسجيل.
///
/// ملاحظة إصدار: `firebase_messaging` 17 أزال `getToken()` وأحلّ محله
/// `register()` + `onRegistered`، وقيمة التسجيل صارت معرّف التثبيت (FID) الذي
/// يُستخدم هدفًا للإرسال المباشر. الخادم يتعامل مع القيمة كما هي.
class FirebasePushProvider implements PushProvider {
  FirebasePushProvider({
    FirebaseMessaging? messaging,
    Stream<RemoteMessage>? foreground,
    Stream<RemoteMessage>? opened,
    Future<RemoteMessage?> Function()? initialMessage,
    bool? configured,
  })  : _injected = messaging,
        _foregroundOverride = foreground,
        _openedOverride = opened,
        _initialMessage = initialMessage,
        _configuredOverride = configured;

  final FirebaseMessaging? _injected;
  FirebaseMessaging? _resolved;
  final Stream<RemoteMessage>? _foregroundOverride;
  final Stream<RemoteMessage>? _openedOverride;
  final Future<RemoteMessage?> Function()? _initialMessage;
  final bool? _configuredOverride;

  final StreamController<Map<String, dynamic>> _taps =
      StreamController<Map<String, dynamic>>.broadcast();
  StreamSubscription<RemoteMessage>? _openedSub;
  StreamSubscription<String>? _registeredSub;
  String? _lastToken;
  bool _listening = false;

  /// الوصول إلى `FirebaseMessaging.instance` يرمي إن لم يُهيَّأ Firebase،
  /// لذلك يُجلب بكسل وبلا استثناء يصل للواجهة.
  FirebaseMessaging? get _messaging {
    if (_injected != null) return _injected;
    if (_resolved != null) return _resolved;
    try {
      return _resolved = FirebaseMessaging.instance;
    } catch (_) {
      return null;
    }
  }

  /// هل يوجد مشروع Firebase مُهيَّأ فعلًا على هذا الجهاز؟
  @override
  bool get isConfigured {
    if (_configuredOverride != null) return _configuredOverride;
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<PushPermission> requestPermission() async {
    final messaging = _messaging;
    if (!isConfigured || messaging == null) return PushPermission.unavailable;
    try {
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      return mapAuthorizationStatus(settings.authorizationStatus);
    } catch (_) {
      return PushPermission.unavailable;
    }
  }

  /// تحويل حالة إذن Firebase إلى حالة التطبيق. دالة نقية كي تُختبر مباشرة.
  static PushPermission mapAuthorizationStatus(AuthorizationStatus status) {
    switch (status) {
      case AuthorizationStatus.authorized:
      case AuthorizationStatus.provisional:
        return PushPermission.granted;
      case AuthorizationStatus.denied:
      case AuthorizationStatus.deniedPermanently:
        return PushPermission.denied;
      case AuthorizationStatus.notDetermined:
        return PushPermission.notDetermined;
    }
  }

  @override
  Future<String?> currentToken() async {
    final messaging = _messaging;
    if (!isConfigured || messaging == null) return null;
    final cached = _lastToken;
    if (cached != null && cached.isNotEmpty) return cached;
    _listenRegistered();
    try {
      await messaging.register();
      final fresh = await messaging.onRegistered.first
          .timeout(const Duration(seconds: 5));
      if (fresh.trim().isNotEmpty) _lastToken = fresh.trim();
    } catch (_) {
      // بلا تسجيل فعلي لا رمز: لا نخترع قيمة.
    }
    final value = _lastToken;
    return (value == null || value.isEmpty) ? null : value;
  }

  void _listenRegistered() {
    final messaging = _messaging;
    if (messaging == null) return;
    _registeredSub ??= messaging.onRegistered.listen((value) {
      final clean = value.trim();
      if (clean.isNotEmpty) _lastToken = clean;
    }, onError: (_) {});
  }

  @override
  Stream<String> get onTokenRefresh {
    final messaging = _messaging;
    if (!isConfigured || messaging == null) return const Stream.empty();
    _listenRegistered();
    return messaging.onRegistered.where((t) => t.trim().isNotEmpty);
  }

  @override
  Stream<Map<String, dynamic>> get onForegroundMessage {
    final source = _foregroundOverride ??
        (isConfigured ? FirebaseMessaging.onMessage : null);
    if (source == null) return const Stream.empty();
    // الرسالة الأمامية يعرضها التطبيق بواجهته، لا نظام التشغيل: نُطفئ التنبيه
    // الأمامي كي لا تظهر مرتين.
    if (_foregroundOverride == null && isConfigured) {
      _messaging?.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: true,
        sound: false,
      );
    }
    return source.map(dataOf);
  }

  /// ضغطات الإشعارات: من الخلفية (`onMessageOpenedApp`) ومن حالة الإغلاق
  /// الكامل (`getInitialMessage`، تُقرأ مرة واحدة عند أول استماع).
  @override
  Stream<Map<String, dynamic>> get onNotificationTap {
    final source = _openedOverride ??
        (isConfigured ? FirebaseMessaging.onMessageOpenedApp : null);
    if (source == null) return const Stream.empty();
    _startTapListening(source);
    return _taps.stream;
  }

  void _startTapListening(Stream<RemoteMessage> opened) {
    if (_listening) return;
    _listening = true;
    _openedSub = opened.listen((m) => _taps.add(dataOf(m)), onError: (_) {});
    final read = _initialMessage ??
        (isConfigured ? _messaging?.getInitialMessage : null);
    read?.call().then((m) {
      if (m != null) _taps.add(dataOf(m));
    }).catchError((_) {});
  }

  /// يحوّل رسالة Firebase إلى حمولة التطبيق: `data` كما هي، مع تعبئة العنوان
  /// والنص ومعرّف الرسالة من مقطع `notification` إن لم يرسلها السيرفر.
  static Map<String, dynamic> dataOf(RemoteMessage message) {
    final map = Map<String, dynamic>.from(message.data);
    final title = message.notification?.title;
    if (title != null && !map.containsKey('title')) map['title'] = title;
    final body = message.notification?.body;
    if (body != null && !map.containsKey('body')) map['body'] = body;
    if (message.messageId != null && !map.containsKey('message_id')) {
      map['message_id'] = message.messageId!;
    }
    return map;
  }

  Future<void> dispose() async {
    await _openedSub?.cancel();
    await _registeredSub?.cancel();
    _openedSub = null;
    _registeredSub = null;
    await _taps.close();
  }
}
