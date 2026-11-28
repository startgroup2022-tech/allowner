/// مغادرات الفندق وبحثها برقم الغرفة/الوحدة (المتطلب 9 من المستند 06).
library;

import 'unit_search.dart';

String _isoDate(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// هل السجل مغادرة اليوم؟
///
/// نعتمد على `can_check_out` الذي يحدده السيرفر، وإلا على تاريخ المغادرة
/// (`check_out`) المطابق ليوم اليوم. لا نستنتج مغادرة بلا بيانات حقيقية.
bool isDepartureRecord(Map<String, dynamic> booking, DateTime today) {
  if (booking['can_check_out'] == true) return true;
  final checkOut = (booking['check_out'] ?? '').toString().trim();
  return checkOut.isNotEmpty && checkOut.startsWith(_isoDate(today));
}

/// يرشّح مغادرات اليوم ثم يبحث فيها برقم الغرفة/الوحدة.
///
/// القائمة تأتي من `/hotel/bookings.php?scope=active` وهي مقيّدة أصلًا بفندق
/// الموظف المصرّح له على السيرفر، فلا يمكن له رؤية مغادرات فندق آخر.
List<Map<String, dynamic>> filterDeparturesByUnit({
  required List<Map<String, dynamic>> bookings,
  required String query,
  DateTime? today,
}) {
  final day = today ?? DateTime.now();
  final departures = bookings.where((b) => isDepartureRecord(b, day)).toList();
  return filterUnitsByUnitNumber(
    units: departures,
    query: query,
    unitNumberOf: departureUnitNumber,
  );
}
