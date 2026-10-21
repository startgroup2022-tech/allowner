import 'dart:convert';
import 'dart:typed_data';

import 'package:allowners/models/app_user.dart';
import 'package:allowners/screens/owner/owner_navigation_screen.dart';
import 'package:allowners/services/api_client.dart';
import 'package:allowners/theme/app_theme.dart';
import 'package:allowners/utils/session_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// إثبات أن التطبيق يوجّه **موظف الوحدة** (`unit_manager`) إلى واجهته
/// الصحيحة (المتطلب 75): يرى «الوحدات» و«طلبات الصيانة» ولا يرى تبويب
/// الإيرادات الممنوع عليه. المحوّل يخدم ردودًا بشكل الإنتاج لكل نقطة يطلبها
/// شريط التنقّل عند أول رسم.
class _Adapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    Object body;
    if (path.contains('owner-dashboard')) {
      body = {
        'success': true,
        'stats': {
          'units_count': 3,
          'bookings_count': 12,
          'pending_bookings': 2,
          'revenue': '12000',
        },
      };
    } else if (path.contains('owner-maintenance')) {
      body = {
        'success': true,
        'requests': [
          {
            'id': 7,
            'title': 'تسريب ماء',
            'status': 'in_progress',
            'hotel_name': 'فندق فيرمونت مكه',
            'unit_name': 'جناح عائلي',
          },
        ],
      };
    } else if (path.contains('owner-units')) {
      body = {
        'success': true,
        'units': [
          {'id': 13, 'name_ar': 'جناح عائلي', 'status': 'active'},
        ],
      };
    } else if (path.contains('notifications')) {
      body = {'success': true, 'notifications': []};
    } else {
      body = {'success': true};
    }
    return ResponseBody.fromString(jsonEncode(body), 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }
}

Widget _wrap(Widget child, SessionNotifier session) => ProviderScope(
      overrides: [sessionProvider.overrideWith((ref) => session)],
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
  late HttpClientAdapter original;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    original = ApiClient.instance.dio.httpClientAdapter;
    ApiClient.instance.dio.httpClientAdapter = _Adapter();
  });

  tearDown(() {
    ApiClient.instance.dio.httpClientAdapter = original;
  });

  Future<void> pumpAs(WidgetTester tester, String role) async {
    final session = SessionNotifier();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_wrap(const OwnerNavigationScreen(), session));
    await tester.pumpAndSettle();
    session.state = SessionState(
      user: AppUser(
        id: 9,
        fullName: 'مدير الوحدات',
        email: 'manager@example.com',
        role: role,
      ),
      isLoading: false,
    );
    await tester.pumpAndSettle();
  }

  // يقتصر البحث على شريط التنقّل السفلي لأن IndexedStack يبني كل التبويبات،
  // فقد تظهر نصوص داخل شاشات أخرى لا تعبّر عن التوجيه.
  Finder navLabel(String text) => find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.text(text),
      );

  group('توجيه موظف الوحدة (المتطلب 75)', () {
    testWidgets('موظف الوحدة يرى تبويب الصيانة لا الإيرادات', (tester) async {
      await pumpAs(tester, 'unit_manager');
      expect(tester.takeException(), isNull);
      // التبويب الأوسط يعرض «طلبات الصيانة» بدل «الإيرادات».
      expect(navLabel('طلبات الصيانة'), findsOneWidget);
      expect(navLabel('الإيرادات'), findsNothing);
    });

    testWidgets('موظف الوحدة يرى تبويب الوحدات (لا حجوزات الوكيل)',
        (tester) async {
      await pumpAs(tester, 'unit_manager');
      expect(tester.takeException(), isNull);
      expect(navLabel('وحداتي'), findsOneWidget);
      expect(navLabel('حجوزاتي'), findsNothing);
    });

    testWidgets('المالك يرى تبويب الإيرادات (تباين للتوجيه)', (tester) async {
      await pumpAs(tester, 'owner');
      expect(tester.takeException(), isNull);
      expect(navLabel('الإيرادات'), findsOneWidget);
      expect(navLabel('طلبات الصيانة'), findsNothing);
    });
  });
}
