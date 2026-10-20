/// بناء جسم طلب إنشاء الحجز (`POST /bookings/create.php`).
///
/// دالة نقية حتى يمكن إثبات ما يُرسل فعلًا للسيرفر (المتطلبات 144–148): بريد
/// التأكيد المتبادل بين الفندق والمالك والعميل يعتمد على أن هذه الحقول تصل:
/// اسم الضيف (145)، رقم الهوية/الجواز (146)، تاريخ الدخول (147)، والوحدة التي
/// يشتق منها السيرفر نوع الوحدة ورقم الغرفة (148).
///
/// القواعد:
/// - لا نرسل حقلًا فارغًا بلا معنى (مثل `addon_ids: []`)، لكن `guest_id_number`
///   يُرسل دائمًا كنص فارغ كما كان، لأن السيرفر يعتمد على وجود المفتاح.
/// - التواريخ بصيغة `YYYY-MM-DD` فقط (بلا وقت)، وهو ما يتوقعه السيرفر.
/// - لا نخترع أي قيمة: كل حقل يأتي من مُدخل حقيقي أو يُحذف.
library;

String formatBookingDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

Map<String, dynamic> buildBookingPayload({
  required int hotelId,
  int? unitId,
  required DateTime checkIn,
  required DateTime checkOut,
  required int guests,
  required String paymentMethod,
  String? cardNumber,
  List<String> mealTypes = const [],
  bool extraBed = false,
  List<int>? addonIds,
  String? guestIdNumber,
  String? customerName,
  String? customerPhone,
}) {
  return {
    'hotel_id': hotelId,
    if (unitId != null) 'unit_id': unitId,
    'check_in': formatBookingDate(checkIn),
    'check_out': formatBookingDate(checkOut),
    'guests': guests,
    'payment_method': paymentMethod,
    'meal_types': mealTypes,
    'extra_bed': extraBed,
    if (addonIds != null && addonIds.isNotEmpty) 'addon_ids': addonIds,
    if (cardNumber != null) 'card_number': cardNumber,
    'guest_id_number': guestIdNumber ?? '',
    if (customerName != null && customerName.trim().isNotEmpty)
      'customer_name': customerName.trim(),
    if (customerPhone != null && customerPhone.trim().isNotEmpty)
      'customer_phone': customerPhone.trim(),
  };
}
