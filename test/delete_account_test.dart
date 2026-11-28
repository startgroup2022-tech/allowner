import 'dart:convert';
import 'dart:typed_data';

import 'package:allowners/models/app_user.dart';
import 'package:allowners/screens/profile/delete_account_screen.dart';
import 'package:allowners/services/api_client.dart';
import 'package:allowners/services/auth_service.dart';
import 'package:allowners/theme/app_theme.dart';
import 'package:allowners/utils/app_strings.dart';
import 'package:allowners/utils/session_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// حذف الحساب من داخل التطبيق (سياسة Google Play): الشاشة، التحقق، الاستدعاء
/// الفعلي للسيرفر، ورفض ادّعاء النجاح عند غياب المسار أو عند فشل الشبكة.

/// يخدم مسارات الشاشة حسب السيناريو المطلوب.
class _Adapter implements HttpClientAdapter {
  _Adapter({
    this.deleteStatus = 200,
    this.deleteBody,
    this.upcoming = false,
    this.throwNetwork = false,
  });

  final int deleteStatus;
  final Map<String, Object?>? deleteBody;
  final bool upcoming;
  final bool throwNetwork;

  final List<RequestOptions> calls = [];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(options);
    if (options.path.contains('user/delete-account')) {
      if (throwNetwork) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          message: 'offline',
        );
      }
      final body = deleteBody ?? {'success': true};
      return ResponseBody.fromString(jsonEncode(body), deleteStatus, headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      });
    }
    if (options.path.contains('bookings/my')) {
      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'bookings': upcoming
              ? [
                  {
                    'id': 5,
                    'check_in': '2099-01-01',
                    'check_out': '2099-01-03',
                    'status': 'confirmed',
                  }
                ]
              : <Object>[],
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType]
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode({'success': true}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType]
      },
    );
  }
}

Widget _wrap(Widget child, SessionNotifier session, {bool isArabic = true}) =>
    ProviderScope(
      overrides: [sessionProvider.overrideWith((ref) => session)],
      child: MaterialApp(
        locale: Locale(isArabic ? 'ar' : 'en'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.light(isArabic: isArabic),
        home: child,
      ),
    );

void main() {
  late HttpClientAdapter originalAdapter;

  setUp(() {
    SharedPreferences.setMockInitialValues({'auth_token': 'tok-123'});
    originalAdapter = ApiClient.instance.dio.httpClientAdapter;
  });

  tearDown(() {
    ApiClient.instance.dio.httpClientAdapter = originalAdapter;
  });

  Future<SessionNotifier> pump(
    WidgetTester tester, {
    bool isArabic = true,
  }) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = SessionNotifier();
    session.state = SessionState(
      user: AppUser(
        id: 12,
        fullName: 'ضيف تجريبي',
        email: 'guest@example.com',
        role: 'guest',
      ),
      isLoading: false,
    );
    await tester.pumpWidget(
        _wrap(const DeleteAccountScreen(), session, isArabic: isArabic));
    await tester.pumpAndSettle();
    return session;
  }

  group('نصوص الشاشة بالعربية والإنجليزية', () {
    test('المفاتيح المطلوبة موجودة بلا نص خام', () {
      for (final key in const [
        'delete_account',
        'delete_account_intro',
        'delete_account_what_is_deleted',
        'delete_account_what_is_kept',
        'delete_account_ack',
        'delete_account_submit',
        'delete_account_done_title',
        'delete_account_unavailable',
        'delete_account_web',
      ]) {
        expect(AppStrings.hasKey(key), isTrue, reason: key);
        expect(AppStrings.t(true, key), isNot(key));
        expect(AppStrings.t(false, key), isNot(key));
      }
      expect(AppStrings.t(true, 'delete_account'), 'حذف الحساب');
      expect(AppStrings.t(false, 'delete_account'), 'Delete account');
    });
  });

  group('الشاشة والتحقق قبل الإرسال', () {
    testWidgets('تعرض التحذير وتُبقي زر الحذف معطّلًا قبل التأكيد',
        (tester) async {
      ApiClient.instance.dio.httpClientAdapter = _Adapter();
      await pump(tester);
      expect(find.text(AppStrings.t(true, 'delete_account_intro')),
          findsOneWidget);
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('التأكيد النصي شرط: كلمة خاطئة تُبقي الزر معطّلًا',
        (tester) async {
      ApiClient.instance.dio.httpClientAdapter = _Adapter();
      await pump(tester);
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'حذفني');
      await tester.pumpAndSettle();
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
      await tester.enterText(find.byType(TextField), 'حذف');
      await tester.pumpAndSettle();
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNotNull,
      );
    });

    testWidgets('حجز قادم يمنع الحذف ويظهر السبب', (tester) async {
      ApiClient.instance.dio.httpClientAdapter = _Adapter(upcoming: true);
      await pump(tester);
      expect(
        find.text(AppStrings.t(true, 'delete_account_bookings_warning')),
        findsOneWidget,
      );
      await tester.tap(find.byType(Checkbox));
      await tester.enterText(find.byType(TextField), 'حذف');
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );
    });
  });

  group('الاستدعاء الفعلي للسيرفر', () {
    testWidgets('نجاح السيرفر يعرض شاشة الإتمام ويُفرّغ الجلسة',
        (tester) async {
      final adapter = _Adapter();
      ApiClient.instance.dio.httpClientAdapter = adapter;
      final session = await pump(tester);
      await tester.tap(find.byType(Checkbox));
      await tester.enterText(find.byType(TextField), 'حذف');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      final call = adapter.calls
          .firstWhere((c) => c.path.contains('user/delete-account'));
      expect(call.method, 'POST');
      expect((call.data as Map)['confirm'], isTrue);

      expect(find.text(AppStrings.t(true, 'delete_account_done_title')),
          findsOneWidget);
      expect(session.state.user, isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), isNull);
    });

    testWidgets('404 = غير مُفعَّلة على الخادم: لا نجاح وهمي ولا مسح للجلسة',
        (tester) async {
      ApiClient.instance.dio.httpClientAdapter =
          _Adapter(deleteStatus: 404, deleteBody: {'message': 'not found'});
      final session = await pump(tester);
      await tester.tap(find.byType(Checkbox));
      await tester.enterText(find.byType(TextField), 'حذف');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.t(true, 'delete_account_unavailable')),
          findsOneWidget);
      expect(find.text(AppStrings.t(true, 'delete_account_done_title')),
          findsNothing);
      expect(session.state.user, isNotNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), 'tok-123');
    });

    testWidgets('فشل الشبكة يُظهر الخطأ ويُبقي الحساب', (tester) async {
      ApiClient.instance.dio.httpClientAdapter = _Adapter(throwNetwork: true);
      final session = await pump(tester);
      await tester.tap(find.byType(Checkbox));
      await tester.enterText(find.byType(TextField), 'حذف');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.t(true, 'delete_account_done_title')),
          findsNothing);
      expect(session.state.user, isNotNull);
    });

    testWidgets('success:false من السيرفر لا يُعالج كنجاح', (tester) async {
      ApiClient.instance.dio.httpClientAdapter = _Adapter(
        deleteStatus: 200,
        deleteBody: {
          'success': false,
          'message': 'cannot delete owner account'
        },
      );
      final session = await pump(tester);
      await tester.tap(find.byType(Checkbox));
      await tester.enterText(find.byType(TextField), 'حذف');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.text('cannot delete owner account'), findsOneWidget);
      expect(session.state.user, isNotNull);
    });
  });

  group('الخدمة نفسها', () {
    test('ترفع reason عند اختياره', () async {
      final adapter = _Adapter();
      ApiClient.instance.dio.httpClientAdapter = adapter;
      await AuthService()
          .deleteAccount(reason: 'delete_account_reason_privacy');
      final call = adapter.calls
          .firstWhere((c) => c.path.contains('user/delete-account'));
      expect((call.data as Map)['reason'], 'delete_account_reason_privacy');
    });

    test('تترجم 404 إلى ApiErrorKind.notFound', () async {
      ApiClient.instance.dio.httpClientAdapter = _Adapter(deleteStatus: 404);
      await expectLater(
        AuthService().deleteAccount(),
        throwsA(isA<ApiException>()
            .having((e) => e.kind, 'kind', ApiErrorKind.notFound)),
      );
    });
  });
}
