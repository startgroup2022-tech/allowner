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
flutter analyze                 # baseline: 0 errors, 0 warnings, 80 info
flutter test                    # 58 tests
dart format lib/ test/          # see "Formatting" below
```

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

- **Card numbers are posted to the backend.** `booking_screen.dart` sends the raw PAN as
  `card_number` to `bookings/create.php`. That puts the platform in PCI scope. The fix is a
  hosted-field/tokenising PSP flow, which is a **payment-gateway decision**, not a code
  cleanup. Do not add "card storage" or a new payment path unilaterally.
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
  hardware; the 58 tests are unit/widget tests.

Full analysis: `docs/ALL_OWNERS_IMPLEMENTATION_GAP_REPORT.md`.

## Formatting

`dart format --set-exit-if-changed .` **fails** on this repo, for two
pre-existing reasons: the formatter changed between Dart versions (files
byte-identical to `main` are re-wrapped), and parts of `main` were never
formatted. Do not run a repo-wide format as part of an unrelated change — it
produces a large diff that hides the real work. Format only the files you touch.

## Branches

Work on `feature/allowners-new-version-exec01` (Execution 01). Never commit
directly to `main`. Execution 01 is complete at commit `bfe0a93`.

## Environment notes

- No Android emulator or device; `flutter devices` lists Linux desktop only.
- For rendered-screen evidence, a web harness was built at `/tmp/allowner_web`
  with a patched `lib/screenshot_main.dart` that selects screens via
  `?screen=` / `?lang=` / `?v=` URL parameters, served on port 8899. It is
  temporary and deliberately **not** committed.
- `git` has no global identity; a repo-local one is set to `openhands`.
