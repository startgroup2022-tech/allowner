import 'package:allowners/utils/subscription.dart';
import 'package:flutter_test/flutter_test.dart';

/// اختبارات المتطلب 123: منع إضافة الوحدات **والطلبات** حتى يُفعَّل الاشتراك.
///
/// البوابة المشتركة (`ensureSubscriptionForOperation`) تعتمد كليًا على
/// `SubscriptionState`، فنختبر هنا القرار النقي الذي تتخذه في الحالات الثلاث.
/// لا نحتاج واجهة: السلوك المهم هو **هل تُحجب العملية أم لا**.
void main() {
  group('قرار البوابة حسب حالة الاشتراك', () {
    test('مؤكَّد أنه غير مُفعَّل → تُحجب العملية', () {
      final state = SubscriptionState.fromMap({'subscription_active': false});
      expect(state.isExplicitlyInactive, isTrue);
      expect(state.canPerformOperations, isFalse);
      expect(state.isBrowseOnly, isTrue);
    });

    test('مؤكَّد أنه مُفعَّل → تمرّ العملية', () {
      final state = SubscriptionState.fromMap({'subscription_active': true});
      expect(state.isExplicitlyInactive, isFalse);
      expect(state.canPerformOperations, isTrue);
      expect(state.isBrowseOnly, isFalse);
    });

    test('غير معلن → تمرّ العملية ولا يُكسر تدفّق عامل', () {
      final state = SubscriptionState.fromMap(const {});
      expect(state.isKnown, isFalse);
      expect(state.isExplicitlyInactive, isFalse);
      // الاحتياط: بلا تأكيد من السيرفر نعرض وضع الاستعراض، لكن لا نحجب محليًا
      // حتى لا نعطّل مالكًا مشتركًا بسبب إعداد ناقص.
      expect(state.isBrowseOnly, isTrue);
    });

    test('خريطة null تُعامل كغير معلنة', () {
      final state = SubscriptionState.fromMap(null);
      expect(state.isKnown, isFalse);
      expect(state.isExplicitlyInactive, isFalse);
    });

    test('القيم النصية تُقرأ باصطلاح المشروع (yes/true/1 = مُفعَّل)', () {
      // `asBool` في المشروع يقبل 'yes'/'true'/'1' صراحةً؛ نتثبّت من ذلك هنا
      // حتى لا يتحوّل الاصطلاح إلى سلوك غير مقصود.
      expect(
          SubscriptionState.fromMap({'subscription_active': 'yes'})
              .canPerformOperations,
          isTrue);
      expect(
          SubscriptionState.fromMap({'subscription_active': '1'})
              .canPerformOperations,
          isTrue);
      expect(
          SubscriptionState.fromMap({'subscription_active': 'no'})
              .isExplicitlyInactive,
          isTrue);
    });

    test('قيمة غير معروفة الشكل لا تُقرأ كتفعيل', () {
      final state = SubscriptionState.fromMap({'subscription_active': 'maybe'});
      // 'maybe' ليست من القيم المعروفة، فـ asBool تعيد false → تُحجب العملية.
      expect(state.isExplicitlyInactive, isTrue);
    });
  });
}
