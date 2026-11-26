# Flutter → cPanel integration handover

**Branch:** `feature/allowners-new-version-exec01` · **PR:** [#1](https://github.com/startgroup2022-tech/allowner/pull/1) (Draft)
**Scope of this document:** what the Flutter client *actually* sends and reads, so the
PHP side can be reconciled field by field.

> This document was **not** written from the PHP source. See §1: the backend
> repository was not readable from this environment. Everything below is derived
> from the shipping Flutter code (`lib/services/**`, `lib/utils/**`), which is the
> authoritative statement of what the server must accept and return.

---

## 1. Backend repository access — honest status

| Attempt | Command | Result |
|---|---|---|
| GitHub API, authenticated | `GET /repos/mohammadaljallad079-rgb/allownerapp` | **HTTP 404** |
| Git, unauthenticated | `git ls-remote https://github.com/mohammadaljallad079-rgb/allownerapp` | `Repository not found` |
| Git, token in URL | `git ls-remote https://<token>@github.com/…/allownerapp` | `Repository not found` |
| Public page | `GET https://github.com/mohammadaljallad079-rgb/allownerapp` | **HTTP 404** |

A 404 from an authenticated call means either the repository is private and this
token has no access, or it was renamed/deleted. **No PHP file was read, and none
was modified.** If the repository is made readable to this account, the
reconciliation table in §4 can be filled in mechanically — the "Flutter expects"
column is already exact.

---

## 2. Transport conventions the client relies on

| Item | Value in the app | Where |
|---|---|---|
| Base URL | `https://all-owner.online/api` | `lib/services/api_client.dart` (`ApiConfig.baseUrl`) |
| Auth | `Authorization: Bearer <token>` after `auth/login.php` | `ApiClient` interceptor |
| Envelope | JSON object; `success: false` means failure, `message` is the error text | `_ensureSuccess` in every service |
| Payload lists | Responses return the list under a named key (`units`, `hotels`, `bookings`, …) — the client never assumes a bare array | `asMapList(...)` |
| Error taxonomy | timeout / network / unauthorized / badResponse — mapped in `ApiException.fromDioError` | `lib/services/api_client.dart` |
| Card data | The client refuses to send any payload matching card-number patterns (`findPaymentDataLeaks`) | `lib/utils/booking_payload.dart` |

**Hard rule the server must uphold:** payment authorisation is never trusted from
the client. The app only ever sends a *method key*, never an amount or a card.

---

## 3. Endpoints the client calls (58)

Grouped by the role that uses them. "Keys" = the request/response field names the
Dart code reads or writes — if PHP renames one, the screen silently degrades.

### 3.1 Auth & profile

| Method | Path | Request keys | Response keys read |
|---|---|---|---|
| POST | `/auth/login.php` | `email`, `password` | `token`, `user{id,full_name,email,phone,role}` |
| POST | `/auth/register.php` | `full_name`, `email`, `phone`, `password`, `role` | `token`, `user{}` |
| POST | `/auth/logout.php` | — | `success` |
| GET | `/auth/me.php` | — | `user{}` |
| POST | `/auth/forgot-password.php` | `email` | `message` |
| POST | `/user/update-profile.php` | `full_name`, `phone`, `email` | `user{}` |
| POST | `/user/avatar.php` | multipart `avatar` | `user{avatar}` |
| POST | `/user/device-token.php` | `token`, `platform` | `success` |

### 3.2 Discovery

| Method | Path | Request keys | Response keys read |
|---|---|---|---|
| GET | `/cities/list.php` | — | `cities[]` |
| GET | `/categories/list.php` | — | `categories[]` |
| GET | `/hotels/list.php` | `city`, `q`, `page` | `hotels[]` (`id,name_ar,name_en,city,rating,units_count,image`) |
| GET | `/hotels/detail.php` | `id` | `hotel{…}`, `units[]`, `availability[]` |
| GET | `/units/browse.php` | `q`, `city`, `category`, `min_price`, `max_price`, `guests`, `owner_only`, `sort` | `units[]` |
| GET | `/units/list.php` | `hotel_id` | `units[]` |
| GET | `/units/detail.php` | `id` | `unit{}`, `addons[]`, `availability[]` |

### 3.3 Booking (Document 06 core)

| Method | Path | Request keys | Response keys read |
|---|---|---|---|
| POST | `/bookings/create.php` | see payload below | `booking{booking_ref,total,nights,unit_number,check_in,check_out,status}` |
| GET | `/bookings/my.php` | `status` (optional) | `bookings[]` (`id,booking_ref,hotel_name,unit_number,unit_name,check_in,check_out,nights,status,total,can_check_in,can_check_out`) |
| POST | `/bookings/manage.php` | `id`, `action` (`cancel` \| `modify`), `check_in`, `check_out` | `booking{}` |

Exact `bookings/create.php` payload built by `buildBookingPayload`:

```json
{
  "hotel_id": 2,
  "unit_id": 13,              // omitted for hotel-level bookings
  "check_in": "2026-11-27",
  "check_out": "2026-11-29",
  "guests": 2,
  "payment_method": "cash",   // online | cash | bank_transfer
  "meal_types": ["breakfast"],
  "extra_bed": true,
  "extra_bed_qty": 2,         // only when > 1
  "addon_ids": [5, 6],        // omitted when empty
  "guest_id_number": "1023456789",
  "customer_name": "…",       // booking-agent bookings only
  "customer_phone": "…"       // booking-agent bookings only
}
```

Server-side requirements this payload implies:

1. `extra_bed_qty` defaults to `1` when absent. The charge must be
   `qty × nightly_extra_bed_price × nights` — the same formula the app shows
   (`extraBedChargeFormula`). If PHP multiplies by anything else the receipt and
   the price breakdown will disagree.
2. `unit_number` in the response must be the **real unit number** of the booked
   unit. The confirmation screen prints what the server returns and falls back to
   the number the guest selected — it must never print `booking_ref` in that slot.
3. `payment_method` must be validated against the admin-enabled set (§4). A
   disabled method must be rejected here, not merely hidden in the UI.
4. Double booking must be rejected atomically (row lock or unique constraint on
   `unit_id + date range`), not by a check-then-insert.

### 3.4 Site settings (drives requirements 6, 7, 8 and payment visibility)

| Method | Path | Response keys read |
|---|---|---|
| GET | `/content/settings.php` | `payment_methods{online,cash,bank_transfer}`, `payment_<method>_enabled`, `online_checkout_url` / `checkout_url`, `support_email`, `support_phone`, `whatsapp` |
| GET | `/content/get.php` | `title`, `body` (about / terms / privacy) |

Resolution logic (`lib/utils/payment_methods_config.dart`):

```
payment_methods may be:
  - an object  {"online": false, "cash": false, "bank_transfer": false}
  - a list     ["online"]                      → listed = enabled
  - flat keys  payment_online_enabled / payment_cash_enabled / payment_bank_transfer_enabled
online is enabled only if a valid absolute https checkout URL is also present.
Absent flags mean DISABLED — the client fails closed, not open.
```

### 3.5 Guest services, favourites, messaging, community

| Method | Path | Notes |
|---|---|---|
| POST | `/services/request.php` | `booking_id`, `room_number`, `service_type`, `description` |
| POST | `/services/meal-request.php` | `booking_id`, `room_number`, `meals[]`, `notes` |
| GET/POST | `/favorites/my.php`, `/favorites/toggle.php` | `unit_id` / `hotel_id` |
| GET/POST | `/messages/conversations.php`, `/directory.php`, `/send.php`, `/thread.php` | `user_id`, `body`, `thread_id` |
| GET/POST | `/community/list.php`, `/post.php`, `/like.php`, `/comments.php` | `post_id`, `body` |
| GET/POST | `/marketplace/list.php`, `/create.php`, `/interest.php` | `title`, `price`, `city`, `category` |
| GET/POST | `/decisions/list.php`, `/create.php`, `/vote.php` | `title`, `body`, `choice` |
| GET | `/documents/list.php` | `documents[]` |
| GET/POST | `/user/notifications.php` | `notifications[]`, `unread_count`; POST marks read |

### 3.6 Hotel management (`hotel_management` / `hotel_employee`)

| Method | Path | Request keys | Response keys read |
|---|---|---|---|
| GET | `/hotel/dashboard.php` | — | `stats{}`, `arrivals[]`, `departures[]` |
| GET | `/hotel/bookings.php` | `from`, `to`, `status`, `q` | `bookings[]` (incl. `unit_number`, guest name/phone) |
| GET/POST | `/hotel/prices.php` | `service`, `price`, `title`, `date_from`, `date_to` | `prices[]` |
| GET/POST | `/hotel/unit-pricing.php` | `title`, `date_from`, `date_to`, `rows[{unit_type,price}]` | rows |
| GET/POST | `/hotel/meal-pricing.php` | `title`, `date_from`, `date_to`, `breakfast`, `lunch`, `dinner` | prices |
| GET | `/hotel/requests.php` | `type` (`cleaning` \| `meal` \| `maintenance` \| `extra_bed`) | `requests[]` incl. `approved_price`, `requester_phone`, `unit_name_ar/en` |
| POST | `/hotel/requests.php` | `type`, `id`, `action` (`confirm`/`done`/`reject`/`preparing`/`delivered`), `note`, `price`, `settlement`, multipart `image` | `payment_link` \| `payment_url` \| `checkout_url` \| `invoice_url` |

`settlement` values the app sends:

| Value | Meaning | Server must |
|---|---|---|
| `deduct_balance` | deduct the approved price from the unit/owner balance | deduct **once** (idempotent on request id), reject if balance is insufficient, return the new balance |
| `whatsapp_link` | send the guest a payment link over WhatsApp | create a **server-side** payment intent and return its URL in one of the four keys above |

**Idempotency is mandatory:** confirming the same request twice must not deduct
twice. The client already blocks the button in-session, but that is not
authoritative — the server must enforce it (unique index on
`(request_type, request_id, settlement)` or a `settled_at` column).

### 3.7 Owner, booking agent, subscription, wallet

| Method | Path | Notes |
|---|---|---|
| GET | `/user/owner-dashboard.php` | `stats{}`, wallet balance, revenue summary |
| GET/POST | `/user/owner-units.php` | `hotel_id`, `unit_number`, `type`, `price`, `capacity`, `status` |
| GET/POST | `/user/owner-bookings.php` | bookings of the owner's units |
| GET/POST | `/user/owner-staff.php` | `name`, `phone`, `role`, `hotel_id` — permissions per employee |
| GET/POST | `/user/owner-wallet.php` | `balance`, `transactions[]` |
| GET | `/user/owner-revenue.php` | per-period revenue |
| GET/POST | `/user/owner-bank.php` | `iban`, `account_name`, `bank_name` |
| GET/POST | `/user/owner-maintenance.php` | maintenance requests |
| GET/POST | `/user/owner-meals.php` | meal requests |
| POST | `/user/owner-requests.php` | owner-side service requests |
| GET/POST | `/user/agent-clients.php` | agent's clients, `client_id` |
| GET | `/user/agent-commission.php` | `total`, `pending`, `paid`, `entries[]` |
| POST | `/user/agent-commission.php` | `action=request_transfer` + `amount` (request only, see 3.8) |
| POST | `/user/owner-staff.php` | `action=set_permissions` + `id` + `permissions{}` (see 3.8) |

### 3.8 Contracts added by Document 06 group 01 (Flutter side already shipped)

Both calls are already implemented and tested in the app. They fail loudly
until PHP handles them; the app never fakes success.

**(a) Staff permissions — requirement 74**

```http
POST /user/owner-staff.php
Content-Type: application/json

{
  "action": "set_permissions",
  "id": 12,
  "permissions": {
    "can_manage_bookings": true,
    "can_manage_services": true,
    "can_check_in_out": false,
    "can_view_finance": false
  }
}
```

* The app always sends all four keys (no partial diffs) so PHP can treat the
  body as the full authoritative state.
* `GET /user/owner-staff.php` should return `permissions` per employee, either
  as that same object or as a list of enabled key names. When the field is
  absent the app falls back to role defaults, so an old response cannot lock
  anyone out.
* Server must reject `can_view_finance=true` for an owner without an active
  subscription, and must enforce each permission on every endpoint — the app
  hides UI, PHP must refuse the request.

**(b) Commission transfer request — requirement 108**

```http
POST /user/agent-commission.php
Content-Type: application/json

{ "action": "request_transfer", "amount": 200 }
```

* `amount` is exactly the `unpaid` value the server itself returned moments
  earlier; the client never computes or edits it.
* Expected reply on success: `{"success": true, "message": "..."}`. Any
  `message` is displayed verbatim. A non-2xx or `success: false` is shown as an
  error and the sheet stays open.
* No money moves from the app: the transfer, its ledger entries, and its status
  machine belong to PHP. Idempotency (one pending request per agent per period)
  must be enforced server-side.

---

## 4. Reconciliation checklist for the cPanel phase (Codex)

Each row is a fact the client already depends on. Tick when PHP matches; a
mismatch is a client-visible bug, not a cosmetic one.

| # | Contract | Flutter expectation | Confirm in PHP |
|---|---|---|---|
| C1 | `bookings/create.php` payload keys | exactly the §3.3 keys, snake_case | ☐ |
| C2 | `extra_bed_qty` default 1 | charge = qty × price × nights | ☐ |
| C3 | `booking.unit_number` | real unit number, not the reference | ☐ |
| C4 | `payment_method` allow-list | server rejects disabled methods (HTTP 4xx + `success:false`) | ☐ |
| C5 | Double-booking | atomic rejection, no check-then-insert race | ☐ |
| C6 | `content/settings.php` shape | `payment_methods{}` (or list, or `payment_*_enabled`) | ☐ |
| C7 | Default payment state | `cash` and `bank_transfer` **disabled** until an admin enables them | ☐ |
| C8 | Admin toggles | per-method enable/disable, admin-only, audited | ☐ |
| C9 | `hotel/requests.php` `settlement` | accepts `deduct_balance` / `whatsapp_link` | ☐ |
| C10 | Settlement idempotency | one deduction per request id | ☐ |
| C11 | `payment_link` response | absolute `https` URL, server-generated only | ☐ |
| C12 | `hotel/bookings.php` | accepts `q` for unit/room number (departures search) | ☐ |
| C13 | `hotel/dashboard.php` | returns `arrivals[]` and `departures[]` | ☐ |
| C14 | `units/detail.php` addons | `category` ∈ `meal_plan` \| `extra_bed` \| other, plus `price` and `price_unit` | ☐ |
| C15 | `user/device-token.php` | stores FCM token per user/device | ☐ |
| C16 | Role names | `customer`, `owner`, `owner_employee`, `hotel_management`, `hotel_employee`, `booking_agent`, `admin` | ☐ |
| C17 | `bookings/my.php` | returns `can_check_in` / `can_check_out` booleans | ☐ |

---

## 5. What this document does **not** claim

- It does not claim any PHP endpoint is implemented. Everything above is the
  *client's* contract, verified against the shipping Dart code and its tests.
- It does not claim the admin payment toggles exist. Requirement 8 stays
  `FLUTTER COMPLETE — BACKEND PENDING` until a PHP implementation is tested.
- It does not authorise enabling real online payments. The app refuses to send
  card data at all; hosted checkout links must be issued by the server.

---

## 6. Reproduce this inventory

```bash
python3 - <<'PY'
import re, pathlib
eps = {}
for p in pathlib.Path('lib').rglob('*.dart'):
    for m in re.finditer(r"_(?:dio|client)\.(get|post|put|delete)\(\s*'([^']+)'",
                         p.read_text(encoding='utf-8')):
        eps.setdefault(m.group(2), set()).add(m.group(1))
for k in sorted(eps):
    print(sorted(eps[k]), k)
print('total', len(eps))
PY
```
