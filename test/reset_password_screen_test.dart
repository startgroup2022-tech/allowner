import 'dart:convert';
import 'dart:typed_data';

import 'package:allowners/screens/auth/reset_password_screen.dart';
import 'package:allowners/services/api_client.dart';
import 'package:allowners/theme/app_theme.dart';
import 'package:allowners/utils/app_strings.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// اختبار شاشة استعادة كلمة المرور (المتطلب 110).
///
/// الخدمة غير مُنفَّذة على السيرفر: نحاكي رد 404 الحقيقي ونتأكد أن الشاشة
/// تعرض «غير مُفعَّلة» + مسار الدعم، لا نجاحًا وهميًا ولا زرًا لا يعمل.
class _Adapter implements HttpClientAdapter {
  _Adapter({required this.status});
  final int status;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode({'success': false, 'message': 'not found'}),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.light(isArabic: true),
        home: child,
      ),
    );

void main() {
  late HttpClientAdapter _original;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _original = ApiClient.instance.dio.httpClientAdapter;
  });

  tearDown(() {
    ApiClient.instance.dio.httpClientAdapter = _original;
  });

  testWidgets('ترفض البريد الفارغ وغير الصحيح قبل الإرسال', (tester) async {
    ApiClient.instance.dio.httpClientAdapter = _Adapter(status: 404);
    await tester.pumpWidget(_wrap(const ResetPasswordScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.t(true, 'reset_send_link')));
    await tester.pumpAndSettle();
    expect(find.text('هذا الحقل مطلوب'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'not-an-email');
    await tester.tap(find.text(AppStrings.t(true, 'reset_send_link')));
    await tester.pumpAndSettle();
    expect(find.text('أدخل بريدًا صحيحًا'), findsOneWidget);
  });

  testWidgets('عند 404 تعرض «غير مُفعَّلة» ومسار الدعم', (tester) async {
    ApiClient.instance.dio.httpClientAdapter = _Adapter(status: 404);
    await tester.pumpWidget(_wrap(const ResetPasswordScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'user@example.com');
    await tester.tap(find.text(AppStrings.t(true, 'reset_send_link')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.t(true, 'reset_unavailable')), findsOneWidget);
    expect(find.text(AppStrings.t(true, 'contact_support')), findsOneWidget);
    // لا نجاح وهمي
    expect(find.text(AppStrings.t(true, 'reset_sent')), findsNothing);
  });
}
