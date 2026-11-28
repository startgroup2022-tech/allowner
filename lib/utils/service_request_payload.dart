/// بناء أجسام طلبات الخدمات المرسلة للسيرفر.
///
/// دالة نقية لكل مسار حتى يمكن إثبات ما يُرسل فعلًا (المتطلبات 49، 53، 57، 58،
/// 62، 65، 66، 67): طلب الوجبات المستقل بعدة وجبات، طلب النظافة/الصيانة من
/// الضيف، وطلب المالك للفندق (نظافة/وجبات/سرير إضافي).
///
/// القواعد: لا يُرسل حقل بلا قيمة حقيقية، والنصوص تُشذَّب، والأنواع تبقى كما
/// يتوقعها السيرفر (مصفوفة وجبات، أرقام صحيحة للمعرّفات).
library;

/// طلب وجبات مستقل من الضيف (`POST /services/meal-request.php`).
Map<String, dynamic> buildMealRequestPayload({
  required int bookingId,
  required String roomNumber,
  required List<String> mealTypes,
  String? notes,
}) {
  return {
    'booking_id': bookingId,
    'room_number': roomNumber.trim(),
    'meal_types': mealTypes,
    if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
  };
}

/// طلب خدمة من الضيف (`POST /services/request.php`) — نظافة أو صيانة أو إلغاء.
Map<String, dynamic> buildServiceRequestPayload({
  int? bookingId,
  required String roomNumber,
  required String serviceType,
  String? description,
}) {
  return {
    if (bookingId != null) 'booking_id': bookingId,
    'room_number': roomNumber.trim(),
    'service_type': serviceType,
    if (description != null && description.trim().isNotEmpty)
      'description': description.trim(),
  };
}

/// طلب المالك إلى إدارة الفندق (`POST /user/owner-requests.php`).
///
/// [type] واحد من: cleaning | maintenance | meal | extra_bed — نفس الأنواع التي
/// تعرضها شاشة طلبات الفندق (`hotel/requests.php`).
Map<String, dynamic> buildOwnerRequestPayload({
  required String type,
  required int hotelId,
  required int unitId,
  String? description,
}) {
  return {
    'type': type,
    'hotel_id': hotelId,
    'unit_id': unitId,
    if (description != null && description.trim().isNotEmpty)
      'description': description.trim(),
  };
}

/// وصف طلب الوجبات المُرسل من المالك: الوجبات المختارة ثم الملاحظة.
///
/// يُبنى بهذا الشكل لأن مسار المالك يقبل نصًا واحدًا (`description`) لا مصفوفة
/// وجبات، وهذه هي الصيغة التي يقرأها موظف الفندق في قائمة الطلبات.
String buildOwnerMealDescription({
  required List<String> mealTypes,
  String? notes,
}) {
  final meals = mealTypes.where((m) => m.trim().isNotEmpty).toList();
  return [
    if (meals.isNotEmpty) 'meals: ${meals.join(',')}',
    if (notes != null && notes.trim().isNotEmpty) notes.trim(),
  ].join(' — ');
}
