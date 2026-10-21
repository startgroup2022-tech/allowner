# All Owners — Backend Discovery & Access Request

**Branch:** `feature/allowners-new-version-exec01`
**Date:** 2026-10-20
**Probed:** read-only GET/POST-with-empty-body requests; no writes, no account creation
**Verdict:** the backend is **live and fully discoverable**, but its **source code is not in
this repository and not obtainable from the client side**. Access must be granted by the owner.

---

## 1. What was discovered (all verified live, no assumptions)

### 1.1 The backend is real, running, and answering

```
$ curl -sI https://all-owner.online/api/cities/list.php
HTTP/2 200
x-powered-by: PHP/8.2.34
server: LiteSpeed
content-type: application/json; charset=utf-8
access-control-allow-origin: *
access-control-allow-methods: GET, POST, PUT, DELETE, OPTIONS
access-control-allow-headers: Content-Type, Authorization
set-cookie: allowners_session=...; path=/; secure
```

- **Runtime:** PHP **8.2.34** on **LiteSpeed**.
- **Session model:** a native PHP session cookie (`allowners_session`, `secure`), in addition
  to the `Authorization: Bearer <token>` header the Flutter client sends.
- **API style:** hand-written PHP scripts, one file per endpoint, no framework, no
  `composer.json` (returns 404).

### 1.2 The host IP and the surrounding surfaces

| Host / path | Result | Meaning |
|---|---|---|
| `all-owner.online` → `157.90.130.252` | live | Hetzner range; single server |
| `/` | 200, Arabic RTL site («أول أونرز») | public website exists |
| `/api/` | **200 — directory listing enabled** | full endpoint surface exposed |
| `/admin/` | 302 → `/admin/login.php` | **separate admin dashboard exists** |
| `/admin/login.php` | 200, `<title>تسجيل دخول الأدمن</title>`, CSRF token | admin panel is real |
| `/hotels.php?type=Hotels|Apartments|Resorts|Chalets` | 200 | website filters by type |
| `/unit.php?id=N` | 200 | website unit pages exist |
| `/register.php?role=owner` | 200 | website registration by role |
| `/api/bootstrap.php` | 200, empty body | shared bootstrap (config/DB/auth) |

### 1.3 The complete API surface (from the directory index)

The server exposes its own file tree, so this list is **complete, not guessed**:

```
/api/bootstrap.php
/api/auth/       login.php logout.php me.php register.php
/api/bookings/   create.php manage.php my.php
/api/categories/ list.php
/api/cities/     list.php
/api/community/  comments.php like.php list.php post.php
/api/content/    get.php settings.php
/api/decisions/  create.php list.php vote.php
/api/documents/  list.php
/api/favorites/  my.php toggle.php
/api/hotel/      bookings.php dashboard.php prices.php requests.php
/api/hotels/     detail.php list.php
/api/marketplace/create.php interest.php list.php
/api/messages/   conversations.php directory.php send.php thread.php
/api/services/   meal-request.php request.php
/api/units/      addons.php browse.php detail.php list.php
/api/user/       agent-clients.php agent-commission.php avatar.php
                 hotel-prices.php notifications.php owner-bank.php
                 owner-bookings.php owner-dashboard.php owner-maintenance.php
                 owner-meals.php owner-requests.php owner-revenue.php
                 owner-staff.php owner-units.php update-profile.php update.php
```

**Two endpoints exist that the client does not call:**

- `POST /user/update.php` — a second profile-update path, distinct from
  `update-profile.php`. Which one is canonical is unknown.
- `GET /user/hotel-prices.php` — a *user-scoped* price endpoint. The client calls the
  `hotel/*` variants. This may be the endpoint requirement 68 actually needs.

This is the one concrete win from discovery: two candidate endpoints for open
requirements were found without any owner action.

---

## 2. What was **not** discovered, and why

The source code is not reachable:

- `find . -name "*.php"` in this repository → **0 files**. `git log --all` over every ref
  contains no `.php` and no `.sql` ever.
- `https://github.com/startgroup2022-tech/allowner` is the **Flutter client only**; the org's
  other 11 repositories are unrelated projects.
- `/api/.htaccess` → 403 (present, not readable). `config.php`, `db.php`, `includes/`,
  `composer.json`, `README.md` → all 404 (not web-served, correctly).
- `robots.txt`, `sitemap.xml` → 404.

So the PHP, the MariaDB schema, the migrations, the admin panel source and the website
source are **all on the server and nowhere else**. No amount of client-side probing can
produce them, and attempting to (parameter fuzzing, path traversal, force-browsing) would be
attacking a production system we do not own. It was not attempted.

---

## 3. The access request (copy/paste for the owner)

To complete Priority 2 (the 42 backend-blocked requirements) we need exactly this:

### 3.1 Source code

1. **PHP API source** — the contents of `/api/` on `all-owner.online` (or a Git repository).
2. **Website source** — the document root (`index.php`, `hotels.php`, `unit.php`,
   `register.php`, `login.php`, …).
3. **Admin panel source** — `/admin/`.
4. **Database schema** — a `mysqldump --no-data` of the MariaDB/MySQL database, **or** the
   `CREATE TABLE` migrations. Do **not** send production row data.

### 3.2 A non-production environment

5. **A staging copy** — same PHP version (8.2), same schema, **anonymised data**. Required
   for Priority 3 integration testing; testing the 50 unverified items against production is
   not acceptable.
6. **Test accounts**, one per role, on staging:
   - `guest`, `unit_owner`, `hotel_management`, `booking_agent`, and `admin` if the mobile
     app is meant to serve it.
7. **A database read/write credential for staging only.**

### 3.3 Deployment facts

8. **How the API is deployed** (Git pull? FTP? cPanel file manager?) so changes can be
   shipped without touching production directly.
9. **Where the mobile app's `Authorization: Bearer` token is minted and verified**, and
   whether `auth/me.php` is the sole token validator.
10. **CORS intent** — `access-control-allow-origin: *` is currently set on an authenticated
    API. Whether that is deliberate.

### 3.4 Payment

11. **A licensed payment provider account** (Moyasar / HyperPay / PayTabs / Tap — all are
    Saudi-licensed) and its **hosted-checkout** credentials, **for staging first**.
    See `docs/PAYMENT_SECURITY_ASSESSMENT.md` for what the client now expects.

**Until items 1–3 arrive, Priority 2 cannot be started**, and any claim that it was would be
false.

---

## 4. What the client does while it waits

The 42 backend-blocked items are **not** stubbed. Where the client can defend itself it does
(see the payment work in this pass). Where it cannot, the screen shows an honest state. The
per-item record is `docs/ALL_OWNERS_REQUIREMENTS_MATRIX.md`.

Two new defects were found by this discovery pass and are recorded rather than hidden:

- **`/api/` directory listing is publicly enabled.** It leaks the full internal endpoint
  layout. Server-config fix, not client.
- **`access-control-allow-origin: *` on an authenticated API** lets any website issue
  credentialed calls. Server-config fix.

Both belong in the access request as findings, and both are the owner's call.
