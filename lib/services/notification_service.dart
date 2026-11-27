import 'dart:async';

import 'package:dio/dio.dart';

import '../utils/notification_routing.dart';
import '../utils/safe_parse.dart';
import 'api_client.dart';

/// حالة إذن الإشعارات على الجهاز.
enum PushPermission { granted, denied, notDetermined, unavailable }

/// مزوّد الدفع... لا؛ مزوّد الإشعارات.
///
/// التطبيق لا يعتمد على Firebase مباشرة هنا: هذه الواجهة الصغيرة تُركَّب على
/// `firebase_messaging` في مرحلة الإعداد (انظر
/// `docs/ALL_OWNERS_FINAL_BACKEND_MASTER.md` §7). الافتراضي
/// [UnavailablePushProvider] لأن مشروع Firebase (`google-services.json` /
/// `GoogleService-Info.plist`) غير موجود في هذا المستودع، ولا يجوز أن ندّعي
/// إشعارات تعمل بلا إعداد حقيقي.
abstract class PushProvider {
  /// هل المزوّد مهيّأ فعلًا على هذا الجهاز؟
  bool get isConfigured;

  Future<PushPermission> requestPermission();

  /// رمز الجهاز الحالي، أو null إن لم يكن هناك رمز حقيقي.
  Future<String?> currentToken();

  /// بثّ تجديد الرمز (FCM `onTokenRefresh`).
  Stream<String> get onTokenRefresh;

  /// رسائل تصل والتطبيق في المقدمة.
  Stream<Map<String, dynamic>> get onForegroundMessage;

  /// ضغطة المستخدم على إشعار والتطبيق في الخلفية/مغلق.
  Stream<Map<String, dynamic>> get onNotificationTap;
}

/// مزوّد بديل يُستخدم حتى يُضاف مشروع Firebase: لا رمز، لا إذن، لا رسائل.
class UnavailablePushProvider implements PushProvider {
  const UnavailablePushProvider();

  @override
  bool get isConfigured => false;

  @override
  Future<PushPermission> requestPermission() async =>
      PushPermission.unavailable;

  @override
  Future<String?> currentToken() async => null;

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  Stream<Map<String, dynamic>> get onForegroundMessage => const Stream.empty();

  @override
  Stream<Map<String, dynamic>> get onNotificationTap => const Stream.empty();
}

/// نتيجة محاولة تسجيل الرمز لدى الخادم.
class PushRegistrationResult {
  final bool registered;
  final String? reason;

  const PushRegistrationResult({required this.registered, this.reason});
}

/// خدمة الإشعارات: الإذن، تسجيل رمز الجهاز وتجديده، وإلغاء التسجيل عند خروج
/// الحساب.
///
/// كل ما يخرج من الجهاز هنا هو الرمز والمنصّة واللغة — لا بيانات حجز ولا مبالغ.
/// ولا يُرسل أي شيء إن لم يكن هناك رمز حقيقي من المزوّد.
class NotificationService {
  NotificationService({PushProvider? provider, Dio? dio})
      : _provider = provider ?? const UnavailablePushProvider(),
        _dio = dio ?? ApiClient.instance.dio;

  final PushProvider _provider;
  final Dio _dio;

  /// بثّ الإشعارات التي يجب أن تُعرض داخل التطبيق (snackbar/banner) بعد إزالة
  /// التكرار. الشاشات تستهلكه عند الحاجة.
  final StreamController<Map<String, dynamic>> _inApp =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get inAppMessages => _inApp.stream;

  final Set<String> _delivered = <String>{};
  final StreamController<Map<String, dynamic>> _taps =
      StreamController<Map<String, dynamic>>.broadcast();
  bool _attached = false;

  bool get isConfigured => _provider.isConfigured;

  /// يطلب الإذن ثم يسجّل الرمز لدى الخادم. يُرجع نتيجة صريحة، ولا يدّعي نجاحًا.
  Future<PushRegistrationResult> register({
    required String locale,
  }) async {
    if (!_provider.isConfigured) {
      return const PushRegistrationResult(
          registered: false, reason: 'push_provider_not_configured');
    }
    final permission = await _provider.requestPermission();
    if (permission != PushPermission.granted) {
      return PushRegistrationResult(
          registered: false, reason: 'permission_${permission.name}');
    }
    final token = await _provider.currentToken();
    if (token == null || token.trim().isEmpty) {
      return const PushRegistrationResult(
          registered: false, reason: 'no_device_token');
    }
    return _sendToken(token, locale: locale);
  }

  /// يُنادى عند `onTokenRefresh`: يُرسل الرمز الجديد ويُبطل القديم على الخادم.
  Future<PushRegistrationResult> refreshToken(String token,
      {required String locale}) async {
    if (token.trim().isEmpty) {
      return const PushRegistrationResult(
          registered: false, reason: 'no_device_token');
    }
    return _sendToken(token, locale: locale);
  }

  Future<PushRegistrationResult> _sendToken(String token,
      {required String locale}) async {
    try {
      await _dio.post('/user/device-token.php', data: {
        'token': token.trim(),
        'platform': _platformName(),
        'locale': locale,
      });
      return const PushRegistrationResult(registered: true);
    } on DioException catch (e) {
      return PushRegistrationResult(
          registered: false,
          reason: 'api_${ApiException.fromDioError(e).statusCode ?? 0}');
    }
  }

  /// إلغاء التسجيل عند تسجيل الخروج حتى لا تصل إشعارات مستخدم لحساب آخر.
  Future<void> unregister({required String token}) async {
    if (token.trim().isEmpty || !_provider.isConfigured) return;
    try {
      await _dio.post('/user/device-token.php',
          data: {'token': token.trim(), 'action': 'unregister'});
    } on DioException {
      // لا نُسقط تسجيل الخروج بسبب فشل شبكي.
    }
  }

  /// بثّ تجديد الرمز كما يصل من المزوّد (فارغ إن لم يكن مهيّأً).
  Stream<String> get tokenRefreshes => _provider.onTokenRefresh;

  /// بثّ ضغطات الإشعارات بعد ربط المزوّد عبر [attach].
  Stream<Map<String, dynamic>> get onNotificationTap => _taps.stream;

  /// يربط بثّ المزوّد بالخدمة: عرض الرسائل في المقدمة وإعادة توجيه الضغطات.
  ///
  /// الربط مرة واحدة فقط: الاستدعاء الثاني لا يضاعف الاشتراكات ولا يُكرّر
  /// عرض الرسالة نفسها.
  void attach() {
    if (_attached) return;
    _attached = true;
    _provider.onForegroundMessage.listen((data) {
      final key = notificationDedupeKey(data);
      if (key != null) {
        if (!_delivered.add(key)) return;
      }
      _inApp.add(data);
    });
    _provider.onNotificationTap.listen(_taps.add);
  }

  /// الرمز الحالي من المزوّد إن وُجد وكان مهيّأً. تُستخدم بعد نجاح التسجيل
  /// لحفظ الرمز نفسه الذي وافق عليه الخادم بدل تخمينه.
  Future<String?> currentProviderToken() async {
    if (!_provider.isConfigured) return null;
    final token = await _provider.currentToken();
    final clean = token?.trim();
    return (clean == null || clean.isEmpty) ? null : clean;
  }

  /// حمولة تعريفية للتسجيل — تُستخدم في الاختبارات لإثبات ما يُرسل.
  Map<String, dynamic> tokenPayload(String token, {required String locale}) => {
        'token': token.trim(),
        'platform': _platformName(),
        'locale': locale,
      };

  String _platformName() {
    if (const bool.fromEnvironment('dart.library.io')) {
      // لا نستورد `dart:io` هنا كي يبقى الملف قابلًا للاختبار على أي منصة.
      final os = asString(const String.fromEnvironment('FLUTTER_TEST_PLATFORM',
          defaultValue: ''));
      return os.isEmpty ? 'mobile' : os;
    }
    return 'web';
  }

  /// إغلاق البثوث (يُستخدم في الاختبارات وفي dispose).
  Future<void> dispose() async {
    await _inApp.close();
    await _taps.close();
  }
}

/// هل يدعم الخادم تسجيل الرموز؟ تقرأه الشاشات لعرض الحالة بصدق.
bool pushEndpointSupported(Map<String, dynamic> response) {
  final value = response['success'] ?? response['ok'];
  return value == true || value == 1 || value == '1';
}
