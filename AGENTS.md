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
flutter test                    # 200 unit/widget tests pass, 16 live tests skip
dart format --output=none --set-exit-if-changed .   # clean (93 files)

# Live integration tests against the real backend (network required):
flutter test test/integration/live_backend_test.dart --dart-define=RUN_LIVE_TESTS=true

# Android release build (needs JDK + Android SDK, see below):
flutter build apk --release
```

**`--dart-define=RUN_LIVE_TESTS=true` is required** — `bool.fromEnvironment` does not accept
`1`. Without the define the 16 integration tests skip, so a Codemagic build stays offline-safe.

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
