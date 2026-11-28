import 'dart:convert';
import 'dart:typed_data';

import 'package:allowners/models/app_user.dart';
import 'package:allowners/screens/services/hotel_services_screen.dart';
import 'package:allowners/services/api_client.dart';
import 'package:allowners/theme/app_theme.dart';
import 'package:allowners/utils/app_strings.dart';
import 'package:allowners/utils/service_request_store.dart';
import 'package:allowners/utils/locale_provider.dart';
import 'package:allowners/utils/session_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// المتطلب 59 — «إظهار حالة طلبات الخدمات للضيف».
///
/// المبدأ: الحالة تُعرض فقط إذا أعادها السيرفر. لا يُخترع «قيد الانتظار» لطلب
/// لم يُعلن السيرفر حالته، ولا تُعرض قائمة وهمية حين تغيب نقطة القراءة.
class _Adapter implements HttpClientAdapter {
  _Adapter({this.requestsStatus = 404, this.rows = const []});

  final int requestsStatus;
  final List<Map<String, dynamic>> rows;
  int calls = 0;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.contains('services/my-requests')) {
      calls++;
      if (requestsStatus != 200) {
        return ResponseBody.fromString(
          jsonEncode({'success': false, 'message': 'not implemented'}),
          requestsStatus,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      }
      return ResponseBody.fromString(
        jsonEncode({'success': true, 'requests': rows}),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode({'success': true}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

Widget _wrap(Widget child, SessionNotifier session, {bool isArabic = true}) =>
    ProviderScope(
      overrides: [
        sessionProvider.overrideWith((ref) => session),
        localeProvider.overrideWith((ref) => _FixedLocale(isArabic)),
      ],
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

/// لغة ثابتة للاختبار — `LocaleNotifier` يقرأ التفضيلات ويعود للعربية.
class _FixedLocale extends LocaleNotifier {
  _FixedLocale(bool isArabic) {
    state = Locale(isArabic ? 'ar' : 'en');
  }

  @override
  Future<void> toggleLocale() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('سجل الطلبات — ترميز وفك ترميز', () {
    test('الترميز والفك يعيدان نفس السجلات', () {
      final records = [
        ServiceRequestRecord(
          type: 'maintenance',
          id: 12,
          status: 'done',
          roomNumber: '402',
          description: 'مكيف',
          createdAt: DateTime(2026, 11, 1, 10, 30),
        ),
        ServiceRequestRecord(
          type: 'housekeeping',
          createdAt: DateTime(2026, 11, 2, 9),
        ),
      ];
      final decoded = decodeServiceRequests(encodeServiceRequests(records));
      expect(decoded, records);
    });

    test('نص تالف أو شكل غير متوقع يُرجع قائمة فارغة بلا استثناء', () {
      expect(decodeServiceRequests(null), isEmpty);
      expect(decodeServiceRequests(''), isEmpty);
      expect(decodeServiceRequests('not json'), isEmpty);
      expect(decodeServiceRequests('{"a":1}'), isEmpty);
      expect(decodeServiceRequests('[1,2,3]'), isEmpty);
    });

    test('سجل من استجابة السيرفر يحفظ الحالة كما أعلنها فقط', () {
      final withStatus = ServiceRequestRecord.fromServer(
        {
          'success': true,
          'request': {'id': 77, 'status': 'pending'},
        },
        type: 'maintenance',
        roomNumber: '101',
        now: DateTime(2026, 11, 3),
      );
      expect(withStatus.id, 77);
      expect(withStatus.status, 'pending');

      final withoutStatus = ServiceRequestRecord.fromServer(
        {'success': true},
        type: 'housekeeping',
        now: DateTime(2026, 11, 3),
      );
      expect(withoutStatus.id, isNull);
      expect(withoutStatus.status, isNull,
          reason: 'لا نُخترع «قيد الانتظار» حين لا يُعلنها السيرفر');
    });

    test('صف السيرفر يقبل الأسماء البديلة ويحوّل معرّفًا صفريًا إلى null', () {
      final row = ServiceRequestRecord.fromRemoteRow({
        'id': '0',
        'service_type': 'housekeeping',
        'unit_number': '305',
        'status': 'done',
        'created_at': '2026-11-04T08:00:00Z',
      });
      expect(row.type, 'housekeeping');
      expect(row.id, isNull);
      expect(row.roomNumber, '305');
      expect(row.status, 'done');
      expect(row.createdAt.toUtc().hour, 8);
    });
  });

  group('دمج القوائم — السيرفر هو المرجع', () {
    test('سجل السيرفر يستبدل نظيره المحلي بالمعرّف نفسه', () {
      final local = [
        ServiceRequestRecord(
          type: 'maintenance',
          id: 5,
          status: 'pending',
          createdAt: DateTime(2026, 11, 1),
        ),
      ];
      final remote = [
        ServiceRequestRecord(
          type: 'maintenance',
          id: 5,
          status: 'done',
          createdAt: DateTime(2026, 11, 1),
        ),
      ];
      final merged = mergeServiceRequests(local, remote);
      expect(merged, hasLength(1));
      expect(merged.single.status, 'done');
    });

    test('الطلبات المحلية بلا معرّف تبقى ظاهرة', () {
      final local = [
        ServiceRequestRecord(
          type: 'cancellation',
          createdAt: DateTime(2026, 11, 2),
        ),
      ];
      final remote = [
        ServiceRequestRecord(
          type: 'maintenance',
          id: 9,
          status: 'confirmed',
          createdAt: DateTime(2026, 11, 1),
        ),
      ];
      final merged = mergeServiceRequests(local, remote);
      expect(merged.map((r) => r.type), ['cancellation', 'maintenance'],
          reason: 'الأحدث أولًا');
    });

    test('السقف maxRecords يمنع نمو القائمة', () {
      final local = [
        for (var i = 1; i <= maxRecords + 5; i++)
          ServiceRequestRecord(
            type: 'maintenance',
            id: i,
            createdAt: DateTime(2026, 1, 1).add(Duration(minutes: i)),
          ),
      ];
      final merged = mergeServiceRequests(local, const []);
      expect(merged, hasLength(maxRecords));
      expect(merged.first.id, maxRecords + 5);
    });
  });

  group('التخزين المحلي', () {
    test('add يحفظ ويقرأ، ويستبدل التكرار بالمعرّف نفسه', () async {
      SharedPreferences.setMockInitialValues({});
      const store = ServiceRequestStore();
      final first = ServiceRequestRecord(
        type: 'maintenance',
        id: 3,
        status: 'pending',
        createdAt: DateTime(2026, 11, 1),
      );
      await store.add(first);
      await store.add(ServiceRequestRecord(
        type: 'maintenance',
        id: 3,
        status: 'done',
        createdAt: DateTime(2026, 11, 1),
      ));
      final loaded = await store.load();
      expect(loaded, hasLength(1));
      expect(loaded.single.status, 'done');
    });
  });

  group('شاشة الخدمات — قسم «طلباتي» (المتطلب 59)', () {
    late HttpClientAdapter originalAdapter;

    setUp(() {
      originalAdapter = ApiClient.instance.dio.httpClientAdapter;
    });

    tearDown(() {
      ApiClient.instance.dio.httpClientAdapter = originalAdapter;
    });

    Future<void> pumpScreen(WidgetTester tester, {bool isArabic = true}) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final session = SessionNotifier();
      await tester.pumpWidget(
        _wrap(const HotelServicesScreen(), session, isArabic: isArabic),
      );
      await tester.pumpAndSettle();
      session.state = SessionState(
        user: AppUser(
          id: 9,
          fullName: 'ضيف تجريبي',
          email: 'guest@example.com',
          role: 'guest',
        ),
        isLoading: false,
      );
      await tester.pumpAndSettle();
    }

    testWidgets('نقطة القراءة غائبة (404) → نعرض ما حفظناه ونقول ذلك صراحة',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        serviceRequestStoreKey: encodeServiceRequests([
          ServiceRequestRecord(
            type: 'maintenance',
            id: 41,
            status: 'done',
            roomNumber: '402',
            createdAt: DateTime(2026, 11, 1),
          ),
        ]),
      });
      ApiClient.instance.dio.httpClientAdapter = _Adapter(requestsStatus: 404);

      await pumpScreen(tester);

      expect(
          find.text(AppStrings.t(true, 'my_service_requests')), findsOneWidget);
      expect(find.textContaining('#41'), findsOneWidget);
      expect(find.text(AppStrings.t(true, 'status_done')), findsOneWidget);
      expect(
        find.text(AppStrings.t(true, 'service_requests_local_only')),
        findsOneWidget,
      );
    });

    testWidgets('لا سجلات و404 → حالة فارغة بلا ادّعاء', (tester) async {
      SharedPreferences.setMockInitialValues({});
      ApiClient.instance.dio.httpClientAdapter = _Adapter(requestsStatus: 404);

      await pumpScreen(tester);

      expect(
        find.text(AppStrings.t(true, 'no_service_requests')),
        findsOneWidget,
      );
      expect(find.text(AppStrings.t(true, 'status_done')), findsNothing);
    });

    testWidgets('السيرفر يُرجع الطلبات → حالته هي المعروضة', (tester) async {
      SharedPreferences.setMockInitialValues({
        serviceRequestStoreKey: encodeServiceRequests([
          ServiceRequestRecord(
            type: 'maintenance',
            id: 41,
            status: 'pending',
            createdAt: DateTime(2026, 11, 1),
          ),
        ]),
      });
      ApiClient.instance.dio.httpClientAdapter = _Adapter(
        requestsStatus: 200,
        rows: [
          {
            'id': 41,
            'type': 'maintenance',
            'status': 'confirmed',
            'room_number': '402',
            'created_at': '2026-11-01T10:00:00Z',
          },
        ],
      );

      await pumpScreen(tester);

      expect(find.text(AppStrings.t(true, 'status_confirmed')), findsOneWidget);
      expect(find.text(AppStrings.t(true, 'status_pending')), findsNothing,
          reason: 'حالة السيرفر تستبدل الحالة المحلية القديمة');
      expect(
        find.text(AppStrings.t(true, 'service_requests_local_only')),
        findsNothing,
        reason: 'الحالة الحيّة متاحة فلا داعي للنص البديل',
      );
    });

    testWidgets('طلب بلا حالة من السيرفر يظهر بشرطة لا بحالة مُختلقة',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        serviceRequestStoreKey: encodeServiceRequests([
          ServiceRequestRecord(
            type: 'housekeeping',
            id: 8,
            createdAt: DateTime(2026, 11, 2),
          ),
        ]),
      });
      ApiClient.instance.dio.httpClientAdapter = _Adapter(
        requestsStatus: 200,
        rows: [
          {
            'id': 8,
            'type': 'housekeeping',
            'created_at': '2026-11-02T10:00:00Z',
          },
        ],
      );

      await pumpScreen(tester);

      expect(find.text(AppStrings.t(true, 'status_unknown')), findsOneWidget);
      expect(find.text(AppStrings.t(true, 'status_pending')), findsNothing);
    });

    testWidgets('التسميات الإنجليزية تُعرض بالإنجليزية', (tester) async {
      SharedPreferences.setMockInitialValues({
        serviceRequestStoreKey: encodeServiceRequests([
          ServiceRequestRecord(
            type: 'housekeeping',
            id: 8,
            status: 'rejected',
            createdAt: DateTime(2026, 11, 2),
          ),
        ]),
      });
      ApiClient.instance.dio.httpClientAdapter = _Adapter(requestsStatus: 404);

      await pumpScreen(tester, isArabic: false);

      expect(find.text('My Requests'), findsOneWidget);
      expect(find.text('Rejected'), findsOneWidget);
      expect(
          find.textContaining('not enabled on the server yet'), findsOneWidget);
    });
  });
}
