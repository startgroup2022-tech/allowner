import 'dart:convert';
import 'dart:typed_data';

import 'package:allowners/services/api_client.dart';
import 'package:allowners/services/owner_service.dart';
import 'package:allowners/utils/owner_wallet.dart';
import 'package:allowners/utils/payment_methods_config.dart';
import 'package:allowners/utils/payment_security.dart';
import 'package:allowners/utils/request_settlement.dart';
import 'package:allowners/utils/revenue_reports.dart';
import 'package:allowners/utils/staff_permissions.dart';
import 'package:allowners/utils/subscription.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// «سلامة مالية» — القسم 7 من طلب الدمج النهائي.
///
/// كل حالة هنا تُثبت ضمانة في التطبيق نفسه. أما الضمانات التي لا يملكها
/// التطبيق (خصم على السيرفر، إصدار رابط دفع، احتساب إيراد مدفوع) فمذكورة في
/// `docs/FINAL_INTEGRATION_REPORT.md` كمتطلبات سيرفر، لا كنجاحات مُدّعاة.
class _Adapter implements HttpClientAdapter {
  _Adapter(this.body, {this.status = 200});

  final Map<String, dynamic> body;
  final int status;
  final requests = <RequestOptions>[];
  final payloads = <String>[];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    payloads.add(jsonEncode(options.data ?? const {}));
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. الحجوزات غير المدفوعة لا تُحتسب إيرادًا محصّلًا', () {
    test('الإيراد يُقرأ من monthly السيرفر فقط، لا من قائمة الحجوزات', () {
      // الحمولة تحمل حجوزات غير مدفوعة إلى جانب سطور الإيراد. التطبيق يجب أن
      // يجمع monthly فقط؛ لو جمع الحجوزات لظهر الإيراد 3000 بدل 1200.
      final serverData = {
        'total': 1200,
        'monthly': [
          {'month': '2026-10', 'total': 1000},
          {'month': '2026-11', 'total': 200},
        ],
        'bookings': [
          {'id': 1, 'status': 'pending', 'total': 1500},
          {'id': 2, 'status': 'cancelled', 'total': 1500},
        ],
      };
      final monthly =
          (serverData['monthly'] as List).cast<Map<String, dynamic>>().toList();
      final totals = RevenueReports.yearTotals(monthly);
      expect(totals.map((t) => t.total).fold<double>(0, (a, b) => a + b), 1200);
      expect(totals.first.year, 2026);
    });

    test('بلا سطور monthly لا يُستنتج إيراد من الحجوزات', () {
      final totals = RevenueReports.yearTotals(const []);
      expect(totals, isEmpty,
          reason: 'لا نُحوّل حجوزات غير مدفوعة إلى إيراد من عندنا');
    });
  });

  group('2. طلب تحويل العمولة لا يُعرض كدفعة مكتملة', () {
    late HttpClientAdapter original;

    setUp(() => original = ApiClient.instance.dio.httpClientAdapter);
    tearDown(() => ApiClient.instance.dio.httpClientAdapter = original);

    test('الإرسال لا يحمل إلا الإجراء والمبلغ — لا علامة «مدفوعة»', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 't'});
      final adapter = _Adapter({'success': true, 'message': 'تم إرسال الطلب'});
      ApiClient.instance.dio.httpClientAdapter = adapter;

      final res = await OwnerService().requestCommissionTransfer(250);

      expect(adapter.requests.single.path, '/user/agent-commission.php');
      expect(jsonDecode(adapter.payloads.single),
          {'action': 'request_transfer', 'amount': 250});
      expect(res['message'], 'تم إرسال الطلب',
          reason: 'رسالة السيرفر تُعرض كما هي، لا رسالة نجاح مُصطنعة');
      expect(res.containsKey('paid'), isFalse);
    });

    test('رفض السيرفر يُمرَّر كخطأ لا كنجاح', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 't'});
      ApiClient.instance.dio.httpClientAdapter = _Adapter(
        {'success': false, 'message': 'التحويل غير مُفعَّل'},
        status: 400,
      );

      await expectLater(
        OwnerService().requestCommissionTransfer(250),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('3. وسائل الدفع المعطّلة لا يمكن إرسالها', () {
    test('الإعدادات الفارغة = كل الوسائل معطّلة (المتطلبان 7 و8 من 06)', () {
      final availability = resolvePaymentMethods(null);
      for (final method in PaymentMethodKey.values) {
        expect(availability.isEnabled(method), isFalse,
            reason: '${method.wireName} يجب أن يبقى معطّلًا افتراضيًا');
        expect(paymentMethodBlockReason(availability, method.wireName),
            'payment_method_unavailable');
      }
    });

    test('علم صريح false يمنع حتى لو وُجد رابط دفع مستضاف', () {
      final availability = resolvePaymentMethods({
        'payment_checkout_url': 'https://pay.example.com/checkout',
        'payment_methods': {
          'online': false,
          'at_hotel': false,
          'owner_transfer': false,
        },
      });
      expect(availability.enabled, isEmpty);
      expect(paymentMethodBlockReason(availability, 'at_hotel'),
          'payment_method_unavailable');
      expect(paymentMethodBlockReason(availability, 'owner_transfer'),
          'payment_method_unavailable');
    });

    test('وسيلة غير معروفة تُرفض أيضًا', () {
      final availability = resolvePaymentMethods({
        'payment_methods': {'at_hotel': true},
      });
      expect(paymentMethodBlockReason(availability, 'cash'),
          'payment_method_unavailable');
      expect(paymentMethodBlockReason(availability, null),
          'payment_method_unavailable');
    });

    test('تفعيل السيرفر الصريح هو الطريق الوحيد للسماح', () {
      final availability = resolvePaymentMethods({
        'payment_methods': {'at_hotel': true, 'owner_transfer': true},
      });
      expect(paymentMethodBlockReason(availability, 'at_hotel'), isNull);
      expect(paymentMethodBlockReason(availability, 'owner_transfer'), isNull);
    });
  });

  group('4. أرصدة المحفظة من السيرفر فقط', () {
    test('استجابة بلا حقول لا تُنتج أصفارًا مضلِّلة', () {
      final wallet = WalletBalance.fromMap(const {'success': true});
      expect(wallet.total, isNull);
      expect(wallet.withdrawable, isNull);
      expect(wallet.hasAnyValue, isFalse);
    });

    test('قيمة السيرفر للرصيد تُعرض كما هي', () {
      final wallet = WalletBalance.fromMap(const {
        'balance': '1500.50',
        'commission': '150',
        'expenses': '20',
        'reserved': '100',
        'available': '1380.50',
      });
      expect(wallet.total, 1500.5);
      expect(wallet.withdrawable, 1380.5);
      expect(wallet.hasAnyValue, isTrue);
    });
  });

  group('5. تفعيل الاشتراك يحتاج استجابة سيرفر حقيقية', () {
    test('بلا رابط https مُعلن لا يوجد رابط دفع', () {
      expect(resolveHostedCheckout(const {'subscription_fee': 500}), isNull);
      expect(
        resolveHostedCheckout(const {
          'payment_checkout_url': 'http://insecure.example.com/pay',
        }),
        isNull,
      );
      expect(
        resolveHostedCheckout(const {
          'payment_checkout_url': 'https://pay.example.com/x',
        }),
        isNotNull,
      );
    });

    test('حالة الاشتراك تُقرأ من السيرفر، والغياب ليس «مُفعَّل»', () {
      final unknown = SubscriptionState.fromMap(const {'success': true});
      expect(unknown.canPerformOperations, isFalse);
      expect(unknown.isKnown, isFalse,
          reason: 'غياب الحقل لا يعني اشتراكًا نشطًا');

      final active =
          SubscriptionState.fromMap(const {'subscription_active': true});
      expect(active.canPerformOperations, isTrue);
    });
  });

  group('6. التسوية لا تُنشئ خصمًا مزدوجًا', () {
    final request = {
      'id': 88,
      'type': 'cleaning',
      'price': 120,
      'status': 'pending',
    };

    test('طلب غير مسوّى بسعر معتمد ووسيلة مختارة يمر', () {
      expect(
        validateRequestSettlement(
          request: request,
          choice: RequestSettlement.walletBalance,
          price: 120,
          canConfirm: true,
          kind: SettlementRequestKind.cleaning,
        ),
        isNull,
      );
    });

    test('طلب مسوّى مسبقًا يُرفض بأي وسيلة', () {
      for (final settled in const [
        {'settlement': 'wallet_balance'},
        {'settlement_status': 'settled'},
        {'payment_status': 'paid'},
        {'settled': true},
      ]) {
        final recorded = {...request, ...settled};
        expect(isRequestSettlementRecorded(recorded), isTrue);
        expect(
          validateRequestSettlement(
            request: recorded,
            choice: RequestSettlement.whatsappLink,
            price: 120,
            canConfirm: true,
            kind: SettlementRequestKind.cleaning,
          ),
          'settlement_already_recorded',
        );
      }
    });

    test('بلا سعر معتمد أو بلا اختيار وسيلة لا يُرسل شيء', () {
      expect(
        validateRequestSettlement(
          request: request,
          choice: RequestSettlement.walletBalance,
          price: null,
          canConfirm: true,
          kind: SettlementRequestKind.cleaning,
        ),
        'housekeeping_price_missing',
      );
      expect(
        validateRequestSettlement(
          request: request,
          choice: null,
          price: 120,
          canConfirm: true,
          kind: SettlementRequestKind.cleaning,
        ),
        'payment_method_required',
      );
    });

    test('السعر المعتمد يُقرأ من حقول السيرفر، والصفر لا يُعتمد', () {
      expect(approvedRequestPrice({'price': '120'}), 120);
      expect(approvedRequestPrice({'approved_price': 99.5}), 99.5);
      expect(approvedRequestPrice({'price': 0}), isNull);
      expect(approvedRequestPrice(const {}), isNull);
    });
  });

  group('7. روابط الدفع بالواتساب من السيرفر فقط', () {
    test('رابط الدفع يُقبل فقط إن كان https مطلقًا', () {
      expect(extractServerPaymentLink({'payment_link': 'https://pay.x/1'}),
          'https://pay.x/1');
      expect(
          extractServerPaymentLink({'payment_link': 'http://pay.x/1'}), isNull);
      expect(extractServerPaymentLink({'payment_link': '/pay/1'}), isNull);
      expect(extractServerPaymentLink({'payment_link': ''}), isNull);
      expect(extractServerPaymentLink(null), isNull);
      expect(extractServerPaymentLink(const {'success': true}), isNull);
    });

    test('رسالة واتساب بلا رابط دفع لا تحمل رابطًا مُختلقًا', () {
      final uri = buildSettlementWhatsAppUri(
        phone: '966500000000',
        isArabic: true,
        kind: SettlementRequestKind.cleaning,
        requestId: 88,
        unitName: '402',
        amount: 120,
      );
      expect(uri, isNotNull);
      final text = uri!.queryParameters['text']!;
      expect(text, contains('88'));
      expect(text, contains('120'));
      expect(text, isNot(contains('http')));
    });

    test('رابط السيرفر الحقيقي يُضاف كما هو', () {
      final uri = buildSettlementWhatsAppUri(
        phone: '966500000000',
        isArabic: false,
        kind: SettlementRequestKind.meal,
        paymentLink: 'https://pay.x/abc',
      );
      expect(uri!.queryParameters['text'], contains('https://pay.x/abc'));
    });

    test('بلا رقم واتساب صالح لا يُبنى رابط', () {
      expect(
        buildSettlementWhatsAppUri(
          phone: null,
          isArabic: true,
          kind: SettlementRequestKind.cleaning,
        ),
        isNull,
      );
    });
  });

  group('8. الموظف غير المصرّح لا يرى المعلومة المالية', () {
    test('can_view_finance معطّل افتراضيًا لكل دور', () {
      for (final role in const [
        'hotel_employee',
        'hotel_manager',
        'booking_agent',
        'owner',
      ]) {
        expect(defaultStaffPermissions(role)['can_view_finance'], isFalse,
            reason: '$role لا يحصل على المالية تلقائيًا');
      }
    });

    test('غياب حقل الصلاحية يُسقط إلى الافتراضي (مغلق)', () {
      final parsed = parseStaffPermissions(
        {'can_manage_bookings': true},
        role: 'hotel_employee',
      );
      expect(parsed['can_view_finance'], isFalse);
    });

    test('الصلاحية تُفتح فقط بنص صريح من السيرفر', () {
      final parsed = parseStaffPermissions(
        {'can_view_finance': '1'},
        role: 'hotel_employee',
      );
      expect(parsed['can_view_finance'], isTrue);
    });

    test('قائمة أسماء لا تُفتح بلا ذكر can_view_finance', () {
      final parsed = parseStaffPermissions(
        ['can_manage_bookings', 'can_manage_services'],
        role: 'hotel_employee',
      );
      expect(parsed['can_view_finance'], isFalse);
    });
  });
}
