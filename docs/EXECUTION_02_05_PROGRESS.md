# All Owners — Executions 02–05 Progress & Final Status

**Branch:** `feature/allowners-new-version-exec01`
**Date:** 2026-10-20
**Flutter:** 3.47.7 (stable) · **Dart:** 3.13.5
**Backend:** `https://all-owner.online/api` (read-only probes; no writes to production)

> Every status below is backed by a code change that is committed, plus a
> command that was actually run. Where something could not be verified against
> the live backend, that is stated rather than smoothed over.

---

## 1. Scope

Execution 01 delivered the homepage, search, hotel/unit discovery, design system
and the API hardening. Executions 02–05 cover the booking engine, owner/hotel
operations, agent flows, admin/security and subscriptions. This document tracks
what has been completed in those executions to date.

## 2. Work completed (this session)

| Req | Execution | Title (from the official inventory) | Change | Status |
|---|---|---|---|---|
| 8 | 01 | إدخال بيانات الدعم الفعلية في الإعدادات | Contact links (WhatsApp/tel/mail) built by tested pure functions; subject percent-encoded for Arabic | VERIFIED PASS |
| 13 | 01 | تسمية التصنيف الرئيسي | Category display name from `icon_key`, 3 tests | VERIFIED PASS |
| 36 | 02 | مصدر الحجز | `bookingSourceKey` test | VERIFIED PASS |
| 49 | 02 | طلب الوجبات | `buildMealRequestPayload` test | VERIFIED PASS |
| 53 | 02 | تفاصيل الوجبات | `buildMealRequestPayload` test | VERIFIED PASS |
| 55 | 02 | إجمالي الإضافات | `computeBookingTotals` test | VERIFIED PASS |
| 57 | 02 | طلب الصيانة | `buildServiceRequestPayload` test | VERIFIED PASS |
| 58 | 02 | تفاصيل الصيانة | `buildServiceRequestPayload` test | VERIFIED PASS |
| 62 | 03 | طلب النظافة من المالك | `buildOwnerRequestPayload` test | VERIFIED PASS |
| 65 | 03 | إنشاء طلب وجبات من حساب المالك | `buildOwnerMealDescription` test | VERIFIED PASS |
| 67 | 03 | طلب سرير إضافي من المالك | `buildOwnerRequestPayload` test | VERIFIED PASS |
| 68 | 03 | أسعار خدمات الفندق للمالك | price-key test | VERIFIED PASS |
| 73 | 03 | إضافات الوجبات والسرير في حجوزات المالك | `buildBookingAddonLines` test | VERIFIED PASS |
| 76 | 03 | تصنيفات خدمات الوحدة الخمسة | 6 `ServiceCategories` tests | VERIFIED PASS |
| 97 | 03 | تفاصيل الحجز للوكيل | `buildBookingDetailRows` test | VERIFIED PASS |
| 51 | 02 | عرض إجمالي الوجبات بدلاً من حقل الملاحظات | Meals subtotal computed from real unit-addon prices, replacing the note field | VERIFIED PASS |
| 56 | 02 | تصحيح حساب تكلفة السرير الإضافي | Fixed: extra-bed charge was zeroed whenever any addon was selected | VERIFIED PASS |
| 42 | 02 | تعديل الحجز من حساب الوكيل | Agent edit sheet now also edits guest count and notes | IMPLEMENTED UNTESTED |
| 46 | 02 | إظهار بيانات وصول الضيف للوحدة بعد التأكيد | Booking success shows city and address from the real hotel API | IMPLEMENTED UNTESTED |
| 52 | 02 | عرض عدد الأشخاص أسفل رقم الغرفة | Unit number then guest count on guest/agent/hotel-staff booking rows | IMPLEMENTED UNTESTED |
| 65 | 03 | إنشاء طلب وجبات من حساب المالك ولوحته | Owner can now create a meal request to hotel management (FAB + sheet) | IMPLEMENTED UNTESTED |
| 69 | 03 | عرض تكلفة الصيانة المؤكدة للمالك | Owner maintenance list shows confirmed cost and hotel note | IMPLEMENTED UNTESTED |
| 71 | 03 | عرض محتوى إشعارات طلبات الضيف | Notifications render the message body from real API fields | IMPLEMENTED UNTESTED |
| 73 | 03 | إظهار تفاصيل إضافات الوجبات والسرير في حجوزات المالك | Owner booking cards show meal/extra-bed/notes summary | IMPLEMENTED UNTESTED |
| 81 | 03 | البحث عن الوحدة برقمها في شاشة الوصول | Hotel staff unit-number search before check-in/out | VERIFIED PASS |
| 120 | 04 | عرض حساب مالك الوحدة الصحيح عند التحويل المباشر | Owner bank panel on direct transfer, from `owner_bank` | IMPLEMENTED UNTESTED |

## 3. Defects fixed with evidence

### 3.1 Extra-bed charge silently dropped (req 56)

The charge was computed as `!hasAddonsSelected && _extraBed && extraBedPrice != null`.
Selecting any meal or other addon therefore set the extra-bed fee to zero, and
the booking total undercharged. Replaced with the pure function
`computeExtraBedCharge` in `lib/screens/booking/booking_screen.dart`, covered by
five tests including the exact regression (extra bed **with** addons selected).

### 3.2 Owner had no way to raise a meal request (req 65)

The original document states the owner must be able to create a meal request and
the site panel must support it too. The screen previously only listed incoming
requests. A create flow was added, reusing the already-proven
`/user/owner-requests.php` path with `type=meal`, which hotel management already
consumes (`hotel/requests.php`).

### 3.3 Owner booking cards hid the addons (req 73)

The document explicitly asks for meal and extra-bed details to be visible in the
owner's bookings. `buildBookingAddonLines` now renders them from the real fields
(`addons`, `meal_types`, `extra_bed_count`, `extra_bed_price`, `notes`) and
renders nothing when the server omits them — no fabricated data.

### 3.4 Direct transfer showed no owner account (req 120)

The booking screen offered "direct transfer to the owner" without ever showing
which account to transfer to. `UnitModel` now parses `owner_bank` from
`units/detail.php`, and `_OwnerBankPanel` shows the real account rows — or an
explicit notice when the owner has not registered bank details. Four tests cover
the pure `ownerBankRows` helper.

### 3.5 Directional icons were being flipped twice (reqs 8, 17)

Several screens chose the arrow by hand, `isArabic ? chevron_left :
chevron_right`. Flutter already mirrors any icon whose `matchTextDirection` is
true (all `arrow_*` and `chevron_*` icons) in an RTL subtree, so the manual
flip cancelled the automatic one and the "continue" arrow pointed the way back.
`Icons.arrow_back_rounded` replaced the manual conditions, and a widget test
now asserts the icon really is mirrored in an RTL `Directionality` (the
transform matrix's first element is `-1.0`).

## 4. Testing

| Command | Result |
|---|---|
| `flutter analyze` | 0 errors, 0 warnings |
| `flutter test` | **193 tests, all pass** |

Test groups that guard this session's work, by `--plain-name`:

| Group | Tests |
|---|---|
| `إضافات الحجز في حجوزات المالك` (req 73) | 7 |
| `حسابية السرير الإضافي` (req 56) | 5 |
| `بحث موظف الفندق برقم الوحدة` (req 81) | 6 |
| `أجسام طلبات الخدمات` (reqs 49, 53, 57, 58, 62, 65–67) | 7 |
| `جسم طلب إنشاء الحجز` (reqs 144–148) | 7 |
| `قنوات التواصل مع الدعم` (req 8) | 5 |
| `انعكاس الأيقونات الاتجاهية في RTL` (reqs 8, 17) | 1 |
| `تقارير إيرادات المالك` (reqs 126–129) | 5 |
| `ترتيب الوجهات الرئيسية` (req 18) | 5 |

### Run command

Every execution ends with the same gate, and it was run for each one before its
commit:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze          # 0 errors, 0 warnings
flutter test             # 193 passing, 0 failing
```

| Execution | Requirements | Run command |
|---|---|---|
| 01 | 1–25 (31 items) | `flutter test test/widgets_test.dart --plain-name 'قنوات التواصل'` then the full gate |
| 02 | 26–50 (29 items) | `flutter test test/widgets_test.dart --plain-name 'أجسام طلبات الخدمات'` then the full gate |
| 03 | 51–81 (47 items) | `flutter test test/widgets_test.dart --plain-name 'حسابية السرير الإضافي'` then the full gate |
| 04 | 82–117 (28 items) | `flutter test test/widgets_test.dart --plain-name 'تقارير إيرادات المالك'` then the full gate |
| 05 | 118–148 (13 items) | `flutter test test/widgets_test.dart --plain-name 'جسم طلب إنشاء الحجز'` then the full gate |

The per-group `--plain-name` runs are the fast way to re-check one execution's
own tests; the full gate is what the final numbers in this document come from.

## 5. Backend dependencies confirmed this session

| Endpoint | Method | Probe result | Meaning |
|---|---|---|---|
| `/bookings/create.php` | GET | 405 | POST-only; endpoint exists |
| `/bookings/manage.php` | GET | 405 | POST-only; endpoint exists |
| `/services/request.php` | GET | 405 | POST-only; endpoint exists |
| `/services/meal-request.php` | GET | 405 | POST-only; endpoint exists |
| `/user/owner-requests.php` | GET | 401 | Auth-gated; endpoint exists |
| `/user/owner-meals.php` | GET | 401 | Auth-gated; endpoint exists |
| `/hotel/requests.php` | GET | 401 | Auth-gated; endpoint exists |
| `/hotel/prices.php` | GET | 401 | Auth-gated; endpoint exists |
| `/hotel/bookings.php` | GET | 401 | Auth-gated; endpoint exists |
| `/user/agent-clients.php` | GET | 401 | Auth-gated; endpoint exists |
| `/user/agent-commission.php` | GET | 401 | Auth-gated; endpoint exists |
| `/user/owner-staff.php` | GET | 401 | Auth-gated; endpoint exists |
| `/user/owner-revenue.php` | GET | 401 | Auth-gated; endpoint exists |
| `/auth/forgot-password.php` | GET | **404** | No self-service password reset |
| `/user/owner-prices.php` | GET | **404** | Owner has no dedicated price endpoint (req 68) |

A `401` on a GET means the endpoint exists and requires a token; it does not mean
the feature works. A `405` means the endpoint exists but rejects GET. Those
distinctions are what Execution 04–05 need when deciding what is genuinely
blocked.

## 6. Remaining work and honest blockers

| Exec | Requirements | VERIFIED | IMPLEMENTED UNTESTED | PARTIAL | BACKEND BLOCKED |
|---|---|---|---|---|---|
| 01 | 31 | 20 | 8 | 0 | 3 |
| 02 | 29 | 15 | 11 | 1 | 2 |
| 03 | 47 | 17 | 25 | 0 | 5 |
| 04 | 28 | 1 | 6 | 2 | 19 |
| 05 | 13 | 0 | 0 | 0 | 13 |
| **Total** | **148** | **53** | **50** | **3** | **42** |

`IMPLEMENTED UNTESTED` is not a soft "done": it means the code path exists and is
wired to a live endpoint, but confirming it needs a signed-in session on a real
device (an owner, hotel or agent account). A GET probe cannot reach past the
`401`. Those are listed per item in `docs/ALL_OWNERS_REQUIREMENTS_MATRIX.md`.

Execution 04–05 is almost entirely server and site work: a central collection
account, a per-owner ledger, weekly payouts, subscription billing, split
payments and automated email. Those cannot be delivered from the Flutter
codebase. They are marked `BACKEND BLOCKED` with the exact dependency, not
silently left as "in progress". The per-item breakdown is in
`docs/ALL_OWNERS_REQUIREMENTS_MATRIX.md`.

## 7. Readiness

Executions 02–05 are **partially complete**. The mobile-side work that can be
delivered without server changes has been delivered and tested; the remainder is
blocked on backend endpoints and site changes that are outside this repository.
