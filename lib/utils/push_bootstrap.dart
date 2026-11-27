import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/firebase_push_provider.dart';
import '../services/notification_service.dart';
import 'push_lifecycle.dart';

/// نتيجة محاولة تهيئة Firebase: إما مزوّد حقيقي أو لا شيء.
///
/// لا نُسقط التطبيق إن غاب الإعداد (الحالة الفعلية لهذا المستودع): نرجع null
/// فيعمل التطبيق بمزوّد غير مهيّأ ويقول الحقيقة بدل الادّعاء.
Future<FirebasePushProvider?> initializeFirebasePush({
  bool registerBackgroundHandler = true,
}) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    if (registerBackgroundHandler) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }
    final provider = FirebasePushProvider();
    return provider.isConfigured ? provider : null;
  } catch (error, stack) {
    // لا إعداد Firebase في المستودع: هذا متوقّع وليس خطأ تشغيل.
    debugPrint('push: Firebase not initialised (${error.runtimeType})');
    debugPrintStack(stackTrace: stack, maxFrames: 3);
    return null;
  }
}

/// المزوّد المُستخدم في كل التطبيق. يُستبدل في `main()` عند نجاح التهيئة،
/// ويبقى [UnavailablePushProvider] في الاختبارات وكل بيئة بلا Firebase.
final pushProviderProvider = Provider<PushProvider>(
  (ref) => const UnavailablePushProvider(),
);

/// دورة حياة واحدة مشتركة: التسجيل (من الجلسة) والتوجيه (من الواجهة) يجب أن
/// يعملوا على نفس الكائن، وإلا تكرّرت المستمعات وتكرّرت الرسائل.
final pushLifecycleProvider = Provider<PushLifecycle>((ref) {
  final lifecycle = PushLifecycle(
    service: NotificationService(provider: ref.watch(pushProviderProvider)),
  );
  ref.onDispose(lifecycle.dispose);
  return lifecycle;
});
