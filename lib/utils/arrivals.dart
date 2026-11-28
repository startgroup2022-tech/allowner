/// وصول الفندق وبحثه برقم الغرفة/الوحدة (المتطلبان 80 و81، والمستند 06 §F).
library;

import 'unit_search.dart';

String _isoDate(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// هل السجل وصول اليوم؟
///
/// نعتمد أولًا على `can_check_in` الذي يحدده السيرفر، وإلا على تاريخ الوصول
/// (`check_in`) المطابق ليوم اليوم. لا نستنتج وصولًا بلا بيانات حقيقية، ولا
/// نُدرج حجزًا مُسجَّل الدخول بالفعل (له `checked_in_at` أو حالة in_house).
bool isArrivalRecord(Map<String, dynamic> booking, DateTime today) {
  final status = (booking['status'] ?? '').toString().toLowerCase();
  if (status == 'checked_in' || status == 'in_house') return false;
  if (booking['can_check_in'] == true) return true;
  final checkIn = (booking['check_in'] ?? '').toString().trim();
  return checkIn.isNotEmpty && checkIn.startsWith(_isoDate(today));
}

/// يرشّح وصولات اليوم ثم يبحث فيها برقم الوحدة.
///
/// القائمة تأتي من `/hotel/bookings.php?scope=active` وهي مقيّدة على السيرفر
/// بفندق الموظف المصرّح له، فلا يمكنه رؤية وصولات فندق آخر.
List<Map<String, dynamic>> filterArrivalsByUnit({
  required List<Map<String, dynamic>> bookings,
  required String query,
  DateTime? today,
}) {
  final day = today ?? DateTime.now();
  final arrivals = bookings.where((b) => isArrivalRecord(b, day)).toList();
  return filterUnitsByUnitNumber(
    units: arrivals,
    query: query,
    unitNumberOf: departureUnitNumber,
  );
}
