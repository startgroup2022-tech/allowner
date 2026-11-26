# All Owners — Modification Document 06 — Group 01 (Requirements 1–10)

**Branch:** `feature/allowners-new-version-exec01`
**Pull request:** [#1](https://github.com/startgroup2022-tech/allowner/pull/1) (kept open and Draft)
**Date:** 2026-11-26
**Flutter:** 3.47.7 (stable) · **Dart:** 3.13.5
**Application ID:** `com.superai.allowners` (unchanged) · **Signing:** unchanged · **Codemagic:** unchanged

This is an implementation report, not an audit. Every requirement below was
implemented in the Flutter client. Where a requirement needs PHP/admin work that
does not exist in this repository, the exact cPanel backend contract is specified
in §12 and the status is stated honestly.

---

## 0. Commands actually run

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

| Command | Result |
|---|---|
| `flutter pub get` | OK — resolves against Flutter 3.47.7 with **no change** to `pubspec.lock` (the committed lock is kept; no dependency was added or upgraded) |
| `dart format --output=none --set-exit-if-changed .` | `Formatted 135 files (0 changed)` → exit 0 |
| `flutter analyze` | `143 issues found` — **0 errors, 0 warnings**; all 143 are pre-existing `info` lints (`withOpacity`, `activeColor`, `groupValue` deprecations, `curly_braces`, `prefer_const`) in files this change touches only where the same pattern already existed |
| `flutter test` | **553 passed, 17 skipped, 0 failed** (`All tests passed!`) |

The 17 skips are the pre-existing live-backend integration tests that require
`RUN_LIVE_TESTS=1` and a reachable production API. No test was disabled,
deleted, or weakened to obtain this result. The one test that had to change
(`test/widgets_test.dart`, payment-method row) changed **because requirement 5
removes that row from the screen**; it now asserts the row is absent.

---

## 1. Requirement 1 — “ضيافاتي” / “My Stays”

**Implementation**
- `my_stays` = «ضيافاتي» / “My Stays”, `nav_stays` = «ضيافاتي» / “Stays”.
- Guest booking list title switches on role: guests get `my_stays`, booking
  agents keep `my_bookings` («حجوزاتي» / “My Bookings”).
- Guest bottom navigation tab uses `nav_stays`.
- The login prompt on the same screen uses `login_to_view_stays`.
- Owner and booking-agent terminology is untouched (`my_bookings`,
  `owner_bookings`, agent screens).

**Modified files**
- `lib/utils/app_strings.dart` (`my_stays`, `nav_stays`, `login_to_view_stays`)
- `lib/screens/bookings/my_bookings_screen.dart`
- `lib/screens/home/main_navigation_screen.dart`

**Test evidence** — `test/document06_group01_test.dart`
- `النصوص العربية والإنجليزية` → `ضيافاتي` / `My Stays`, `nav_stays`
- `مصطلح المالك والوكيل يبقى «حجوزاتي»`
- widget: guest sees `ضيافاتي` and never `حجوزاتي`; agent sees the inverse

**Backend dependencies** — none.
**Screenshots** — no emulator/device in this environment (headless container);
widget tests render the real screens at 390×844 and assert the strings instead.
**Status:** **COMPLETE AND VERIFIED**

---

## 2. Requirement 2 — Search available units by unit number inside hotel details

**Implementation**
- New pure search helper `lib/utils/unit_search.dart`:
  - `normalizeUnitSearchText` trims, collapses spaces, and maps Arabic-Indic
    (٠–٩) and Persian (۰–۹) digits to ASCII so any keyboard finds the unit.
  - `filterUnitsByUnitNumber` returns the list unchanged for an empty query,
    otherwise ranks exact match → prefix → substring (partial + exact matching).
  - `hasNoUnitSearchMatch` drives the empty-results state.
- `_UnitsList` in the hotel details screen now has a search field
  («البحث برقم الوحدة» / “Search by unit number”) with a clear button
  (`مسح البحث` / “Clear search”), loading state preserved, “no matching units”
  empty state, and a reset whenever the hotel changes.
- Search runs only over the units of the selected hotel (already fetched for
  that hotel); filters and the existing “Book now” action are untouched.

**Modified files**
- `lib/utils/unit_search.dart` (new)
- `lib/screens/hotel/hotel_details_screen.dart`
- `lib/utils/app_strings.dart` (`search_unit_number`, `search_unit_number_hint`,
  `no_matching_units`; reuses existing `clear_search`)

**Test evidence** — `test/document06_group01_test.dart`
- empty query returns everything; `101` ranks `2101` before `1101` and excludes `1001`
- Arabic-Indic digits and Latin letters match
- `hasNoUnitSearchMatch` true only when units exist and nothing matches
- Arabic/English hint and empty-state strings exist

**Backend dependencies** — none (filtering happens on the units already returned
for the hotel).
**Screenshots** — not available (headless).
**Status:** **COMPLETE AND VERIFIED**

---

## 3. Requirement 3 — “رقم الضيافة” / “Stay Reference”

**Implementation**
- `stay_reference` = «رقم الضيافة» / “Stay Reference”.
- The stay/hospitality details row builder now uses it as the first row label;
  the old label `booking_reference` («رقم الحجز») is no longer used on customer
  hospitality screens.
- Internal identifiers are untouched: `bookingRef`, `booking['id']`,
  `booking['reference']` continue to flow through the API payloads and the
  navigation to details.

**Modified files**
- `lib/utils/app_strings.dart`
- `lib/screens/booking/booking_success_screen.dart`

**Test evidence**
- `«رقم الضيافة» بدل «رقم الحجز»` → label values in both languages
- first row of `buildBookingSuccessRows` is `رقم الضيافة`; `رقم الحجز` absent
- the internal reference stays visible under its own label
  `booking_reference_internal` («المرجع الداخلي للحجز»), which is deliberately
  **not** the string «رقم الحجز»

**Backend dependencies** — none.
**Status:** **COMPLETE AND VERIFIED** *(corrected in Group 02 — see §4 note)*

---

## 4. Requirement 4 — Display the actual booked unit number

**Implementation**
- `BookingScreen` now accepts `unitNumber` (from the chosen unit / booking
  response) and passes it to `BookingSuccessScreen`.
- `buildBookingSuccessRows` shows the real `unitNumber` under the “Stay
  Reference” label. **No unit number is ever fabricated.**
- **Acceptance correction (Group 02):** when the API does not return a real unit
  number, the row now shows the explicit `not_available` state
  («غير متاح حاليًا» / “Currently unavailable”). It no longer substitutes the
  booking reference, and it no longer shows `-`. The internal booking reference
  is preserved separately in its own row labelled
  `booking_reference_internal` («المرجع الداخلي للحجز» /
  “Internal booking reference”). Internal IDs, `booking['id']`,
  `booking['reference']`, edit/cancel paths and API relations are unchanged;
  the change is display-only.

**Modified files**
- `lib/screens/booking/booking_screen.dart`
- `lib/screens/booking/booking_success_screen.dart`
- `lib/screens/hotel/hotel_details_screen.dart` (2 call sites)
- `lib/screens/unit/unit_details_screen.dart`

**Test evidence**
- `يعرض رقم الوحدة القادم من الاستجابة` → `' 4005 '` renders `4005`
- `لا يختلق رقمًا حين لا يصل رقم وحدة` → shows «غير متاح حاليًا» /
  “Currently unavailable”, never `BK-77`
- `المتطلب 4 … يُعرض رقم الوحدة الفعلي بدل رقم الحجز` (`widgets_test.dart`) →
  `'4005'` when present, «غير متاح حاليًا» when absent, and `BK-100` only in the
  separate internal-reference row
- widget: `BookingSuccessScreen(unitNumber: '4005')` renders `4005`

**Backend dependencies** — the booking response should include the unit number
(`unit_number`, or `unit.unit_number`). Already present in `bookings/create.php`
responses; if absent, the client degrades honestly.
**Status:** **COMPLETE AND VERIFIED**

---

## 5. Requirement 5 — Remove the payment-method display from hospitality details

**Implementation**
- `buildBookingSuccessRows` no longer emits a payment-method row at all.
- `BookingSuccessScreen` no longer accepts/renders a `paymentMethod` argument.
- Backend payment records, `payment_method` in the booking payload and all
  payment processing remain intact — only the customer-facing row is gone.

**Modified files**
- `lib/screens/booking/booking_success_screen.dart`
- `lib/screens/booking/booking_screen.dart` (stops passing the argument)
- `test/widgets_test.dart` (assertion updated to the new required behaviour)

**Test evidence**
- `لا صف لطريقة الدفع في تفاصيل الضيافة` (Arabic + English label absent)
- `الحالة تُترجم عبر مفتاحها، وطريقة الدفع لا تُعرض إطلاقًا` (widgets_test)

**Backend dependencies** — none; `payment_method` stays stored server-side.
**Status:** **COMPLETE AND VERIFIED**

---

## 6. Requirement 6 — “عرض تفاصيل ضيافتي” / “View My Stay Details”

**Implementation**
- `view_stay_details` = «عرض تفاصيل ضيافتي» / “View My Stay Details”.
- The guest booking card uses it; the existing tap target and navigation to the
  details screen are unchanged. Agent/owner label
  `view_booking_details` («عرض تفاصيل الحجز») is unchanged.

**Modified files**
- `lib/utils/app_strings.dart`
- `lib/screens/bookings/my_bookings_screen.dart`

**Test evidence**
- string test for both languages + unchanged agent label
- widget: guest booking screen shows `عرض تفاصيل ضيافتي`

**Backend dependencies** — none.
**Status:** **COMPLETE AND VERIFIED**

---

## 7. Requirement 7 — Disable “pay on arrival” and “bank transfer to owner” by default

**Implementation**
- New `lib/utils/payment_methods_config.dart` is the single source of truth:
  - `PaymentMethodKey` (`online`, `atHotel`, `ownerTransfer`) with wire values
    `online` / `at_hotel` / `owner_transfer` matching `payment_method` in
    `POST /bookings/create.php`.
  - `resolvePaymentMethods(settings)` reads `payment_methods.{...}` (map or
    list) or the flat `payment_{wire}_enabled` flags.
  - **Defaults: everything disabled.** `at_hotel` and `owner_transfer` are only
    enabled when the server explicitly says `true`.
  - `online` is enabled **only** when the server also publishes a usable
    `https` hosted-checkout URL (`payment_checkout_url`); a bare flag never
    enables it.
  - `paymentMethodBlockReason` rejects a method the server disabled before the
    request is sent.
- `BookingScreen` replaced its local enum with the server-driven keys, shows
  only enabled methods, blocks disabled ones client-side, and refuses online
  payment without a hosted checkout page. **No card data is collected or sent**
  (`findPaymentDataLeaks` guard still covers the payload).
- Methods stay configurable (data-driven), not deleted.

**Modified files**
- `lib/utils/payment_methods_config.dart` (new)
- `lib/screens/booking/booking_screen.dart`

**Test evidence** — `test/document06_group01_test.dart`
- default config → `at_hotel`, `owner_transfer`, `online` all disabled, `hasAny == false`
- per-method enable via `payment_methods` map
- `online` refused with no URL, with `http://`, accepted with `https://`
- disabled method → non-null block reason; `payment_at_hotel_enabled: '1'` → allowed
- existing suite: `أمان الدفع — لا تمرّ بيانات البطاقة عبر التطبيق` still passes

**Backend dependencies** — `content/settings.php` (see §12.1). Until the server
publishes the flags, the client shows **no** payment method, which is the
requested safe default.
**Status:** **FLUTTER COMPLETE — BACKEND PENDING**

---

## 8. Requirement 8 — Admin controls to enable/disable each payment method

**Implementation (client side, complete)**
- Dynamic availability: the booking screen renders exactly the methods returned
  by `resolvePaymentMethods`, in a fixed order, with a `null` selection when
  none are available and a blocking message
  (`لا توجد طريقة دفع متاحة حاليًا` / “No payment method is available right
  now”).
- Consistent behaviour across booking screens: the same availability object
  drives the payment sheet, the review sheet and the pre-submit guard, so the
  guest can never submit a method that disappeared between screens.
- Server-side enforcement and admin permissions are **not implemented here** —
  the PHP admin dashboard is not part of this repository. The exact contract is
  in §12.1/§12.2. This report does **not** claim the admin controls are
  operational.

**Modified files**
- `lib/utils/payment_methods_config.dart`
- `lib/screens/booking/booking_screen.dart`

**Test evidence** — same group as §7 (`المتطلبان 7 و8 — إتاحة وسائل الدفع من السيرفر`),
5 tests covering defaults, per-method enable, hosted-checkout gating and the
pre-submit block.
**Status:** **FLUTTER COMPLETE — BACKEND PENDING**

---

## 9. Requirement 9 — Unit-number search on the hotel departures screen

**Implementation**
- New `lib/utils/departures.dart`:
  - `isDepartureRecord` treats a record as a departure when the server says
    `can_check_out == true`, otherwise when `check_out` equals today.
  - `filterDeparturesByUnit` keeps today’s departures and then applies the same
    partial/exact unit-number matcher as §2 (Arabic-Indic digits included).
  - `departureUnitNumber` reads `unit_number`, `room_number`, `unit_no`,
    `room_no` and returns `''` when the server sent no real number.
- New `HotelDeparturesScreen`:
  - title «مغادرات اليوم» / “Departures Today”,
  - unit-number search field with clear button,
  - guest name, hotel, unit name, unit number, check-in/check-out, guests,
  - existing `checkOut` action preserved (same `hotel/bookings.php` `check_out`),
  - empty-results state, error + retry state, pull-to-refresh.
- Reachable from the hotel dashboard: the “departures today” tile is now tappable
  and opens the screen. The other three tiles are unchanged.
- Results are restricted to the authorized hotel because the endpoint itself is
  scoped server-side to the staff member’s hotel.
- The existing arrivals/unit-number search on `HotelBookingsScreen` is untouched.

**Modified files**
- `lib/utils/departures.dart` (new)
- `lib/screens/hotel_staff/hotel_departures_screen.dart` (new)
- `lib/screens/hotel_staff/hotel_dashboard_screen.dart`
- `lib/utils/app_strings.dart` (`departures`, `departures_today_title`,
  `no_departures`, `room_or_unit_number`)

**Test evidence**
- today-only filtering; partial search on `unit_number` and `room_number`; no
  match → empty; `can_check_out` honoured; key-reading never fabricates a number
- widget: `HotelDeparturesScreen` renders the title, one search `TextField`, and
  the authorized hotel’s departure

**Backend dependencies** — none beyond the existing `GET /hotel/bookings.php?scope=active`.
**Status:** **COMPLETE AND VERIFIED**

---

## 10. Requirement 10 — Housekeeping confirmation with payment options

**Implementation (client side)**
- New `lib/utils/housekeeping_settlement.dart`:
  - `HousekeepingSettlement { walletBalance, whatsappLink }` sent as
    `settlement = wallet_balance | whatsapp_link`.
  - `approvedHousekeepingPrice` reads the approved price from the server record
    (`price` / `approved_price` / `total_price` / `cost`), never invents one.
  - `isHousekeepingSettlementRecorded` detects an already-settled request
    (`settlement`, `settled`, `payment_status`, `settlement_status`) to prevent
    **duplicate deductions and duplicate payment requests**.
  - `validateHousekeepingSettlement` enforces, in order: permission → not
    already settled → approved price present → a method selected.
  - `canConfirmHousekeepingSettlement` limits confirmation to
    `hotel_manager` / `owner` / `unit_manager`.
  - `extractServerPaymentLink` accepts only an absolute `https` link returned by
    the server; the app never builds a payment URL.
  - `buildHousekeepingWhatsAppUri` opens WhatsApp with request id, unit, amount
    and — only when the server issued one — the real payment link.
- `HotelRequestsScreen` confirmation dialog for `cleaning` now shows the
  approved price and the two options («خصم من الرصيد» / «الدفع عبر رابط
  بالواتساب»), requires a selection, shows inline validation errors, and
  disables the confirm button for already-settled requests. The maintenance
  flow keeps its existing behaviour.
- `HotelStaffService.actOnRequest` now returns the server response so the client
  can read `payment_link` from the confirmation response.
- No wallet balance, price, or payment link is fabricated; no real financial
  transaction is triggered (the link only opens if the server issued it).

**Modified files**
- `lib/utils/housekeeping_settlement.dart` (new)
- `lib/screens/hotel_staff/hotel_requests_screen.dart`
- `lib/services/hotel_staff_service.dart`
- `lib/utils/app_strings.dart` (`housekeeping_settlement`,
  `settle_wallet_balance`, `settle_whatsapp_pay_link`,
  `approved_housekeeping_price`, `housekeeping_price_missing`,
  `settlement_already_recorded`, `payment_link_not_available`,
  `permission_denied`, `payment_method_required`)

**Test evidence** — 8 tests
- Arabic/English option labels; wire payload values
- approved price read from the server only; `0`/missing → `null`
- no selection → `payment_method_required`; no price → `housekeeping_price_missing`
- four “already settled” shapes → `settlement_already_recorded`
- role permissions (`guest`/`booking_agent`/`null` denied)
- payment link: `https` accepted; `http` and `javascript:` rejected
- WhatsApp message contains the amount but **no** URL when the server sent no
  link, and contains the exact server link when it did
- maintenance options unchanged

**Backend dependencies** — see §12.3.
**Status:** **FLUTTER COMPLETE — BACKEND PENDING**

---

## 11. Project protection rules

| Rule | Status |
|---|---|
| Existing approved design and visual identity | Preserved — new UI uses existing `AppColors`/`AppDimens` and card/field patterns |
| Arabic RTL / English LTR | Preserved — all new strings exist in both languages, layout uses `Directionality`-safe widgets |
| Document 05 modifications | Preserved (no revert; additive changes only) |
| Google Play account deletion | Untouched |
| Existing features | None removed |
| Application ID `com.superai.allowners` | Unchanged |
| Signing configuration | Unchanged |
| Codemagic workflows | Unchanged; no build triggered |
| Local APK/AAB build | Not performed |
| Production cPanel | Not modified |
| Merge to main | Not performed |
| Force push | Not performed |
| PR #1 | Open, Draft |

---

## 12. Exact cPanel backend requirements

The PHP source and admin dashboard are not in this repository, so the following
is the contract the Flutter client already speaks. Each item is independent and
can be implemented without touching the app again.

### 12.1 Payment-method configuration (requirements 7 & 8)

`GET /api/content/settings.php` must return, in addition to the current keys:

```json
{
  "success": true,
  "payment_methods": {
    "online": false,
    "at_hotel": false,
    "owner_transfer": false
  },
  "payment_checkout_url": "",
  "payment_provider": ""
}
```

- Both default to `false` in the DB so a fresh install matches the app default.
- `payment_checkout_url` must be an absolute `https://` URL of the provider’s
  hosted page. While it is empty the app will not offer online payment.
- The flat form (`payment_online_enabled`, `payment_at_hotel_enabled`,
  `payment_owner_transfer_enabled`) is also accepted.

**Server-side enforcement** — `POST /api/bookings/create.php` must reject a
disabled method instead of trusting the client:

```php
$allowed = payment_methods_enabled();            // from settings
if (!in_array($method, $allowed, true)) {
    http_response_code(422);
    echo json_encode(['success' => false,
                      'message' => 'طريقة الدفع غير متاحة حاليًا']);
    exit;
}
```

**Admin controls** — a `payment_methods` screen in the admin dashboard with one
toggle per method (`online`, `at_hotel`, `owner_transfer`), restricted to the
`admin` role (capability check on every POST, CSRF token, audit row with
`admin_id`, `method`, `enabled`, `created_at`). `at_hotel` and
`owner_transfer` ship **disabled**.

**Never** store or accept raw card data in these endpoints; online payment must
redirect to the provider’s hosted page only.

### 12.2 Booking API contract (requirements 3, 4, 5)

`POST /api/bookings/create.php` response should include, alongside the existing
fields:

```json
{
  "success": true,
  "booking": {
    "id": 123,
    "reference": "BK-...",
    "unit_number": "4005",
    "unit": { "id": 12, "unit_number": "4005", "name_ar": "...", "name_en": "..." },
    "payment_method": "at_hotel"
  }
}
```

`payment_method` must keep being stored (requirement 5 removes only the display).
`unit_number` is what the customer confirmation now shows; without it the app
falls back to `reference` rather than inventing a number.

### 12.3 Housekeeping settlement (requirement 10)

`POST /api/hotel/requests.php` (action `confirm`, type `cleaning`) must accept:

```
id=<request_id>&action=confirm&type=cleaning&price=<amount>&settlement=wallet_balance|whatsapp_link
```

Required server behaviour:

1. **Authorization** — the caller must be `hotel_manager` (or owner/unit manager
   of that hotel); otherwise `403 {"success":false,"message":"غير مصرّح"}`.
2. **Approved price** — if the request has no approved price, reject with `422`
   rather than defaulting to `0`.
3. **Idempotency** — inside one transaction, lock the row
   (`SELECT ... FOR UPDATE`) and reject if `settlement`/`payment_status` is
   already set (`409`). This is what prevents duplicate deductions and duplicate
   payment requests; the client guard is only a UX layer.
4. **`wallet_balance`** — debit the unit/owner wallet by the approved amount,
   insert a ledger row (`request_id`, `amount`, `type='housekeeping'`), set
   `settlement='wallet_balance'`, `settlement_status='deducted'`. The wallet
   balance must come from the ledger, never from a client value.
5. **`whatsapp_link`** — create a provider payment intent and return its URL:

   ```json
   { "success": true, "payment_link": "https://<provider-hosted-page>", "payment_status": "pending" }
   ```

   The link must be issued by the payment provider (Moyasar / HyperPay / Tap or
   equivalent), tied to `request_id`, single-use and expiring. **Do not**
   synthesise a link, and do not enable this until the provider account,
   webhook signature verification and refund policy are ready.
6. **Webhook** — `POST /api/payments/webhook.php` verifies the provider
   signature, marks `payment_status='paid'`, and is idempotent by provider
   reference.

Until 1–6 exist, the Flutter flow is complete but the two options only send the
`settlement` choice; `whatsapp_link` shows “the payment link is issued by the
server once the payment gateway is enabled” and never invents a URL.

### 12.4 Departures endpoint (requirement 9, optional)

`GET /api/hotel/bookings.php?scope=active` already powers the screen. If a
dedicated feed is preferred, add `GET /api/hotel/departures.php?date=YYYY-MM-DD`
returning `bookings[]` with `unit_number`, `room_number`, `guest_name`,
`check_in`, `check_out`, `guests`, `can_check_out`, scoped to the staff member’s
hotel. The client change would be a single line; the current implementation
needs nothing.

---

## 13. Acceptance summary

| # | Requirement | Status |
|---|---|---|
| 1 | “ضيافاتي” / “My Stays” | **COMPLETE AND VERIFIED** |
| 2 | Unit-number search in hotel details | **COMPLETE AND VERIFIED** |
| 3 | “رقم الضيافة” / “Stay Reference” | **COMPLETE AND VERIFIED** |
| 4 | Actual unit number on confirmation | **COMPLETE AND VERIFIED** (Group 02 correction: unavailable state instead of booking reference) |
| 5 | Payment method removed from hospitality details | **COMPLETE AND VERIFIED** |
| 6 | “عرض تفاصيل ضيافتي” / “View My Stay Details” | **COMPLETE AND VERIFIED** |
| 7 | Pay-on-arrival and owner-transfer disabled by default | **FLUTTER COMPLETE — BACKEND PENDING** |
| 8 | Admin payment-method controls | **FLUTTER COMPLETE — BACKEND PENDING** |
| 9 | Unit-number search on hotel departures | **COMPLETE AND VERIFIED** |
| 10 | Housekeeping payment options | **FLUTTER COMPLETE — BACKEND PENDING** |

---

## 14. Visual evidence — real rendered screenshots (not mockups)

Every PNG below was produced by rendering the **actual production widgets** in a
Flutter test harness and writing the `RepaintBoundary` layer to disk. No
hand-drawn mockup, no HTML reconstruction, no placeholder image is used anywhere
in this evidence set.

How the screenshots are produced:

| Piece | File | What it does |
|---|---|---|
| Harness | `test/screenshot_support.dart` | Boots the real widgets under `ProviderScope` + `MaterialApp` with the production `AppTheme`, blocks `GoogleFonts` runtime fetching and loads the bundled brand fonts (`IBM Plex Sans Arabic`, `Inter`) so Arabic glyphs shape correctly; mocks the Dio `HttpClientAdapter` and `path_provider` so screens receive the same JSON shapes the cPanel API returns |
| Customer set | `test/screenshot_export_test.dart` | 24 screens: home (AR/EN), search, results, hotel details, unit details, unit-number search (results + empty), booking, extra-bed calculation, price breakdown, payment-method state, booking success, stays list + stay details + hospitality details, favourites, account, account deletion, notifications |
| Staff/owner/agent set | `test/screenshot_export_roles_test.dart` | 34 screens: hotel dashboard, staff navigation, arrivals (+ search, + empty), departures (+ unit-number search), hotel bookings, hotel prices, unit pricing (AR/EN), meal pricing, cleaning requests (+ confirmation dialog with the two settlement options), meal requests, owner home/navigation, owner bookings, owner service prices, cleaning, meal requests, extra bed, maintenance, wallet, revenue, staff, notifications, units, subscription, bank, booking-agent clients/commission/home, owner-employee navigation |

Regenerate (deterministic, no network):

```bash
flutter test test/screenshot_export_test.dart --update-goldens
flutter test test/screenshot_export_roles_test.dart --update-goldens
```

58 PNG files are committed under `docs/evidence/final-acceptance/`:

```
docs/evidence/final-acceptance/
├── customer/arabic/*.png          (16)
├── customer/english/*.png         ( 8)
├── hotel-staff/arabic/*.png       (13)
├── hotel-staff/english/*.png      ( 2)
├── owner/arabic/*.png             (15)
├── booking-agent/arabic/*.png     ( 3)
└── owner-employee/arabic/*.png    ( 1)
```

### 14.1 Screenshot map to the ten Group 01 requirements

All paths are relative to `docs/evidence/final-acceptance/`.

| # | Requirement | Screenshot evidence (committed PNG) |
|---|---|---|
| 1 | “ضيافاتي” / “My Stays” | `customer/arabic/DOC06-REQ-006-my-bookings-ar.png` — page title «ضيافاتي»; same in `customer/english/DOC06-REQ-006-my-bookings-en.png` (“My Stays”) |
| 2 | Unit-number search in hotel details | `customer/arabic/DOC06-REQ-002-hotel-unit-search-ar.png` (field «البحث برقم الوحدة» inside the hotel details screen), `customer/arabic/DOC05-REQ-028-030-hotel-details-ar.png`, `customer/english/DOC05-REQ-028-030-hotel-details-en.png` |
| 3 | “رقم الضيافة” / “Stay Reference” | `customer/arabic/DOC06-REQ-006-stay-details-sheet-ar.png` — label «رقم الضيافة» while the internal booking id stays intact |
| 4 | Actual unit number on confirmation | `customer/arabic/DOC06-REQ-003-005-booking-success-ar.png`, `customer/english/DOC06-REQ-003-005-booking-success-en.png` — the booked unit number (“وحدة رقم 402”) is shown, never the booking reference |
| 5 | Payment method removed from hospitality details | The hospitality-details screen is covered by `customer/arabic/DOC06-REQ-006-stay-details-sheet-ar.png` — no payment-method row is rendered; the backend payment record is untouched |
| 6 | “عرض تفاصيل ضيافتي” / “View My Stay Details” | `customer/arabic/DOC06-REQ-006-my-bookings-ar.png` — action label «عرض تفاصيل ضيافتي» on the stay card, same action and navigation as before |
| 7 | Pay-on-arrival / owner-transfer disabled by default | `customer/arabic/DOC05-REQ-033-booking-payment-methods-ar.png` — booking screen renders «لا توجد طريقة دفع متاحة حاليًا. تواصل مع الدعم.» because the server advertises no enabled method |
| 8 | Admin payment-method controls | Client side: `customer/arabic/DOC05-REQ-033-booking-payment-methods-ar.png`. Server side: §12.1 of this document — the cPanel dashboard is not in this repository, so no screenshot pretends the admin toggle exists |
| 9 | Unit-number search on departures | `hotel-staff/arabic/DOC06-REQ-009-departures-search-ar.png` — searching «1205» filters to the guest of unit 1205 while «تأكيد خروج الضيف» stays available. Arrivals search preserved: `hotel-staff/arabic/DOC06-REQ-F-002-arrivals-search-ar.png`, empty state `DOC06-REQ-F-002-arrivals-empty-ar.png` |
| 10 | Housekeeping payment options | `hotel-staff/arabic/DOC06-REQ-010-housekeeping-payment-options-ar.png` — the confirmation dialog shows «سعر النظافة المعتمد 120 ريال» and «طريقة سداد قيمة الطلب» with the exactly-two options «خصم من الرصيد» and «الدفع عبر رابط بالواتساب»; `hotel-staff/arabic/DOC06-REQ-010-requests-cleaning-ar.png` (list state), `hotel-staff/arabic/DOC06-REQ-011-requests-meal-ar.png` (same pattern for meal requests) |

Extra-bed arithmetic (§B, prerequisite for the stay pricing in requirements 2 and
10) is visually proven by `customer/arabic/DOC06-REQ-B-002-booking-extra-bed-ar.png`:
the card reads «+150 ريال × لكل ليلة لكل سرير», quantity `1`, and the formula
`1 × 150 × 2 = 300 ريال`, with the same 300 added under «تفاصيل السعر».

### 14.2 What the screenshots deliberately do *not* claim

- Requirement 8's admin toggle is a **backend** capability; the cPanel dashboard
  source is not in this repository, so no screenshot pretends the toggle exists.
- Requirement 10's «الدفع عبر رابط بالواتساب» shows only the client flow. The
  payment link must be generated by the server; the app never fabricates one.
- Requirement 7's disabled state is read from the server response. When the
  backend later enables a method, the Flutter app renders it without a code
  change — that is the whole point of §12.1.

### 14.3 The extra-bed defect — found, fixed, and locked down

Producing the evidence found a real defect: the extra-bed card was built inside
the *hotel-level* booking branch only, so with `unitId != null` the customer could
not select an extra bed at all — even though the price lives on the hotel and the
total is computed identically on both paths.

**Fix (`lib/screens/booking/booking_screen.dart`).** The `if (widget.unitId != null)
… else …` collection-spread was replaced by `_buildExtrasSection(context, isArabic)`,
which builds the unit add-ons / hotel meals for its branch and then, *after* the
branch, appends the shared `_ExtraBedCard`. Both paths therefore render the same
widget, with the same switch, the same `_StepperBox` quantity control
(1–`kMaxExtraBeds` = 4), and the same `count × nightlyPrice × nights` line. The
booking payload (`extra_bed`, `extra_bed_qty`) and the price breakdown were already
path-independent and are untouched.

The card is suppressed only when the owner defined an `extra_bed` *unit addon*
(`category == 'extra_bed'`), so the bed can never be charged twice.

**Regression tests** — `test/booking_extra_bed_paths_test.dart` (10 tests):

| Test | Asserts |
|---|---|
| unit path: card, stepper, formula | `إضافة سرير إضافي` exists with `unitId: 13`; `1 × 150 × 2 = 300` |
| unit path: quantity change | tapping `+` gives `2 × 150 × 2 = 600` |
| unit path: cap | `+` is disabled at `kMaxExtraBeds` |
| hotel path: card + meals | card renders and the three legacy meal chips survive |
| free price | `extra_bed_price: 0` shows `مجاني` and no stepper |
| arithmetic | `computeExtraBedCharge` / `extraBedChargeFormula` matrix |
| payload ×3 | `extra_bed`/`extra_bed_qty` sent for unit and hotel paths; `1` omitted |

These tests were run **against the pre-fix file** as proof they catch the defect:

```
00:03 +0 -1: مسار الحجز المباشر لوحدة … بطاقة السرير الإضافي…
  Expected: at least one matching candidate
  Actual: _TextWidgetFinder:<Found 0 widgets with text "إضافة سرير إضافي": []>
```

and against the fixed file: `00:04 +10: All tests passed!`.

### 14.4 Screenshots for both booking paths

| File | Shows |
|---|---|
| `customer/arabic/DOC06-REQ-B-002-booking-extra-bed-hotel-ar.png` | hotel-level booking, 2 beds, `2 × 150 × 2` |
| `customer/arabic/DOC06-REQ-B-002-booking-extra-bed-unit-ar.png` | unit-level booking (`unitId: 13`), 2 beds, breakdown `إضافة سرير إضافي 600`, total `4140` |
| `customer/english/DOC06-REQ-B-002-booking-extra-bed-unit-en.png` | the same screen in English LTR |
| `customer/arabic/DOC06-REQ-B-002-booking-extra-bed-summary-ar.png` | scrolled to `تفاصيل السعر` + the `تفاصيل الحجز` CTA |

The Arabic-font fallback added to the test-only theme override keeps Arabic hotel
names readable in the English screenshots instead of rendering tofu boxes. The
production theme (`GoogleFonts`) is unchanged.

### 14.5 Requirement-wide evidence

`docs/DOCUMENT_05_06_EVIDENCE_REPORT.md` is generated by
`tools/gen_evidence_report.py` from the 148-requirement matrix, the test files and
the PNGs, and lists every requirement with its status, API dependency, tagged test
and screenshot. The backend-side contract for those API dependencies is in
`docs/BACKEND_INTEGRATION_HANDOVER.md`.

## 15. Final status of Group 01

| # | Requirement | Final acceptance status |
|---|---|---|
| 1 | “ضيافاتي” / “My Stays” | **COMPLETE AND VERIFIED** |
| 2 | Unit-number search in hotel details | **COMPLETE AND VERIFIED** |
| 3 | “رقم الضيافة” / “Stay Reference” | **COMPLETE AND VERIFIED** |
| 4 | Actual unit number on confirmation | **COMPLETE AND VERIFIED** |
| 5 | Payment method removed from hospitality details | **COMPLETE AND VERIFIED** |
| 6 | “عرض تفاصيل ضيافتي” | **COMPLETE AND VERIFIED** |
| 7 | Pay-on-arrival / owner-transfer disabled by default | **FLUTTER COMPLETE — BACKEND PENDING** |
| 8 | Admin payment-method controls | **FLUTTER COMPLETE — BACKEND PENDING** |
| 9 | Unit-number search on departures | **COMPLETE AND VERIFIED** |
| 10 | Housekeeping payment options | **FLUTTER COMPLETE — BACKEND PENDING** |

Test evidence: `flutter test` → **553 passed, 17 skipped (pre-existing live-backend
tests), 0 failed**. `flutter analyze` → **0 errors, 0 warnings** (143 pre-existing
`info` lints). No test was disabled to reach this result.
