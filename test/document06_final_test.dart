import 'package:allowners/models/unit_model.dart';
import 'package:allowners/screens/booking/booking_screen.dart';
import 'package:allowners/services/notification_service.dart';
import 'package:allowners/utils/app_strings.dart';
import 'package:allowners/utils/arrivals.dart';
import 'package:allowners/utils/availability.dart';
import 'package:allowners/utils/booking_payload.dart';
import 'package:allowners/utils/city_ordering.dart';
import 'package:allowners/utils/home_sections.dart';
import 'package:allowners/utils/notification_routing.dart';
import 'package:flutter_test/flutter_test.dart';

/// اختبارات الدفعة النهائية للمستندين 05 و06 (§A، §B، §D، §F).
void main() {
  group('§A — ترتيب الرئيسية والوجهات', () {
    test('«اكتشف حسب النوع» آخر قسم في الرئيسية', () {
      expect(kHomeSectionOrder.last, HomeSection.categories);
      expect(kHomeSectionOrder.first, HomeSection.destinations);
      // لا قسم مفقود ولا مُكرَّر.
      expect(kHomeSectionOrder.toSet().length, HomeSection.values.length);
    });

    test('ترتيب المدن: مكة ثم المدينة ثم جدة (والرياض تبقى بعدها)', () {
      expect(kFeaturedCityOrder.take(3).toList(), ['مكة', 'المدينة', 'جدة']);
      expect(kFeaturedCityOrder, contains('الرياض'));
      final cities = ['الرياض', 'جدة', 'المدينة', 'مكة', 'الطائف'];
      final ordered = CityOrdering.prioritize(cities, (c) => c);
      expect(ordered, ['مكة', 'المدينة', 'جدة', 'الرياض', 'الطائف']);
      // لا مدينة تُحذف ولا تُضاف.
      expect(ordered.toSet(), cities.toSet());
    });

    test('اسم المدينة كما يعيده الـ API («مكة المكرمة») يُطابق المطلوب', () {
      final ordered = CityOrdering.prioritize(['جدة', 'مكة المكرمة'], (c) => c);
      expect(ordered.first, 'مكة المكرمة');
    });
  });

  group('§B — حسابية السرير الإضافي والليالي', () {
    test('التكلفة = العدد × سعر الليلة × الليالي', () {
      expect(
          computeExtraBedCharge(
              extraBed: true, extraBedPrice: 100, quantity: 2, nights: 3),
          600);
      expect(
          computeExtraBedCharge(
              extraBed: true, extraBedPrice: 100, quantity: 1, nights: 4),
          400);
    });

    test('بدون سرير أو بسعر صفري لا تُحتسب تكلفة', () {
      expect(
          computeExtraBedCharge(
              extraBed: false, extraBedPrice: 100, quantity: 2, nights: 3),
          0);
      expect(
          computeExtraBedCharge(
              extraBed: true, extraBedPrice: 0, quantity: 2, nights: 3),
          0);
      expect(
          computeExtraBedCharge(
              extraBed: true, extraBedPrice: 100, quantity: 1),
          100); // بلا ليالٍ صريحة: ليلة واحدة
    });

    test('سطر الشرح يعرض العدد والسعر والليالي', () {
      expect(extraBedChargeFormula(quantity: 2, nightlyPrice: 100, nights: 3),
          '2 × 100 × 3');
    });

    test('جسم الحجز يرسل العدد ولا يرسله حين لا سرير', () {
      final withBed = buildBookingPayload(
        hotelId: 1,
        checkIn: DateTime(2026, 11, 1),
        checkOut: DateTime(2026, 11, 4),
        guests: 2,
        paymentMethod: 'at_hotel',
        extraBed: true,
        extraBedQty: 2,
      );
      expect(withBed['extra_bed'], isTrue);
      expect(withBed['extra_bed_qty'], 2);

      final oneBed = buildBookingPayload(
        hotelId: 1,
        checkIn: DateTime(2026, 11, 1),
        checkOut: DateTime(2026, 11, 4),
        guests: 2,
        paymentMethod: 'at_hotel',
        extraBed: true,
        extraBedQty: 1,
      );
      expect(oneBed.containsKey('extra_bed_qty'), isFalse);

      final noBed = buildBookingPayload(
        hotelId: 1,
        checkIn: DateTime(2026, 11, 1),
        checkOut: DateTime(2026, 11, 4),
        guests: 2,
        paymentMethod: 'at_hotel',
        extraBedQty: 2,
      );
      expect(noBed['extra_bed'], isFalse);
      expect(noBed.containsKey('extra_bed_qty'), isFalse);
      // لا بيانات بطاقة في أي حال.
      expect(noBed.keys.any((k) => k.contains('card')), isFalse);
    });

    test('منتقي التاريخ يمنع الأيام خارج فترات الإتاحة المعلنة', () {
      final periods = [
        UnitAvailabilityModel(
            from: DateTime(2026, 11, 1), to: DateTime(2026, 11, 10)),
      ];
      expect(isDaySelectable(day: DateTime(2026, 11, 5), periods: periods),
          isTrue);
      expect(isDaySelectable(day: DateTime(2026, 12, 5), periods: periods),
          isFalse);
      // بلا فترات معلنة لا قيد محلي ولا اختلاق.
      expect(isDaySelectable(day: DateTime(2026, 12, 5), periods: const []),
          isTrue);
      expect(
          checkAvailability(
            checkIn: DateTime(2026, 11, 1),
            checkOut: DateTime(2026, 11, 5),
            periods: periods,
          ),
          AvailabilityVerdict.inside);
      expect(
          checkAvailability(
            checkIn: DateTime(2026, 11, 8),
            checkOut: DateTime(2026, 11, 12),
            periods: periods,
          ),
          AvailabilityVerdict.outside);
    });
  });

  group('§F — وصولات الفندق وبحث رقم الوحدة', () {
    final base = {
      'check_in': '2026-11-26',
      'check_out': '2026-11-28',
      'unit_number': '402',
      'status': 'confirmed',
    };

    test('وصول اليوم يُكتشف من التاريخ أو من can_check_in', () {
      expect(isArrivalRecord(base, DateTime(2026, 11, 26)), isTrue);
      expect(isArrivalRecord(base, DateTime(2026, 11, 27)), isFalse);
      expect(
          isArrivalRecord({'can_check_in': true, 'check_in': '2026-01-01'},
              DateTime(2026, 11, 26)),
          isTrue);
      // المسجَّل دخوله ليس وصولًا.
      expect(
          isArrivalRecord(
              {...base, 'status': 'checked_in'}, DateTime(2026, 11, 26)),
          isFalse);
    });

    test('البحث برقم الوحدة داخل الوصولات فقط', () {
      final rows = [
        {...base, 'id': 1, 'guest_name': 'أ'},
        {...base, 'id': 2, 'unit_number': '1205', 'guest_name': 'ب'},
        {
          ...base,
          'id': 3,
          'unit_number': '999',
          'check_in': '2026-12-01',
          'guest_name': 'ج'
        },
      ];
      final found = filterArrivalsByUnit(
          bookings: rows, query: '120', today: DateTime(2026, 11, 26));
      expect(found.map((r) => r['id']), [2]);
      // مسح البحث يُعيد كل وصول اليوم (وليس الحجز المستقبلي).
      final all = filterArrivalsByUnit(
          bookings: rows, query: '   ', today: DateTime(2026, 11, 26));
      expect(all.map((r) => r['id']), [1, 2]);
      // بحث بلا مطابقة.
      expect(
          filterArrivalsByUnit(
              bookings: rows, query: '777', today: DateTime(2026, 11, 26)),
          isEmpty);
    });
  });

  group('§D — توجيه الإشعارات ونصوصها', () {
    test('أنواع الأحداث تُقرأ من الحمولة دون اختلاق', () {
      expect(parseNotificationEvent({'type': 'booking'}),
          NotificationEvent.bookingCreated);
      expect(parseNotificationEvent({'event': 'booking_confirmed'}),
          NotificationEvent.bookingConfirmed);
      expect(parseNotificationEvent({'kind': 'cleaning'}),
          NotificationEvent.serviceRequestCreated);
      expect(parseNotificationEvent({'event': 'payment_link_issued'}),
          NotificationEvent.paymentLinkIssued);
      expect(parseNotificationEvent(const {}), NotificationEvent.unknown);
    });

    test('الوجهة تُشتق من نوع الحدث', () {
      expect(targetForEvent(NotificationEvent.bookingConfirmed),
          NotificationTarget.booking);
      expect(targetForEvent(NotificationEvent.serviceRequestApproved),
          NotificationTarget.serviceRequest);
      expect(targetForEvent(NotificationEvent.paymentLinkIssued),
          NotificationTarget.payment);
      expect(
          targetForEvent(NotificationEvent.unknown), NotificationTarget.none);
      expect(
          notificationRouteKey(NotificationEvent.bookingCreated), 'bookings');
    });

    test('نص الخادم للغة الجهاز يُفضَّل، ثم النص المترجم محليًا', () {
      final data = {
        'type': 'booking_confirmed',
        'title_ar': 'تم تأكيد حجزك',
        'body_ar': 'الوحدة 402',
        'title_en': 'Your booking is confirmed',
      };
      final ar = notificationTexts(data, isArabic: true);
      expect(ar.title, 'تم تأكيد حجزك');
      expect(ar.body, 'الوحدة 402');
      final en = notificationTexts(data, isArabic: false);
      expect(en.title, 'Your booking is confirmed');
      expect(en.body, '');
      // بلا نصوص من الخادم: العنوان من مفاتيح التطبيق.
      final fallback = notificationTexts({'type': 'payment'}, isArabic: true);
      expect(fallback.title, AppStrings.t(true, 'notif_payment_received'));
    });

    test('كل مفاتيح عناوين الإشعارات مترجمة في اللغتين', () {
      for (final event in NotificationEvent.values) {
        final key = notificationTitleKey(event);
        expect(AppStrings.t(true, key), isNotEmpty, reason: key);
        expect(AppStrings.t(false, key), isNotEmpty, reason: key);
      }
    });

    test('مفتاح إزالة التكرار يمنع عرض نفس الإشعار مرتين', () {
      expect(
          notificationDedupeKey(
              {'type': 'booking', 'message_id': 'abc', 'booking_id': 7}),
          'msg:abc');
      expect(notificationDedupeKey({'type': 'booking', 'booking_id': 7}),
          'bookingCreated:7');
      expect(notificationDedupeKey(const {}), isNull);
      expect(notificationEntityId({'request_id': '12'}), 12);
      expect(notificationEntityId({'request_id': 'x'}), isNull);
    });
  });

  group('§D — خدمة الإشعارات لا تدّعي عملًا غير موجود', () {
    test('بلا مزوّد مهيّأ: لا تسجيل ولا رمز ولا إشعار', () async {
      final service = NotificationService();
      expect(service.isConfigured, isFalse);
      final result = await service.register(locale: 'ar');
      expect(result.registered, isFalse);
      expect(result.reason, 'push_provider_not_configured');
      await service.dispose();
    });

    test('المزوّد غير المهيّأ لا يُرجع رمزًا', () async {
      const provider = UnavailablePushProvider();
      expect(await provider.currentToken(), isNull);
      expect(await provider.requestPermission(), PushPermission.unavailable);
    });

    test('حمولة الرمز تحمل الرمز والمنصّة واللغة فقط', () {
      final service = NotificationService();
      final payload = service.tokenPayload('tok-1', locale: 'en');
      expect(payload['token'], 'tok-1');
      expect(payload['locale'], 'en');
      expect(payload.keys.toSet(), {'token', 'platform', 'locale'});
    });

    test('تسجيل رمز فارغ يُرفض بلا استدعاء شبكي', () async {
      final service = NotificationService();
      final result = await service.refreshToken('  ', locale: 'ar');
      expect(result.registered, isFalse);
      expect(result.reason, 'no_device_token');
      await service.dispose();
    });
  });
}
