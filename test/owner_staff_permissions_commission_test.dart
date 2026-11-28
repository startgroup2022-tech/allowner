import 'dart:convert';
import 'dart:typed_data';

import 'package:allowners/screens/owner/owner_commission_screen.dart';
import 'package:allowners/screens/owner/owner_staff_screen.dart';
import 'package:allowners/services/api_client.dart';
import 'package:allowners/theme/app_theme.dart';
import 'package:allowners/utils/staff_permissions.dart';
import 'package:allowners/utils/staff_permissions_strings.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// المتطلبان 74 و108: صلاحيات موظفي المالك، وتحويل العمولات غير المدفوعة.
///
/// القاعدة المُختبَرة: التطبيق يرسل الطلب **فقط** ولا يخترع نجاحًا ولا يغيّر
/// رقمًا؛ رسالة النجاح الظاهرة هي رسالة السيرفر، والخطأ الظاهر خطأ السيرفر.

const _staffJson = {
  'success': true,
  'staff': [
    {
      'id': 12,
      'full_name': 'سالم الحربي',
      'email': 'salem@example.com',
      'phone': '0550000000',
      'role': 'unit_manager',
      'status': 'active',
      'permissions': {
        'can_manage_bookings': true,
        'can_manage_services': true,
        'can_check_in_out': false,
        'can_view_finance': false,
      },
    },
  ],
};

const _commissionJson = {
  'success': true,
  'commission_type': 'percentage',
  'commission_rate': '10',
  'total_bookings': 3,
  'total_commission': '450',
  'paid': '250',
  'unpaid': '200',
  'items': [
    {
      'booking_ref': 'BK-2002',
      'guest_name': 'عميل',
      'hotel_name': 'فندق',
      'booking_total': '1000',
      'amount': '100',
      'status': 'unpaid',
      'booking_status': 'confirmed',
    },
  ],
};

class _Recorder implements HttpClientAdapter {
  _Recorder({
    this.commissionBody = _commissionJson,
    this.postStatus = 200,
    this.postBody,
  });

  final Object staffBody = _staffJson;
  final Object commissionBody;
  final int postStatus;
  final Object? postBody;
  final List<Map<String, dynamic>> posts = [];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    if (options.method == 'POST') {
      Object? raw = options.data;
      if (raw is String) {
        try {
          raw = jsonDecode(raw);
        } catch (_) {}
      }
      posts.add({
        'path': path,
        'data': raw is Map ? Map<String, dynamic>.from(raw) : raw,
      });
      final body = postBody ?? {'success': true, 'message': 'تم الاستلام'};
      return ResponseBody.fromString(
        jsonEncode(body),
        postStatus,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    Object body;
    if (path.contains('owner-staff')) {
      body = staffBody;
    } else if (path.contains('agent-commission')) {
      body = commissionBody;
    } else {
      body = {'success': true};
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
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
  late HttpClientAdapter original;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    original = ApiClient.instance.dio.httpClientAdapter;
  });

  tearDown(() => ApiClient.instance.dio.httpClientAdapter = original);

  Future<void> pump(WidgetTester tester, Widget screen,
      {_Recorder? adapter, bool isArabic = true}) async {
    ApiClient.instance.dio.httpClientAdapter = adapter ?? _Recorder();
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_wrap(screen, isArabic: isArabic));
    await tester.pumpAndSettle();
  }

  group('StaffPermissions (المتطلب 74)', () {
    test('قراءة الصلاحيات من خريطة منطقية', () {
      final perms = parseStaffPermissions({
        'can_manage_bookings': false,
        'can_view_finance': true,
      }, role: 'unit_manager');
      expect(perms['can_manage_bookings'], isFalse);
      expect(perms['can_view_finance'], isTrue);
      // الحقل الغائب يأخذ صلاحية الدور بدل أن يُقرأ كـ false صامت
      expect(perms['can_manage_services'], isTrue);
    });

    test('قراءة الصلاحيات من قائمة أسماء', () {
      final perms = parseStaffPermissions(
          ['can_manage_bookings', 'can_check_in_out'],
          role: 'hotel_manager');
      expect(perms['can_manage_bookings'], isTrue);
      expect(perms['can_check_in_out'], isTrue);
      expect(perms['can_view_finance'], isFalse);
    });

    test('غياب الحقل = صلاحيات الدور', () {
      final perms = parseStaffPermissions(null, role: 'unit_manager');
      expect(perms, defaultStaffPermissions('unit_manager'));
    });

    test('الحمولة ترسل الخريطة كاملة تحت action=set_permissions', () {
      final payload = staffPermissionsPayload(
          staffId: 12, permissions: {'can_view_finance': true});
      expect(payload['action'], 'set_permissions');
      expect(payload['id'], 12);
      final sent = payload['permissions'] as Map;
      expect(sent.keys.toSet(), kStaffPermissionKeys.toSet());
      expect(sent['can_view_finance'], isTrue);
      expect(sent['can_manage_bookings'], isFalse);
    });

    test('كشف التغيير لا يعتبر الخريطة الفارغة تغييرًا', () {
      expect(staffPermissionsChanged(const {}, const {}), isFalse);
      expect(
          staffPermissionsChanged(
              {'can_view_finance': false}, {'can_view_finance': true}),
          isTrue);
    });

    test('منع منح الصلاحية المالية قبل الاشتراك', () {
      expect(
          staffPermissionBlockReason(
              permissions: {'can_view_finance': true},
              ownerSubscriptionActive: false),
          'staff_finance_needs_subscription');
      expect(
          staffPermissionBlockReason(
              permissions: {'can_view_finance': true},
              ownerSubscriptionActive: true),
          isNull);
    });

    test('التسميات عربية وإنجليزية لكل مفتاح', () {
      final ar = staffPermissionLabels(true);
      final en = staffPermissionLabels(false);
      for (final key in kStaffPermissionKeys) {
        expect(ar[key], isNotNull, reason: 'ناقص عربي: $key');
        expect(en[key], isNotNull, reason: 'ناقص إنجليزي: $key');
      }
      expect(ar['can_view_finance'], contains('المالية'));
      expect(en['can_view_finance'], 'View financial data');
    });
  });

  group('شاشة الموظفين (المتطلب 74)', () {
    testWidgets('تعرض صلاحيات الموظف الحالية على البطاقة', (tester) async {
      await pump(tester, const OwnerStaffScreen());
      expect(tester.takeException(), isNull);
      expect(find.text('الصلاحيات'), findsOneWidget);
      expect(find.text('إدارة الحجوزات'), findsWidgets);
      // can_check_in_out=false فلا يظهر
      expect(find.text('تسجيل الدخول والخروج'), findsNothing);
    });

    testWidgets('حفظ الصلاحيات يرسل set_permissions للحقل الصحيح',
        (tester) async {
      final adapter = _Recorder();
      await pump(tester, const OwnerStaffScreen(), adapter: adapter);

      await tester.tap(find.text('الصلاحيات'));
      await tester.pumpAndSettle();

      // تشغيل «تسجيل الدخول والخروج»
      final tile = find.text('تسجيل الدخول والخروج');
      expect(tile, findsOneWidget);
      await tester.tap(tile);
      await tester.pumpAndSettle();

      await tester.tap(find.text('حفظ').last);
      await tester.pumpAndSettle();

      final post = adapter.posts.single;
      expect(post['path'], contains('owner-staff'));
      final data = post['data'] as Map;
      expect(data['action'], 'set_permissions');
      expect(data['id'], 12);
      expect((data['permissions'] as Map)['can_check_in_out'], isTrue);
    });

    testWidgets('بلا تغيير لا يُرسل أي طلب', (tester) async {
      final adapter = _Recorder();
      await pump(tester, const OwnerStaffScreen(), adapter: adapter);

      await tester.tap(find.text('الصلاحيات'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('حفظ').last);
      await tester.pumpAndSettle();

      expect(adapter.posts, isEmpty);
      expect(find.text('لم تتغيّر أي صلاحية.'), findsOneWidget);
    });
  });

  group('العمولات والتحويل (المتطلب 108)', () {
    testWidgets('تظهر بطاقة طلب التحويل عند وجود عمولات غير مدفوعة',
        (tester) async {
      await pump(tester, const OwnerCommissionScreen());
      expect(tester.takeException(), isNull);
      expect(find.text('العمولات غير المدفوعة'), findsOneWidget);
      expect(find.text('طلب تحويل المستحقات'), findsOneWidget);
    });

    testWidgets('إرسال الطلب يستخدم المبلغ المعلن من السيرفر', (tester) async {
      final adapter = _Recorder();
      await pump(tester, const OwnerCommissionScreen(), adapter: adapter);

      await tester.tap(find.text('طلب تحويل المستحقات'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('طلب تحويل المستحقات').last);
      await tester.pumpAndSettle();

      final post = adapter.posts.single;
      expect(post['path'], contains('agent-commission'));
      final data = post['data'] as Map;
      expect(data['action'], 'request_transfer');
      expect(data['amount'], 200);
      // رسالة السيرفر هي ما يظهر، لا رسالة مُصطنعة
      expect(find.text('تم الاستلام'), findsOneWidget);
    });

    testWidgets('رفض السيرفر يظهر كخطأ ولا يُغلق النافذة', (tester) async {
      final adapter = _Recorder(
        postStatus: 400,
        postBody: {'success': false, 'message': 'التحويل غير متاح حاليًا'},
      );
      await pump(tester, const OwnerCommissionScreen(), adapter: adapter);

      await tester.tap(find.text('طلب تحويل المستحقات'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('طلب تحويل المستحقات').last);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('التحويل غير متاح'), findsOneWidget);
    });

    testWidgets('لا بطاقة تحويل بلا عمولات غير مدفوعة', (tester) async {
      final adapter = _Recorder(commissionBody: {
        'success': true,
        'commission_type': 'percentage',
        'commission_rate': '10',
        'total_bookings': 1,
        'total_commission': '100',
        'paid': '100',
        'unpaid': '0',
        'items': const [],
      });
      await pump(tester, const OwnerCommissionScreen(), adapter: adapter);
      expect(find.text('طلب تحويل المستحقات'), findsNothing);
    });

    testWidgets('الواجهة الإنجليزية تعرض المصطلح الإنجليزي', (tester) async {
      SharedPreferences.setMockInitialValues({'app_locale': 'en'});
      await pump(tester, const OwnerCommissionScreen(), isArabic: false);
      expect(tester.takeException(), isNull);
      expect(find.text('Unpaid commission'), findsOneWidget);
      expect(find.text('Request transfer'), findsWidgets);
    });
  });
}
