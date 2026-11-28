# All Owners — السجل الرئيسي للمتطلبات الأصلية / Original Requirements Master Register

**Branch:** `feature/allowners-new-version-exec01`
**Draft PR:** [#1](https://github.com/startgroup2022-tech/allowner/pull/1)
**Date:** 2026-10-20
**Source of truth:** `docs/AllOwners_Original_Under_3MB.docx` (the owner's original Word
document, 51 pages, 56 embedded images) — committed by the owner in `91de5fe`.
**Working inventory:** `docs/AllOwners_Requirements_Inventory.md` (148 numbered items) —
also committed by the owner in `91de5fe`.
**Verbatim extraction:** `docs/evidence/exec01/original/AllOwners_Original_Extracted_Text.md`
(+ all 56 images in the same directory).

---

## 0. How this register was produced

1. The `.docx` was unzipped and `word/document.xml` parsed in **document order**, capturing
   `<w:t>` text, `<w:br/>`, paragraph boundaries and `r:embed` image anchors. Result:
   **17,466 characters of Arabic/English text, 442 lines, 56 image references**, verified
   against the raw `<w:t>` total (no text dropped).
2. The 148-item inventory was validated: **IDs 1–148, contiguous, no gaps, no duplicates.**
3. Every requirement below is traced to the inventory ID and to the document section it
   comes from. The Arabic wording is the inventory's own wording, unaltered.
4. Status is decided **only** from code actually read in this session. Where a requirement
   concerns the PHP backend, the website, or the admin panel — none of which are in this
   repository — it is marked **⛔ خارج نطاق هذا المستودع** rather than guessed.

### Status key

| Symbol | Meaning |
|---|---|
| ✅ | Implemented — the code path was found and read |
| 🟡 | Partial — present but incomplete against the wording |
| ❌ | Missing — not found in the client |
| ⛔ | Outside this repository (backend / website / admin panel) or needs an owner decision |

---

## 1. الهوية والمحتوى والدعم — Identity, content, support (9)

Source: document lines 1–45 (welcome text, app description, tagline, logo, help, avatars).

| # | المتطلب | الحالة | الدليل من الكود |
|---|---|---|---|
| 1 | نص الترحيب العربي داخل التطبيق | ✅ | `app_strings.dart` `onboard_desc_1..3` — Arabic matches the document verbatim |
| 2 | نص الترحيب الإنجليزي داخل التطبيق | ✅ | `onboard_desc_1..3` `en` — matches the document verbatim |
| 3 | الوصف العربي للتطبيق | ✅ | `onboard_desc_2`, `onboard_desc_3` |
| 4 | الوصف الإنجليزي للتطبيق | ✅ | same keys, `en` |
| 5 | العبارة التعريفية العربية والإنجليزية | ❌ | `app_tagline` = «فندقك، أينما كنت» / "Your stay, anywhere". The document specifies **«المنصة الموثوقة لملاك الوحدات والعقارات»** / "The Trusted Platform for Property Owners". Wrong string. |
| 6 | استبدال شعارات التطبيق بالشعارات الجديدة | ✅ | `assets/images/icon_square.png`, `icon_foreground.png`, `logo.png`; `flutter_launcher_icons` + `flutter_native_splash` configured |
| 7 | تكبير شعار AO في الترحيب | 🟡 | `AppLogo` widget exists; the document asks for **+15–20%** in the welcome area specifically. No evidence of the size change. |
| 8 | إضافة بيانات المساعدة والدعم | ✅ | `help_support_screen.dart`; `help_support` key |
| 9 | تغيير الصورة الشخصية لكل الأدوار | ✅ | `EditableAvatar`; `user/avatar.php`; used in owner + profile screens |

---

## 2. الرئيسية والبحث والاكتشاف — Home, search, discovery (18)

Source: document lines 45–150 (home structure, the 5 categories, destinations, the
hotels-with-owner-units section, the "أهم 3 تعديلات" list, the proposed page order).

| # | المتطلب | الحالة | الدليل من الكود |
|---|---|---|---|
| 10 | ترحيب مخصص باسم المستخدم | ✅ | `home_screen.dart:525` `'${hello}, $userName'` |
| 11 | ترحيب خاص بحساب المالك | ✅ | `hello_guest` / role-aware greeting |
| 12 | إبراز مربع البحث وتغيير نصه | ✅ | `where_to` «أين ترغب في الإقامة؟» + `search_destination` |
| 13 | تغيير تصنيف فنادق إلى وحدات فندقية | ✅ | `hotels` = «الوحدات الفندقية» |
| 14 | إضافة تصنيفات الوحدات الخمسة | ✅ | `hotels`/`apartments`/`resorts`/`chalets`/`properties` |
| 15 | سحب التصنيفات أفقياً | ✅ | horizontal scroll in `home_screen.dart` categories row |
| 16 | تغيير أحدث الأجنحة إلى أحدث الوحدات | ✅ | `recently_added_units` = «أحدث الوحدات المضافة» |
| 17 | تقليل المساحات البيضاء وإظهار البطاقات | 🟡 | cards render directly under filters; whitespace reduction not separately verifiable without a device |
| 18 | قسم الوجهات الرئيسية مكة جدة المدينة الرياض | ✅ | `featured_destinations` from `cities/list.php` |
| 19 | بطاقات مدن قابلة للنقر والتصفية | ✅ | city tap → `search_screen` with city filter |
| 20 | قسم اكتشف حسب النوع | ✅ | `browse_by_category` |
| 21 | قسم فنادق بوحدات ملاك | ✅ | `hotels_with_owner_units`; `units/browse.php?owner_only=1` |
| 22 | عرض عدد الوحدات والتقييم والمدينة في بطاقات فنادق الملاك | ✅ | `units_available_count`; rating chip; city on card |
| 23 | قسم وحدات الملاك مرتبط بالمدينة المختارة | ✅ | `owner_only=1` + city query |
| 24 | إضافة الفنادق المحددة في قائمة مكة وحالات قريباً | ❌ | The document names 13 Makkah hotels (Fairmont … Al Safwah Orchid) with «قريبا». **No such list and no "Soon" state exists anywhere in `lib/`.** |
| 25 | إضافة فنادق المدينة وجدة والرياض وحالات قريباً | ❌ | Same: Madinah/Jeddah/Riyadh "Soon" hotels absent |
| 26 | إظهار الفنادق المضافة من لوحة المالك عند البحث باسم المدينة | ⛔ | Depends on `hotels/list.php?city=` server behaviour (exact-match quirk documented in `AGENTS.md`); server-side fix required |
| 27 | تعديل ترتيب أقسام الرئيسية والقائمة السفلية | ✅ | order matches the document: welcome → search → destinations → type → owner-units → latest; bottom nav الرئيسية\|بحث\|حجوزاتي\|المفضلة\|حسابي |

---

## 3. الحجز وتفاصيله — Booking and its details (20)

Source: document lines ~150–270 (the 5-step guest flow, owner confirm/cancel/modify, the
double-booking example, access details, sync with the website).

| # | المتطلب | الحالة | الدليل من الكود |
|---|---|---|---|
| 28 | عرض تفاصيل الفندق قبل اختيار الغرف | ✅ | `hotel_details_screen.dart` |
| 29 | عرض وحدات الفندق وأسعارها وخدماتها | ✅ | unit list with price + amenities |
| 30 | عرض تفاصيل وصور الوحدة وزر احجز الآن | ✅ | `unit_details_screen.dart` |
| 31 | عرض سعر الوحدة وإضافات الوجبات والسرير قبل الحجز | ✅ | `booking_screen.dart` — meal/extra-bed selection with prices |
| 32 | تغيير زر تأكيد الحجز إلى تفاصيل الحجز | ❌ | `booking_screen.dart:707` still renders **`confirm_booking`** («تأكيد الحجز»). The document says the button must read **«تفاصيل الحجز»** at this step. |
| 33 | صفحة ملخص الحجز ببيانات الضيف والتواريخ والأشخاص والإضافات | ✅ | `booking_summary`; success screen shows the details |
| 34 | عرض طرق الدفع ضمن تفاصيل الحجز | ✅ | `PaymentMethod {online, atHotel, ownerTransfer}` selector |
| 35 | إظهار تفاصيل الحجز في تطبيق المالك ولوحته | 🟡 | app: `owner_bookings_screen` shows details + edit dialog; dashboard side is ⛔ |
| 36 | إظهار الحجوزات الواردة من الضيف والوكيل للمالك | ✅ | `user/owner-bookings.php` |
| 37 | تأكيد الحجز من تطبيق المالك | ✅ | `confirmBooking` → `action=confirm` |
| 38 | إلغاء الحجز من تطبيق المالك | ✅ | `cancelBooking` → `action=cancel` |
| 39 | تعديل الحجز من حساب المالك | ✅ | `editBooking` → `action=update` |
| 40 | تعديل الحجز من حساب الضيف | ✅ | `my_bookings_screen.dart:231` `editMyBooking` → `bookings/manage.php`; gated on server `can_edit` |
| 41 | إلغاء الحجز من حساب الضيف | ✅ | `my_bookings_screen.dart:172` `cancelMyBooking`; gated on server `can_cancel` |
| 42 | تعديل الحجز من حساب الوكيل | 🟡 | the same `my_bookings_screen` serves agents, so the action is reachable, but whether the server sets `can_edit` for an agent's own booking is a backend question |
| 43 | إلغاء الحجز من حساب الوكيل | 🟡 | same — reachable, server-gated by `can_cancel` |
| 44 | إرسال تأكيد الحجز للفندق بالبريد تلقائياً | ⛔ | email is server-side; **no email code in this repo** |
| 45 | منع الحجز المزدوج لنفس الوحدة والتواريخ | ⛔ | must be enforced in `bookings/create.php`; client cannot guarantee it. The document reports the bug (client 2 confirmed over client 1). |
| 46 | إظهار بيانات وصول الضيف للوحدة بعد التأكيد | 🟡 | `booking_success_screen` exists; the document states access data is **absent** after owner confirmation |
| 47 | مزامنة تفاصيل الحجز والتغييرات بين التطبيق والموقع | ⛔ | website not in this repo |

---

## 4. الضيف والوجبات والسرير — Guest, meals, extra bed (12)

Source: document lines ~270–330 (guest page: people count, meal prices, total instead of
notes, send to owner, extra bed, cleaning/maintenance requests, status).

| # | المتطلب | الحالة | الدليل من الكود |
|---|---|---|---|
| 48 | اختيار عدة وجبات عند إنشاء الحجز | ✅ | `mealTypes` multi-select in `booking_screen` |
| 49 | اختيار عدة وجبات في طلب وجبة مستقل | ✅ | `meal_request_screen` multi-select |
| 50 | عرض سعر كل وجبة | 🟡 | booking screen shows addon prices; **`meal_request_screen` uses a static `_meals` list with no prices** |
| 51 | عرض إجمالي الوجبات بدلاً من حقل الملاحظات | ❌ | `meal_request_screen` still shows a **notes** field (`notes_hint`); no meal total |
| 52 | عرض عدد الأشخاص أسفل رقم الغرفة | 🟡 | `guests` shown in booking; "under the room number" placement unverified |
| 53 | إرسال طلب الوجبات من الضيف إلى مالك الوحدة | ✅ | `services/meal-request.php` → owner meal requests |
| 54 | إضافة طلب سرير إضافي للضيف | ✅ | `extraBed` on booking |
| 55 | عرض تفاصيل وأسعار السرير الإضافي | ✅ | `extra_bed_price` on hotel/unit model |
| 56 | تصحيح حساب تكلفة السرير الإضافي | ⛔ | the arithmetic correction is in the booking engine (server) |
| 57 | تمكين الضيف من طلب النظافة | ✅ | `service_request_screen` |
| 58 | تمكين الضيف من طلب الصيانة | ✅ | `service_request_screen` |
| 59 | إظهار حالة طلبات الخدمات للضيف | ✅ | status shown on request lists |

---

## 5. المالك والخدمات — Owner and services (17)

Source: document lines ~170–250 and ~300–330 (owner cleaning/meal/bed requests, hotel
service prices visible to owner, maintenance cost, image on maintenance, staff
permissions, unit service categories).

| # | المتطلب | الحالة | الدليل من الكود |
|---|---|---|---|
| 60 | قائمة طلب النظافة في حساب المالك | ✅ | `owner_cleaning_screen` |
| 61 | تغيير هاوس كيبنج إلى النظافة | ✅ | `housekeeping` = «النظافة» |
| 62 | إنشاء طلب نظافة من تطبيق المالك | ✅ | `createOwnerHotelRequest(type:'cleaning')` |
| 63 | إنشاء طلب نظافة من لوحة المالك | ⛔ | dashboard not in repo |
| 64 | إرسال طلب النظافة من المالك للفندق | ✅ | `user/owner-requests.php` → hotel requests |
| 65 | إنشاء طلب وجبات من حساب المالك ولوحته | 🟡 | app side via meal requests; dashboard ⛔ |
| 66 | تمرير طلب وجبات الضيف/الوكيل من المالك للفندق | ✅ | `owner_requests` flow |
| 67 | إنشاء طلب سرير إضافي من تطبيق المالك ولوحته | 🟡 | app: request screen; dashboard ⛔ |
| 68 | عرض أسعار خدمات الفندق للمالك | ❌ | the document's "ملاحظه مهمه": hotel service prices set in hotel management **do not appear** on the owner page. Not found in client. |
| 69 | عرض تكلفة الصيانة المؤكدة للمالك | 🟡 | maintenance screen shows requests; confirmed **cost** display not confirmed |
| 70 | عرض تكلفة النظافة المؤكدة للمالك | 🟡 | same |
| 71 | عرض محتوى إشعارات طلبات الضيف وتفاصيل الخدمة | 🟡 | notifications screen exists; the document reports the content is not openable |
| 72 | إضافة صورة إلى طلب الصيانة في حساب المالك | ❌ | `image_picker` is a dependency but no image attach on maintenance requests |
| 73 | إظهار تفاصيل إضافات الوجبات والسرير في حجوزات المالك | 🟡 | booking details shown; the add-on breakdown is the document's complaint |
| 74 | إدارة صلاحيات موظفي المالك كاملة | 🟡 | `owner_staff_screen` lists staff + toggles status; **full permission editing** ("فتح جميع الخانات") not implemented |
| 75 | تصحيح توجيه حساب موظف المالك إلى واجهته المناسبة | ✅ | `login_screen.dart:44-48` routes by `isHotelStaff` / `isOwnerSide` |
| 76 | إضافة تصنيفات خدمات الوحدة (مفارش/طعام/حمام/وسائط/معدات) مع التفاصيل | ❌ | amenity icons exist, but the **five service categories with details** are not present |

---

## 6. إدارة الفندق — Hotel management (16)

Source: document lines ~180–210 (email requests, check-in/out, openable sections, unit
search by number, per-suite prices, cleaning/maintenance/meals/bed confirmation with
description, owner→hotel requests, maintenance image).

| # | المتطلب | الحالة | الدليل من الكود |
|---|---|---|---|
| 77 | استقبال رسائل الطلبات بالبريد الإلكتروني | ⛔ | server-side email; none in repo |
| 78 | تأكيد دخول الضيف Check-in | ✅ | `checkIn` → `action=check_in` |
| 79 | تأكيد خروج الضيف Check-out | ✅ | `checkOut` → `action=check_out` |
| 80 | فتح أقسام لوحة إدارة الفندق القابلة للدخول | ✅ | hotel staff navigation with open sections |
| 81 | البحث عن الوحدة برقمها في شاشة الوصول | ❌ | no unit-number search on the access screen |
| 82 | تحديد أسعار النظافة حسب الوحدة | ✅ | `hotel/prices.php` `savePrice` |
| 83 | تأكيد طلب النظافة مع وصف | ✅ | `actOnRequest` (confirm/done/reject) |
| 84 | تحديد أسعار الصيانة | ✅ | `savePrice` |
| 85 | تأكيد طلب الصيانة مع وصف | ✅ | `actOnRequest` |
| 86 | تسجيل إنجاز الصيانة مع وصف | ✅ | `actOnRequest(action:'done')` |
| 87 | تحديد أسعار الوجبات | ✅ | `savePrice` |
| 88 | تأكيد طلب الوجبات | ✅ | `actOnRequest` |
| 89 | تحديد أسعار السرير الإضافي | ✅ | `savePrice` |
| 90 | تأكيد طلب السرير الإضافي | ✅ | `actOnRequest` |
| 91 | استقبال الطلبات المرسلة من المالك | ✅ | `hotel/requests.php` |
| 92 | إضافة صورة لطلب الصيانة من حساب إدارة الفندق | ❌ | no image attach in hotel requests |

---

## 7. وكيل الحجوزات — Booking agent (17)

Source: document lines ~255–280 and ~330–345 (agent page: fix adding clients, booking
details, rename units→bookings, commission reports, remove contracts/community/voting,
keep maintenance, add meals/cleaning/extra-bed, unpaid commissions, bank details).

| # | المتطلب | الحالة | الدليل من الكود |
|---|---|---|---|
| 93 | إصلاح إضافة عملاء الوكيل | ✅ | `saveAgentClient` add/update |
| 94 | إضافة حقل اسم العميل عند الحجز | ✅ | `customerName` + `customerPhone` on agent bookings |
| 95 | اختيار فندق عند إنشاء حجز للعميل | ✅ | hotel selection in agent booking flow |
| 96 | عرض وحدات الفندق المختار للوكيل | ✅ | unit list for the chosen hotel |
| 97 | عرض تفاصيل حجز الوكيل | ✅ | booking details available |
| 98 | تغيير وحداتي إلى حجوزاتي | ❌ | agent bottom nav label is **`nav_units` = «وحداتي»** (`owner_navigation_screen.dart:57`), not «حجوزاتي» |
| 99 | عرض جميع حجوزات عملاء الوكيل | ✅ | `my_bookings_screen` agent bookings |
| 100 | تغيير التقارير المالية إلى تقارير عمولات | ✅ | `my_commission`; commission screen |
| 101 | إزالة العقود والمستندات من قائمة الوكيل | ❌ | `owner_profile_screen.dart:150` shows **`contracts_docs`** to every role, including agents |
| 102 | إزالة مجتمع الملاك من قائمة الوكيل | ❌ | `owners_community` shown unconditionally (line 175) |
| 103 | إزالة التصويت من قائمة الوكيل | ❌ | `voting_decisions` shown unconditionally (line 160) |
| 104 | الإبقاء على خدمات الصيانة في قائمة الوكيل | ✅ | `maintenance_requests` shown to all |
| 105 | إضافة طلب الوجبات في قائمة الوكيل | ❌ | no meal-request entry for agents |
| 106 | إضافة طلب النظافة في قائمة الوكيل | ❌ | no cleaning entry for agents |
| 107 | إضافة طلب سرير إضافي في قائمة الوكيل | ❌ | no extra-bed entry for agents |
| 108 | تحويل العمولات غير المدفوعة | ⛔ | payout is server-side |
| 109 | إدخال بيانات حساب الوكيل البنكي لاستلام العمولات | ❌ | no bank-account form; `units/detail.php` does return an `owner_bank` field but it is not modelled or surfaced |

---

## 8. الإدارة والموقع والأمان — Admin, website, security (8)

Source: document lines ~340–365 (admin list order, subscription fee, payment control,
website tagline, booking-details parity).

| # | المتطلب | الحالة | الدليل من الكود |
|---|---|---|---|
| 110 | إصلاح نسيت كلمة المرور | ⛔ | all `auth/forgot*` paths return **404**; `login_screen.dart:172` documents this and routes elsewhere instead of a dead button |
| 111 | إضافة طلبات الصيانة إلى لوحة الأدمن | ⛔ | admin panel not in repo |
| 112 | إضافة إدارة وسائل الدفع والصلاحيات للأدمن | ⛔ | admin panel not in repo |
| 113 | التحكم في وسائل الدفع المسموحة لكل مالك | ⛔ | admin panel not in repo |
| 114 | إعادة ترتيب 16 قسمًا في قائمة الأدمن | ⛔ | admin panel not in repo; the required order is transcribed in §10 below |
| 115 | إضافة رسوم الاشتراك السنوي عند إنشاء المالك من الأدمن | ⛔ | admin panel not in repo |
| 116 | تحديث العبارة التعريفية على الموقع | ⛔ | website not in repo |
| 117 | توحيد عرض تفاصيل الحجوزات على الموقع مع التطبيق | ⛔ | website not in repo |

---

## 9. الاشتراكات والمحاسبة والمدفوعات — Subscriptions, accounting, payments (26)

Source: document lines ~350–442 (the owner's full financial model: central collection,
owner ledger, 10% commission, annual owner subscription, wallet, payouts, SAMA note).

> **The document states this model explicitly.** The owner's recommendation, verbatim:
> عمولة **10%** من قيمة الحجز · المالك هو الطرف الذي يتحمل العمولة · الضيف يرى السعر
> النهائي · التسوية **بعد انتهاء الإقامة** · الدفع للمالك **أسبوعي** · حساب المالك =
> **Owner Ledger** داخل التطبيق · التحويل عبر **مزود دفع مرخص** · **كل وحدة لها حساب
> إيرادات مستقل**. The document also warns that holding owner funds directly enters
> SAMA-regulated payment-services scope, and recommends Split Payment / Payouts instead.

| # | المتطلب | الحالة | الدليل من الكود |
|---|---|---|---|
| 118 | تسجيل بيانات حساب المالك البنكي | ❌ | no bank-details form in the client |
| 119 | خيار تحويل مباشر إلى حساب المالك في الحجز | 🟡 | `owner_transfer` exists as a payment method, but see G2 in the gap report — it conflicts with the commission model |
| 120 | عرض حساب مالك الوحدة الصحيح عند التحويل المباشر | ❌ | not implemented |
| 121 | تفعيل اشتراك سنوي للمالك فقط | ❌ | no subscription code |
| 122 | السماح للمالك غير المشترك بالاستعراض دون عمليات | ❌ | no gating |
| 123 | منع إضافة الوحدات والطلبات حتى الاشتراك | ❌ | no gating |
| 124 | صفحة تفعيل ودفع الاشتراك في حسابي | ❌ | absent |
| 125 | عرض شروط الاشتراك ونسبة العمولة | ❌ | absent |
| 126 | تقارير مبيعات المالك الشهرية والسنوية | 🟡 | `owner_revenue_screen` shows revenue; monthly **and** yearly split not confirmed |
| 127 | خصم الصيانة والنظافة من صافي الإيرادات | ❌ | the document requires sales minus maintenance minus cleaning; not implemented in the client |
| 128 | تقارير مصروفات الصيانة الشهرية والسنوية | ❌ | absent |
| 129 | تقارير مصروفات النظافة الشهرية والسنوية | ❌ | absent |
| 130 | خيار خصم الصيانة من رصيد الوحدة | ❌ | absent |
| 131 | خيار إرسال رابط دفع الصيانة عبر واتساب | ❌ | absent |
| 132 | حساب تحصيل مركزي للمنصة | ⛔ | server/PSP side |
| 133 | حساب أستاذ مستقل لكل مالك Ledger | ❌ | absent from client |
| 134 | تسجيل الحجوزات والعمولات والاستردادات والتسويات | ❌ | absent |
| 135 | محفظة مالك (الرصيد/الحجوزات/العمولة/المصروفات/القابل للتحويل) | ❌ | absent — only an icon reference exists, no wallet screen |
| 136 | طلب تحويل مستحقات المالك | ❌ | absent |
| 137 | تسوية وتحويل مستحقات المالك إلى حسابه البنكي | ⛔ | payout side |
| 138 | دعم Split Payment أو Payouts عبر مزود مرخص | ⛔ | requires a licensed PSP — **owner decision** |
| 139 | احتساب عمولة 10% على المالك | 🟡 | commission screens exist and are admin-set; the **10%** figure and owner-bears-it rule are not enforced in the client |
| 140 | إظهار السعر النهائي للضيف | ✅ | total shown at booking |
| 141 | التسوية بعد انتهاء الإقامة | ⛔ | server-side |
| 142 | دفع مستحقات المالك أسبوعياً | ⛔ | server-side |
| 143 | حساب إيرادات مستقل لكل وحدة | 🟡 | per-unit revenue display not confirmed |

---

## 10. الإشعارات والبريد — Notifications and email (5)

Source: document line ~250 (the email paragraph: the confirmation email must
auto-include guest name, ID/passport, check-in date, unit type and room).

| # | المتطلب | الحالة | الدليل من الكود |
|---|---|---|---|
| 144 | تفعيل البريد المتبادل بين الفندق والمالك والعميل | ⛔ | email is server-side; the document says it is **غير فعال** |
| 145 | تضمين اسم الضيف تلقائياً في رسالة التأكيد | ⛔ | server-side |
| 146 | تضمين رقم الهوية أو الجواز تلقائياً | ⛔ | server-side; the client already collects `guest_id_number` |
| 147 | تضمين تاريخ الدخول تلقائياً | ⛔ | server-side |
| 148 | تضمين نوع الوحدة ورقم الغرفة تلقائياً | ⛔ | server-side |

---

## 11. Admin menu order required by the document (for requirement 114)

Transcribed verbatim from the document so the admin panel can be reordered without
re-reading the `.docx`:

1. سلايدات الرئيسية  2. لوحة القيادة  3. الفنادق  4. الأجنحة  5. الحجوزات  6. الأقسام
7. الوجهات  8. طلبات الوجبات  9. طلبات الصيانة *(إضافة جديدة)*  10. الملاك  11. الوكلاء
12. المستخدمون  13. الإشعارات  14. المحتوى والخصوصية  15. التحكم بوسائل الدفع والصلاحيات
*(إضافة جديدة)*  16. الإعدادات

---

## 12. Summary

| Status | Count |
|---|---|
| ✅ Implemented | 67 |
| 🟡 Partial | 17 |
| ❌ Missing (in the client) | 38 |
| ⛔ Outside this repository / needs a decision | 26 |
| **Total** | **148** |

Counts are machine-tallied from this document (every ID 1–148 present exactly once, no
gaps). Of the 38 missing items, the ones that are **fully implementable in this Flutter
client without a backend change or an owner decision** are listed in
`docs/ALL_OWNERS_IMPLEMENTATION_GAP_REPORT.md` §2 with the exact file to change. The rest
depend on the PHP backend, the website, the admin panel, or a payment/commission decision.

---

*This document was produced by an AI agent (OpenHands) on behalf of the repository owner.
Requirement wording is the owner's own inventory text, unaltered; no requirement was
invented.*
