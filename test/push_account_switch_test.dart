import 'dart:async';
import 'dart:typed_data';

import 'package:allowners/services/notification_service.dart';
import 'package:allowners/utils/push_lifecycle.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// سيناريوهات تبديل الحساب والفشل والاسترداد على مسار الإشعارات.
///
/// كلها تعمل بمزوّد «مهيّأ» مُحقون وشبكة مُقلَّدة، فلا شيء يخرج من الجهاز.
class _FakeProvider implements PushProvider {
  _FakeProvider({this.token = 'tok-A', this.granted = true});

  String? token;
  bool granted;

  @override
  bool get isConfigured => true;

  @override
  Future<PushPermission> requestPermission() async =>
      granted ? PushPermission.granted : PushPermission.denied;

  @override
  Future<String?> currentToken() async => token;

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  Stream<Map<String, dynamic>> get onForegroundMessage => const Stream.empty();

  @override
  Stream<Map<String, dynamic>> get onNotificationTap => const Stream.empty();
}

/// محوّل Dio يسجّل كل طلب ويرد بحسب جدول حالات مُحدَّد.
class _Recorder implements HttpClientAdapter {
  _Recorder(this.statuses, {this.byAction});

  /// حالات الرد بالترتيب؛ آخر عنصر يتكرّر.
  final List<int> statuses;

  /// حالة ثابتة لكل نوع طلب (إلغاء/تسجيل) تتقدّم على [statuses].
  final Map<String, int>? byAction;
  final List<Map<String, dynamic>> bodies = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = Map<String, dynamic>.from(options.data as Map);
    bodies.add(body);
    final action = body['action'] == 'unregister' ? 'unregister' : 'register';
    final status = byAction?[action] ??
        (statuses.length == 1
            ? statuses.first
            : statuses[(bodies.length - 1).clamp(0, statuses.length - 1)]);
    if (status == 200) {
      return ResponseBody.fromString('{"success":true}', 200, headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      });
    }
    return ResponseBody.fromString('{"success":false}', status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

Dio _dio(_Recorder recorder) =>
    Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = recorder;

NotificationService _service(_FakeProvider provider, _Recorder recorder) =>
    NotificationService(
      provider: provider,
      dio: _dio(recorder),
      retryDelays: const [Duration.zero, Duration.zero],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('تبديل الحساب', () {
    test('رمز محفوظ لحساب آخر يُلغى قبل تسجيل الحساب الجديد', () async {
      SharedPreferences.setMockInitialValues({
        PushLifecycle.tokenKey: 'tok-A',
        PushLifecycle.tokenUserKey: '11',
      });
      final provider = _FakeProvider(token: 'tok-A');
      final recorder = _Recorder([200]);
      final lifecycle = PushLifecycle(service: _service(provider, recorder));

      final result = await lifecycle.onLogin(locale: 'ar', userId: '22');

      expect(result.registered, isTrue);
      expect(recorder.bodies, hasLength(2));
      expect(recorder.bodies.first['action'], 'unregister');
      expect(recorder.bodies.first['token'], 'tok-A');
      expect(recorder.bodies.last['token'], 'tok-A');
      expect(recorder.bodies.last.containsKey('action'), isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(PushLifecycle.tokenUserKey), '22');
    });

    test('نفس الحساب لا يُلغي الرمز: تسجيل واحد فقط', () async {
      SharedPreferences.setMockInitialValues({
        PushLifecycle.tokenKey: 'tok-A',
        PushLifecycle.tokenUserKey: '11',
      });
      final recorder = _Recorder([200]);
      final lifecycle = PushLifecycle(
          service: _service(_FakeProvider(token: 'tok-A'), recorder));

      await lifecycle.onLogin(locale: 'ar', userId: '11');

      expect(recorder.bodies, hasLength(1));
      expect(recorder.bodies.single.containsKey('action'), isFalse);
    });

    test('رمز استُبدل على الجهاز: القديم يُلغى والجديد يُسجَّل', () async {
      SharedPreferences.setMockInitialValues({
        PushLifecycle.tokenKey: 'tok-old',
        PushLifecycle.tokenUserKey: '11',
      });
      final recorder = _Recorder([200]);
      final lifecycle = PushLifecycle(
          service: _service(_FakeProvider(token: 'tok-new'), recorder));

      await lifecycle.onLogin(locale: 'en', userId: '11');

      expect(recorder.bodies.first['action'], 'unregister');
      expect(recorder.bodies.first['token'], 'tok-old');
      expect(recorder.bodies.last['token'], 'tok-new');
      expect(recorder.bodies.last['locale'], 'en');
    });
  });

  group('فشل الإلغاء والاسترداد', () {
    test('فشل الإلغاء يحفظ الرمز معلّقًا ولا يفقده', () async {
      SharedPreferences.setMockInitialValues({
        PushLifecycle.tokenKey: 'tok-A',
        PushLifecycle.tokenUserKey: '11',
      });
      // 500 ثلاث مرات: كل المحاولات تفشل.
      final recorder = _Recorder([500]);
      final lifecycle = PushLifecycle(
          service: _service(_FakeProvider(token: 'tok-B'), recorder));

      await lifecycle.onLogin(locale: 'ar', userId: '22');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(PushLifecycle.pendingUnregisterKey), 'tok-A');
    });

    test('الإقلاع التالي يعيد محاولة الإلغاء المعلّق وينجح فيمسحه', () async {
      SharedPreferences.setMockInitialValues({
        PushLifecycle.pendingUnregisterKey: 'tok-A',
      });
      final recorder = _Recorder([200]);
      final lifecycle = PushLifecycle(
          service: _service(_FakeProvider(token: 'tok-A'), recorder));

      final ok = await lifecycle.flushPendingUnregister();

      expect(ok, isTrue);
      expect(recorder.bodies.single['action'], 'unregister');
      expect(await lifecycle.pendingUnregister(), isNull);
    });

    test('تدوير الرمز لا يفقد القديم إن فشل إلغاؤه', () async {
      SharedPreferences.setMockInitialValues({
        PushLifecycle.tokenKey: 'tok-old',
      });
      // الإلغاء يفشل دائمًا، والتسجيل ينجح.
      final recorder =
          _Recorder([200], byAction: {'unregister': 500, 'register': 200});
      final lifecycle = PushLifecycle(
          service: _service(_FakeProvider(token: 'tok-new'), recorder));

      final result = await lifecycle.onTokenRefresh('tok-new', locale: 'ar');

      expect(result.registered, isTrue);
      expect(await lifecycle.pendingUnregister(), 'tok-old');
      expect(await lifecycle.storedToken(), 'tok-new');
    });
  });

  group('سياسة إعادة المحاولة', () {
    test('5xx يُعاد حتى النجاح', () async {
      final recorder = _Recorder([503, 503, 200]);
      final service = _service(_FakeProvider(), recorder);

      final result = await service.register(locale: 'ar');

      expect(result.registered, isTrue);
      expect(recorder.bodies, hasLength(3));
    });

    test('4xx قرار نهائي: لا إعادة', () async {
      final recorder = _Recorder([400]);
      final service = _service(_FakeProvider(), recorder);

      final result = await service.register(locale: 'ar');

      expect(result.registered, isFalse);
      expect(result.reason, 'api_400');
      expect(recorder.bodies, hasLength(1));
    });

    test('استنفاد المحاولات يُرجع آخر سبب حقيقي', () async {
      final recorder = _Recorder([503]);
      final service = _service(_FakeProvider(), recorder);

      final result = await service.register(locale: 'ar');

      expect(result.registered, isFalse);
      expect(result.reason, 'api_503');
      expect(recorder.bodies, hasLength(3));
    });

    test('رفض الإذن يمنع أي طلب شبكة', () async {
      final recorder = _Recorder([200]);
      final service = _service(_FakeProvider(granted: false), recorder);

      final result = await service.register(locale: 'ar');

      expect(result.registered, isFalse);
      expect(result.reason, 'permission_denied');
      expect(recorder.bodies, isEmpty);
    });
  });

  group('تسجيل الخروج', () {
    test('يُلغي الرمز ويمسحه، ويرجع الإلغاء المعلّق عند الفشل', () async {
      SharedPreferences.setMockInitialValues({
        PushLifecycle.tokenKey: 'tok-A',
        PushLifecycle.tokenUserKey: '11',
      });
      final recorder = _Recorder([200]);
      final lifecycle = PushLifecycle(
          service: _service(_FakeProvider(token: 'tok-A'), recorder));

      await lifecycle.onLogout();

      expect(recorder.bodies.single['action'], 'unregister');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(PushLifecycle.tokenKey), isNull);
      expect(prefs.getString(PushLifecycle.tokenUserKey), isNull);
      expect(prefs.getString(PushLifecycle.pendingUnregisterKey), isNull);
    });

    test('فشل الإلغاء عند الخروج يبقيه معلّقًا للمحاولة التالية', () async {
      SharedPreferences.setMockInitialValues({
        PushLifecycle.tokenKey: 'tok-A',
        PushLifecycle.tokenUserKey: '11',
      });
      final recorder = _Recorder([500]);
      final lifecycle = PushLifecycle(
          service: _service(_FakeProvider(token: 'tok-A'), recorder));

      await lifecycle.onLogout();

      expect(await lifecycle.pendingUnregister(), 'tok-A');
      expect(await lifecycle.storedToken(), isNull);
    });
  });
}
