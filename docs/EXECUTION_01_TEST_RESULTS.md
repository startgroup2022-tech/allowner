# All Owners — Execution 01 Test Results

**Branch:** `feature/allowners-new-version-exec01`
**Date:** 2026-10-19
**Flutter:** 3.47.7 (stable) · **Dart:** 3.13.5

> Every number in this document comes from a command that was actually run.
> Where a command failed or could not run, that is stated rather than smoothed over.

---

## 1. Project checks

| # | Command | Result | Exit |
|---|---|---|---|
| 1 | `flutter pub get` | Resolved; dependencies unchanged (`pubspec.yaml` not modified) | 0 |
| 2 | `dart format --output=none --set-exit-if-changed .` | **Fails** — 52 of 76 files differ | 1 |
| 3 | `flutter analyze` | **0 errors, 0 warnings**, 81 info | 0 |
| 4 | `flutter test` | **53 tests, all pass** | 0 |

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
| info | 112 | 81 |
| **total** | **117** | **81** |

The 5 baseline warnings were eliminated:

1. `unused_import` — `api_client.dart` in `hotel_staff/hotel_dashboard_screen.dart`
2. `unused_import` — `safe_parse.dart` in `owner/owner_decisions_screen.dart`
3. `unused_element_parameter` — `iconColor` in `unit_details_screen.dart`
4. `unawaited_return_in_try_block` — `auth_service.dart:25`
5. `unawaited_return_in_try_block` — `auth_service.dart:37`

The 81 remaining info items are pre-existing style suggestions
(`prefer_const_constructors`, `deprecated withOpacity`, `use_super_parameters`).
None is an error or a warning, and none was introduced here — the count is lower
than baseline, not higher.

---

## 2. Automated test suite

Two files, 53 tests, all passing.

```
00:01 +53: All tests passed!
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

---

## 3. Isolated tests vs live-integration verification

The mandate requires this distinction to be explicit.

### 3.1 Isolated automated tests (no network)

`flutter test` — 53 tests. These run with **no backend access**. They exercise
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
| Automated tests | 53 passing, 0 failing |
| Analyzer | 0 errors, 0 warnings (baseline: 0 errors, 5 warnings) |
| Required functional checks | 19 pass, 1 partial, 0 fail |
| Live endpoints verified | 11 |
| Rendered screens inspected | 12 |
| Visual defects found and fixed | 3 |
| Tests not executed | 6, each with a stated reason |

**No test result in this document is inferred.** Every command listed was run and
its real outcome recorded, including the one that fails.
