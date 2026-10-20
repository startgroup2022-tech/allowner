import 'dart:convert';
import 'dart:typed_data';

import 'package:allowners/screens/owner/owner_subscription_screen.dart';
import 'package:allowners/screens/owner/owner_wallet_screen.dart';
import 'package:allowners/services/api_client.dart';
import 'package:allowners/theme/app_theme.dart';
import 'package:allowners/utils/app_strings.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// اختبارات عرض شاشات المحفظة والاشتراك (المتطلبات 121–143).
///
/// الهدف إثبات أن الشاشات:
///   • تُبنى وتُرسم بلا استثناء على العروض المطلوبة (360/390/768)،
///   • تعرض الأرقام الحقيقية عندما يعيدها السيرفر،
///   • وتعرض حالة «غير مُفعَّلة على السيرفر» عند 404 بدل أصفار مضلِّلة.
///
/// الحمولات منسوخة من شكل استجابة `content/settings.php` الحقيقي، والحمولة
/// الفارغة تُحاكي غياب endpoint المحفظة (404) وهو الواقع المُتحقَّق منه.
const _settingsJson = {
  'success': true,
  'commission_percent': '10',
  'subscription_annual_fee': 500,
  'subscription_active': '1',
  'currency': 'SAR',
};

const _walletJson = {
  'success': true,
  'balance': '1500.50',
  'commission': 150,
  'expenses': '100',
  'reserved': 200,
  'ledger': [
    {
      'type': 'booking',
      'amount': 500,
      'date': '2026-10-01',
    },
    {'type': 'commission', 'amount': -50, 'date': '2026-10-02'},
    {'type': 'weird', 'amount': 10},
  ],
};

class _Adapter implements HttpClientAdapter {
  _Adapter({this.walletNotFound = false, this.walletBody});
  final bool walletNotFound;
  final Object? walletBody;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    if (path.contains('owner-wallet')) {
      if (walletNotFound) {
        return ResponseBody.fromString('{"success":false}', 404, headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        });
      }
      return _json(walletBody ?? _walletJson);
    }
    if (path.contains('content/settings')) {
      return _json(_settingsJson);
    }
    return _json({'success': true});
  }

  ResponseBody _json(Object body) => ResponseBody.fromString(
        jsonEncode(body),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
}

Widget _wrap(Widget child, {bool isArabic = true}) {
  return ProviderScope(
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
}

void main() {
  late HttpClientAdapter _original;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _original = ApiClient.instance.dio.httpClientAdapter;
  });

  tearDown(() {
    ApiClient.instance.dio.httpClientAdapter = _original;
  });

  void useAdapter(HttpClientAdapter a) =>
      ApiClient.instance.dio.httpClientAdapter = a;

  group('شاشة الاشتراك السنوي (121–125)', () {
    for (final w in const [360.0, 390.0, 768.0]) {
      testWidgets('تُرسم بلا تجاوز على ${w.toInt()}px', (tester) async {
        useAdapter(_Adapter());
        tester.view.physicalSize = Size(w, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_wrap(const OwnerSubscriptionScreen()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text(AppStrings.t(true, 'subscription_active')),
            findsOneWidget);
        // المتطلب 125: نسبة العمولة والرسم من الإعدادات الحقيقية
        expect(find.text('10%'), findsOneWidget);
        expect(find.text('500 SAR'), findsOneWidget);
      });
    }

    testWidgets('زر التفعيل معطّل (لا مزوّد دفع) ويشرح السبب', (tester) async {
      useAdapter(_Adapter());
      await tester.pumpWidget(_wrap(const OwnerSubscriptionScreen()));
      await tester.pumpAndSettle();

      final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(btn.onPressed, isNull);
      expect(find.text(AppStrings.t(true, 'subscription_payment_pending')),
          findsOneWidget);
    });
  });

  group('شاشة المحفظة (132–143)', () {
    testWidgets('تعرض الأرقام الحقيقية وكشف الحساب', (tester) async {
      useAdapter(_Adapter());
      await tester.pumpWidget(_wrap(const OwnerWalletScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.t(true, 'wallet_balance')), findsOneWidget);
      expect(find.text(AppStrings.t(true, 'wallet_ledger')), findsOneWidget);
      // 1500.50 − 200 − 100 = 1200.5، ويُعرض بالتقريب الصحيح لنفس الدالة
      final expected =
          '${(1200.5).toStringAsFixed(0)} ${AppStrings.t(true, 'sar')}';
      expect(find.text(expected), findsOneWidget);
      // سطور الكشف الحقيقية — النوع المجهول يُصنَّف «حركة أخرى» وقد يكون
      // أسفل الشاشة، فنمرّر إليه.
      expect(find.text(AppStrings.t(true, 'ledger_booking')), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text(AppStrings.t(true, 'ledger_other')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(AppStrings.t(true, 'ledger_other')), findsOneWidget);
    });

    testWidgets('عند غياب endpoint المحفظة (404) تعرض حالة صريحة لا أصفار',
        (tester) async {
      useAdapter(_Adapter(walletNotFound: true));
      await tester.pumpWidget(_wrap(const OwnerWalletScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
          find.text(AppStrings.t(true, 'wallet_unavailable')), findsOneWidget);
      expect(find.text('0 ${AppStrings.t(true, 'sar')}'), findsNothing);
    });

    testWidgets('عند غياب كل الأرقام تعرض حالة غير مُفعَّلة', (tester) async {
      useAdapter(_Adapter(walletBody: {'success': true}));
      await tester.pumpWidget(_wrap(const OwnerWalletScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
          find.text(AppStrings.t(true, 'wallet_unavailable')), findsOneWidget);
    });

    for (final w in const [360.0, 768.0]) {
      testWidgets('تُرسم بلا تجاوز على ${w.toInt()}px', (tester) async {
        useAdapter(_Adapter());
        tester.view.physicalSize = Size(w, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_wrap(const OwnerWalletScreen()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    }
  });
}
