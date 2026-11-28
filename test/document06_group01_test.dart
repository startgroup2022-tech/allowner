import 'dart:convert';
import 'dart:typed_data';

import 'package:allowners/models/app_user.dart';
import 'package:allowners/models/hotel_model.dart';
import 'package:allowners/screens/booking/booking_success_screen.dart';
import 'package:allowners/screens/bookings/my_bookings_screen.dart';
import 'package:allowners/screens/hotel_staff/hotel_departures_screen.dart';
import 'package:allowners/services/api_client.dart';
import 'package:allowners/theme/app_theme.dart';
import 'package:allowners/utils/app_strings.dart';
import 'package:allowners/utils/departures.dart';
import 'package:allowners/utils/housekeeping_settlement.dart';
import 'package:allowners/utils/maintenance_settlement.dart';
import 'package:allowners/utils/payment_methods_config.dart';
import 'package:allowners/utils/session_provider.dart';
import 'package:allowners/utils/unit_search.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// اختبارات المستند 06 — المجموعة 01 (المتطلبات 1–10).

const _bookingsJson = {
  'success': true,
  'bookings': [
    {
      'id': 71,
      'guest_name': 'سالم الغامدي',
      'hotel_name': 'فندق فيرمونت مكه',
      'unit_name_ar': 'جناح عائلي',
      'unit_name_en': 'Family Suite',
      'unit_number': '4005',
      'check_in': '2026-11-20',
      'check_out': '2026-11-26',
      'guests': 2,
      'status': 'checked_in',
      'can_check_out': true,
    },
    {
      'id': 72,
      'guest_name': 'نورة العتيبي',
      'hotel_name': 'فندق فيرمونت مكه',
      'unit_name_ar': 'غرفة مزدوجة',
      'unit_name_en': 'Double Room',
      'unit_number': '1201',
      'check_in': '2026-11-22',
      'check_out': '2026-11-28',
      'guests': 1,
      'status': 'checked_in',
      'can_check_out': false,
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
    Object body;
    if (options.path.contains('bookings/my')) {
      body = _bookingsJson;
    } else if (options.path.contains('hotel/bookings')) {
      body = _bookingsJson;
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
  late HttpClientAdapter originalAdapter;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    originalAdapter = ApiClient.instance.dio.httpClientAdapter;
    ApiClient.instance.dio.httpClientAdapter = _Adapter();
  });

  tearDown(() {
    ApiClient.instance.dio.httpClientAdapter = originalAdapter;
  });

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen,
    String role, {
    bool isArabic = true,
    double width = 390,
  }) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = SessionNotifier();
    await tester.pumpWidget(_wrap(screen, session, isArabic: isArabic));
    await tester.pumpAndSettle();
    session.state = SessionState(
      user: AppUser(
        id: 9,
        fullName: 'مستخدم تجريبي',
        email: 'user@example.com',
        role: role,
      ),
      isLoading: false,
    );
    await tester.pumpAndSettle();
  }

  group('المتطلب 1 — «ضيافاتي» بدل «حجوزاتي» للضيف', () {
    test('النصوص العربية والإنجليزية', () {
      expect(AppStrings.t(true, 'my_stays'), 'ضيافاتي');
      expect(AppStrings.t(false, 'my_stays'), 'My Stays');
      expect(AppStrings.t(true, 'nav_stays'), 'ضيافاتي');
    });
    test('مصطلح المالك والوكيل يبقى «حجوزاتي»', () {
      expect(AppStrings.t(true, 'my_bookings'), 'حجوزاتي');
      expect(AppStrings.t(false, 'my_bookings'), 'My Bookings');
    });
    testWidgets('شاشة الضيف تعرض «ضيافاتي»', (tester) async {
      await pumpScreen(tester, const MyBookingsScreen(), 'guest');
      expect(tester.takeException(), isNull);
      expect(find.text('ضيافاتي'), findsWidgets);
      expect(find.text('حجوزاتي'), findsNothing);
    });
    testWidgets('شاشة الوكيل تبقى «حجوزاتي»', (tester) async {
      await pumpScreen(tester, const MyBookingsScreen(), 'booking_agent');
      expect(tester.takeException(), isNull);
      expect(find.text('حجوزاتي'), findsWidgets);
      expect(find.text('ضيافاتي'), findsNothing);
    });
  });

  group('المتطلب 2 — البحث برقم الوحدة داخل تفاصيل الفندق', () {
    List<String> units(List<String?> queries) => const [
          '1001',
          '1002',
          '2101',
          '2102',
          'AR-7',
        ];

    test('البحث الفارغ يُرجع كل الوحدات', () {
      final all = units([]);
      expect(
        filterUnitsByUnitNumber(units: all, query: '  ', unitNumberOf: (u) => u)
            .length,
        all.length,
      );
    });
    test('مطابقة جزئية ومطابقة كاملة مع تقديم الكاملة', () {
      final result = filterUnitsByUnitNumber(
        units: const ['2101', '1001', '1101'],
        query: '101',
        unitNumberOf: (u) => u,
      );
      expect(result.first, '2101');
      expect(result.contains('1101'), isTrue);
      expect(result.contains('1001'), isFalse);
    });
    test('يقبل الأرقام العربية-الهندية والحروف اللاتينية', () {
      expect(
        filterUnitsByUnitNumber(
          units: const ['1001', '2102'],
          query: '١٠٠١',
          unitNumberOf: (u) => u,
        ),
        ['1001'],
      );
      expect(
        filterUnitsByUnitNumber(
          units: const ['AR-7', '1001'],
          query: 'ar-7',
          unitNumberOf: (u) => u,
        ),
        ['AR-7'],
      );
    });
    test('حالة «لا نتائج» تظهر فقط عند وجود وحدات وغياب المطابقة', () {
      expect(
        hasNoUnitSearchMatch(
            units: const ['1001'], query: '999', unitNumberOf: (u) => u),
        isTrue,
      );
      expect(
        hasNoUnitSearchMatch(
            units: const ['1001'], query: '', unitNumberOf: (u) => u),
        isFalse,
      );
      expect(
        hasNoUnitSearchMatch(
            units: const <String>[], query: '999', unitNumberOf: (u) => u),
        isFalse,
      );
    });
    test('نصوص البحث متاحة بالعربية والإنجليزية', () {
      expect(
          AppStrings.t(true, 'search_unit_number_hint'), 'البحث برقم الوحدة');
      expect(AppStrings.t(false, 'search_unit_number_hint'),
          'Search by unit number');
      expect(AppStrings.t(true, 'no_matching_units'), isNotEmpty);
      expect(AppStrings.t(false, 'no_matching_units'), isNotEmpty);
      expect(AppStrings.t(true, 'clear_search'), isNotEmpty);
    });
  });

  group('المتطلب 3 — «رقم الضيافة» بدل «رقم الحجز»', () {
    test('النصوص', () {
      expect(AppStrings.t(true, 'stay_reference'), 'رقم الضيافة');
      expect(AppStrings.t(false, 'stay_reference'), 'Stay Reference');
    });
    test('الصف الأول في تفاصيل الضيافة يستخدم التسمية الجديدة', () {
      final rows = buildBookingSuccessRows(
        isArabic: true,
        hotelName: 'فندق',
        unitNumber: '4005',
        bookingRef: 'BK-77',
      );
      expect(rows.first.$1, 'رقم الضيافة');
      // المرجع الداخلي مسموح بتسمية مختلفة تمامًا عن «رقم الحجز».
      expect(rows.any((r) => r.$1 == 'رقم الحجز'), isFalse);
      expect(
          AppStrings.t(true, 'booking_reference_internal'), isNot('رقم الحجز'));
    });
  });

  group('المتطلب 4 — عرض رقم الوحدة الفعلي', () {
    test('يعرض رقم الوحدة القادم من الاستجابة', () {
      final rows = buildBookingSuccessRows(
        isArabic: false,
        hotelName: 'Hotel',
        unitNumber: ' 4005 ',
        bookingRef: 'BK-77',
      );
      expect(rows.first.$2, '4005');
    });
    test('لا يختلق رقمًا حين لا يصل رقم وحدة', () {
      // تصحيح قبول المجموعة 01: لا يُعرض رقم الحجز مكان رقم الوحدة.
      final rows = buildBookingSuccessRows(
        isArabic: false,
        hotelName: 'Hotel',
        bookingRef: 'BK-77',
      );
      expect(rows.first.$1, 'Stay Reference');
      expect(rows.first.$2, AppStrings.t(false, 'not_available'));
      expect(rows.first.$2, isNot('BK-77'));
      // المرجع الداخلي يبقى محفوظًا في سطر منفصل.
      final internal = rows.firstWhere(
          (r) => r.$1 == AppStrings.t(false, 'booking_reference_internal'));
      expect(internal.$2, 'BK-77');
      final noRef =
          buildBookingSuccessRows(isArabic: false, hotelName: 'Hotel');
      expect(noRef.first.$2, AppStrings.t(false, 'not_available'));
    });
  });

  group('المتطلب 5 — إزالة عرض طريقة الدفع', () {
    test('لا صف لطريقة الدفع في تفاصيل الضيافة', () {
      final rows = buildBookingSuccessRows(
        isArabic: true,
        hotelName: 'فندق',
        bookingRef: 'BK-1',
        status: 'confirmed',
        total: 900,
      );
      expect(
          rows.any((r) => r.$1 == AppStrings.t(true, 'payment_method_label')),
          isFalse);
      expect(
          rows.any((r) => r.$1 == AppStrings.t(false, 'payment_method_label')),
          isFalse);
    });
  });

  group('المتطلب 6 — «عرض تفاصيل ضيافتي»', () {
    test('النصوص', () {
      expect(AppStrings.t(true, 'view_stay_details'), 'عرض تفاصيل ضيافتي');
      expect(AppStrings.t(false, 'view_stay_details'), 'View My Stay Details');
      // تسمية الوكيل/المالك لا تتغير.
      expect(AppStrings.t(true, 'view_booking_details'), 'عرض تفاصيل الحجز');
    });
    testWidgets('زر تفاصيل الضيافة للضيف بالتسمية الجديدة', (tester) async {
      await pumpScreen(
        tester,
        BookingSuccessScreen(
          hotel: HotelModel.fromJson(const {
            'id': 1,
            'name': 'فندق فيرمونت مكه',
            'city_ar': 'مكة المكرمة',
            'city_en': 'Makkah',
          }),
          bookingRef: 'BK-77',
          unitNumber: '4005',
        ),
        'guest',
      );
      expect(tester.takeException(), isNull);
      expect(find.text('عرض تفاصيل ضيافتي'), findsWidgets);
      expect(find.text('4005'), findsWidgets);
    });
  });

  group('المتطلبان 7 و8 — إتاحة وسائل الدفع من السيرفر', () {
    test('الافتراضي: الدفع عند الوصول والتحويل للمالك معطّلان', () {
      final availability = resolvePaymentMethods(null);
      expect(availability.isEnabled(PaymentMethodKey.atHotel), isFalse);
      expect(availability.isEnabled(PaymentMethodKey.ownerTransfer), isFalse);
      expect(availability.isEnabled(PaymentMethodKey.online), isFalse);
      expect(availability.hasAny, isFalse);
    });
    test('الإدارة تستطيع تفعيل كل وسيلة على حدة', () {
      final availability = resolvePaymentMethods(const {
        'payment_methods': {'at_hotel': true, 'owner_transfer': false},
      });
      expect(availability.isEnabled(PaymentMethodKey.atHotel), isTrue);
      expect(availability.isEnabled(PaymentMethodKey.ownerTransfer), isFalse);
    });
    test('الدفع الإلكتروني لا يُفعَّل بلا صفحة دفع مستضافة https', () {
      final noUrl = resolvePaymentMethods(const {
        'payment_methods': {'online': true},
      });
      expect(noUrl.isEnabled(PaymentMethodKey.online), isFalse);

      final insecure = resolvePaymentMethods(const {
        'payment_methods': {'online': true},
        'payment_checkout_url': 'http://pay.example.com/checkout',
      });
      expect(insecure.isEnabled(PaymentMethodKey.online), isFalse);

      final secure = resolvePaymentMethods(const {
        'payment_methods': {'online': true},
        'payment_checkout_url': 'https://pay.example.com/checkout',
      });
      expect(secure.isEnabled(PaymentMethodKey.online), isTrue);
    });
    test('الوسيلة المعطّلة تُرفض قبل الإرسال ولو تجاوز المستخدم الواجهة', () {
      final availability = resolvePaymentMethods(const {
        'payment_methods': {'at_hotel': false},
      });
      expect(paymentMethodBlockReason(availability, 'at_hotel'), isNotNull);
      expect(
          paymentMethodBlockReason(availability, 'owner_transfer'), isNotNull);
      expect(paymentMethodBlockReason(availability, 'online'), isNotNull);
      expect(
        paymentMethodBlockReason(
            resolvePaymentMethods(const {'payment_at_hotel_enabled': '1'}),
            'at_hotel'),
        isNull,
      );
    });
  });

  group('المتطلب 9 — بحث مغادرات الفندق برقم الوحدة', () {
    final today = DateTime(2026, 11, 26);
    final bookings = <Map<String, dynamic>>[
      {
        'id': 1,
        'guest_name': 'سالم',
        'unit_number': '4005',
        'check_out': '2026-11-26',
      },
      {
        'id': 2,
        'guest_name': 'نورة',
        'room_number': '1201',
        'check_out': '2026-11-26',
      },
      {
        'id': 3,
        'guest_name': 'فهد',
        'unit_number': '3300',
        'check_out': '2026-12-02',
      },
    ];

    test('يعرض مغادرات اليوم فقط افتراضيًا', () {
      final rows =
          filterDeparturesByUnit(bookings: bookings, query: '', today: today);
      expect(rows.map((r) => r['id']), [1, 2]);
    });
    test('البحث الجزئي برقم الغرفة أو الوحدة', () {
      expect(
        filterDeparturesByUnit(bookings: bookings, query: '40', today: today)
            .map((r) => r['id']),
        [1],
      );
      expect(
        filterDeparturesByUnit(bookings: bookings, query: '1201', today: today)
            .map((r) => r['id']),
        [2],
      );
    });
    test('لا نتائج لرقم غير موجود', () {
      expect(
        filterDeparturesByUnit(bookings: bookings, query: '9999', today: today),
        isEmpty,
      );
    });
    test('can_check_out من السيرفر يعتمد حتى لو اختلف التاريخ', () {
      final rows = filterDeparturesByUnit(
        bookings: const [
          {'id': 9, 'unit_number': '7777', 'can_check_out': true},
        ],
        query: '',
        today: today,
      );
      expect(rows.single['id'], 9);
    });
    test('رقم الوحدة يُقرأ من مفاتيح الباك إند ولا يُختلق', () {
      expect(departureUnitNumber({'unit_number': '4005'}), '4005');
      expect(departureUnitNumber({'room_number': '12'}), '12');
      expect(departureUnitNumber({'unit_no': 'A-1'}), 'A-1');
      expect(departureUnitNumber({'guest_name': 'x'}), '');
    });
    testWidgets('شاشة المغادرات تعرض البحث والمغادرات المصرّح بها',
        (tester) async {
      await pumpScreen(tester, const HotelDeparturesScreen(), 'hotel_manager');
      expect(tester.takeException(), isNull);
      expect(find.text('مغادرات اليوم'), findsWidgets);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.textContaining('سالم الغامدي'), findsWidgets);
    });
  });

  group('المتطلب 10 — خيارا سداد طلب النظافة', () {
    test('النصوص العربية والإنجليزية', () {
      expect(AppStrings.t(true, 'settle_wallet_balance'), 'خصم من الرصيد');
      expect(
          AppStrings.t(false, 'settle_wallet_balance'), 'Deduct from Balance');
      expect(AppStrings.t(true, 'settle_whatsapp_pay_link'),
          'الدفع عبر رابط بالواتساب');
      expect(AppStrings.t(false, 'settle_whatsapp_pay_link'),
          'Pay via WhatsApp Link');
    });
    test('قيم الإرسال للسيرفر', () {
      expect(
          housekeepingSettlementPayload(HousekeepingSettlement.walletBalance),
          'wallet_balance');
      expect(housekeepingSettlementPayload(HousekeepingSettlement.whatsappLink),
          'whatsapp_link');
    });
    test('السعر المعتمد يُقرأ من السيرفر فقط', () {
      expect(approvedHousekeepingPrice({'price': '150'}), 150);
      expect(approvedHousekeepingPrice({'approved_price': 90.5}), 90.5);
      expect(approvedHousekeepingPrice({'price': 0}), isNull);
      expect(approvedHousekeepingPrice({}), isNull);
    });
    test('لا تأكيد بلا سعر معتمد أو بلا اختيار وسيلة', () {
      expect(
        validateHousekeepingSettlement(
          request: {'price': 150},
          choice: null,
          price: 150,
          canConfirm: true,
        ),
        'payment_method_required',
      );
      expect(
        validateHousekeepingSettlement(
          request: {},
          choice: HousekeepingSettlement.walletBalance,
          price: null,
          canConfirm: true,
        ),
        'housekeeping_price_missing',
      );
      expect(
        validateHousekeepingSettlement(
          request: {'price': 150},
          choice: HousekeepingSettlement.walletBalance,
          price: 150,
          canConfirm: true,
        ),
        isNull,
      );
    });
    test('منع الخصم المزدوج وطلب الدفع المكرر', () {
      for (final recorded in const [
        {'settlement': 'wallet_balance'},
        {'settled': true},
        {'payment_status': 'paid'},
        {'settlement_status': 'deducted'},
      ]) {
        expect(isHousekeepingSettlementRecorded(recorded), isTrue);
        expect(
          validateHousekeepingSettlement(
            request: {...recorded, 'price': 100},
            choice: HousekeepingSettlement.walletBalance,
            price: 100,
            canConfirm: true,
          ),
          'settlement_already_recorded',
        );
      }
      expect(isHousekeepingSettlementRecorded({'status': 'pending'}), isFalse);
    });
    test('صلاحيات التأكيد تتبع أدوار لوحة الفندق', () {
      expect(canConfirmHousekeepingSettlement('hotel_manager'), isTrue);
      expect(canConfirmHousekeepingSettlement('owner'), isTrue);
      expect(canConfirmHousekeepingSettlement('unit_manager'), isTrue);
      expect(canConfirmHousekeepingSettlement('guest'), isFalse);
      expect(canConfirmHousekeepingSettlement('booking_agent'), isFalse);
      expect(canConfirmHousekeepingSettlement(null), isFalse);
      expect(
        validateHousekeepingSettlement(
          request: {'price': 100},
          choice: HousekeepingSettlement.walletBalance,
          price: 100,
          canConfirm: false,
        ),
        'permission_denied',
      );
    });
    test('رابط الدفع يؤخذ من السيرفر فقط (https)', () {
      expect(
        extractServerPaymentLink(const {
          'payment_link': 'https://pay.example.com/i/abc',
        }),
        'https://pay.example.com/i/abc',
      );
      expect(
        extractServerPaymentLink(
            const {'payment_link': 'http://pay.example.com'}),
        isNull,
      );
      expect(
        extractServerPaymentLink(const {'payment_link': 'javascript:alert(1)'}),
        isNull,
      );
      expect(extractServerPaymentLink(const {'success': true}), isNull);
      expect(extractServerPaymentLink(null), isNull);
    });
    test('رسالة واتساب تحمل الرابط الحقيقي فقط عند وصوله', () {
      final withoutLink = buildHousekeepingWhatsAppUri(
        phone: '0500000000',
        isArabic: true,
        requestId: 12,
        unitName: '4005',
        amount: 150,
      );
      expect(withoutLink, isNotNull);
      final text = withoutLink!.queryParameters['text']!;
      expect(text.contains('150'), isTrue);
      expect(text.contains('http'), isFalse);

      final withLink = buildHousekeepingWhatsAppUri(
        phone: '0500000000',
        isArabic: true,
        requestId: 12,
        amount: 150,
        paymentLink: 'https://pay.example.com/i/abc',
      );
      expect(withLink!.queryParameters['text'],
          contains('https://pay.example.com/i/abc'));
      expect(
        buildHousekeepingWhatsAppUri(phone: null, isArabic: true),
        isNull,
      );
    });
    test('خيارا الصيانة القائمان لم يتغيرا', () {
      expect(
          settlementPayload(MaintenanceSettlement.unitBalance), 'unit_balance');
      expect(settlementPayload(MaintenanceSettlement.whatsappLink),
          'whatsapp_link');
    });
  });
}
