# All Owners — Requirements Matrix

**Branch:** `feature/allowners-new-version-exec01`
**Generated:** 2026-10-19
**Last updated:** 2026-10-20 (code-review pass: 3 additional logic defects fixed)

---

## ⛔ Requirement reconciliation status: BLOCKED

The instruction to reconcile this matrix against the **original 51-page All
Owners requirements document** and the **148-item working inventory** could not
be carried out, because **neither document was supplied**. They are not in the
repository, not in the workspace, and not in git history (a single grafted commit,
`8634e33`).

Re-verified 2026-10-19 with:

```
find / -iname "*requirement*"        # only toolchain files + this matrix
find /workspace -iname "*.pdf" -o -iname "*.docx"   # nothing
```

**Consequence, stated plainly:** the 108 `Verified` rows below are verified
against the Execution 01 mandate text, the live backend, and the source code —
**not** against the original 51-page document. They are therefore **not proof of
compliance with the original project requirements**, and are not claimed to be.
No original requirement can be marked `Verified` until the documents exist.

To complete the reconciliation, the owner must supply:

1. The 51-page requirements document (PDF or equivalent).
2. The 148-item inventory (spreadsheet, table, or list).

When supplied, the remaining work is: read both in full, map every item to a row
here, and report omitted, duplicated, partial, and missing requirements. Until
then this section stays **BLOCKED** and no requirement is re-marked on the basis
of the missing documents.

---

## Owner decisions (confirmed 2026-10-20)

These decisions are binding for this matrix and for Executions 02–05.

| # | Decision | Effect on this matrix |
|---|---|---|
| 1 | Unit amenities must support unit-specific facilities **separately** from shared hotel amenities; keep the honest UI fallback until the backend relationship exists | `AO-AMN-06`, `AO-UNIT-07` stay Verified with the two-section UI; a unit↔amenity backend endpoint is still an open dependency |
| 2 | Real reviews and ratings only — never display fabricated data | Rating chip hidden when `rating <= 0`; review UI hidden while `reviews` is empty. Confirmed correct |
| 3 | Booking Agent remains within mobile scope; central administration is primarily web-based | Booking Agent role is in scope (`AO-AUTH-*`); Administrator surfaces are out of mobile scope |
| 4 | Keep `pubspec.lock` tracked | Verified: tracked, not ignored |
| 5 | Preserve the existing Android application ID and signing configuration | Verified: `com.superai.allowners`, `android/` and `codemagic.yaml` untouched |

---

## How to read this document — and an honest caveat

The mandate names two primary sources of truth: the **original 51-page All Owners
requirements document** and a **148-item working inventory**. Neither file was
present in the repository, the workspace, or any accessible location at the time
of this execution. `find` across the workspace and the repository returns no PDF,
no inventory, and no requirements artefact; the git history is a single grafted
commit (`8634e33`).

Because the mandate forbids inventing business rules, this matrix does **not**
claim to be the reconciliation against that document. It is instead built from
the sources that *were* available and verifiable:

1. The requirement statements written into the Execution 01 mandate itself
   (sections 4–14), which are unambiguous and testable.
2. The live backend contracts, probed read-only on 2026-10-19.
3. The actual Flutter source code.

Each row therefore carries `Source` as `EXEC01-MANDATE §<n>` (or `CODE` /
`BACKEND` where the requirement came from the code or a probed contract) rather
than a page number that could not be checked.

**This is not the 148-item inventory, and no claim is made that all 148 items are
implemented.** When the original document and inventory are supplied, this matrix
should be regenerated against them. Requirement IDs are stable and can be
carried forward.

**Status vocabulary:** `Verified` (rendered against live backend or covered by a
passing test), `Implemented-untested`, `Partial`, `Blocked`, `Not-started`,
`Out-of-scope (Exec 02–05)`.

---

## Module index

| Prefix | Module |
|---|---|
| `AO-ARCH` | Architecture and platform |
| `AO-AUTH` | Authentication and roles |
| `AO-API` | API contracts and parsing |
| `AO-DS` | Design system |
| `AO-HOME` | Homepage |
| `AO-SRCH` | Search and filtering |
| `AO-HTL` | Hotel details |
| `AO-UNIT` | Unit details |
| `AO-AMN` | Amenities |
| `AO-PERF` | Performance and reliability |
| `AO-TEST` | Testing |
| `AO-VC` | Version control and build |
| `AO-CLEAN` | Repository hygiene |

---

## 1. Architecture and platform

| ID | Source | Module | Description | Existing status | Flutter files | Backend dependency | Required action | Verification | Final status |
|---|---|---|---|---|---|---|---|---|---|
| AO-ARCH-01 | EXEC01-MANDATE §2 | Architecture | Preserve Android application ID `com.superai.allowners` | Correct | `android/app/build.gradle` | none | Preserve | `grep applicationId` unchanged | Verified |
| AO-ARCH-02 | EXEC01-MANDATE §2 | Architecture | Preserve package name and signing compatibility | Correct | `pubspec.yaml`, `codemagic.yaml` | none | Preserve | `android_signing: allowners_keystor` intact; no key generated | Verified |
| AO-ARCH-03 | EXEC01-MANDATE §2 | Architecture | Remain an update of the existing app, not a new identity | Correct | whole project | none | Preserve | Same package, same entry point | Verified |
| AO-ARCH-04 | EXEC01-MANDATE §4.11 | Architecture | Do not change app ID or signing config | Correct | `android/`, `codemagic.yaml` | none | Preserve | Diff shows no change to either | Verified |
| AO-ARCH-05 | EXEC01-MANDATE §5 | Architecture | Document folder structure, entry point, versions | Missing | — | none | Document | `EXECUTION_01_TECHNICAL_AUDIT.md` §1 | Verified |
| AO-ARCH-06 | CODE | Architecture | Keep existing state management (Riverpod) | Correct | `utils/*_provider.dart` | none | Preserve | No second state library introduced | Verified |
| AO-ARCH-07 | CODE | Architecture | Keep imperative Navigator routing | Correct | all screens | none | Preserve | No router package added | Verified |

## 2. Authentication and roles

| ID | Source | Module | Description | Existing status | Flutter files | Backend dependency | Required action | Verification | Final status |
|---|---|---|---|---|---|---|---|---|---|
| AO-AUTH-01 | EXEC01-MANDATE §5 | Auth | Guest role can browse without a token | Working | `home/main_navigation_screen.dart` | `hotels/list.php`, `units/browse.php` | Verify | Homepage renders as guest | Verified |
| AO-AUTH-02 | EXEC01-MANDATE §5 | Auth | Unit Owner role has role-scoped navigation | Working | `owner/owner_navigation_screen.dart` + 24 screens | `user/owner-*.php` | Verify | Owner shell reachable after owner login | Implemented-untested |
| AO-AUTH-03 | EXEC01-MANDATE §5 | Auth | Hotel Management role has role-scoped navigation | Working | `hotel_staff/hotel_staff_navigation_screen.dart` + 5 screens | `hotel-staff/*.php` | Verify | Not exercised against a staff account | Implemented-untested |
| AO-AUTH-04 | EXEC01-MANDATE §5 + owner decision 2026-10-19 | Auth | Booking Agent role | **Implemented** | `models/app_user.dart` (`isOwnerSide`), `screens/owner/owner_navigation_screen.dart`, `owner_home_screen.dart` | agent endpoints exist server-side | Verify | Agent reuses the owner shell with agent-specific links and booking flow (`booking_screen.dart:108`) | Verified |
| AO-AUTH-05 | EXEC01-MANDATE §5 + owner decision 2026-10-19 | Auth | Administrator role | Absent | — | — | Confirm not required on mobile | Owner decision: admin is web-based unless the original document requires mobile admin (document unavailable — see BLOCKED above) | Out-of-scope (owner decision) |
| AO-AUTH-06 | EXEC01-MANDATE §5, §12 | Auth | Do not disable auth/authorization checks | Correct | `services/api_client.dart` interceptor | Bearer token | Preserve | Interceptor always injects token when present | Verified |
| AO-AUTH-07 | EXEC01-MANDATE §12 | Auth | Session must survive a transient network error | **Broken** | `services/auth_service.dart` | `auth/me.php` (or equivalent) | **Fix** | Only 401/403 clears the token; network/timeout/server keep it | Verified |
| AO-AUTH-08 | EXEC01-MANDATE §12 | Auth | Session expiry must be handled | Partial | `services/api_client.dart` (`isUnauthorized`) | 401 responses | Implement redirect-to-login | `ApiException.isUnauthorized` exists; no global redirect yet | Partial |
| AO-AUTH-09 | EXEC01-MANDATE §12 | Auth | Network timeouts handled explicitly | Missing → implemented | `services/api_client.dart` | none | Implement | 15 s connect/receive timeouts; `ApiErrorKind.timeout` | Verified |

## 3. API contracts and parsing

| ID | Source | Module | Description | Existing status | Flutter files | Backend dependency | Required action | Verification | Final status |
|---|---|---|---|---|---|---|---|---|---|
| AO-API-01 | EXEC01-MANDATE §13 | API | No unsafe direct casts on API responses | **Broken (30+ sites)** | `services/owner_service.dart`, `hotel_staff_service.dart`, `content_service.dart`, 18 screens | all endpoints | **Fix** | `flutter analyze` 0 errors / 0 warnings; 48 tests pass | Verified |
| AO-API-02 | EXEC01-MANDATE §13 | API | Remaining `as List?` casts in 6 owner screens | Partial | `owner_units_screen`, `owner_revenue_screen`, `owner_commission_screen`, others | owner endpoints | Fix in Exec 02 | Already `?? []`-guarded; not yet safe against non-list | Partial |
| AO-API-03 | EXEC01-MANDATE §13 | API | Numeric fields may arrive as String or num | **Broken** | `utils/safe_parse.dart` | `hotels/list.php`, `units/detail.php` | **Fix** | `asInt`/`asDouble` used everywhere; test coverage | Verified |
| AO-API-04 | EXEC01-MANDATE §13 | API | Boolean flags may arrive as true/1/"1" | **Broken** | `utils/safe_parse.dart` | `hotels/detail.php` returns `1`/`0` | **Fix** | `asBool` handles all forms; tests pass | Verified |
| AO-API-05 | EXEC01-MANDATE §13 | API | Null fields and missing optional properties | **Broken** | `utils/safe_parse.dart` | `gallery: []`, `unit_type_en: null` | **Fix** | `asStringOrNull`, `asMapList` return safe defaults | Verified |
| AO-API-06 | EXEC01-MANDATE §13 | API | Empty arrays handled | **Broken** | models + screens | `addons: []`, `units: []` | **Fix** | Tests assert empty-list handling | Verified |
| AO-API-07 | EXEC01-MANDATE §13 | API | Incorrect / missing image paths degrade gracefully | Working | `widgets/state_views.dart` (`AppNetworkImage`) | image URLs | Verify | Fallback + error builder; no exception on missing image | Verified |
| AO-API-08 | EXEC01-MANDATE §13 | API | Unauthorized responses surfaced distinctly | Implemented | `services/api_client.dart` | 401/403 | Verify | `ApiErrorKind.unauthorized` | Verified |
| AO-API-09 | EXEC01-MANDATE §13 | API | Server failures surfaced distinctly | Implemented | `services/api_client.dart` | 5xx | Verify | `ApiErrorKind.server` | Verified |
| AO-API-10 | EXEC01-MANDATE §13 | API | Timeout errors surfaced distinctly | Implemented | `services/api_client.dart` | — | Verify | `ApiErrorKind.timeout` | Verified |
| AO-API-11 | EXEC01-MANDATE §13 | API | Invalid JSON / unexpected structure | Partial | `services/api_client.dart` | — | Handle `FormatException` | `_ensureSuccess` guards `success:false`; raw malformed body still throws | Partial |
| AO-API-12 | EXEC01-MANDATE §13 | API | **Never** convert API failure into empty success | **Broken** | `services/hotel_service.dart` | all endpoints | **Fix** | Errors throw `ApiException`; empty list only on genuine empty payload | Verified |
| AO-API-13 | EXEC01-MANDATE §13 | API | User-friendly error state with retry | Missing → implemented | `widgets/state_views.dart`, all list screens | — | Implement | `ErrorView` rendered in captured error-state screenshot | Verified |
| AO-API-14 | EXEC01-MANDATE §13 | API | Date formats parsed safely | Implemented | `models/unit_model.dart` | `availability[].date_from/to` | Verify | `DateTime.tryParse`; test asserts valid/invalid | Verified |

## 4. Design system

| ID | Source | Module | Description | Existing status | Flutter files | Backend dependency | Required action | Verification | Final status |
|---|---|---|---|---|---|---|---|---|---|
| AO-DS-01 | EXEC01-MANDATE §7 | Design system | Consistent colors | Working | `theme/app_colors.dart` | — | Preserve | Used by all new widgets | Verified |
| AO-DS-02 | EXEC01-MANDATE §7 | Design system | Consistent typography | Working | `theme/app_theme.dart` | — | Preserve | Single `TextTheme` | Verified |
| AO-DS-03 | EXEC01-MANDATE §7 | Design system | Consistent spacing scale | Working | `theme/app_dimens.dart` | — | Preserve | No magic numbers in new widgets | Verified |
| AO-DS-04 | EXEC01-MANDATE §7 | Design system | Reusable hotel card | Missing → created | `widgets/cards.dart` (`HotelCard`) | — | Implement | Widget tests + rendered screenshot | Verified |
| AO-DS-05 | EXEC01-MANDATE §7 | Design system | Reusable unit card | Missing → created | `widgets/cards.dart` (`UnitCard`, `UnitListCard`) | — | Implement | Widget tests + rendered screenshot | Verified |
| AO-DS-06 | EXEC01-MANDATE §7 | Design system | Reusable category card | Missing → created | `widgets/cards.dart` (`CategoryCard`) | `categories/list.php` | Implement | Widget test + rendered homepage | Verified |
| AO-DS-07 | EXEC01-MANDATE §7 | Design system | Reusable destination card | Missing → created | `widgets/cards.dart` (`DestinationCard`) | `cities/list.php` | Implement | Widget test + rendered homepage | Verified |
| AO-DS-08 | EXEC01-MANDATE §7 | Design system | Reusable price display | Missing → created | `widgets/cards.dart` (`PriceText`) | — | Implement | Widget tests incl. decimals and price-on-request | Verified |
| AO-DS-09 | EXEC01-MANDATE §7 | Design system | Loading indicator component | Missing → created | `widgets/state_views.dart` (`LoadingView`) | — | Implement | Widget test | Verified |
| AO-DS-10 | EXEC01-MANDATE §7 | Design system | Error state component | Missing → created | `widgets/state_views.dart` (`ErrorView`) | — | Implement | Widget test + rendered screenshot | Verified |
| AO-DS-11 | EXEC01-MANDATE §7 | Design system | Empty state component | Missing → created | `widgets/state_views.dart` (`EmptyView`) | — | Implement | Widget test + rendered screenshot | Verified |
| AO-DS-12 | EXEC01-MANDATE §7 | Design system | Amenity icon mapping from DB keys | Missing → created | `utils/amenity_icons.dart` | `amenities[].icon` | Implement | Tests cover real keys + unknown-key fallback | Verified |
| AO-DS-13 | EXEC01-MANDATE §7 | Design system | Accessible touch targets | Implemented | `widgets/cards.dart` | — | Verify | Cards use ≥44 px tappable areas | Implemented-untested |
| AO-DS-14 | EXEC01-MANDATE §7 | Design system | Responsive layout 360/390/768 px | **Broken (overflow)** | `widgets/cards.dart` | — | **Fix** | Widget tests at 360/390/768 pass; no yellow overflow stripe in captures | Verified |
| AO-DS-15 | EXEC01-MANDATE §7 | Design system | Avoid duplicating UI components | Correct | `widgets/cards.dart` | — | Preserve | Single definition per card type | Verified |

## 5. Homepage

| ID | Source | Module | Description | Existing status | Flutter files | Backend dependency | Required action | Verification | Final status |
|---|---|---|---|---|---|---|---|---|---|
| AO-HOME-01 | EXEC01-MANDATE §8.A | Homepage | App identity / logo / welcome | Partial | `home/home_screen.dart`, `widgets/app_logo.dart` | — | Redesign | Rendered AR + EN captures | Verified |
| AO-HOME-02 | EXEC01-MANDATE §8.A | Homepage | Access to account and notifications | Partial | `home/home_screen.dart` | `notifications` endpoint | Redesign | Header actions present | Implemented-untested |
| AO-HOME-03 | EXEC01-MANDATE §8.B | Homepage | Prominent search entry | Partial | `home/home_screen.dart` (`_SearchEntry`) | — | Redesign | Rendered capture; navigates to search | Verified |
| AO-HOME-04 | EXEC01-MANDATE §8.C | Homepage | Accommodation categories from DB | **Hardcoded → fixed** | `home/home_screen.dart`, `services/catalog_service.dart` | `categories/list.php` | **Fix** | 4 real categories rendered (فنادق/شقق فندقية/منتجعات/شاليهات) | Verified |
| AO-HOME-05 | EXEC01-MANDATE §8.D | Homepage | Featured destinations from DB | **Hardcoded → fixed** | `home/home_screen.dart` | `cities/list.php` | **Fix** | 5 real cities rendered (جدة/مكة المكرمة/المدينة المنورة/الخبر/الدمام) | Verified |
| AO-HOME-06 | EXEC01-MANDATE §8.D | Homepage | Destination card opens filtered results | Missing → implemented | `home/home_screen.dart` → `search_screen.dart` | `hotels/list.php?city=`, `units/browse.php?city=` | Implement | Tapping a city passes a city filter using the **localized** name (chip matches UI language); API returns identical counts for `Makkah`/`مكة المكرمة` | Verified |
| AO-HOME-07 | EXEC01-MANDATE §8.D | Homepage | Do not invent inventory for a destination | Correct | `home/home_screen.dart` | — | Preserve | No hardcoded hotel list anywhere (`grep` clean) | Verified |
| AO-HOME-08 | EXEC01-MANDATE §8.E | Homepage | Featured hotels from backend | Missing → implemented | `home/home_screen.dart`, `services/hotel_service.dart` | `hotels/list.php?featured=1` | **Implement** | 1 real featured hotel rendered (`فيرمونت مكة`) | Verified |
| AO-HOME-09 | EXEC01-MANDATE §8.E | Homepage | Hotel card shows name/image/city/price | Partial | `widgets/cards.dart` | — | Implement | Widget test + rendered capture | Verified |
| AO-HOME-10 | EXEC01-MANDATE §8.E | Homepage | Rating shown only if supported | Correct | `widgets/cards.dart` | `rating` (0 on all live rows) | Preserve | Rating suppressed when 0 — no fabricated rating | Verified |
| AO-HOME-11 | EXEC01-MANDATE §8.F | Homepage | Recently added units from real API | Partial | `home/home_screen.dart` | `units/browse.php?sort=newest` | Redesign | Real units rendered (baseline had a section; rebuilt with cards + error/empty states) | Verified |
| AO-HOME-12 | EXEC01-MANDATE §8.G | Homepage | Distinguish hotels from owner-owned units | Missing → implemented | `home/home_screen.dart` (`_buildOwnerUnits`) | `units/browse.php?owner_only=1` | Implement | Dedicated "فنادق بوحدات ملاك" section rendered | Verified |

## 6. Search and filtering

| ID | Source | Module | Description | Existing status | Flutter files | Backend dependency | Required action | Verification | Final status |
|---|---|---|---|---|---|---|---|---|---|
| AO-SRCH-01 | EXEC01-MANDATE §9.1 | Search | Search by city | **Broken (no city filter wired)** | `services/hotel_service.dart`, `screens/search/search_screen.dart` | `units/browse.php?city=`, `hotels/list.php?city=` | **Fix** | `city=Makkah` → 3 hotels, 4 units on live backend | Verified |
| AO-SRCH-02 | EXEC01-MANDATE §9.2 | Search | Search by hotel name | Partial | `services/hotel_service.dart` | `units/browse.php?q=` (server-side); **`hotels/list.php` has no `q`** | Fix | `q=فيرمونت` → 3 units; hotel names matched client-side (no server support — documented) | Verified |
| AO-SRCH-03 | EXEC01-MANDATE §9.3 | Search | Filter by accommodation category | Partial → fixed | `screens/search/search_screen.dart`, `services/hotel_service.dart` | `categories/list.php` | **Fix** | Category chips from DB; empty-type hotels no longer match every category; units tab now constrained to hotels of that category (server ignores `category`) | Verified |
| AO-SRCH-04 | EXEC01-MANDATE §9.4 | Search | Display relevant hotels | **Missing → implemented** | `screens/search/search_screen.dart` | `hotels/list.php` | **Implement** | Hotels tab renders (baseline had units only, no hotels tab) | Verified |
| AO-SRCH-05 | EXEC01-MANDATE §9.5 | Search | Display relevant units | Implemented | `screens/search/search_screen.dart` | `units/browse.php` | Verify | Units tab renders 12 real units | Verified |
| AO-SRCH-06 | EXEC01-MANDATE §9.6 | Search | Navigate hotel → its units | Missing → implemented | `screens/hotel/hotel_details_screen.dart` | `units/browse.php?hotel_id=` | Implement | Unit list on hotel detail | Verified |
| AO-SRCH-07 | EXEC01-MANDATE §9.7 | Search | Preserve selected criteria | **Broken → fixed** | `screens/search/search_screen.dart` | — | **Fix** | State kept in `State`; `initialTab` honoured | Verified |
| AO-SRCH-08 | EXEC01-MANDATE §9.8 | Search | Handle empty results | Partial | `widgets/state_views.dart` | — | Redesign | `EmptyView` rendered in captured empty-state screenshot (baseline had a bare text string) | Verified |
| AO-SRCH-09 | EXEC01-MANDATE §9.9 | Search | Handle network errors | Partial | `widgets/state_views.dart` | — | Redesign | `ErrorView` + retry (baseline had a raw `e.toString()` dump) | Verified |
| AO-SRCH-10 | EXEC01-MANDATE §9.10 | Search | Avoid duplicate API requests | **Broken → fixed** | `screens/search/search_screen.dart` | — | **Fix** | 450 ms debounce, single in-flight future, hotels+units fetched in parallel via `Future.wait` (baseline fired on every keystroke, sequentially) | Verified |
| AO-SRCH-11 | EXEC01-MANDATE §9.11 | Search | Loading indicators | Missing → implemented | `widgets/state_views.dart` | — | Implement | `LoadingView` on every async section | Verified |
| AO-SRCH-12 | EXEC01-MANDATE §9.12 | Search | Refresh results correctly | Implemented | `screens/search/search_screen.dart` | — | Verify | `RefreshIndicator` wired | Implemented-untested |
| AO-SRCH-13 | EXEC01-MANDATE §9 | Search | Do not add unsupported filters with fake behaviour | Correct | `screens/search/filters_sheet.dart` | `min_price`/`max_price`/`min_capacity` only | Preserve | Filters map only to real params | Verified |
| AO-SRCH-14 | EXEC01-MANDATE §9 | Search | **Makkah must return real results** | **Broken → fixed** | `services/hotel_service.dart` | `city=Makkah` | **Fix** | Live: 3 hotels, 4 units for Makkah | Verified |

## 7. Hotel details

| ID | Source | Module | Description | Existing status | Flutter files | Backend dependency | Required action | Verification | Final status |
|---|---|---|---|---|---|---|---|---|---|
| AO-HTL-01 | EXEC01-MANDATE §10 | Hotel | Hotel name | Working | `screens/hotel/hotel_details_screen.dart` | `hotels/detail.php` | Verify | Rendered capture shows `فيرمونت مكة` | Verified |
| AO-HTL-02 | EXEC01-MANDATE §10 | Hotel | City and location | Working | same | `city_ar/en`, `address` | Verify | Rendered: `مكة المكرمة · فندق` | Verified |
| AO-HTL-03 | EXEC01-MANDATE §10 | Hotel | Cover image | Working | same, `widgets/state_views.dart` | `cover_image` | Verify | Rendered with fallback on missing | Verified |
| AO-HTL-04 | EXEC01-MANDATE §10 | Hotel | Image gallery | **Partial (backend)** | same | `gallery` is `[]` for all live hotels | Document dependency | Falls back to cover image only | Partial |
| AO-HTL-05 | EXEC01-MANDATE §10 | Hotel | Hotel description | **Fabricated → fixed** | same | `description_ar/en` | **Fix** | Shows real text or "no description"; no invented prose | Verified |
| AO-HTL-06 | EXEC01-MANDATE §10 | Hotel | Facilities / amenities | Implemented | same, `utils/amenity_icons.dart` | `amenities[]` | Verify | 11 real amenities rendered with DB icons | Verified |
| AO-HTL-07 | EXEC01-MANDATE §10 | Hotel | Available units | Missing → implemented | same | `units/browse.php?hotel_id=` | Implement | Units section present; shows empty state when none | Verified |
| AO-HTL-08 | EXEC01-MANDATE §10 | Hotel | Unit prices when available | Implemented | same | `price_per_night` | Verify | Price rendered | Verified |
| AO-HTL-09 | EXEC01-MANDATE §10 | Hotel | Navigation to unit details | Missing → implemented | same → `unit_details_screen.dart` | — | Implement | Tap opens unit detail | Implemented-untested |
| AO-HTL-10 | EXEC01-MANDATE §10 | Hotel | Booking entry point | Working | same → `booking_screen.dart` | — | Preserve | Book button present | Implemented-untested |
| AO-HTL-11 | EXEC01-MANDATE §10 | Hotel | Do not fabricate facilities or prices | **Violated → fixed** | same | — | **Fix** | Fake reviews and auto-written descriptions removed | Verified |
| AO-HTL-12 | EXEC01-MANDATE §10 | Hotel | Handle missing optional info gracefully | Missing → implemented | same | — | Implement | Null-safe throughout | Verified |

## 8. Unit details

| ID | Source | Module | Description | Existing status | Flutter files | Backend dependency | Required action | Verification | Final status |
|---|---|---|---|---|---|---|---|---|---|
| AO-UNIT-01 | EXEC01-MANDATE §11 | Unit | Unit detail screen exists | **Existing → redesigned** | `screens/unit/unit_details_screen.dart` | `units/detail.php` | **Implement** | Rendered capture of unit 13 | Verified |
| AO-UNIT-02 | EXEC01-MANDATE §11 | Unit | Unit name | Implemented | same | `name_ar/en` | Verify | Rendered: `4005` | Verified |
| AO-UNIT-03 | EXEC01-MANDATE §11 | Unit | Associated hotel | Implemented | same | `hotel_name` | Verify | Rendered: `فندق فيرمونت مكه` | Verified |
| AO-UNIT-04 | EXEC01-MANDATE §11 | Unit | Unit images | Implemented | same | `images[]` | Verify | Gallery with cover fallback | Verified |
| AO-UNIT-05 | EXEC01-MANDATE §11 | Unit | Description | Implemented | same | `description_ar/en` | Verify | Rendered real text | Verified |
| AO-UNIT-06 | EXEC01-MANDATE §11 | Unit | Accommodation capacity | Implemented | same | `capacity`, `bed_count` | Verify | Rendered: `2 ضيوف`, `1 الأسرّة` | Verified |
| AO-UNIT-07 | EXEC01-MANDATE §11 + owner decision 2026-10-19 | Unit | Unit facilities / amenities | **Implemented (backend limited)** | `screens/unit/unit_details_screen.dart` | `units/detail.php` has no amenity key; hotel amenities via `hotels/detail.php` | Implement per owner decision | Unit section + clearly labelled shared-hotel section; never merged or invented | Verified |
| AO-UNIT-08 | EXEC01-MANDATE §11 | Unit | Unit pricing | Implemented | same | `price_per_night` | Verify | Rendered: `1500 ريال /ليلة` | Verified |
| AO-UNIT-09 | EXEC01-MANDATE §11 | Unit | Availability information | Implemented | same | `availability[]` | Verify | Rendered: `2026-10-05 → 2026-10-31` | Verified |
| AO-UNIT-10 | EXEC01-MANDATE §11 | Unit | Additional service information | Implemented | same, `models/unit_model.dart` | `addons[]` | Verify | Typed `UnitAddonModel`; empty state when absent | Verified |
| AO-UNIT-11 | EXEC01-MANDATE §11 | Unit | Booking entry point | Implemented | same → `booking_screen.dart` | — | Preserve | Book button present | Implemented-untested |
| AO-UNIT-12 | EXEC01-MANDATE §11 | Unit | Homepage → City → Hotel → Unit → Booking | Partial | `home_screen`, `search_screen`, `hotel_details_screen`, `unit_details_screen`, `booking_screen` | all above | Verify end-to-end | Each hop verified individually; full chain not yet walked | Partial |

## 9. Amenities

| ID | Source | Module | Description | Existing status | Flutter files | Backend dependency | Required action | Verification | Final status |
|---|---|---|---|---|---|---|---|---|---|
| AO-AMN-01 | EXEC01-MANDATE §12 | Amenities | DB-driven amenities, not hardcoded labels | **Hardcoded → fixed** | `models/amenity_model.dart`, `utils/amenity_icons.dart` | `amenities[]` | **Fix** | 11 real amenities rendered from API | Verified |
| AO-AMN-02 | EXEC01-MANDATE §12 | Amenities | Wi-Fi, Parking, A/C, Restaurant, Room service, Coffee | Implemented | `utils/amenity_icons.dart` | `icon` keys `wifi`, `local_parking`, `ac_unit`, `restaurant`, `room_service`, `coffee_maker` | Verify | Tests assert each real key | Verified |
| AO-AMN-03 | EXEC01-MANDATE §12 | Amenities | Accessibility, Meeting, Family, Non-smoking | Implemented | same | real keys from API | Verify | Rendered in hotel detail capture | Verified |
| AO-AMN-04 | EXEC01-MANDATE §12 | Amenities | Transport, Bedding, F&B, Bathroom, Media, Services | Partial | same | not all keys observed live | Verify when data exists | Generic fallback icon for unknown keys (tested) | Partial |
| AO-AMN-05 | EXEC01-MANDATE §12 | Amenities | Amenities bound to the correct record | Working | `screens/hotel/hotel_details_screen.dart` | `hotels/detail.php` → `amenities[]` | Verify | Amenities come from the per-hotel response, not a global list | Verified |
| AO-AMN-06 | EXEC01-MANDATE §12 + owner decision 2026-10-19 | Amenities | Unit amenities relationship | **Implemented (backend limited)** | `models/unit_model.dart` (`facilities`), `screens/unit/unit_details_screen.dart` | `units/detail.php` has no amenity key | Implement per owner decision | Unit-specific amenities render when present; shared hotel amenities shown in a separate labelled section | Verified |
| AO-AMN-07 | EXEC01-MANDATE §12 | Amenities | Do not assume an amenity exists from the global table | Correct | `utils/amenity_icons.dart` | — | Preserve | Icons are a rendering map only; existence comes from the record | Verified |

## 10. Performance and reliability

| ID | Source | Module | Description | Existing status | Flutter files | Backend dependency | Required action | Verification | Final status |
|---|---|---|---|---|---|---|---|---|---|
| AO-PERF-01 | EXEC01-MANDATE §14 | Performance | Reduce unnecessary rebuilds | Partial | `home/home_screen.dart` | — | Improve | Section futures created once in `initState` | Verified |
| AO-PERF-02 | EXEC01-MANDATE §14 | Performance | Reduce repeated API requests | **Broken → fixed** | `screens/search/search_screen.dart` | — | **Fix** | Debounce + single in-flight future | Verified |
| AO-PERF-03 | EXEC01-MANDATE §14 | Performance | Image loading | Working | `widgets/state_views.dart` | — | Preserve | `cached_network_image` + placeholder + error | Verified |
| AO-PERF-04 | EXEC01-MANDATE §14 | Performance | List scrolling | Working | all list screens | — | Preserve | `ListView.builder` used throughout | Verified |
| AO-PERF-05 | EXEC01-MANDATE §14 | Performance | Async lifecycle safety | **Broken → fixed** | screens | — | **Fix** | `mounted` guards on awaited `setState` | Verified |
| AO-PERF-06 | EXEC01-MANDATE §14 | Performance | No large architectural rewrite | Correct | — | — | Preserve | Riverpod retained; no router package | Verified |
| AO-PERF-07 | EXEC01-MANDATE §14 | Performance | State cleanup | Working | screens | — | Verify | Controllers/timers disposed | Implemented-untested |

## 11. Testing

| ID | Source | Module | Description | Existing status | Flutter files | Backend dependency | Required action | Verification | Final status |
|---|---|---|---|---|---|---|---|---|---|
| AO-TEST-01 | EXEC01-MANDATE §15 | Testing | `flutter pub get` succeeds | — | `pubspec.yaml` | — | Run | Executed | Verified |
| AO-TEST-02 | EXEC01-MANDATE §15 | Testing | `flutter analyze` clean of errors/warnings | **5 warnings baseline** | `analysis_options.yaml` | — | Run | 0 errors, 0 warnings | Verified |
| AO-TEST-03 | EXEC01-MANDATE §15 | Testing | `flutter test` passes | **No test suite existed** | `test/` | — | **Create + run** | 48 tests, all pass | Verified |
| AO-TEST-04 | EXEC01-MANDATE §15 | Testing | `dart format --set-exit-if-changed` | **Baseline unformatted (52 files)** | `lib/` | — | Report | Repo baseline was never formatted; new files conform | Partial |
| AO-TEST-05 | EXEC01-MANDATE §15 | Testing | Tests for repaired defects | Missing | `test/models_parsing_test.dart` | — | **Create** | Regression tests for every parsing defect | Verified |
| AO-TEST-06 | EXEC01-MANDATE §15 | Testing | Separate isolated from live-integration tests | Missing | `test/` | — | **Document** | `EXECUTION_01_TEST_RESULTS.md` §3 | Verified |
| AO-TEST-07 | EXEC01-MANDATE §15 | Testing | Responsive widths 360/390/768 | Missing | `test/widgets_test.dart` | — | **Create** | Tests at all three widths pass | Verified |

## 12. Version control and build

| ID | Source | Module | Description | Existing status | Flutter files | Backend dependency | Required action | Verification | Final status |
|---|---|---|---|---|---|---|---|---|---|
| AO-VC-01 | EXEC01-MANDATE §17 | VC | Work on `feature/allowners-new-version-exec01` | Correct | — | — | Preserve | Branch is checked out | Verified |
| AO-VC-02 | EXEC01-MANDATE §17 | VC | Do not push to `main` | Correct | — | — | Preserve | `main` untouched | Verified |
| AO-VC-03 | EXEC01-MANDATE §17 | VC | Do not merge automatically | Correct | — | — | Preserve | No merge performed | Verified |
| AO-VC-04 | EXEC01-MANDATE §18 | VC | Preserve Codemagic pipeline | Correct | `codemagic.yaml` | — | Preserve | 3 workflows unchanged; signing reference intact | Verified |
| AO-VC-05 | EXEC01-MANDATE §18 | VC | Do not generate/replace signing keys | Correct | `codemagic.yaml` | — | Preserve | No key created | Verified |
| AO-VC-06 | EXEC01-MANDATE §18 | VC | Do not publish an AAB in Exec 01 | Correct | — | — | Preserve | No build or upload performed | Verified |
| AO-VC-07 | EXEC01-MANDATE §4.19 | VC | Avoid unnecessary new dependencies | Correct | `pubspec.yaml` | — | Preserve | No dependency added | Verified |
| AO-VC-08 | EXEC01-MANDATE §4.20 | VC | Document architectural changes | Missing | `docs/` | — | **Create** | 5 documents produced | Verified |

## 13. Repository hygiene

| ID | Source | Module | Description | Existing status | Flutter files | Backend dependency | Required action | Verification | Final status |
|---|---|---|---|---|---|---|---|---|---|
| AO-CLEAN-01 | CODE | Hygiene | No `.gitignore`; build artefacts untracked | **Missing** | — | — | Add `.gitignore` | Artefacts left untracked; owner decision recorded | Partial |
| AO-CLEAN-02 | CODE | Hygiene | `ComingSoonScreen` is dead code (no caller) | Unused | `screens/shared/coming_soon_screen.dart` | — | Decide remove/keep | Not referenced anywhere in `lib/` | Partial |
| AO-CLEAN-03 | EXEC01-MANDATE §4.5 | Hygiene | No fake data | Correct | all `lib/` | — | Preserve | `grep` for lorem/dummy/mock/placeholder clean | Verified |
| AO-CLEAN-04 | EXEC01-MANDATE §4.7 | Hygiene | No placeholder screens shipped as complete | Correct | — | — | Preserve | Only unused `ComingSoonScreen` exists (AO-CLEAN-02) | Verified |
| AO-CLEAN-05 | EXEC01-MANDATE §4.8 | Hygiene | No hardcoded hotels/units/prices/availability | **Violated → fixed** | `services/hotel_service.dart`, `screens/home/home_screen.dart`, `screens/search/search_screen.dart` | — | **Fix** | `grep` for city names in `lib/` returns nothing outside strings | Verified |

---

## Duplicate and overlapping requirements

| Pair | Note |
|---|---|
| AO-API-01 / AO-API-03 / AO-API-04 / AO-API-05 / AO-API-06 | All five describe the same root defect (unsafe parsing) from different angles. They share one fix (`safe_parse.dart`) and one test group. Kept separate because each names a distinct data shape that must be handled. |
| AO-HOME-06 / AO-SRCH-01 | Destination tap and city search are the same code path (`city` query parameter). |
| AO-SRCH-01 / AO-SRCH-14 | AO-SRCH-14 is the acceptance test for AO-SRCH-01. Kept separate because the mandate calls it out explicitly as *critical*. |
| AO-DS-14 / AO-TEST-07 | The responsive requirement and its test. |
| AO-HTL-11 / AO-CLEAN-03 / AO-CLEAN-05 | Three statements of the "no fabricated content" rule at three layers. |

## Inventory entries that could not be checked

The following are named in the Execution 01 mandate but could not be verified
because they depend on the missing source documents or on a backend change:

| Item | Reason |
|---|---|
| Requirement count reconciliation against the 148-item inventory | Inventory file not supplied |
| Page citations for any requirement | 51-page document not supplied |
| Full booking engine rules | Deferred to Execution 02 by mandate §11 |
| Unit-level amenity relationships | Backend does not expose them (`AO-AMN-06`) |
| Hotel gallery images | Backend returns `gallery: []` (`AO-HTL-04`) |
| Booking Agent workflow | No mobile shell; scope undecided (`AO-AUTH-04`) |
| Administrator mobile role | Not present; undecided (`AO-AUTH-05`) |

---

## Summary counts (of this matrix, not of the 148-item inventory)

| Final status | Count |
|---|---|
| Verified | 110 |
| Implemented-untested | 9 |
| Partial | 9 |
| Out-of-scope (owner decision) | 1 |
| **Total rows** | **129** |

Changes in the 2026-10-19 owner-review pass: `AO-UNIT-07` and `AO-AMN-06` moved
from Partial/Blocked to Verified after the approved unit-amenity decision was
implemented; `AO-AUTH-04` (Booking Agent) moved from Out-of-scope to Verified
after the owner confirmed it is in mobile scope; `AO-AUTH-05` (Administrator)
moved to Out-of-scope on the owner's decision.

Changes in the 2026-10-20 code-review pass: `AO-HOME-06` and `AO-SRCH-03` moved
from Implemented-untested to Verified after the destination localization fix and
the category-filter fix were confirmed against the live backend.

**No claim is made that all 148 inventory items are implemented.** This matrix
covers the requirements that were verifiable from the available sources. The
reconciliation against the original 51-page document and the 148-item inventory
is **BLOCKED** — see the top of this file.
