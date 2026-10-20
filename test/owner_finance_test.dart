import 'package:allowners/utils/owner_wallet.dart';
import 'package:allowners/utils/payouts.dart';
import 'package:allowners/utils/subscription.dart';
import 'package:flutter_test/flutter_test.dart';

/// اختبارات المتطلبات 121–143: الاشتراك السنوي، المحفظة، العمولة والتسوية.
///
/// كل الدوال المُختبَرة نقية، فلا تحتاج سيرفرًا. القاعدة المُختبَرة هي الأهم:
/// **لا يُعرض رقم مُخترع ولا تُفعَّل عملية بلا تأكيد السيرفر**.
void main() {
  group('SubscriptionState (المتطلبات 121–125)', () {
    test('غياب الحقل = حالة غير معروفة، لا "مُفعَّل" ولا "غير مُفعَّل"', () {
      final state = SubscriptionState.fromMap({'other': 'x'});
      expect(state.active, isNull);
      expect(state.isKnown, isFalse);
      expect(subscriptionStatusKey(state), 'subscription_unknown');
    });

    test('قراءة الحالة من أشكال true/1/"1"', () {
      expect(SubscriptionState.fromMap({'subscription_active': true}).active,
          isTrue);
      expect(
          SubscriptionState.fromMap({'subscription_active': 1}).active, isTrue);
      expect(SubscriptionState.fromMap({'subscription_active': '1'}).active,
          isTrue);
      expect(SubscriptionState.fromMap({'subscription_active': 0}).active,
          isFalse);
      expect(SubscriptionState.fromMap({'subscription_active': '0'}).active,
          isFalse);
    });

    test('المتطلب 123: الحجب فقط عند تأكيد السيرفر أن الاشتراك غير مُفعَّل',
        () {
      final inactive =
          SubscriptionState.fromMap({'subscription_active': false});
      final unknown = SubscriptionState.fromMap(const {});
      final active = SubscriptionState.fromMap({'subscription_active': true});

      expect(inactive.isExplicitlyInactive, isTrue);
      // «غير معروفة» لا تُحجب — حتى لا نكسر تدفّق الإضافة العامل
      expect(unknown.isExplicitlyInactive, isFalse);
      expect(active.isExplicitlyInactive, isFalse);
    });

    test('المتطلب 122: وضع الاستعراض فقط عندما لا يكون مُفعَّلًا', () {
      expect(
          SubscriptionState.fromMap({'subscription_active': true}).isBrowseOnly,
          isFalse);
      expect(
          SubscriptionState.fromMap({'subscription_active': false})
              .isBrowseOnly,
          isTrue);
      expect(SubscriptionState.fromMap(const {}).isBrowseOnly, isTrue);
    });

    test('المتطلب 125: نسبة العمولة تُقرأ، وتُترك null إن لم تُعلَن', () {
      final withRate = SubscriptionState.fromMap({
        'commission_percent': '10',
        'subscription_annual_fee': 500,
        'currency': 'SAR',
      });
      expect(withRate.commissionPercent, 10);
      expect(withRate.annualFee, 500);
      expect(withRate.currency, 'SAR');

      final without = SubscriptionState.fromMap(const {});
      expect(without.commissionPercent, isNull);
      expect(without.annualFee, isNull);
    });

    test('لا يُبنى زر دفع بلا رسم معلن', () {
      expect(canPaySubscription(SubscriptionState.fromMap(const {})), isFalse);
      expect(
          canPaySubscription(
              SubscriptionState.fromMap({'subscription_annual_fee': 0})),
          isFalse);
      expect(
          canPaySubscription(
              SubscriptionState.fromMap({'subscription_annual_fee': 300})),
          isTrue);
    });

    test('رسالة المنع تُرجع null عندما يُسمح بالعملية', () {
      expect(
          subscriptionBlockMessageKey(
              SubscriptionState.fromMap({'subscription_active': true})),
          isNull);
      expect(
          subscriptionBlockMessageKey(
              SubscriptionState.fromMap({'subscription_active': false})),
          'subscription_required_to_operate');
    });
  });

  group('WalletBalance (المتطلبات 132–138)', () {
    test('غياب كل الحقول = لا قيمة معروضة (لا أصفار مضلِّلة)', () {
      final w = WalletBalance.fromMap(const {});
      expect(w.hasAnyValue, isFalse);
      expect(w.computedWithdrawable, isNull);
      expect(w.canRequestTransfer, isFalse);
    });

    test('قراءة الأرقام من أشكال num وString (أعمدة DECIMAL)', () {
      final w = WalletBalance.fromMap({
        'balance': '1500.50',
        'commission': 150,
        'expenses': '100',
        'reserved': 200,
      });
      expect(w.total, 1500.50);
      expect(w.commission, 150);
      expect(w.expenses, 100);
      expect(w.reserved, 200);
    });

    test('القابل للتحويل يُحسب من الرصيد − المحجوز − المصروفات', () {
      final w = WalletBalance.fromMap({
        'balance': 1000,
        'reserved': 200,
        'expenses': 100,
      });
      expect(w.computedWithdrawable, 700);
    });

    test('قيمة السيرفر للقابل للتحويل تُقدَّم على الحساب المحلي', () {
      final w = WalletBalance.fromMap({'balance': 1000, 'withdrawable': 333});
      expect(w.computedWithdrawable, 333);
    });

    test('لا يُعرض رصيد سالب — يُقيَّد عند صفر', () {
      final w = WalletBalance.fromMap({'balance': 100, 'expenses': 500});
      expect(w.computedWithdrawable, 0);
      expect(w.canRequestTransfer, isFalse);

      final negative = WalletBalance.fromMap({'withdrawable': -50});
      expect(negative.computedWithdrawable, 0);
    });

    test('canRequestTransfer صحيح فقط عند وجود مبلغ موجب', () {
      expect(WalletBalance.fromMap({'balance': 0}).canRequestTransfer, isFalse);
      expect(WalletBalance.fromMap({'balance': 1}).canRequestTransfer, isTrue);
    });
  });

  group('WalletLedgerEntry (المتطلبات 134–136)', () {
    test('ترجمة أنواع الحركات المعروفة', () {
      expect(
          WalletLedgerEntry.fromMap({'type': 'booking', 'amount': 500}).typeKey,
          'ledger_booking');
      expect(
          WalletLedgerEntry.fromMap({'type': 'COMMISSION', 'amount': 50})
              .typeKey,
          'ledger_commission');
      expect(WalletLedgerEntry.fromMap({'type': 'refund'}).typeKey,
          'ledger_refund');
      expect(WalletLedgerEntry.fromMap({'type': 'settlement'}).typeKey,
          'ledger_settlement');
      expect(WalletLedgerEntry.fromMap({'type': 'payout'}).typeKey,
          'ledger_payout');
    });

    test('النوع المجهول يُصنَّف other بدل إسقاط السطر', () {
      expect(
          WalletLedgerEntry.fromMap({'type': 'weird'}).typeKey, 'ledger_other');
      expect(WalletLedgerEntry.fromMap(const {}).typeKey, 'ledger_other');
    });

    test('المبلغ يُقرأ من نص أو رقم', () {
      expect(WalletLedgerEntry.fromMap({'amount': '120.75'}).amount, 120.75);
      expect(WalletLedgerEntry.fromMap(const {}).amount, 0);
    });
  });

  group('طلب تحويل المستحقات (المتطلبات 138–139)', () {
    test('الحمولة تحتوي الإجراء والمبلغ فقط عند غياب الآيبان', () {
      final p = buildTransferRequestPayload(amount: 500);
      expect(p['action'], 'request_transfer');
      expect(p['amount'], 500);
      expect(p.containsKey('iban'), isFalse);
      expect(p.containsKey('note'), isFalse);
    });

    test('الحقول الفارغة تُحذف ولا تُرسل كنصوص فارغة', () {
      final p = buildTransferRequestPayload(amount: 500, iban: '  ', note: '');
      expect(p.containsKey('iban'), isFalse);
      expect(p.containsKey('note'), isFalse);
    });

    test('الحقول الصحيحة تُرسل كما هي', () {
      final p = buildTransferRequestPayload(
          amount: 500, iban: 'SA000000000000', note: 'أول دفعة');
      expect(p['iban'], 'SA000000000000');
      expect(p['note'], 'أول دفعة');
    });

    test('التحقق من المبلغ يرفض الصفر والسالب وتجاوز القابل للتحويل', () {
      final balance = WalletBalance.fromMap({'balance': 1000});
      expect(isValidTransferAmount(500, balance), isTrue);
      expect(isValidTransferAmount(1000, balance), isTrue);
      expect(isValidTransferAmount(0, balance), isFalse);
      expect(isValidTransferAmount(-1, balance), isFalse);
      expect(isValidTransferAmount(1001, balance), isFalse);
      expect(isValidTransferAmount(null, balance), isFalse);
    });

    test('لا تحويل عندما يكون القابل للتحويل غير معروف', () {
      final unknown = WalletBalance.fromMap(const {});
      expect(isValidTransferAmount(100, unknown), isFalse);
    });
  });

  group('العمولة والتسوية (المتطلبات 139–142)', () {
    test('المتطلب 139: عمولة 10% افتراضيًا', () {
      final b = computeCommission(1000);
      expect(b.percent, 10);
      expect(b.commission, 100);
      expect(b.ownerNet, 900);
    });

    test('النسبة المخصّصة تُطبَّق', () {
      final b = computeCommission(2000, percent: 15);
      expect(b.commission, 300);
      expect(b.ownerNet, 1700);
    });

    test('النسبة تُقيَّد بين 0 و100، والمبلغ السالب يُعامل كصفر', () {
      expect(computeCommission(1000, percent: -5).commission, 0);
      expect(computeCommission(1000, percent: 150).commission, 1000);
      expect(computeCommission(-500).commission, 0);
      expect(computeCommission(-500).ownerNet, 0);
    });

    test('المتطلب 141: التسوية بعد انتهاء الإقامة', () {
      final today = DateTime(2026, 10, 19);
      expect(isStayCompleted('2026-10-18', today: today), isTrue);
      expect(isStayCompleted('2026-10-19', today: today), isTrue);
      expect(isStayCompleted('2026-10-20', today: today), isFalse);
      // تاريخ غير صالح لا يُعتبر إقامة منتهية
      expect(isStayCompleted(null, today: today), isFalse);
      expect(isStayCompleted('', today: today), isFalse);
      expect(isStayCompleted('ليس تاريخًا', today: today), isFalse);
    });

    test('parseIsoDate يرفض التواريخ المستحيلة', () {
      expect(parseIsoDate('2026-10-19'), DateTime(2026, 10, 19));
      expect(parseIsoDate('2026-10-19 14:30:00'), DateTime(2026, 10, 19));
      expect(parseIsoDate('2026-10-19T14:30:00Z'), DateTime(2026, 10, 19));
      expect(parseIsoDate('2026-02-31'), isNull);
      expect(parseIsoDate('2026-13-01'), isNull);
      expect(parseIsoDate('19/10/2026'), isNull);
    });

    test('المتطلب 142: لا يُخترع يوم دفع أسبوعي', () {
      final sunday = DateTime(2026, 10, 18); // الأحد = 7
      // بلا تحديد يوم: مسموح دائمًا
      expect(isPayoutDay(today: sunday), isTrue);
      // مع تحديد يوم الأحد: يطابق
      expect(isPayoutDay(payoutWeekday: 7, today: sunday), isTrue);
      expect(isPayoutDay(payoutWeekday: 1, today: sunday), isFalse);
      // يوم غير صالح = بلا قيد
      expect(isPayoutDay(payoutWeekday: 99, today: sunday), isTrue);
    });

    test('المتطلب 140: عرض السعر النهائي بأرقام صحيحة', () {
      expect(formatFinalPrice(1500), '1500 ريال');
      expect(formatFinalPrice(1500.7), '1501 ريال');
      expect(formatFinalPrice(0), '0 ريال');
      expect(formatFinalPrice(1500, isArabic: false), '1500 SAR');
    });
  });

  group('المتطلب 124: دفع الاشتراك من صفحة مستضافة', () {
    test('بلا رابط مُعلن = null، فلا يُفعَّل الزر', () {
      expect(resolveSubscriptionCheckout(const {}), isNull);
      expect(resolveSubscriptionCheckout(null), isNull);
      expect(resolveSubscriptionCheckout({'subscription_checkout_url': '  '}),
          isNull);
    });

    test('يرفض الروابط غير الآمنة (http أو نسبية)', () {
      expect(
          resolveSubscriptionCheckout(
              {'subscription_checkout_url': 'http://pay.example.com'}),
          isNull,
          reason: 'الدفع يجب أن يكون عبر https');
      expect(
          resolveSubscriptionCheckout(
              {'subscription_checkout_url': '/checkout/subscription'}),
          isNull,
          reason: 'الرابط يجب أن يكون مطلقًا');
    });

    test('يقبل رابطًا مطلقًا https ويقرأ اسم المزوّد', () {
      final cfg = resolveSubscriptionCheckout({
        'subscription_checkout_url': 'https://pay.example.com/sub',
        'subscription_payment_provider': 'Moyasar',
      });
      expect(cfg, isNotNull);
      expect(cfg!.provider, 'Moyasar');
      expect(cfg.isUsable, isTrue);
    });

    test('يرجع إلى رابط الدفع المشترك إن لم يُعلن رابط الاشتراك', () {
      final cfg = resolveSubscriptionCheckout(
          {'payment_checkout_url': 'https://pay.example.com/any'});
      expect(cfg, isNotNull);
      expect(cfg!.checkoutUrl, 'https://pay.example.com/any');
    });

    test('رابط الاشتراك المخصّص يتقدّم على المشترك', () {
      final cfg = resolveSubscriptionCheckout({
        'subscription_checkout_url': 'https://pay.example.com/sub',
        'payment_checkout_url': 'https://pay.example.com/any',
      });
      expect(cfg!.checkoutUrl, 'https://pay.example.com/sub');
    });

    test('الزر لا يعمل إلا بالرسم والرابط معًا', () {
      const url = 'https://pay.example.com/sub';
      final feeKnown =
          SubscriptionState.fromMap({'subscription_annual_fee': 500});
      final feeUnknown = SubscriptionState.fromMap(const {});
      final checkout = resolveSubscriptionCheckout({
        'subscription_checkout_url': url,
      });

      expect(canPaySubscription(feeKnown) && checkout != null, isTrue);
      expect(canPaySubscription(feeUnknown) && checkout != null, isFalse,
          reason: 'لا رسم معلن = لا زر يعمل');
      expect(canPaySubscription(feeKnown) && null != null, isFalse,
          reason: 'لا رابط معلن = لا زر يعمل');
    });

    test('بناء الرابط يمرّر معرّف المالك والغرض فقط، بلا مبلغ', () {
      final cfg = resolveSubscriptionCheckout(
          {'subscription_checkout_url': 'https://pay.example.com/sub?x=1'});
      final uri = buildSubscriptionCheckoutUri(cfg!, ownerId: 42);
      expect(uri.queryParameters['owner_id'], '42');
      expect(uri.queryParameters['purpose'], 'subscription');
      expect(uri.queryParameters['x'], '1', reason: 'المعاملات الأصلية تُحفظ');
      expect(uri.queryParameters.containsKey('amount'), isFalse,
          reason: 'المبلغ من العميل قابل للتلاعب، فلا يُمرَّر');
    });
  });
}
