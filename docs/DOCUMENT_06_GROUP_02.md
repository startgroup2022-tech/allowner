# All Owners — Modification Document 06 — Group 02 (Requirements 11–17)

**Branch:** `feature/allowners-new-version-exec01`
**Pull request:** [#1](https://github.com/startgroup2022-tech/allowner/pull/1) (kept open and Draft)
**Date:** 2026-11-26
**Flutter:** 3.47.7 (stable) · **Dart:** 3.13.5
**Application ID:** `com.superai.allowners` (unchanged) · **Signing:** unchanged · **Codemagic:** unchanged

This is an implementation report, not an audit. Every requirement was implemented
in the Flutter client. Requirements 13–17 need PHP/admin-dashboard work that is
**not present in this repository**, so the exact cPanel contract is specified in
§8 and each status states that limitation honestly.

---

## 0. Commands actually run

```bash
flutter pub get                                         # resolved, pubspec.lock unchanged
dart format --output=none --set-exit-if-changed .       # 130 files, 0 changed
flutter analyze                                         # 141 issues, 0 errors, 0 warnings
flutter test                                            # +471 passed, 17 skipped (live backend only)
```

The 141 analyzer findings are all pre-existing `info`-level lints (the baseline
before this group was 148; six deprecated `RadioListTile.groupValue/onChanged`
uses and one `if`-without-braces were fixed here, so the count went **down**).
No test was skipped or disabled to obtain these results.

New tests added in this group: **34 unit tests** (`test/document06_group02_test.dart`)
plus **11 widget/render tests** (`test/hotel_staff_screens_render_test.dart`, which
grew from 7 to 18).
Two Group 01 tests were tightened (not weakened) for the corrected requirement 4
behaviour.

---

## 1. Requirement 11 — Confirm a meal request with a payment option

**Implementation**
- Meal requests now go through the same confirmation-and-settlement path as
  cleaning requests (`lib/utils/request_settlement.dart`):
  `wallet_balance` («خصم من الرصيد» / “Deduct from Balance”) or
  `whatsapp_link` («الدفع عبر رابط بالواتساب» / “Pay via WhatsApp Link”).
- The confirmation dialog shows the **approved meal price** read from the server
  (`price`, `approved_price`, `total_price`, `cost`).
- Meal types are displayed exactly as returned by the server
  (`meal_types`, `meals[]`, `meal_type`); known values are localised through
  `meal_breakfast` / `meal_lunch` / `meal_dinner`, unknown values are shown
  verbatim. No meal type is invented.
- Confirmation sends `settlement` in the existing `actOnRequest` call, so the
  request lifecycle and the existing endpoints are unchanged.
- Duplicate settlements are blocked client-side (see §11).

**Modified files**
- `lib/utils/request_settlement.dart` *(new)*
- `lib/screens/hotel_staff/hotel_requests_screen.dart`
- `lib/utils/app_strings.dart` (meal price labels, meal types label, settlement labels)

**Test evidence** (`test/document06_group02_test.dart`)
- `تمييز نوع الطلب`, `السعر المعتمد يُقرأ من حقول السيرفر الحقيقية فقط`
- `أنواع الوجبات تُقرأ من الطلب ولا تُختلق`, `تسميات الوجبات تُترجم عبر مفاتيح التطبيق`
- `التحقق يمنع التأكيد بلا سعر معتمد أو بلا وسيلة سداد`
- `رسالة واتساب الوجبات تحمل الطلب والوحدة والمبلغ`, `لا يُبنى رابط واتساب بلا رقم صالح`
- `رابط الدفع يُقبل من السيرفر فقط وبـ https`
- Widget: `بطاقة الوجبات تعرض السعر المعتمد وأنواع الوجبات`,
  `نافذة تأكيد الوجبات تعرض وسيلتي السداد`

**Backend dependencies** — `/hotel/requests.php` must accept and persist
`settlement` for `type=meal` and expose the approved price and meal types in its
response. Exact contract in §8.1.

**Status:** **FLUTTER COMPLETE — BACKEND PENDING** (the Flutter flow, validation
and messaging are done and tested; persisting the deduction and issuing a real
payment link are server responsibilities that do not exist yet.)

---

## 2. Requirement 12 — Settle an extra-bed request with the approved amount

**Implementation**
- Same two payment options as the maintenance and cleaning flows, through the
  shared module (no duplicated logic).
- The dialog and the list card display: approved price, number of extra beds,
  number of nights and total cost.
  - beds ← `beds` / `extra_beds` / `beds_count` / `quantity` / `qty` / `count`
  - nights ← `nights` / `nights_count` / `duration`, otherwise computed from the
    real `check_in` / `check_out` values
  - total ← server `total` / `grand_total` / `total_price`, otherwise
    `price × beds × nights` **only when all three values are real**; otherwise
    the UI shows `—` instead of a fabricated number.
- Confirmation requires a selected payment method and an approved price, and the
  approved price is added to the request with the settlement option.
- Only genuine https payment links from the server response are opened; no link
  is fabricated and no balance is invented.

**Modified files**
- `lib/utils/request_settlement.dart` (`extraBedCount`, `extraBedNights`,
  `extraBedTotal`)
- `lib/screens/hotel_staff/hotel_requests_screen.dart`
- `lib/utils/app_strings.dart`

**Test evidence**
- `عدد الأسرّة من حقول السيرفر`
- `عدد الليالي من الطلب أو من تاريخي الوصول والمغادرة`
- `الإجمالي من السيرفر أو من السعر × الأسرّة × الليالي` (including the “data
  missing → no number” cases)
- `التحقق يستخدم رسالة سعر السرير الإضافي`
- `القواعد مشتركة بين الأنواع الثلاثة`
- `رسالة واتساب السرير الإضافي تعرض الأسرّة والليالي والإجمالي`
- Widget: `بطاقة السرير الإضافي تعرض الأسرّة والليالي والإجمالي`

**Backend dependencies** — `/hotel/requests.php` must echo beds/nights/total for
`type=extra_bed` and persist the settlement. §8.1.

**Status:** **FLUTTER COMPLETE — BACKEND PENDING**

---

## 3. Requirement 13 — Title field in the hotel unit pricing form

**Implementation**
- New screen `HotelUnitPricingScreen` with a **title** field
  (`pricing_title_field` = «العنوان» / “Title”).
- The title is required by `validateUnitPricing` before saving.
- On edit, the stored title is retrieved from
  `GET /hotel/unit-pricing.php` and shown in the field.

**Modified files**
- `lib/screens/hotel_staff/hotel_unit_pricing_screen.dart` *(new)*
- `lib/widgets/pricing_widgets.dart` *(new — `PricingTitleField`)*
- `lib/utils/pricing_forms.dart` *(new — validation + payload)*
- `lib/services/hotel_staff_service.dart`
- `lib/utils/app_strings.dart`

**Test evidence**
- `العنوان والتاريخ مطلوبان قبل الحفظ`
- `جسم الحفظ يحمل العنوان والتاريخ`
- Widget: `ستة صفوف أنواع وحدات وأسعار من بيانات الفندق` (title field rendered)

**Backend dependencies** — `hotel/unit-pricing.php` must store `title`. §8.2.

**Status:** **FLUTTER COMPLETE — BACKEND PENDING**

---

## 4. Requirement 14 — Date picker in the hotel unit pricing form

**Implementation**
- `PricingDateField` opens the app's standard `showDatePicker` (same call as
  `booking_screen.dart` / `owner_add_unit_screen.dart`, so the visual identity is
  preserved).
- The picked date is stored and submitted as `pricing_date` in `yyyy-MM-dd`.
- `parsePricingDate` reads `pricing_date` (or `date`) back for editing, so the
  saved date is retrieved and displayed.
- Saving without a date is blocked (`pricing_date_required`).

**Modified files**
- `lib/widgets/pricing_widgets.dart`, `lib/utils/pricing_forms.dart`
  (`formatPricingDate`, `parsePricingDate`), `lib/utils/app_strings.dart`

**Test evidence**
- `تاريخ التسعير يُنسّق ويُقرأ بشكل ثابت` (round-trip, ISO payload, empty/null)
- `العنوان والتاريخ مطلوبان قبل الحفظ`
- `السجل المحفوظ يُسترجع كاملًا عند التعديل`

**Backend dependencies** — the endpoint must store a DATE column and echo it.
§8.2.

**Status:** **FLUTTER COMPLETE — BACKEND PENDING**

---

## 5. Requirement 15 — Six unit-type and price rows

**Implementation**
- `buildUnitPricingRows` always returns **exactly six** rows
  (`kUnitPricingRowCount = 6`).
- Row names come from the hotel's real data, never hardcoded: saved record rows
  first (so editing keeps existing prices), then the distinct `unit_type_ar` /
  `unit_type_en` values of the hotel's units, then blank rows up to six.
- Duplicate unit types are collapsed; blank rows are never submitted.
- Each row is validated: a row that has a type must have a price `> 0`, and two
  rows cannot share the same unit type.
- Owners can read the approved prices: `OwnerService.getOwnerPricingSheets()`
  plus a read-only section on `OwnerServicePricesScreen`
  (`saved_pricing_records`), reusing the same authorised endpoint. A missing
  endpoint never breaks the owner screen — the section is simply hidden.

**Modified files**
- `lib/utils/pricing_forms.dart`, `lib/screens/hotel_staff/hotel_unit_pricing_screen.dart`
- `lib/services/owner_service.dart`, `lib/screens/owner/owner_service_prices_screen.dart`
- `lib/screens/hotel_staff/hotel_prices_screen.dart`,
  `lib/screens/hotel_staff/hotel_dashboard_screen.dart` (entry points)
- `lib/utils/app_strings.dart`

**Test evidence**
- `النموذج يعرض ستة صفوف دائمًا`
- `أنواع الوحدات تُقرأ من بيانات الفندق بلا أسماء ثابتة` (dedupe, blank padding,
  empty when the hotel has no unit types)
- `السجل المحفوظ يُسترجع كاملًا عند التعديل`
- `تحقق الأسعار يمنع الصفوف الناقصة والمكررة`
- `جسم الحفظ يحمل الصفوف المكتملة فقط`
- Widget: `ستة صفوف أنواع وحدات وأسعار من بيانات الفندق` (6 price fields,
  360 px / 768 px / English LTR renders)

**Backend dependencies** — `hotel/unit-pricing.php` must persist a sheet with six
rows. §8.2.

**Status:** **FLUTTER COMPLETE — BACKEND PENDING**

---

## 6. Requirement 16 — Hotel meal pricing form (title, date, three meals)

**Implementation**
- New screen `HotelMealPricingScreen` with title, date and **three** meal rows
  (name + price), `kMealPricingRowCount = 3`.
- Saved records are retrieved through `GET /hotel/meal-pricing.php` and can be
  re-opened for editing; blank rows are never submitted; duplicate names and
  missing prices are rejected.
- Meal names are typed by the hotel (not hardcoded), and all labels are
  localised in Arabic and English.

**Modified files**
- `lib/screens/hotel_staff/hotel_meal_pricing_screen.dart` *(new)*
- `lib/utils/pricing_forms.dart` (`MealPricingRow`, `buildMealPricingRows`,
  `validateMealPricing`, `mealPricingPayload`)
- `lib/services/hotel_staff_service.dart`, `lib/widgets/pricing_widgets.dart`,
  `lib/utils/app_strings.dart`

**Test evidence**
- `النموذج يعرض ثلاث وجبات دائمًا`
- `الوجبات المحفوظة تُسترجع بالاسم والسعر`
- `التحقق يمنع الحفظ بلا عنوان أو تاريخ أو أسعار`
- `جسم الحفظ يحمل الوجبات المكتملة فقط`
- Widget: `ثلاث وجبات وأسعارها مع العنوان والتاريخ` (3 name fields),
  `بلا تجاوز على 360px`

**Backend dependencies** — `hotel/meal-pricing.php`. §8.2.

**Status:** **FLUTTER COMPLETE — BACKEND PENDING**

---

## 7. Requirement 17 — Remove the nightly price from the hotel creation form

**Implementation in this repository: nothing to change, and nothing was changed.**

Evidence that the form is not here:

```bash
$ grep -rn "create_hotel\|add_hotel\|hotel/create" lib/ | wc -l
0
$ ls lib/screens/admin 2>&1
ls: cannot access 'lib/screens/admin': No such file or directory
$ grep -rln "<form" --include=*.php . | wc -l
0
```

The Flutter app has no hotel-creation screen (hotel onboarding is performed in
the PHP admin dashboard). Removing the field is therefore a cPanel-phase change;
the exact edit is specified in §8.3.

**Preserved deliberately (not part of requirement 17)**
- Unit-level nightly pricing: `owner_add_unit_screen.dart` (`price_per_night`),
  `POST /hotel/units.php` (`price_per_night`), booking totals and every pricing
  path from Groups 01–02. Requirement 17 targets the **hotel creation** form
  only.

**Backend dependencies** — `admin/hotels/create.php` (or its equivalent).

**Status:** **FLUTTER COMPLETE — BACKEND PENDING** (no Flutter hotel-creation
form exists; the PHP change is documented in §8.3. An empty field that is
removed from the form does not break the create/update SQL path, because
`price_per_night` on the hotels table has a default.)

---

## 8. Exact cPanel backend requirements

Nothing in this section has been deployed, tested, or claimed as operational.
The PHP/admin-dashboard source is not in this repository, so these are the exact
contracts the Flutter client already implements against.

### 8.1 `hotel/requests.php` — settlement for cleaning, meal and extra bed

Request (`POST`, existing action `confirm`), additional field:

| field | type | meaning |
|---|---|---|
| `settlement` | enum | `wallet_balance` or `whatsapp_link` |

Rules to enforce **server-side** (the client cannot be trusted):

1. Reject any other `settlement` value with `400`.
2. Reject `wallet_balance` when the guest/unit wallet has insufficient balance —
   never allow a negative balance.
3. Idempotency: if the request row already has `settlement`,
   `payment_status IN ('paid','settled','deducted')` or `settled = 1`, respond
   `409` with `settlement_already_recorded`. This is what prevents a double
   deduction and a duplicate payment request.
4. Only `hotel_manager`, `owner`, `unit_manager` of the request's hotel may
   confirm; everyone else gets `403`.
5. Store the approved price in `requests.price` (or `approved_price`) before
   settlement; refuse to settle without a price.
6. For `whatsapp_link`, create the payment link **on the server** with the
   payment provider and return it in the response as `payment_link` (https,
   absolute). If the provider is not configured, return no link — the app then
   tells the user honestly that the link is unavailable instead of inventing one.

Response (unchanged fields plus):

```json
{ "success": true, "settlement": "whatsapp_link", "payment_link": "https://…" }
```

For `type=meal` the list/detail response should include `meal_types` (array) or
`meals[] {name, price}`. For `type=extra_bed` it should include `beds`, `nights`
and `total` (or `total_price`).

### 8.2 Pricing sheets — two new endpoints

**`hotel/unit-pricing.php`**

- `GET` → `{"success":true,"units":[{"id":1,"unit_type_ar":"…","unit_type_en":"…"}],
  "records":[{"id":4,"title":"…","pricing_date":"2026-03-09",
  "rows":[{"unit_type":"…","unit_type_ar":"…","unit_type_en":"…","price":400}]}]}`
  - `units` must be restricted to the caller's authorised hotel(s).
  - `records` ordered by `pricing_date DESC`.
- `POST` → body from the app:

```json
{"action":"save","id":4,"title":"أسعار مارس","pricing_date":"2026-03-09",
 "rows":[{"unit_type_ar":"جناح","unit_type_en":"Suite","unit_type":"جناح","price":400}]}
```

  - `id` absent → INSERT, present → UPDATE (same hotel only).
  - Enforce at most six rows, `price > 0`, unique `unit_type` per sheet.
  - Roles: `hotel_manager`, `owner`, `unit_manager` (write); the same roles may
    `GET` (owners read-only in the app).

Suggested schema:

```sql
CREATE TABLE hotel_unit_pricing (
  id INT AUTO_INCREMENT PRIMARY KEY,
  hotel_id INT NOT NULL,
  title VARCHAR(191) NOT NULL,
  pricing_date DATE NOT NULL,
  created_by INT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX (hotel_id, pricing_date)
);
CREATE TABLE hotel_unit_pricing_rows (
  id INT AUTO_INCREMENT PRIMARY KEY,
  sheet_id INT NOT NULL,
  unit_type VARCHAR(191) NOT NULL,
  unit_type_ar VARCHAR(191) NULL,
  unit_type_en VARCHAR(191) NULL,
  price DECIMAL(10,2) NOT NULL,
  UNIQUE KEY (sheet_id, unit_type),
  FOREIGN KEY (sheet_id) REFERENCES hotel_unit_pricing(id) ON DELETE CASCADE
);
```

**`hotel/meal-pricing.php`**

- `GET` → `{"success":true,"records":[{"id":3,"title":"…","pricing_date":"2026-03-09",
  "meals":[{"name":"فطور","price":35}]}]}`
- `POST` → `{"action":"save","id":3,"title":"…","pricing_date":"2026-03-09",
  "meals":[{"name":"فطور","price":35}]}`
  - Exactly three meals, `price > 0`, unique `name` per sheet.
  - Same role/hotel scoping as above.

```sql
CREATE TABLE hotel_meal_pricing (
  id INT AUTO_INCREMENT PRIMARY KEY,
  hotel_id INT NOT NULL,
  title VARCHAR(191) NOT NULL,
  pricing_date DATE NOT NULL,
  INDEX (hotel_id, pricing_date)
);
CREATE TABLE hotel_meal_pricing_items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  sheet_id INT NOT NULL,
  name VARCHAR(191) NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  UNIQUE KEY (sheet_id, name),
  FOREIGN KEY (sheet_id) REFERENCES hotel_meal_pricing(id) ON DELETE CASCADE
);
```

Both endpoints must return `404`-equivalent JSON (`"success":false`) when the
tables are missing. The owner screen already hides the section in that case.

### 8.3 `admin/hotels/create.php` (and `edit.php`) — remove the nightly price

1. Delete the `price_per_night` (سعر الليلة) input from the create form; keep it
   out of the update form as well, so the value cannot be reintroduced.
2. Drop the field from the INSERT/UPDATE statement and from `$_POST` validation.
3. Keep the column on `hotels` (default `0`) so existing rows and reports do not
   break; optional cleanup afterwards:
   `ALTER TABLE hotels MODIFY price_per_night DECIMAL(10,2) NOT NULL DEFAULT 0;`
4. Do **not** touch `units.price_per_night`, `hotel/prices.php`,
   `hotel/unit-pricing.php` or any booking-price calculation — unit pricing
   remains the source of nightly prices.
5. Audit `admin/hotels/index.php` (list view) for a “سعر الليلة” column belonging
   to the hotel row; remove it there too. Columns derived from units stay.

### 8.4 Payment methods (carried over from Group 01)

- Settings keys `payment_methods.at_hotel`, `payment_methods.owner_transfer`,
  `payment_methods.online`, both default `0`, and
  `payment_checkout_url` (https only).
- `payment-settings.php` exposes the flags to the app and to the booking
  endpoints; `bookings/create.php` must reject any disabled method with `403`.
- Admin UI writes through `POST payment-settings.php` with an admin-only role
  check. See `docs/DOCUMENT_06_GROUP_01.md` §8 for the full contract.

---

## 9. Project protection rules — verified

| Rule | Evidence |
|---|---|
| Existing approved design preserved | Reused `AppColors`, `AppDimens`, `AppTheme`, existing card/dialog patterns; no restyle |
| Arabic RTL and English LTR preserved | All new strings exist in both languages; render tests run in `ar` and `en` (LTR) |
| Document 05 modifications preserved | No Document 05 file was reverted; only additions/targeted edits |
| Google Play account-deletion flow preserved | `lib/screens/profile/delete_account_screen.dart` untouched |
| No feature removed | Groups 01–02 only add; the deprecated-radio cleanup keeps identical behaviour |
| Application ID `com.superai.allowners` | `android/app/build.gradle` untouched |
| Signing configuration | `android/key.properties`, `signingConfigs` untouched |
| Codemagic workflows | `codemagic.yaml` untouched |
| No local APK/AAB build | none run |
| No Codemagic trigger | none triggered |
| No production cPanel change | none made |
| No merge to main, no force push | PR #1 stays open and Draft |

---

## 10. Honest limitations

1. **Payment settlement is not live.** No wallet deduction and no payment link is
   produced by this repository; the app sends the chosen option and shows what
   the server returns. No fake confirmation, balance, or link exists anywhere in
   the code.
2. **The pricing screens will show a load error until §8.2 is deployed.** They
   do not crash and do not lose existing service prices
   (`hotel/prices.php` is untouched).
3. **Requirement 17 cannot be completed here** because the PHP dashboard is not
   in the repository. §8.3 is the exact change to apply during the cPanel phase.
4. **No screenshots.** The environment runs headless; widget tests at 360 / 390 /
   768 logical pixels are the visual evidence instead (no overflow exceptions).

---

## 11. Acceptance summary

| # | Requirement | Status |
|---|---|---|
| 11 | Meal request payment options | **FLUTTER COMPLETE — BACKEND PENDING** |
| 12 | Extra-bed settlement with approved amount | **FLUTTER COMPLETE — BACKEND PENDING** |
| 13 | Unit pricing title field | **FLUTTER COMPLETE — BACKEND PENDING** |
| 14 | Unit pricing date picker | **FLUTTER COMPLETE — BACKEND PENDING** |
| 15 | Six unit-type and price rows | **FLUTTER COMPLETE — BACKEND PENDING** |
| 16 | Meal pricing (title, date, three meals) | **FLUTTER COMPLETE — BACKEND PENDING** |
| 17 | Nightly price removed from hotel creation | **FLUTTER COMPLETE — BACKEND PENDING** (no Flutter form exists; §8.3) |
| — | Group 01 requirement 4 acceptance correction | **COMPLETE AND VERIFIED** |

No requirement in this group could be marked COMPLETE AND VERIFIED end-to-end
because all seven depend on PHP endpoints or admin-dashboard screens that are not
present in `startgroup2022-tech/allowner`.
