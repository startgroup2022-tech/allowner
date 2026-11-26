import 'dart:convert';

import 'package:allowners/models/hotel_model.dart';
import 'package:allowners/screens/booking/booking_screen.dart';
import 'package:allowners/screens/booking/booking_success_screen.dart';
import 'package:allowners/screens/bookings/my_bookings_screen.dart';
import 'package:allowners/screens/favorites/favorites_screen.dart';
import 'package:allowners/screens/home/home_screen.dart';
import 'package:allowners/screens/hotel/hotel_details_screen.dart';
import 'package:allowners/screens/profile/profile_screen.dart';
import 'package:allowners/screens/search/search_screen.dart';
import 'package:allowners/screens/unit/unit_details_screen.dart';
import 'package:allowners/services/api_client.dart';
import 'package:allowners/utils/app_strings.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'screenshot_support.dart';

/// توليد لقطات الشاشة الحقيقية — شاشات الضيف (المستندان 05 و06).
///
/// التشغيل: `flutter test test/screenshot_export_test.dart --update-goldens`
/// المخرجات: `docs/evidence/final-acceptance/<role>/<lang>/<file>.png`
void main() {
  late HttpClientAdapter original;

  setUpAll(() async {
    await loadBrandFonts();
  });

  setUp(() {
    original = ApiClient.instance.dio.httpClientAdapter;
    installShotAdapter();
    setSession();
  });

  tearDown(() => restoreShotAdapter(original));

  final hotel = HotelModel.fromJson(
      Map<String, dynamic>.from(hotelDetailJson['hotel'] as Map));

  group('الرئيسية', () {
    testWidgets('DOC05-REQ-010-018-home-ar', (tester) async {
      await capture(tester, const HomeScreen(),
          'customer/arabic/DOC05-REQ-010-018-home-ar.png');
    });

    testWidgets('DOC05-REQ-013-016-home-en', (tester) async {
      setSession(locale: 'en');
      await capture(tester, const HomeScreen(),
          'customer/english/DOC05-REQ-013-016-home-en.png',
          isArabic: false);
    });

    testWidgets('DOC06-REQ-A-001-home-section-order-ar', (tester) async {
      await capture(
        tester,
        const HomeScreen(),
        'customer/arabic/DOC06-REQ-A-001-home-section-order-ar.png',
        height: 2320,
        interact: (t) async {
          await t.drag(find.byType(Scrollable).first, const Offset(0, -760));
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets('DOC06-REQ-A-001-home-section-order-en', (tester) async {
      setSession(locale: 'en');
      await capture(
        tester,
        const HomeScreen(),
        'customer/english/DOC06-REQ-A-001-home-section-order-en.png',
        isArabic: false,
        height: 2320,
        interact: (t) async {
          await t.drag(find.byType(Scrollable).first, const Offset(0, -760));
          await t.pumpAndSettle();
        },
      );
    });
  });

  group('البحث', () {
    testWidgets('DOC05-REQ-019-search-results-ar', (tester) async {
      await capture(tester, const SearchScreen(initialQuery: 'مكة'),
          'customer/arabic/DOC05-REQ-019-search-results-ar.png');
    });

    testWidgets('DOC05-REQ-019-search-results-en', (tester) async {
      setSession(locale: 'en');
      await capture(tester, const SearchScreen(initialQuery: 'Makkah'),
          'customer/english/DOC05-REQ-019-search-results-en.png',
          isArabic: false);
    });

    testWidgets('DOC05-REQ-019-search-empty-ar', (tester) async {
      await capture(tester, const SearchScreen(initialQuery: ''),
          'customer/arabic/DOC05-REQ-019-search-empty-ar.png');
    });

    testWidgets('DOC05-REQ-019-search-error-ar', (tester) async {
      installShotAdapter(failPath: 'hotels/list');
      await capture(tester, const SearchScreen(initialQuery: 'مكة'),
          'customer/arabic/DOC05-REQ-019-search-error-ar.png');
    });
  });

  group('الفندق والوحدة', () {
    testWidgets('DOC05-REQ-028-030-hotel-details-ar', (tester) async {
      await capture(tester, HotelDetailsScreen(hotel: hotel),
          'customer/arabic/DOC05-REQ-028-030-hotel-details-ar.png');
    });

    testWidgets('DOC05-REQ-028-030-hotel-details-en', (tester) async {
      setSession(locale: 'en');
      await capture(tester, HotelDetailsScreen(hotel: hotel),
          'customer/english/DOC05-REQ-028-030-hotel-details-en.png',
          isArabic: false);
    });

    testWidgets('DOC06-REQ-002-hotel-unit-search-ar', (tester) async {
      await capture(
        tester,
        HotelDetailsScreen(hotel: hotel),
        'customer/arabic/DOC06-REQ-002-hotel-unit-search-ar.png',
        interact: (t) async {
          await t.drag(find.byType(Scrollable).first, const Offset(0, -420));
          await t.pumpAndSettle();
          await t.enterText(find.byType(TextField).first, '402');
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets('DOC05-REQ-030-unit-details-ar', (tester) async {
      await capture(tester, const UnitDetailsScreen(unitId: 13),
          'customer/arabic/DOC05-REQ-030-unit-details-ar.png');
    });

    testWidgets('DOC05-REQ-030-unit-details-en', (tester) async {
      setSession(locale: 'en');
      await capture(tester, const UnitDetailsScreen(unitId: 13),
          'customer/english/DOC05-REQ-030-unit-details-en.png',
          isArabic: false);
    });
  });

  group('الحجز', () {
    testWidgets('DOC05-REQ-031-034-booking-ar', (tester) async {
      await capture(tester, BookingScreen(hotel: hotel, unitId: 13),
          'customer/arabic/DOC05-REQ-031-034-booking-ar.png');
    });

    testWidgets('DOC05-REQ-031-034-booking-en', (tester) async {
      setSession(locale: 'en');
      await capture(tester, BookingScreen(hotel: hotel, unitId: 13),
          'customer/english/DOC05-REQ-031-034-booking-en.png',
          isArabic: false);
    });

    testWidgets('DOC06-REQ-B-002-booking-extra-bed-ar', (tester) async {
      // مسار الحجز على مستوى الفندق (بلا وحدة محددة) هو المسار الذي يعرض
      // بطاقة السرير الإضافي مع عدّاد الكمية وسطر الحساب.
      await capture(
        tester,
        BookingScreen(hotel: hotel),
        'customer/arabic/DOC06-REQ-B-002-booking-extra-bed-ar.png',
        height: 2600,
        interact: (t) async {
          expect(hotel.extraBedPrice, 150,
              reason: 'سعر السرير الإضافي يجب أن يُقرأ من حمولة الفندق');
          final labels = find.text(AppStrings.t(true, 'add_extra_bed'));
          for (var i = 0; i < 8 && labels.evaluate().isEmpty; i++) {
            await t.drag(find.byType(Scrollable).first, const Offset(0, -260));
            await t.pumpAndSettle();
          }
          expect(labels, findsWidgets,
              reason: 'بطاقة السرير الإضافي يجب أن تُبنى داخل صفحة الحجز');
          Finder? switchFinder;
          for (var i = 0; i < labels.evaluate().length; i++) {
            final row = find
                .ancestor(of: labels.at(i), matching: find.byType(Row))
                .first;
            final sw = find.descendant(of: row, matching: find.byType(Switch));
            if (sw.evaluate().isNotEmpty) {
              switchFinder = sw;
              break;
            }
          }
          expect(switchFinder, isNotNull);
          await t.tap(switchFinder!);
          await t.pumpAndSettle();
          await t.tap(find.byIcon(Icons.add_circle_outline_rounded).first);
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets('DOC05-REQ-033-booking-payment-methods-ar', (tester) async {
      await capture(
        tester,
        BookingScreen(hotel: hotel, unitId: 13),
        'customer/arabic/DOC05-REQ-033-booking-payment-methods-ar.png',
        interact: (t) async {
          await t.drag(find.byType(Scrollable).first, const Offset(0, -900));
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets('DOC06-REQ-003-005-booking-success-ar', (tester) async {
      await capture(
        tester,
        BookingSuccessScreen(
          hotel: hotel,
          bookingRef: 'BK-2088',
          unitNumber: '402',
          unitName: 'جناح عائلي',
          total: 1950,
          checkIn: DateTime(2026, 11, 1),
          checkOut: DateTime(2026, 11, 3),
          nights: 2,
          guests: 2,
          guestName: 'محمد علي',
          guestPhone: '0500000000',
        ),
        'customer/arabic/DOC06-REQ-003-005-booking-success-ar.png',
        height: 1200,
      );
    });

    testWidgets('DOC06-REQ-003-005-booking-success-en', (tester) async {
      setSession(locale: 'en');
      await capture(
        tester,
        BookingSuccessScreen(
          hotel: hotel,
          bookingRef: 'BK-2088',
          unitNumber: '402',
          unitName: 'Family suite',
          total: 1950,
          checkIn: DateTime(2026, 11, 1),
          checkOut: DateTime(2026, 11, 3),
          nights: 2,
          guests: 2,
          guestName: 'محمد علي',
          guestPhone: '0500000000',
        ),
        'customer/english/DOC06-REQ-003-005-booking-success-en.png',
        isArabic: false,
        height: 1200,
      );
    });
  });

  group('ضيافاتي', () {
    testWidgets('DOC06-REQ-006-my-bookings-ar', (tester) async {
      await capture(tester, const MyBookingsScreen(),
          'customer/arabic/DOC06-REQ-006-my-bookings-ar.png');
    });

    testWidgets('DOC06-REQ-006-my-bookings-en', (tester) async {
      setSession(locale: 'en');
      await capture(tester, const MyBookingsScreen(),
          'customer/english/DOC06-REQ-006-my-bookings-en.png',
          isArabic: false);
    });

    testWidgets('DOC06-REQ-006-stay-details-sheet-ar', (tester) async {
      await capture(
        tester,
        const MyBookingsScreen(),
        'customer/arabic/DOC06-REQ-006-stay-details-sheet-ar.png',
        height: 1200,
        interact: (t) async {
          final action = find.text(AppStrings.t(true, 'view_my_stay_details'));
          if (action.evaluate().isNotEmpty) {
            await t.tap(action.first);
            await t.pumpAndSettle();
          }
        },
      );
    });
  });

  group('الحساب', () {
    testWidgets('DOC05-REQ-144-profile-ar', (tester) async {
      await capture(tester, const ProfileScreen(),
          'customer/arabic/DOC05-REQ-144-profile-ar.png',
          height: 1400);
    });

    testWidgets('DOC05-REQ-020-favorites-empty-ar', (tester) async {
      await capture(tester, const FavoritesScreen(),
          'customer/arabic/DOC05-REQ-020-favorites-empty-ar.png');
    });
  });
}
