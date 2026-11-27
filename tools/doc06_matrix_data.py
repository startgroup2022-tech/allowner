# -*- coding: utf-8 -*-
"""بيانات مصفوفة المستند 06 — مصدر وحيد لملف `docs/MATRIX_DOCUMENT_06.md`.

كل صف: (المعرّف، العنوان العربي، النص الإنجليزي، المجموعة، الحالة،
        ملفات Flutter، اختبارات، لقطات، اعتماد السيرفر، ملاحظة الصدق)

الحالة تُكتب من الحالات الثلاث المعتمدة فقط:
  COMPLETE AND VERIFIED / FLUTTER COMPLETE — BACKEND PENDING / INCOMPLETE
"""

COMPLETE = 'COMPLETE AND VERIFIED'
FLUTTER = 'FLUTTER COMPLETE — BACKEND PENDING'

ENTRIES = [
    (
        '1',
        '«ضيافاتي» بدل «حجوزاتي» للضيف',
        '“My Stays” instead of “My Bookings” for the guest',
        'Group 01',
        COMPLETE,
        'lib/utils/app_strings.dart (my_bookings → ضيافاتي / My Stays), '
        'lib/screens/bookings/my_bookings_screen.dart, lib/screens/home/main_navigation_screen.dart',
        'test/document06_group01_test.dart — «المتطلب 1» (نصوص + بقاء مصطلح المالك والوكيل)',
        'customer/arabic/DOC06-REQ-006-my-bookings-ar.png, '
        'customer/english/DOC06-REQ-006-my-bookings-en.png',
        '—',
        'تسمية المالك والوكيل «حجوزاتي» لم تتغير (اختبار صريح).',
    ),
    (
        '2',
        'البحث برقم الوحدة داخل تفاصيل الفندق',
        'Search available units by unit number inside hotel details',
        'Group 01',
        COMPLETE,
        'lib/utils/unit_search.dart, '
        'lib/screens/hotel/hotel_details_screen.dart',
        'test/document06_group01_test.dart — «المتطلب 2» (5 اختبارات: فارغ، جزئي/كامل، '
        'أرقام عربية-هندية، لا نتائج، نصوص)',
        'customer/arabic/DOC06-REQ-002-hotel-unit-search-ar.png, '
        'customer/english/DOC06-REQ-002-hotel-unit-search-en.png',
        '—',
        'البحث محصور بالوحدات المحمّلة للفندق المختار؛ لا طلب سيرفر جديد.',
    ),
    (
        '3',
        '«رقم الضيافة» بدل «رقم الحجز»',
        '“Stay Reference” instead of “Booking Number”',
        'Group 01',
        COMPLETE,
        'lib/utils/app_strings.dart (booking_number → رقم الضيافة / Stay Reference)',
        'test/document06_group01_test.dart — «المتطلب 3»',
        'customer/arabic/DOC06-REQ-006-stay-details-sheet-ar.png, '
        'customer/english/DOC06-REQ-006-stay-details-sheet-en.png',
        '—',
        'المعرّفات الداخلية (booking id / booking_ref) بقيت كما هي في كل الطلبات.',
    ),
    (
        '4',
        'عرض رقم الوحدة الفعلي في تأكيد الضيافة',
        'Display the actual booked unit number on the confirmation screen',
        'Group 01',
        COMPLETE,
        'lib/screens/booking/booking_success_screen.dart, '
        'lib/services/hotel_service.dart (booking.unit_number)',
        'test/document06_group01_test.dart — «المتطلب 4» (يعرض الرقم القادم من '
        'الاستجابة + لا يختلق رقمًا حين يغيب)',
        'customer/arabic/DOC06-REQ-003-005-booking-success-ar.png, '
        'customer/english/DOC06-REQ-003-005-booking-success-en.png',
        'يجب أن يُرجع `bookings/create.php` الحقل `booking.unit_number`. '
        'عند غيابه يعرض التطبيق «غير متاح» ولا يستبدله برقم الحجز.',
        'التعديل والإنهاء لا يتأثران: الوحدة تُقرأ للعرض فقط.',
    ),
    (
        '5',
        'إزالة عرض طريقة الدفع من تفاصيل الضيافة',
        'Remove the payment-method row from customer hospitality details',
        'Group 01',
        COMPLETE,
        'lib/screens/bookings/my_bookings_screen.dart (buildBookingDetailRows)',
        'test/document06_group01_test.dart — «المتطلب 5» (لا صف لطريقة الدفع)',
        'customer/arabic/DOC06-REQ-006-stay-details-sheet-ar.png, '
        'customer/english/DOC06-REQ-006-stay-details-sheet-en.png',
        '—',
        'سجلات الدفع والمعالجة المالية في الخلفية لم تُمس.',
    ),
    (
        '6',
        '«عرض تفاصيل ضيافتي»',
        '“View My Stay Details” action label',
        'Group 01',
        COMPLETE,
        'lib/utils/app_strings.dart (view_booking_details → عرض تفاصيل ضيافتي)',
        'test/document06_group01_test.dart — «المتطلب 6»',
        'customer/arabic/DOC06-REQ-006-my-bookings-ar.png',
        '—',
        'الإجراء والتنقّل كما هما؛ تغيّر النص فقط.',
    ),
    (
        '7',
        'تعطيل «الدفع عند الوصول» و«التحويل المباشر للمالك» افتراضيًا',
        'Disable pay-on-arrival and owner bank transfer by default',
        'Group 01',
        FLUTTER,
        'lib/utils/payment_methods_config.dart, '
        'lib/screens/booking/booking_screen.dart',
        'test/document06_group01_test.dart — «المتطلبان 7 و8» (افتراضي معطّل، تفعيل '
        'مستقل، رفض الوسيلة المعطّلة قبل الإرسال)',
        'customer/arabic/DOC05-REQ-033-booking-payment-methods-ar.png',
        'يجب أن يعلن `content/settings.php` حالة كل وسيلة، وأن يرفض '
        '`bookings/create.php` أي `payment_method` معطّلة.',
        'الوسيلتان قابلتان للتفعيل من الإعدادات، لم تُحذفا.',
    ),
    (
        '8',
        'تحكّم الإدارة في تفعيل/تعطيل كل وسيلة دفع',
        'Admin controls to enable or disable each payment method',
        'Group 01',
        FLUTTER,
        'lib/utils/payment_methods_config.dart (قراءة الإعدادات + التحقق قبل الإرسال)',
        'test/document06_group01_test.dart — «المتطلبان 7 و8»',
        '—',
        'لوحة الإدارة و`content/settings.php` غير موجودتين في هذا المستودع؛ '
        'المواصفة الكاملة في `docs/API_HANDOVER_AUTHORITATIVE.md` §3–§4.',
        'لا ندّعي أن التحكّم الإداري يعمل: البند سيرفري بالكامل.',
    ),
    (
        '9',
        'البحث برقم الوحدة في شاشة المغادرات',
        'Unit-number search on the hotel departures screen',
        'Group 01',
        COMPLETE,
        'lib/utils/departures.dart, '
        'lib/screens/hotel_staff/hotel_bookings_screen.dart',
        'test/document06_group01_test.dart — «المتطلب 9» (بحث جزئي، لا نتائج، '
        'can_check_out، رقم الوحدة من مفاتيح الباك إند)',
        'hotel-staff/arabic/DOC06-REQ-009-departures-search-ar.png, '
        'hotel-staff/english/DOC06-REQ-009-departures-search-en.png',
        '`hotel/bookings.php?scope=departures` يجب أن يبقى محصورًا بفندق الموظف.',
        'بحث الوصولات (arrivals) لم يُمس.',
    ),
    (
        '10',
        'خيارا سداد طلب النظافة',
        'Housekeeping confirmation with two payment options',
        'Group 01',
        FLUTTER,
        'lib/utils/request_settlement.dart, '
        'lib/screens/hotel_staff/hotel_requests_screen.dart',
        'test/document06_group01_test.dart — «المتطلب 10» (9 اختبارات: النصوص، '
        'قيم الإرسال، السعر المعتمد، منع التكرار، الصلاحيات، رابط السيرفر، واتساب، '
        'عدم تغيير خياري الصيانة)',
        'hotel-staff/arabic/DOC06-REQ-010-housekeeping-payment-options-ar.png, '
        'hotel-staff/english/DOC06-REQ-010-housekeeping-payment-options-en.png',
        '`hotel/requests.php` يجب أن ينفّذ الخصم مرة واحدة ويُرجع `payment_link` '
        'حقيقيًا عند اختيار الواتساب.',
        'لا خصم ولا رابط دفع من طرف التطبيق؛ كلاهما من السيرفر.',
    ),
    (
        '11',
        'تأكيد طلب وجبات مع خيار سداد',
        'Confirm a meal request with a payment option',
        'Group 02',
        FLUTTER,
        'lib/utils/request_settlement.dart, '
        'lib/screens/hotel_staff/hotel_requests_screen.dart',
        'test/document06_group02_test.dart — «المتطلب 11»',
        'hotel-staff/arabic/DOC06-REQ-011-requests-meal-ar.png, '
        'hotel-staff/english/DOC06-REQ-011-requests-meal-en.png',
        'نفس عقد §2.3 في `docs/API_HANDOVER_AUTHORITATIVE.md`.',
        'أنواع الوجبات تُعرض كما يرسلها السيرفر؛ لا نوع مُختلق.',
    ),
    (
        '12',
        'تسوية السرير الإضافي بالمبلغ المعتمد',
        'Settle an extra-bed request with the approved amount',
        'Group 02',
        FLUTTER,
        'lib/utils/request_settlement.dart, '
        'lib/screens/hotel_staff/hotel_requests_screen.dart',
        'test/document06_group02_test.dart — «المتطلب 12»',
        'customer/arabic/DOC06-REQ-B-002-booking-extra-bed-summary-ar.png',
        'المبلغ المعتمد من السيرفر (`approved_price`/`price`) هو الوحيد المقبول.',
        'لا تسوية بلا سعر معتمد.',
    ),
    (
        '13',
        'حقل العنوان في نموذج تسعير وحدات الفندق',
        'Title field in the hotel unit pricing form',
        'Group 02',
        FLUTTER,
        'lib/screens/hotel_staff/hotel_prices_screen.dart',
        'test/document06_group02_test.dart — «المتطلب 13 و14»',
        'hotel-staff/arabic/DOC05-REQ-083-hotel-prices-ar.png',
        '`hotel/unit-pricing.php` يجب أن يحفظ `title`.',
        'العنوان يُرسل كما أدخله الموظف، بلا توليد من التطبيق.',
    ),
    (
        '14',
        'منتقي التاريخ في نموذج تسعير الوحدات',
        'Date picker in the hotel unit pricing form',
        'Group 02',
        FLUTTER,
        'lib/screens/hotel_staff/hotel_prices_screen.dart',
        'test/document06_group02_test.dart — «المتطلب 13 و14»',
        'hotel-staff/arabic/DOC05-REQ-083-hotel-prices-ar.png',
        '`hotel/unit-pricing.php` يجب أن يحفظ `effective_date` (YYYY-MM-DD).',
        'التاريخ بصيغة ISO فقط؛ لا تحويل ضمني.',
    ),
    (
        '15',
        'ستة صفوف أنواع وحدات وأسعار',
        'Six unit-type and price rows',
        'Group 02',
        FLUTTER,
        'lib/screens/hotel_staff/hotel_prices_screen.dart',
        'test/document06_group02_test.dart — «المتطلب 15»',
        'hotel-staff/arabic/DOC05-REQ-083-hotel-prices-ar.png',
        '`hotel/unit-pricing.php` يجب أن يقبل حتى ستة صفوف في طلب واحد.',
        'الصفوف الفارغة لا تُرسل.',
    ),
    (
        '16',
        'تسعير الوجبات: عنوان وتاريخ وثلاث وجبات',
        'Hotel meal pricing form (title, date, three meals)',
        'Group 02',
        FLUTTER,
        'lib/screens/hotel_staff/hotel_prices_screen.dart',
        'test/document06_group02_test.dart — «المتطلب 16»',
        'hotel-staff/arabic/DOC06-REQ-016-meal-pricing-ar.png, '
        'hotel-staff/english/DOC06-REQ-016-meal-pricing-en.png',
        '`hotel/meal-pricing.php` يجب أن يحفظ `title`, `effective_date`, '
        '`breakfast`, `lunch`, `dinner`.',
        'لا أسعار افتراضية من التطبيق.',
    ),
    (
        '17',
        'إزالة سعر الليلة من نموذج إنشاء الفندق',
        'Remove the nightly price from the hotel creation form',
        'Group 02',
        FLUTTER,
        'lib/screens/hotel_staff/* (لا نموذج إنشاء فندق في تطبيق Flutter)',
        'test/document06_group02_test.dart — «المتطلب 17» (غياب الحقل مُثبت)',
        '—',
        'إن كان نموذج إنشاء الفندق موجودًا في لوحة الويب فقط، فالإزالة عمل PHP.',
        'لا يوجد نموذج إنشاء فندق في Flutter، فلا شيء أُزيل هنا.',
    ),
    (
        '§A-001',
        'ترتيب أقسام الرئيسية والوجهات',
        'Home section order and destinations',
        'Section A',
        COMPLETE,
        'lib/screens/home/home_screen.dart, lib/utils/city_ordering.dart, lib/utils/home_sections.dart',
        'test/document06_final_test.dart — «§A»',
        'customer/arabic/DOC06-REQ-A-001-home-section-order-ar.png, '
        'customer/english/DOC06-REQ-A-001-home-section-order-en.png',
        '—',
        'الترتيب من قرار المالك: بحث ← وجهات ← تصنيفات ← فنادق الملاك ← أحدث الوحدات.',
    ),
    (
        '§B-002',
        'حسابية السرير الإضافي والليالي',
        'Extra-bed arithmetic and nights',
        'Section B',
        COMPLETE,
        'lib/utils/booking_payload.dart, lib/utils/booking_totals.dart',
        'test/document06_final_test.dart — «§B», test/booking_extra_bed_paths_test.dart',
        'customer/arabic/DOC06-REQ-B-002-booking-extra-bed-hotel-ar.png, '
        'customer/english/DOC06-REQ-B-002-booking-extra-bed-unit-en.png',
        '`extra_bed_price` من `hotels/detail.php` هو مصدر سعر السرير.',
        'الكمية تُرسل فقط عند تفعيل السرير الإضافي.',
    ),
    (
        '§D',
        'توجيه الإشعارات ونصوصها',
        'Notification routing and copy',
        'Section D',
        COMPLETE,
        'lib/utils/notification_routing.dart, lib/services/firebase_push_provider.dart, '
        'lib/utils/push_lifecycle.dart',
        'test/document06_final_test.dart — «§D», test/firebase_push_provider_test.dart, '
        'test/push_account_switch_test.dart, test/push_tap_router_test.dart, '
        'test/session_push_wiring_test.dart',
        '—',
        '`user/device-token.php` يجب أن يخزّن رمز Firebase لكل مستخدم ويقبل الإلغاء.',
        'دورة الحياة كاملة: تسجيل عند الدخول، تدوير، إلغاء عند الخروج، تبديل حساب.',
    ),
    (
        '§F',
        'لوحة إدارة الفندق (78–92) والوصولات',
        'Hotel management dashboard (78–92) and arrivals',
        'Section F',
        COMPLETE,
        'lib/screens/hotel_staff/*, lib/utils/arrivals.dart, lib/utils/departures.dart',
        'test/document06_final_test.dart — «§F», test/hotel_staff_screens_render_test.dart',
        'hotel-staff/arabic/DOC06-REQ-F-002-arrivals-search-ar.png, '
        'hotel-staff/english/DOC06-REQ-F-002-arrivals-search-en.png',
        '`hotel/dashboard.php`, `hotel/bookings.php`, `hotel/requests.php` '
        'مقيّدة بفندق الموظف على السيرفر.',
        'بحث الوصولات والمغادرات يعمل محليًا على بيانات السيرفر المحمّلة.',
    ),
]

# متطلبات المستند 06 التي لا يوجد لها نص أصلي حرفي في المستودع.
NO_ORIGINAL_TEXT = [
    '1–17',
    '§A-001',
    '§B-002',
    '§D',
    '§F',
]
