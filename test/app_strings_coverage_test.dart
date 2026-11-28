import 'dart:io';

import 'package:allowners/utils/app_strings.dart';
import 'package:flutter_test/flutter_test.dart';

/// حارس الترجمة (المتطلبات 1، 2، 12، 13 وما يتبعها من تسميات).
///
/// وجدنا في `owner_staff_screen.dart` حرفًا ظاهرًا في الواجهة العربية:
/// `AppStrings.t(isArabic, isActive ? 'active' : 'suspended')` والمفتاح
/// `active` لم يكن معرّفًا، فيُرجع `t()` المفتاح نفسه ويظهر «active» داخل
/// واجهة عربية. هذا الاختبار يمنع تكرار الصنف كله: يقرأ كل نداءات
/// `AppStrings.t(...)` ويستخرج **كل** مفتاح حرفي داخل الوسيط (بما فيها
/// الشروط الثلاثية)، ويؤكد وجود نص عربي وإنجليزي له.

const _libDir = 'lib';

/// يزيل المقاطع التي ليست مفاتيح ترجمة: استيفاءات `${...}` واشتراكات
/// الخرائط `['field']` داخل الوسيط، كي لا تُحسب أسماء حقول الـ JSON
/// (مثل `r['booking_status']`) كمفاتيح نصوص.
String _stripNonKeys(String arg) {
  var text = arg;
  // ${ ... }
  var guard = 0;
  while (text.contains(r'${') && guard++ < 200) {
    final start = text.indexOf(r'${');
    var i = start + 2;
    var depth = 1;
    while (i < text.length && depth > 0) {
      if (text[i] == '{') depth++;
      if (text[i] == '}') depth--;
      i++;
    }
    text = text.substring(0, start) + text.substring(i);
  }
  // [ ... ] اشتراكات
  text = text.replaceAll(RegExp(r"\[[^\]]*\]"), '');
  // مقارنات مثل status == 'pending' ليست مفاتيح
  text = text.replaceAll(RegExp(r"[!=]=\s*'[^']*'"), '');
  // مفاتيح ديناميكية مثل 'status_$status' تُفحص كمجموعة منفصلة (بعد إزالة
  // الاستيفاء تبقى على شكل 'status_$')
  text = text.replaceAll(RegExp(r"'[a-z0-9_]*\$[a-z0-9_]*'"), '');
  text = text.replaceAll(RegExp(r"'[a-z0-9_]*\$'"), '');
  return text;
}

/// يستخرج نص الوسيط الثاني لكل نداء `AppStrings.t(` بتوازن الأقواس.
List<String> _tCallArgs(String source) {
  final args = <String>[];
  const marker = 'AppStrings.t(';
  var index = source.indexOf(marker);
  while (index != -1) {
    var i = index + marker.length;
    var depth = 1;
    final start = i;
    while (i < source.length && depth > 0) {
      final ch = source[i];
      if (ch == '(') depth++;
      if (ch == ')') depth--;
      i++;
    }
    if (depth == 0) args.add(source.substring(start, i - 1));
    index = source.indexOf(marker, i);
  }
  return args;
}

void main() {
  test('كل مفتاح مستخدم في AppStrings.t له نص عربي وإنجليزي', () {
    final literalKeys = <String>{};
    final files = Directory(_libDir)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !f.path.endsWith('app_strings.dart'));

    for (final file in files) {
      final source = file.readAsStringSync();
      if (!source.contains('AppStrings.t(')) continue;
      for (final rawArg in _tCallArgs(source)) {
        final arg = _stripNonKeys(rawArg);
        for (final match in RegExp(r"'([a-z0-9_]+)'").allMatches(arg)) {
          final key = match.group(1)!;
          // بادئة تُدمج مع متغيّر ('status_' + value) — يغطّيها الاختبار
          // الديناميكي أدناه، ولا تُعد مفتاحًا كاملًا هنا.
          if (key.endsWith('_')) continue;
          literalKeys.add(key);
        }
      }
    }

    expect(literalKeys, isNotEmpty,
        reason: 'لم يُقرأ أي مفتاح — تحقّق من المسار');

    final missing = literalKeys.where((k) => !AppStrings.hasKey(k)).toList()
      ..sort();
    expect(missing, isEmpty,
        reason: 'مفاتيح بلا نص: ستظهر خامّة في الواجهة → $missing');

    // النصان موجودان فعلًا وليسا فارغين
    final emptyTranslations = <String>[];
    for (final key in literalKeys) {
      final ar = AppStrings.t(true, key);
      final en = AppStrings.t(false, key);
      // المفتاح قد يكون كلمة إنجليزية مقصودة (night/nights/guests)، لكن
      // ظهوره في الواجهة العربية يعني نصًا ناقصًا.
      if (ar.trim().isEmpty || en.trim().isEmpty || ar == key) {
        emptyTranslations.add(key);
      }
    }
    emptyTranslations.sort();
    expect(emptyTranslations, isEmpty,
        reason: 'ترجمة ناقصة أو راجعة للمفتاح → $emptyTranslations');
  });

  test('مفاتيح الحالة الديناميكية status_* و req_type_* مغطّاة', () {
    // الشاشات تبني المفتاح ديناميكيًا: AppStrings.t(isArabic, 'status_$s')
    final dynamicPrefixes = <String, List<String>>{
      'status_': ['checked_in', 'checked_out', 'cancelled', 'pending'],
      'req_type_': ['cleaning', 'maintenance', 'meal', 'extra_bed'],
    };
    final missing = <String>[];
    dynamicPrefixes.forEach((prefix, suffixes) {
      for (final suffix in suffixes) {
        if (!AppStrings.hasKey('$prefix$suffix')) missing.add('$prefix$suffix');
      }
    });
    expect(missing, isEmpty, reason: 'مفاتيح ديناميكية بلا نص → $missing');
  });

  test('تسميات الحالة النشطة والموقوفة عربية', () {
    expect(AppStrings.t(true, 'active'), 'نشط');
    expect(AppStrings.t(true, 'suspended'), 'موقوف');
    expect(AppStrings.t(false, 'active'), 'Active');
    expect(AppStrings.t(false, 'suspended'), 'Suspended');
  });

  test('نصوص صلاحيات الموظف موجودة بالعربية والإنجليزية', () {
    for (final key in [
      'staff_permissions',
      'staff_permissions_saved',
      'staff_permissions_unchanged',
      'staff_finance_needs_subscription',
    ]) {
      expect(AppStrings.hasKey(key), isTrue, reason: 'ناقص: $key');
      expect(AppStrings.t(true, key), isNot(key));
      expect(AppStrings.t(false, key), isNot(key));
    }
  });

  test('نصوص تحويل العمولات موجودة بالعربية والإنجليزية', () {
    for (final key in [
      'commission_unpaid_amount',
      'commission_transfer_hint',
      'request_transfer',
      'transfer_requested',
      'transfer_requires_server',
    ]) {
      expect(AppStrings.hasKey(key), isTrue, reason: 'ناقص: $key');
      expect(AppStrings.t(true, key), isNot(key));
      expect(AppStrings.t(false, key), isNot(key));
    }
  });
}
