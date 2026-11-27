import 'package:allowners/screens/hotel_staff/hotel_arrivals_screen.dart';
import 'package:allowners/screens/hotel_staff/hotel_bookings_screen.dart';
import 'package:allowners/screens/hotel_staff/hotel_dashboard_screen.dart';
import 'package:allowners/screens/hotel_staff/hotel_departures_screen.dart';
import 'package:allowners/screens/hotel_staff/hotel_meal_pricing_screen.dart';
import 'package:allowners/screens/hotel_staff/hotel_prices_screen.dart';
import 'package:allowners/screens/hotel_staff/hotel_requests_screen.dart';
import 'package:allowners/screens/hotel_staff/hotel_staff_navigation_screen.dart';
import 'package:allowners/screens/hotel_staff/hotel_unit_pricing_screen.dart';
import 'package:allowners/screens/owner/owner_bookings_screen.dart';
import 'package:allowners/screens/owner/owner_bank_screen.dart';
import 'package:allowners/screens/owner/owner_cleaning_screen.dart';
import 'package:allowners/screens/owner/owner_clients_screen.dart';
import 'package:allowners/screens/owner/owner_commission_screen.dart';
import 'package:allowners/screens/owner/owner_extra_bed_screen.dart';
import 'package:allowners/screens/owner/owner_home_screen.dart';
import 'package:allowners/screens/owner/owner_maintenance_screen.dart';
import 'package:allowners/screens/owner/owner_meal_requests_screen.dart';
import 'package:allowners/screens/owner/owner_navigation_screen.dart';
import 'package:allowners/screens/owner/owner_notifications_screen.dart';
import 'package:allowners/screens/owner/owner_revenue_screen.dart';
import 'package:allowners/screens/owner/owner_service_prices_screen.dart';
import 'package:allowners/screens/owner/owner_staff_screen.dart';
import 'package:allowners/screens/owner/owner_subscription_screen.dart';
import 'package:allowners/screens/owner/owner_units_screen.dart';
import 'package:allowners/screens/owner/owner_wallet_screen.dart';
import 'package:allowners/services/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'screenshot_support.dart';

/// توليد لقطات الشاشة الحقيقية — إدارة الفندق، المالك، الوكيل، موظف المالك.
///
/// التشغيل: `flutter test test/screenshot_export_roles_test.dart --update-goldens`
void main() {
  late HttpClientAdapter original;

  setUpAll(loadBrandFonts);

  setUp(() {
    original = ApiClient.instance.dio.httpClientAdapter;
    installShotAdapter();
    setSession(role: 'hotel_manager', name: 'مدير الفندق');
  });

  tearDown(() => restoreShotAdapter(original));

  group('إدارة الفندق (المتطلبات 78–92، المستند 06 §F)', () {
    testWidgets('DOC05-REQ-080-hotel-dashboard-ar', (tester) async {
      await capture(tester, const HotelDashboardScreen(),
          'hotel-staff/arabic/DOC05-REQ-080-hotel-dashboard-ar.png');
    });

    testWidgets('DOC05-REQ-080-hotel-dashboard-en', (tester) async {
      setSession(role: 'hotel_manager', name: 'Hotel Manager', locale: 'en');
      await capture(tester, const HotelDashboardScreen(),
          'hotel-staff/english/DOC05-REQ-080-hotel-dashboard-en.png',
          isArabic: false);
    });

    testWidgets('DOC05-REQ-080-dashboard-navigation-ar', (tester) async {
      await capture(tester, const HotelStaffNavigationScreen(),
          'hotel-staff/arabic/DOC05-REQ-080-staff-navigation-ar.png');
    });

    testWidgets('DOC05-REQ-081-arrivals-ar', (tester) async {
      await capture(tester, const HotelArrivalsScreen(),
          'hotel-staff/arabic/DOC05-REQ-081-arrivals-ar.png');
    });

    testWidgets('DOC06-REQ-F-002-arrivals-search-ar', (tester) async {
      await capture(
        tester,
        const HotelArrivalsScreen(),
        'hotel-staff/arabic/DOC06-REQ-F-002-arrivals-search-ar.png',
        interact: (t) async {
          await t.enterText(find.byType(TextField).first, '402');
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets('DOC06-REQ-F-002-arrivals-empty-ar', (tester) async {
      await capture(
        tester,
        const HotelArrivalsScreen(),
        'hotel-staff/arabic/DOC06-REQ-F-002-arrivals-empty-ar.png',
        interact: (t) async {
          await t.enterText(find.byType(TextField).first, '9999');
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets('DOC06-REQ-009-departures-search-ar', (tester) async {
      await capture(
        tester,
        const HotelDeparturesScreen(),
        'hotel-staff/arabic/DOC06-REQ-009-departures-search-ar.png',
        interact: (t) async {
          await t.enterText(find.byType(TextField).first, '1205');
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets('DOC06-REQ-009-departures-search-en', (tester) async {
      setSession(role: 'hotel_manager', name: 'Hotel Manager', locale: 'en');
      await capture(
        tester,
        const HotelDeparturesScreen(),
        'hotel-staff/english/DOC06-REQ-009-departures-search-en.png',
        isArabic: false,
        interact: (t) async {
          await t.enterText(find.byType(TextField).first, '1205');
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets('DOC05-REQ-082-hotel-bookings-ar', (tester) async {
      await capture(tester, const HotelBookingsScreen(),
          'hotel-staff/arabic/DOC05-REQ-082-hotel-bookings-ar.png');
    });

    testWidgets('DOC05-REQ-083-hotel-prices-ar', (tester) async {
      await capture(tester, const HotelPricesScreen(),
          'hotel-staff/arabic/DOC05-REQ-083-hotel-prices-ar.png');
    });

    testWidgets('DOC06-REQ-013-015-unit-pricing-ar', (tester) async {
      await capture(tester, const HotelUnitPricingScreen(),
          'hotel-staff/arabic/DOC06-REQ-013-015-unit-pricing-ar.png',
          height: 1000);
    });

    testWidgets('DOC06-REQ-013-015-unit-pricing-en', (tester) async {
      setSession(role: 'hotel_manager', name: 'Hotel Manager', locale: 'en');
      await capture(tester, const HotelUnitPricingScreen(),
          'hotel-staff/english/DOC06-REQ-013-015-unit-pricing-en.png',
          isArabic: false, height: 1000);
    });

    testWidgets('DOC06-REQ-016-meal-pricing-ar', (tester) async {
      await capture(tester, const HotelMealPricingScreen(),
          'hotel-staff/arabic/DOC06-REQ-016-meal-pricing-ar.png',
          height: 1000);
    });

    testWidgets('DOC06-REQ-010-012-requests-cleaning-ar', (tester) async {
      await capture(
        tester,
        const HotelRequestsScreen(),
        'hotel-staff/arabic/DOC06-REQ-010-requests-cleaning-ar.png',
        height: 1200,
      );
    });

    testWidgets('DOC06-REQ-010-housekeeping-payment-options-ar',
        (tester) async {
      await capture(
        tester,
        const HotelRequestsScreen(),
        'hotel-staff/arabic/DOC06-REQ-010-housekeeping-payment-options-ar.png',
        height: 1200,
        interact: (t) async {
          final confirm = find.text('تأكيد الطلب');
          expect(confirm, findsWidgets,
              reason: 'زر تأكيد طلب التنظيف يجب أن يكون ظاهرًا');
          await t.tap(confirm.first);
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets('DOC06-REQ-010-housekeeping-payment-options-en',
        (tester) async {
      setSession(role: 'hotel_manager', name: 'Hotel Manager', locale: 'en');
      await capture(
        tester,
        const HotelRequestsScreen(),
        'hotel-staff/english/DOC06-REQ-010-housekeeping-payment-options-en.png',
        isArabic: false,
        height: 1200,
        interact: (t) async {
          final confirm = find.text('Confirm Request');
          expect(confirm, findsWidgets,
              reason: 'زر تأكيد طلب التنظيف بالإنجليزية يجب أن يكون ظاهرًا');
          await t.tap(confirm.first);
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets('DOC06-REQ-011-requests-meal-ar', (tester) async {
      await capture(
        tester,
        const HotelRequestsScreen(),
        'hotel-staff/arabic/DOC06-REQ-011-requests-meal-ar.png',
        height: 1200,
        interact: (t) async {
          final tab = find.textContaining('وجب');
          if (tab.evaluate().isNotEmpty) {
            await t.tap(tab.first);
            await t.pumpAndSettle();
          }
        },
      );
    });
  });

  group('المالك (المتطلبات 60–76، 118–143)', () {
    setUp(() => setSession(role: 'owner', name: 'مالك الوحدة'));

    testWidgets('DOC05-REQ-060-owner-home-ar', (tester) async {
      await capture(tester, const OwnerHomeScreen(),
          'owner/arabic/DOC05-REQ-060-owner-home-ar.png',
          height: 1200);
    });

    testWidgets('DOC05-REQ-060-owner-navigation-ar', (tester) async {
      await capture(tester, const OwnerNavigationScreen(),
          'owner/arabic/DOC05-REQ-060-owner-navigation-ar.png');
    });

    testWidgets('DOC05-REQ-036-040-owner-bookings-ar', (tester) async {
      await capture(tester, const OwnerBookingsScreen(),
          'owner/arabic/DOC05-REQ-036-040-owner-bookings-ar.png',
          height: 1000);
    });

    testWidgets('DOC05-REQ-068-owner-service-prices-ar', (tester) async {
      await capture(tester, const OwnerServicePricesScreen(),
          'owner/arabic/DOC05-REQ-068-owner-service-prices-ar.png',
          height: 1000);
    });

    testWidgets('DOC05-REQ-060-owner-cleaning-ar', (tester) async {
      await capture(tester, const OwnerCleaningScreen(),
          'owner/arabic/DOC05-REQ-060-owner-cleaning-ar.png');
    });

    testWidgets('DOC05-REQ-069-owner-meal-requests-ar', (tester) async {
      await capture(tester, const OwnerMealRequestsScreen(),
          'owner/arabic/DOC05-REQ-069-owner-meal-requests-ar.png');
    });

    testWidgets('DOC05-REQ-070-owner-extra-bed-ar', (tester) async {
      await capture(tester, const OwnerExtraBedScreen(),
          'owner/arabic/DOC05-REQ-070-owner-extra-bed-ar.png');
    });

    testWidgets('DOC05-REQ-072-owner-maintenance-ar', (tester) async {
      await capture(tester, const OwnerMaintenanceScreen(),
          'owner/arabic/DOC05-REQ-072-owner-maintenance-ar.png');
    });

    testWidgets('DOC05-REQ-133-owner-wallet-ar', (tester) async {
      await capture(tester, const OwnerWalletScreen(),
          'owner/arabic/DOC05-REQ-133-owner-wallet-ar.png',
          height: 1200);
    });

    testWidgets('DOC05-REQ-126-129-owner-revenue-ar', (tester) async {
      await capture(tester, const OwnerRevenueScreen(),
          'owner/arabic/DOC05-REQ-126-129-owner-revenue-ar.png',
          height: 1200);
    });

    testWidgets('DOC05-REQ-074-owner-staff-ar', (tester) async {
      await capture(tester, const OwnerStaffScreen(),
          'owner/arabic/DOC05-REQ-074-owner-staff-ar.png');
    });

    testWidgets('DOC05-REQ-134-owner-notifications-ar', (tester) async {
      await capture(tester, const OwnerNotificationsScreen(),
          'owner/arabic/DOC05-REQ-134-owner-notifications-ar.png');
    });

    testWidgets('DOC05-REQ-061-owner-units-ar', (tester) async {
      await capture(tester, const OwnerUnitsScreen(),
          'owner/arabic/DOC05-REQ-061-owner-units-ar.png');
    });

    testWidgets('DOC05-REQ-121-owner-subscription-ar', (tester) async {
      await capture(tester, const OwnerSubscriptionScreen(),
          'owner/arabic/DOC05-REQ-121-owner-subscription-ar.png');
    });

    testWidgets('DOC05-REQ-109-owner-bank-ar', (tester) async {
      await capture(tester, const OwnerBankScreen(),
          'owner/arabic/DOC05-REQ-109-owner-bank-ar.png');
    });
  });

  group('وكيل الحجوزات (المتطلبات 93–109)', () {
    setUp(() => setSession(role: 'booking_agent', name: 'وكيل الحجوزات'));

    testWidgets('DOC05-REQ-097-agent-clients-ar', (tester) async {
      await capture(tester, const OwnerClientsScreen(),
          'booking-agent/arabic/DOC05-REQ-097-agent-clients-ar.png');
    });

    testWidgets('DOC05-REQ-100-agent-commission-ar', (tester) async {
      await capture(tester, const OwnerCommissionScreen(),
          'booking-agent/arabic/DOC05-REQ-100-agent-commission-ar.png',
          height: 1200);
    });

    testWidgets('DOC05-REQ-093-agent-home-ar', (tester) async {
      await capture(tester, const OwnerHomeScreen(),
          'booking-agent/arabic/DOC05-REQ-093-agent-home-ar.png',
          height: 1200);
    });
  });

  group('موظف المالك (المتطلب 75)', () {
    setUp(() => setSession(role: 'unit_manager', name: 'مدير الوحدات'));

    testWidgets('DOC05-REQ-075-employee-staff-navigation-ar', (tester) async {
      await capture(tester, const HotelStaffNavigationScreen(),
          'owner-employee/arabic/DOC05-REQ-075-employee-staff-navigation-ar.png');
    });
    testWidgets('DOC06-REQ-011-requests-meal-en', (tester) async {
      setSession(role: 'hotel_manager', name: 'Hotel Manager', locale: 'en');
      await capture(
        tester,
        const HotelRequestsScreen(),
        'hotel-staff/english/DOC06-REQ-011-requests-meal-en.png',
        isArabic: false,
        height: 1200,
        interact: (t) async {
          final tab = find.textContaining('Meal');
          if (tab.evaluate().isNotEmpty) {
            await t.tap(tab.first);
            await t.pumpAndSettle();
          }
        },
      );
    });

    testWidgets('DOC06-REQ-016-meal-pricing-en', (tester) async {
      setSession(role: 'hotel_manager', name: 'Hotel Manager', locale: 'en');
      await capture(tester, const HotelMealPricingScreen(),
          'hotel-staff/english/DOC06-REQ-016-meal-pricing-en.png',
          isArabic: false, height: 1000);
    });

    testWidgets('DOC06-REQ-F-002-arrivals-search-en', (tester) async {
      setSession(role: 'hotel_manager', name: 'Hotel Manager', locale: 'en');
      await capture(
        tester,
        const HotelArrivalsScreen(),
        'hotel-staff/english/DOC06-REQ-F-002-arrivals-search-en.png',
        isArabic: false,
        interact: (t) async {
          await t.enterText(find.byType(TextField).first, '402');
          await t.pumpAndSettle();
        },
      );
    });
  });
}
