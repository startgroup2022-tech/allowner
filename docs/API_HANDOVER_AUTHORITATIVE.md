# All Owners — Authoritative API handover (generated from the Dart source)

**Branch:** `feature/allowners-new-version-exec01`
**Status:** this file is the single source of truth for the PHP work. It is
derived from the actual client calls (`grep` over `lib/`), not from earlier
prose. Where an older document disagrees, **this file wins**, and §6 lists every
conflict that was resolved.

**How to regenerate the endpoint inventory**

```bash
grep -rhoE "'/(auth|user|units|hotels|bookings|categories|cities|content|services|hotel|notifications|messages|favorites)[a-zA-Z0-9_./-]*'" lib/ \
  | sort | uniq -c | sort -rn
```

Base URL comes from `lib/services/api_client.dart` (a single Dio instance).
Every request is `POST` with a JSON body unless the table says `GET`.
Response convention used by the client: a JSON object; `success` is read when
present, but the client also accepts payloads without it (older endpoints).

---

## 1. Endpoints the client calls today (58)

### 1.1 Auth and profile

| Endpoint | Method | Body / query | Read fields |
|---|---|---|---|
| `/auth/login.php` | POST | `email`, `password` | `user{id,name,email,phone,role,avatar_url}`, `token` |
| `/auth/register.php` | POST | `full_name`, `email`, `phone`, `password`, `role` | same as login |
| `/auth/logout.php` | POST | — | `success` |
| `/auth/me.php` | GET | — | `user{…}` |
| `/auth/forgot-password.php` | POST | `email` | `success`, `message` |
| `/user/update-profile.php` | POST | `full_name`, `phone?`, `current_password?`, `new_password?` | `user{…}` |
| `/user/avatar.php` | POST (multipart) | `avatar` file, or `remove=1` | `user{…}`, `avatar_url` |
| `/user/device-token.php` | POST | `token`, `platform`, `locale`; or `token` + `action=unregister` | `success` |

### 1.2 Discovery

| Endpoint | Method | Query / body | Read fields |
|---|---|---|---|
| `/categories/list.php` | GET | — | `categories[]{id,name_ar,name_en,icon_key,count}` |
| `/cities/list.php` | GET | — | `cities[]{id,name_ar,name_en,image_url}` |
| `/units/browse.php` | GET | `q?`, `city?`, `category_id?`, `type?`, `sort?`, `owner_only?`, `page?` | `units[]{…}`, `total` |
| `/units/list.php` | GET | `hotel_id` | `units[]{id,unit_number,name_ar,name_en,price,images,availability,owner_bank}` |
| `/units/detail.php` | GET | `id` | `unit{…,owner_bank}`, `hotel{…}`, `availability[]` |
| `/units/addons.php` | GET | `hotel_id`, `unit_id?` | `addons[]{id,name,price,price_unit,category}` |
| `/hotels/list.php` | GET | `q?`, `city?`, `page?` | `hotels[]{id,name_ar,name_en,city,rating,units_count,image_url}` |
| `/hotels/detail.php` | GET | `id` | `hotel{id,name_ar,name_en,city,address,description,images,rating,amenities,owner_bank,extra_bed_price}` |
| `/content/settings.php` | GET | — | see §3 (settings contract) |
| `/content/get.php` | GET | `key` | `value` |
| `/favorites/my.php` | GET | — | `favorites[]{unit_id,…}` |
| `/favorites/toggle.php` | POST | `unit_id` | `favorited` |

### 1.3 Booking (Document 06 core)

| Endpoint | Method | Body | Read fields |
|---|---|---|---|
| `/bookings/create.php` | POST | `hotel_id`, `unit_id?`, `check_in`, `check_out`, `guests`, `payment_method`, `meal_types[]`, `extra_bed`, `extra_bed_qty?`, `addon_ids[]?`, `guest_id_number`, `customer_name?`, `customer_phone?` | `booking{id,booking_ref,unit_number,status,total,payment_method}`, `success`, `message` |
| `/bookings/my.php` | GET | — | `bookings[]{id,booking_ref,unit_number,hotel,check_in,check_out,status,total,can_edit,can_cancel,payment_method}` |
| `/bookings/manage.php` | POST | `action=update\|cancel`, `booking_id`, plus edited fields (`check_in`,`check_out`,`guests`,`guest_name`,`guest_phone`,`notes`) | `success`, `message`, `booking{…}` |

`payment_method` values sent by the app: `online`, `at_hotel`,
`owner_transfer`. Nothing else is ever sent.

### 1.4 Guest services, messaging, notifications

| Endpoint | Method | Body | Read fields |
|---|---|---|---|
| `/services/request.php` | POST | `type` (`maintenance`\|`cleaning`\|`extra_bed`), `unit_id?`, `hotel_id?`, `description`, `preferred_date?` | `request{id,status}` |
| `/services/meal-request.php` | POST | `hotel_id`, `unit_id?`, `meal_type`, `guests`, `date` | `request{id,status}` |
| `/services/my-requests.php` | GET | — | `requests[]{id,type,status,room_number,created_at}` — **مطلوب من السيرفر، غير منفّذ بعد (404)**؛ التطبيق يعرض ما حُفظ محليًا من استجابات الإرسال ويقول ذلك صراحة |
|  `/user/notifications.php` | GET | — | `notifications[]{id,title,body,type,created_at,read}` |
| `/messages/conversations.php` | GET | — | `conversations[]{id,peer_name,last_message,unread}` |
| `/messages/directory.php` | GET | — | `users[]{id,name,role}` |
| `/messages/thread.php` | GET | `conversation_id` | `messages[]{id,sender_id,body,created_at}` |
| `/messages/send.php` | POST | `conversation_id?` or `peer_id`, `body` | `message{…}` |

### 1.5 Hotel management (`hotel_employee`, `hotel_manager`)

| Endpoint | Method | Query / body | Read fields |
|---|---|---|---|
| `/hotel/dashboard.php` | GET | — | counters: `arrivals_today`, `departures_today`, `in_house`, `open_requests` |
| `/hotel/bookings.php` | GET | `scope=active\|arrivals\|departures` | `bookings[]{id,booking_ref,guest_name,guest_phone,unit_number,check_in,check_out,status,total,payment_method}` |
| `/hotel/bookings.php` | POST | `action=check_in\|check_out`, `booking_id` | `success`, `message` |
| `/hotel/requests.php` | GET | `type?`, `status?` | `requests[]{id,type,status,description,unit_id,unit_number,price,approved_price,settlement,settlement_status,created_at}` |
| `/hotel/requests.php` | POST | `action=confirm`, `request_id`, `price?`, `settlement?` | `success`, `message`, `payment_link?` |
| `/hotel/prices.php` | GET/POST | read all prices; write `action=save` + price rows | `prices{…}` |
| `/hotel/unit-pricing.php` | GET/POST | `unit_id`, price fields | `prices{…}` |
| `/hotel/meal-pricing.php` | GET/POST | meal price rows | `prices{…}` |

### 1.6 Owner, booking agent, subscription, wallet

| Endpoint | Method | Body | Read fields |
|---|---|---|---|
| `/user/owner-dashboard.php` | GET | — | counters, `subscription` |
| `/user/owner-units.php` | GET/POST | `action=create\|update\|delete\|toggle_status`, `id?`, unit fields | `units[]{…}` |
| `/user/owner-bookings.php` | GET/POST | read; `action=confirm\|cancel\|update`, `booking_id` | `bookings[]{…,source,agent_name}`, `success`, `message` |
| `/user/owner-staff.php` | GET/POST | read; `action=create\|update\|delete\|toggle_status\|set_permissions`, `id`, `permissions{can_manage_bookings,can_manage_services,can_check_in_out,can_view_finance}` | `staff[]{…,permissions}`, `success`, `message` |
| `/user/owner-requests.php` | GET | `type?` | `requests[]{…}` |
| `/user/owner-maintenance.php` | GET/POST | maintenance records | `requests[]{…}` |
| `/user/owner-meals.php` | GET | — | `meals[]{…}` |
| `/user/owner-revenue.php` | GET | — | `total`, `monthly[]{month\|ym,total,maintenance_expense?,cleaning_expense?,commission?}`, optional `net` |
| `/user/owner-bank.php` | GET/POST | bank fields | `bank{holder_name,bank_name,iban,account_number}` |
| `/user/owner-wallet.php` | GET/POST | read; `action=request_transfer`, `amount`, `iban?`, `note?` | `wallet{balance,commission,expenses,reserved,available}`, `ledger[]` |
| `/user/agent-clients.php` | GET/POST | `action=create\|update\|delete`, client fields | `clients[]{…}` |
| `/user/agent-commission.php` | GET/POST | read; `action=request_transfer`, `amount` | `commission{earned,paid,unpaid}`, `success`, `message` |
| `/user/site-settings.php` | **not called** | — | see §6.1 |

---

## 2. Field-level contracts that matter

### 2.1 Booking creation

* `check_in` / `check_out` are `YYYY-MM-DD`, no time (Document 05 reqs 146–148).
* The client reads the created booking from the **top-level `booking` object**
  (`lib/services/hotel_service.dart`), not from `data.booking`. `unit_number` is
  read as a string and may be absent (see §2.1).
* `guest_id_number` is **always** sent, empty string when the guest left it blank.
* `unit_id` is omitted for hotel-level bookings; the server derives unit type and
  room number from it when present.
* `extra_bed_qty` is only sent when `extra_bed` is true.
* Response must include `booking.unit_number` — the confirmation screen shows the
  real unit number (Document 06 req 4). When the server does not send it, the app
  shows "not available"; it never substitutes the booking reference.

### 2.2 Booking management

* `bookings/my.php` must return `can_edit` / `can_cancel` booleans per booking;
  the app hides the actions otherwise.
* `manage.php` rejects unknown `action` values; the app only sends `update` and
  `cancel`.

### 2.3 Hotel requests (Document 06 reqs 9–12)

```json
POST /hotel/requests.php
{ "action": "confirm", "request_id": 88, "price": 120, "settlement": "wallet_balance" }
```

* `settlement` accepts `unit_balance` (maintenance path) and `wallet_balance` /
  `whatsapp_link` (cleaning, meal, extra bed path). See §6.6 for why both names
  exist.
* The server must reject a second `confirm` for an already settled request
  (idempotency): the app disables the button, but PHP is the enforcement point.
* For `whatsapp_link` the server may return `payment_link`; the app opens it only
  when it is an `https://` URL, and otherwise falls back to a `wa.me` message that
  contains the request id, unit and amount. The app never fabricates a link.

### 2.4 Push device tokens

```json
POST /user/device-token.php
{ "token": "<registration id>", "platform": "android|ios", "locale": "ar|en" }

POST /user/device-token.php
{ "token": "<registration id>", "action": "unregister" }
```

* One row per `(user_id, token)`; a token that logs into another account must be
  reassigned, not duplicated.
* `unregister` must be idempotent and must return 200 for an unknown token.
* `firebase_messaging` 17 provides a **Firebase Installation ID** via
  `register()` / `onRegistered`; that value is the direct-send target. Treat it
  as the FCM `token` in the HTTP v1 API.
* FCM data payload keys the client understands: `type`
  (`booking`|`service_request`|`payment`|`wallet`|`subscription`), optional
  `target` (`booking`|`service`|`service_request`|`wallet`|`subscription`|`payment`),
  `message_id` (dedupe), `booking_id`, `request_id`.

---

## 3. Settings contract (`/content/settings.php`)

All keys are optional; a missing key keeps the client default (never enables
something).

```json
{
  "success": true,
  "logo_url": "https://…/logo.png",
  "tagline_ar": "…", "tagline_en": "…",
  "app_description_ar": "…", "app_description_en": "…",
  "contact_email": "…", "contact_phone": "…", "contact_whatsapp": "…",
  "subscription_active": false,
  "subscription_fee": 500,
  "commission_percent": 10,
  "payment_checkout_url": "https://…",
  "payment_methods": {
    "online": false,
    "at_hotel": false,
    "owner_transfer": false
  },
  "payment_online_enabled": false,
  "payment_at_hotel_enabled": false,
  "payment_owner_transfer_enabled": false
}
```

Rules enforced by the client (`lib/utils/payment_methods_config.dart`):

1. `payment_methods{}` is read first; the flat `payment_*_enabled` keys are the
   fallback.
2. Absent means **disabled**. Both `at_hotel` and `owner_transfer` therefore
   default to off (Document 06 req 7).
3. `online` is only offered when `payment_checkout_url` is an `https://` URL;
   the app redirects to that hosted page and never collects card data.
4. The server must reject a booking whose `payment_method` is disabled, even if
   the request comes from a script (Document 06 req 8). Hiding the row is not
   enforcement.

---

## 4. Server-side enforcement the app depends on

| Area | Server must enforce | Why the client cannot |
|---|---|---|
| Payment method availability | reject `payment_method` not enabled in settings | a modified client can post anything |
| Staff permissions | each `can_*` flag on every endpoint | the app only hides UI |
| Subscription gate | refuse unit/request creation without an active subscription | the app has a soft, non-destructive gate |
| Hotel scoping | `hotel/bookings.php` and `hotel/requests.php` limited to the employee's hotel | the app filters nothing on the server's behalf |
| Departures search | `unit_number` filter scoped to the authorized hotel | the client sends the filter only |
| Settlement idempotency | one settlement per request | duplicate taps are possible |
| Commission transfer | one pending request per agent per period | the app sends the server's own amount |

---

## 5. Error handling contract

* Any non-2xx is shown as an error; no screen ever renders success without a
  server `success: true`.
* `401` means "session expired" and the app signs out.
* `404` on an optional endpoint (wallet, reset password, device token) is shown as
  "not enabled on the server" — never as an empty success.
* Error bodies are read as `{success:false, message}` when present; `message` is
  displayed verbatim.

---

## 6. Conflicts resolved (this round)

### 6.1 `content/settings.php` vs `user/site-settings.php`

**The app calls `content/settings.php` only.** No Dart file references
`user/site-settings.php`. If Codex is building `user/site-settings.php`, it must
either (a) be an authenticated alias that returns the same payload, or (b) be
dropped. Adding a second source of truth for payment flags would let the two
disagree, which is exactly the failure mode Document 06 req 7–8 forbids.

### 6.2 `bookings/create.php` vs "alternative booking actions"

**The app calls `POST /bookings/create.php` with no `action` field.** Alternative
names (`bookings/store.php`, `action=create` on `bookings/index.php`) are not
called and must not be introduced without a client change.

### 6.3 `hotel/bookings.php` vs `user/hotel-management.php`

**The app calls `/hotel/bookings.php` (GET `scope`, POST `action`) and
`/hotel/requests.php`.** `user/hotel-management.php` is not called. The hotel
namespace is the one to implement.

### 6.4 `cash` vs `pay_on_arrival`

**The wire value is `at_hotel`.** `cash` appears nowhere in `lib/`. The settings
flag is `payment_at_hotel_enabled` / `payment_methods.at_hotel`. If PHP already
uses `cash` internally, it must map it to `at_hotel` at the API boundary.

### 6.5 `bank_transfer` vs `bank_transfer_owner`

**The wire value is `owner_transfer`.** The settings flag is
`payment_owner_transfer_enabled` / `payment_methods.owner_transfer`. The bank
details themselves come from `/user/owner-bank.php` and `owner_bank` inside
`units/detail.php` and `hotels/detail.php`.

### 6.6 `settlement=deduct_balance` vs `payment_method=balance`

Two different fields, two different flows — they are not synonyms:

| Flow | Field | Values |
|---|---|---|
| Booking payment | `payment_method` on `/bookings/create.php` | `online`, `at_hotel`, `owner_transfer` |
| Service-request settlement | `settlement` on `/hotel/requests.php` | `unit_balance`, `wallet_balance`, `whatsapp_link` |

`balance` alone is never sent. `unit_balance` is the maintenance path (existing
behaviour, Document 06 req 11); `wallet_balance` is the housekeeping/meal/extra
bed path (Document 06 req 10). The server should accept both and treat them as
the same ledger operation, keeping the request type as the discriminator.

---

## 7. What this document does not claim

* It does not claim any of these endpoints exist or are correct on the server.
  The client behaviour is verified by tests; the server behaviour is not.
* It does not authorise a rename of an existing PHP endpoint. Any rename is a
  breaking change that needs a client release.
