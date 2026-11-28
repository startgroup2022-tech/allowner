import 'package:allowners/models/hotel_model.dart';
import 'package:allowners/models/unit_model.dart';
import 'package:allowners/screens/booking/booking_screen.dart';
import 'package:allowners/screens/owner/owner_bookings_screen.dart';
import 'package:allowners/screens/owner/owner_cleaning_screen.dart';
import 'package:allowners/screens/owner/owner_revenue_screen.dart';
import 'package:allowners/screens/services/hotel_services_screen.dart';
import 'package:allowners/services/api_client.dart';
import 'package:allowners/utils/service_request_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'screenshot_support.dart';

/// لقطات المتطلبات الـ28 التي كانت بلا صورة في مصفوفة المستند 05.
///
/// لا تُصوَّر إلا المتطلبات التي لها سطح مرئي حقيقي في التطبيق. المتطلبات
/// الخلفية (بريد، لوحة أدمن، مزوّد دفع) لا تُصوَّر ولها في التقرير سند اختباري
/// أو تصريح حجب صريح.
///
/// التشغيل: `flutter test test/screenshot_export_gaps_test.dart --update-goldens`
void main() {
  late HttpClientAdapter original;

  setUpAll(() async {
    await loadBrandFonts();
  });

  setUp(() {
    original = ApiClient.instance.dio.httpClientAdapter;
  });

  tearDown(() => restoreShotAdapter(original));

  final hotel = HotelModel.fromJson(
      Map<String, dynamic>.from(hotelDetailJson['hotel'] as Map));
  final unit = UnitModel.fromJson(
      Map<String, dynamic>.from(unitDetailJson['unit'] as Map));

  Widget bookingScreen() => BookingScreen(
        hotel: hotel,
        unitId: unit.id,
        unitName: unit.nameAr,
        unitNumber: unit.unitNumber,
        unitPricePerNight: unit.pricePerNight,
      );

  /// يسجّل عربيًا وإنجليزيًا، مع تهيئة تُنفَّذ داخل كل اختبار (بيانات/فشل).
  void pair(
    String stem,
    String folder, {
    required Widget Function() build,
    Widget Function()? buildEn,
    String role = 'customer',
    double height = 844,
    Future<void> Function(WidgetTester tester)? interact,
    Future<void> Function()? prepare,
  }) {
    testWidgets('$stem-ar', (tester) async {
      setSession(role: role);
      installShotAdapter();
      if (prepare != null) await prepare();
      await capture(tester, build(), '$folder/arabic/$stem-ar.png',
          height: height, interact: interact);
    });

    testWidgets('$stem-en', (tester) async {
      setSession(role: role, name: 'Mohammed Ali', locale: 'en');
      installShotAdapter();
      if (prepare != null) await prepare();
      await capture(
          tester, (buildEn ?? build)(), '$folder/english/$stem-en.png',
          isArabic: false, height: height, interact: interact);
    });
  }

  /// طلبان محفوظان من استجابات سيرفر حقيقية: أحدهما أعلن السيرفر حالته،
  /// والآخر لم يُعلنها بعد (فتُعرض «—» ولا تُختلق حالة).
  Future<void> seedRequests() async {
    await const ServiceRequestStore().saveAll([
      ServiceRequestRecord(
        type: 'cleaning',
        id: 41,
        status: 'done',
        roomNumber: '402',
        description: 'تنظيف بعد المغادرة',
        createdAt: DateTime(2026, 11, 26, 9),
      ),
      ServiceRequestRecord(
        type: 'maintenance',
        id: 42,
        status: null,
        roomNumber: '402',
        description: 'مكيف الغرفة لا يبرد',
        createdAt: DateTime(2026, 11, 27, 8),
      ),
    ]);
  }

  group('الضيف — طلبات الخدمات (59)', () {
    pair(
      'DOC05-REQ-059-my-requests',
      'customer',
      build: () => const HotelServicesScreen(),
      height: 1100,
      prepare: () async {
        // نقطة القراءة الحيّة غير موجودة على السيرفر بعد: تُعلن الشاشة ذلك
        // وتُظهر ما حُفظ من استجابات فعلية بدل اختلاق قائمة.
        installShotAdapter(failPath: 'my-requests');
        await seedRequests();
      },
      interact: (t) async {
        await t.drag(find.byType(Scrollable).first, const Offset(0, -520));
      },
    );
  });

  group('المالك — الطلبات والإيرادات (63، 64، 73، 143)', () {
    pair(
      'DOC05-REQ-063-064-owner-request-to-hotel',
      'owner',
      role: 'owner',
      build: () => const OwnerCleaningScreen(),
      height: 1100,
      interact: (t) async {
        final fab = find.byType(FloatingActionButton);
        if (fab.evaluate().isNotEmpty) await t.tap(fab.first);
        await t.pumpAndSettle();
        await t.drag(find.byType(Scrollable).last, const Offset(0, -180));
      },
    );

    pair(
      'DOC05-REQ-073-owner-booking-addons',
      'owner',
      role: 'owner',
      build: () => const OwnerBookingsScreen(),
      height: 1200,
      interact: (t) async {
        await t.drag(find.byType(Scrollable).first, const Offset(0, -260));
      },
    );

    pair(
      'DOC05-REQ-143-owner-unit-revenue',
      'owner',
      role: 'owner',
      build: () => const OwnerRevenueScreen(),
      height: 1300,
      interact: (t) async {
        await t.drag(find.byType(Scrollable).first, const Offset(0, -420));
      },
    );
  });

  group('الضيف — بيانات الحجز والسعر النهائي (94، 140، 145–148)', () {
    pair(
      'DOC05-REQ-094-booking-guest-fields',
      'booking-agent',
      role: 'booking_agent',
      build: bookingScreen,
      height: 1500,
      interact: (t) async {
        await t.drag(find.byType(Scrollable).first, const Offset(0, -820));
      },
    );

    pair(
      'DOC05-REQ-140-booking-final-price',
      'customer',
      build: bookingScreen,
      height: 1500,
      interact: (t) async {
        await t.drag(find.byType(Scrollable).first, const Offset(0, -1180));
      },
    );
  });
}
