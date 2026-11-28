# All Owners — Final Flutter Completion (Documents 05 & 06)

Branch: `feature/allowners-new-version-exec01` · Pull request: #1 (Draft, base `main`)
Application: Flutter, `com.superai.allowners` · API base: `https://all-owner.online/api`

This document reports the closing Flutter round: what was still incomplete after the
Document 05/06 sweep, what was implemented now, what each item is verified by, and the
exact backend work that remains on cPanel. It is the written companion of
`docs/ALL_OWNERS_FINAL_IMPLEMENTATION_REPORT.docx` (Arabic RTL, 198 pages) and its PDF.

## 1. Status summary

| Area | Before this round | After |
| --- | --- | --- |
| Document 06 requirements 1–17 | complete | unchanged, still complete |
| Account deletion inside the app (Google Play) | web route only, no in-app flow | implemented + tested, backend endpoint pending |
| Notification device state / permission prompt | service only, no UI | status banner + retry in the notifications screen |
| Codemagic configuration | `flutter: stable`, no verification gate | pinned `3.44.9`, `flutter-verify` workflow added |
| Automated tests | 800 passing in the Doc 05/06 sweep | 813 passing, 17 pre-existing skips, 0 failures |

Requirement-level statuses are in `docs/MATRIX_DOCUMENT_05.md` (148 rows) and
`docs/MATRIX_DOCUMENT_06.md` (24 rows). Only the three approved statuses are used:
`COMPLETE AND VERIFIED`, `FLUTTER COMPLETE — BACKEND PENDING`, `INCOMPLETE`.

## 2. What was implemented

### 2.1 Account deletion from inside the app — `§P-01`

Google Play requires an in-app deletion path for any app that offers account creation.
Before this round the repository could only point at a web page; there was no screen,
no service call and no test.

- `lib/screens/profile/delete_account_screen.dart` (new): explains what is deleted and
  what is retained, lists selectable reasons, requires an acknowledgement checkbox and
  typing the confirmation word (`حذف` / `DELETE`), and refuses to continue while the
  user has an upcoming stay.
- `lib/services/auth_service.dart` — `deleteAccount({String? reason})` posts
  `{"confirm": true, "reason": …}` to `/user/delete-account.php` and clears the token
  only on a real success answer.
- `lib/utils/session_provider.dart` — `deleteAccount()` calls the service, cancels push
  registration and empties the session; the exception is re-thrown so the screen can
  tell "not enabled" from "network failed".
- `lib/screens/profile/profile_screen.dart` — new danger row «حذف الحساب» above
  «تسجيل الخروج»; sign-out is untouched.

Honesty rules enforced by tests: a `404` shows "not enabled on the server" and erases
nothing; a `success: false` body is treated as a failure; a network error keeps the
session and the stored token.

### 2.2 Device notification state and permission request — `§P-02`

`NotificationService.register()` existed but nothing in the UI ever called it, so the
user could not tell whether notifications worked, and a denied permission was silent.

- `lib/widgets/push_status_banner.dart` (new): renders the last real registration
  result plus its reason, and offers «تفعيل الإشعارات» / «إعادة المحاولة». It never
  shows "enabled" unless the service returned `registered: true`.
- `lib/screens/owner/owner_notifications_screen.dart`: the banner sits above the list,
  so every role that opens notifications sees the state of the current device.

Reason mapping is explicit: `push_provider_not_configured` (no Firebase in this build),
`permission_*` (denied by the OS), `no_device_token`, and any `api_*` code is shown with
its code rather than a generic "error".

### 2.3 Codemagic readiness — `§P-03`

- `codemagic.yaml` now pins `flutter: 3.44.9` in all workflows — the exact version the
  golden screenshots were rasterised with. `stable` drifted and produced pixel failures
  that had nothing to do with the app.
- Added the `flutter-verify` workflow: `pub get` → `dart format --set-exit-if-changed
  lib test` → `flutter analyze` → `flutter test`. It produces no APK/AAB and no build
  was triggered from this workspace.
- `applicationId`, `namespace`, signing block, keystore indirection
  (`android/key.properties` written by Codemagic) and the three release workflows are
  unchanged.

### 2.4 Visual identity and evidence

Seven goldens changed because the two screens above gained rows and a banner; they were
regenerated with `--update-goldens`, reviewed as images, and no unrelated PNG moved:

- `customer/{arabic,english}/DOC05-REQ-144-profile-*.png` — new deletion row
- `customer/{arabic,english}/DOC05-REQ-009-avatar-options-*.png` — profile behind the
  sheet scrim
- `owner/{arabic,english}/DOC05-REQ-071-owner-notification-body-*.png` and
  `DOC05-REQ-134-owner-notifications-*.png` — status banner

Eight new evidence pairs were captured (1× golden + 2× hires) under
`customer/{arabic,english}/DOC06-POLICY-delete-account-{form,done,blocked}-*.png` and
`DOC06-POLICY-profile-delete-entry-*.png`.

## 3. Tests

New files:

| File | Tests | Covers |
| --- | --- | --- |
| `test/delete_account_test.dart` | 10 | AR/EN copy, disabled button before ack/word, confirmation word, upcoming-booking block, real success + session cleared + token removed, 404 keeps everything, network failure, `success:false`, `reason` payload, 404 → `ApiErrorKind.notFound` |
| `test/push_status_banner_test.dart` | 6 | AR/EN copy, provider missing, successful registration, denied permission, pre-set reason from the session, unknown server reason shown with code |
| `test/screenshot_export_account_deletion_test.dart` | 8 | golden + hires capture of the four new screen states in both languages |

Gate run on this branch:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .   # 0 changed
flutter analyze                                     # No issues found
flutter test                                        # 813 passed, 17 pre-existing skips
```

No test was disabled or skipped to reach this result; the 17 skips come from the
pre-existing suite and were present before this round.

## 4. Backend requirements for the cPanel phase (exact)

### 4.1 `POST /api/user/delete-account.php` — required by `§P-01`

Request (the app sends exactly this, authenticated with the session token):

```json
{ "confirm": true, "reason": "delete_account_reason_privacy" }
```

`reason` is optional and is one of `delete_account_reason_no_longer`,
`delete_account_reason_privacy`, `delete_account_reason_other`, or absent.

Required behaviour:

1. Reject unauthenticated calls with `401`.
2. If the user has a booking in `pending`, `confirmed` or `checked_in` whose `check_out`
   is today or later, answer `409` and an Arabic `message`; the app shows it as-is.
3. Otherwise delete or deactivate the account, revoke every session token for it, and
   remove its device tokens from `user/device-token.php` storage.
4. Answer `200 {"success": true}` — and only then does the app show the done screen.
5. Keep a deletion route on the website (`https://all-owner.online/delete-account`) for
   users who cannot open the app; the app links to it.

Acceptance: deleting a test account returns `success: true` and the old token gets `401`
on the next call; an account with an upcoming stay is refused with `409`.

### 4.2 Firebase + `POST /api/user/device-token.php` — required by `§P-02`

The client already sends `{"token", "platform", "locale"}`, `{"token",
"action": "unregister"}` and refreshes on `onTokenRefresh`. Two things are missing and
both are outside this repository:

1. `android/app/google-services.json` + `lib/firebase_options.dart` for the real project
   (application id `com.superai.allowners`), then `Firebase.initializeApp()` succeeds and
   `isConfigured` becomes true.
2. The server stores one token per user/device with `platform` and `locale`, honours the
   unregister action, and sends through the Firebase Admin SDK while respecting each
   role's access (never notify a user about a booking they may not see).

Acceptance: a registered device receives one notification when a booking changes state;
after signing out, that device receives nothing.

## 5. Protections preserved

- Arabic RTL and English LTR untouched; no screen was redesigned, only extended.
- Document 05 and 06 (groups 01 and 02) behaviour unchanged; matrix statuses for those
  rows did not move.
- Google Play account-deletion functionality preserved and now completed inside the app.
- `com.superai.allowners` unchanged; signing configuration unchanged.
- No APK/AAB built locally, no Codemagic build triggered, no cPanel change, no merge to
  `main`, no force push; PR #1 stays open and Draft.

## 6. Remaining, by design

| Item | Status | Blocked by |
| --- | --- | --- |
| Account deletion end-to-end | FLUTTER COMPLETE — BACKEND PENDING | `user/delete-account.php` |
| Push notifications arriving on a device | FLUTTER COMPLETE — BACKEND PENDING | Firebase config + `device-token.php` storage/sending |
| Live guest service-request status (Doc 05 #59) | FLUTTER COMPLETE — BACKEND PENDING | `GET /services/my-requests.php` |
| Payment method availability enforced server-side (Doc 06 #7, #8) | FLUTTER COMPLETE — BACKEND PENDING | `content/settings.php` + admin flag + rejection in `bookings/create.php` |
| Housekeeping settlement (Doc 06 #10) | FLUTTER COMPLETE — BACKEND PENDING | approval price + payment link endpoints |

Nothing in this list is claimed as working; each row names the endpoint that would make
it real.
