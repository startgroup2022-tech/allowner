import 'dart:convert';
import 'dart:typed_data';

import 'package:allowners/screens/profile/delete_account_screen.dart';
import 'package:allowners/screens/profile/profile_screen.dart';
import 'package:allowners/services/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'screenshot_support.dart';

/// لقطات حذف الحساب من داخل التطبيق (سياسة Google Play).
///
/// تُصوَّر الشاشة في حالتين: النموذج بعد تأكيد المستخدم، وشاشة الإتمام بعد ردّ
/// السيرفر بالنجاح — إضافة إلى مدخل «حذف الحساب» في الملف الشخصي.
///
/// التشغيل: `HIRES_EXPORT=1 flutter test test/screenshot_export_account_deletion_test.dart`
class _DeleteAdapter implements HttpClientAdapter {
  _DeleteAdapter({this.upcoming = false});

  final bool upcoming;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    Object body;
    if (options.path.contains('bookings/my')) {
      body = {
        'success': true,
        'bookings': upcoming
            ? [
                {
                  'id': 91,
                  'hotel_name': 'فندق فيرمونت مكه',
                  'unit_number': '4005',
                  'check_in': '2026-12-02',
                  'check_out': '2026-12-05',
                  'status': 'confirmed',
                }
              ]
            : <Object>[],
      };
    } else if (options.path.contains('user/delete-account')) {
      body = {'success': true};
    } else if (options.path.contains('auth/me')) {
      body = {'success': true, 'user': currentUserJson ?? {}};
    } else {
      body = {'success': true};
    }
    return ResponseBody.fromString(jsonEncode(body), 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }
}

void main() {
  late HttpClientAdapter original;

  setUpAll(() async {
    await loadBrandFonts();
  });

  setUp(() {
    original = ApiClient.instance.dio.httpClientAdapter;
  });

  tearDown(() => restoreShotAdapter(original));

  void shot(
    String stem,
    String folder, {
    required Widget Function() build,
    String role = 'customer',
    double height = 900,
    Future<void> Function(WidgetTester tester)? interact,
    bool upcoming = false,
  }) {
    testWidgets('$stem-ar', (tester) async {
      setSession(role: role);
      ApiClient.instance.dio.httpClientAdapter =
          _DeleteAdapter(upcoming: upcoming);
      await capture(tester, build(), '$folder/arabic/$stem-ar.png',
          height: height, interact: interact);
    });

    testWidgets('$stem-en', (tester) async {
      setSession(role: role, name: 'Mohammed Ali', locale: 'en');
      ApiClient.instance.dio.httpClientAdapter =
          _DeleteAdapter(upcoming: upcoming);
      await capture(tester, build(), '$folder/english/$stem-en.png',
          isArabic: false, height: height, interact: interact);
    });
  }

  Future<void> fillAndSubmit(WidgetTester tester, {bool submit = false}) async {
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'حذف');
    await tester.pumpAndSettle();
    if (submit) {
      await tester.drag(find.byType(ListView), const Offset(0, -260));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
    }
  }

  group('حذف الحساب — سياسة Google Play', () {
    shot(
      'DOC06-POLICY-delete-account-form',
      'customer',
      build: () => const DeleteAccountScreen(),
      interact: (t) => fillAndSubmit(t),
    );

    shot(
      'DOC06-POLICY-delete-account-done',
      'customer',
      build: () => const DeleteAccountScreen(),
      interact: (t) => fillAndSubmit(t, submit: true),
    );

    shot(
      'DOC06-POLICY-delete-account-blocked',
      'customer',
      build: () => const DeleteAccountScreen(),
      upcoming: true,
    );

    shot(
      'DOC06-POLICY-profile-delete-entry',
      'customer',
      build: () => const ProfileScreen(),
      height: 1000,
      interact: (t) async {
        await t.drag(find.byType(Scrollable).first, const Offset(0, -320));
      },
    );
  });
}
