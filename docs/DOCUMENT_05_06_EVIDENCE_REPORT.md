# المستندان 05 و06 — تقرير الأدلة الكامل متطلبًا بمتطلب

**الفرع:** `feature/allowners-new-version-exec01` · **PR:** [#1](https://github.com/startgroup2022-tech/allowner/pull/1) (Draft)

> **هذا الملف مُولَّد آليًا** بـ `python3 tools/gen_evidence_report.py`. لا تُحرّره يدويًا. المصادر: مصفوفة المتطلبات 148، ملفات الاختبار الفعلية، ولقطات الشاشة الحقيقية تحت `docs/evidence/final-acceptance/`.

## 0. منهج الإثبات — وكيف يُقرأ هذا التقرير

| العمود | معناه بالضبط |
|---|---|
| **الحالة** | تصنيف المصفوفة الرسمية (`VERIFIED PASS` / `PARTIAL` / `BACKEND BLOCKED` / `INTEGRATION VERIFIED`) |
| **ملفات Flutter** | الملفات التي تنفّذ المتطلب، كما في المصفوفة |
| **اعتماد الـ API** | نقطة النهاية أو الجدول الذي يحتاجه المتطلب على cPanel |
| **اختبار يحمل المعرّف** | اختبارات تحمل في اسمها `DOC05-REQ-…`. الكثير من المتطلبات مغطّى باختبارات عامة (`widgets_test.dart`, `document06_*_test.dart`) لا تحمل معرّفًا رقميًا، فتظهر هنا «—» مع أنها مُختبَرة |
| **لقطة شاشة** | PNG حقيقي مرسوم من الودجات الإنتاجية، لا موك‑أب |

**قاعدة الصدق المتّبعة:** نجاح اختبار بلقطة شاشة يعني أن الواجهة تعرض الشيء الصحيح مقابل بيانات وهمية مطابقة لعقد الـ API؛ ولا يعني أن PHP منفّذ. كل متطلب له اعتماد API يظهر في العمود المخصص ويُعدّ `FLUTTER COMPLETE — BACKEND PENDING` إن لم يوجد إثبات سيرفر.

## 1. الملخّص

- متطلبات المستند 05 المرصودة في المصفوفة: **148**
- متطلبات لها لقطة شاشة حقيقية: **53**
- متطلبات لها اختبار يحمل معرّفها: **53**
- متطلبات لها اعتماد API (خارج قدرة التطبيق وحده): **133**
- لقطات الشاشة المنشورة: **86**

| الحالة | العدد |
|---|---|
| VERIFIED PASS | 99 |
| BACKEND BLOCKED | 26 |
| PARTIAL | 20 |
| INTEGRATION VERIFIED | 3 |

## 2. المستند 05 — الـ148 متطلبًا

| # | المتطلب | الحالة | اعتماد الـ API | اختبار يحمل المعرّف | لقطة الشاشة |
|---|---|---|---|---|---|
| 1 | نص الترحيب العربي داخل التطبيق | VERIFIED PASS | — | `test/screenshot_export_matrix_test.dart` (DOC05-REQ-001-002) | `docs/evidence/final-acceptance/customer/arabic/DOC05-REQ-001-002-onboarding-ar.png`<br>`docs/evidence/final-acceptance/customer/english/DOC05-REQ-001-002-onboarding-en.png` |
| 2 | نص الترحيب الإنجليزي داخل التطبيق | VERIFIED PASS | — | `test/screenshot_export_matrix_test.dart` (DOC05-REQ-001-002) | `docs/evidence/final-acceptance/customer/arabic/DOC05-REQ-001-002-onboarding-ar.png`<br>`docs/evidence/final-acceptance/customer/english/DOC05-REQ-001-002-onboarding-en.png` |
| 3 | الوصف العربي للتطبيق | VERIFIED PASS | — | `test/screenshot_export_matrix_test.dart` (DOC05-REQ-003-005) | `docs/evidence/final-acceptance/customer/arabic/DOC05-REQ-003-005-about-app-ar.png`<br>`docs/evidence/final-acceptance/customer/english/DOC05-REQ-003-005-about-app-en.png` |
| 4 | الوصف الإنجليزي للتطبيق | VERIFIED PASS | — | `test/screenshot_export_matrix_test.dart` (DOC05-REQ-003-005) | `docs/evidence/final-acceptance/customer/arabic/DOC05-REQ-003-005-about-app-ar.png`<br>`docs/evidence/final-acceptance/customer/english/DOC05-REQ-003-005-about-app-en.png` |
| 5 | العبارة التعريفية العربية والإنجليزية | VERIFIED PASS | — | `test/screenshot_export_matrix_test.dart` (DOC05-REQ-003-005) | `docs/evidence/final-acceptance/customer/arabic/DOC05-REQ-003-005-about-app-ar.png`<br>`docs/evidence/final-acceptance/customer/english/DOC05-REQ-003-005-about-app-en.png` |
| 6 | استبدال شعارات التطبيق بالشعارات الجديدة | VERIFIED PASS | /content/settings.php | — | — |
| 7 | تكبير شعار AO في الترحيب | VERIFIED PASS | — | — | — |
| 8 | إضافة بيانات المساعدة والدعم | VERIFIED PASS | /content/settings.php (مُتحقَّق حيًّا: info@assetsaxis.com / +966555634615 / whatsapp) | `test/screenshot_export_matrix_test.dart` (DOC05-REQ-008) | `docs/evidence/final-acceptance/customer/arabic/DOC05-REQ-008-help-support-ar.png`<br>`docs/evidence/final-acceptance/customer/english/DOC05-REQ-008-help-support-en.png` |
| 9 | تغيير الصورة الشخصية لكل الأدوار | VERIFIED PASS | /user/avatar.php | — | — |
| 10 | ترحيب مخصص باسم المستخدم | VERIFIED PASS | /auth/me.php | `test/screenshot_export_test.dart` (DOC05-REQ-010-018) | `docs/evidence/final-acceptance/customer/arabic/DOC05-REQ-010-018-home-ar.png` |
| 11 | ترحيب خاص بحساب المالك | VERIFIED PASS | /user/owner-dashboard.php | `test/screenshot_export_test.dart` (DOC05-REQ-010-018) | `docs/evidence/final-acceptance/customer/arabic/DOC05-REQ-010-018-home-ar.png` |
| 12 | إبراز مربع البحث وتغيير نصه | VERIFIED PASS | /units/browse.php | `test/screenshot_export_test.dart` (DOC05-REQ-010-018) | `docs/evidence/final-acceptance/customer/arabic/DOC05-REQ-010-018-home-ar.png` |
| 13 | تغيير تصنيف فنادق إلى وحدات فندقية | VERIFIED PASS | /categories/list.php | `test/screenshot_export_test.dart` (DOC05-REQ-010-018)<br>`test/screenshot_export_test.dart` (DOC05-REQ-013-016) | `docs/evidence/final-acceptance/customer/arabic/DOC05-REQ-010-018-home-ar.png`<br>`docs/evidence/final-acceptance/customer/english/DOC05-REQ-013-016-home-en.png` |
| 14 | إضافة تصنيفات الوحدات الخمسة | BACKEND BLOCKED | /categories/list.php | `test/screenshot_export_test.dart` (DOC05-REQ-010-018)<br>`test/screenshot_export_test.dart` (DOC05-REQ-013-016) | `docs/evidence/final-acceptance/customer/arabic/DOC05-REQ-010-018-home-ar.png`<br>`docs/evidence/final-acceptance/customer/english/DOC05-REQ-013-016-home-en.png` |
| 15 | سحب التصنيفات أفقياً | VERIFIED PASS | /categories/list.php | `test/screenshot_export_test.dart` (DOC05-REQ-010-018)<br>`test/screenshot_export_test.dart` (DOC05-REQ-013-016) | `docs/evidence/final-acceptance/customer/arabic/DOC05-REQ-010-018-home-ar.png`<br>`docs/evidence/final-acceptance/customer/english/DOC05-REQ-013-016-home-en.png` |
| 16 | تغيير أحدث الأجنحة إلى أحدث الوحدات | VERIFIED PASS | /units/browse.php?sort=newest | `test/screenshot_export_test.dart` (DOC05-REQ-010-018)<br>`test/screenshot_export_test.dart` (DOC05-REQ-013-016) | `docs/evidence/final-acceptance/customer/arabic/DOC05-REQ-010-018-home-ar.png`<br>`docs/evidence/final-acceptance/customer/english/DOC05-REQ-013-016-home-en.png` |
| 17 | تقليل المساحات البيضاء وإظهار البطاقات | VERIFIED PASS | — | `test/screenshot_export_test.dart` (DOC05-REQ-010-018) | `docs/evidence/final-acceptance/customer/arabic/DOC05-REQ-010-018-home-ar.png` |
| 18 | قسم الوجهات الرئيسية مكة جدة المدينة الرياض | VERIFIED PASS | /cities/list.php | `test/screenshot_export_test.dart` (DOC05-REQ-010-018) | `docs/evidence/final-acceptance/customer/arabic/DOC05-REQ-010-018-home-ar.png` |
| 19 | بطاقات مدن قابلة للنقر والتصفية | VERIFIED PASS | /units/browse.php?city= | `test/screenshot_export_test.dart` (DOC05-REQ-019) | `docs/evidence/final-acceptance/customer/arabic/DOC05-REQ-019-search-empty-ar.png`<br>`docs/evidence/final-acceptance/customer/arabic/DOC05-REQ-019-search-error-ar.png`<br>`docs/evidence/final-acceptance/customer/arabic/DOC05-REQ-019-search-results-ar.png`<br>`docs/evidence/final-acceptance/customer/english/DOC05-REQ-019-search-results-en.png` |
| 20 | قسم اكتشف حسب النوع | VERIFIED PASS | /categories/list.php | — | — |
| 21 | قسم فنادق بوحدات ملاك | VERIFIED PASS | /units/browse.php?owner_only=1 + /hotels/list.php | — | — |
| 22 | عرض عدد الوحدات والتقييم والمدينة في بطاقات فنادق الملاك | VERIFIED PASS | /units/browse.php + /hotels/list.php | — | — |
| 23 | قسم وحدات الملاك مرتبط بالمدينة المختارة | VERIFIED PASS | /units/browse.php?city= + /hotels/list.php?city= | — | — |
| 24 | إضافة الفنادق المحددة في قائمة مكة وحالات قريباً | BACKEND BLOCKED | /hotels/list.php | — | — |
| 25 | إضافة فنادق المدينة وجدة والرياض وحالات قريباً | BACKEND BLOCKED | /hotels/list.php | — | — |
| 26 | إظهار الفنادق المضافة من لوحة المالك عند البحث باسم المدينة | VERIFIED PASS | /hotels/list.php + /units/browse.php | — | — |
| 27 | تعديل ترتيب أقسام الرئيسية والقائمة السفلية | VERIFIED PASS | — | — | — |
| 28 | عرض تفاصيل الفندق قبل اختيار الغرف | VERIFIED PASS | /hotels/detail.php | `test/screenshot_export_test.dart` (DOC05-REQ-028-030) | `docs/evidence/final-acceptance/customer/arabic/DOC05-REQ-028-030-hotel-details-ar.png`<br>`docs/evidence/final-acceptance/customer/english/DOC05-REQ-028-030-hotel-details-en.png` |
| 29 | عرض وحدات الفندق وأسعارها وخدماتها | INTEGRATION VERIFIED | /units/list.php?hotel_id= | `test/screenshot_export_test.dart` (DOC05-REQ-028-030) | `docs/evidence/final-acceptance/customer/arabic/DOC05-REQ-028-030-hotel-details-ar.png`<br>`docs/evidence/final-acceptance/customer/english/DOC05-REQ-028-030-hotel-details-en.png` |
| 30 | عرض تفاصيل وصور الوحدة وزر احجز الآن | INTEGRATION VERIFIED | /units/detail.php | `test/screenshot_export_test.dart` (DOC05-REQ-028-030)<br>`test/screenshot_export_test.dart` (DOC05-REQ-030) | `docs/evidence/final-acceptance/customer/arabic/DOC05-REQ-028-030-hotel-details-ar.png`<br>`docs/evidence/final-acceptance/customer/arabic/DOC05-REQ-030-unit-details-ar.png`<br>`docs/evidence/final-acceptance/customer/english/DOC05-REQ-028-030-hotel-details-en.png`<br>`docs/evidence/final-acceptance/customer/english/DOC05-REQ-030-unit-details-en.png` |
| 31 | عرض سعر الوحدة وإضافات الوجبات والسرير قبل الحجز | VERIFIED PASS | /units/addons.php price_unit | `test/screenshot_export_test.dart` (DOC05-REQ-031-034) | `docs/evidence/final-acceptance/customer/arabic/DOC05-REQ-031-034-booking-ar.png`<br>`docs/evidence/final-acceptance/customer/english/DOC05-REQ-031-034-booking-en.png` |
| 32 | تغيير زر تأكيد الحجز إلى تفاصيل الحجز | VERIFIED PASS | /bookings/create.php | `test/screenshot_export_test.dart` (DOC05-REQ-031-034) | `docs/evidence/final-acceptance/customer/arabic/DOC05-REQ-031-034-booking-ar.png`<br>`docs/evidence/final-acceptance/customer/english/DOC05-REQ-031-034-booking-en.png` |
| 33 | صفحة ملخص الحجز ببيانات الضيف والتواريخ والأشخاص والإضافات | VERIFIED PASS | /bookings/create.php | `test/screenshot_export_test.dart` (DOC05-REQ-031-034)<br>`test/screenshot_export_test.dart` (DOC05-REQ-033) | `docs/evidence/final-acceptance/customer/arabic/DOC05-REQ-031-034-booking-ar.png`<br>`docs/evidence/final-acceptance/customer/arabic/DOC05-REQ-033-booking-payment-methods-ar.png`<br>`docs/evidence/final-acceptance/customer/english/DOC05-REQ-031-034-booking-en.png` |
| 34 | عرض طرق الدفع ضمن تفاصيل الحجز | PARTIAL | /bookings/create.php + /content/settings.php (payment_checkout_url) | `test/screenshot_export_test.dart` (DOC05-REQ-031-034) | `docs/evidence/final-acceptance/customer/arabic/DOC05-REQ-031-034-booking-ar.png`<br>`docs/evidence/final-acceptance/customer/english/DOC05-REQ-031-034-booking-en.png` |
| 35 | إظهار تفاصيل الحجز في تطبيق المالك ولوحته | VERIFIED PASS | /user/owner-bookings.php | — | — |
| 36 | إظهار الحجوزات الواردة من الضيف والوكيل للمالك | VERIFIED PASS | /user/owner-bookings.php source/agent_name | `test/screenshot_export_roles_test.dart` (DOC05-REQ-036-040) | `docs/evidence/final-acceptance/owner/arabic/DOC05-REQ-036-040-owner-bookings-ar.png` |
| 37 | تأكيد الحجز من تطبيق المالك | VERIFIED PASS | owner_service | `test/screenshot_export_roles_test.dart` (DOC05-REQ-036-040) | `docs/evidence/final-acceptance/owner/arabic/DOC05-REQ-036-040-owner-bookings-ar.png` |
| 38 | إلغاء الحجز من تطبيق المالك | VERIFIED PASS | owner_service | `test/screenshot_export_roles_test.dart` (DOC05-REQ-036-040) | `docs/evidence/final-acceptance/owner/arabic/DOC05-REQ-036-040-owner-bookings-ar.png` |
| 39 | تعديل الحجز من حساب المالك | VERIFIED PASS | /user/owner-bookings.php (action=update) | `test/screenshot_export_roles_test.dart` (DOC05-REQ-036-040) | `docs/evidence/final-acceptance/owner/arabic/DOC05-REQ-036-040-owner-bookings-ar.png` |
| 40 | تعديل الحجز من حساب الضيف | VERIFIED PASS | /bookings/manage.php | `test/screenshot_export_roles_test.dart` (DOC05-REQ-036-040) | `docs/evidence/final-acceptance/owner/arabic/DOC05-REQ-036-040-owner-bookings-ar.png` |
| 41 | إلغاء الحجز من حساب الضيف | VERIFIED PASS | /bookings/manage.php | — | — |
| 42 | تعديل الحجز من حساب الوكيل | VERIFIED PASS | /bookings/manage.php | — | — |
| 43 | إلغاء الحجز من حساب الوكيل | VERIFIED PASS | /bookings/manage.php | — | — |
| 44 | إرسال تأكيد الحجز للفندق بالبريد تلقائياً | BACKEND BLOCKED | بريد السيرفر | — | — |
| 45 | منع الحجز المزدوج لنفس الوحدة والتواريخ | PARTIAL | /bookings/create.php (فحص التوفّر) + /units/detail.php availability | — | — |
| 46 | إظهار بيانات وصول الضيف للوحدة بعد التأكيد | VERIFIED PASS | /bookings/create.php + /hotels/detail.php | — | — |
| 47 | مزامنة تفاصيل الحجز والتغييرات بين التطبيق والموقع | BACKEND BLOCKED | مزامنة الموقع | — | — |
| 48 | اختيار عدة وجبات عند إنشاء الحجز | VERIFIED PASS | /units/addons.php price_unit | — | — |
| 49 | اختيار عدة وجبات في طلب وجبة مستقل | VERIFIED PASS | /services/meal-request.php | — | — |
| 50 | عرض سعر كل وجبة | INTEGRATION VERIFIED | /units/addons.php | — | — |
| 51 | عرض إجمالي الوجبات بدلاً من حقل الملاحظات | VERIFIED PASS | /units/addons.php | — | — |
| 52 | عرض عدد الأشخاص أسفل رقم الغرفة | VERIFIED PASS | /bookings/my.php, /hotel/bookings.php | — | — |
| 53 | إرسال طلب الوجبات من الضيف إلى مالك الوحدة | VERIFIED PASS | /services/meal-request.php | — | — |
| 54 | إضافة طلب سرير إضافي للضيف | VERIFIED PASS | /units/addons.php | — | — |
| 55 | عرض تفاصيل وأسعار السرير الإضافي | VERIFIED PASS | /units/addons.php | — | — |
| 56 | تصحيح حساب تكلفة السرير الإضافي | VERIFIED PASS | /units/addons.php | — | — |
| 57 | تمكين الضيف من طلب النظافة | VERIFIED PASS | /services/request.php | — | — |
| 58 | تمكين الضيف من طلب الصيانة | VERIFIED PASS | /services/request.php | — | — |
| 59 | إظهار حالة طلبات الخدمات للضيف | BACKEND BLOCKED | غير موجود — لا توجد نقطة GET لعرض طلبات الضيف: /services/my-requests.php و/services/requests.php و/services/my_service_requests.php كلها 404 (مُتحقَّق) | — | — |
| 60 | قائمة طلب النظافة في حساب المالك | VERIFIED PASS | /user/owner-requests.php?type=cleaning | `test/screenshot_export_matrix_test.dart` (DOC05-REQ-060)<br>`test/screenshot_export_roles_test.dart` (DOC05-REQ-060) | `docs/evidence/final-acceptance/owner/arabic/DOC05-REQ-060-owner-cleaning-ar.png`<br>`docs/evidence/final-acceptance/owner/arabic/DOC05-REQ-060-owner-home-ar.png`<br>`docs/evidence/final-acceptance/owner/arabic/DOC05-REQ-060-owner-navigation-ar.png`<br>`docs/evidence/final-acceptance/owner/english/DOC05-REQ-060-owner-home-en.png`<br>`docs/evidence/final-acceptance/owner/english/DOC05-REQ-060-owner-navigation-en.png` |
| 61 | تغيير هاوس كيبنج إلى النظافة | VERIFIED PASS | — | `test/screenshot_export_matrix_test.dart` (DOC05-REQ-061)<br>`test/screenshot_export_roles_test.dart` (DOC05-REQ-061) | `docs/evidence/final-acceptance/owner/arabic/DOC05-REQ-061-owner-units-ar.png`<br>`docs/evidence/final-acceptance/owner/english/DOC05-REQ-061-owner-units-en.png` |
| 62 | إنشاء طلب نظافة من تطبيق المالك | VERIFIED PASS | /user/owner-requests.php | — | — |
| 63 | إنشاء طلب نظافة من لوحة المالك | BACKEND BLOCKED | لوحة المالك | — | — |
| 64 | إرسال طلب النظافة من المالك للفندق | BACKEND BLOCKED | /user/owner-requests.php | — | — |
| 65 | إنشاء طلب وجبات من حساب المالك ولوحته | VERIFIED PASS | /user/owner-requests.php (type=meal) | — | — |
| 66 | تمرير طلب وجبات الضيف أو الوكيل من المالك للفندق | BACKEND BLOCKED | /user/owner-meals.php | — | — |
| 67 | إنشاء طلب سرير إضافي من تطبيق المالك ولوحته | VERIFIED PASS | /user/owner-requests.php (type=extra_bed) | — | — |
| 68 | عرض أسعار خدمات الفندق للمالك | VERIFIED PASS | /hotel/prices.php (نفس نقطة الفندق، 401 بدون توكن) | `test/screenshot_export_roles_test.dart` (DOC05-REQ-068) | `docs/evidence/final-acceptance/owner/arabic/DOC05-REQ-068-owner-service-prices-ar.png` |
| 69 | عرض تكلفة الصيانة المؤكدة للمالك | VERIFIED PASS | /user/owner-maintenance.php | `test/screenshot_export_matrix_test.dart` (DOC05-REQ-069)<br>`test/screenshot_export_roles_test.dart` (DOC05-REQ-069) | `docs/evidence/final-acceptance/owner/arabic/DOC05-REQ-069-owner-meal-requests-ar.png`<br>`docs/evidence/final-acceptance/owner/english/DOC05-REQ-069-owner-meal-requests-en.png` |
| 70 | عرض تكلفة النظافة المؤكدة للمالك | VERIFIED PASS | /user/owner-requests.php | `test/screenshot_export_roles_test.dart` (DOC05-REQ-070) | `docs/evidence/final-acceptance/owner/arabic/DOC05-REQ-070-owner-extra-bed-ar.png` |
| 71 | عرض محتوى إشعارات طلبات الضيف وتفاصيل الخدمة | VERIFIED PASS | /user/notifications.php | — | — |
| 72 | إضافة صورة إلى طلب الصيانة في حساب المالك | VERIFIED PASS | /user/owner-maintenance.php (multipart image) | `test/screenshot_export_matrix_test.dart` (DOC05-REQ-072)<br>`test/screenshot_export_roles_test.dart` (DOC05-REQ-072) | `docs/evidence/final-acceptance/owner/arabic/DOC05-REQ-072-owner-maintenance-ar.png`<br>`docs/evidence/final-acceptance/owner/english/DOC05-REQ-072-owner-maintenance-en.png` |
| 73 | إظهار تفاصيل إضافات الوجبات والسرير في حجوزات المالك | VERIFIED PASS | /user/owner-bookings.php (حقول addons/meal_types/extra_bed_count/extra_bed_price/notes) | — | — |
| 74 | إدارة صلاحيات موظفي المالك كاملة | PARTIAL | owner-staff.php action=set_permissions (حفظ الخريطة) + إرجاع permissions في GET owner-staff.php | `test/screenshot_export_matrix_test.dart` (DOC05-REQ-074)<br>`test/screenshot_export_roles_test.dart` (DOC05-REQ-074) | `docs/evidence/final-acceptance/owner/arabic/DOC05-REQ-074-owner-staff-ar.png`<br>`docs/evidence/final-acceptance/owner/arabic/DOC05-REQ-074-staff-permissions-sheet-ar.png`<br>`docs/evidence/final-acceptance/owner/english/DOC05-REQ-074-owner-staff-en.png`<br>`docs/evidence/final-acceptance/owner/english/DOC05-REQ-074-staff-permissions-sheet-en.png` |
| 75 | تصحيح توجيه حساب موظف المالك إلى واجهته المناسبة | VERIFIED PASS | — | `test/screenshot_export_matrix_test.dart` (DOC05-REQ-075)<br>`test/screenshot_export_roles_test.dart` (DOC05-REQ-075) | `docs/evidence/final-acceptance/owner-employee/arabic/DOC05-REQ-075-employee-staff-navigation-ar.png`<br>`docs/evidence/final-acceptance/owner-employee/english/DOC05-REQ-075-employee-navigation-en.png` |
| 76 | إضافة تصنيفات خدمات الوحدة المفارش والطعام والحمام والوسائط والمعدات مع التفاصيل | VERIFIED PASS | /units/detail.php (facilities/amenities) — غير مُرجَع حاليًا | — | — |
| 77 | استقبال رسائل الطلبات بالبريد الإلكتروني | BACKEND BLOCKED | بريد السيرفر | — | — |
| 78 | تأكيد دخول الضيف Check-in | VERIFIED PASS | /hotel/bookings.php action=check_in | — | — |
| 79 | تأكيد خروج الضيف Check-out | VERIFIED PASS | /hotel/bookings.php action=check_out | — | — |
| 80 | فتح أقسام لوحة إدارة الفندق القابلة للدخول | VERIFIED PASS | /hotel/dashboard.php | `test/screenshot_export_roles_test.dart` (DOC05-REQ-080) | `docs/evidence/final-acceptance/hotel-staff/arabic/DOC05-REQ-080-hotel-dashboard-ar.png`<br>`docs/evidence/final-acceptance/hotel-staff/arabic/DOC05-REQ-080-staff-navigation-ar.png`<br>`docs/evidence/final-acceptance/hotel-staff/english/DOC05-REQ-080-hotel-dashboard-en.png` |
| 81 | البحث عن الوحدة برقمها في شاشة الوصول | VERIFIED PASS | /hotel/bookings.php | `test/screenshot_export_roles_test.dart` (DOC05-REQ-081) | `docs/evidence/final-acceptance/hotel-staff/arabic/DOC05-REQ-081-arrivals-ar.png` |
| 82 | تحديد أسعار النظافة حسب الوحدة | VERIFIED PASS | /hotel/prices.php | `test/screenshot_export_roles_test.dart` (DOC05-REQ-082) | `docs/evidence/final-acceptance/hotel-staff/arabic/DOC05-REQ-082-hotel-bookings-ar.png` |
| 83 | تأكيد طلب النظافة مع وصف | VERIFIED PASS | /hotel/requests.php action=confirm | `test/screenshot_export_roles_test.dart` (DOC05-REQ-083) | `docs/evidence/final-acceptance/hotel-staff/arabic/DOC05-REQ-083-hotel-prices-ar.png` |
| 84 | تحديد أسعار الصيانة | VERIFIED PASS | /hotel/prices.php | — | — |
| 85 | تأكيد طلب الصيانة مع وصف | VERIFIED PASS | /hotel/requests.php action=confirm | — | — |
| 86 | تسجيل إنجاز الصيانة مع وصف | VERIFIED PASS | /hotel/requests.php action=done | — | — |
| 87 | تحديد أسعار الوجبات | VERIFIED PASS | /hotel/prices.php | — | — |
| 88 | تأكيد طلب الوجبات | VERIFIED PASS | /hotel/requests.php action=confirm | — | — |
| 89 | تحديد أسعار السرير الإضافي | VERIFIED PASS | /hotel/prices.php | — | — |
| 90 | تأكيد طلب السرير الإضافي | VERIFIED PASS | /hotel/requests.php action=confirm | — | — |
| 91 | استقبال الطلبات المرسلة من المالك | VERIFIED PASS | /hotel/requests.php | — | — |
| 92 | إضافة صورة لطلب الصيانة من حساب إدارة الفندق | VERIFIED PASS | /hotel/requests.php (multipart image) | — | — |
| 93 | إصلاح إضافة عملاء الوكيل | VERIFIED PASS | /user/agent-clients.php | `test/screenshot_export_matrix_test.dart` (DOC05-REQ-093)<br>`test/screenshot_export_roles_test.dart` (DOC05-REQ-093) | `docs/evidence/final-acceptance/booking-agent/arabic/DOC05-REQ-093-agent-home-ar.png`<br>`docs/evidence/final-acceptance/booking-agent/english/DOC05-REQ-093-agent-home-en.png` |
| 94 | إضافة حقل اسم العميل عند الحجز | VERIFIED PASS | /bookings/create.php customer_name | — | — |
| 95 | اختيار فندق عند إنشاء حجز للعميل | VERIFIED PASS | /hotels/list.php | — | — |
| 96 | عرض وحدات الفندق المختار للوكيل | VERIFIED PASS | /units/list.php | — | — |
| 97 | عرض تفاصيل حجز الوكيل | VERIFIED PASS | /bookings/my.php | `test/screenshot_export_matrix_test.dart` (DOC05-REQ-097)<br>`test/screenshot_export_roles_test.dart` (DOC05-REQ-097) | `docs/evidence/final-acceptance/booking-agent/arabic/DOC05-REQ-097-agent-clients-ar.png`<br>`docs/evidence/final-acceptance/booking-agent/english/DOC05-REQ-097-agent-clients-en.png` |
| 98 | تغيير وحداتي إلى حجوزاتي | VERIFIED PASS | — | — | — |
| 99 | عرض جميع حجوزات عملاء الوكيل | VERIFIED PASS | /user/agent-clients.php | — | — |
| 100 | تغيير التقارير المالية إلى تقارير عمولات | VERIFIED PASS | /user/agent-commission.php | `test/screenshot_export_matrix_test.dart` (DOC05-REQ-100)<br>`test/screenshot_export_roles_test.dart` (DOC05-REQ-100) | `docs/evidence/final-acceptance/booking-agent/arabic/DOC05-REQ-100-agent-commission-ar.png`<br>`docs/evidence/final-acceptance/booking-agent/english/DOC05-REQ-100-agent-commission-en.png` |
| 101 | إزالة العقود والمستندات من قائمة الوكيل | VERIFIED PASS | — | — | — |
| 102 | إزالة مجتمع الملاك من قائمة الوكيل | VERIFIED PASS | — | — | — |
| 103 | إزالة التصويت من قائمة الوكيل | VERIFIED PASS | — | — | — |
| 104 | الإبقاء على خدمات الصيانة في قائمة الوكيل | VERIFIED PASS | — | — | — |
| 105 | إضافة طلب الوجبات في قائمة الوكيل | VERIFIED PASS | /services/meal-request.php | — | — |
| 106 | إضافة طلب النظافة في قائمة الوكيل | VERIFIED PASS | /services/request.php | — | — |
| 107 | إضافة طلب سرير إضافي في قائمة الوكيل | VERIFIED PASS | /services/request.php | — | — |
| 108 | تحويل العمولات غير المدفوعة | PARTIAL | /user/agent-commission.php action=request_transfer + /user/owner-bank.php | `test/screenshot_export_matrix_test.dart` (DOC05-REQ-108) | `docs/evidence/final-acceptance/owner/arabic/DOC05-REQ-108-commission-transfer-sheet-ar.png`<br>`docs/evidence/final-acceptance/owner/english/DOC05-REQ-108-commission-transfer-sheet-en.png` |
| 109 | إدخال بيانات حساب الوكيل البنكي لاستلام العمولات | VERIFIED PASS | /user/owner-bank.php | `test/screenshot_export_matrix_test.dart` (DOC05-REQ-109)<br>`test/screenshot_export_roles_test.dart` (DOC05-REQ-109) | `docs/evidence/final-acceptance/owner/arabic/DOC05-REQ-109-owner-bank-ar.png`<br>`docs/evidence/final-acceptance/owner/english/DOC05-REQ-109-owner-bank-en.png` |
| 110 | إصلاح نسيت كلمة المرور | PARTIAL | غير موجود — كل مسارات auth/forgot* و reset-password.php تُرجع 404 (مُتحقَّق) | — | — |
| 111 | إضافة طلبات الصيانة إلى لوحة الأدمن | BACKEND BLOCKED | لوحة الأدمن | — | — |
| 112 | إضافة إدارة وسائل الدفع والصلاحيات للأدمن | BACKEND BLOCKED | لوحة الأدمن | — | — |
| 113 | التحكم في وسائل الدفع المسموحة لكل مالك | BACKEND BLOCKED | سيرفر | — | — |
| 114 | إعادة ترتيب 16 قسمًا في قائمة الأدمن | BACKEND BLOCKED | لوحة الأدمن | — | — |
| 115 | إضافة رسوم الاشتراك السنوي عند إنشاء المالك من الأدمن | BACKEND BLOCKED | لوحة الأدمن | — | — |
| 116 | تحديث العبارة التعريفية على الموقع | BACKEND BLOCKED | الموقع | — | — |
| 117 | توحيد عرض تفاصيل الحجوزات على الموقع مع التطبيق | BACKEND BLOCKED | الموقع | — | — |
| 118 | تسجيل بيانات حساب المالك البنكي | VERIFIED PASS | /user/owner-bank.php | — | — |
| 119 | خيار تحويل مباشر إلى حساب المالك في الحجز | VERIFIED PASS | /bookings/create.php owner_transfer | — | — |
| 120 | عرض حساب مالك الوحدة الصحيح عند التحويل المباشر | VERIFIED PASS | /units/detail.php owner_bank | — | — |
| 121 | تفعيل اشتراك سنوي للمالك فقط | PARTIAL | /content/settings.php (قراءة الإعلان) | `test/screenshot_export_matrix_test.dart` (DOC05-REQ-121)<br>`test/screenshot_export_roles_test.dart` (DOC05-REQ-121) | `docs/evidence/final-acceptance/owner/arabic/DOC05-REQ-121-owner-subscription-ar.png`<br>`docs/evidence/final-acceptance/owner/english/DOC05-REQ-121-owner-subscription-en.png` |
| 122 | السماح للمالك غير المشترك بالاستعراض دون عمليات | PARTIAL | /content/settings.php | — | — |
| 123 | منع إضافة الوحدات والطلبات حتى الاشتراك | PARTIAL | /content/settings.php + قيد can_create في owner-units.php | — | — |
| 124 | صفحة تفعيل ودفع الاشتراك في حسابي | PARTIAL | غير موجود — لا مزوّد دفع اشتراك على السيرفر | — | — |
| 125 | عرض شروط الاشتراك ونسبة العمولة | VERIFIED PASS | /content/settings.php | — | — |
| 126 | تقارير مبيعات المالك الشهرية والسنوية | PARTIAL | /user/owner-revenue.php monthly[] | `test/screenshot_export_matrix_test.dart` (DOC05-REQ-126-129)<br>`test/screenshot_export_roles_test.dart` (DOC05-REQ-126-129) | `docs/evidence/final-acceptance/owner/arabic/DOC05-REQ-126-129-owner-revenue-ar.png`<br>`docs/evidence/final-acceptance/owner/english/DOC05-REQ-126-129-owner-revenue-en.png` |
| 127 | خصم الصيانة والنظافة من صافي الإيرادات | PARTIAL | /user/owner-revenue.php حقول المصروفات | `test/screenshot_export_matrix_test.dart` (DOC05-REQ-126-129)<br>`test/screenshot_export_roles_test.dart` (DOC05-REQ-126-129) | `docs/evidence/final-acceptance/owner/arabic/DOC05-REQ-126-129-owner-revenue-ar.png`<br>`docs/evidence/final-acceptance/owner/english/DOC05-REQ-126-129-owner-revenue-en.png` |
| 128 | تقارير مصروفات الصيانة الشهرية والسنوية | PARTIAL | /user/owner-revenue.php maintenance_expense | `test/screenshot_export_matrix_test.dart` (DOC05-REQ-126-129)<br>`test/screenshot_export_roles_test.dart` (DOC05-REQ-126-129) | `docs/evidence/final-acceptance/owner/arabic/DOC05-REQ-126-129-owner-revenue-ar.png`<br>`docs/evidence/final-acceptance/owner/english/DOC05-REQ-126-129-owner-revenue-en.png` |
| 129 | تقارير مصروفات النظافة الشهرية والسنوية | PARTIAL | /user/owner-revenue.php cleaning_expense | `test/screenshot_export_matrix_test.dart` (DOC05-REQ-126-129)<br>`test/screenshot_export_roles_test.dart` (DOC05-REQ-126-129) | `docs/evidence/final-acceptance/owner/arabic/DOC05-REQ-126-129-owner-revenue-ar.png`<br>`docs/evidence/final-acceptance/owner/english/DOC05-REQ-126-129-owner-revenue-en.png` |
| 130 | خيار خصم الصيانة من رصيد الوحدة | PARTIAL | /hotel/requests.php حقل settlement — لا يوجد endpoint للرصيد | — | — |
| 131 | خيار إرسال رابط دفع الصيانة عبر واتساب | PARTIAL | /hotel/requests.php حقل settlement + رقم هاتف الطالب | — | — |
| 132 | حساب تحصيل مركزي للمنصة | BACKEND BLOCKED | غير موجود — /user/owner-wallet.php تُرجع 404 (مُتحقَّق) | — | — |
| 133 | حساب أستاذ مستقل لكل مالك Ledger | PARTIAL | غير موجود — يُتوقّع جدول ledger في owner-wallet.php | `test/screenshot_export_matrix_test.dart` (DOC05-REQ-133)<br>`test/screenshot_export_roles_test.dart` (DOC05-REQ-133) | `docs/evidence/final-acceptance/owner/arabic/DOC05-REQ-133-owner-wallet-ar.png`<br>`docs/evidence/final-acceptance/owner/english/DOC05-REQ-133-owner-wallet-en.png` |
| 134 | تسجيل الحجوزات والعمولات والاستردادات والتسويات | PARTIAL | ledger في owner-wallet.php | `test/screenshot_export_matrix_test.dart` (DOC05-REQ-134)<br>`test/screenshot_export_roles_test.dart` (DOC05-REQ-134) | `docs/evidence/final-acceptance/owner/arabic/DOC05-REQ-134-owner-notifications-ar.png`<br>`docs/evidence/final-acceptance/owner/english/DOC05-REQ-134-owner-notifications-en.png` |
| 135 | محفظة مالك تعرض الرصيد والحجوزات والعمولة والمصروفات والقابل للتحويل | PARTIAL | owner-wallet.php | — | — |
| 136 | طلب تحويل مستحقات المالك | PARTIAL | owner-wallet.php (action=request_transfer) | — | — |
| 137 | تسوية وتحويل مستحقات المالك إلى حسابه البنكي | BACKEND BLOCKED | غير موجود — يحتاج مزوّد دفع/تحويل | — | — |
| 138 | دعم Split Payment أو Payouts عبر مزود مرخص | BACKEND BLOCKED | غير موجود — يحتاج مزوّد مرخّص (Split/Payouts) | — | — |
| 139 | احتساب عمولة 10 بالمئة على المالك | VERIFIED PASS | حسابي (نقي) | — | — |
| 140 | إظهار السعر النهائي للضيف | VERIFIED PASS | bookings (إجمالي الحجز) | — | — |
| 141 | التسوية بعد انتهاء الإقامة | VERIFIED PASS | حسابي (نقي) | — | — |
| 142 | دفع مستحقات المالك أسبوعياً | PARTIAL | غير موجود — يحتاج جدولة على السيرفر | — | — |
| 143 | حساب إيرادات مستقل لكل وحدة | BACKEND BLOCKED | /user/owner-revenue.php | — | — |
| 144 | تفعيل البريد المتبادل بين الفندق والمالك والعميل | BACKEND BLOCKED | /bookings/create.php + قالب البريد على السيرفر | `test/screenshot_export_test.dart` (DOC05-REQ-144) | `docs/evidence/final-acceptance/customer/arabic/DOC05-REQ-144-profile-ar.png` |
| 145 | تضمين اسم الضيف تلقائياً في رسالة التأكيد | BACKEND BLOCKED | /bookings/create.php + قالب البريد | — | — |
| 146 | تضمين رقم الهوية أو الجواز تلقائياً | BACKEND BLOCKED | /bookings/create.php + قالب البريد | — | — |
| 147 | تضمين تاريخ الدخول تلقائياً | BACKEND BLOCKED | /bookings/create.php + قالب البريد | — | — |
| 148 | تضمين نوع الوحدة ورقم الغرفة تلقائياً | BACKEND BLOCKED | /bookings/create.php + قالب البريد | — | — |

## 3. المستند 06 — المتطلبات المرقّمة والأقسام الحرفية

الأقسام: 01 = المتطلبات 1–10، 02 = 11–17، مع أقسام §A (ترتيب الرئيسية)، §B (حسابية السرير الإضافي)، §D (الإشعارات)، §F (لوحة إدارة الفندق 78–92).

| المعرّف | اختبار | لقطة شاشة |
|---|---|---|
| DOC06-REQ-002 | `test/screenshot_export_test.dart` | `docs/evidence/final-acceptance/customer/arabic/DOC06-REQ-002-hotel-unit-search-ar.png` |
| DOC06-REQ-003-005 | `test/screenshot_export_test.dart` | `docs/evidence/final-acceptance/customer/arabic/DOC06-REQ-003-005-booking-success-ar.png`<br>`docs/evidence/final-acceptance/customer/english/DOC06-REQ-003-005-booking-success-en.png` |
| DOC06-REQ-006 | `test/screenshot_export_test.dart` | `docs/evidence/final-acceptance/customer/arabic/DOC06-REQ-006-my-bookings-ar.png`<br>`docs/evidence/final-acceptance/customer/arabic/DOC06-REQ-006-stay-details-sheet-ar.png`<br>`docs/evidence/final-acceptance/customer/english/DOC06-REQ-006-my-bookings-en.png` |
| DOC06-REQ-009 | `test/screenshot_export_roles_test.dart` | `docs/evidence/final-acceptance/hotel-staff/arabic/DOC06-REQ-009-departures-search-ar.png` |
| DOC06-REQ-010 | `test/screenshot_export_roles_test.dart` | `docs/evidence/final-acceptance/hotel-staff/arabic/DOC06-REQ-010-housekeeping-payment-options-ar.png`<br>`docs/evidence/final-acceptance/hotel-staff/arabic/DOC06-REQ-010-requests-cleaning-ar.png` |
| DOC06-REQ-010-012 | `test/screenshot_export_roles_test.dart` | — |
| DOC06-REQ-011 | `test/screenshot_export_roles_test.dart` | `docs/evidence/final-acceptance/hotel-staff/arabic/DOC06-REQ-011-requests-meal-ar.png` |
| DOC06-REQ-013-015 | `test/screenshot_export_roles_test.dart` | `docs/evidence/final-acceptance/hotel-staff/arabic/DOC06-REQ-013-015-unit-pricing-ar.png`<br>`docs/evidence/final-acceptance/hotel-staff/english/DOC06-REQ-013-015-unit-pricing-en.png` |
| DOC06-REQ-016 | `test/screenshot_export_roles_test.dart` | `docs/evidence/final-acceptance/hotel-staff/arabic/DOC06-REQ-016-meal-pricing-ar.png` |
| DOC06-REQ-A-001 | `test/screenshot_export_test.dart` | `docs/evidence/final-acceptance/customer/arabic/DOC06-REQ-A-001-home-section-order-ar.png`<br>`docs/evidence/final-acceptance/customer/english/DOC06-REQ-A-001-home-section-order-en.png` |
| DOC06-REQ-B-002 | `test/screenshot_export_test.dart` | `docs/evidence/final-acceptance/customer/arabic/DOC06-REQ-B-002-booking-extra-bed-hotel-ar.png`<br>`docs/evidence/final-acceptance/customer/arabic/DOC06-REQ-B-002-booking-extra-bed-summary-ar.png`<br>`docs/evidence/final-acceptance/customer/arabic/DOC06-REQ-B-002-booking-extra-bed-unit-ar.png`<br>`docs/evidence/final-acceptance/customer/english/DOC06-REQ-B-002-booking-extra-bed-unit-en.png` |
| DOC06-REQ-F-002 | `test/screenshot_export_roles_test.dart` | `docs/evidence/final-acceptance/hotel-staff/arabic/DOC06-REQ-F-002-arrivals-empty-ar.png`<br>`docs/evidence/final-acceptance/hotel-staff/arabic/DOC06-REQ-F-002-arrivals-search-ar.png` |

## 4. متطلبات بلا لقطة شاشة — ولماذا

لا يوجد متطلب «مُهمَل»؛ إنما تُصنَّف المتطلبات بلا لقطة إلى ثلاث فئات، وكل فئة موثّقة أدناه بأرقامها:

**أ) متطلب نصي/سلوكي غير مرئي (نص، ترتيب بيانات، صلاحية، نسخ ولصق):** 7, 27, 98, 101, 102, 103, 104

**ب) متطلب يعتمد على السيرفر أو مزوّد دفع، فلا يمكن إثباته بلقطة عميل:** 6, 9, 20, 21, 22, 23, 24, 25, 26, 35, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 62, 63, 64, 65, 66, 67, 71, 73, 76, 77, 78, 79, 84, 85, 86, 87, 88, 89, 90, 91, 92, 94, 95, 96, 99, 105, 106, 107, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 122, 123, 124, 125, 130, 131, 132, 135, 136, 137, 138, 139, 140, 141, 142, 143, 145, 146, 147, 148

هذان السردان يُظهران أن غياب اللقطة ليس إغفالًا بل حدود إثبات.

## 5. مستوى الإثبات وتعليمات إعادة التوليد

```bash
# اللقطات الحقيقية (بلا شبكة، بخطوط عربية حقيقية)
flutter test test/screenshot_export_test.dart --update-goldens
flutter test test/screenshot_export_roles_test.dart --update-goldens
# هذا التقرير
python3 tools/gen_evidence_report.py
```
