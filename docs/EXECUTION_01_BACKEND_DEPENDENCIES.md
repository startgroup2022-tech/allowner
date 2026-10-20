# All Owners — Execution 01 Backend Dependencies

**Branch:** `feature/allowners-new-version-exec01`
**Backend:** `https://all-owner.online/api`
**Probed:** 2026-10-19, read-only (GET requests only; no writes to production)

---

## 1. Purpose

This document records every place where the mobile application's behaviour is
limited by the backend, not by the mobile code. It exists so that Execution 02–05
can distinguish "we have not built it yet" from "the backend does not expose it
yet". Nothing here is a guess: each item was confirmed by an actual request.

---

## 2. Endpoints the app depends on

| Endpoint | Used by | Status |
|---|---|---|
| `GET /cities/list.php` | Homepage destinations, search | Working |
| `GET /categories/list.php` | Homepage categories | Working |
| `GET /hotels/list.php` | Homepage featured, search, destinations | Working |
| `GET /hotels/detail.php` | Hotel details | Working, with gaps (§4) |
| `GET /units/browse.php` | Homepage units, search, hotel units | Working |
| `GET /units/detail.php` | Unit details | Working, with gaps (§4) |
| `GET /auth/login.php` | Login | Working (not modified) |
| `GET /auth/register.php` | Registration | Working (not modified) |
| `GET /user/owner-bookings.php` | Owner bookings | Working |
| `GET /hotels/amenities.php` (via `detail.php`) | Amenities | Working |

---

## 3. Query-parameter support actually verified

### `GET /hotels/list.php`

| Parameter | Supported | Verified |
|---|---|---|
| `city` | Yes | `city=Makkah` → 3 hotels (accepts Arabic or English) |
| `featured` | Yes | `featured=1` → 1 hotel |
| `stars` | Yes (per code) | Not probed with data |
| `min_price` / `max_price` | Yes | `min_price=2000` → 1 hotel |
| **`q` / text search** | **No** | Sending `q` has no effect |

**Consequence — important and honestly reported:** the backend provides **no
server-side hotel name search**. Hotel name matching is therefore done
client-side over the results of `hotels/list.php`. This is correct behaviour
(no fake results, no invented endpoint), but it means hotel-name search cannot
find a hotel outside the returned page. If the catalogue grows, a server-side
`q` parameter should be requested from the backend owner.

### `GET /units/browse.php`

| Parameter | Supported | Verified |
|---|---|---|
| `q` | **Yes** | `q=فيرمونت` → 3 units |
| `city` | Yes | `city=Makkah` → 4 units |
| `hotel_id` | Yes | `hotel_id=2` → 8 units |
| `owner_only` | Yes | used by the homepage owner-units section |
| `min_price` / `max_price` | Yes | per code |
| `min_capacity` | Yes | per code |
| `sort` | Yes | `newest` used |
| `limit` | Yes | used |

Units are the one entity with real server-side text search.

---

## 4. Backend gaps that block or limit features

### 4.1 Hotel gallery is an empty array

```
GET /hotels/detail.php?id=4
→ { "success": true, "hotel": {...}, "gallery": [], "amenities": [...], "reviews": [] }
```

`gallery` is present but always `[]` (verified on hotel ids 1–4). `amenities`
and `reviews` are **top-level** keys, not nested under `hotel`. `amenities` is
populated (0/7/11/11 for ids 1/2/3/4); `reviews` is always `[]`.

- **Mobile impact:** the hotel detail gallery falls back to the cover image.
  `asStringList` handles `[]` and a `null` identically, so either shape is safe.
- **Requirement:** `AO-HTL-04`.
- **Needed from backend:** populate `gallery` with image URLs per hotel, or
  confirm the field is deprecated and remove it from the contract.

### 4.2 Hotel detail does not return its units

`hotels/detail.php` returns `units: []`. Units are fetched separately via
`units/browse.php?hotel_id=<id>`, which works.

- **Mobile impact:** none — the app already makes the second call.
- **Requirement:** `AO-HTL-07`.
- **Note:** this is a design choice, not a defect. Recorded so it is not
  mistaken for a bug.

### 4.3 Unit detail returns no facilities or amenities

```
GET /units/detail.php?id=13
→ { "success": true, "unit": { ..., "images": [...], "addons": [], "availability": [...] } }
```

There is **no `facilities` key and no `amenities` key** in the response.

- **Mobile impact:** the unit detail screen shows "no facilities added for this
  property". It does not invent amenities.
- **Requirement:** `AO-AMN-06`, `AO-UNIT-07`.
- **Needed from backend:** an amenity relation for units — either
  `unit_amenities` joined into `units/detail.php`, or the unit inheriting its
  hotel's amenities. **This is the single most impactful backend dependency for
  the unit experience.**
- **Owner decision required:** should a unit inherit the hotel's amenities, or
  have its own? The data model must answer this before the UI can.

### 4.4 No password-reset endpoint

Probed and confirmed **404**:

```
/api/auth/forgot-password.php   → 404
/api/auth/forgot.php            → 404
/api/auth/reset-password.php    → 404
/api/auth/forgot_password.php   → 404
```

- **Mobile impact:** the login screen's "Forgot Password?" button had no
  destination. In the baseline it was a non-functional button
  (`onPressed: () {}`), which the mandate forbids.
- **Fix applied in Execution 01:** the button now opens the real Help & Support
  screen, which offers the working WhatsApp / phone / email channels from
  `contact` data. The user has a real path to recover access.
- **Needed from backend:** a password-reset endpoint, if self-service reset is
  wanted. Until then the support route is the honest option.

### 4.5 All ratings are zero

Every hotel returned by `hotels/list.php` has `rating: 0` and `reviews_count: 0`,
even where `reviews: []` is returned by the detail endpoint.

- **Mobile impact:** the rating chip is suppressed when the value is 0
  (`if (hotel.rating > 0)`). Nothing is displayed rather than showing a
  fabricated "4.9".
- **Requirement:** `AO-HOME-10`.
- **Needed from backend:** either real aggregated ratings, or confirmation that
  ratings are not part of this product.

### 4.6 `reviews` array is empty

`hotels/detail.php` returns a `reviews` array, but it is empty for the hotels
probed.

- **Mobile impact:** the baseline displayed **two fabricated reviews** (invented
  names, ratings and comments) regardless of this array. Those were removed in
  Execution 01. The screen now renders real reviews when present, and shows
  nothing fabricated when absent.
- **Requirement:** `AO-HTL-11`.

---

## 5. Field-shape hazards in the contract

These are not gaps but genuine contract hazards that the mobile code must defend
against. All are now handled by `lib/utils/safe_parse.dart`.

| Field | Observed shapes | Risk |
|---|---|---|
| `price_per_night` | `1500` (int), `"2300.75"` (string) | `as num` throws on the string form |
| `rating` | `0` (int), `"4.5"` (string) | same |
| `stars` | `5` (int), `"5"` (string) | same |
| `free_cancellation` | `true` (bool in `list.php`), `1` (int in `detail.php`) | `as bool` throws on the int form |
| `breakfast_included` | `true` / `1` | same |
| `is_featured` | `true` / `1` | same |
| `gallery` | `[]` (never seen non-empty) | raw `as List` is safe today, but `null` would throw |
| `unit_type_en` | often `null` while `unit_type_ar` is set | blank labels unless fallback exists |
| `images`, `addons`, `availability` | `[]` on most rows | must not be treated as present |
| `units` (in hotel detail) | `[]` | must not be treated as present |

**Recommendation for the backend owner:** normalise numeric columns to a single
type in JSON, and return `[]` rather than `null` for empty collections. This
would remove an entire class of client-side defensive code. The mobile app now
handles both shapes, so this is a robustness improvement rather than a blocker.

---

## 6. Production-safety constraints respected

| Constraint | How it was respected |
|---|---|
| Do not modify the production database | Only GET requests were issued |
| Do not modify the production website | No write endpoint was called |
| Do not introduce fake data | All displayed content comes from the API; demo data was removed |
| Do not hardcode inventory | Cities, categories, hotels and units are all fetched |
| Do not disable auth checks | The bearer-token interceptor is intact |
| Do not publish to Google Play | No build, no upload |

---

## 7. Requests to the backend owner

Ordered by impact on the remaining executions.

| # | Request | Blocks |
|---|---|---|
| 1 | Unit amenity relation (unit-specific vs hotel-shared) | Unit experience completeness — `AO-AMN-06`, `AO-UNIT-07` |
| 2 | Server-side hotel name search (`q` on `hotels/list.php`) | Search completeness at catalogue scale — `AO-SRCH-02` |
| 3 | Populate hotel `gallery` | Hotel gallery — `AO-HTL-04` |
| 4 | Decide whether ratings/reviews are in scope | Rating and review display — `AO-HOME-10`, `AO-HTL-11` |
| 5 | Password-reset endpoint | Self-service account recovery — `AO-AUTH-08` area |
| 6 | Normalise numeric and boolean JSON types | Removes a class of client defensive code |
| 7 | ~~Confirm the Booking Agent role is in mobile scope~~ **RESOLVED by owner: in scope; already implemented** | — |

---

## 8. What is *not* a backend dependency

Recorded to prevent misattribution in later executions:

| Item | Real cause |
|---|---|
| Booking flow not finished | Mobile scope — Execution 02 by mandate |
| Session not auto-redirecting on 401 | Mobile scope — shared session provider |
| Remaining `as List?` casts in 6 owner screens | Mobile scope — `AO-API-02` |
| `dart format` check failing | Repository/CI scope, pre-existing |
| Missing `.gitignore` | Repository hygiene — `AO-CLEAN-01` |

---

## 9. Reconciliation addendum (2026-10-20)

The 148-item inventory is now available (`docs/AllOwners_Requirements_Inventory.md`)
and fully reconciled in `docs/ALL_OWNERS_REQUIREMENTS_MATRIX.md`. The
reconciliation re-confirmed every backend dependency recorded above and surfaced
the following, all verified by live read-only requests.

### 9.1 Newly confirmed backend gaps

| Inventory items | Gap | Evidence |
|---|---|---|
| 24, 25 | Named Makkah hotels (فيرمونت إعمار، رافلز، كونراد، هيلتون…) and the "قريبًا" (coming soon) states do not exist in `hotels/list.php`. | Live `hotels/list.php` returns 4 hotels total; none of the named properties is present. |
| 18 | Riyadh (الرياض) is not in `cities/list.php`. | Live response lists 5 cities: جدة، مكة المكرمة، المدينة المنورة، الخبر، الدمام — no الرياض. |
| 13 | The primary category is named «فنادق»/Hotels in the database, but the requirement asks for «وحدات فندقية» (hotel units). | Live `categories/list.php` returns 4 categories. |
| 14 | The requirement lists 5 categories; the database returns 4. | Live `categories/list.php` count = 4. |
| 110 | No password-reset endpoint exists (`/auth/forgot*` returns 404). | Confirmed in `login_screen.dart`; the UI routes to support instead of a dead button. |
| 56 | Extra-bed cost calculation needs a server correction. | `units/addons.php` addon pricing. |
| 44, 45, 47, 63, 64, 66, 77, 108, 109, 111–117 | Booking-confirmation email, double-booking prevention, site sync, request forwarding, commission payout, bank-account capture, admin-console work — all require server/site changes. | Recorded per-item in the matrix. |
| 118–143 | Subscription / accounting / payments module: no mobile surface and no supporting endpoints. | `grep` for wallet/subscription/bank across `lib/` finds no screen. |
| 144–148 | Notifications/email module: depends on server-side email delivery. | Same. |

### 9.2 Field-shape notes re-confirmed

- `hotels/list.php` returns the hotel name in `name` (not `name_ar`), a mix of
  `int` and quoted-decimal prices, and `free_cancellation` as `true` in `list.php`
  but `1` in `detail.php`. The typed models already handle all three.
- `units/browse.php` list rows carry `hotel_name`, `city_ar`, `city_en` inline —
  this is what lets the new owner-hotels section build hotel cards without an
  extra per-unit request.

### 9.3 What the new owner-hotels section depends on

`OwnerHotelSummary.build` reads **only** existing endpoints
(`/units/browse.php?owner_only=1` and `/hotels/list.php`). It requires no new
backend work. If the backend later adds an explicit "hotels that contain owner
units" endpoint, the section can switch to it without a UI change.

---

## 10. Addendum — endpoint probes run while closing Executions 02–05

Every probe below is a plain `GET` against `https://all-owner.online/api`, with no
token and no writes. The status code is the evidence, and the three codes mean
different things:

- **`401`** — the route exists and is auth-gated. A GET cannot get past it, so a
  signed-in owner / hotel / agent account is the only way to confirm the feature.
- **`405`** — the route exists but rejects `GET`; it is `POST`-only.
- **`404`** — no such route. This is a real backend gap, not a client defect.

### 10.1 Routes that exist (auth-gated) — the feature is unverified, not missing

| Endpoint | Probe | Used by |
|---|---|---|
| `/user/owner-bank.php` | 401 | Owner bank details (req 118) |
| `/user/owner-revenue.php` | 401 | Owner revenue reports (reqs 126–129) |
| `/user/owner-requests.php` | 401 | Owner cleaning / meal / extra-bed requests (reqs 60, 62, 65, 67, 70) |
| `/user/owner-maintenance.php` | 401 | Owner maintenance requests (reqs 69, 72) |
| `/user/owner-meals.php` | 401 | Owner meal list (req 65) |
| `/user/owner-staff.php` | 401 | Owner staff management (req 75) |
| `/hotel/requests.php` | 401 | Hotel-side request handling (reqs 83, 85, 86, 88, 90–92) |
| `/hotel/prices.php` | 401 | Service pricing, hotel and owner (reqs 68, 82, 84, 87, 89) |
| `/hotel/bookings.php` | 401 | Hotel check-in / check-out (reqs 78, 79) |
| `/hotel/dashboard.php` | 401 | Hotel dashboard (req 80) |
| `/user/agent-clients.php` | 401 | Agent client list (reqs 93, 99) |
| `/user/agent-commission.php` | 401 | Agent commissions (reqs 108, 109) |

### 10.2 Routes that exist but are `POST`-only

| Endpoint | Probe | Used by |
|---|---|---|
| `/bookings/create.php` | 405 | Booking creation (reqs 144–148) |
| `/bookings/manage.php` | 405 | Booking edit / cancel (reqs 40–43) |
| `/services/request.php` | 405 | Guest maintenance / cleaning request (reqs 57–59) |
| `/services/meal-request.php` | 405 | Guest meal request (reqs 49, 53) |

### 10.3 Routes that do **not** exist — genuine backend gaps

These are the reason the corresponding matrix items are `BACKEND BLOCKED` or
`PARTIAL`. None of them can be created from this repository.

| Missing route | Blocks | Requirement |
|---|---|---|
| `/auth/forgot-password.php` (and every `auth/forgot*` path) | Password reset — the login screen routes to Help & Support instead of a dead button | 110 |
| `/services/my-requests.php`, `/services/requests.php`, `/services/my_service_requests.php` | Guest viewing their own service-request status | 59 (partly) |
| `/user/owner-subscription.php`, `/subscription/status.php` | Owner annual subscription, gating, payment page, terms | 121–125 |
| `/user/owner-prices.php` | Owner-specific price endpoint (the hotel endpoint is reused) | 68 |
| `/user/agent-bank.php`, `/user/agent-commission-transfer.php`, `/user/agent-payout.php`, `/user/agent-commission-withdraw.php` | Agent commission transfer / payout | 108, 109 |
| any wallet / ledger / payout route | Owner wallet, ledger, weekly payout, split payment | 132–143 |

### 10.4 One mobile-side dependency worth naming

`units/detail.php` returns **no** `facilities` or `amenities` key. The unit-detail
screen therefore renders the service-category sections only from what the
endpoint actually sends, and the matrix item (76) records that the amenity
relationship for a *unit* has to come from the server before the section can be
populated with real data. Hotel amenities are unaffected — `hotels/detail.php`
does return them (11 for hotel 4).

### 10.5 `hotels/list.php` ignores `type` and `category_id`

Probed on 2026-10-19. Every value returns the same 4 rows:

| Query | Rows returned |
|---|---|
| `?type=Hotel` | 4 |
| `?type=Resorts` | 4 |
| `?type=Chalet` | 4 |
| `?type=Apartment` | 4 |
| `?type=فندق` | 4 |
| `?category_id=1` … `?category_id=4` | 4 each |
| no filter | 4 |

The website's `?type=` filter is equally inert, so this is a server-side gap,
not a client misuse. **The app must keep filtering category on the client** —
`HotelService.filterHotels` does exactly that, and `test/widgets_test.dart`
locks the behaviour in so a future "optimisation" cannot drop it.

**Consequence found and fixed in the client (real defect).** Because the client
had to filter locally, the category name had to match `type_ar`/`type_en`. The
category rows are plural (`فنادق`, `منتجعات`, `شاليهات`, `شقق فندقية`) but the
hotel rows are singular (`فندق`, `منتجع`, `شاليه`). A plain substring test
therefore returned **zero hotels for every Arabic category**, and — because the
search screen constrains units to the hotels of the chosen category via
`hotel_id` — the units section went empty too. English only worked by luck:
`"hotel".contains("hotels")` is false but `"hotels".contains("hotel")` is true,
and the old code tried both directions.

Fixed by canonicalising both sides before comparison (regular plural suffixes
plus an explicit broken-plural alias table). Verified live: the real
`فنادق` category now returns the 4 real hotels. Covered by a unit test and a
live integration test.

**Ask for the backend owner:** honour `category_id` (preferred — it is a real
foreign key) or `type` in `hotels/list.php` and `units/browse.php`, so the app
can stop filtering client-side and paginate correctly.
