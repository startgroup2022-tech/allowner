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
  `max_price` — but **no text search**. Hotel-name search is client-side.
- `units/browse.php` **does** support `q`, `city`, `hotel_id`, `owner_only`.
- `hotels/detail.php` returns `gallery: null` (not `[]`) and `units: []`.
- `units/detail.php` returns no `facilities` or `amenities` key at all.
- All `auth/forgot*` paths return **404** — there is no password reset.
- All ratings are `0`; the UI suppresses the rating chip when it is 0.

Details and owner decisions: `docs/EXECUTION_01_BACKEND_DEPENDENCIES.md`.

## Formatting

`dart format --set-exit-if-changed .` **fails** on this repo, for two
pre-existing reasons: the formatter changed between Dart versions (files
byte-identical to `main` are re-wrapped), and parts of `main` were never
formatted. Do not run a repo-wide format as part of an unrelated change — it
produces a large diff that hides the real work. Format only the files you touch.

## Branches

Work on `feature/allowners-new-version-exec01` (Execution 01). Never commit
directly to `main`. Execution 01 is complete at commit `7862e23`.

## Environment notes

- No Android emulator or device; `flutter devices` lists Linux desktop only.
- For rendered-screen evidence, a web harness was built at `/tmp/allowner_web`
  with a patched `lib/screenshot_main.dart` that selects screens via
  `?screen=` / `?lang=` / `?v=` URL parameters, served on port 8899. It is
  temporary and deliberately **not** committed.
- `git` has no global identity; a repo-local one is set to `openhands`.
