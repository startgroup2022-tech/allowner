import 'package:allowners/screens/onboarding/onboarding_screen.dart';
import 'package:allowners/screens/owner/owner_bank_screen.dart';
import 'package:allowners/screens/owner/owner_clients_screen.dart';
import 'package:allowners/screens/owner/owner_commission_screen.dart';
import 'package:allowners/screens/owner/owner_home_screen.dart';
import 'package:allowners/screens/owner/owner_maintenance_screen.dart';
import 'package:allowners/screens/owner/owner_meal_requests_screen.dart';
import 'package:allowners/screens/owner/owner_navigation_screen.dart';
import 'package:allowners/screens/owner/owner_notifications_screen.dart';
import 'package:allowners/screens/owner/owner_revenue_screen.dart';
import 'package:allowners/screens/owner/owner_staff_screen.dart';
import 'package:allowners/screens/owner/owner_subscription_screen.dart';
import 'package:allowners/screens/owner/owner_units_screen.dart';
import 'package:allowners/screens/owner/owner_wallet_screen.dart';
import 'package:allowners/screens/shared/app_about_screen.dart';
import 'package:allowners/screens/shared/help_support_screen.dart';
import 'package:allowners/services/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'screenshot_support.dart';

/// لقطات إضافية لإكمال تغطية المتطلبات (المستندان 05 و06).
///
/// التشغيل: `flutter test test/screenshot_export_matrix_test.dart --update-goldens`
///
/// كل لقطة مرسومة من الودجات الإنتاجية عبر المحوّل الوهمي نفسه المستخدم في
/// بقية ملفات اللقطات؛ لا صور مُعاد رسمها ولا موك‑أب.
void main() {
  late HttpClientAdapter original;

  setUpAll(loadBrandFonts);

  setUp(() {
    original = ApiClient.instance.dio.httpClientAdapter;
    installShotAdapter();
    setSession();
  });

  tearDown(() => restoreShotAdapter(original));

  group('الهوية والترحيب والدعم (المتطلبات 1–8)', () {
    testWidgets('DOC05-REQ-001-002-onboarding-ar', (tester) async {
      await capture(tester, const OnboardingScreen(),
          'customer/arabic/DOC05-REQ-001-002-onboarding-ar.png');
    });

    testWidgets('DOC05-REQ-001-002-onboarding-en', (tester) async {
      setSession(locale: 'en');
      await capture(tester, const OnboardingScreen(),
          'customer/english/DOC05-REQ-001-002-onboarding-en.png',
          isArabic: false);
    });

    testWidgets('DOC05-REQ-003-005-about-app-ar', (tester) async {
      await capture(tester, const AppAboutScreen(),
          'customer/arabic/DOC05-REQ-003-005-about-app-ar.png',
          height: 1400);
    });

    testWidgets('DOC05-REQ-003-005-about-app-en', (tester) async {
      setSession(locale: 'en');
      await capture(tester, const AppAboutScreen(),
          'customer/english/DOC05-REQ-003-005-about-app-en.png',
          isArabic: false, height: 1400);
    });

    testWidgets('DOC05-REQ-008-help-support-ar', (tester) async {
      await capture(tester, const HelpSupportScreen(),
          'customer/arabic/DOC05-REQ-008-help-support-ar.png');
    });

    testWidgets('DOC05-REQ-008-help-support-en', (tester) async {
      setSession(locale: 'en');
      await capture(tester, const HelpSupportScreen(),
          'customer/english/DOC05-REQ-008-help-support-en.png',
          isArabic: false);
    });
  });

  group('شاشات المالك بالعربية والإنجليزية (المتطلبات 60–143)', () {
    testWidgets('DOC05-REQ-060-owner-home-en', (tester) async {
      setSession(role: 'owner', name: 'Owner', locale: 'en');
      await capture(tester, const OwnerHomeScreen(),
          'owner/english/DOC05-REQ-060-owner-home-en.png',
          isArabic: false, height: 1400);
    });

    testWidgets('DOC05-REQ-060-owner-navigation-en', (tester) async {
      setSession(role: 'owner', name: 'Owner', locale: 'en');
      await capture(tester, const OwnerNavigationScreen(),
          'owner/english/DOC05-REQ-060-owner-navigation-en.png',
          isArabic: false);
    });

    testWidgets('DOC05-REQ-061-owner-units-en', (tester) async {
      setSession(role: 'owner', name: 'Owner', locale: 'en');
      await capture(tester, const OwnerUnitsScreen(),
          'owner/english/DOC05-REQ-061-owner-units-en.png',
          isArabic: false);
    });

    testWidgets('DOC05-REQ-074-owner-staff-en', (tester) async {
      setSession(role: 'owner', name: 'Owner', locale: 'en');
      await capture(tester, const OwnerStaffScreen(),
          'owner/english/DOC05-REQ-074-owner-staff-en.png',
          isArabic: false, height: 1000);
    });

    testWidgets('DOC05-REQ-074-owner-staff-permissions-ar', (tester) async {
      setSession(role: 'owner', name: 'المالك');
      await capture(
        tester,
        const OwnerStaffScreen(),
        'owner/arabic/DOC05-REQ-074-staff-permissions-sheet-ar.png',
        height: 1000,
        interact: (t) async {
          await t.tap(find.text('الصلاحيات'));
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets('DOC05-REQ-074-owner-staff-permissions-en', (tester) async {
      setSession(role: 'owner', name: 'Owner', locale: 'en');
      await capture(
        tester,
        const OwnerStaffScreen(),
        'owner/english/DOC05-REQ-074-staff-permissions-sheet-en.png',
        isArabic: false,
        height: 1000,
        interact: (t) async {
          await t.tap(find.text('Permissions'));
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets('DOC05-REQ-072-owner-maintenance-en', (tester) async {
      setSession(role: 'owner', name: 'Owner', locale: 'en');
      await capture(tester, const OwnerMaintenanceScreen(),
          'owner/english/DOC05-REQ-072-owner-maintenance-en.png',
          isArabic: false);
    });

    testWidgets('DOC05-REQ-069-owner-meal-requests-en', (tester) async {
      setSession(role: 'owner', name: 'Owner', locale: 'en');
      await capture(tester, const OwnerMealRequestsScreen(),
          'owner/english/DOC05-REQ-069-owner-meal-requests-en.png',
          isArabic: false);
    });

    testWidgets('DOC05-REQ-108-owner-commission-transfer-ar', (tester) async {
      setSession(role: 'owner', name: 'المالك');
      await capture(
        tester,
        const OwnerCommissionScreen(),
        'owner/arabic/DOC05-REQ-108-commission-transfer-sheet-ar.png',
        height: 1000,
        interact: (t) async {
          await t.tap(find.text('طلب تحويل المستحقات'));
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets('DOC05-REQ-108-owner-commission-transfer-en', (tester) async {
      setSession(role: 'owner', name: 'Owner', locale: 'en');
      await capture(
        tester,
        const OwnerCommissionScreen(),
        'owner/english/DOC05-REQ-108-commission-transfer-sheet-en.png',
        isArabic: false,
        height: 1000,
        interact: (t) async {
          await t.tap(find.text('Request transfer'));
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets('DOC05-REQ-133-owner-wallet-en', (tester) async {
      setSession(role: 'owner', name: 'Owner', locale: 'en');
      await capture(tester, const OwnerWalletScreen(),
          'owner/english/DOC05-REQ-133-owner-wallet-en.png',
          isArabic: false, height: 1200);
    });

    testWidgets('DOC05-REQ-126-129-owner-revenue-en', (tester) async {
      setSession(role: 'owner', name: 'Owner', locale: 'en');
      await capture(tester, const OwnerRevenueScreen(),
          'owner/english/DOC05-REQ-126-129-owner-revenue-en.png',
          isArabic: false, height: 1200);
    });

    testWidgets('DOC05-REQ-121-owner-subscription-en', (tester) async {
      setSession(role: 'owner', name: 'Owner', locale: 'en');
      await capture(tester, const OwnerSubscriptionScreen(),
          'owner/english/DOC05-REQ-121-owner-subscription-en.png',
          isArabic: false, height: 1000);
    });

    testWidgets('DOC05-REQ-109-owner-bank-en', (tester) async {
      setSession(role: 'owner', name: 'Owner', locale: 'en');
      await capture(tester, const OwnerBankScreen(),
          'owner/english/DOC05-REQ-109-owner-bank-en.png',
          isArabic: false);
    });

    testWidgets('DOC05-REQ-134-owner-notifications-en', (tester) async {
      setSession(role: 'owner', name: 'Owner', locale: 'en');
      await capture(tester, const OwnerNotificationsScreen(),
          'owner/english/DOC05-REQ-134-owner-notifications-en.png',
          isArabic: false);
    });
  });

  group('وكيل الحجوزات وموظف المالك بالإنجليزية (المتطلبات 93–107، 75)', () {
    testWidgets('DOC05-REQ-093-agent-home-en', (tester) async {
      setSession(role: 'booking_agent', name: 'Agent', locale: 'en');
      await capture(tester, const OwnerHomeScreen(),
          'booking-agent/english/DOC05-REQ-093-agent-home-en.png',
          isArabic: false, height: 1400);
    });

    testWidgets('DOC05-REQ-097-agent-clients-en', (tester) async {
      setSession(role: 'booking_agent', name: 'Agent', locale: 'en');
      await capture(tester, const OwnerClientsScreen(),
          'booking-agent/english/DOC05-REQ-097-agent-clients-en.png',
          isArabic: false);
    });

    testWidgets('DOC05-REQ-100-agent-commission-en', (tester) async {
      setSession(role: 'booking_agent', name: 'Agent', locale: 'en');
      await capture(tester, const OwnerCommissionScreen(),
          'booking-agent/english/DOC05-REQ-100-agent-commission-en.png',
          isArabic: false, height: 1000);
    });

    testWidgets('DOC05-REQ-075-employee-navigation-en', (tester) async {
      setSession(role: 'owner_employee', name: 'Employee', locale: 'en');
      await capture(tester, const OwnerNavigationScreen(),
          'owner-employee/english/DOC05-REQ-075-employee-navigation-en.png',
          isArabic: false);
    });
  });
}
