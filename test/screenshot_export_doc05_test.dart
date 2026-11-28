import 'package:allowners/models/hotel_model.dart';
import 'package:allowners/models/unit_model.dart';
import 'package:allowners/screens/auth/reset_password_screen.dart';
import 'package:allowners/screens/booking/booking_screen.dart';
import 'package:allowners/screens/booking/booking_success_screen.dart';
import 'package:allowners/screens/bookings/my_bookings_screen.dart';
import 'package:allowners/screens/home/home_screen.dart';
import 'package:allowners/screens/home/main_navigation_screen.dart';
import 'package:allowners/screens/hotel_staff/hotel_bookings_screen.dart';
import 'package:allowners/screens/hotel_staff/hotel_prices_screen.dart';
import 'package:allowners/screens/hotel_staff/hotel_requests_screen.dart';
import 'package:allowners/screens/owner/owner_bank_screen.dart';
import 'package:allowners/screens/owner/owner_bookings_screen.dart';
import 'package:allowners/screens/owner/owner_cleaning_screen.dart';
import 'package:allowners/screens/owner/owner_extra_bed_screen.dart';
import 'package:allowners/screens/owner/owner_home_screen.dart';
import 'package:allowners/screens/owner/owner_meal_requests_screen.dart';
import 'package:allowners/screens/owner/owner_notifications_screen.dart';
import 'package:allowners/screens/owner/owner_subscription_screen.dart';
import 'package:allowners/screens/owner/owner_wallet_screen.dart';
import 'package:allowners/screens/profile/profile_screen.dart';
import 'package:allowners/screens/search/search_screen.dart';
import 'package:allowners/screens/services/meal_request_screen.dart';
import 'package:allowners/screens/services/service_request_screen.dart';
import 'package:allowners/screens/unit/unit_details_screen.dart';
import 'package:allowners/services/api_client.dart';
import 'package:allowners/utils/app_strings.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'screenshot_support.dart';

/// المتطلبات الـ95 من المستند 05 التي كانت بلا لقطة مباشرة.
///
/// كل لقطة تُسمّى بنطاق المتطلبات التي تُثبتها فعليًا. المتطلبات غير المرئية
/// (دوال نقية، عقود API، منع من الخادم) لا تُصوَّر — دليلها اختبارات
/// `test/document05_*.dart`، و`docs/DOCUMENT_05_VISUAL_EVIDENCE.md` يسجّل ذلك.
///
/// كل لقطة في اختبار مستقل: جلستان في اختبار واحد تُبقي `localeProvider`
/// على العربية فتُنتج «لقطة إنجليزية» بنص عربي.
///
/// التشغيل: `flutter test test/screenshot_export_doc05_test.dart --update-goldens`
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
  final unit = UnitModel.fromJson(
      Map<String, dynamic>.from(unitDetailJson['unit'] as Map));

  /// يسجّل لقطتين (عربي + إنجليزي) في اختبارين منفصلين.
  void shotPair({
    required String stem,
    required String folder,
    required Widget Function() build,
    Widget Function()? buildEn,
    String role = 'customer',
    String arabicName = 'محمد علي',
    String englishName = 'Mohammed Ali',
    double height = 844,
    double width = 390,
    Future<void> Function(WidgetTester tester)? interact,
    Future<void> Function(WidgetTester tester)? interactEn,
    void Function()? prepare,
    Duration? drainTimers,
  }) {
    testWidgets('$stem-ar', (tester) async {
      setSession(role: role, name: arabicName);
      prepare?.call();
      await capture(tester, build(), '$folder/arabic/$stem-ar.png',
          height: height,
          width: width,
          interact: interact,
          drainTimers: drainTimers);
    });

    testWidgets('$stem-en', (tester) async {
      setSession(role: role, name: englishName, locale: 'en');
      prepare?.call();
      await capture(
          tester, (buildEn ?? build)(), '$folder/english/$stem-en.png',
          isArabic: false,
          height: height,
          width: width,
          interact: interactEn ?? interact,
          drainTimers: drainTimers);
    });
  }

  group('الضيف — الهوية والأقسام (6، 7، 9، 20، 21، 22، 23، 26، 27)', () {
    shotPair(
      stem: 'DOC05-REQ-006-007-home-logo',
      folder: 'customer',
      build: () => const HomeScreen(),
    );

    shotPair(
      stem: 'DOC05-REQ-009-avatar-options',
      folder: 'customer',
      build: () => const ProfileScreen(),
      height: 1000,
      // الضغط على الصورة يفتح خيارات (معرض/كاميرا/إزالة) — المتطلب 9.
      interact: (t) async {
        await t.tap(find.byIcon(Icons.edit).first);
      },
    );

    shotPair(
      stem: 'DOC05-REQ-020-023-home-sections',
      folder: 'customer',
      build: () => const HomeScreen(),
      height: 1400,
      interact: (t) async {
        await t.drag(find.byType(Scrollable).first, const Offset(0, -420));
      },
    );

    shotPair(
      stem: 'DOC05-REQ-026-search-city',
      folder: 'customer',
      build: () => const SearchScreen(initialCity: 'مكة المكرمة'),
      height: 1000,
      interact: (t) async {
        await t.drag(find.byType(Scrollable).first, const Offset(0, -200));
      },
    );

    shotPair(
      stem: 'DOC05-REQ-027-main-navigation',
      folder: 'customer',
      build: () => const MainNavigationScreen(),
      drainTimers: const Duration(seconds: 11),
    );
  });

  group('الضيف — الحجز والخدمات (41–58، 76، 95، 96)', () {
    shotPair(
      stem: 'DOC05-REQ-041-043-my-bookings-actions',
      folder: 'customer',
      build: () => const MyBookingsScreen(),
      height: 1200,
      interact: (t) async {
        await t.drag(find.byType(Scrollable).first, const Offset(0, -260));
      },
    );

    shotPair(
      stem: 'DOC05-REQ-042-edit-booking-sheet',
      folder: 'customer',
      build: () => const MyBookingsScreen(),
      height: 1200,
      interact: (t) async {
        final edit = find.text(AppStrings.t(true, 'edit_booking'));
        expect(edit, findsWidgets, reason: 'زر تعديل الحجز يجب أن يُبنى');
        await t.tap(edit.first);
      },
      interactEn: (t) async {
        final edit = find.text(AppStrings.t(false, 'edit_booking'));
        expect(edit, findsWidgets, reason: 'زر تعديل الحجز يجب أن يُبنى');
        await t.tap(edit.first);
      },
    );

    shotPair(
      stem: 'DOC05-REQ-045-availability-warning',
      folder: 'customer',
      build: () => BookingScreen(
        hotel: hotel,
        unitId: unit.id,
        unitName: unit.nameAr,
        unitNumber: unit.unitNumber,
        unitPricePerNight: unit.pricePerNight,
        // فترة إتاحة في الماضي: التواريخ الافتراضية للحجز تقع خارجها،
        // فيظهر تحذير المتطلب 45 قبل الدفع.
        unitAvailability: [
          UnitAvailabilityModel(
            from: DateTime(2020, 1, 1),
            to: DateTime(2020, 12, 31),
          ),
        ],
      ),
      height: 1400,
      interact: (t) async {
        await t.drag(find.byType(Scrollable).first, const Offset(0, -700));
      },
    );

    shotPair(
      stem: 'DOC05-REQ-046-booking-success-access',
      folder: 'customer',
      build: () => BookingSuccessScreen(
        hotel: hotel,
        bookingRef: 'BK-1001',
        unitNumber: '402',
        unitName: 'جناح عائلي',
        total: 1500,
        checkIn: DateTime(2026, 12, 1),
        checkOut: DateTime(2026, 12, 3),
        nights: 2,
        guests: 2,
        guestName: 'محمد علي',
        guestPhone: '0500000000',
        status: 'confirmed',
      ),
      height: 1200,
    );

    shotPair(
      stem: 'DOC05-REQ-048-051-booking-meal-addons',
      folder: 'customer',
      build: () => BookingScreen(
        hotel: hotel,
        unitId: unit.id,
        unitName: unit.nameAr,
        unitNumber: unit.unitNumber,
        unitPricePerNight: unit.pricePerNight,
      ),
      height: 1600,
      interact: (t) async {
        await t.drag(find.byType(Scrollable).first, const Offset(0, -520));
      },
    );

    shotPair(
      stem: 'DOC05-REQ-049-053-meal-request',
      folder: 'customer',
      build: () => const MealRequestScreen(),
      height: 1100,
    );

    shotPair(
      stem: 'DOC05-REQ-054-056-extra-bed',
      folder: 'customer',
      build: () => BookingScreen(
        hotel: hotel,
        unitId: unit.id,
        unitName: unit.nameAr,
        unitNumber: unit.unitNumber,
        unitPricePerNight: unit.pricePerNight,
      ),
      height: 1600,
      interact: (t) async {
        await t.drag(find.byType(Scrollable).first, const Offset(0, -700));
      },
    );

    shotPair(
      stem: 'DOC05-REQ-057-058-service-request',
      folder: 'customer',
      build: () => ServiceRequestScreen(
        icon: Icons.build_outlined,
        title: AppStrings.t(true, 'maintenance'),
        description: AppStrings.t(true, 'maintenance_desc'),
        serviceType: 'maintenance',
      ),
      buildEn: () => ServiceRequestScreen(
        icon: Icons.build_outlined,
        title: AppStrings.t(false, 'maintenance'),
        description: AppStrings.t(false, 'maintenance_desc'),
        serviceType: 'maintenance',
      ),
      height: 900,
    );

    shotPair(
      stem: 'DOC05-REQ-076-unit-service-categories',
      folder: 'customer',
      build: () => UnitDetailsScreen(unitId: unit.id),
      height: 1600,
      interact: (t) async {
        await t.drag(find.byType(Scrollable).first, const Offset(0, -900));
      },
    );

    shotPair(
      stem: 'DOC05-REQ-095-096-booking-hotel-units',
      folder: 'customer',
      build: () => BookingScreen(
        hotel: hotel,
        unitId: unit.id,
        unitName: unit.nameAr,
        unitNumber: unit.unitNumber,
        unitPricePerNight: unit.pricePerNight,
      ),
      height: 1200,
    );
  });

  group(
      'المالك — الحجوزات والطلبات (35، 62، 65–67، 71، 98، 99، 118–125، 135–142)',
      () {
    shotPair(
      stem: 'DOC05-REQ-035-owner-booking-details',
      folder: 'owner',
      role: 'owner',
      // بطاقة حجز المالك تعرض التفاصيل كاملة (الضيف، الوحدة، الوجبات،
      // الإضافات، الإجمالي، التواريخ) فلا حاجة لفتح نافذة إضافية.
      build: () => const OwnerBookingsScreen(),
      height: 1200,
    );

    shotPair(
      stem: 'DOC05-REQ-062-owner-cleaning-new',
      folder: 'owner',
      role: 'owner',
      build: () => const OwnerCleaningScreen(),
      height: 1100,
      interact: (t) async {
        final fab = find.byType(FloatingActionButton);
        if (fab.evaluate().isNotEmpty) {
          await t.tap(fab.first);
        }
      },
    );

    shotPair(
      stem: 'DOC05-REQ-065-066-owner-meal-new',
      folder: 'owner',
      role: 'owner',
      build: () => const OwnerMealRequestsScreen(),
      height: 1100,
      interact: (t) async {
        final fab = find.byType(FloatingActionButton);
        if (fab.evaluate().isNotEmpty) {
          await t.tap(fab.first);
        }
      },
    );

    shotPair(
      stem: 'DOC05-REQ-067-owner-extra-bed-request',
      folder: 'owner',
      role: 'owner',
      build: () => const OwnerExtraBedScreen(),
      height: 1100,
      interact: (t) async {
        final fab = find.byType(FloatingActionButton);
        if (fab.evaluate().isNotEmpty) {
          await t.tap(fab.first);
        }
      },
    );

    shotPair(
      stem: 'DOC05-REQ-071-owner-notification-body',
      folder: 'owner',
      role: 'owner',
      build: () => const OwnerNotificationsScreen(),
      height: 900,
    );

    shotPair(
      stem: 'DOC05-REQ-098-099-owner-nav',
      folder: 'owner',
      role: 'owner',
      build: () => const OwnerHomeScreen(),
      height: 1600,
    );

    shotPair(
      stem: 'DOC05-REQ-118-owner-bank',
      folder: 'owner',
      role: 'owner',
      build: () => const OwnerBankScreen(),
      height: 1000,
    );

    shotPair(
      stem: 'DOC05-REQ-119-120-owner-transfer',
      folder: 'owner',
      role: 'owner',
      build: () => BookingScreen(
        hotel: hotel,
        unitId: unit.id,
        unitName: unit.nameAr,
        unitNumber: unit.unitNumber,
        unitPricePerNight: unit.pricePerNight,
        ownerBank: Map<String, dynamic>.from(ownerBankJson['bank'] as Map),
      ),
      height: 1600,
      // «التحويل المباشر للمالك» معطّل افتراضيًا (المتطلب 7 من المستند 06)؛
      // نُعلنه مُفعَّلًا هنا من السيرفر حتى تظهر بيانات حساب المالك (المتطلب 120)
      // بعد اختيار التحويل.
      prepare: () => installShotAdapter(ownerTransferEnabled: true),
      interact: (t) async {
        await t.drag(find.byType(Scrollable).first, const Offset(0, -760));
        final radio = find.text(AppStrings.t(true, 'pay_owner_transfer'));
        expect(radio, findsWidgets, reason: 'خيار التحويل يجب أن يُعرض');
        await t.tap(radio.first);
      },
      interactEn: (t) async {
        await t.drag(find.byType(Scrollable).first, const Offset(0, -760));
        final radio = find.text(AppStrings.t(false, 'pay_owner_transfer'));
        expect(radio, findsWidgets, reason: 'خيار التحويل يجب أن يُعرض');
        await t.tap(radio.first);
      },
    );

    shotPair(
      stem: 'DOC05-REQ-122-125-subscription',
      folder: 'owner',
      role: 'owner',
      build: () => const OwnerSubscriptionScreen(),
      height: 1200,
      prepare: () => installShotAdapter(richSettings: true),
    );

    shotPair(
      stem: 'DOC05-REQ-135-136-wallet-balance',
      folder: 'owner',
      role: 'owner',
      build: () => const OwnerWalletScreen(),
      height: 1300,
    );

    shotPair(
      stem: 'DOC05-REQ-142-payouts',
      folder: 'owner',
      role: 'owner',
      build: () => const OwnerWalletScreen(),
      height: 1600,
      interact: (t) async {
        await t.drag(find.byType(Scrollable).first, const Offset(0, -420));
      },
    );
  });

  group('فندق — الإدارة (78، 79، 84–92، 130، 131)', () {
    shotPair(
      stem: 'DOC05-REQ-078-079-hotel-checkin-out',
      folder: 'hotel-staff',
      role: 'hotel_manager',
      build: () => const HotelBookingsScreen(),
      height: 1200,
    );

    shotPair(
      stem: 'DOC05-REQ-084-089-hotel-service-prices',
      folder: 'hotel-staff',
      role: 'hotel_manager',
      build: () => const HotelPricesScreen(),
      height: 1300,
    );

    shotPair(
      stem: 'DOC05-REQ-085-092-hotel-request-actions',
      folder: 'hotel-staff',
      role: 'hotel_manager',
      build: () => const HotelRequestsScreen(),
      height: 1200,
    );

    shotPair(
      stem: 'DOC05-REQ-130-131-maintenance-settlement',
      folder: 'hotel-staff',
      role: 'hotel_manager',
      build: () => const HotelRequestsScreen(),
      height: 1100,
      interact: (t) async {
        final confirm = find.text(AppStrings.t(true, 'confirm_request'));
        if (confirm.evaluate().isNotEmpty) {
          await t.tap(confirm.first);
        }
      },
      interactEn: (t) async {
        final confirm = find.text('Confirm Request');
        if (confirm.evaluate().isNotEmpty) {
          await t.tap(confirm.first);
        }
      },
    );
  });

  group('الحساب والوصول (101–107، 110)', () {
    shotPair(
      stem: 'DOC05-REQ-110-reset-password',
      folder: 'customer',
      build: () => const ResetPasswordScreen(),
      height: 900,
    );

    shotPair(
      stem: 'DOC05-REQ-101-107-agent-menu',
      folder: 'booking-agent',
      role: 'booking_agent',
      arabicName: 'وكيل الحجوزات',
      englishName: 'Booking Agent',
      build: () => const OwnerHomeScreen(),
      height: 1600,
    );
  });
}
