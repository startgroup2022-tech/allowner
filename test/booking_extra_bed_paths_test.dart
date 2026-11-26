import 'package:allowners/models/hotel_model.dart';
import 'package:allowners/screens/booking/booking_screen.dart';
import 'package:allowners/services/api_client.dart';
import 'package:allowners/utils/booking_payload.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'screenshot_support.dart';

/// انحدار عيب «اختفاء السرير الإضافي» (المستند 06 §B).
///
/// العيب: بطاقة السرير الإضافي كانت مبنية داخل فرع «الحجز على مستوى الفندق»
/// فقط، فتختفي عند الحجز المباشر لوحدة (`unitId != null`) رغم أن السعر معرّف
/// على الفندق والإجمالي يُحسب في المسارين.
///
/// هذه الاختبارات تفشل على الشيفرة القديمة وتمر على الشيفرة المصحّحة.
void main() {
  late HttpClientAdapter original;

  setUpAll(loadBrandFonts);

  setUp(() {
    original = ApiClient.instance.dio.httpClientAdapter;
    installShotAdapter();
    setSession();
  });

  tearDown(() => restoreShotAdapter(original));

  final hotel = HotelModel.fromJson(
      Map<String, dynamic>.from(hotelDetailJson['hotel'] as Map));

  /// يبني شاشة الحجز بحجم نافذة طويل حتى تُبنى كل الأقسام بلا تمرير.
  Future<void> pumpBooking(WidgetTester tester, {int? unitId}) async {
    tester.view.physicalSize = const Size(390, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      wrapShot(BookingScreen(hotel: hotel, unitId: unitId), isArabic: true),
    );
    await tester.pumpAndSettle();
  }

  /// يفتح بطاقة السرير الإضافي: يضغط المفتاح داخل صفّ «إضافة سرير إضافي».
  Future<Finder> enableExtraBed(WidgetTester tester) async {
    final labels = find.text('إضافة سرير إضافي');
    expect(labels, findsWidgets, reason: 'بطاقة السرير الإضافي يجب أن تُبنى');
    Finder? toggle;
    for (var i = 0; i < labels.evaluate().length; i++) {
      final row =
          find.ancestor(of: labels.at(i), matching: find.byType(Row)).first;
      final sw = find.descendant(of: row, matching: find.byType(Switch));
      if (sw.evaluate().isNotEmpty) {
        toggle = sw;
        break;
      }
    }
    expect(toggle, isNotNull,
        reason: 'يجب أن يحتوي الصفّ على مفتاح تشغيل للسرير الإضافي');
    await tester.tap(toggle!);
    await tester.pumpAndSettle();
    return labels;
  }

  /// زر (+) الخاص بعدّاد السرير الإضافي — لا زر عدّاد الضيوف الذي يستخدم
  /// نفس الأيقونة ويأتي قبله في الشجرة.
  Future<Finder> extraBedPlus(WidgetTester tester) async {
    final row = find
        .ancestor(
            of: find.text('عدد الأسرّة الإضافية'), matching: find.byType(Row))
        .first;
    return find.descendant(
        of: row, matching: find.byIcon(Icons.add_circle_outline_rounded));
  }

  group('مسار الحجز المباشر لوحدة (unitId != null)', () {
    testWidgets('بطاقة السرير الإضافي والعدّاد وسطر الحساب تظهر',
        (tester) async {
      await pumpBooking(tester, unitId: 13);

      expect(find.text('إضافة سرير إضافي'), findsWidgets);
      expect(find.textContaining('لكل ليلة لكل سرير'), findsWidgets,
          reason: 'اللافتة تعرض سعر الليلة لكل سرير');

      await enableExtraBed(tester);

      expect(find.text('عدد الأسرّة الإضافية'), findsOneWidget,
          reason: 'عدّاد الكمية يجب أن يظهر بعد التفعيل');
      // العدد × سعر الليلة × الليالي = 1 × 150 × 2
      expect(find.textContaining('1 × 150 × 2 = 300'), findsOneWidget);
    });

    testWidgets('زيادة العدد تحدّث سطر الحساب', (tester) async {
      await pumpBooking(tester, unitId: 13);
      await enableExtraBed(tester);

      await tester.tap(await extraBedPlus(tester));
      await tester.pumpAndSettle();

      expect(find.textContaining('2 × 150 × 2 = 600'), findsOneWidget);
      expect(find.textContaining('1 × 150 × 2'), findsNothing);
    });

    testWidgets('العدّاد يتوقف عند الحد الأعلى', (tester) async {
      await pumpBooking(tester, unitId: 13);
      await enableExtraBed(tester);

      final plus = await extraBedPlus(tester);
      for (var i = 1; i < kMaxExtraBeds; i++) {
        await tester.tap(plus);
        await tester.pumpAndSettle();
      }
      expect(find.textContaining('$kMaxExtraBeds × 150 × 2'), findsOneWidget);

      final button = tester.widget<IconButton>(
        find.ancestor(of: plus, matching: find.byType(IconButton)).first,
      );
      expect(button.onPressed, isNull,
          reason: 'لا يمكن تجاوز الحد الأعلى للأسرّة الإضافية');
    });
  });

  group('مسار الحجز على مستوى الفندق (unitId == null)', () {
    testWidgets('بطاقة السرير الإضافي تظهر كما في السابق', (tester) async {
      await pumpBooking(tester);

      await enableExtraBed(tester);

      expect(find.text('عدد الأسرّة الإضافية'), findsOneWidget);
      expect(find.textContaining('1 × 150 × 2 = 300'), findsOneWidget);
    });

    testWidgets('وجبات الفندق التقليدية باقية بجانب البطاقة', (tester) async {
      await pumpBooking(tester);
      // شرائح الوجبات القديمة (فطور/غداء/عشاء) لم تُحذف في هذا المسار.
      expect(find.byType(FilterChip), findsNWidgets(3));
    });
  });

  group('لافتة السعر والاحتساب', () {
    testWidgets('السعر صفر يُعرض «مجاني» بلا عدّاد', (tester) async {
      final freeHotel = HotelModel.fromJson({
        ...Map<String, dynamic>.from(hotelDetailJson['hotel'] as Map),
        'extra_bed_price': 0,
      });
      tester.view.physicalSize = const Size(390, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        wrapShot(BookingScreen(hotel: freeHotel, unitId: 13), isArabic: true),
      );
      await tester.pumpAndSettle();

      await enableExtraBed(tester);

      expect(find.text('مجاني'), findsWidgets);
      expect(find.text('عدد الأسرّة الإضافية'), findsNothing,
          reason: 'السعر 0 لا يحتاج عدّادًا لأن الرسم صفر');
    });

    test('حسابية السرير الإضافي = العدد × السعر × الليالي', () {
      expect(
        computeExtraBedCharge(
            extraBed: true, extraBedPrice: 150, quantity: 3, nights: 4),
        1800,
      );
      expect(
        computeExtraBedCharge(
            extraBed: true, extraBedPrice: 150, quantity: 1, nights: 2),
        300,
      );
      expect(
        computeExtraBedCharge(
            extraBed: false, extraBedPrice: 150, quantity: 2, nights: 2),
        0,
      );
      expect(
        computeExtraBedCharge(
            extraBed: true, extraBedPrice: 0, quantity: 2, nights: 2),
        0,
      );
      expect(
        extraBedChargeFormula(quantity: 2, nightlyPrice: 150, nights: 3),
        '2 × 150 × 3',
      );
    });
  });

  group('جسم طلب الحجز يحمل السرير الإضافي في المسارين', () {
    test('وحدة محددة: extra_bed و extra_bed_qty', () {
      final payload = buildBookingPayload(
        hotelId: 2,
        unitId: 13,
        checkIn: DateTime(2026, 11, 27),
        checkOut: DateTime(2026, 11, 29),
        guests: 2,
        paymentMethod: 'cash',
        extraBed: true,
        extraBedQty: 2,
      );
      expect(payload['extra_bed'], isTrue);
      expect(payload['extra_bed_qty'], 2);
      expect(payload['unit_id'], 13);
    });

    test('حجز على مستوى الفندق: extra_bed بلا وحدة', () {
      final payload = buildBookingPayload(
        hotelId: 2,
        checkIn: DateTime(2026, 11, 27),
        checkOut: DateTime(2026, 11, 29),
        guests: 2,
        paymentMethod: 'cash',
        extraBed: true,
        extraBedQty: 1,
      );
      expect(payload['extra_bed'], isTrue);
      // العدد 1 هو الافتراضي في السيرفر، فلا يُرسل حقلًا زائدًا.
      expect(payload.containsKey('extra_bed_qty'), isFalse);
      expect(payload.containsKey('unit_id'), isFalse);
    });

    test('بلا سرير إضافي لا تُرسل كمية', () {
      final payload = buildBookingPayload(
        hotelId: 2,
        checkIn: DateTime(2026, 11, 27),
        checkOut: DateTime(2026, 11, 29),
        guests: 2,
        paymentMethod: 'cash',
      );
      expect(payload['extra_bed'], isFalse);
      expect(payload.containsKey('extra_bed_qty'), isFalse);
    });
  });
}
