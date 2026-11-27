import 'dart:async';

import 'package:allowners/services/firebase_push_provider.dart';
import 'package:allowners/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';

/// المزوّد الحقيقي: ما يمكن إثباته بلا مشروع Firebase.
///
/// لا يوجد `google-services.json` في المستودع، لذلك كل ما يلمس الشبكة يبقى
/// صامتًا — وهذا بالضبط ما نُثبته. أمّا التحويلات النقية (حالة الإذن، حمولة
/// الرسالة، بثّ الضغطات) فتُختبر بمصادر مُحقونة.
void main() {
  group('حالة الإذن', () {
    test('كل حالة إذن تُترجم ترجمة واحدة صحيحة', () {
      expect(
        FirebasePushProvider.mapAuthorizationStatus(
            AuthorizationStatus.authorized),
        PushPermission.granted,
      );
      expect(
        FirebasePushProvider.mapAuthorizationStatus(
            AuthorizationStatus.provisional),
        PushPermission.granted,
      );
      expect(
        FirebasePushProvider.mapAuthorizationStatus(AuthorizationStatus.denied),
        PushPermission.denied,
      );
      expect(
        FirebasePushProvider.mapAuthorizationStatus(
            AuthorizationStatus.deniedPermanently),
        PushPermission.denied,
      );
      expect(
        FirebasePushProvider.mapAuthorizationStatus(
            AuthorizationStatus.notDetermined),
        PushPermission.notDetermined,
      );
    });
  });

  group('حمولة الرسالة', () {
    test('يحفظ حقول السيرفر كما هي ويضيف العنوان والنص والمعرّف', () {
      const message = RemoteMessage(
        data: {
          'type': 'booking',
          'booking_id': '7',
          'title': 'عنوان السيرفر',
        },
        messageId: 'msg-9',
        notification: RemoteNotification(
          title: 'عنوان النظام',
          body: 'نص النظام',
        ),
      );

      final data = FirebasePushProvider.dataOf(message);

      expect(data['type'], 'booking');
      expect(data['booking_id'], '7');
      // عنوان السيرفر يتقدّم على عنوان مقطع notification.
      expect(data['title'], 'عنوان السيرفر');
      expect(data['body'], 'نص النظام');
      expect(data['message_id'], 'msg-9');
    });

    test('رسالة بلا حقول لا تُنتج مفاتيح وهمية', () {
      final data = FirebasePushProvider.dataOf(const RemoteMessage());
      expect(data, isEmpty);
    });
  });

  group('بلا تهيئة Firebase', () {
    test('لا رمز ولا إذن ولا رسائل — ولا استثناء', () async {
      final provider = FirebasePushProvider();

      expect(provider.isConfigured, isFalse);
      expect(await provider.currentToken(), isNull);
      expect(await provider.requestPermission(), PushPermission.unavailable);
      expect(await provider.onTokenRefresh.isEmpty, isTrue);
      expect(await provider.onForegroundMessage.isEmpty, isTrue);
      expect(await provider.onNotificationTap.isEmpty, isTrue);

      await provider.dispose();
    });
  });

  group('بمصادر مُحقونة (محاكاة جهاز مهيّأ)', () {
    test('رسالة المقدمة تصل بحمولتها', () async {
      final foreground = StreamController<RemoteMessage>.broadcast();
      final provider = FirebasePushProvider(
        configured: true,
        foreground: foreground.stream,
      );
      final received = <Map<String, dynamic>>[];
      final sub = provider.onForegroundMessage.listen(received.add);

      foreground.add(const RemoteMessage(data: {'type': 'booking'}));
      await Future<void>.delayed(Duration.zero);

      expect(received, [
        {'type': 'booking'},
      ]);

      await sub.cancel();
      await foreground.close();
      await provider.dispose();
    });

    test('ضغطة من الخلفية ومن حالة الإغلاق تصلان إلى نفس البثّ', () async {
      final opened = StreamController<RemoteMessage>.broadcast();
      final provider = FirebasePushProvider(
        configured: true,
        opened: opened.stream,
        initialMessage: () async =>
            const RemoteMessage(data: {'type': 'wallet', 'target': 'wallet'}),
      );
      final taps = <Map<String, dynamic>>[];
      final sub = provider.onNotificationTap.listen(taps.add);

      opened.add(const RemoteMessage(data: {'type': 'service_request'}));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(taps, hasLength(2));
      expect(taps.map((t) => t['type']), contains('service_request'));
      // رسالة حالة الإغلاق تُقرأ مرة واحدة عند بدء الاستماع.
      expect(taps.map((t) => t['target']), contains('wallet'));

      await sub.cancel();
      await opened.close();
      await provider.dispose();
    });

    test('الاستماع مرتين لا يضاعف الضغطات', () async {
      final opened = StreamController<RemoteMessage>.broadcast();
      final provider = FirebasePushProvider(
        configured: true,
        opened: opened.stream,
        initialMessage: () async => null,
      );
      final taps = <Map<String, dynamic>>[];
      final first = provider.onNotificationTap.listen(taps.add);
      final second = provider.onNotificationTap.listen(taps.add);

      opened.add(const RemoteMessage(data: {'type': 'booking'}));
      await Future<void>.delayed(Duration.zero);

      expect(taps, hasLength(2)); // مستمعان، رسالة واحدة لكل منهما.

      await first.cancel();
      await second.cancel();
      await opened.close();
      await provider.dispose();
    });
  });
}
