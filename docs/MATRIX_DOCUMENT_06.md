# All Owners — مصفوفة المستند 06

**الفرع:** `feature/allowners-new-version-exec01`  
**المستند:** Modification Document 06 (المتطلبات 1–17 + الأقسام §A، §B، §D، §F)  
**مُولَّد آليًا:** `python3 tools/gen_doc06_matrix.py` من `tools/doc06_matrix_data.py` — لا تُحرّره يدويًا.  
**التفاصيل الكاملة:** `docs/DOCUMENT_06_GROUP_01.md`، `docs/DOCUMENT_06_GROUP_02.md`، 
`docs/DOCUMENT_06_FINAL_ACCEPTANCE.md`  
**عقد الـ API:** `docs/API_HANDOVER_AUTHORITATIVE.md`

> كل صف يتحقق منه المولّد: الملفات والاختبارات واللقطات المذكورة يجب أن 
> تكون موجودة فعلًا، وإلا يفشل التوليد. متطلبات المستند 05 في ملف مستقل 
> (`docs/MATRIX_DOCUMENT_05.md`).

## 1. الملخّص

| المقياس | القيمة |
|---|---|
| إجمالي بنود المستند 06 | 24 |
| Group 01 | 10 |
| Group 02 | 7 |
| Section A | 1 |
| Section B | 1 |
| Section D | 1 |
| Section F | 1 |
| Section P — Policy | 3 |

| الحالة | العدد |
|---|---|
| COMPLETE AND VERIFIED | 12 |
| FLUTTER COMPLETE — BACKEND PENDING | 12 |

## 2. المصفوفة

| # | المتطلب | المجموعة | الحالة | اختبار | لقطة |
|---|---|---|---|---|---|
| 1 | «ضيافاتي» بدل «حجوزاتي» للضيف | Group 01 | COMPLETE AND VERIFIED | test/document06_group01_test.dart — «المتطلب 1» (نصوص + بقاء مصطلح المالك والوكيل) | customer/arabic/DOC06-REQ-006-my-bookings-ar.png |
| 2 | البحث برقم الوحدة داخل تفاصيل الفندق | Group 01 | COMPLETE AND VERIFIED | test/document06_group01_test.dart — «المتطلب 2» (5 اختبارات: فارغ، جزئي/كامل، أرقام عربية-هندية، لا نتائج، نصوص) | customer/arabic/DOC06-REQ-002-hotel-unit-search-ar.png |
| 3 | «رقم الضيافة» بدل «رقم الحجز» | Group 01 | COMPLETE AND VERIFIED | test/document06_group01_test.dart — «المتطلب 3» | customer/arabic/DOC06-REQ-006-stay-details-sheet-ar.png |
| 4 | عرض رقم الوحدة الفعلي في تأكيد الضيافة | Group 01 | COMPLETE AND VERIFIED | test/document06_group01_test.dart — «المتطلب 4» (يعرض الرقم القادم من الاستجابة + لا يختلق رقمًا حين يغيب) | customer/arabic/DOC06-REQ-003-005-booking-success-ar.png |
| 5 | إزالة عرض طريقة الدفع من تفاصيل الضيافة | Group 01 | COMPLETE AND VERIFIED | test/document06_group01_test.dart — «المتطلب 5» (لا صف لطريقة الدفع) | customer/arabic/DOC06-REQ-006-stay-details-sheet-ar.png |
| 6 | «عرض تفاصيل ضيافتي» | Group 01 | COMPLETE AND VERIFIED | test/document06_group01_test.dart — «المتطلب 6» | customer/arabic/DOC06-REQ-006-my-bookings-ar.png |
| 7 | تعطيل «الدفع عند الوصول» و«التحويل المباشر للمالك» افتراضيًا | Group 01 | FLUTTER COMPLETE — BACKEND PENDING | test/document06_group01_test.dart — «المتطلبان 7 و8» (افتراضي معطّل، تفعيل مستقل، رفض الوسيلة المعطّلة قبل الإرسال) | customer/arabic/DOC05-REQ-033-booking-payment-methods-ar.png |
| 8 | تحكّم الإدارة في تفعيل/تعطيل كل وسيلة دفع | Group 01 | FLUTTER COMPLETE — BACKEND PENDING | test/document06_group01_test.dart — «المتطلبان 7 و8» | — |
| 9 | البحث برقم الوحدة في شاشة المغادرات | Group 01 | COMPLETE AND VERIFIED | test/document06_group01_test.dart — «المتطلب 9» (بحث جزئي، لا نتائج، can_check_out، رقم الوحدة من مفاتيح الباك إند) | hotel-staff/arabic/DOC06-REQ-009-departures-search-ar.png |
| 10 | خيارا سداد طلب النظافة | Group 01 | FLUTTER COMPLETE — BACKEND PENDING | test/document06_group01_test.dart — «المتطلب 10» (9 اختبارات: النصوص، قيم الإرسال، السعر المعتمد، منع التكرار، الصلاحيات، رابط السيرفر، واتساب، عدم تغيير خياري الصيانة) | hotel-staff/arabic/DOC06-REQ-010-housekeeping-payment-options-ar.png |
| 11 | تأكيد طلب وجبات مع خيار سداد | Group 02 | FLUTTER COMPLETE — BACKEND PENDING | test/document06_group02_test.dart — «المتطلب 11» | hotel-staff/arabic/DOC06-REQ-011-requests-meal-ar.png |
| 12 | تسوية السرير الإضافي بالمبلغ المعتمد | Group 02 | FLUTTER COMPLETE — BACKEND PENDING | test/document06_group02_test.dart — «المتطلب 12» | customer/arabic/DOC06-REQ-B-002-booking-extra-bed-summary-ar.png |
| 13 | حقل العنوان في نموذج تسعير وحدات الفندق | Group 02 | FLUTTER COMPLETE — BACKEND PENDING | test/document06_group02_test.dart — «المتطلب 13 و14» | hotel-staff/arabic/DOC05-REQ-083-hotel-prices-ar.png |
| 14 | منتقي التاريخ في نموذج تسعير الوحدات | Group 02 | FLUTTER COMPLETE — BACKEND PENDING | test/document06_group02_test.dart — «المتطلب 13 و14» | hotel-staff/arabic/DOC05-REQ-083-hotel-prices-ar.png |
| 15 | ستة صفوف أنواع وحدات وأسعار | Group 02 | FLUTTER COMPLETE — BACKEND PENDING | test/document06_group02_test.dart — «المتطلب 15» | hotel-staff/arabic/DOC05-REQ-083-hotel-prices-ar.png |
| 16 | تسعير الوجبات: عنوان وتاريخ وثلاث وجبات | Group 02 | FLUTTER COMPLETE — BACKEND PENDING | test/document06_group02_test.dart — «المتطلب 16» | hotel-staff/arabic/DOC06-REQ-016-meal-pricing-ar.png |
| 17 | إزالة سعر الليلة من نموذج إنشاء الفندق | Group 02 | FLUTTER COMPLETE — BACKEND PENDING | test/document06_group02_test.dart — «المتطلب 17» (غياب الحقل مُثبت) | — |
| §A-001 | ترتيب أقسام الرئيسية والوجهات | Section A | COMPLETE AND VERIFIED | test/document06_final_test.dart — «§A» | customer/arabic/DOC06-REQ-A-001-home-section-order-ar.png |
| §B-002 | حسابية السرير الإضافي والليالي | Section B | COMPLETE AND VERIFIED | test/document06_final_test.dart — «§B» | customer/arabic/DOC06-REQ-B-002-booking-extra-bed-hotel-ar.png |
| §D | توجيه الإشعارات ونصوصها | Section D | COMPLETE AND VERIFIED | test/document06_final_test.dart — «§D» | — |
| §F | لوحة إدارة الفندق (78–92) والوصولات | Section F | COMPLETE AND VERIFIED | test/document06_final_test.dart — «§F» | hotel-staff/arabic/DOC06-REQ-F-002-arrivals-search-ar.png |
| §P-01 | حذف الحساب من داخل التطبيق (سياسة Google Play) | Section P — Policy | FLUTTER COMPLETE — BACKEND PENDING | test/delete_account_test.dart (10 اختبارات: نصوص ar/en، تعطيل الزر قبل التأكيد، كلمة التأكيد، حجز قادم يمنع الحذف، نجاح فعلي، 404 بلا نجاح وهمي، فشل شبكة، success:false، حمولة reason، ترجمة 404) | customer/arabic/DOC06-POLICY-delete-account-form-ar.png |
| §P-02 | حالة إشعارات الجهاز وطلب الإذن داخل التطبيق | Section P — Policy | FLUTTER COMPLETE — BACKEND PENDING | test/push_status_banner_test.dart (6 اختبارات: نصوص ar/en، بلا مزوّع، نجاح التسجيل، رفض الإذن، سبب أولي من الجلسة، سبب خادم) | owner/arabic/DOC05-REQ-134-owner-notifications-ar.png |
| §P-03 | جاهزية Codemagic (تثبيت نسخة Flutter + بوابة تحقق) | Section P — Policy | COMPLETE AND VERIFIED | يُتحقق منه بتشغيل البوابة محليًا: `dart format --set-exit-if-changed lib test` + `flutter analyze` + `flutter test` (813 اختبارًا ناجحًا) | — |

## 3. التفاصيل

### 1 — «ضيافاتي» بدل «حجوزاتي» للضيف

- **English:** “My Stays” instead of “My Bookings” for the guest
- **المجموعة:** Group 01
- **الحالة:** COMPLETE AND VERIFIED
- **ملفات Flutter:** lib/utils/app_strings.dart (my_bookings → ضيافاتي / My Stays), lib/screens/bookings/my_bookings_screen.dart, lib/screens/home/main_navigation_screen.dart
- **الاختبارات:** test/document06_group01_test.dart — «المتطلب 1» (نصوص + بقاء مصطلح المالك والوكيل)
- **اللقطات:** customer/arabic/DOC06-REQ-006-my-bookings-ar.png, customer/english/DOC06-REQ-006-my-bookings-en.png
- **اعتماد السيرفر:** —
- **ملاحظة:** تسمية المالك والوكيل «حجوزاتي» لم تتغير (اختبار صريح).

### 2 — البحث برقم الوحدة داخل تفاصيل الفندق

- **English:** Search available units by unit number inside hotel details
- **المجموعة:** Group 01
- **الحالة:** COMPLETE AND VERIFIED
- **ملفات Flutter:** lib/utils/unit_search.dart, lib/screens/hotel/hotel_details_screen.dart
- **الاختبارات:** test/document06_group01_test.dart — «المتطلب 2» (5 اختبارات: فارغ، جزئي/كامل، أرقام عربية-هندية، لا نتائج، نصوص)
- **اللقطات:** customer/arabic/DOC06-REQ-002-hotel-unit-search-ar.png, customer/english/DOC06-REQ-002-hotel-unit-search-en.png
- **اعتماد السيرفر:** —
- **ملاحظة:** البحث محصور بالوحدات المحمّلة للفندق المختار؛ لا طلب سيرفر جديد.

### 3 — «رقم الضيافة» بدل «رقم الحجز»

- **English:** “Stay Reference” instead of “Booking Number”
- **المجموعة:** Group 01
- **الحالة:** COMPLETE AND VERIFIED
- **ملفات Flutter:** lib/utils/app_strings.dart (booking_number → رقم الضيافة / Stay Reference)
- **الاختبارات:** test/document06_group01_test.dart — «المتطلب 3»
- **اللقطات:** customer/arabic/DOC06-REQ-006-stay-details-sheet-ar.png, customer/english/DOC06-REQ-006-stay-details-sheet-en.png
- **اعتماد السيرفر:** —
- **ملاحظة:** المعرّفات الداخلية (booking id / booking_ref) بقيت كما هي في كل الطلبات.

### 4 — عرض رقم الوحدة الفعلي في تأكيد الضيافة

- **English:** Display the actual booked unit number on the confirmation screen
- **المجموعة:** Group 01
- **الحالة:** COMPLETE AND VERIFIED
- **ملفات Flutter:** lib/screens/booking/booking_success_screen.dart, lib/services/hotel_service.dart (booking.unit_number)
- **الاختبارات:** test/document06_group01_test.dart — «المتطلب 4» (يعرض الرقم القادم من الاستجابة + لا يختلق رقمًا حين يغيب)
- **اللقطات:** customer/arabic/DOC06-REQ-003-005-booking-success-ar.png, customer/english/DOC06-REQ-003-005-booking-success-en.png
- **اعتماد السيرفر:** يجب أن يُرجع `bookings/create.php` الحقل `booking.unit_number`. عند غيابه يعرض التطبيق «غير متاح» ولا يستبدله برقم الحجز.
- **ملاحظة:** التعديل والإنهاء لا يتأثران: الوحدة تُقرأ للعرض فقط.

### 5 — إزالة عرض طريقة الدفع من تفاصيل الضيافة

- **English:** Remove the payment-method row from customer hospitality details
- **المجموعة:** Group 01
- **الحالة:** COMPLETE AND VERIFIED
- **ملفات Flutter:** lib/screens/bookings/my_bookings_screen.dart (buildBookingDetailRows)
- **الاختبارات:** test/document06_group01_test.dart — «المتطلب 5» (لا صف لطريقة الدفع)
- **اللقطات:** customer/arabic/DOC06-REQ-006-stay-details-sheet-ar.png, customer/english/DOC06-REQ-006-stay-details-sheet-en.png
- **اعتماد السيرفر:** —
- **ملاحظة:** سجلات الدفع والمعالجة المالية في الخلفية لم تُمس.

### 6 — «عرض تفاصيل ضيافتي»

- **English:** “View My Stay Details” action label
- **المجموعة:** Group 01
- **الحالة:** COMPLETE AND VERIFIED
- **ملفات Flutter:** lib/utils/app_strings.dart (view_booking_details → عرض تفاصيل ضيافتي)
- **الاختبارات:** test/document06_group01_test.dart — «المتطلب 6»
- **اللقطات:** customer/arabic/DOC06-REQ-006-my-bookings-ar.png
- **اعتماد السيرفر:** —
- **ملاحظة:** الإجراء والتنقّل كما هما؛ تغيّر النص فقط.

### 7 — تعطيل «الدفع عند الوصول» و«التحويل المباشر للمالك» افتراضيًا

- **English:** Disable pay-on-arrival and owner bank transfer by default
- **المجموعة:** Group 01
- **الحالة:** FLUTTER COMPLETE — BACKEND PENDING
- **ملفات Flutter:** lib/utils/payment_methods_config.dart, lib/screens/booking/booking_screen.dart
- **الاختبارات:** test/document06_group01_test.dart — «المتطلبان 7 و8» (افتراضي معطّل، تفعيل مستقل، رفض الوسيلة المعطّلة قبل الإرسال)
- **اللقطات:** customer/arabic/DOC05-REQ-033-booking-payment-methods-ar.png
- **اعتماد السيرفر:** يجب أن يعلن `content/settings.php` حالة كل وسيلة، وأن يرفض `bookings/create.php` أي `payment_method` معطّلة.
- **ملاحظة:** الوسيلتان قابلتان للتفعيل من الإعدادات، لم تُحذفا.

### 8 — تحكّم الإدارة في تفعيل/تعطيل كل وسيلة دفع

- **English:** Admin controls to enable or disable each payment method
- **المجموعة:** Group 01
- **الحالة:** FLUTTER COMPLETE — BACKEND PENDING
- **ملفات Flutter:** lib/utils/payment_methods_config.dart (قراءة الإعدادات + التحقق قبل الإرسال)
- **الاختبارات:** test/document06_group01_test.dart — «المتطلبان 7 و8»
- **اللقطات:** —
- **اعتماد السيرفر:** لوحة الإدارة و`content/settings.php` غير موجودتين في هذا المستودع؛ المواصفة الكاملة في `docs/API_HANDOVER_AUTHORITATIVE.md` §3–§4.
- **ملاحظة:** لا ندّعي أن التحكّم الإداري يعمل: البند سيرفري بالكامل.

### 9 — البحث برقم الوحدة في شاشة المغادرات

- **English:** Unit-number search on the hotel departures screen
- **المجموعة:** Group 01
- **الحالة:** COMPLETE AND VERIFIED
- **ملفات Flutter:** lib/utils/departures.dart, lib/screens/hotel_staff/hotel_bookings_screen.dart
- **الاختبارات:** test/document06_group01_test.dart — «المتطلب 9» (بحث جزئي، لا نتائج، can_check_out، رقم الوحدة من مفاتيح الباك إند)
- **اللقطات:** hotel-staff/arabic/DOC06-REQ-009-departures-search-ar.png, hotel-staff/english/DOC06-REQ-009-departures-search-en.png
- **اعتماد السيرفر:** `hotel/bookings.php?scope=departures` يجب أن يبقى محصورًا بفندق الموظف.
- **ملاحظة:** بحث الوصولات (arrivals) لم يُمس.

### 10 — خيارا سداد طلب النظافة

- **English:** Housekeeping confirmation with two payment options
- **المجموعة:** Group 01
- **الحالة:** FLUTTER COMPLETE — BACKEND PENDING
- **ملفات Flutter:** lib/utils/request_settlement.dart, lib/screens/hotel_staff/hotel_requests_screen.dart
- **الاختبارات:** test/document06_group01_test.dart — «المتطلب 10» (9 اختبارات: النصوص، قيم الإرسال، السعر المعتمد، منع التكرار، الصلاحيات، رابط السيرفر، واتساب، عدم تغيير خياري الصيانة)
- **اللقطات:** hotel-staff/arabic/DOC06-REQ-010-housekeeping-payment-options-ar.png, hotel-staff/english/DOC06-REQ-010-housekeeping-payment-options-en.png
- **اعتماد السيرفر:** `hotel/requests.php` يجب أن ينفّذ الخصم مرة واحدة ويُرجع `payment_link` حقيقيًا عند اختيار الواتساب.
- **ملاحظة:** لا خصم ولا رابط دفع من طرف التطبيق؛ كلاهما من السيرفر.

### 11 — تأكيد طلب وجبات مع خيار سداد

- **English:** Confirm a meal request with a payment option
- **المجموعة:** Group 02
- **الحالة:** FLUTTER COMPLETE — BACKEND PENDING
- **ملفات Flutter:** lib/utils/request_settlement.dart, lib/screens/hotel_staff/hotel_requests_screen.dart
- **الاختبارات:** test/document06_group02_test.dart — «المتطلب 11»
- **اللقطات:** hotel-staff/arabic/DOC06-REQ-011-requests-meal-ar.png, hotel-staff/english/DOC06-REQ-011-requests-meal-en.png
- **اعتماد السيرفر:** نفس عقد §2.3 في `docs/API_HANDOVER_AUTHORITATIVE.md`.
- **ملاحظة:** أنواع الوجبات تُعرض كما يرسلها السيرفر؛ لا نوع مُختلق.

### 12 — تسوية السرير الإضافي بالمبلغ المعتمد

- **English:** Settle an extra-bed request with the approved amount
- **المجموعة:** Group 02
- **الحالة:** FLUTTER COMPLETE — BACKEND PENDING
- **ملفات Flutter:** lib/utils/request_settlement.dart, lib/screens/hotel_staff/hotel_requests_screen.dart
- **الاختبارات:** test/document06_group02_test.dart — «المتطلب 12»
- **اللقطات:** customer/arabic/DOC06-REQ-B-002-booking-extra-bed-summary-ar.png
- **اعتماد السيرفر:** المبلغ المعتمد من السيرفر (`approved_price`/`price`) هو الوحيد المقبول.
- **ملاحظة:** لا تسوية بلا سعر معتمد.

### 13 — حقل العنوان في نموذج تسعير وحدات الفندق

- **English:** Title field in the hotel unit pricing form
- **المجموعة:** Group 02
- **الحالة:** FLUTTER COMPLETE — BACKEND PENDING
- **ملفات Flutter:** lib/screens/hotel_staff/hotel_prices_screen.dart
- **الاختبارات:** test/document06_group02_test.dart — «المتطلب 13 و14»
- **اللقطات:** hotel-staff/arabic/DOC05-REQ-083-hotel-prices-ar.png
- **اعتماد السيرفر:** `hotel/unit-pricing.php` يجب أن يحفظ `title`.
- **ملاحظة:** العنوان يُرسل كما أدخله الموظف، بلا توليد من التطبيق.

### 14 — منتقي التاريخ في نموذج تسعير الوحدات

- **English:** Date picker in the hotel unit pricing form
- **المجموعة:** Group 02
- **الحالة:** FLUTTER COMPLETE — BACKEND PENDING
- **ملفات Flutter:** lib/screens/hotel_staff/hotel_prices_screen.dart
- **الاختبارات:** test/document06_group02_test.dart — «المتطلب 13 و14»
- **اللقطات:** hotel-staff/arabic/DOC05-REQ-083-hotel-prices-ar.png
- **اعتماد السيرفر:** `hotel/unit-pricing.php` يجب أن يحفظ `effective_date` (YYYY-MM-DD).
- **ملاحظة:** التاريخ بصيغة ISO فقط؛ لا تحويل ضمني.

### 15 — ستة صفوف أنواع وحدات وأسعار

- **English:** Six unit-type and price rows
- **المجموعة:** Group 02
- **الحالة:** FLUTTER COMPLETE — BACKEND PENDING
- **ملفات Flutter:** lib/screens/hotel_staff/hotel_prices_screen.dart
- **الاختبارات:** test/document06_group02_test.dart — «المتطلب 15»
- **اللقطات:** hotel-staff/arabic/DOC05-REQ-083-hotel-prices-ar.png
- **اعتماد السيرفر:** `hotel/unit-pricing.php` يجب أن يقبل حتى ستة صفوف في طلب واحد.
- **ملاحظة:** الصفوف الفارغة لا تُرسل.

### 16 — تسعير الوجبات: عنوان وتاريخ وثلاث وجبات

- **English:** Hotel meal pricing form (title, date, three meals)
- **المجموعة:** Group 02
- **الحالة:** FLUTTER COMPLETE — BACKEND PENDING
- **ملفات Flutter:** lib/screens/hotel_staff/hotel_prices_screen.dart
- **الاختبارات:** test/document06_group02_test.dart — «المتطلب 16»
- **اللقطات:** hotel-staff/arabic/DOC06-REQ-016-meal-pricing-ar.png, hotel-staff/english/DOC06-REQ-016-meal-pricing-en.png
- **اعتماد السيرفر:** `hotel/meal-pricing.php` يجب أن يحفظ `title`, `effective_date`, `breakfast`, `lunch`, `dinner`.
- **ملاحظة:** لا أسعار افتراضية من التطبيق.

### 17 — إزالة سعر الليلة من نموذج إنشاء الفندق

- **English:** Remove the nightly price from the hotel creation form
- **المجموعة:** Group 02
- **الحالة:** FLUTTER COMPLETE — BACKEND PENDING
- **ملفات Flutter:** lib/screens/hotel_staff/* (لا نموذج إنشاء فندق في تطبيق Flutter)
- **الاختبارات:** test/document06_group02_test.dart — «المتطلب 17» (غياب الحقل مُثبت)
- **اللقطات:** —
- **اعتماد السيرفر:** إن كان نموذج إنشاء الفندق موجودًا في لوحة الويب فقط، فالإزالة عمل PHP.
- **ملاحظة:** لا يوجد نموذج إنشاء فندق في Flutter، فلا شيء أُزيل هنا.

### §A-001 — ترتيب أقسام الرئيسية والوجهات

- **English:** Home section order and destinations
- **المجموعة:** Section A
- **الحالة:** COMPLETE AND VERIFIED
- **ملفات Flutter:** lib/screens/home/home_screen.dart, lib/utils/city_ordering.dart, lib/utils/home_sections.dart
- **الاختبارات:** test/document06_final_test.dart — «§A»
- **اللقطات:** customer/arabic/DOC06-REQ-A-001-home-section-order-ar.png, customer/english/DOC06-REQ-A-001-home-section-order-en.png
- **اعتماد السيرفر:** —
- **ملاحظة:** الترتيب من قرار المالك: بحث ← وجهات ← تصنيفات ← فنادق الملاك ← أحدث الوحدات.

### §B-002 — حسابية السرير الإضافي والليالي

- **English:** Extra-bed arithmetic and nights
- **المجموعة:** Section B
- **الحالة:** COMPLETE AND VERIFIED
- **ملفات Flutter:** lib/utils/booking_payload.dart, lib/utils/booking_totals.dart
- **الاختبارات:** test/document06_final_test.dart — «§B», test/booking_extra_bed_paths_test.dart
- **اللقطات:** customer/arabic/DOC06-REQ-B-002-booking-extra-bed-hotel-ar.png, customer/english/DOC06-REQ-B-002-booking-extra-bed-unit-en.png
- **اعتماد السيرفر:** `extra_bed_price` من `hotels/detail.php` هو مصدر سعر السرير.
- **ملاحظة:** الكمية تُرسل فقط عند تفعيل السرير الإضافي.

### §D — توجيه الإشعارات ونصوصها

- **English:** Notification routing and copy
- **المجموعة:** Section D
- **الحالة:** COMPLETE AND VERIFIED
- **ملفات Flutter:** lib/utils/notification_routing.dart, lib/services/firebase_push_provider.dart, lib/utils/push_lifecycle.dart
- **الاختبارات:** test/document06_final_test.dart — «§D», test/firebase_push_provider_test.dart, test/push_account_switch_test.dart, test/push_tap_router_test.dart, test/session_push_wiring_test.dart
- **اللقطات:** —
- **اعتماد السيرفر:** `user/device-token.php` يجب أن يخزّن رمز Firebase لكل مستخدم ويقبل الإلغاء.
- **ملاحظة:** دورة الحياة كاملة: تسجيل عند الدخول، تدوير، إلغاء عند الخروج، تبديل حساب.

### §F — لوحة إدارة الفندق (78–92) والوصولات

- **English:** Hotel management dashboard (78–92) and arrivals
- **المجموعة:** Section F
- **الحالة:** COMPLETE AND VERIFIED
- **ملفات Flutter:** lib/screens/hotel_staff/*, lib/utils/arrivals.dart, lib/utils/departures.dart
- **الاختبارات:** test/document06_final_test.dart — «§F», test/hotel_staff_screens_render_test.dart
- **اللقطات:** hotel-staff/arabic/DOC06-REQ-F-002-arrivals-search-ar.png, hotel-staff/english/DOC06-REQ-F-002-arrivals-search-en.png
- **اعتماد السيرفر:** `hotel/dashboard.php`, `hotel/bookings.php`, `hotel/requests.php` مقيّدة بفندق الموظف على السيرفر.
- **ملاحظة:** بحث الوصولات والمغادرات يعمل محليًا على بيانات السيرفر المحمّلة.

### §P-01 — حذف الحساب من داخل التطبيق (سياسة Google Play)

- **English:** In-app account deletion (Google Play policy)
- **المجموعة:** Section P — Policy
- **الحالة:** FLUTTER COMPLETE — BACKEND PENDING
- **ملفات Flutter:** lib/screens/profile/delete_account_screen.dart, lib/services/auth_service.dart (deleteAccount), lib/utils/session_provider.dart (deleteAccount), lib/screens/profile/profile_screen.dart (مدخل «حذف الحساب»)
- **الاختبارات:** test/delete_account_test.dart (10 اختبارات: نصوص ar/en، تعطيل الزر قبل التأكيد، كلمة التأكيد، حجز قادم يمنع الحذف، نجاح فعلي، 404 بلا نجاح وهمي، فشل شبكة، success:false، حمولة reason، ترجمة 404)
- **اللقطات:** customer/arabic/DOC06-POLICY-delete-account-form-ar.png, customer/english/DOC06-POLICY-delete-account-form-en.png, customer/arabic/DOC06-POLICY-delete-account-done-ar.png, customer/english/DOC06-POLICY-delete-account-done-en.png, customer/arabic/DOC06-POLICY-delete-account-blocked-ar.png, customer/english/DOC06-POLICY-delete-account-blocked-en.png, customer/arabic/DOC06-POLICY-profile-delete-entry-ar.png, customer/english/DOC06-POLICY-profile-delete-entry-en.png
- **اعتماد السيرفر:** `POST /user/delete-account.php` — غير مُنفَّذ على الخادم (المتوقع 404). التطبيق يعرض «غير مُفعَّلة» ولا يمسح الجلسة ولا يدّعي حذفًا.
- **ملاحظة:** لا يُعلن النجاح إلا بردّ `success: true`. شاشة الإتمام وصفحة الويب (all-owner.online/delete-account) بديلان لمن لا يستطيع فتح التطبيق.

### §P-02 — حالة إشعارات الجهاز وطلب الإذن داخل التطبيق

- **English:** Device notification status and permission request in-app
- **المجموعة:** Section P — Policy
- **الحالة:** FLUTTER COMPLETE — BACKEND PENDING
- **ملفات Flutter:** lib/widgets/push_status_banner.dart, lib/screens/owner/owner_notifications_screen.dart, lib/services/notification_service.dart (register)
- **الاختبارات:** test/push_status_banner_test.dart (6 اختبارات: نصوص ar/en، بلا مزوّع، نجاح التسجيل، رفض الإذن، سبب أولي من الجلسة، سبب خادم)
- **اللقطات:** owner/arabic/DOC05-REQ-134-owner-notifications-ar.png, owner/english/DOC05-REQ-134-owner-notifications-en.png
- **اعتماد السيرفر:** `POST /user/device-token.php` (موجود في التطبيق) + إعداد Firebase (`google-services.json` + `firebase_options.dart`) غير موجودين في المستودع، لذلك `isConfigured = false` ولا يصل أي إشعار.
- **ملاحظة:** الشريط يعرض آخر نتيجة تسجيل فعلية وسببها، ويسمح بإعادة المحاولة؛ لا يدّعي تفعيلًا لم يحدث.

### §P-03 — جاهزية Codemagic (تثبيت نسخة Flutter + بوابة تحقق)

- **English:** Codemagic readiness (pinned Flutter + verify gate)
- **المجموعة:** Section P — Policy
- **الحالة:** COMPLETE AND VERIFIED
- **ملفات Flutter:** codemagic.yaml
- **الاختبارات:** يُتحقق منه بتشغيل البوابة محليًا: `dart format --set-exit-if-changed lib test` + `flutter analyze` + `flutter test` (813 اختبارًا ناجحًا)
- **اللقطات:** —
- **اعتماد السيرفر:** —
- **ملاحظة:** نسخة Flutter مثبّتة على 3.44.9 (نسخة توليد اللقطات) في كل مسارات العمل، وأُضيف مسار `flutter-verify` لا يُنتج APK/AAB. لم يُشغَّل أي بناء هنا.

## 4. تدقيق الإسناد إلى المستند الأصلي

ملف المستند 06 الأصلي **ليس في هذا المستودع** (المستودع يحتوي المستند 05 فقط: 
`docs/AllOwners_Original_Under_3MB.docx`). لذلك النصوص العربية/الإنجليزية 
أعلاه مأخوذة من موجز المالك ومن التقارير السابقة، وليست نقلًا حرفيًا عن 
صفحات المستند 06.

البنود التي تنقصها إشارة إلى نص/صفحة أصلية:

- 1–17
- §A-001
- §B-002
- §D
- §F
- §P-01
- §P-02
- §P-03

لإغلاق هذا النقص: إرفاق ملف المستند 06 الأصلي في `docs/` ثم إعادة التوليد 
مع إضافة رقم الصفحة لكل بند في `tools/doc06_matrix_data.py`.

## 5. إعادة التوليد

```bash
python3 tools/gen_doc06_matrix.py
python3 tools/gen_doc05_matrix.py
```

