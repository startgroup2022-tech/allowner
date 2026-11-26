import 'package:allowners/screens/booking/booking_success_screen.dart';
import 'package:allowners/utils/app_strings.dart';
import 'package:allowners/utils/payment_methods_config.dart';
import 'package:allowners/utils/housekeeping_settlement.dart';
import 'package:allowners/utils/pricing_forms.dart';
import 'package:allowners/utils/request_settlement.dart';
import 'package:flutter_test/flutter_test.dart';

/// اختبارات المستند 06 — المجموعة 02 (المتطلبات 11–16).
void main() {
  group('المتطلب 11 — تأكيد طلب الوجبات بالسداد', () {
    test('تمييز نوع الطلب', () {
      expect(settlementKindForRequestType('meal'), SettlementRequestKind.meal);
      expect(settlementKindForRequestType('cleaning'),
          SettlementRequestKind.cleaning);
      expect(settlementKindForRequestType('extra_bed'),
          SettlementRequestKind.extraBed);
      // الصيانة لها مسارها القائم، فلا تُدخل في مسار تسوية الخدمات.
      expect(settlementKindForRequestType('maintenance'), isNull);
      expect(settlementKindForRequestType(null), isNull);
    });

    test('السعر المعتمد يُقرأ من حقول السيرفر الحقيقية فقط', () {
      expect(approvedRequestPrice({'price': 150}), 150);
      expect(approvedRequestPrice({'price': '150.5'}), 150.5);
      expect(approvedRequestPrice({'approved_price': 90}), 90);
      expect(approvedRequestPrice({'total_price': '220'}), 220);
      expect(approvedRequestPrice({'cost': 40}), 40);
      expect(approvedRequestPrice({'price': 0}), isNull);
      expect(approvedRequestPrice(const {}), isNull);
    });

    test('أنواع الوجبات تُقرأ من الطلب ولا تُختلق', () {
      expect(
          requestMealLabels({
            'meal_types': ['breakfast', 'dinner']
          }),
          ['breakfast', 'dinner']);
      expect(
          requestMealLabels({
            'meals': [
              {'name': 'breakfast'},
              {'name': 'غداء'},
            ],
          }),
          ['breakfast', 'غداء']);
      expect(requestMealLabels({'meal_type': 'breakfast، lunch'}).length, 2);
      // التكرار يُزال، والاسم غير المعروف يُعرض كما وصل.
      expect(requestMealLabels({'meal_type': 'brunch, brunch'}), ['brunch']);
      expect(requestMealLabels(const {}), isEmpty);
    });

    test('تسميات الوجبات تُترجم عبر مفاتيح التطبيق', () {
      expect(mealLabelKey('breakfast'), 'meal_breakfast');
      expect(mealLabelKey('فطور'), 'meal_breakfast');
      expect(mealLabelKey('lunch'), 'meal_lunch');
      expect(mealLabelKey('dinner'), 'meal_dinner');
      expect(mealLabelKey('brunch'), isNull);
      expect(AppStrings.t(true, 'meal_breakfast'), 'فطور');
      expect(AppStrings.t(false, 'meal_breakfast'), 'Breakfast');
    });

    test('التحقق يمنع التأكيد بلا سعر معتمد أو بلا وسيلة سداد', () {
      const request = {'id': 7, 'type': 'meal', 'status': 'pending'};
      expect(
          validateRequestSettlement(
            request: request,
            choice: RequestSettlement.walletBalance,
            price: 150,
            canConfirm: true,
            kind: SettlementRequestKind.meal,
          ),
          isNull);
      expect(
          validateRequestSettlement(
            request: request,
            choice: null,
            price: 150,
            canConfirm: true,
            kind: SettlementRequestKind.meal,
          ),
          'payment_method_required');
      expect(
          validateRequestSettlement(
            request: request,
            choice: RequestSettlement.walletBalance,
            price: null,
            canConfirm: true,
            kind: SettlementRequestKind.meal,
          ),
          'meal_price_missing');
      expect(
          validateRequestSettlement(
            request: request,
            choice: RequestSettlement.walletBalance,
            price: 150,
            canConfirm: false,
            kind: SettlementRequestKind.meal,
          ),
          'permission_denied');
    });

    test('منع الدفع المكرر: الطلب المسوّى لا يُسوّى مرة أخرى', () {
      expect(
          validateRequestSettlement(
            request: {'id': 7, 'type': 'meal', 'payment_status': 'paid'},
            choice: RequestSettlement.walletBalance,
            price: 150,
            canConfirm: true,
            kind: SettlementRequestKind.meal,
          ),
          'settlement_already_recorded');
      expect(
          isRequestSettlementRecorded(
              {'settlement': 'wallet_balance', 'status': 'confirmed'}),
          isTrue);
      expect(isRequestSettlementRecorded({'status': 'pending'}), isFalse);
    });

    test('الصلاحيات: أدوار لوحة الفندق فقط', () {
      for (final role in ['hotel_manager', 'owner', 'unit_manager']) {
        expect(canConfirmRequestSettlement(role), isTrue, reason: role);
      }
      for (final role in [null, '', 'customer', 'agent', 'admin']) {
        expect(canConfirmRequestSettlement(role), isFalse, reason: '$role');
      }
    });

    test('وسيلتا السداد هما فقط خصم الرصيد أو رابط واتساب', () {
      expect(RequestSettlement.values, hasLength(2));
      expect(requestSettlementPayload(RequestSettlement.walletBalance),
          'wallet_balance');
      expect(requestSettlementPayload(RequestSettlement.whatsappLink),
          'whatsapp_link');
      expect(AppStrings.t(true, 'settle_wallet_balance'), 'خصم من الرصيد');
      expect(
          AppStrings.t(false, 'settle_wallet_balance'), 'Deduct from Balance');
      expect(AppStrings.t(true, 'settle_whatsapp_pay_link'),
          'الدفع عبر رابط بالواتساب');
      expect(AppStrings.t(false, 'settle_whatsapp_pay_link'),
          'Pay via WhatsApp Link');
    });

    test('رسالة واتساب الوجبات تحمل الطلب والوحدة والمبلغ', () {
      final uri = buildSettlementWhatsAppUri(
        phone: '0500000000',
        isArabic: true,
        kind: SettlementRequestKind.meal,
        requestId: 7,
        unitName: 'جناح عائلي',
        amount: 150,
        details: const ['أنواع الوجبات: فطور'],
      );
      expect(uri, isNotNull);
      expect(uri!.host, 'wa.me');
      expect(uri.pathSegments.last, '0500000000');
      final text = uri.queryParameters['text']!;
      expect(text.contains('طلب سداد تكلفة وجبات'), isTrue);
      expect(text.contains('7'), isTrue);
      expect(text.contains('جناح عائلي'), isTrue);
      expect(text.contains('150 SAR'), isTrue);
      expect(text.contains('فطور'), isTrue);
    });

    test('لا يُبنى رابط واتساب بلا رقم صالح', () {
      expect(
          buildSettlementWhatsAppUri(
            phone: null,
            isArabic: true,
            kind: SettlementRequestKind.meal,
          ),
          isNull);
      expect(
          buildSettlementWhatsAppUri(
            phone: '123',
            isArabic: false,
            kind: SettlementRequestKind.meal,
          ),
          isNull);
    });

    test('رابط الدفع يُقبل من السيرفر فقط وبـ https', () {
      expect(
          extractServerPaymentLink(
              {'payment_link': 'https://pay.example.com/inv/7'}),
          'https://pay.example.com/inv/7');
      expect(extractServerPaymentLink({'checkout_url': 'http://x.test/1'}),
          isNull);
      expect(extractServerPaymentLink({'payment_link': ''}), isNull);
      expect(extractServerPaymentLink(null), isNull);
      final uri = buildSettlementWhatsAppUri(
        phone: '0500000000',
        isArabic: false,
        kind: SettlementRequestKind.meal,
        paymentLink: 'https://pay.example.com/inv/7',
      );
      expect(uri!.queryParameters['text']!,
          contains('https://pay.example.com/inv/7'));
    });
  });

  group('المتطلب 12 — تسوية السرير الإضافي', () {
    test('عدد الأسرّة من حقول السيرفر', () {
      expect(extraBedCount({'beds': 2}), 2);
      expect(extraBedCount({'extra_beds': '1'}), 1);
      expect(extraBedCount({'quantity': 3}), 3);
      expect(extraBedCount(const {}), isNull);
      expect(extraBedCount({'beds': 0}), isNull);
    });

    test('عدد الليالي من الطلب أو من تاريخي الوصول والمغادرة', () {
      expect(extraBedNights({'nights': 4}), 4);
      expect(
          extraBedNights({
            'check_in': '2026-11-01',
            'check_out': '2026-11-04',
          }),
          3);
      expect(extraBedNights({'check_out': '2026-11-04'}), isNull);
      expect(
          extraBedNights({
            'check_in': '2026-11-04',
            'check_out': '2026-11-01',
          }),
          isNull);
    });

    test('الإجمالي من السيرفر أو من السعر × الأسرّة × الليالي', () {
      expect(extraBedTotal({'total': 600}, 100), 600);
      expect(extraBedTotal({'price': 100, 'beds': 2, 'nights': 3}, 100), 600);
      // بيانات ناقصة → لا رقم مُختلق.
      expect(extraBedTotal({'price': 100, 'beds': 2}, 100), isNull);
      expect(extraBedTotal(const {}, null), isNull);
    });

    test('التحقق يستخدم رسالة سعر السرير الإضافي', () {
      expect(
          validateRequestSettlement(
            request: const {'id': 9, 'type': 'extra_bed'},
            choice: RequestSettlement.whatsappLink,
            price: null,
            canConfirm: true,
            kind: SettlementRequestKind.extraBed,
          ),
          'extra_bed_price_missing');
      expect(AppStrings.t(true, 'extra_bed_price_missing'), isNotEmpty);
      expect(AppStrings.t(false, 'extra_bed_price_missing'), isNotEmpty);
    });

    test('القواعد مشتركة بين الأنواع الثلاثة', () {
      for (final kind in SettlementRequestKind.values) {
        expect(
            validateRequestSettlement(
              request: const {'id': 1},
              choice: null,
              price: 50,
              canConfirm: true,
              kind: kind,
            ),
            'payment_method_required',
            reason: kind.name);
        expect(
            validateRequestSettlement(
              request: const {'id': 1, 'settled': true},
              choice: RequestSettlement.walletBalance,
              price: 50,
              canConfirm: true,
              kind: kind,
            ),
            'settlement_already_recorded',
            reason: kind.name);
      }
    });

    test('واجهة النظافة القديمة تعمل عبر المنطق المشترك', () {
      expect(
          housekeepingSettlementPayload(HousekeepingSettlement.walletBalance),
          'wallet_balance');
      expect(
          validateHousekeepingSettlement(
            request: const {'id': 3},
            choice: HousekeepingSettlement.walletBalance,
            price: null,
            canConfirm: true,
          ),
          'housekeeping_price_missing');
      expect(approvedHousekeepingPrice({'price': 80}), 80);
      expect(canConfirmHousekeepingSettlement('owner'), isTrue);
    });

    test('رسالة واتساب السرير الإضافي تعرض الأسرّة والليالي والإجمالي', () {
      final uri = buildSettlementWhatsAppUri(
        phone: '0511111111',
        isArabic: false,
        kind: SettlementRequestKind.extraBed,
        requestId: 12,
        amount: 600,
        details: const [
          'Extra beds: 2',
          'Nights: 3',
          'Total cost: 600 SAR',
        ],
      );
      final text = uri!.queryParameters['text']!;
      expect(text.contains('Extra bed payment request'), isTrue);
      expect(text.contains('Request #12'), isTrue);
      expect(text.contains('Extra beds: 2'), isTrue);
      expect(text.contains('Nights: 3'), isTrue);
      expect(text.contains('Total cost: 600 SAR'), isTrue);
    });
  });

  group('المتطلب 13 و14 — عنوان وتاريخ نموذج تسعير الوحدات', () {
    test('تاريخ التسعير يُنسّق ويُقرأ بشكل ثابت', () {
      final date = DateTime(2026, 3, 9);
      expect(formatPricingDate(date), '2026-03-09');
      expect(parsePricingDate('2026-03-09'), date);
      expect(parsePricingDate('2026-03-09 00:00:00'), date);
      expect(parsePricingDate(''), isNull);
      expect(parsePricingDate(null), isNull);
    });

    test('العنوان والتاريخ مطلوبان قبل الحفظ', () {
      final rows = buildUnitPricingRows();
      expect(
          validateUnitPricing(
              title: ' ', date: DateTime(2026, 3, 9), rows: rows),
          'pricing_title_required');
      expect(validateUnitPricing(title: 'أسعار مارس', date: null, rows: rows),
          'pricing_date_required');
      expect(AppStrings.t(true, 'pricing_title_field'), 'العنوان');
      expect(AppStrings.t(false, 'pricing_title_field'), 'Title');
      expect(AppStrings.t(true, 'pricing_date_field'), 'التاريخ');
      expect(AppStrings.t(false, 'pricing_date_field'), 'Date');
    });

    test('جسم الحفظ يحمل العنوان والتاريخ', () {
      final payload = unitPricingPayload(
        title: 'أسعار مارس',
        date: DateTime(2026, 3, 9),
        rows: const [UnitPricingRow(unitTypeAr: 'جناح', price: 400)],
      );
      expect(payload['action'], 'save');
      expect(payload['title'], 'أسعار مارس');
      expect(payload['pricing_date'], '2026-03-09');
      expect(payload.containsKey('id'), isFalse);
      final editing = unitPricingPayload(
        id: 5,
        title: 'أسعار مارس',
        date: DateTime(2026, 3, 9),
        rows: const [UnitPricingRow(unitTypeAr: 'جناح', price: 400)],
      );
      expect(editing['id'], 5);
    });
  });

  group('المتطلب 15 — ستة صفوف أنواع وحدات وأسعار', () {
    test('النموذج يعرض ستة صفوف دائمًا', () {
      expect(buildUnitPricingRows(), hasLength(kUnitPricingRowCount));
      expect(kUnitPricingRowCount, 6);
    });

    test('أنواع الوحدات تُقرأ من بيانات الفندق بلا أسماء ثابتة', () {
      final units = [
        {'unit_type_ar': 'جناح', 'unit_type_en': 'Suite'},
        {'unit_type_ar': 'جناح', 'unit_type_en': 'Suite'},
        {'unit_type_ar': 'غرفة', 'unit_type_en': 'Room'},
      ];
      final rows = buildUnitPricingRows(units: units);
      expect(rows, hasLength(6));
      expect(rows[0].unitTypeAr, 'جناح');
      expect(rows[0].unitTypeEn, 'Suite');
      expect(rows[1].unitTypeAr, 'غرفة');
      // الصفوف الباقية فارغة، ولم تُملأ بأسماء مُختلقة.
      expect(rows.skip(2).every((r) => r.isBlank), isTrue);
      // بلا بيانات وحدات لا يظهر أي نوع وحدة.
      expect(buildUnitPricingRows().every((r) => r.isBlank), isTrue);
    });

    test('السجل المحفوظ يُسترجع كاملًا عند التعديل', () {
      final saved = {
        'id': 5,
        'title': 'أسعار مارس',
        'pricing_date': '2026-03-09',
        'rows': [
          {'unit_type_ar': 'جناح', 'price': 400},
          {'unit_type_ar': 'غرفة', 'price': 250},
        ],
      };
      final rows = buildUnitPricingRows(saved: saved);
      expect(rows[0].unitTypeAr, 'جناح');
      expect(rows[0].price, 400);
      expect(rows[1].price, 250);
      expect(parsePricingDate(saved['pricing_date']), DateTime(2026, 3, 9));
    });

    test('تحقق الأسعار يمنع الصفوف الناقصة والمكررة', () {
      final date = DateTime(2026, 3, 9);
      expect(
          validateUnitPricing(
              title: 'أسعار', date: date, rows: buildUnitPricingRows()),
          'pricing_row_required');
      expect(
          validateUnitPricing(title: 'أسعار', date: date, rows: const [
            UnitPricingRow(unitTypeAr: 'جناح'),
          ]),
          'pricing_price_invalid');
      expect(
          validateUnitPricing(title: 'أسعار', date: date, rows: const [
            UnitPricingRow(unitTypeAr: 'جناح', price: 400),
            UnitPricingRow(unitTypeAr: 'جناح', price: 500),
          ]),
          'pricing_row_required');
      expect(
          validateUnitPricing(title: 'أسعار', date: date, rows: const [
            UnitPricingRow(unitTypeAr: 'جناح', price: 400),
            UnitPricingRow(unitTypeAr: 'غرفة', price: 250),
          ]),
          isNull);
    });

    test('جسم الحفظ يحمل الصفوف المكتملة فقط', () {
      final payload = unitPricingPayload(
        title: 'أسعار',
        date: DateTime(2026, 3, 9),
        rows: const [
          UnitPricingRow(unitTypeAr: 'جناح', unitTypeEn: 'Suite', price: 400),
          UnitPricingRow(),
        ],
      );
      final rows = payload['rows'] as List;
      expect(rows, hasLength(1));
      expect(rows.single, {
        'unit_type_ar': 'جناح',
        'unit_type_en': 'Suite',
        'unit_type': 'جناح',
        'price': 400.0,
      });
      expect(AppStrings.t(true, 'unit_type_column'), 'نوع الوحدة');
      expect(AppStrings.t(false, 'unit_price_column'), 'Price');
      expect(AppStrings.t(true, 'six_unit_price_rows'), contains('ستة'));
    });
  });

  group('المتطلب 16 — تسعير الوجبات (عنوان وتاريخ وثلاث وجبات)', () {
    test('النموذج يعرض ثلاث وجبات دائمًا', () {
      expect(buildMealPricingRows(), hasLength(kMealPricingRowCount));
      expect(kMealPricingRowCount, 3);
    });

    test('الوجبات المحفوظة تُسترجع بالاسم والسعر', () {
      final rows = buildMealPricingRows(saved: {
        'meals': [
          {'name': 'فطور', 'price': 35},
          {'name': 'غداء', 'price': 60},
        ],
      });
      expect(rows[0].name, 'فطور');
      expect(rows[0].price, 35);
      expect(rows[1].price, 60);
      expect(rows[2].isBlank, isTrue);
    });

    test('التحقق يمنع الحفظ بلا عنوان أو تاريخ أو أسعار', () {
      final date = DateTime(2026, 3, 9);
      expect(
          validateMealPricing(
              title: '', date: date, rows: buildMealPricingRows()),
          'pricing_title_required');
      expect(
          validateMealPricing(
              title: 'وجبات', date: null, rows: buildMealPricingRows()),
          'pricing_date_required');
      expect(
          validateMealPricing(
              title: 'وجبات', date: date, rows: buildMealPricingRows()),
          'pricing_row_required');
      expect(
          validateMealPricing(title: 'وجبات', date: date, rows: const [
            MealPricingRow(name: 'فطور'),
          ]),
          'pricing_price_invalid');
      expect(
          validateMealPricing(title: 'وجبات', date: date, rows: const [
            MealPricingRow(name: 'فطور', price: 35),
            MealPricingRow(name: 'فطور', price: 40),
          ]),
          'pricing_row_required');
      expect(
          validateMealPricing(title: 'وجبات', date: date, rows: const [
            MealPricingRow(name: 'فطور', price: 35),
            MealPricingRow(name: 'غداء', price: 60),
            MealPricingRow(name: 'عشاء', price: 50),
          ]),
          isNull);
    });

    test('جسم الحفظ يحمل الوجبات المكتملة فقط', () {
      final payload = mealPricingPayload(
        title: 'وجبات مارس',
        date: DateTime(2026, 3, 9),
        rows: const [
          MealPricingRow(name: 'فطور', price: 35),
          MealPricingRow(),
        ],
      );
      expect(payload['action'], 'save');
      expect(payload['pricing_date'], '2026-03-09');
      expect(payload['meals'], [
        {'name': 'فطور', 'price': 35.0},
      ]);
      expect(AppStrings.t(true, 'meal_pricing_title'), 'تسعير الوجبات');
      expect(AppStrings.t(false, 'meal_pricing_title'), 'Meal pricing');
      expect(AppStrings.t(true, 'meal_name_column'), 'اسم الوجبة');
    });
  });

  group('حماية ثوابت المجموعة 01 أثناء عمل المجموعة 02', () {
    test('تفاصيل الضيافة لا تعرض رقم الحجز مكان رقم الوحدة', () {
      final rows = buildBookingSuccessRows(
        isArabic: true,
        hotelName: 'فندق',
        bookingRef: 'BK-99',
      );
      expect(rows.first.$2, AppStrings.t(true, 'not_available'));
      expect(rows.first.$2, isNot('BK-99'));
      expect(
          rows
              .firstWhere((r) =>
                  r.$1 == AppStrings.t(true, 'booking_reference_internal'))
              .$2,
          'BK-99');
    });

    test('طريقة الدفع لا تعود إلى شاشات الضيف', () {
      final rows = buildBookingSuccessRows(
        isArabic: false,
        hotelName: 'Hotel',
        status: 'confirmed',
        total: 900,
      );
      expect(
          rows.any((r) => r.$1 == AppStrings.t(false, 'payment_method_label')),
          isFalse);
    });

    test('غياب إعدادات الدفع يمنع الحجز ولا يُنتج نجاحًا كاذبًا', () {
      final availability = resolvePaymentMethods(null);
      expect(availability.hasAny, isFalse);
      expect(paymentMethodBlockReason(availability, null), isNotNull);
      // ولا تُقبل وسيلة لم تُفعّلها الإدارة من الخادم.
      expect(availability.isEnabled(PaymentMethodKey.atHotel), isFalse);
      expect(availability.isEnabled(PaymentMethodKey.ownerTransfer), isFalse);
      expect(availability.isEnabled(PaymentMethodKey.online), isFalse);
    });
  });

  group('تسميات ونصوص المجموعة 02 (عربي/إنجليزي)', () {
    const keys = [
      'approved_meal_price',
      'approved_extra_bed_price',
      'meal_price_missing',
      'extra_bed_price_missing',
      'service_settlement',
      'meal_types_label',
      'extra_bed_count',
      'extra_bed_nights',
      'extra_bed_total',
      'unit_pricing_title',
      'meal_pricing_title',
      'pricing_title_field',
      'pricing_date_field',
      'pricing_date_required',
      'unit_type_column',
      'unit_price_column',
      'meal_name_column',
      'pricing_title_required',
      'pricing_price_invalid',
      'pricing_row_required',
      'pricing_saved',
      'no_unit_types',
      'saved_pricing_records',
      'no_saved_pricing',
      'six_unit_price_rows',
      'meal_prices_three_rows',
      'booking_reference_internal',
    ];

    test('كل المفاتيح مترجمة في اللغتين', () {
      for (final key in keys) {
        expect(AppStrings.t(true, key), isNotEmpty, reason: key);
        expect(AppStrings.t(false, key), isNotEmpty, reason: key);
        expect(AppStrings.t(true, key) == key, isFalse, reason: key);
        expect(AppStrings.t(false, key) == key, isFalse, reason: key);
      }
    });
  });
}
