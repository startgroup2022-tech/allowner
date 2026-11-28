# All Owners — تقرير الدمج النهائي وجاهزية الإصدار

**الفرع:** `feature/allowners-new-version-exec01`
**طلب الدمج:** PR #1 — **Draft، لم يُدمج ولن يُدمج في `main`**
**تاريخ التقرير:** 2026-11-26
**نطاق الوكيل:** تطبيق Flutter فقط. PHP/MariaDB/الموقع/لوحة الإدارة/cPanel **خارج النطاق ولم تُمَس**.

---

## 1. الملخّص التنفيذي

| المقياس | قبل هذه الجولة | بعد هذه الجولة |
|---|---|---|
| اختبارات ناجحة | 740 | **777** |
| اختبارات فاشلة | 0 | **0** |
| متخطّاة (اختبارات حيّة تحتاج `RUN_LIVE_TESTS=1`) | 17 | 17 |
| مشاكل `flutter analyze` | 0 | **0** |
| ملفات منسّقة (`dart format`) | 158 | **162** (0 تغيير) |
| لقطات معتمدة | 157 | **157** (بلا أي تغيير بصري) |
| متطلبات المستند 05 مغطاة بلقطات | 120/148 | 120/148 |
| «Flutter مكتمل — السيرفر ناقص» في المصفوفة | 0 | **2** (59، 143) |

**لم يتغيّر أي شيء في التصميم أو الهوية البصرية:** كل اللقطات الـ157 تُطابق صورها
الذهبية بيكسل بيكسل، أي أن هذه الجولة أضافت وظائف دون أي انحراف بصري.

---

## 2. البوابات — نتائج حقيقية

```bash
flutter pub get                                  # Got dependencies
dart format --output=none --set-exit-if-changed . # 162 files, 0 changed
flutter analyze                                  # No issues found!
flutter test                                     # 777 passed, 17 skipped, 0 failed
```

الاختبارات المتخطّاة (17) هي اختبارات الشبكة الحيّة في
`test/integration/live_backend_test.dart` وهي مشروطة بـ `RUN_LIVE_TESTS=1` لأنها
تستهدف قاعدة بيانات الإنتاج. لم يُعطَّل أي اختبار ولم يُحذف.

---

## 3. ما أُنجز في هذه الجولة

### 3.1 المتطلب 59 — «إظهار حالة طلبات الخدمات للضيف»

كان التطبيق يرسل الطلب فقط ولا يعرض حالته لغياب نقطة قراءة على السيرفر.

**المنجَز:**

- `lib/utils/service_request_store.dart` (جديد): سجل طلب (`type`, `id`, `status`,
  `room_number`, `description`, `created_at`) مع ترميز/فك ترميز JSON، ودمج
  يجعل **السيرفر هو المرجع**: سجل السيرفر يستبدل نظيره المحلي بالمعرّف نفسه،
  والطلبات المحلية بلا معرّف تبقى ظاهرة، وسقف 20 سجلًا.
- `lib/screens/services/hotel_services_screen.dart`: قسم «طلباتي» أسفل قائمة
  الخدمات، يعرض النوع ورقم الوحدة وشريحة الحالة.
- `lib/services/hotel_service.dart`: `submitServiceRequest` صار يُرجع استجابة
  السيرفر (`request{id,status}`)، وأُضيفت قراءة `/services/my-requests.php`.
- `lib/screens/services/service_request_screen.dart`: بعد نجاح الإرسال يُحفظ
  الطلب كما أعلنه السيرفر، وتُحدَّث القائمة عند العودة.

**قاعدة الصدق المطبَّقة:** لا تُعرض حالة لم يُعلنها السيرفر. الطلب بلا حالة
يظهر «—» بدل اختلاق «قيد الانتظار». وحين تغيب نقطة القراءة (404) تُعرض
الطلبات المحفوظة من استجابات السيرفر الفعلية مع نص صريح:
«التحديث الحيّ للحالة غير مُفعَّل بعد على السيرفر».

**الاختبارات:** `test/service_request_status_test.dart` — 13 اختبارًا
(ترميز/فك ترميز/نص تالف، أسماء حقول بديلة، معرّف صفري، دمج وتقدّم السيرفر،
سقف القائمة، تخزين محلي، و5 اختبارات ويدجت عربي/إنجليزي تشمل 404، الحالة
الفارغة، استبدال الحالة المحلية بحالة السيرفر، وغياب الحالة).

### 3.2 المتطلب 143 — إيراد كل وحدة

الشاشة تقرأ `by_unit` أو `units` من `/user/owner-revenue.php` وتعرض إيراد كل
وحدة كما يرسله السيرفر، مع حالة «لا بيانات» عند غياب المصفوفة. لا يُجمع أي
رقم من الحجوزات محليًا (مُثبت في `test/financial_safety_test.dart` §1).
**ما ينقص:** أن يُرجع السيرفر مصفوفة `by_unit` — بند سيرفر لا بند تطبيق.

### 3.3 إصلاح جوهري: حتمية اللقطات (كانت تفشل بتغيّر اليوم)

`DOC05-REQ-031-034-booking`, `-045-`, `-048-051-`, `-054-056-`,
`-119-120-` كانت تُقارن شاشة الحجز التي تبني تاريخ الوصول الافتراضي من
`DateTime.now()`، فتفشل تلقائيًا كل يوم يمرّ بلا أي تغيير في الكود
(رُصد فعلًا: الصورة الذهبية ٢٨ نوفمبر والاختبار أنتج ٢٧ نوفمبر).

**الحل:** `lib/utils/app_clock.dart` (جديد) — نقطة واحدة لقراءة الوقت،
`AppClock.now()`، مع `freeze()` للاختبارات. شاشة الحجز تقرأ منها بدل
`DateTime.now()`، و`test/screenshot_support.dart` يثبّت الساعة على
`2026-11-27` (لحظة اعتماد اللقطات) قبل كل لقطة ويعيدها بعدها.

**الأثر:** اللقطات الـ157 تمر بلا تغيير، والبوابة لم تعد تفشل لمجرد تغيّر
تاريخ التشغيل. لم تُحدَّث أي صورة ذهبية.

### 3.4 عنوان الـ API قابل للتجاوز لبيئة اختبار معزولة

`ApiConfig.baseUrl` صار `String.fromEnvironment('API_BASE_URL', defaultValue:
defaultBaseUrl)`؛ القيمة الافتراضية هي الإنتاج، فلا يتغيّر أي بناء عادي.
هذا يسمح بتشغيل الاختبارات الحيّة على نسخة staging بلا لمس الإنتاج:

```bash
RUN_LIVE_TESTS=1 flutter test --dart-define=API_BASE_URL=https://staging.example.com/api
```

### 3.5 المصفوفة وعقد الـ API

- `tools/matrix_data.py` + `tools/gen_requirements_matrix.py`: أُضيفت حالة
  `FLUTTER COMPLETE — BACKEND PENDING` لتمييز «الواجهة جاهزة والسيرفر ناقص»
  عن «BACKEND BLOCKED» (لا يوجد شيء في الواجهة). المتطلبان 59 و143 صارا بهذه
  الحالة، وأُعيد توليد `docs/ALL_OWNERS_REQUIREMENTS_MATRIX.md`
  (148 صفًا، 99 VERIFIED PASS، 3 INTEGRATION VERIFIED، 2 FLUTTER COMPLETE،
  20 PARTIAL، 24 BACKEND BLOCKED).
- `docs/API_HANDOVER_AUTHORITATIVE.md`: أُضيف `/services/my-requests.php`
  بالعقد المطلوب ووسم «غير منفّذ بعد».

---

## 4. التحقق المالي — البنود الثمانية

`test/financial_safety_test.dart` — **24 اختبارًا**، كلها على كود حقيقي (بلا
mocks للوحدات المالية؛ فقط محوّل Dio لالتقاط الحمولة الفعلية).

| # | البند المطلوب | كيف أُثبت | النتيجة |
|---|---|---|---|
| 1 | الحجوزات غير المدفوعة ليست إيرادًا محصّلًا | `RevenueReports.yearTotals` يقرأ `monthly` فقط؛ حمولة فيها حجوزات `pending`/`cancelled` لا تدخل الإيراد؛ بلا `monthly` لا إيراد | ✅ |
| 2 | طلب تحويل العمولة لا يظهر كدفعة مكتملة | الحمولة المُرسلة `{action: request_transfer, amount}` فقط؛ رسالة السيرفر تُعرض كما هي؛ رفض 400 يرمي `ApiException`؛ لا حقل `paid` مُصطنع | ✅ |
| 3 | الوسائل المعطّلة لا يمكن إرسالها | `resolvePaymentMethods(null)` = كل الوسائل معطّلة؛ علم `false` يمنع حتى مع رابط دفع؛ وسيلة غير معروفة تُرفض؛ `paymentMethodBlockReason` قبل كل إرسال في `booking_screen` | ✅ |
| 4 | أرصدة المحفظة من السيرفر فقط | `WalletBalance.fromMap` بلا حقول = `null` لا أصفار؛ قيم `DECIMAL` النصية تُقرأ كما هي | ✅ |
| 5 | تفعيل الاشتراك يحتاج استجابة سيرفر | رابط الدفع يُقبل فقط `https` مطلقًا؛ غياب `subscription_active` = حالة غير معروفة ≠ نشط | ✅ |
| 6 | لا خصم مزدوج في التسوية | `isRequestSettlementRecorded` + `validateRequestSettlement` يرفضان الطلب المسوّى بأربعة أشكال مختلفة (`settlement`, `settlement_status`, `payment_status`, `settled`) | ✅ |
| 7 | روابط الواتساب حقيقية فقط | `extractServerPaymentLink` يرفض `http`/الروابط النسبية/الفارغة؛ رسالة الواتساب لا تحمل رابطًا إن لم يُصدره السيرفر؛ بلا رقم صالح لا يُبنى رابط | ✅ |
| 8 | الموظف غير المصرّح لا يرى المالية | `can_view_finance` معطّل افتراضيًا لكل الأدوار؛ غياب الحقل يُسقط إلى «مغلق»؛ يُفتح فقط بنص صريح من السيرفر | ✅ |

**ملاحظة صدق:** هذه البنود تُثبت أن التطبيق لا يختلق أرقامًا ولا يرسل وسيلة
معطّلة ولا يكرّر تسوية. أما **فرض** ذلك على مستوى قاعدة البيانات (رفض طلب
حجز بوسيلة معطّلة عبر API مباشر، ومنع خصم مزدوج على السيرفر) فهو بند سيرفر
(§6-د) ولم يُدَّع إنجازه.

---

## 5. ما لم يتغيّر (قيود محفوظة)

- معرّف التطبيق `com.superai.allowners` — بلا تغيير.
- إعدادات التوقيع و`codemagic.yaml` — بلا تغيير؛ **لم يُبنَ APK/AAB محليًا ولم
  تُشغَّل أي بناء Codemagic**.
- وظيفة حذف الحساب على Google Play — بلا تغيير (اختباراتها تمرّ).
- RTL/LTR والهوية البصرية — بلا تغيير (157 لقطة مطابقة).
- PR #1 بقي **Draft**، ولم يُدمج في `main`، ولم يُستخدم force push.
- لم تُمَس أي ملفات PHP أو قاعدة بيانات أو cPanel.

---

## 6. متطلبات السيرفر الدقيقة (مرحلة cPanel)

هذه هي القائمة التي تحوّل الحالات من «Flutter مكتمل — السيرفر ناقص» إلى
مكتملة، ومرتبة حسب الأثر.

### أ. قراءة طلبات الضيف (المتطلب 59)

```
GET /api/services/my-requests.php
Auth: Bearer <token> (guest)
Response 200:
{
  "success": true,
  "requests": [
    {"id": 41, "type": "maintenance|housekeeping|cleaning|extra_bed",
     "status": "pending|confirmed|in_progress|done|rejected",
     "room_number": "402", "created_at": "2026-11-01T10:00:00Z"}
  ]
}
```
- مقيّد بطلبات المستخدم الحالي فقط (`user_id = token.user_id`).
- ترتيب تنازلي بـ `created_at`، وسقف 50 صفًا.
- التطبيق يقبل `type` أو `service_type` و`room_number` أو `unit_number`.

### ب. إيراد كل وحدة (المتطلب 143)

```
GET /api/user/owner-revenue.php   (موجود — ينقصه الحقل)
{
  "total": 12000,
  "monthly": [{"month": "2026-11", "total": 3000}],
  "by_unit": [{"unit_id": 7, "unit_number": "402", "total": 4500}]
}
```
- `by_unit` تُحسب من الحجوزات **المدفوعة/المكتملة فقط**، ولا تُشمل الملغاة.
- المبالغ أرقام أو نصوص `DECIMAL` (التطبيق يقرأ الشكلين).

### ج. إتاحة وسائل الدفع (المتطلبان 7 و8 من المستند 06)

```
GET /api/content/settings.php  →  payment_methods: {online, at_hotel, owner_transfer}
POST /api/admin/payment-methods.php  (admin فقط)
   body: {method: "at_hotel", enabled: false}
```
- التطبيق يقرأ `payment_methods` (خريطة أو مصفوفة أسماء) أو
  `payment_<method>_enabled`، والغياب = **معطّل**.
- **الفرض على السيرفر إلزامي:** `bookings/create.php` يرفض (400) أي
  `payment_method` غير مُفعَّل، حتى لو تجاوز العميل الواجهة.
- سجل تدقيق لكل تغيير (`admin_id`, `method`, `old`, `new`, `at`).

### د. الفرض المالي على السيرفر

- `bookings/create.php`: رفض `at_hotel` و`owner_transfer` ما لم يُفعّلا.
- `hotel/*-request.php` (تسوية النظافة/الوجبات/السرير): `settlement` في
  `{wallet_balance, whatsapp_link}`؛ الخصم داخل معاملة واحدة مع قيد
  `SELECT … FOR UPDATE` على صف الطلب، ورفض أي طلب `settlement_status` غير
  فارغ (منع الخصم المزدوج).
- `payment_link` يُصدره السيرفر عبر مزوّد مرخّص؛ التطبيق لا يبني روابط دفع.

### هـ. النقاط التي لا يمكن إثباتها من هذه البيئة

لا توجد في المستودع بيانات اعتماد إنتاج (حساب ضيف/مالك/فندق/أدمن)، ولا نسخة
staging. لذلك:

| البند | الحالة |
|---|---|
| اختبارات الشبكة الحيّة ضد الإنتاج | **غير مُنفَّذة** (17 اختبارًا متخطّاة عمدًا، تُشغَّل بـ `RUN_LIVE_TESTS=1`) |
| إثبات رفض السيرفر للوسائل المعطّلة عبر API مباشر | **غير مُثبت** — يحتاج curl على staging أو إنتاج |
| إصدار رابط دفع حقيقي | **غير مُنفَّذ** — يحتاج مزوّد دفع |
| بناء APK/AAB والتحقق على جهاز | **لم يُنفَّذ** — ممنوع محليًا؛ Codemagic لم يُشغَّل |

---

## 7. الملفات

**جديدة:** `lib/utils/service_request_store.dart`، `lib/utils/app_clock.dart`،
`test/service_request_status_test.dart`، `test/financial_safety_test.dart`،
`docs/FINAL_INTEGRATION_REPORT.md`.

**معدّلة:** `lib/screens/services/hotel_services_screen.dart`،
`lib/screens/services/service_request_screen.dart`،
`lib/services/hotel_service.dart`، `lib/services/api_client.dart`،
`lib/screens/booking/booking_screen.dart`، `lib/utils/app_strings.dart`،
`test/screenshot_support.dart`، `test/matrix_sync_test.dart`،
`tools/matrix_data.py`، `tools/gen_requirements_matrix.py`،
`docs/ALL_OWNERS_REQUIREMENTS_MATRIX.md`،
`docs/API_HANDOVER_AUTHORITATIVE.md`.

---

## 8. إعادة إنتاج النتائج

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
python3 tools/gen_requirements_matrix.py   # يعيد توليد مصفوفة الـ148
```

---

## 9. الحالة النهائية

| البند | الحالة |
|---|---|
| بوابات Flutter (format/analyze/test) | **خضراء** — 777 ناجح، 0 فاشل |
| اللقطات البصرية (157) | **مطابقة بلا تغيير** |
| المتطلب 59 (حالة الطلبات) | **Flutter مكتمل — السيرفر ناقص** |
| المتطلب 143 (إيراد الوحدة) | **Flutter مكتمل — السيرفر ناقص** |
| التحقق المالي (8 بنود) | **مكتمل على مستوى التطبيق** |
| فرض الوسائل المالية على السيرفر | **بانتظار مرحلة cPanel** |
| PR #1 | **مفتوح، Draft، غير مدموج** |
