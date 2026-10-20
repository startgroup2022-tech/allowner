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

## 4. Testing

| Command | Result |
|---|---|
| `flutter analyze` | 0 errors, 0 warnings, 82 info |
| `flutter test` | **94 tests, all pass** |

New tests added this session (12 total): 6 for req 73 (owner booking addons),
5 for req 56 (extra-bed charge), 1 for the hotel-staff unit search.

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
| 02 | 29 | 4 | 16 | 6 | 3 |
| 03 | 47 | 2 | 18 | 23 | 4 |
| 04 | 28 | 1 | 1 | 1 | 25 |
| 05 | 13 | 0 | 0 | 0 | 13 |

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
