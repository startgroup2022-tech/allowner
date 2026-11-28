import 'package:allowners/services/notification_service.dart';
import 'package:allowners/theme/app_theme.dart';
import 'package:allowners/utils/app_strings.dart';
import 'package:allowners/widgets/push_status_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// شريط «إشعارات هذا الجهاز»: يعرض آخر نتيجة تسجيل حقيقية، ويسمح بإعادة
/// المحاولة، ولا يدّعي التفعيل عند غياب مزوّد أو رفض الإذن.

/// خدمة مزيفة تعيد النتيجة المطلوبة لكل نداء (بدون شبكة).
class _FakeService extends NotificationService {
  _FakeService(this.results);

  final List<PushRegistrationResult> results;
  int calls = 0;

  @override
  Future<PushRegistrationResult> register({required String locale}) async {
    final result = results[calls.clamp(0, results.length - 1)];
    calls++;
    return result;
  }
}

Widget _wrap(Widget child, {bool isArabic = true}) => MaterialApp(
      locale: Locale(isArabic ? 'ar' : 'en'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light(isArabic: isArabic),
      home: Scaffold(body: child),
    );

void main() {
  group('نصوص الشريط', () {
    test('المفاتيح موجودة بالعربية والإنجليزية', () {
      expect(AppStrings.t(true, 'push_status_title'), 'إشعارات هذا الجهاز');
      expect(AppStrings.t(false, 'push_status_title'), 'Device notifications');
      expect(AppStrings.t(true, 'push_enable'), 'تفعيل الإشعارات');
      expect(AppStrings.t(false, 'push_enable'), 'Enable notifications');
      for (final key in const [
        'push_enabled_on_device',
        'push_not_requested',
        'push_not_configured',
        'push_permission_denied',
        'push_no_token',
        'push_register_failed',
        'push_retry',
      ]) {
        expect(AppStrings.hasKey(key), isTrue, reason: key);
        expect(AppStrings.t(true, key), isNot(key));
        expect(AppStrings.t(false, key), isNot(key));
      }
    });
  });

  group('العرض والتفاعل', () {
    testWidgets('بلا مزوّع: يظهر سبب غياب الإعداد ولا يُدّعى التفعيل',
        (tester) async {
      final service = _FakeService(const [
        PushRegistrationResult(
            registered: false, reason: 'push_provider_not_configured'),
      ]);
      await tester.pumpWidget(_wrap(PushStatusBanner(
          isArabic: true, service: service, initialReason: null)));
      await tester.pumpAndSettle();

      expect(
          find.text(AppStrings.t(true, 'push_not_requested')), findsOneWidget);
      await tester.tap(find.text(AppStrings.t(true, 'push_enable')));
      await tester.pumpAndSettle();

      expect(
          find.text(AppStrings.t(true, 'push_not_configured')), findsOneWidget);
      expect(find.text(AppStrings.t(true, 'push_enabled_on_device')),
          findsNothing);
      expect(find.text(AppStrings.t(true, 'push_retry')), findsOneWidget);
      expect(service.calls, 1);
    });

    testWidgets('نجاح التسجيل يعرض حالة التفعيل ويُخفي زر الإعادة',
        (tester) async {
      final service =
          _FakeService(const [PushRegistrationResult(registered: true)]);
      await tester.pumpWidget(_wrap(PushStatusBanner(
          isArabic: false, service: service, initialReason: null)));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.t(false, 'push_enable')));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.t(false, 'push_enabled_on_device')),
          findsOneWidget);
      expect(find.byType(OutlinedButton), findsNothing);
    });

    testWidgets('رفض الإذن يُعرض كرفض نظام لا كخطأ عام', (tester) async {
      final service = _FakeService(const [
        PushRegistrationResult(registered: false, reason: 'permission_denied'),
      ]);
      await tester.pumpWidget(_wrap(PushStatusBanner(
          isArabic: true, service: service, initialReason: null)));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.t(true, 'push_enable')));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.t(true, 'push_permission_denied')),
          findsOneWidget);
    });

    testWidgets('سبب أولي من الجلسة يظهر فورًا قبل أي محاولة', (tester) async {
      final service = _FakeService(const []);
      await tester.pumpWidget(_wrap(PushStatusBanner(
        isArabic: true,
        service: service,
        initialReason: 'permission_denied',
      )));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.t(true, 'push_permission_denied')),
          findsOneWidget);
      expect(service.calls, 0);
    });

    testWidgets('سبب خادم غير معروف يُعرض مع رمزه', (tester) async {
      final service = _FakeService(const [
        PushRegistrationResult(registered: false, reason: 'api_500'),
      ]);
      await tester.pumpWidget(_wrap(PushStatusBanner(
          isArabic: true, service: service, initialReason: null)));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.t(true, 'push_enable')));
      await tester.pumpAndSettle();
      expect(find.textContaining('api_500'), findsOneWidget);
    });
  });
}
