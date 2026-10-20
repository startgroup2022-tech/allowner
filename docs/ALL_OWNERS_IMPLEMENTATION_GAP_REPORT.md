# All Owners — Implementation Gap Report

**Branch:** `feature/allowners-new-version-exec01`
**Draft PR:** [#1](https://github.com/startgroup2022-tech/allowner/pull/1)
**Head at time of this report:** `4e98000`
**Date:** 2026-10-20

---

## 0. Scope — what this report is and is not

This report audits the **actual repository** against the live backend and the Execution 01
mandate. Every finding below was read from the source in this session.

It is **not** a compliance report against the original Arabic requirements document,
because that document was never delivered. See
`docs/ALL_OWNERS_ORIGINAL_DOCUMENT_BLOCKER.md`. The task's Phase 3 list (hotel management
dashboard, booking agent dashboard, payments and accounting, subscriptions, notifications
and email, PHP backend, database schema) is audited **as it appears in this client
repository**; the PHP backend and database are a separate system and are **not** in this
repository, so their internals could not be inspected — only the client's calls to them.

---

## 1. What is present and working

| Area | Evidence in this repo | Status |
|---|---|---|
| Flutter customer app | 73 Dart files; 58/58 tests pass; 0 analyzer errors/warnings | ✅ implemented |
| Arabic RTL + English | `AppStrings.t(isArabic, key)`, `localeProvider`; a test enforces every string exists in both languages | ✅ implemented |
| Auth | `auth/login.php`, `register.php`, `logout.php`, `me.php`; bearer-token interceptor | ✅ implemented |
| Hotel / unit discovery | `hotels/list.php`, `hotels/detail.php`, `units/browse.php`, `units/detail.php`, `units/list.php` | ✅ implemented |
| Search + filters | `search_screen.dart`, `filters_sheet.dart`; 3 filter defects fixed in Execution 01 | ✅ implemented |
| Booking creation | `bookings/create.php` with meals, extra bed, add-ons, guest ID | ✅ implemented |
| My bookings / management | `bookings/my.php`, `bookings/manage.php` | ✅ implemented |
| Hotel staff dashboard | `hotel/dashboard.php`, `bookings`, `prices`, `requests`; 5 screens | ✅ implemented |
| Owner dashboard | 8 `user/owner-*.php` endpoints; ~14 owner screens (units, staff, revenue, maintenance, meals, requests, documents, decisions, community, marketplace, messages, commission) | ✅ implemented |
| Booking agent | `user/agent-clients.php`, `user/agent-commission.php`; `agent-clients` and commission screens | ✅ implemented |
| Favorites | `favorites/my.php`, `favorites/toggle.php` | ✅ implemented |
| Community / decisions | `community/*` (list, post, comments, like), `decisions/*` (list, create, vote) | ✅ implemented |
| Messages | `messages/conversations.php`, `thread.php`, `send.php`, `directory.php` | ✅ implemented |
| Marketplace | `marketplace/list.php`, `create.php`, `interest.php` | ✅ implemented |
| Notifications (in-app) | `user/notifications.php`, `markAllNotificationsRead()` | ✅ implemented |
| Maintenance / housekeeping | `user/owner-maintenance.php`, `owner_cleaning_screen.dart`, `owner_maintenance_screen.dart` | ✅ implemented |
| Meals / extra beds | `services/meal-request.php`, `units/addons.php`, meal + extra-bed fields on booking | ✅ implemented |
| Safe JSON parsing | `lib/utils/safe_parse.dart` (`asInt`/`asDouble`/`asBool`/`asString`/`asMapList`/`asStringList`/`localized`) | ✅ implemented |
| No fabricated content | 0 `TODO`/`FIXME`/"coming soon"/"قريباً" in `lib/`; test enforces it | ✅ verified |
| App identity + CI | `com.superai.allowners` in gradle + all 3 Codemagic workflows | ✅ preserved |

---

## 2. Gaps and risks found in this audit

Ordered by severity. Each is a real observation from the source, not a guess.

### G1 — Raw card numbers are transmitted to the backend · **HIGH (security)**

`lib/screens/booking/booking_screen.dart` collects a card number and sends it as
`card_number` in the `bookings/create.php` body:

```dart
cardNumber: _paymentMethod == PaymentMethod.online
    ? _cardNumberController.text.replaceAll(RegExp(r'\D'), '')
    : null,
```

`lib/services/hotel_service.dart` then posts it:

```dart
if (cardNumber != null) 'card_number': cardNumber,
```

**Why it matters.** A PAN sent to a first-party PHP endpoint puts the platform in PCI-DSS
scope and exposes card data to the server and to every log along the way. The only
compliant designs are a hosted payment field / tokenising SDK (so the PAN never touches the
app or the server) or a redirect to a PSP. Storing or forwarding a PAN requires
SAQ-D-level controls that this stack shows no sign of having.

**Status:** missing / requires owner decision. **Do not fix unilaterally** — the correct fix
is a payment-gateway decision the owner must make. See §3.

### G2 — Three payment methods, two of which conflict with each other · **HIGH (business rule)**

`booking_screen.dart` defines:

```dart
enum PaymentMethod { online, atHotel, ownerTransfer }
```

and sends `'online'`, `'owner_transfer'` or `'at_hotel'`. Yet the owner side also has a
**commission** model (`user/agent-commission.php`, `owner_commission_screen.dart` with
`total_commission`, paid/unpaid/pending statuses).

These two models encode **opposite business rules**:

- *centralised collection* — the platform takes the guest's money and settles with the
  owner (commission model); versus
- *direct owner transfer* — the guest pays the owner directly and the platform is bypassed
  (no commission is earned on that booking).

The code implements **both simultaneously** with no rule choosing between them and no
stated effect of `owner_transfer` on the commission ledger. The task explicitly flags this
conflict. It is a **business decision, not a coding decision** — see §3.

### G3 — The PHP backend and database are outside this repository · **MEDIUM**

The audit brief lists the PHP backend, APIs, database schema and migrations as areas to
inspect. This repository is the **Flutter client only**; it contains no PHP, no schema and
no migrations. The client calls 53 endpoints on `https://all-owner.online/api`, but their
server-side behaviour (authorisation, validation, double-booking prevention, payment state)
**cannot be verified from here**. Any claim that server-side validation or RBAC is correct
would be unfounded.

### G4 — No subscriptions module in the client · **MEDIUM**

The brief lists "Subscriptions" as an area. There is no subscription, plan, billing-cycle or
entitlement code anywhere in `lib/`. If subscriptions exist, they are backend-only and not
surfaced in this app; if they do not exist, this is a missing module. Cannot be resolved
without the backend or the original document.

### G5 — Email is not implemented in the client · **MEDIUM**

The brief lists "Notifications and email". **In-app** notifications exist
(`user/notifications.php`). There is **no email** path in the client (no mail sending, no
email-preference screen). Email would normally be server-side; nothing in this repo confirms
it exists.

### G6 — No on-device verification possible here · **MEDIUM**

No Android device or emulator is available in this container (`flutter devices` lists Linux
desktop only). The 58 passing tests are **unit/widget tests**, not end-to-end device runs.
Booking, payment and RTL rendering on a real device are **unverified**.

### G7 — Hotel management dashboard vs. owner dashboard boundary is untested · **LOW**

`hotel_*` screens (staff) and `owner_*` screens (owner) both exist, but the tests cover
parsing, filtering and string parity — **not** role-based screen access. Whether a
`hotel_manager` can reach an owner-only screen (or vice versa) is a client-side routing
question; real enforcement must be server-side and cannot be checked here.

---

## 3. Decisions required from the owner (do not implement without approval)

| # | Decision | Blocks |
|---|---|---|
| D1 | **Payment model:** centralised collection (platform collects, commission to owner) **or** direct owner transfer **or** both with an explicit rule. | G1, G2 |
| D2 | **Payment gateway:** which PSP, and does it offer a hosted field / tokenising SDK so the app never sees a PAN? | G1 |
| D3 | **Commission ledger:** what happens to commission on an `owner_transfer` booking — zero, deferred, or manually reconciled? | G2 |
| D4 | **Subscriptions:** do they exist? If yes, what is the plan model and where does it live? | G4 |
| D5 | **Email:** is transactional email required, and through which provider? | G5 |

Per the task rule — *"Do not introduce financial policies without owner approval"* — none of
these were implemented.

---

## 4. How this reconciles with the previous 148-point inventory

The 148-point inventory is **not available** in this environment (see the blocker document).
No row-by-row reconciliation was performed, and none is claimed. What can be said honestly:

- The matrix in `docs/ALL_OWNERS_REQUIREMENTS_MATRIX.md` verifies **129 requirements
  derivable from the mandate, the live backend and the source** — not from the original
  document.
- It is **not** presented as the owner's inventory, and it is **not** used as a substitute
  for the original document.
- The 110 "Verified" rows in that matrix mean "verified against the code and backend", not
  "verified as matching the original requirement". The matrix already states this.

---

## 5. Summary counts

| Metric | Value |
|---|---|
| Requirements extracted from the **original document** | **not computable** — document not supplied |
| Verified against the **code + live backend** (this session) | 58/58 tests pass; 0 analyzer errors/warnings; 53 endpoints wired; 0 fabricated content |
| Partially implemented | G5 (in-app only, no email), G7 (screens exist, role access untested) |
| Missing | G1 (safe payment capture), G4 (subscriptions) |
| Blocked | G3 (backend/database not in this repo), original-document reconciliation |
| Requiring owner approval | D1–D5 (5 decisions) |

---

*This document was produced by an AI agent (OpenHands) on behalf of the repository owner.
It contains no invented requirement text and no unapproved financial policy.*
