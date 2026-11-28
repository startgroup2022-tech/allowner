import 'dart:convert';
import 'dart:typed_data';

import 'package:allowners/screens/owner/owner_bookings_screen.dart';
import 'package:allowners/services/api_client.dart';
import 'package:allowners/theme/app_theme.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// إثبات أن زرّي «تأكيد الحجز» و«إلغاء الحجز» في تطبيق المالك يُرسلان فعلًا
/// الطلب الصحيح إلى `/user/owner-bookings.php` (المتطلبان 37 و38) — لا أن
/// الشاشة تُرسم فقط. المحوّل يسجّل كل POST ويخدم قائمة حجوزات بشكل الإنتاج.
class _RecordingAdapter implements HttpClientAdapter {
  final posts = <Map<String, dynamic>>[];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.method.toUpperCase() == 'POST') {
      final raw = options.data is String
          ? options.data as String
          : jsonEncode(options.data ?? const {});
      posts.add(jsonDecode(raw) as Map<String, dynamic>);
      return ResponseBody.fromString(jsonEncode({'success': true}), 200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          });
    }
    // GET: قائمة الحجوزات. الحجز بانتظار المالك: can_confirm=true،
    // وحجز مؤكد قابل للإلغاء: can_cancel=true.
    return ResponseBody.fromString(
      jsonEncode({
        'success': true,
        'bookings': [
          {
            'id': 31,
            'booking_ref': 'BK-1001',
            'guest_name': 'محمد علي',
            'guest_phone': '0500000000',
            'hotel_name': 'فندق فيرمونت مكه',
            'unit_name': 'جناح عائلي',
            'check_in': '2026-11-01',
            'check_out': '2026-11-03',
            'total': '1500',
            'status': 'pending',
            'can_confirm': true,
            'can_edit': false,
            'can_cancel': true,
          },
        ],
      }),
      200,
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
  late _RecordingAdapter adapter;
  late HttpClientAdapter original;

  setUp(() {
    SharedPreferences.setMockInitialValues({'auth_token': 'test-token'});
    adapter = _RecordingAdapter();
    original = ApiClient.instance.dio.httpClientAdapter;
    ApiClient.instance.dio.httpClientAdapter = adapter;
  });

  tearDown(() {
    ApiClient.instance.dio.httpClientAdapter = original;
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_wrap(const OwnerBookingsScreen()));
    await tester.pumpAndSettle();
  }

  testWidgets('المتطلب 35: البطاقة تعرض الضيف والوحدة والتواريخ والإجمالي',
      (tester) async {
    await pump(tester);
    expect(tester.takeException(), isNull);
    expect(find.textContaining('محمد علي'), findsWidgets);
    expect(find.textContaining('فندق فيرمونت مكه'), findsWidgets);
    expect(find.textContaining('2026-11-01'), findsWidgets);
    expect(find.textContaining('2026-11-03'), findsWidgets);
    expect(find.textContaining('1500'), findsWidgets);
  });

  testWidgets('المتطلب 37: تأكيد الحجز يُرسل action=confirm مع رقم الحجز',
      (tester) async {
    await pump(tester);
    await tester.tap(find.text('تأكيد الحجز'));
    await tester.pumpAndSettle();
    // مربّع حوار التأكيد ثم «تأكيد».
    await tester.tap(find.text('تأكيد'));
    await tester.pumpAndSettle();

    expect(adapter.posts, hasLength(1));
    expect(adapter.posts.single['booking_id'], 31);
    expect(adapter.posts.single['action'], 'confirm');
  });

  testWidgets('المتطلب 38: إلغاء الحجز يُرسل action=cancel مع رقم الحجز',
      (tester) async {
    await pump(tester);
    await tester.tap(find.text('إلغاء الحجز'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تأكيد'));
    await tester.pumpAndSettle();

    expect(adapter.posts, hasLength(1));
    expect(adapter.posts.single['booking_id'], 31);
    expect(adapter.posts.single['action'], 'cancel');
  });

  testWidgets('رفض مربّع الحوار لا يُرسل أي طلب', (tester) async {
    await pump(tester);
    await tester.tap(find.text('تأكيد الحجز'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();

    expect(adapter.posts, isEmpty);
  });
}
