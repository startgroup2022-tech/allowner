# AGENTS.md — All Owners (Flutter)

Repository knowledge for future agent sessions. Keep it short and factual.

## Project

Flutter/Dart mobile app for the "All Owners" hospitality platform.
Arabic-first (RTL) with full English (LTR) support. Builds via Codemagic.

- Android application ID: `com.superai.allowners` — **do not change**
- Backend: `https://all-owner.online/api` (`lib/services/api_client.dart`)
- Flutter 3.47.7 stable / Dart 3.13.5 in this environment

## Commands

```bash
export PATH=/opt/flutter/bin:$PATH
flutter pub get
flutter analyze                 # 0 errors, 0 warnings (info items are style-only)
flutter test                    # 267 unit/widget tests pass, 17 live tests skip
dart format --output=none --set-exit-if-changed .   # clean (108 files)

# Live integration tests against the real backend (network required):
flutter test test/integration/live_backend_test.dart --dart-define=RUN_LIVE_TESTS=true

# Android release build (needs JDK + Android SDK, see below):
flutter build apk --release
```

**`--dart-define=RUN_LIVE_TESTS=true` is required** — `bool.fromEnvironment` does not accept
`1`. Without the define the 17 integration tests skip, so a Codemagic build stays offline-safe.

**Test files:**
- `test/widgets_test.dart` — pure functions and individual widgets.
- `test/screens_render_test.dart` — builds the real screens (`HomeScreen`, `SearchScreen`,
  `HotelDetailsScreen`, `UnitDetailsScreen`) over the real service layer with a fixture Dio
  adapter serving verbatim production payloads. Asserts no layout overflow at 360/390/768 and
  `takeException() == null`. When adding a screen-level guarantee, put it here.
- `test/integration/live_backend_test.dart` — network; see the define above.
- `test/models_parsing_test.dart` — defensive JSON parsing.

**`/opt/flutter` does not exist in every container.** A fresh container has no Flutter at
all; install **3.47.7 / Dart 3.13.5** (the version this repo is verified against):

```bash
curl -sL -o /tmp/f.tar.xz https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.47.7-stable.tar.xz
tar -xf /tmp/f.tar.xz -C /tmp
export PATH=/tmp/flutter/bin:$PATH PUB_CACHE=/tmp/pubcache
```

Do **not** use Flutter 3.24.5: its bundled `flutter_localizations` pins `intl 0.19.0`, which
conflicts with this repo's `intl: ^0.20.2`, and `pub get` fails with
"version solving failed".

## Architecture

| Concern | Where |
|---|---|
| State management | Riverpod (`ProviderScope`, `ConsumerWidget`, `ref.watch`) |
| Routing | Imperative `Navigator.push` with `MaterialPageRoute` — no named routes |
| Localization | `AppStrings.t(isArabic, key)`, flat `Map<String, Map<String,String>>` in `lib/utils/app_strings.dart`; locale via `localeProvider` |
| Theme tokens | `lib/theme/app_colors.dart`, `lib/theme/app_dimens.dart` |
| HTTP | Single `Dio` instance in `ApiClient`; bearer-token interceptor |
| Safe JSON | `lib/utils/safe_parse.dart` |

## Rules that matter here

1. **Never cast API values directly.** The backend returns the same column as a
   number *or* a quoted string, and flags as `true` *or* `1`. Always go through
   `asInt` / `asDouble` / `asBool` / `asString` / `asMapList` / `asStringList` /
   `localized` from `lib/utils/safe_parse.dart`.
2. **Never add fabricated content.** No demo hotels, no invented descriptions,
   no invented reviews, no placeholder prices. The baseline contained all of
   these and they were removed in Execution 01. Data comes from the API or the
   screen shows an honest empty state.
3. **Never add a non-functional button.** If the backend has no endpoint, route
   the action to something real (e.g. Help & Support) or omit it.
4. **Never hardcode cities, categories or inventory.** Use
   `CatalogService` (`cities/list.php`, `categories/list.php`).
5. Every new user-visible string needs **both** an `ar` and an `en` entry; the
   test in `test/widgets_test.dart` enforces this.
5b. **A category has two names, and they must not be confused.** The raw DB name
   (`CategoryModel.name`) drives filtering and must stay verbatim. The approved
   display label (`CategoryModel.displayName`, e.g. `الوحدات الفندقية` for
   `icon_key=hotels`) is presentation only, per reqs 13/14. Anywhere a category
   is shown to the user — including the search screen's active filter chip —
   use `displayName`; anywhere it is sent to the API or compared to
   `type_ar`, use `name`. Mixing them produces two labels for one category on
   consecutive screens.
6. New widgets should reuse `lib/widgets/cards.dart` and
   `lib/widgets/state_views.dart` rather than duplicating UI.

## Backend quirks (verified live)

- `hotels/list.php` supports `city`, `featured`, `stars`, `min_price`,
  `max_price` — but **no text search** and **no category/type filter**
  (`type`, `category`, `category_id`, `type_id` are all ignored). Hotel-name and
  category matching are client-side, in `HotelService.filterHotels`.
- `hotels/list.php?city=` is an **exact, case-insensitive** match on the full
  city name (`Makkah` and `مكة المكرمة` both work; a short form like `مكة`
  returns 0). `units/browse.php?city=` is a **partial** match, so `مكة` works
  there. Prefer passing the value from `cities/list.php` unchanged.
- `units/browse.php` supports `q`, `city`, `hotel_id`, `owner_only` — but
  **ignores category/type**. To filter units by category, constrain them to the
  hotels of that category via `hotel_id`.
- **Category names are plural, hotel types are singular.** `categories/list.php`
  returns `فنادق` / `منتجعات` / `شاليهات` / `شقق فندقية`; `hotels/list.php`
  returns `type_ar` of `فندق` / `منتجع` / `شاليه`. A plain `contains` therefore
  matches nothing, and an Arabic category yields zero hotels — which also
  empties the units section, because units are constrained by `hotel_id`.
  `HotelService._canonicalTokens` canonicalises both sides (regular plural
  suffixes + a broken-plural alias table) before comparing. Keep it, and keep
  the category comparison client-side.
- `hotels/detail.php` returns `gallery: null` (not `[]`) and `units: []`.
- `units/detail.php` returns no `facilities` or `amenities` key at all.
- All `auth/forgot*` paths return **404** — there is no password reset.
- All ratings are `0`; the UI suppresses the rating chip when it is 0.
- Dart quirk to remember: `'x'.contains('')` is `true`, so guard `contains`
  against empty needles when matching category/type strings.

Details and owner decisions: `docs/EXECUTION_01_BACKEND_DEPENDENCIES.md`.

## Open findings — do not "fix" without an owner decision

- **Card data no longer leaves the app (FIXED, commit `79dd97e`).** The booking screen used to
  post the raw PAN as `card_number` to `bookings/create.php`. That is gone: no card field is
  collected, `buildBookingPayload` emits none, and `HotelService.createBooking` refuses to send
  any payload that trips `findPaymentDataLeaks`. Online payment is now a hosted-checkout
  redirect whose URL comes from `content/settings.php` (`payment_checkout_url`) and carries only
  the booking reference. Until the owner supplies provider credentials that key is absent, so
  the screen honestly says online payment is not enabled. **Remaining work is server-side (a
  payment-state field + a provider webhook) and commercial (choose a licensed provider).** See
  `docs/PAYMENT_SECURITY_ASSESSMENT.md`.
- **Two contradictory payment models coexist.** `PaymentMethod { online, atHotel,
  ownerTransfer }` allows the guest to pay the owner directly, while `agent-commission`
  assumes the platform collects and takes a commission. No rule reconciles them, and the
  commission effect of `owner_transfer` is undefined. Business decision.
- **This repo is the Flutter client only.** The PHP backend, database schema and migrations
  are not here, so server-side authorisation, validation, double-booking prevention and
  payment-state consistency **cannot be verified from this repository**. Do not claim they
  are correct.
- **No subscriptions module** exists in the client. **No email** path exists (in-app
  notifications only).
- **No Android device/emulator here**, so booking/payment/RTL behaviour is unverified on
  hardware; the 193 tests are unit/widget tests.

Full analysis: `docs/ALL_OWNERS_IMPLEMENTATION_GAP_REPORT.md`.

## Formatting

`dart format --output=none --set-exit-if-changed .` **now passes** (92 files, 0
changed). It used to fail because the formatter changed between Dart versions and
parts of `main` were never formatted; a single dedicated `dart format .` commit
resolved that, as the Execution 01 test-results addendum recommended. Keep it
clean: run `dart format` on the files you touch before committing.

## Branches

Work on `feature/allowners-new-version-exec01`. Never commit directly to `main`.
Execution 01 is complete; Executions 02–05 are tracked in
`docs/EXECUTION_02_05_PROGRESS.md` and `docs/ALL_OWNERS_REQUIREMENTS_MATRIX.md`
(53 VERIFIED PASS, 50 IMPLEMENTED UNTESTED, 3 PARTIAL, 42 BACKEND BLOCKED).

**Directional icons:** do not write `isArabic ? chevron_left : chevron_right`.
Flutter mirrors every `arrow_*` / `chevron_*` icon in an RTL subtree
(`matchTextDirection` is true for all of them), so the manual flip cancels the
automatic one and the arrow points the wrong way. Use the plain icon and let
`Directionality` do the work; a widget test in `test/widgets_test.dart` guards
this.

## Environment notes

- No Android emulator or device; `flutter devices` lists Linux desktop only.
- **Android release build works in this container** (verified: 69.4 MB `app-release.apk`,
  `com.superai.allowners`, versionCode 20). A fresh container needs a JDK and the SDK:
  ```bash
  sudo apt-get install -y default-jdk-headless          # gives JDK 21
  # cmdline-tools + sdkmanager to /tmp/androidsdk, then:
  export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
  export ANDROID_SDK_ROOT=/tmp/androidsdk ANDROID_HOME=/tmp/androidsdk
  # launcher icons are generated by Codemagic, not committed — replicate first:
  dart run flutter_launcher_icons && dart run flutter_native_splash:create
  flutter build apk --release
  ```
  Without the icon step the build fails with `resource mipmap/ic_launcher not found`. That is
  **not** a repo defect: `codemagic.yaml` runs the same two generators before every build.
- The Flutter build tool auto-"migrates" `android/` on first build (rewrites `minSdkVersion`
  to `flutter.minSdkVersion` and adds `android.builtInKotlin`/`android.newDsl` to
  `gradle.properties`). **Revert the `minSdkVersion` change** — the app ships with `23`, the
  migrator would silently raise it to 24 and drop Android 6.0 users.
- For rendered-screen evidence, a web harness was built at `/tmp/allowner_web`
  with a patched `lib/screenshot_main.dart` that selects screens via
  `?screen=` / `?lang=` / `?v=` URL parameters, served on port 8899. It is
  temporary and deliberately **not** committed.
- `git` has no global identity; a repo-local one is set to `openhands`.

## Original requirements document (resolved)

The owner delivered the original Arabic document in commit `91de5fe`:

- `docs/AllOwners_Original_Under_3MB.docx` — the 51-page requirements document (56 images).
- `docs/AllOwners_Requirements_Inventory.md` — 148 numbered requirements (IDs 1-148, verified
  contiguous with no gaps or duplicates).

Both are authoritative. The earlier `docs/ALL_OWNERS_ORIGINAL_DOCUMENT_BLOCKER.md` is
**superseded** and kept only as a record.

- **Extract the document in document order.** A naive `<w:t>`-only regex silently loses text:
  `<w:tab/>` also matches `<w:t[^>]*>`, which swallows markup into the output. Use
  `(<w:t(?:\s[^>]*)?>(.*?)</w:t>)` and treat `</w:p>` as a line break. Verified extraction:
  17,466 chars / 442 lines / 56 images, matching the raw `<w:t>` total.
- The verbatim extraction and all 56 images are committed under
  `docs/evidence/exec01/original/`.
- **Audit trail:** `docs/ALL_OWNERS_ORIGINAL_REQUIREMENTS_MASTER.md` maps every one of the
  148 requirements to a status and to the file/line that satisfies or misses it.
  `docs/ALL_OWNERS_IMPLEMENTATION_GAP_REPORT.md` records what was implemented, what needs the
  PHP backend / admin panel / website, and what needs an owner decision.

### This repo is the Flutter client only

There is **no PHP backend, no admin panel and no website** here (`find . -name "*.php"`
returns nothing). 26 of the 148 requirements target those surfaces and are marked
"outside this repository" — they are **not** client defects. Do not implement them here, and
do not stub them.

### Do not fabricate to close a requirement

Several requirements (e.g. the named Makkah hotels with «قريباً», per-meal prices, the owner
wallet/ledger) need data or endpoints that do not exist. Hard-coding a hotel list or inventing
a meal price to make a screen look complete is forbidden here. Leave the requirement open and
record the blocker.

### Requirement traceability matrix

`docs/ALL_OWNERS_REQUIREMENTS_MATRIX.md` is the machine-generated traceability matrix: one row
per requirement (1–148), Arabic text verbatim, each mapped to section, execution, status,
Flutter files, API dependency, evidence, remaining work, and an acceptance criterion. Regenerate
it with `tools/gen_requirements_matrix.py` (reads the inventory; never invents text). It
complements `docs/ALL_OWNERS_ORIGINAL_REQUIREMENTS_MASTER.md` (the file/line audit).

Homepage section order is **unresolved** (inventory item 27): the original document lists
destinations before categories; the mandate text lists the reverse. Left as-is and flagged for
owner decision — do not "fix" it without confirmation.

## Environment reset gotcha

The container can be reset mid-session, wiping `/opt/flutter`. If `flutter` is
missing, reinstall Flutter **3.47.7 stable** (required by `pubspec.lock`'s
`flutter: ">=3.47.0"` and Codemagic's `flutter: stable`):

```bash
curl -sL -o /tmp/flutter.tar.xz \
  https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.47.7-stable.tar.xz
mkdir -p ~/sdk && tar -xf /tmp/flutter.tar.xz -C ~/sdk
export PATH=~/sdk/flutter/bin:$PATH
```

Extracting to `/opt` fails on a symlinked pub-cache entry; extract to `$HOME`.

## Document 06 — Group 01 (requirements 1–10)

Implemented and documented in `docs/DOCUMENT_06_GROUP_01.md`. Key invariants to
preserve:

- Guest-facing hospitality vocabulary is «ضيافاتي» / “My Stays”, «رقم الضيافة» /
  “Stay Reference”, «عرض تفاصيل ضيافتي» / “View My Stay Details”. Owner and
  booking-agent wording («حجوزاتي», «عرض تفاصيل الحجز») must stay unchanged.
- `lib/utils/payment_methods_config.dart` is the only source of truth for payment
  method availability. Defaults are **all disabled**; `online` additionally
  requires an `https` hosted-checkout URL from the server. Never enable a method
  client-side and never collect card data.
- `lib/utils/unit_search.dart` holds the shared unit/room-number matcher
  (Arabic-Indic digits, exact → prefix → substring). Reuse it instead of writing
  new filters.
- `lib/utils/housekeeping_settlement.dart` owns the housekeeping settlement rules
  (approved price required, duplicate-settlement guard, role check, server-only
  payment link). Payment links are never synthesised in the app.
- `HotelStaffService.actOnRequest` returns the server response so callers can read
  a server-issued `payment_link`.
- `pubspec.lock` requires Flutter >= 3.47.0. Do not run `flutter pub get` with an
  older SDK and commit the lock: it silently downgrades ~50 packages.

## Document 06 — Group 02 (requirements 11–17)

Implemented and documented in `docs/DOCUMENT_06_GROUP_02.md`. Invariants:

- `lib/utils/request_settlement.dart` is now the **single** implementation of the
  service-request settlement flow (cleaning, meal, extra bed): two options only
  (`wallet_balance` / `whatsapp_link`), approved price required, duplicate guard,
  hotel-dashboard roles only, server-issued `https` payment links only.
  `lib/utils/housekeeping_settlement.dart` is a thin compatibility wrapper over it
  — keep both public APIs working (existing tests use the housekeeping names).
- The hotel-requests screen reads the session **role during build** and passes it
  into the confirm dialog. Do not move that read into the dialog: `sessionProvider`
  is created lazily on first read, and reading it there yields a null role.
- Extra-bed amounts are derived, never invented: `extraBedTotal` uses server
  totals first, else `price × beds × nights` only when all three are real.
- `lib/utils/pricing_forms.dart` owns both pricing sheets (pure logic, tested):
  six unit-type rows (names come from the hotel's real `unit_type_ar/en`, never
  hardcoded) and three meal rows, each with a required title and date.
  `lib/widgets/pricing_widgets.dart` holds the shared form widgets.
- Pricing endpoints (`/hotel/unit-pricing.php`, `/hotel/meal-pricing.php`) do not
  exist yet: the screens degrade to an inline error and never drop existing
  `/hotel/prices.php` data. Owner read-only access goes through
  `OwnerService.getOwnerPricingSheets()`.
- Requirement 17 (remove the nightly price from hotel creation) has no Flutter
  surface — the form lives in the PHP admin dashboard. Do not add a Flutter hotel
  creation screen "to satisfy" it, and do not touch `units.price_per_night` or
  `hotel/prices.php`.
- Corrected Group 01 requirement 4: when no real unit number arrives, the stay
  reference row shows `not_available` («غير متاح حاليًا»). Never put the booking
  reference there; it belongs to the separate `booking_reference_internal` row.
- `RadioListTile.groupValue/onChanged` are deprecated on Flutter 3.47; use a
  `RadioGroup` ancestor (done in `hotel_requests_screen.dart`).

## Document 05/06 final sweep (commit 97bce9e)

- **Home order lives in one place:** `lib/utils/home_sections.dart`
  (`kHomeSectionOrder`, `kFeaturedCityOrder`). `home_screen` iterates it; the
  widget test in `test/screens_render_test.dart` asserts the rendered `dy`
  ordering (categories last). Cities: Makkah → Madinah → Jeddah → Riyadh
  (Riyadh kept per Doc 05 item 18; owner decision C2).
- **Extra bed** = `qty × nightly price × nights` (`computeExtraBedCharge`),
  payload key `extra_bed_qty` (only when > 1). Do not regress to a one-time fee.
- **Availability:** `isDaySelectable` drives `selectableDayPredicate`, and
  `_confirmBooking` refuses `AvailabilityVerdict.outside`. Server-side double
  booking prevention is still pending (backend master §1).
- **Hotel dashboard:** all four cards navigate (arrivals → `HotelArrivalsScreen`,
  departures → `HotelDeparturesScreen`, in-house → `HotelBookingsScreen`,
  open requests → `HotelRequestsScreen`). Both movement screens share
  `utils/unit_search.dart` + `utils/arrivals.dart` / `utils/departures.dart`.
- **Push notifications:** `utils/notification_routing.dart` (pure routing/texts/
  dedupe) + `services/notification_service.dart` (pluggable `PushProvider`,
  default `UnavailablePushProvider`). Never claim live push until Firebase is
  configured and verified on a real device (owner decision C5).
- **Final matrices/docs are generated or explicit:** `tools/gen_final_matrix.py`
  regenerates `docs/ALL_OWNERS_FINAL_REQUIREMENTS_MATRIX.md` from the official
  inventory — edit the status map there, not the markdown.

## Screenshot evidence harness (Doc 05/06)

- Real rendered screenshots (no mockups) live in `docs/evidence/final-acceptance/`.
- Generate with `flutter test test/screenshot_export_test.dart --update-goldens`
  and `flutter test test/screenshot_export_roles_test.dart --update-goldens`.
- The harness (`test/screenshot_support.dart`) needs three things to work:
  bundled fonts under `test/screenshot_assets/fonts/`,
  `AppTheme.light(fontFamilyOverride: ...)` (production default stays GoogleFonts),
  and mocked `path_provider` + Dio `HttpClientAdapter`.
- `units/addons.php` fixtures must use category `meal_plan` for meal rows and
  hotel-level payloads need `extra_bed_price`, otherwise booking sections stay hidden.
- The extra-bed card only renders on the hotel-level booking path today
  (`unitId == null`); unit-level booking lacks it — tracked as an open defect.

## Booking extras: one builder, two paths (fixed 2026-11-26)

- `booking_screen.dart` builds the extras through `_buildExtrasSection(context, isArabic)`.
  Never re-introduce the `if (unitId != null) … else …` collection spread: that is
  exactly how `_ExtraBedCard` became invisible on unit-level bookings.
- The extra-bed price lives on the hotel, so the card and the stepper must render in
  both booking paths. Hide it only when a unit addon has `category == 'extra_bed'`
  (otherwise the bed is billed twice).
- `test/booking_extra_bed_paths_test.dart` pins both paths, the 4-bed cap, the free
  price state and the `extra_bed` / `extra_bed_qty` payload. Run it before touching
  anything in that screen.
- The guest stepper uses the same `Icons.add_circle_outline_rounded` as the extra-bed
  stepper; scope finders to the `Row` that contains the label.
- Screenshot taps on cards below the fold need `ensureVisible`/`scrollUntilVisible`
  first, otherwise the tap silently lands outside the viewport.

## Analyzer zero and the `dart fix` trap (2026-11-26)

- The project must report `No issues found!`. Before this round it carried 143
  infos (62 `withOpacity`, 36 curly-brace, 31 `prefer_const*`, 10 local underscores,
  1 `use_build_context_synchronously`).
- `withOpacity(x)` → `withValues(alpha: x)`. Regenerate screenshots afterwards:
  the alpha rounding changes pixels, so golden comparisons fail until
  `--update-goldens` runs.
- `dart fix --apply` also "fixed" a test helper by deleting a defaulted
  constructor parameter (`this.staffBody = _staffJson`), turning a passing test
  file into a compile error. Never trust it blindly: run `flutter analyze` and the
  full `flutter test` right after, and read the diff of `test/` files.

## Translation gate (why `AppStrings.hasKey` exists)

- `AppStrings.t` returns the key itself when a key is missing, so a missing key is
  invisible in English and glaring in Arabic (`owner_staff_screen` printed the raw
  word `active`; hotel bookings printed `status_checked_out`).
- `test/app_strings_coverage_test.dart` parses every `AppStrings.t(...)` call in
  `lib/`, strips `${...}` interpolations and `['field']` subscripts, and asserts
  every remaining literal key has Arabic and English text. It also checks the
  dynamic families `status_*` and `req_type_*` explicitly.
- When adding a screen string: add the key to `app_strings.dart` first, then the UI.
  A key whose Arabic value equals the key fails the test on purpose.

## Screenshot matrix file

- `test/screenshot_export_matrix_test.dart` holds the bilingual coverage batch
  (onboarding, about, help, owner EN, agent EN, employee EN, plus the staff
  permissions and commission transfer sheets). 86 PNGs total, 53 requirements
  carry a screenshot.
- Sheet screenshots use the `interact` callback: tap the button text, then
  `pumpAndSettle`, otherwise the sheet is not in the frame.

## Toolchain pin for golden screenshots (2026-11-26)

- Use **Flutter 3.44.9 / Dart 3.10.x**. 3.50.1 resolves newer transitive
  packages and adds 120 `cupertino_ui` deprecation infos; 3.32.0 cannot resolve
  the committed lock. Only 3.44.x gives `No issues found!` with this code.
- Goldens are pixel comparisons, so the SDK and `pubspec.lock` are part of the
  test fixture. After any SDK or lock change, regenerate all 86 PNGs:
  `flutter test test/screenshot_export_test.dart test/screenshot_export_roles_test.dart test/screenshot_export_matrix_test.dart --update-goldens`
- Measured drift: 2.35% of pixels between 3.32.0 and 3.44.9 (antialiasing),
  7.72% between different package resolutions. `ScreenshotComparator` in
  `test/screenshot_support.dart` accepts a diff only when **both** ≤3% of
  pixels and mean channel delta ≤12/255, so real layout/text/colour changes
  still fail. `test/screenshot_comparator_test.dart` proves that.
- `test/failures/` is generated output; it is gitignored. Never commit it.

## Push notification lifecycle (2026-11-26)

- `lib/utils/push_lifecycle.dart` owns register/rotate/unregister and stores the
  token **only** after the server answers `success: true`.
- `NotificationService.attach()` is idempotent (`_attached`); call it twice and
  nothing duplicates. Taps surface via `onNotificationTap`.
- `lib/utils/push_tap_router.dart` maps a payload to a role-appropriate screen;
  unknown `target` values are ignored, never guessed. Add new targets in both
  the router and `docs/BACKEND_INTEGRATION_HANDOVER.md` §3.9.
- No Firebase in this repo: `isConfigured` is false, so nothing is sent. Tests
  assert `push_provider_not_configured` / `permission_denied` / `api_503`
  rather than inventing success.

## Traceability matrices (2026-11-26)

- Two independent matrices, both generated — never hand-edit the `.md`:
  - `python3 tools/gen_doc05_matrix.py` → `docs/MATRIX_DOCUMENT_05.md` (148 rows
    from `tools/matrix_data.py` + the verbatim inventory).
  - `python3 tools/gen_doc06_matrix.py` → `docs/MATRIX_DOCUMENT_06.md` (21 rows
    from `tools/doc06_matrix_data.py`).
- The Doc 06 generator **fails** if a row names a `lib/`, `test/` or screenshot
  path that does not exist. Keep it that way: it is what stops the matrix from
  becoming a claim.
- Neither document carries per-requirement page numbers in this repo; both
  matrices say so instead of inventing citations.

## Screenshot captures

- Add a capture in `test/screenshot_export_test.dart` (customer),
  `test/screenshot_export_roles_test.dart` (staff/owner/agent) or
  `test/screenshot_export_doc05_test.dart` (the Doc 05 top-up batch: one
  `testWidgets` per screenshot), run with `--update-goldens`, then
  `git status docs/evidence` — only new files should appear. Existing goldens
  changing means the capture is non-deterministic.
- `test/screenshot_support.dart` `capture()` takes `drainTimers: true` when the
  screen kicks off `flutter_cache_manager` fetches: it drains the 10s cache
  timer inside `runAsync`, otherwise the test fails with "Pending timers".
- `shotPair()` in `test/screenshot_export_doc05_test.dart` renders AR and EN from
  the same `build`; pass `buildEn` when the widget takes localized strings as
  constructor arguments (`ServiceRequestScreen` title/description), otherwise
  Arabic text leaks into the English file.
- English captures must set `locale: 'en'` **and** pass `isArabic: false`;
  forgetting the flag renders Arabic text into an English file.

## Gate baseline and environment (2026-11-26)

- Green baseline to preserve: `dart format` 0 changed (162 files), `flutter
  analyze` clean, `flutter test` **777 passed / 17 skipped / 0 failed**, and 157
  goldens in `docs/evidence/final-acceptance` unchanged.
- The 17 skipped tests are `test/integration/live_backend_test.dart`, gated by
  `RUN_LIVE_TESTS=1` (they hit the production API). Never "fix" the skip count.
- The container may start without a Flutter SDK. Install the pinned version
  before running gates:
  `curl -sL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.44.9-stable.tar.xz | tar xJ -C /tmp/sdk`,
  then `export PATH=/tmp/sdk/flutter/bin:$PATH`. Goldens are pinned to 3.44.9.
- `ApiConfig.baseUrl` honours `--dart-define=API_BASE_URL=…` (default: production),
  so live tests can point at a staging copy without touching production.

## Time-dependent UI must read AppClock

- `lib/utils/app_clock.dart` is the single clock. Screens that build default
  dates (e.g. `booking_screen.dart`) call `AppClock.now()`, never
  `DateTime.now()`; otherwise goldens fail every day the clock advances (this
  actually happened: golden showed 28 Nov while the test rendered 27 Nov).
- `capture()` in `test/screenshot_support.dart` freezes the clock at `kShotNow`
  (2026-11-27, the date the goldens were approved). If a screen needs a
  different "today", pass it explicitly instead of regenerating goldens.

## Requirement matrix statuses

- `tools/gen_requirements_matrix.py` accepts
  `FLUTTER COMPLETE — BACKEND PENDING` — use it when the Flutter side and its
  tests exist but a specific server endpoint is missing (name the endpoint).
  Reserve `BACKEND BLOCKED` for work that has no Flutter surface at all.
- Adding a status also requires updating the known-status set in
  `test/matrix_sync_test.dart`.

## Honesty rules that tests enforce

- Never fabricate a status, balance, payment link, revenue figure or unit
  number. Missing server data renders as "—"/empty state plus an explicit
  "not enabled on the server yet" line.
- `test/financial_safety_test.dart` locks the eight financial guarantees
  (unpaid ≠ revenue, no fake payment links, no double settlement, disabled
  payment methods never submitted, wallet/commission from server only, staff
  finance permission default-closed).

## Final Word report (Arabic RTL deliverable)

- `python3 tools/gen_final_word_report.py` rebuilds
  `docs/ALL_OWNERS_FINAL_IMPLEMENTATION_REPORT.docx` from
  `tools/matrix_data.py` + `tools/doc06_matrix_data.py` +
  `docs/evidence/final-acceptance-hires`. Never hand-edit the .docx.
- PDF companion: `LD_LIBRARY_PATH=/usr/lib/libreoffice/program soffice
  --headless --convert-to pdf --outdir /tmp/pdfout docs/ALL_OWNERS_FINAL_IMPLEMENTATION_REPORT.docx`
  then copy it to `docs/`.
- python-docx pitfalls fixed here: `w:bidiVisual` and `w:tblBorders` must be
  inserted in `tblPr` schema order (a trailing append is silently ignored by
  Word), set `table.columns[i].width` as well as `cell.width` or the grid stays
  equal-width, and use `w:jc="start"/"end"` instead of right/left for
  bidi-correct alignment in both Word and LibreOffice.
- AR/EN screenshot stems differ per language (`-ar` vs `-en` with different
  requirement ranges), so pair them by screen slug inside the same role folder,
  not by exact file name.
