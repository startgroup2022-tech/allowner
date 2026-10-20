/// تجميع تقارير إيرادات المالك (المتطلبات 126–129).
///
/// كل الدوال هنا نقية وتعمل على بيانات الـ API الحقيقية القادمة من
/// `user/owner-revenue.php` — لا تُختلق أرقام. التجميع السنوي يُحسب من سطور
/// `monthly` (كل سطر فيه `ym` بصيغة YYYY-MM و`total`)، أما مصروفات الصيانة
/// والنظافة فتُقرأ فقط إن أعادها الـ API بأسمائها المعروفة؛ إن لم تُرجَع
/// نُبلّغ بغيابها بدل عرض صفر مضلّل.
library;

class YearTotal {
  final int year;
  final double total;

  const YearTotal({required this.year, required this.total});
}

class ExpenseTotal {
  final String labelKey;
  final double total;

  const ExpenseTotal({required this.labelKey, required this.total});
}

class RevenueReports {
  RevenueReports._();

  /// مفاتيح المصروفات المحتملة في استجابة الـ API، مرتّبة بحسب الأولوية.
  static const Map<String, List<String>> expenseKeys = {
    'maintenance_expense': [
      'maintenance_expense',
      'maintenance_cost',
      'maintenance_total'
    ],
    'cleaning_expense': ['cleaning_expense', 'cleaning_cost', 'cleaning_total'],
    'commission': ['commission', 'commission_total'],
  };

  /// يجمع إجمالي كل سنة من سطور `monthly`. السطور التي تاريخها غير صالح
  /// تُتجاهل بدل أن تُحتسب في سنة خاطئة. النتيجة مرتّبة من الأحدث للأقدم.
  static List<YearTotal> yearTotals(List<Map<String, dynamic>> monthly) {
    final sums = <int, double>{};
    for (final row in monthly) {
      final year = yearOf(row['ym']?.toString());
      if (year == null) continue;
      sums[year] = (sums[year] ?? 0) + _toDouble(row['total']);
    }
    final years = sums.keys.toList()..sort((a, b) => b.compareTo(a));
    return [for (final y in years) YearTotal(year: y, total: sums[y]!)];
  }

  /// يستخرج السنة من `ym` بصيغة `YYYY-MM` أو `YYYY`. يرجع null إن كانت غير صالحة.
  static int? yearOf(String? ym) {
    if (ym == null) return null;
    final part = ym.split('-').first.trim();
    if (part.length != 4) return null;
    final year = int.tryParse(part);
    if (year == null || year < 1900 || year > 2999) return null;
    return year;
  }

  /// مصروفات الصيانة/النظافة/العمولة إن أعادها الـ API فعلًا. الحقول الغائبة
  /// لا تظهر في النتيجة — لا نعرض صفرًا لمصروف لم تُرجعه الخدمة.
  static List<ExpenseTotal> expenses(Map<String, dynamic> data) {
    final out = <ExpenseTotal>[];
    expenseKeys.forEach((labelKey, candidates) {
      for (final key in candidates) {
        if (data.containsKey(key) && data[key] != null) {
          out.add(
              ExpenseTotal(labelKey: labelKey, total: _toDouble(data[key])));
          return;
        }
      }
    });
    return out;
  }

  /// صافي الإيراد = الإجمالي − مجموع المصروفات المُرجَعة. إن لم يُرجَع أي
  /// مصروف نرجع الإجمالي كما هو (لا نخصم أرقامًا غير موجودة).
  static double netRevenue(double gross, List<ExpenseTotal> expenses) {
    var net = gross;
    for (final e in expenses) {
      net -= e.total;
    }
    return net;
  }

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim()) ?? 0;
    return 0;
  }
}
