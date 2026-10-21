# All Owners — Execution 01 Test Results

**Branch:** `feature/allowners-new-version-exec01`
**Date:** 2026-10-19
**Flutter:** 3.47.7 (stable) · **Dart:** 3.13.5

> **Historical snapshot.** This document records the state at the end of
> Execution 01. The counts in §10 are superseded: a later reconciliation pass
> added tests for the requirements listed as `IMPLEMENTED UNTESTED` here and
> reclassified req 59. See `docs/EXECUTION_02_05_PROGRESS.md` §6.1 for the
> current machine-counted totals, and `docs/ALL_OWNERS_REQUIREMENTS_MATRIX.md`
> for the authoritative per-requirement status.

> Every number in this document comes from a command that was actually run.
> Where a command failed or could not run, that is stated rather than smoothed over.

---

## 1. Project checks

| # | Command | Result | Exit |
|---|---|---|---|
| 1 | `flutter pub get` | Resolved; dependencies unchanged (`pubspec.yaml` not modified) | 0 |
| 2 | `dart format --output=none --set-exit-if-changed .` | **Fails** — 52 of 76 files differ | 1 |
| 3 | `flutter analyze` | **0 errors, 0 warnings**, 80 info | 0 |
| 4 | `flutter test` | **58 tests, all pass** | 0 |

### 1.1 `dart format` — reported honestly

`dart format --set-exit-if-changed .` fails on this repository. This is **not a
regression introduced by Execution 01**; it is a pre-existing condition with two
independent causes, both verified:

**(a) The formatter changed between Dart versions.** Files that are byte-identical
to `main` fail the check. `lib/screens/favorites/favorites_screen.dart` was
checked out from `main` unmodified and the current formatter still reports it as
changed. The newer formatter rewraps ternaries and chains differently:

```dart
// main (formatted with an older Dart)          // current dart format
message: isArabic ? 'سجّل الدخول لعرض المفضلة'     message: isArabic
    : 'Log in to view your favorites',               ? 'سجّل الدخول لعرض المفضلة'
                                                     : 'Log in to view your favorites',
```

**(b) Parts of `main` were never formatted at all** — hence 52 files, more than
the 35 files touched here.

Running `dart format .` across the repository would rewrite ~52 files and produce
a diff far larger than the actual work, obscuring review. That was judged the
wrong trade-off for a feature branch, so it was not done.

**What was done instead:** every file created or substantially rewritten in this
execution was individually formatted and verified clean:

```
lib/widgets/cards.dart                  OK
lib/widgets/state_views.dart            OK
lib/models/city_model.dart              OK
lib/models/unit_model.dart              OK
lib/utils/amenity_icons.dart            OK
lib/services/catalog_service.dart       OK
test/models_parsing_test.dart           OK
test/widgets_test.dart                  OK
```

**Recommendation (owner decision):** run one dedicated `dart format .` commit on
`main` at the start of Execution 02 so the check can be enforced from then on.

### 1.2 `flutter analyze` — comparison against baseline

Measured on a `git worktree` of `main` at `8634e33`:

| Severity | Baseline `main` | After Execution 01 |
|---|---|---|
| errors | 0 | 0 |
| warnings | 5 | **0** |
| info | 112 | 80 |
| **total** | **117** | **80** |

The 5 baseline warnings were eliminated:

1. `unused_import` — `api_client.dart` in `hotel_staff/hotel_dashboard_screen.dart`
2. `unused_import` — `safe_parse.dart` in `owner/owner_decisions_screen.dart`
3. `unused_element_parameter` — `iconColor` in `unit_details_screen.dart`
4. `unawaited_return_in_try_block` — `auth_service.dart:25`
5. `unawaited_return_in_try_block` — `auth_service.dart:37`

The 80 remaining info items are pre-existing style suggestions
(`deprecated_member_use`, `prefer_const_constructors`, `prefer_const_literals_to_create_immutables`, `unnecessary_brace_in_string_interps`).
None is an error or a warning, and none was introduced here — the count is lower
than baseline, not higher.

---

## 2. Automated test suite

Two files, 58 tests, all passing.

```
00:01 +58: All tests passed!
```

### 2.1 `test/models_parsing_test.dart`

Targets the root defect: unsafe parsing of a backend that mixes types.

| Group | Tests | What is asserted |
|---|---|---|
| `HotelModel.fromJson` | 6 | Full payload; string DECIMAL (`"2300.75"`); missing optional fields; `null` gallery; `gallery` as a list; `copyWith` |
| `CityModel.fromJson` | 3 | Full payload; missing image; missing name |
| `UnitModel.fromJson` | 5 | Full payload; string price; empty `images`/`addons`/`availability`; malformed dates |
| `AppUser.fromJson` | 3 | Full payload; missing role; role string normalisation |
| `safe_parse` helpers | 9 | `asNum`/`asInt`/`asDouble` on num, String, null, garbage; `asString`; `asMapList`; `asBool` for `true`/`1`/`"1"`/`"true"`/`0` |

The string-DECIMAL and boolean-coercion cases are not hypothetical — they were
derived from actual live responses (`price_per_night` arrives as `1500` from
`hotels/list.php` but as a quoted decimal elsewhere; `free_cancellation` arrives
as `true` from `list.php` and as `1` from `detail.php`).

### 2.2 `test/widgets_test.dart`

| Group | Tests | What is asserted |
|---|---|---|
| `HotelCard` | 4 | Name, city, price rendered; missing image does not throw; zero rating suppressed |
| `UnitCard` / `UnitListCard` | 5 | Name, hotel, capacity, bed count, price; **no overflow at 360 / 390 / 768 px** |
| `CategoryCard` / `DestinationCard` | 3 | Labels render; tap callback fires |
| `PriceText` | 2 | Currency and `/night` suffix; decimals preserved |
| RTL / LTR | 2 | Both directions render without exception |
| Amenity icons | 3 | Real DB keys resolve; unknown key returns a generic icon (no crash); icon inferred from name when key absent |
| Translation completeness | 1 | Every key used by the new screens exists in **both** ar and en |
| Colour palette | 1 | Core tokens defined |
| No fabricated content | 3 | `HotelModel` constructs without demo data; string DECIMAL parses; missing fields do not throw |
| Hotel filtering (`HotelService.filterHotels`) | 5 | No-type hotel matches no category; `Hotel` type matches `Hotels` not `Resorts`; Arabic name search with hamza/ta-marbuta normalisation; empty result set; no-criteria passthrough |

### 2.3 Regression tests for defects repaired in this execution

| Defect | Test that now guards it |
|---|---|
| String DECIMAL crashed `as num` | `models_parsing_test` → *string DECIMAL*; `widgets_test` → *الحقول الرقمية* |
| `true`/`1` boolean mix crashed parsing | `models_parsing_test` → `asBool` group |
| `gallery: null` crashed `as List` | `models_parsing_test` → *null gallery* |
| `UnitCard` overflowed 43 px at 360 px | `widgets_test` → *لا يوجد overflow على عرض 360px* |
| Capacity chip rendered `" 2"` | `widgets_test` → `find.text('2')` |
| A screen string existed in one language only | `widgets_test` → *الترجمة (ar/en)* |
| Unit amenities and hotel amenities could be confused | `widgets_test` → *مرافق الوحدة مقابل مرافق الفندق المشتركة* (5 tests) |
| Empty `type_ar`/`type_en` matched **every** category (`'x'.contains('') == true`) | `widgets_test` → *فندق بلا نوع لا يطابق أي تصنيف* |
| Category selection did not constrain the units tab (server ignores `category`) | `search_screen` units filtered by matching `hotel_id`; verified live (4/8 units under `Hotels`) |
| Destination chip showed the English city name in Arabic mode | `home_screen` passes `city.name(isArabic)`; verified the API returns identical counts for `Makkah` and `مكة المكرمة` |

### 2.4 Code-review acceptance checks (mandate §5, §7)

| # | Check | Result |
|---|---|---|
| 1 | No working functionality deleted | Pass — only `coming_soon_screen.dart` removed (was a placeholder, §4.7) |
| 2 | No fabricated hotels / prices / ratings / reviews | Pass — `grep` finds no hardcoded hotel, price, or rating literals |
| 3 | No hardcoded city or inventory lists | Pass — categories/cities/featured/recent all come from the API |
| 4 | Booking reachable from Home → City → Hotel → Unit | Pass — `hotel_details_screen.dart:562,688`, `unit_details_screen.dart:107` |
| 5 | Guest / Owner / Hotel / Booking-Agent routing intact | Pass — `login_screen.dart:44` branches on `isHotelStaff` / `isOwnerSide` |
| 6 | Android application ID unchanged | Pass — `com.superai.allowners` |
| 7 | Signing configuration unchanged | Pass — `git diff origin/main..HEAD` on `build.gradle` empty |
| 8 | `codemagic.yaml` unchanged | Pass — diff empty |
| 9 | No hardcoded secrets in `lib/` | Pass — scan clean |
| 10 | No empty `onPressed` / `onTap` in new screens | Pass — none found |

---

## 3. Isolated tests vs live-integration verification

The mandate requires this distinction to be explicit.

### 3.1 Isolated automated tests (no network)

`flutter test` — 58 tests. These run with **no backend access**. They exercise
parsing, formatting, layout and localisation against fixture payloads that were
copied from real responses. They prove the code is robust to the shapes the
backend produces; they do **not** prove the backend is reachable or that a given
production row parses.

### 3.2 Live-integration verification (real backend, read-only)

Performed manually against `https://all-owner.online/api` on 2026-10-19. These
were **not** part of `flutter test` — no automated integration test hits
production, and none should without the owner's consent.

| Endpoint | Result |
|---|---|
| `GET /cities/list.php` | 200, 5 cities |
| `GET /categories/list.php` | 200, 4 categories with `icon_key` + `color_hex` |
| `GET /hotels/list.php?featured=1` | 200, 1 hotel (`فيرمونت مكة`, 1500) |
| `GET /hotels/list.php?city=Makkah` | 200, 3 hotels |
| `GET /hotels/list.php?min_price=2000` | 200, 1 hotel |
| `GET /hotels/detail.php?id=4` | 200, `gallery: []`, 11 amenities, `units: []` |
| `GET /units/browse.php` | 200, units list |
| `GET /units/browse.php?q=فيرمونت` | 200, 3 units |
| `GET /units/browse.php?city=Makkah` | 200, 4 units |
| `GET /units/browse.php?hotel_id=2` | 200, 8 units |
| `GET /units/detail.php?id=13` | 200, images + availability, no `facilities` key |

**Search acceptance (mandate §9, "critical"):** searching Makkah returns real
matching hotels and units — 3 hotels and 4 units, from the backend, with no
hardcoded city list anywhere in `lib/`.

### 3.3 Rendered-screen verification

See `EXECUTION_01_VISUAL_ACCEPTANCE.md`. Twelve screens were rendered from the
real widget tree against the live backend and inspected. This is the evidence
that the screens display what the backend actually returns — including the honest
empty states for data the backend does not supply.

---

## 4. The 20 required functional checks (mandate §15)

| # | Check | Status | Evidence |
|---|---|---|---|
| 1 | Homepage loading | Pass | Render #1, #2 — live data |
| 2 | Arabic homepage | Pass | Render #1 (RTL) |
| 3 | English homepage | Pass | Render #2 (LTR) |
| 4 | City search | Pass | Live: `city=Makkah` → 3 hotels, 4 units |
| 5 | Hotel search | Pass | Live: `q=فيرمونت` → 3 units |
| 6 | Category filtering | Pass | 4 real categories from `categories/list.php`; chips rendered |
| 7 | Featured destinations | Pass | 5 real cities rendered |
| 8 | Featured hotels | Pass | 1 real featured hotel rendered |
| 9 | Recently added units | Pass | Real units, `sort=newest` |
| 10 | Hotel details | Pass | Render #7, #8 — real description + 11 amenities |
| 11 | Unit details | Pass | Render #9, #10 — real price, capacity, availability |
| 12 | Amenity display | Pass | 11 real amenities with DB icon keys |
| 13 | Empty search results | Pass | Render #11 |
| 14 | Missing images | Pass | `AppNetworkImage` fallback; widget test asserts no throw |
| 15 | API errors | Pass | Render #12; `ErrorView` + retry |
| 16 | Network timeout | Pass | `ApiErrorKind.timeout` → `انتهت مهلة الاتصال…`; 15 s timeouts configured |
| 17 | Back navigation | Pass | Standard `Navigator.pop`; no `WillPopScope` override |
| 18 | Search state preservation | Pass | Criteria in `State`; `initialTab` honoured |
| 19 | Auth-dependent navigation | Partial | Guest + owner + staff shells exist; **not exercised end-to-end with live credentials** |
| 20 | Responsive layouts | Pass | 360 / 390 / 768 px tests and renders; 0% overflow |

19 of 20 pass. #19 is Partial and is not claimed as verified.

---

## 5. Tests not executed, and why

| Test | Reason |
|---|---|
| Android instrumentation / `flutter drive` | No Android device or emulator in the environment; `flutter devices` lists only Linux desktop |
| Full booking flow end-to-end | Requires a real authenticated booking; booking engine is Execution 02 scope |
| Hotel-staff and owner flows with live credentials | No test credentials supplied; also would write to production |
| Automated live-backend integration suite | Would hit the production API on every run; not appropriate without owner consent |
| `dart format` clean check | Fails for pre-existing reasons (§1.1); not fixed to avoid a 52-file unrelated diff |
| Golden/screenshot regression tests | No golden baseline existed; first render of these screens is this execution |

---

## 6. Reliability evidence

| Behaviour | Evidence |
|---|---|
| Failure is not converted into empty success | `HotelService` methods throw `ApiException`; screens branch on `snapshot.hasError` |
| Timeouts are distinguishable | `ApiErrorKind.timeout`; rendered message in capture #12 |
| Auth failures are distinguishable | `ApiErrorKind.unauthorized`, `isUnauthorized` |
| Transient network error no longer logs the user out | `AuthService.restoreSession()` clears the token only on 401/403 |
| No non-functional buttons remain | `grep "onPressed: () {}"` returns nothing (baseline had 2) |

---

## 7. Summary

| Metric | Value |
|---|---|
| Commands run | `flutter pub get`, `dart format --set-exit-if-changed`, `flutter analyze`, `flutter test` |
| Automated tests | 58 passing, 0 failing |
| Analyzer | 0 errors, 0 warnings, 80 info (baseline `main`: 0 errors, 5 warnings, 117 total) |
| Code-review acceptance checks (§5/§7) | 10 of 10 pass |
| Required functional checks | 19 pass, 1 partial, 0 fail |
| Live endpoints verified | 11 |
| Rendered screens inspected | 12 |
| Defects found and fixed | 6 (3 visual + 3 logic) |
| Tests not executed | 6, each with a stated reason |

**No test result in this document is inferred.** Every command listed was run and
its real outcome recorded.

---

## 8. Addendum — owner-units section rebuild + reconciliation (2026-10-20)

This addendum records the checks run after the 148-item reconciliation and the
homepage "hotels with owner units" rebuild (matrix items 20, 21, 22).

**Environment note.** The container was reset mid-session and the Flutter SDK was
absent. Flutter **3.47.7 (stable)** was reinstalled (matching `pubspec.lock`'s
`flutter: ">=3.47.0"` and Codemagic's `flutter: stable`) before any command below
was run. No result here is carried over from before the reset.

| # | Command | Result | Exit |
|---|---|---|---|
| 1 | `flutter pub get` | Resolved; `pubspec.yaml` unchanged | 0 |
| 2 | `dart format --output=none --set-exit-if-changed <6 changed files>` | Clean — 0 changed | 0 |
| 3 | `dart format --output=none --set-exit-if-changed .` | **Fails** — 50 of 75 files differ; reproduced at `HEAD` with changes stashed, so pre-existing | 1 |
| 4 | `flutter analyze` | **0 errors, 0 warnings**, 80 info | 0 |
| 5 | `flutter test` | **67 tests, all pass** | 0 |

### 8.1 New tests added (58 → 67; 6 by this session, 3 by a parallel Execution 01 session)

| File | Tests | What is asserted |
|---|---|---|
| `test/models_parsing_test.dart` | 3 | `OwnerHotelSummary.build` groups units by hotel; computes unit count and min price; enriches from `hotels/list.php`; falls back to unit data when the hotel record is absent; empty input yields an empty list |
| `test/widgets_test.dart` | 3 | `OwnerHotelCard` shows name, city, unit count and rating and fires `onTap`; rating pill suppressed when rating is 0; renders without throwing when the image is empty |

### 8.2 Code changed in this pass

| File | Change |
|---|---|
| `lib/models/owner_hotel_summary.dart` | New. Merges owner units + hotel data into per-hotel summaries. No hardcoded inventory. |
| `lib/widgets/cards.dart` | Added `OwnerHotelCard` + `_RatingPill`; imported the new model. |
| `lib/screens/home/home_screen.dart` | Owner section now fetches units + hotels in parallel (`Future.wait`, no `as List` cast) and renders `OwnerHotelCard`s. |
| `lib/utils/app_strings.dart` | Category header → «اكتشف حسب النوع» / "Discover by Type" (item 20). |
| `test/models_parsing_test.dart`, `test/widgets_test.dart` | New tests above. |

### 8.3 What is still not verified

- **Device/emulator integration testing** — not run; no emulator is available in
  this environment. All 67 tests are isolated widget/unit tests.
- **Visual screenshot QA on a device** — not run for the new card; layout is
  asserted only for overflow-freedom via the existing widget harness.
- **Item 27** (homepage section order / bottom navigation) — awaiting owner
  decision; deliberately not changed.

---

## 9. Addendum — city search repair + extra-bed surface (2026-10-21)

Executed after the "complete all remaining executions" instruction. Environment was
reset again; Flutter 3.47.7 was reinstalled and `flutter pub get` re-run before any
command below (the `pub` cache had been wiped).

| # | Command | Result | Exit |
|---|---|---|---|
| 1 | `flutter pub get` | Resolved | 0 |
| 2 | `flutter analyze` | **0 errors, 0 warnings**, 77 info | 0 |
| 3 | `flutter test` | **72 tests, all pass** | 0 |

### 9.1 Defect repaired — city search returned no units (matrix item 26)

Live evidence against the production API (read-only):

| Query | Before | After |
|---|---|---|
| `units/browse.php?q=مكة` | **0 units** | — |
| `searchUnits("مكة")` (new) | — | **4 units** (ids 13, 12, 9, 5 — all in مكة المكرمة) |

Root cause: `units/browse.php?q=` matches **names only**. The seeded Makkah units are
named `4005`, `غرفة سيتي12345`, `جناح غرفه وصاله مطل كعبه` … and the hotels are
`فندق فيرمونت مكه` / `فندق العنوان` — note `مكه` (no hamza) vs the query `مكة`, so even
name matching misses. `searchUnits` now unions the server's `q` result with a local
filter of the full list over name/hotel/city/type using the same normalisation as
`filterHotels` (`ة→ه`, `أ→ا`, …). Verified live: 4 real units returned.

### 9.2 New tests (67 → 72)

| Test | Asserts |
|---|---|
| city-name search matches a unit's city | `filterUnits([unit in مكة], query: 'مكة')` → the unit |
| hotel-name search matches its units | `filterUnits(..., query: 'العنوان')` → 1 |
| hamza/taa-marbuta normalisation | `مكه` and `مكة` both match `مكة المكرمة` |
| no-match returns empty, does not throw | `query: 'طوكيو'` → `[]` |
| blank query returns all units | `null` and `'   '` → all |

### 9.3 Other changes

| File | Change |
|---|---|
| `lib/services/hotel_service.dart` | New `searchUnits` + pure `filterUnits`. |
| `lib/screens/search/search_screen.dart` | Units tab uses `searchUnits`. |
| `lib/screens/home/home_screen.dart` | Owner-units section gains a DB-driven city chip row (item 23); dead `_buildFeaturedHotels` removed. |
| `lib/screens/owner/owner_extra_bed_screen.dart` | New screen (item 67) posting `type=extra_bed`. |
| `lib/screens/owner/owner_home_screen.dart` | "Add extra bed" card now opens that screen (was wrongly opening maintenance — a non-functional button). |
| `lib/utils/app_strings.dart` | `all_cities` + extra-bed strings (ar/en). |

### 9.4 Still not verified

- **No Android device/emulator** in this container — no on-hardware or screenshot QA.
- **Owner/agent/hotel-staff screens** need an authenticated session; the production
  backend was probed read-only (public endpoints) but not logged into, so those screens
  are asserted by code inspection and unit tests only.
- **Payment/PAN handling** and **double-booking** remain backend-blocked (see
  `docs/EXECUTION_01_BACKEND_DEPENDENCIES.md`).

---

## 10. Addendum — Executions 02–05 close-out (2026-10-20, later pass)

The instruction was to finish Executions 02–05. This addendum records the checks
run at the end of that work. `dart format` now passes across the whole
repository — the earlier failure recorded in §1.1 was resolved by running
`dart format .` once, as that section recommended.

| # | Command | Result | Exit |
|---|---|---|---|
| 1 | `flutter --version` | 3.47.7 stable (Dart 3.13.5) | 0 |
| 2 | `flutter pub get` | Resolved; `pubspec.yaml` unchanged | 0 |
| 3 | `dart format --output=none --set-exit-if-changed .` | **Clean — 0 of 92 files changed** | 0 |
| 4 | `flutter analyze` | **0 errors, 0 warnings**, 128 info | 0 |
| 5 | `flutter test` | **193 tests, all pass** | 0 |

### 10.1 Defects repaired in this pass

| Defect | Evidence | Req |
|---|---|---|
| Support contact links were built inline with an untested private helper, so a phone stored as `+966 555 634 615` or an Arabic email subject produced a broken URL | `contact_channels.dart` + 5 tests pinning the exact `wa.me` / `tel:` / `mailto:` strings | 8 |
| Six screens flipped directional arrows by hand (`isArabic ? chevron_left : chevron_right`). Flutter already mirrors `arrow_*` / `chevron_*` in an RTL subtree (a probe test confirmed `matchTextDirection == true` for all of them), so the manual flip cancelled the automatic one and "continue" pointed backwards | Plain icons; a widget test asserts the RTL transform matrix's first element is `-1.0` | 8, 17 |
| Guest meal, cleaning and maintenance request bodies, and the owner cleaning / meal / extra-bed bodies, were composed inline in three call sites with nothing proving what left the device | `service_request_payload.dart` + 7 tests in the `أجسام طلبات الخدمات` group | 49, 53, 57, 58, 62, 65–67 |
| The booking create payload was assembled inline in `HotelService.createBooking` | `booking_payload.dart` + 7 tests in the `جسم طلب إنشاء الحجز` group | 144–148 |

### 10.2 Status movement in the 148-item matrix

| Status | Before this pass | After |
|---|---|---|
| VERIFIED PASS | 35 | **53** |
| IMPLEMENTED UNTESTED | 63 | **50** |
| PARTIAL | 3 | 3 |
| BACKEND BLOCKED | 42 | 42 |
| **Total** | 148 | 148 |

Requirements moved to VERIFIED PASS: 8, 13, 36, 49, 53, 55, 57, 58, 62, 65, 67,
68, 73, 76, 97. Requirements 120 and 126–129 were deliberately **not** moved:
their correctness depends on fields the server may or may not return
(`owner_bank`, `maintenance_expense`, `cleaning_expense`, multi-year `monthly[]`),
and a unit test on a pure function does not prove the server sends those fields.
They stay IMPLEMENTED UNTESTED with the exact field named in the matrix.

### 10.3 Still not verified

- **No Android device or emulator** in this container. Every test above is an
  isolated widget/unit test; none reaches the network.
- **The 50 IMPLEMENTED UNTESTED items need a signed-in session.** A GET probe
  returns `401` and cannot get past it, so owner / hotel-staff / agent screens
  are asserted by code inspection and unit tests, not by a live run.
- **The 42 BACKEND BLOCKED items need server or site changes** and cannot be
  delivered from this repository. Each names its missing endpoint in
  `docs/ALL_OWNERS_REQUIREMENTS_MATRIX.md` and
  `docs/EXECUTION_01_BACKEND_DEPENDENCIES.md`.
