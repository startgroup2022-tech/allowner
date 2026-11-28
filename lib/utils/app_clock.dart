/// ساعة التطبيق — نقطة واحدة لقراءة الوقت الحالي.
///
/// الشاشات التي تبني تواريخ افتراضية (الحجز، التقويم) تقرأ منها بدل
/// `DateTime.now()` مباشرة، فيمكن تثبيت الزمن في اختبارات اللقطات فتصبح
/// المقارنة البصرية حتمية ولا تفشل كلما تغيّر يوم التشغيل.
library;

import 'package:flutter/foundation.dart';

class AppClock {
  AppClock._();

  static DateTime Function() _now = DateTime.now;

  static DateTime now() => _now();

  /// يثبّت الساعة على لحظة محددة. `null` يعيد الساعة الحقيقية.
  @visibleForTesting
  static void freeze(DateTime? value) {
    _now = value == null ? DateTime.now : () => value;
  }
}
