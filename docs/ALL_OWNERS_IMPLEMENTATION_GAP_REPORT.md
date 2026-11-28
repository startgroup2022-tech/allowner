# All Owners — تقرير الفجوات وتسوية المتطلبات / Gap Report & Reconciliation

**Branch:** `feature/allowners-new-version-exec01` · **Draft PR:** [#1](https://github.com/startgroup2022-tech/allowner/pull/1)
**Audit date:** 2026-10-20 · **Master register:** `docs/ALL_OWNERS_ORIGINAL_REQUIREMENTS_MASTER.md`

> **Update.** An earlier revision of this report stated that the original Arabic document
> was never delivered and that no row-by-row reconciliation was possible. That is no longer
> true: the owner committed `docs/AllOwners_Original_Under_3MB.docx` and
> `docs/AllOwners_Requirements_Inventory.md` in `91de5fe`. The document was extracted
> verbatim (17,466 chars, 442 lines, 56 images) and all 148 requirements were audited
> against the code. See the master register. Sections 2 and 3 below (security and business
> findings) remain valid and are retained unchanged.

---

## 1. Scope statement — what this repository actually is

The repository `startgroup2022-tech/allowner` contains **one Flutter client** (`lib/`,
`android/`, `ios/`, `test/`). It contains **no PHP backend, no admin panel and no website**:
`find . -name "*.php"` returns nothing.

The owner's document describes changes across **four surfaces**:

| Surface | In this repo? | Consequence |
|---|---|---|
| Flutter app (`lib/`) | yes | fully auditable and implementable here |
| PHP API (`https://all-owner.online/api`) | no | requirements touching it cannot be implemented here |
| Admin panel | no | cannot be implemented here |
| Website | no | cannot be implemented here |

Of the 148 requirements, **26 are marked outside this repository** and are not defects in
this codebase. They are listed in section 5 so the owner can route them to the right surface
instead of expecting them here.

---

## 2. Implemented in this round — verified

| # | Requirement | Change | Evidence |
|---|---|---|---|
| 5 | Tagline must be the document's wording | `app_tagline` replaced; the splash screen reads it from `AppStrings` instead of a hard-coded Arabic literal | `app_strings.dart:7`; `splash_screen.dart:77`; test asserts exact strings |
| 32 | Step-4 button must read «تفاصيل الحجز» before confirming | The primary button now opens a **details review sheet** (unit, dates, nights, guests, agent customer, ID number, extra bed, full price breakdown, payment method) whose own button confirms the booking | `booking_screen.dart` `_openDetailsReview` + `_ReviewRow` |
| 98 | Agent's second tab must be «حجوزاتي», not «وحداتي» | The agent's tab renders `MyBookingsScreen` with label `my_bookings`; owners keep `OwnerUnitsScreen` / `nav_units` | `owner_navigation_screen.dart:32-33,53` |
| 100 | Agent menu must say commission reports, not financial reports | First profile item becomes `my_commission` to `OwnerCommissionScreen` for agents | `owner_profile_screen.dart:138-146` |
| 101 | Remove contracts & documents from the agent menu | Gated with `if (!isAgent)` | `owner_profile_screen.dart:150` |
| 102 | Remove owners' community from the agent menu | Gated with `if (!isAgent)` | `owner_profile_screen.dart:177` |
| 103 | Remove voting from the agent menu | Gated with `if (!isAgent)` | `owner_profile_screen.dart:161` |
| 105 | Add meal requests to the agent menu | Added `OwnerMealRequestsScreen` entry | `owner_home_screen.dart:80-85` |
| 106 | Add cleaning requests to the agent menu | Added `OwnerCleaningScreen` entry | `owner_home_screen.dart:86-90` |
| 107 | Add extra bed to the agent menu | Added an entry routed to the service-request surface | `owner_home_screen.dart:91-95` |

Requirement 104 (keep maintenance for the agent) was already satisfied and was deliberately
preserved while gating 101-103.

---

## 3. Corrections to the previous audit

Two earlier conclusions were **wrong**, because the screen was grepped but not the service
layer:

| # | Earlier claim | Actual state |
|---|---|---|
| 40 | "no guest-side modify" | `my_bookings_screen.dart:231` calls `editMyBooking` to `bookings/manage.php`. Implemented, gated on the server's `can_edit`. |
| 41 | "no guest-side cancel" | `my_bookings_screen.dart:172` calls `cancelMyBooking`. Implemented, gated on the server's `can_cancel`. |

Requirements 42-43 (agent modify/cancel) are downgraded from missing to partial for the same
reason: the same screen serves agents, so the action is reachable; whether the server sets
`can_edit`/`can_cancel` for an agent's own booking is a backend question.

---

## 4. Status counts (machine-tallied from the register)

| Status | Count |
|---|---|
| Implemented | 67 |
| Partial | 17 |
| Missing in the client | 38 |
| Outside this repository / needs a decision | 26 |
| **Total** | **148** |

Every ID 1-148 appears exactly once in the register; there are no gaps.

---

## 5. Not implementable in this repository — route to the right surface

**PHP API:** 26 (city search), 44 (confirmation email), 45 (double-booking prevention),
47 (website parity), 56 (extra-bed cost), 77 (request emails), 108 (commission payout),
110 (forgot-password endpoints — all `auth/forgot*` return 404), 116 (website tagline),
132, 137, 138, 141, 142, 144-148 (email content).

**Admin panel:** 63, 65 (dashboard half), 67 (dashboard half), 111, 112, 113, 114 (menu
reorder — the required 16-item order is transcribed in the register, section 11), 115.

**Owner decision required before any code:** 138 (Split Payment / Payouts through a licensed
PSP). The document itself notes that holding owner funds directly falls inside SAMA-regulated
payment-services scope and recommends a licensed provider. This is a business/compliance
decision, not an engineering one, and is **not** implemented.

---

## 6. High-priority open items inside the client (not yet done)

Each needs a backend field that does not exist yet, or an owner decision. That is why it was
not implemented in this round.

| # | Item | Blocker |
|---|---|---|
| 24-25 | The 13 named Makkah hotels plus Madinah/Jeddah/Riyadh with «قريباً» | Needs the hotel list and a "Soon" concept; every list is server-driven today. Hard-coding a list would fabricate data, which this repo forbids. |
| 51 | Replace the meal-request notes field with the meal total | `services/meal-request.php` returns no per-meal price and there is no meal-price endpoint; showing a total would mean inventing prices. |
| 68 | Hotel service prices must be visible to the owner | Requires the API to expose hotel prices to the owner role. |
| 72 / 92 | Attach an image to maintenance requests (owner and hotel) | Requires a multipart upload endpoint for requests; none exists. |
| 74 | Full staff-permission editing for owners | `owner_staff_screen` toggles status only; a permission catalogue endpoint is needed. |
| 76 | Five unit service categories with details | Needs a category model in the API. |
| 81 | Search a unit by number at hotel check-in/out | Needs a lookup endpoint by unit number. |
| 109 / 118 | Owner and agent bank-account details | `units/detail.php` returns an `owner_bank` field that is not modelled; a save endpoint is also needed. |
| 121-125 | Annual owner subscription (browse-only until paid, activation page, terms, commission %) | Whole feature absent, front and back. The document treats this as a core commercial rule, so it should be scoped deliberately rather than stubbed. |
| 126-129 | Financial reports: monthly and yearly, sales minus maintenance minus cleaning, plus maintenance/cleaning expense reports | Requires revenue/expense aggregation the API does not return. |
| 130-131 | Deduct maintenance from unit balance; send a WhatsApp payment link | Both are payment actions; they need a PSP and an owner decision. |
| 133-136 | Owner ledger and wallet | Requires ledger tables in the API. |

---

## 8. Gaps and risks found in the first audit (retained)

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
is a payment-gateway decision the owner must make. See section 9.

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
conflict. It is a **business decision, not a coding decision** — see section 9.

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

## 9. Decisions required from the owner (do not implement without approval)

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

## 10. Verification performed

```
flutter analyze   -> 0 errors, 0 warnings, 77 info
flutter test      -> 61/61 passed   (58 pre-existing + 3 added for this round)
```

The 3 added tests assert the exact tagline strings from the document, that every newly used
key exists in both Arabic and English, and that the agent's second tab label is «حجوزاتي» and
not «وحداتي». The `info` count is the pre-existing documented baseline; one new
`prefer_const_constructors` info on the splash tagline is unavoidable because the string is
now locale-dependent.

---

*This document was produced by an AI agent (OpenHands) on behalf of the repository owner.
No requirement was invented, and no unverified claim is marked as verified.*
