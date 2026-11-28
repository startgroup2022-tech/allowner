/// بوابة الاشتراك للعمليات (المتطلب 123: منع إضافة الوحدات **والطلبات** حتى
/// يُفعَّل الاشتراك).
///
/// استُخرجت من `owner_units_screen.dart` لتُطبَّق على شاشات الطلبات الأربع
/// (الصيانة، النظافة، الوجبات، السرير الإضافي) بنفس السلوك تمامًا، بدل تكرار
/// المنطق. الحاجز غير مُدمِّر: يمنع العملية فقط عندما **يؤكّد** السيرفر أن
/// الاشتراك غير مُفعَّل، ويمرّر حالة «غير معلنة» حتى لا يكسر تدفّقًا عاملًا
/// يفرضه السيرفر عبر قيوده الخاصة.
library;

import 'package:flutter/material.dart';

import '../screens/owner/owner_subscription_screen.dart';
import '../services/api_client.dart';
import '../services/owner_service.dart';
import 'app_strings.dart';
import 'subscription.dart';

/// يتحقّق من إمكانية تنفيذ عملية كتابة (إضافة وحدة/طلب).
///
/// يعيد `true` إذا سُمح بالمتابعة، و`false` إذا حُجبت العملية وعُرض للمستخدم
/// سبب واضح مع طريق مباشر إلى صفحة الاشتراك.
Future<bool> ensureSubscriptionForOperation({
  required BuildContext context,
  required OwnerService service,
  required bool isArabic,
}) async {
  try {
    final settings = await service.getSubscription();
    final state = SubscriptionState.fromMap(settings);
    if (state.isExplicitlyInactive) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(AppStrings.t(isArabic, 'subscription_required_to_operate')),
          action: SnackBarAction(
            label: AppStrings.t(isArabic, 'subscription_title'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const OwnerSubscriptionScreen()),
            ),
          ),
        ));
      }
      return false;
    }
  } on ApiException {
    // تعذّر التحقق من حالة الاشتراك — نُكمل ولا نُعطّل العملية بسبب الشبكة.
  }
  return true;
}
