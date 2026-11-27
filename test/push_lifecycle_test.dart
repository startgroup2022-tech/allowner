import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:allowners/services/notification_service.dart';
import 'package:allowners/utils/notification_routing.dart';
import 'package:allowners/utils/push_lifecycle.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// القسم 10 من موجز القبول: دورة حياة إشعارات الدفع على جانب Flutter.
///
/// ما يُثبته هذا الملف:
///   • تسجيل الرمز عند الدخول — ويُحفظ فقط إذا وافق عليه الخادم.
///   • تجديد الرمز يُبطل القديم على الخادم قبل استبداله محليًا.
///   • تسجيل الخروج يُلغي الرمز المحفوظ ويمسحه.
///   • لا شبكة إطلاقًا بلا مزوّد مهيّأ (Firebase غير موجود في المستودع).
///   • ضغطات الإشعارات تُترجم إلى حدث موجّه، والرسائل المكرّرة لا تُعرض مرتين.

class _FakeProvider implements PushProvider {
  _FakeProvider({
    this.configured = true,
    this.permission = PushPermission.granted,
    this.token = 'fcm-token-1',
  });

  bool configured;
  PushPermission permission;
  String? token;

  final _refresh = StreamController<String>.broadcast();
  final _foreground = StreamController<Map<String, dynamic>>.broadcast();
  final _tap = StreamController<Map<String, dynamic>>.broadcast();

  @override
  bool get isConfigured => configured;

  @override
  Future<PushPermission> requestPermission() async => permission;

  @override
  Future<String?> currentToken() async => token;

  @override
  Stream<String> get onTokenRefresh => _refresh.stream;

  @override
  Stream<Map<String, dynamic>> get onForegroundMessage => _foreground.stream;

  @override
  Stream<Map<String, dynamic>> get onNotificationTap => _tap.stream;

  void emitRefresh(String value) => _refresh.add(value);
  void emitForeground(Map<String, dynamic> data) => _foreground.add(data);
  void emitTap(Map<String, dynamic> data) => _tap.add(data);

  Future<void> close() async {
    await _refresh.close();
    await _foreground.close();
    await _tap.close();
  }
}

class _TokenRecorder implements HttpClientAdapter {
  _TokenRecorder({this.status = 200});

  int status;
  final List<Map<String, dynamic>> posts = [];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.method == 'POST') {
      Object? raw = options.data;
      if (raw is String) {
        try {
          raw = jsonDecode(raw);
        } catch (_) {}
      }
      posts.add({
        'path': options.path,
        'data': raw is Map ? Map<String, dynamic>.from(raw) : raw,
      });
    }
    return ResponseBody.fromString(
      jsonEncode({'success': status == 200}),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

PushLifecycle _lifecycle(_FakeProvider provider, _TokenRecorder recorder) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'))
    ..httpClientAdapter = recorder;
  return PushLifecycle(
    service: NotificationService(provider: provider, dio: dio),
    prefs: SharedPreferences.getInstance(),
  );
}

/// يترك الحلقة تستقر بعد البثّ: المستمع يقرأ التخزين ثم يُرسل طلبًا.
Future<void> _settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('تسجيل الرمز عند الدخول', () {
    test('يُرسل الرمز والمنصّة واللغة ويحفظ الرمز بعد موافقة الخادم', () async {
      final provider = _FakeProvider();
      final recorder = _TokenRecorder();
      final lifecycle = _lifecycle(provider, recorder);

      final result = await lifecycle.onLogin(locale: 'ar');

      expect(result.registered, isTrue);
      expect(recorder.posts, hasLength(1));
      expect(recorder.posts.single['path'], '/user/device-token.php');
      final data = recorder.posts.single['data'] as Map<String, dynamic>;
      expect(data['token'], 'fcm-token-1');
      expect(data['locale'], 'ar');
      expect(data['platform'], isNotEmpty);
      expect(await lifecycle.storedToken(), 'fcm-token-1');
      expect(lifecycle.lastReason, isNull);

      await lifecycle.dispose();
      await provider.close();
    });

    test('رفض الإذن لا يرسل شيئًا ولا يحفظ رمزًا', () async {
      final provider = _FakeProvider(permission: PushPermission.denied);
      final recorder = _TokenRecorder();
      final lifecycle = _lifecycle(provider, recorder);

      final result = await lifecycle.onLogin(locale: 'en');

      expect(result.registered, isFalse);
      expect(result.reason, 'permission_denied');
      expect(recorder.posts, isEmpty);
      expect(await lifecycle.storedToken(), isNull);
      expect(lifecycle.lastReason, 'permission_denied');

      await lifecycle.dispose();
      await provider.close();
    });

    test('ردّ الخادم بخطأ لا يُحفظ معه رمز', () async {
      final provider = _FakeProvider();
      final recorder = _TokenRecorder(status: 503);
      final lifecycle = _lifecycle(provider, recorder);

      final result = await lifecycle.onLogin(locale: 'ar');

      expect(result.registered, isFalse);
      expect(result.reason, 'api_503');
      expect(await lifecycle.storedToken(), isNull);

      await lifecycle.dispose();
      await provider.close();
    });

    test('بلا مزوّد مهيّأ: لا شبكة ولا ادّعاء تسجيل', () async {
      final provider = _FakeProvider(configured: false);
      final recorder = _TokenRecorder();
      final lifecycle = _lifecycle(provider, recorder);

      final result = await lifecycle.onLogin(locale: 'ar');

      expect(result.registered, isFalse);
      expect(result.reason, 'push_provider_not_configured');
      expect(recorder.posts, isEmpty);

      await lifecycle.dispose();
      await provider.close();
    });
  });

  group('تجديد الرمز', () {
    test('يُبطل الرمز القديم على الخادم ثم يسجّل الجديد ويحفظه', () async {
      final provider = _FakeProvider(token: 'old-token');
      final recorder = _TokenRecorder();
      final lifecycle = _lifecycle(provider, recorder);
      await lifecycle.onLogin(locale: 'ar');
      recorder.posts.clear();

      final result = await lifecycle.onTokenRefresh('new-token', locale: 'ar');

      expect(result.registered, isTrue);
      expect(recorder.posts, hasLength(2));
      expect(recorder.posts.first['data']['action'], 'unregister');
      expect(recorder.posts.first['data']['token'], 'old-token');
      expect(recorder.posts.last['data']['token'], 'new-token');
      expect(recorder.posts.last['data']['action'], isNull);
      expect(await lifecycle.storedToken(), 'new-token');

      await lifecycle.dispose();
      await provider.close();
    });

    test('نفس الرمز لا يُبطل نفسه', () async {
      final provider = _FakeProvider(token: 'same-token');
      final recorder = _TokenRecorder();
      final lifecycle = _lifecycle(provider, recorder);
      await lifecycle.onLogin(locale: 'ar');
      recorder.posts.clear();

      await lifecycle.onTokenRefresh('same-token', locale: 'ar');

      expect(recorder.posts, hasLength(1));
      expect(recorder.posts.single['data']['token'], 'same-token');

      await lifecycle.dispose();
      await provider.close();
    });

    test('بثّ المزوّد يُمرَّر إلى الخدمة ويُحدّث التخزين', () async {
      final provider = _FakeProvider(token: 'first');
      final recorder = _TokenRecorder();
      final lifecycle = _lifecycle(provider, recorder);
      await lifecycle.onLogin(locale: 'ar');
      lifecycle.start();

      provider.emitRefresh('second');
      await _settle();

      expect(await lifecycle.storedToken(), 'second');
      expect(recorder.posts.map((p) => p['data']['token']),
          containsAll(<String>['first', 'second']));

      await lifecycle.dispose();
      await provider.close();
    });
  });

  group('تسجيل الخروج', () {
    test('يُبطل الرمز المحفوظ على الخادم ويمسحه محليًا', () async {
      final provider = _FakeProvider();
      final recorder = _TokenRecorder();
      final lifecycle = _lifecycle(provider, recorder);
      await lifecycle.onLogin(locale: 'ar');
      recorder.posts.clear();

      await lifecycle.onLogout();

      expect(recorder.posts, hasLength(1));
      expect(recorder.posts.single['data'], {
        'token': 'fcm-token-1',
        'action': 'unregister',
      });
      expect(await lifecycle.storedToken(), isNull);

      await lifecycle.dispose();
      await provider.close();
    });

    test('بلا رمز محفوظ: لا طلب إلغاء وهمي', () async {
      final provider = _FakeProvider();
      final recorder = _TokenRecorder();
      final lifecycle = _lifecycle(provider, recorder);

      await lifecycle.onLogout();

      expect(recorder.posts, isEmpty);
      expect(await lifecycle.storedToken(), isNull);

      await lifecycle.dispose();
      await provider.close();
    });
  });

  group('عرض الرسائل وتوجيه الضغطات', () {
    test('الرسالة الأمامية تُمرَّر مرة واحدة رغم تكرار الحمولة', () async {
      final provider = _FakeProvider();
      final recorder = _TokenRecorder();
      final lifecycle = _lifecycle(provider, recorder);
      final received = <Map<String, dynamic>>[];
      lifecycle.start(onForeground: received.add);

      final payload = {
        'type': 'booking',
        'message_id': 'm-1',
        'booking_id': 7,
      };
      provider.emitForeground(payload);
      provider.emitForeground(payload);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(1));

      await lifecycle.dispose();
      await provider.close();
    });

    test('الضغط يُترجم إلى حدث ووجهة صحيحين', () async {
      final provider = _FakeProvider();
      final recorder = _TokenRecorder();
      final lifecycle = _lifecycle(provider, recorder);
      final taps = <NotificationEvent>[];
      lifecycle.start(onTap: (event, data) => taps.add(event));

      provider.emitTap({'type': 'service_request', 'request_id': 12});
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(taps, [NotificationEvent.serviceRequestCreated]);
      expect(targetForEvent(taps.single), NotificationTarget.serviceRequest);

      await lifecycle.dispose();
      await provider.close();
    });

    test('الربط مرتين لا يضاعف الاستماع', () async {
      final provider = _FakeProvider();
      final recorder = _TokenRecorder();
      final lifecycle = _lifecycle(provider, recorder);
      final received = <Map<String, dynamic>>[];
      lifecycle.start(onForeground: received.add);
      lifecycle.start(onForeground: received.add);

      provider.emitForeground({'type': 'booking', 'booking_id': 3});
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(1));

      await lifecycle.dispose();
      await provider.close();
    });
  });
}
