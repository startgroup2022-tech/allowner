# All Owners — Payment Security Assessment (Priority 0)

**Branch:** `feature/allowners-new-version-exec01`
**Commit that fixed the client side:** `79dd97e`
**Status:** client-side PCI exposure **removed**; server-side and commercial work **blocked on owner**.

---

## 1. What was wrong

The booking screen collected four card fields and posted the raw PAN to the application's own
API:

```
booking_screen.dart
  _cardNumberController / _expiryController / _cvvController / _cardNameController
        │
        ▼
  HotelService.createBooking(..., cardNumber: _cardNumberController.text...)
        │
        ▼
  buildBookingPayload(...) → { 'card_number': '4111...', ... }
        │
        ▼
  POST https://all-owner.online/api/bookings/create.php   ← our server receives a PAN
```

Three distinct problems, in order of severity:

1. **Our own server received a full card number (a PAN).** Any system that stores, processes
   or transmits a PAN is in PCI-DSS scope. The All Owners server is a hand-written PHP
   application with a shared session cookie — it is not a hardened cardholder-data
   environment, and nothing in the requirements asks it to become one.
2. **The PAN travelled in a JSON body over a hand-built API** with `access-control-allow-origin: *`
   set (see the backend discovery doc). There is no evidence the server encrypts, truncates
   or discards the field; there is no evidence it keeps it either. The point is the client
   was **sending** it, which is the part we control.
3. **Expiry and CVV were captured by the UI** but never sent, so the screen implied a real
   card charge that the backend never performed. That is the "invented success" failure mode
   the mandate forbids.

## 2. What was changed (client side, complete)

| Change | File |
|---|---|
| `cardNumber` parameter and the `card_number` field deleted from the payload builder | `lib/utils/booking_payload.dart` |
| New payment-security module: hosted-checkout config, Luhn check, leak guard | `lib/utils/payment_security.dart` |
| `createBooking` no longer accepts card data and **refuses to send** any payload that carries a forbidden key or a Luhn-valid number | `lib/services/hotel_service.dart` |
| All four card `TextField`s removed from the UI | `lib/screens/booking/booking_screen.dart` |
| Online payment becomes a hosted-checkout redirect carrying only the booking reference | `lib/screens/booking/booking_screen.dart` |
| Card-entry strings removed; honest Arabic/English notices added | `lib/utils/app_strings.dart` |
| 7 tests pinning all of the above | `test/widgets_test.dart` |

### 2.1 The new flow

```
guest taps "Pay online now"
        │
        ▼
resolveHostedCheckout(content/settings.php)   ── no payment_checkout_url? ──▶ show
        │                                                                     "not enabled"
        ▼  (URL present, https, absolute)
POST bookings/create.php  with payment_method='online'   ← NO card data, ever
        │
        ▼
server returns booking_ref
        │
        ▼
open <checkout_url>?ref=<booking_ref>  in the system browser
        │
        ▼
the LICENSED PROVIDER collects the card on its own page; our server never sees it
```

Two deliberate decisions inside that flow:

- **The amount is not passed by the client.** `buildCheckoutUri` sends only `ref`. A client
  that can set its own price can pay 1 SAR for a 2,000 SAR stay. The provider must read the
  amount from our server, keyed by the booking reference.
- **`isUsable` requires `https` and an absolute URL.** A relative or `http` value is treated
  as "not configured", so a mis-set config cannot silently downgrade the checkout.

### 2.2 The guard is a real guard, not a comment

`HotelService.createBooking` runs `findPaymentDataLeaks(payload)` before every send. It
catches both an obvious `card_number` key **and** a Luhn-valid 12–19-digit number hiding under
an innocent key such as `notes`. If it fires, the request is not sent and an `ApiException`
is raised. A future contributor cannot re-introduce card data by accident without a test
turning red.

## 3. What is **not** done, and who has to do it

### 3.1 Server side (owner / backend developer)

Nothing in this repository can implement these:

- A `bookings/create.php` that stores a payment **state** (`pending`, `paid`, `failed`,
  `refunded`) and **no card field**.
- A provider webhook endpoint that verifies the provider's signature and flips the state.
- A `payment_checkout_url` (and optional `payment_provider`) key in `content/settings.php`.
- Removal of any `card_number` handling already present server-side.

### 3.2 Commercial (owner)

- **Choose and contract a licensed provider.** For a Saudi platform: Moyasar, HyperPay,
  PayTabs or Tap are the usual licensed options. The app is provider-agnostic — it reads a
  URL, it does not embed an SDK — so the choice is the owner's and can change without an app
  release.
- **Supply hosted-checkout credentials for staging first.**
- **Decide the two payment models.** `owner_transfer` (guest pays the owner directly) and
  `agent-commission` (platform collects and takes a cut) still contradict each other. Until
  that is resolved, `owner_transfer` stays as-is and its commission effect is undefined.

## 4. Do not do this

- Do not add a card field back "just for testing". The guard will refuse to send it and the
  test suite will fail — that is intentional.
- Do not let the client pass `amount` to the checkout URL.
- Do not switch to `payment_checkout_url` in production before staging has been exercised
  end-to-end.
- Do not claim a payment works until a **real** provider sandbox transaction is observed and
  recorded here.

## 5. Evidence

| Command | Result |
|---|---|
| `grep -rn "card_number\|cvv\|expiry" lib/` | only `payment_security.dart` (the forbidden-key list) and doc comments — no field is ever built |
| `flutter test` | 200 pass, including the 7 payment-security tests |
| `flutter analyze` | 0 errors, 0 warnings |

The corresponding fix commit is `79dd97e`.
