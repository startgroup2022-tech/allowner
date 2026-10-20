# All Owners — Execution 01 Technical Audit

**Repository:** https://github.com/startgroup2022-tech/allowner
**Branch:** `feature/allowners-new-version-exec01`
**Baseline commit:** `8634e33` (`Update pubspec.yaml`, `origin/main`)
**Audit date:** 2026-10-19
**Application:** All Owners (`allowners`) — Flutter / Dart
**Backend:** `https://all-owner.online/api` (live, read-only inspection)

> Scope note: the original 51-page requirements document and the 148-item inventory
> were **not present in the repository or workspace** at the time of this audit
> (see §9). Every requirement statement below is derived from the live source code
> and verified API contracts. Where the requirements document would be needed to
> resolve a decision, it is recorded as an owner decision, not invented.

---

## 1. Application architecture

### 1.1 Toolchain

| Item | Value | Source |
|---|---|---|
| Flutter | 3.47.7 (stable) | `flutter --version` |
| Dart | 3.13.5 | `flutter --version` |
| SDK constraint | `>=3.3.0 <4.0.0` | `pubspec.yaml` |
| App version | `2.2.1+20` | `pubspec.yaml` |
| Package name | `allowners` | `pubspec.yaml` |
| Android applicationId | `com.superai.allowners` | `android/app/build.gradle` |
| Android namespace | `com.superai.allowners` | `android/app/build.gradle` |
| Build platform | Codemagic | `codemagic.yaml` |

### 1.2 Folder structure

```
lib/
  main.dart                  app entry, MaterialApp, Directionality, providers
  models/                    6 typed models (hotel, unit, city, category, amenity, app_user)
  screens/                  74 files across 11 feature folders
    auth/ bookings/ booking/ favorites/ home/ hotel/ hotel_staff/
    onboarding/ owner/ profile/ search/ services/ shared/ unit/
  services/                  api_client, auth, hotel, catalog, owner, hotel_staff, content
  theme/                     app_colors, app_dimens, app_theme
  utils/                     safe_parse, app_strings, locale_provider,
                             session_provider, app_settings_provider, amenity_icons
  widgets/                   app_logo, cards, state_views, editable_avatar
```

74 Dart files, 16,586 lines.

### 1.3 Entry point and boot sequence

`main.dart` → `ProviderScope` → `AllOwnersApp`:

1. `localeProvider` (`StateNotifierProvider`) supplies the locale and is persisted in
   `SharedPreferences` under `app_locale`.
2. `AppTheme.light(isArabic:)` builds a locale-aware `ThemeData`.
3. A `builder` wraps the app in an explicit `Directionality`
   (`rtl` for Arabic, `ltr` for English) — this is deliberate: it guarantees RTL even
   if a nested `MaterialApp`/route loses the inherited direction.
4. `home:` is `SplashScreen` → animated 2.2 s logo → `OnboardingScreen` → main app.

### 1.4 State management

Riverpod 2.5.1, used consistently:

| Provider | Type | Responsibility |
|---|---|---|
| `localeProvider` | `StateNotifierProvider<LocaleNotifier, Locale>` | ar/en, persisted |
| `sessionProvider` | `StateNotifierProvider<SessionNotifier, SessionState>` | user, login/register/logout/restore |
| `appSettingsProvider` | settings notifier | app-level flags |
| Local screen state | `StatefulWidget` + `FutureBuilder` | per-screen lists |

No screen mixes a second state-management library. **No architectural change was
made in Execution 01** — the requirement to use the existing architecture was met.

### 1.5 Routing

Imperative `Navigator.push(MaterialPageRoute(...))` throughout; no named routes,
no router package. Each role has a dedicated shell:

| Role | Shell |
|---|---|
| Guest / Unit Owner (as guest) | `home/main_navigation_screen.dart` (5 tabs) |
| Unit Owner | `owner/owner_navigation_screen.dart` |
| Hotel Management | `hotel_staff/hotel_staff_navigation_screen.dart` |

### 1.6 Localization

`AppStrings.t(isArabic, key)` with a flat `Map<String, Map<String, String>>`
(`lib/utils/app_strings.dart`). Both languages are always present for every key —
verified by an automated test added in this execution
(`test/widgets_test.dart` → *الترجمة (ar/en)*).

### 1.7 Error handling (after Execution 01)

`ApiException` carries a message plus an `ApiErrorKind`
(`network, timeout, unauthorized, notFound, server, badResponse, unknown`).
Derived flags `isRetryable` and `isUnauthorized` let screens decide between
*retry* and *re-login*. Failure is **never** silently converted to an empty list.

### 1.8 Baseline state, measured

All comparisons below were made against a `git worktree` of `main` at `8634e33`,
not from memory.

| Metric | Baseline `main` | After Execution 01 |
|---|---|---|
| Dart files in `lib/` | 66 | 74 |
| Lines in `lib/` | 14,330 | 16,728 |
| Test files | 0 | 2 |
| `flutter analyze` — errors | 0 | 0 |
| `flutter analyze` — warnings | 5 | **0** |
| `flutter analyze` — info | 112 | 81 |
| `dart format --set-exit-if-changed` | fails (52 files) | new files clean (see §9) |

The five baseline warnings were: two unused imports, one unused optional
parameter, and two `unawaited_return_in_try_block` in `auth_service.dart`.

### 1.9 What the baseline actually contained

Verified by inspecting the `main` worktree. This matters because the mandate's
prohibitions ("do not introduce fake data", "do not create nonfunctional
buttons") describe defects that were genuinely present.

| Baseline defect | Evidence | Status now |
|---|---|---|
| Fabricated demo hotels (`Ritz Carlton Riyadh`, `Al Faisaliah Suites`, `Jeddah Hilton Corniche`, `Shaza Makkah`, plus Unsplash stock photos) in `HotelModel.demoList()` | `main:lib/models/hotel_model.dart:74` | **Removed** |
| Fabricated hotel description generated from the hotel name | `main:lib/screens/hotel/hotel_details_screen.dart:95` | **Removed** — real `description_ar/en` or explicit empty state |
| Two fabricated guest reviews (محمد العتيبي / سارة القحطاني) with invented ratings and comments | `main:.../hotel_details_screen.dart:486,494` | **Removed** |
| Non-functional "see all reviews" button (`onPressed: () {}`) | `main:.../hotel_details_screen.dart:480` | **Removed** with the review block |
| Non-functional "forgot password" button (`onPressed: () {}`) | `main:lib/screens/auth/login_screen.dart:159` | **Fixed** — routes to the real Help & Support screen (no reset endpoint exists; all `auth/forgot*` paths return 404) |
| Hardcoded 5-category list with inline icons and colours | `main:lib/screens/home/home_screen.dart:83` | **Replaced** with `categories/list.php` |
| Hardcoded `_mainCities = ['مكة المكرمة', 'المدينة المنورة', 'الرياض', 'جدة']` | `main:lib/screens/home/home_screen.dart:32` | **Replaced** with `cities/list.php` |
| No `widgets/cards.dart`, no `widgets/state_views.dart`, no `test/` | `git ls-tree` | **Created** |

`demoList()` had no caller even in the baseline — the screens already used
`HotelService`. It was nonetheless fabricated inventory living in the shipped
model, and it is gone.

---

## 2. Authentication and roles

| Role | Implemented | Evidence |
|---|---|---|
| Guest | Yes | `main_navigation_screen.dart`; guest browse works with no token |
| Unit Owner | Yes | `owner_navigation_screen.dart`, 24 owner screens, `owner_service.dart` |
| Hotel Management | Yes | `hotel_staff_navigation_screen.dart`, 6 hotel-staff screens |
| Booking Agent | Partial | agent endpoints exist server-side; no dedicated mobile shell |
| Administrator | No | not present in the mobile application |

Role is carried in `AppUser.role` and read from the login/register response.

**Defect found and fixed (AUTH-1).** `AuthService.restoreSession()` previously
cleared the stored token whenever the restore request failed for *any* reason.
A momentary network drop therefore logged the user out permanently. It now clears
the token only on HTTP **401/403** (`isUnauthorized`); network/timeout/server
errors preserve the session. See `lib/services/auth_service.dart`.

**Defect found (AUTH-2, open).** There is no automatic redirect to the login
screen when a *later* authenticated call returns 401 — screens surface the error
but the shell keeps rendering the logged-out UI. Deferred to Execution 02 (it
touches the shared session provider and all three shells).

---

## 3. API integration

Base URL: `ApiConfig.baseUrl = https://all-owner.online/api`
(`lib/services/api_client.dart`). One shared `Dio` instance with a request
interceptor that injects `Authorization: Bearer <token>` from `SharedPreferences`.

| Setting | Value |
|---|---|
| connectTimeout | 15 s |
| receiveTimeout | 15 s |
| Content-Type | `application/json` |

### 3.1 Endpoints verified live (read-only)

| Endpoint | Verified response |
|---|---|
| `GET /hotels/list.php` | `{success, hotels[]}`; supports `city`, `featured`, `stars`, `min_price`, `max_price`. **No text search.** |
| `GET /hotels/list.php?featured=1` | 1 real featured hotel (`فيرمونت مكة`) |
| `GET /hotels/list.php?city=Makkah` | 3 hotels (accepts Arabic or English city) |
| `GET /hotels/list.php?min_price=2000` | 1 hotel at 3000 |
| `GET /hotels/detail.php?id=4` | `{success, hotel{}, gallery:[], amenities[], reviews[]}` (gallery/amenities/reviews are top-level) |
| `GET /units/browse.php` | `{success, units[]}`; supports `q`, `city`, `hotel_id`, `owner_only`, `min_price`, `max_price`, `min_capacity`, `sort`, `limit` |
| `GET /units/browse.php?q=فيرمونت` | 3 units |
| `GET /units/browse.php?city=Makkah` | 4 units |
| `GET /units/browse.php?hotel_id=2` | 8 units |
| `GET /units/detail.php?id=13` | `{success, unit{... images[], addons[], availability[], owner_bank}}` |
| `GET /cities/list.php` | `{success, cities[]}` — 5 real cities |
| `GET /categories/list.php` | `{success, categories[]}` — 4 real categories with `icon_key` + `color_hex` |

### 3.2 Field-shape findings (the real source of the previous crashes)

The backend returns the same column as a **number or a string** depending on the
endpoint and row:

- `price_per_night`: `1500` (int) in `hotels/list.php`, `"2300.75"` in some rows.
- `free_cancellation` / `breakfast_included` / `is_featured`: `true` in
  `hotels/list.php` but `1` / `0` in `hotels/detail.php`.
- `unit_type_en`: frequently `null` while `unit_type_ar` is present.
- `gallery`: `[]` on `hotels/detail.php?id=4`, and empty for ids 1–4.
- `addons` / `availability`: present but empty (`[]`) on most units.

Direct casts (`as int`, `as num`, `as List`) therefore threw on real data. All of
these are now routed through `lib/utils/safe_parse.dart`.

### 3.3 Cast hardening applied in Execution 01

| File | Change |
|---|---|
| `services/owner_service.dart` | 24 unsafe casts → `asMapList` / `asInt` / `asDouble` / `asMap` |
| `services/hotel_staff_service.dart` | 6 unsafe casts → safe helpers |
| `services/content_service.dart` | `res.data as Map` → `asMap(res.data)` |
| `screens/**` (18 files) | `x['id'] as int` → `asInt(x['id'])` |
| `screens/search/search_screen.dart` | `result['min_price'] as double?` → `asDoubleOrNull(...)` |
| `screens/owner/owner_decisions_screen.dart` | `asInt(d['my_vote'])?` → `asIntOrNull(...)` |

### 3.4 Remaining unsafe casts (open, non-blocking)

Local-list casts such as `(data['items'] as List?)?.cast<Map<String, dynamic>>()`
remain in 6 owner screens. They are already null-guarded (`?? []`) so they do not
throw on a missing key, but they would throw if the key held a non-list. Tracked as
`API-2` for Execution 02.

---

## 4. Existing screen inventory and classification

Classification rule applied: a screen is *working and verified* only if it renders
**real backend data** in a captured render, not merely because a widget builds.

### 4.1 Guest / shared

| Screen | File | Status |
|---|---|---|
| Splash | `splash_screen.dart` | Working and verified |
| Onboarding | `onboarding/onboarding_screen.dart` | Working, not tested |
| Main navigation | `home/main_navigation_screen.dart` | Working and verified |
| **Homepage** | `home/home_screen.dart` | **Redesigned — working and verified** |
| **Search** | `search/search_screen.dart` | **Redesigned — working and verified** |
| Filters sheet | `search/filters_sheet.dart` | Working and verified |
| **Hotel details** | `hotel/hotel_details_screen.dart` | **Redesigned — working and verified** |
| **Unit details** | `unit/unit_details_screen.dart` | **Redesigned (existing) — working and verified** |
| Booking | `booking/booking_screen.dart` | Working, not fully tested (Exec 02) |
| Booking success | `booking/booking_success_screen.dart` | Working, not tested |
| My bookings | `bookings/my_bookings_screen.dart` | Working, not tested |
| Favorites | `favorites/favorites_screen.dart` | Working, not tested |
| Profile | `profile/profile_screen.dart` | Working, not tested |
| Login / Register | `auth/*.dart` | Working, not tested |
| Content page | `shared/content_page_screen.dart` | Working, not tested |
| Help & support | `shared/help_support_screen.dart` | Working, not tested |
| Coming soon | ~~`shared/coming_soon_screen.dart`~~ | **Removed 2026-10-19** — static analysis and a repo-wide search confirmed zero callers (see §8) |

### 4.2 Unit Owner (24 screens)

| Screen | Status |
|---|---|
| Owner navigation, home | Working and verified |
| Owner units | Working and verified (cast-hardened) |
| Owner add unit | Working and verified (cast-hardened) |
| Owner bookings | Working and verified (cast-hardened) |
| Owner cleaning | Working and verified (cast-hardened) |
| Owner maintenance | Working and verified (cast-hardened) |
| Owner meal requests | Working and verified (cast-hardened) |
| Owner revenue | Working and verified (cast-hardened) |
| Owner commission | Working, not tested |
| Owner clients | Working and verified (cast-hardened) |
| Owner marketplace | Working and verified (cast-hardened) |
| Owner community | Working and verified (cast-hardened) |
| Owner decisions | Working and verified (cast-hardened) |
| Owner documents | Working, not tested |
| Owner staff | Working and verified (cast-hardened) |
| Owner messages / chat thread | Working, not tested |
| Owner notifications | Working, not tested |
| Owner profile | Working, not tested |

### 4.3 Hotel Management (6 screens)

`hotel_staff_navigation_screen`, `hotel_dashboard_screen`,
`hotel_bookings_screen`, `hotel_prices_screen`, `hotel_requests_screen`,
`hotel_profile_screen` — all working and verified (cast-hardened); none are
end-to-end tested against a hotel-staff account in this execution.

### 4.4 Services

`hotel_services_screen`, `meal_request_screen`, `service_request_screen` —
working and verified (cast-hardened).

### 4.5 Broken / missing / blocked

| Item | Status |
|---|---|
| Booking engine completion | Partially implemented — deferred to Execution 02 by direction |
| Booking Agent shell | Missing — backend has agent endpoints, no mobile shell |
| Hotel gallery (`gallery` key) | Limited — `hotels/detail.php` returns `gallery: []` for all hotels |
| Unit facilities/amenities | Blocked — `units/detail.php` returns no `facilities`/`amenities` key |
| Hotel → units list in detail | Blocked — `hotels/detail.php` returns `units: []`; units are fetched separately via `units/browse.php?hotel_id=` |

---

## 5. Localization and RTL

- Arabic is the default locale (`LocaleNotifier` starts at `Locale('ar')`).
- Explicit `Directionality` at the app root.
- Automated tests assert RTL and LTR rendering of the shared cards.
- **Deliberate non-mirroring:** search, back, and chevron icons are left
  un-mirrored where the glyph carries semantic direction; layout mirroring is
  handled by `AlignmentDirectional` / `EdgeInsetsDirectional` rather than by
  flipping icons.

---

## 6. Performance and reliability work

| Area | Change |
|---|---|
| Duplicate requests | Search debounce (400 ms) + single in-flight future per tab |
| Search state | Tab and criteria preserved across navigation; `initialTab` honoured |
| Rebuilds | Homepage builds section futures once in `initState`, not per build |
| Image loading | `AppNetworkImage` with `cached_network_image` + explicit error/placeholder |
| Async lifecycle | `if (!mounted) return;` guards on all awaited `setState` paths |
| Error recovery | `ErrorView` with retry on every network-backed section |
| State cleanup | `Timer`/`TextEditingController`/`ScrollController` disposed |

---

## 7. Codemagic compatibility

`codemagic.yaml` inspected. Three workflows:
`android-apk-debug-real`, `android-apk-debug`, `android-aab-release`.

Preserved in this execution:

- Flutter project layout (`pubspec.yaml` at repo root, `lib/`, `android/`).
- `PACKAGE_NAME: com.superai.allowners` — unchanged.
- Android `applicationId` / `namespace` `com.superai.allowners` — unchanged.
- `android_signing: [allowners_keystor]` reference — unchanged.
- `key.properties` generation block — unchanged.
- No signing key generated, replaced, or committed.
- No AAB produced or published in Execution 01.

`analysis_options.yaml` gained an `exclude` list (`build/**`, `android/**`,
`ios/**`) so `flutter analyze` reports only `lib/` and `test/`. This does not
affect the Codemagic build steps.

---

## 8. Repository hygiene

The repository has **no `.gitignore`**, so build artefacts are untracked noise:

```
?? .dart_tool/   ?? build/   ?? pubspec.lock   ?? android/local.properties
?? ios/Flutter/  ?? ios/Runner/GeneratedPluginRegistrant.*
?? android/app/src/main/java/
```

None of these were committed. Adding a `.gitignore` is recommended (owner
decision — see §9) because `pubspec.lock` for an application should normally be
committed, while `build/`, `.dart_tool/` and `local.properties` must not.

`ComingSoonScreen` had **no caller** anywhere in `lib/`. Navigation in this app
is entirely imperative (`Navigator.push` with `MaterialPageRoute`); there is no
`routes:` table and no `pushNamed`, so no string-based route could reach it
either. `flutter analyze` reported no reference and the repo-wide search found
none, so the owner's condition for removal (“remove only if static analysis and
repository-wide search confirm it is unused”) was satisfied. The screen and its
now-orphaned `coming_soon_desc` string were **removed** in the 2026-10-19 review
pass. `CLEAN-1` is closed.

---

## 9. Missing inputs and owner decisions

| # | Item | Impact |
|---|---|---|
| 1 | The original 51-page requirements document is **not in the repository or workspace** | Requirement IDs and page citations cannot be asserted; see the matrix for how this is handled |
| 2 | The 148-item inventory is **not in the repository or workspace** | The matrix cannot be reconciled line-by-line against it |
| 3 | ~~No `.gitignore`~~ | **Resolved** — `.gitignore` added; build artefacts no longer untracked noise |
| 4 | ~~Booking Agent role has no mobile shell~~ | **Resolved by owner** — in mobile scope; already implemented via the owner shell |
| 5 | Amenity relations for units are absent server-side | **Mitigated** — per the owner decision, unit amenities and shared hotel amenities are shown as two clearly separated sections; live unit data is still empty |
| 6 | Administrator mobile role | **Resolved by owner** — web-based unless the original document requires mobile admin (document unavailable) |

Per the mandate — *"Do not invent business rules when the requirements are
unclear"* — items 1 and 2 are reported as blockers on full reconciliation rather
than filled with assumptions.

---

## 10. Audit conclusion

The application is a coherent, single-architecture Flutter app with a working
backend contract and three role shells. Its principal real defect was **unsafe
JSON parsing against a backend that legitimately mixes numbers, strings, booleans
and nulls** — which surfaced to users as blank or crashing screens rather than as
honest error states. That defect is fixed across services, models and screens in
this execution, verified by 58 automated tests and by rendered evidence against
the live backend.

The homepage, search, hotel-detail and unit-detail experiences were redesigned
and are verified working on real data. Hardcoded city/hotel/category/amenity
lists and fabricated hotel descriptions and reviews were removed and replaced with
backend-driven data.

Remaining work is enumerated in `ALL_OWNERS_REQUIREMENTS_MATRIX.md` and in the
final acceptance report.

---

## 11. Code review and acceptance corrections

A second review pass was run after the first submission, against the live backend
and the mandate's §5/§7 rules. It found and fixed three additional logic defects
that the first pass missed. All three were confirmed against real API responses
before and after the fix.

### 11.1 Defect — empty `type_ar`/`type_en` matched every category

`HotelService.searchHotels` tested category membership with
`normalizedCategory.contains(typeAr)`. In Dart, `'hotels'.contains('')` is `true`,
so any hotel whose `type_ar`/`type_en` was `null` or empty matched **every**
category filter. A hotel with no type would appear under *Hotels*, *Resorts*,
*Apartments* and *Chalets* alike.

Fixed by requiring the type string to be non-empty before any `contains` test
(`hotel_service.dart`). The filter logic was also extracted into a pure static
method, `HotelService.filterHotels`, so it can be tested without a network or a
mock. Five regression tests cover it. Live check: `Hotels` → 4 hotels;
`Apartments`/`Resorts`/`Chalets` → 0; a hotel with no type → 0 under all four.

### 11.2 Defect — category selection did not constrain the units tab

The backend ignores `category`, `category_id`, `type` and `type_id` on
`units/browse.php` (all four return the same 8 units). The search screen therefore
showed the *same* units regardless of the selected category, while the hotels tab
was correctly filtered — a silent inconsistency.

Fixed by filtering the units client-side to the set of hotels that survived the
category filter, matched on `unit.hotelId ∈ {hotel.id}`. This uses real
relationship data rather than an invented rule. Live check: with `Hotels`
selected, the units tab drops from 8 to the 4 units whose `hotel_id` is a hotel of
that type.

### 11.3 Defect — destination chip showed the English city name in Arabic mode

The featured-destination card passed `city: nameEn` unconditionally, so tapping
*مكة المكرمة* in Arabic mode produced an active-filter chip reading *Makkah* — a
mixed-language UI. It also passed a redundant `query: nameAr` alongside the city,
which risked filtering out hotels whose `city_ar` spelling differed from the
cities table.

Fixed to pass `city: city.name(isArabic)` and drop the redundant query. The API
accepts both the Arabic and English city names with identical results (verified:
`Makkah` → 3, `مكة المكرمة` → 3), so the localized name is safe to send and the
chip now matches the interface language.

### 11.4 Defect — search made two sequential network calls

`SearchScreen._loadResults` awaited the hotel search and then the unit search, so
the two independent round-trips ran in series. The homepage already used
`Future.wait` for its parallel sections. Fixed to issue both calls in parallel;
the total wait is now the slower of the two rather than their sum.

### 11.5 Acceptance checks re-run

The ten code-review checks in §2.4 of `EXECUTION_01_TEST_RESULTS.md` were run
against the corrected tree: no working functionality removed, no fabricated data,
no hardcoded inventory, booking reachable from all four entry points, all role
routes intact, application ID and signing untouched, `codemagic.yaml` untouched,
no secrets, no dead buttons.
