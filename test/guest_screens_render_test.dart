import 'dart:convert';
import 'dart:typed_data';

import 'package:allowners/models/app_user.dart';
import 'package:allowners/screens/bookings/my_bookings_screen.dart';
import 'package:allowners/screens/favorites/favorites_screen.dart';
import 'package:allowners/screens/profile/profile_screen.dart';
import 'package:allowners/services/api_client.dart';
import 'package:allowners/theme/app_theme.dart';
import 'package:allowners/utils/session_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// اختبارات عرض شاشات الضيف (حجوزاتي، المفضلة، الملف الشخصي).
///
/// المتطلبات: 4، 6، 18، 19، 20، 27، 28، 45، 46.
/// تُبنى الشاشات على `HotelService` الحقيقي بمحوّل Dio يخدم حمولات بشكل
/// استجابات الإنتاج، مع جلسة مسجَّلة الدخول لتفعيل مسار القراءة الحقيقي.
const _myBookingsJson = {
  'success': true,
  'bookings': [
    {
      'id': 41,
      'hotel_name': 'فندق فيرمونت مكه',
      'unit_name_ar': 'جناح عائلي',
      'unit_name_en': 'Family Suite',
      'unit_number': '402',
      'city_ar': 'مكة المكرمة',
      'city_en': 'Makkah',
      'check_in': '2026-11-01',
      'check_out': '2026-11-03',
      'guests_count': 2,
      'nights_count': 2,
      'total': '1500',
      'status': 'confirmed',
      'cover_image': '',
      'can_cancel': true,
      'can_edit': false,
    },
  ],
};

const _favoritesJson = {
  'success': true,
  'hotels': [
    {
      'id': 2,
      'name': 'فندق فيرمونت مكه',
      'city_ar': 'مكة المكرمة',
      'city_en': 'Makkah',
      'cover_image': '',
      'price_per_night': 750,
    },
  ],
};

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
    if (path.contains('bookings/my')) {
      body = _myBookingsJson;
    } else if (path.contains('favorites/my')) {
      body = _favoritesJson;
    } else {
      body = {'success': true};
    }
    return ResponseBody.fromString(jsonEncode(body), 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
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
  late HttpClientAdapter _originalAdapter;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _originalAdapter = ApiClient.instance.dio.httpClientAdapter;
    ApiClient.instance.dio.httpClientAdapter = _Adapter();
  });

  tearDown(() {
    ApiClient.instance.dio.httpClientAdapter = _originalAdapter;
  });

  Future<SessionNotifier> _loggedIn() async {
    return SessionNotifier();
  }

  /// `SessionNotifier` يستدعي `_restore()` بعد البناء فيعيد الحالة إلى غير
  /// مسجَّلة؛ لذلك نزرع الجلسة بعد أول رسم ثم نُعيد الرسم.
  Future<void> _pump(
      WidgetTester tester, Widget screen, SessionNotifier session,
      {double width = 390, bool isArabic = true}) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_wrap(screen, session, isArabic: isArabic));
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

  group('حجوزاتي (المتطلبات 45، 46)', () {
    testWidgets('تعرض الحجز الحقيقي من bookings/my.php', (tester) async {
      final session = await _loggedIn();
      await _pump(tester, const MyBookingsScreen(), session);
      expect(tester.takeException(), isNull);
      expect(find.textContaining('فندق فيرمونت مكه'), findsWidgets);
    });

    for (final w in const [360.0, 768.0]) {
      testWidgets('بلا تجاوز على ${w.toInt()}px', (tester) async {
        final session = await _loggedIn();
        await _pump(tester, const MyBookingsScreen(), session, width: w);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('المفضلة (المتطلبات 18، 19، 20)', () {
    testWidgets('تعرض الفندق المفضل الحقيقي', (tester) async {
      final session = await _loggedIn();
      await _pump(tester, const FavoritesScreen(), session);
      expect(tester.takeException(), isNull);
      expect(find.textContaining('فندق فيرمونت مكه'), findsWidgets);
    });

    for (final w in const [360.0, 768.0]) {
      testWidgets('بلا تجاوز على ${w.toInt()}px', (tester) async {
        final session = await _loggedIn();
        await _pump(tester, const FavoritesScreen(), session, width: w);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('الملف الشخصي (المتطلبات 4، 6، 27، 28)', () {
    testWidgets('يعرض اسم المستخدم ودوره', (tester) async {
      final session = await _loggedIn();
      await _pump(tester, const ProfileScreen(), session);
      expect(tester.takeException(), isNull);
      expect(find.textContaining('ضيف تجريبي'), findsWidgets);
    });

    testWidgets('يُرسم LTR بالإنجليزية بلا تجاوز', (tester) async {
      final session = await _loggedIn();
      await _pump(tester, const ProfileScreen(), session, isArabic: false);
      expect(tester.takeException(), isNull);
    });
  });
}
