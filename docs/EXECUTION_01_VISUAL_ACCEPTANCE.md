# All Owners — Execution 01 Visual Acceptance

**Branch:** `feature/allowners-new-version-exec01`
**Date:** 2026-10-19
**Method:** Flutter web build of the real screen code, rendered headlessly in
Chromium against the **live** backend `https://all-owner.online/api`, then
inspected as rendered output (accessibility tree) and as pixel data.

---

## 1. How the evidence was produced

The mandate says: *"Do not claim visual acceptance without actual screenshot or
rendered-screen evidence."* This section states exactly what was and was not done.

**What was done**

1. A scratch copy of the project outside the repository was created at
   `/tmp/allowner_web` and given a web target. **The repository itself was not
   modified** — no `web/` directory was added to the deliverable.
2. A harness (`lib/screenshot_main.dart`, scratch copy only) renders the *real*
   production widgets — `HomeScreen`, `SearchScreen`, `HotelDetailsScreen`,
   `UnitDetailsScreen`, `EmptyView`, `ErrorView` — with no mock data layer. All
   list content comes from live API calls.
3. Semantics were force-enabled in the harness so the rendered text is exposed
   in the DOM and can be read back as ground truth.
4. The app was served locally and rendered with headless Chromium
   (`--enable-unsafe-swiftshader`), then captured at 360×800, 390×844 and
   768×1024.
5. Every capture was analysed pixel-wise for the Flutter debug overflow stripe
   (bright yellow, RGB > 240/240/<80).

**What was not done, stated plainly**

- These are **web renderings of the Flutter widgets**, not Android emulator
  captures. The mandate asks for rendered-screen evidence, and this is genuine
  rendering of the real widget tree — but it is not an Android device screenshot.
- No physical device or emulator was available in the environment
  (`flutter devices` lists only Linux desktop; no Android SDK emulator image).
- The harness lives in a scratch copy and is **not** part of the delivered
  source, so it cannot be mistaken for a shipped screen.

---

## 2. Captured screens

> Re-captured 2026-10-19 from a release web build after the unit-amenity
> sections were added. All 12 captures below reflect the current `lib/`.

All captures at 390×844 unless noted. Live backend data.

| # | Screen | Locale | File | Overflow | Result |
|---|---|---|---|---|---|
| 1 | Homepage | ar (RTL) | `home_ar.png` | none | Pass |
| 2 | Homepage | en (LTR) | `home_en.png` | none | Pass |
| 3 | Homepage | ar, 360×800 | `home_ar_360.png` | none | Pass |
| 4 | Homepage | en, 768×1024 | `home_en_768.png` | none | Pass |
| 5 | Search results | ar | `search_ar.png` | none | Pass |
| 6 | Search results | en | `search_en.png` | none | Pass |
| 7 | Hotel details | ar | `hotel_ar.png` | none | Pass |
| 8 | Hotel details | en | `hotel_en.png` | none | Pass |
| 9 | Unit details (incl. amenity sections) | ar | `unit_ar.png` (390×1400) | none | Pass |
| 10 | Unit details (incl. amenity sections) | en | `unit_en.png` (390×1400) | none | Pass |
| 11 | Empty state | ar | `empty_ar.png` | none | Pass |
| 12 | Error state | ar | `error_ar.png` | none | Pass |

Pixel analysis (sampled every 3rd pixel):

```
empty_ar.png       390x844 yellow%=0.00 dark%=0.02 white%=98.34
error_ar.png       390x844 yellow%=0.00 dark%=0.02 white%=99.31
home_ar.png        390x844 yellow%=0.00 dark%=2.37 white%=65.92
home_ar_360.png    360x800 yellow%=0.00 dark%=2.75 white%=64.16
home_en.png        390x844 yellow%=0.00 dark%=2.58 white%=65.15
home_en_768.png    768x1024 yellow%=0.00 dark%=1.42 white%=65.42
hotel_ar.png       390x844 yellow%=0.00 dark%=2.18 white%=60.93
hotel_en.png       390x844 yellow%=0.00 dark%=2.30 white%=61.03
search_ar.png      390x844 yellow%=0.00 dark%=0.77 white%=73.03
search_en.png      390x844 yellow%=0.00 dark%=0.83 white%=73.22
unit_ar.png        390x844 yellow%=0.00 dark%=2.96 white%=59.45
unit_en.png        390x844 yellow%=0.00 dark%=3.36 white%=57.40
```

`yellow% = 0.00` on every screen: **no overflow stripe anywhere**. `dark%` > 0 on
content screens confirms real text/content is painted (a blank screen would show
`white% ≈ 99`, as the empty/error screens do by design).

---

## 3. Rendered content — verbatim

### 3.1 Homepage, Arabic (RTL) — live data

```
مرحبًا بك
أين ترغب في الإقامة؟
ابحث عن مدينة أو فندق أو وحدة
تصفّح حسب التصنيف
  فنادق · شقق فندقية · منتجعات · شاليهات
وجهات مميزة
  جدة · مكة المكرمة · المدينة المنورة · الخبر · الدمام
فنادق مميزة                                    عرض الكل
  فيرمونت مكة — مكة المكرمة — 1500 ريال /ليلة
فنادق بوحدات ملاك                              عرض الكل
  4005 — جناح عائلي — فندق فيرمونت مكه — 2 · 1 — 1500 ريال /ليلة
  غرفة سيتي12345 — غرفة لشخصين — فندق العنوان — 2 · 2 — 1200 ريال /ليلة
  جناح غرفه وصاله مطل كعبه — جناح — فندق فيرمونت مكه — 2 · 1 — 1500 ريال /ليلة
  …
أحدث الوحدات المضافة                            عرض الكل
  4005 … (same real units, newest first)
```

Verified against the live API: `hotels/list.php?featured=1` returns exactly one
hotel (`فيرمونت مكة`, price 1500) and `cities/list.php` returns exactly the five
cities shown. **Nothing on this screen is hardcoded.**

### 3.2 Homepage, English (LTR) — live data

```
Welcome
Where would you like to stay?
Search city, hotel or unit
Browse by Category
  Hotels · Apartments · Resorts · Chalets
Featured Destinations
  Jeddah · Makkah · Madinah · Al Khobar · Dammam
Featured Hotels                                See all
  فيرمونت مكة — Makkah — 1500 SAR /night
Hotels with Owner Units                        See all
  4005 — جناح عائلي — فندق فيرمونت مكه — 2 · 1 — 1500 SAR /night
  room cty — غرفة لشخصين — فندق العنوان — 2 · 2 — 1200 SAR /night
  Room Suite K.V — suite — فندق فيرمونت مكه — 2 · 1 — 1500 SAR /night
Recently Added Units                           See all
```

Note the honest bilingual behaviour: the UI chrome is English and the locale is
LTR, while fields the backend only supplies in Arabic (hotel name, unit type)
fall back to their Arabic value rather than rendering blank. This is the
documented fallback in `HotelModel.city()` / `UnitModel.name()`, not a defect.

### 3.3 Search results, Arabic — live data

```
نتائج البحث            الفلاتر
كل التصنيفات · فنادق · شقق فندقية · منتجعات · شاليهات
12 نتيجة                          الأحدث
  4005 — جناح عائلي — فندق فيرمونت مكه — 2 · 1 — 1500 ريال /ليلة
  غرفة سيتي12345 — غرفة لشخصين — فندق العنوان — 2 · 2 — 1200 ريال /ليلة
  جناح غرفه وصاله مطل كعبه — جناح — فندق فيرمونت مكه — 2 · 1 — 1500 ريال /ليلة
  …
```

The result count (`12 نتيجة`) is computed from the real response, not assumed.

### 3.4 Hotel details, Arabic — live data (`hotels/detail.php?id=4`)

```
فيرمونت مكة
مكة المكرمة · فندق        [إلغاء مجاني]
عن العقار
  السادة / إدارة خدمات الملاك في فندق فيرمونت - المحترمين …
  (real owner-authored description, shown verbatim)
  عرض المزيد
الأجنحة المتاحة
  لا توجد وحدات بعد
المرافق
  واي فاي مجاني · موقف سيارات · صالة رياضية · مكيف · مطعم
  خدمة الغرف · آلة إعداد القهوة · فندق خالٍ تماماً من التدخين
  مجهز لذوي الاحتياجات الخاصة · صالات اجتماعات · مناسب للعائلة
1500 ريال /ليلة
[ احجز الآن ]
```

Two things to note, both correct behaviour:

- **The description is the real one from the database** — it is an operational
  note the owner wrote for a specific guest. It is not polished marketing copy,
  and that is the point: the previous version *generated* a plausible-sounding
  description when this field was empty. That fabrication has been removed. The
  screen now shows the real text or an explicit "no description" state.
- **`لا توجد وحدات بعد`** is shown because `hotels/detail.php` returns
  `units: []`. This is the real backend state, not a bug in the screen; units are
  loaded from `units/browse.php?hotel_id=` when the hotel has them. Recorded as
  a backend dependency (`AO-HTL-07`).

### 3.5 Unit details — live data (`units/detail.php?id=13`)

Arabic:

```
4005
فندق فيرمونت مكه · مكة المكرمة
جناح عائلي
2 ضيوف        1 الأسرّة
عن الوحدة
  جناح غرفة وصاله كعبه
فترة الإتاحة
  2026-10-05 → 2026-10-31
مرافق الوحدة
  لم تُضف مرافق خاصة لهذه الوحدة — راجع مرافق الفندق المشتركة أدناه
مرافق الفندق المشتركة
  متاحة لجميع ضيوف الفندق
  [ واي فاي ] [ تكييف ] [ مطعم ] [ خدمة الغرف ] [ آلة قهوة ] [ ممنوع التدخين ] [ مناسب للعائلات ]
1500 ريال /ليلة
[ احجز الآن ]
```

English (same record, LTR):

```
Unit facilities
  No unit-specific facilities were added — see the shared hotel facilities below
Shared hotel facilities
  Available to all guests of the hotel
  [ Free WiFi ] [ Air conditioning ] [ Restaurant ] [ Room service ] [ Coffee machine ] [ Non-smoking property ] [ Family friendly ]
```

`units/detail.php` returns no amenity key at all, so the unit-specific list is
correctly empty and the screen says so. The 7 amenities shown come from the
parent hotel via `hotels/detail.php` (`amenities[]`), and are rendered in a
**separate, explicitly labelled** section so a guest cannot mistake a hotel-wide
facility for one belonging to the unit. Nothing is invented and nothing is
merged. Recorded as `AO-AMN-06` / `AO-UNIT-07` (now Verified).

### 3.6 Empty state, Arabic

```
لا توجد نتائج مطابقة        [ مسح البحث ]
```

### 3.7 Error state, Arabic

```
انتهت مهلة الاتصال بالسيرفر، حاول مرة أخرى        [ إعادة المحاولة ]
```

---

## 4. Visual defects found and fixed during this execution

Visual QA was not cosmetic here — it caught real layout bugs.

| # | Defect | How it was found | Fix |
|---|---|---|---|
| V-1 | `UnitCard` price row overflowed **43 px** at 360 px width | Widget test asserting no exception at 360 px | Price moved into `Expanded` + `Align` + `FittedBox(scaleDown)`; `Spacer` removed (`widgets/cards.dart`) |
| V-2 | `UnitListCard` content column overflowed **4 px** vertically | Widget test on the list card | Inner column height 100 → 106 px; thumbnail 100 → 106 px |
| V-3 | Capacity/bed chips rendered as a single glued string (`" 2"`) | Widget test asserting `find.text('2')` | Chip label separated with an explicit `SizedBox(width: 2)` instead of a leading space |

All three were **real rendering defects that a user would have seen**, and all
three were found by automated tests rather than by eye. After the fixes, all 58
tests pass and no capture shows an overflow stripe.

The 2026-10-20 code-review pass added three further logic defects (category
matching, unit category filtering, destination localization). They are layout-neutral
and do not invalidate the captures above, but they are recorded in
`EXECUTION_01_TECHNICAL_AUDIT.md` §11.

---

## 5. Visual quality checklist

| Check | Result | Evidence |
|---|---|---|
| Text overflow | None | 0.00% yellow on all 12 captures; 58 tests pass |
| RTL alignment correct | Pass | AR captures render right-aligned; explicit `Directionality` at root |
| LTR alignment correct | Pass | EN captures render left-aligned |
| Typography consistent | Pass | Single `TextTheme`; no per-screen font overrides |
| Spacing balanced | Pass | All new widgets use `AppDimens` |
| Images not cropped oddly | Pass | `BoxFit.cover` in `AppNetworkImage`; fallback on error |
| Icons correct | Pass | Amenity icons resolve from DB `icon` keys; tests cover real keys |
| Navigation not broken | Pass | Each hop verified individually (see §6) |
| Buttons usable | Pass | Book / retry / clear-search all render with ≥44 px targets |
| Empty states present | Pass | Capture 11 |
| Error states present | Pass | Capture 12 |
| No fabricated content | Pass | Real description shown; no invented amenities or reviews |

---

## 6. Navigation verification

| Hop | Verified | How |
|---|---|---|
| Homepage → Search | Yes | `_SearchEntry` `onTap` → `SearchScreen`; `initialTab` honoured |
| Homepage → Category → Search | Yes | `CategoryCard.onTap` passes `categoryId` + `categoryName` |
| Homepage → Destination → Search | Yes | `DestinationCard.onTap` passes the city |
| Homepage → Hotel details | Yes | `_openHotel` → `HotelDetailsScreen(hotel:)` |
| Hotel details → Unit details | Yes | Unit tap → `UnitDetailsScreen(unitId:)` |
| Unit details → Booking | Yes | Book button → `BookingScreen` |
| Search → Hotel / Unit details | Yes | Card `onTap` handlers wired |
| Back navigation | Yes | Standard `Navigator.pop`; no custom `WillPopScope` override |
| Search state preservation | Yes | Criteria held in `State`; `initialTab` respected |
| Full chain Homepage→City→Hotel→Unit→Booking | **Not walked end-to-end in one session** | Each hop verified individually; the composed chain is `AO-UNIT-12`, status Partial |

---

## 7. Honest limitations

1. Renders are web renderings of the Flutter widget tree, not Android emulator
   captures. No Android emulator was available.
2. The harness enables semantics, which changes the accessibility tree slightly
   relative to production. It does not change layout, which is what was measured.
3. Live-backend data is small and in places looks like test data
   (`test`, `يي`, `ديمو`, `Start Group`). That is the real production data at the
   time of capture. It is rendered faithfully rather than filtered, which is
   itself evidence that the screens show what the backend actually holds.
4. Only Arabic was captured for the empty and error states; English equivalents
   are covered by widget tests, not by a capture.
5. Animations (splash, page transitions) were not captured frame-by-frame.

**Conclusion:** visual acceptance is claimed for the twelve captured screens at
the widths tested, with the limitations above stated explicitly. No defect
identified in §4 remains open.

---

## 8. Addendum — owner-units section (2026-10-20)

The reconciliation added a new homepage component, `OwnerHotelCard`, in the
"hotels with owner units" section (matrix items 21–22). Its layout was verified
in the existing widget harness, not on a device:

| Check | Result |
|---|---|
| Renders name, city, unit count, rating, min price | Verified (`widgets_test.dart`, `OwnerHotelCard` group) |
| Rating pill suppressed when rating is 0 | Verified |
| Does not throw when the image URL is empty | Verified |
| `onTap` fires | Verified |
| Arabic RTL / English LTR text direction | Inherited from the shared `wrap()` harness used by all card tests |

**Not verified visually:** an actual device screenshot of the new card. No
emulator is available in this environment, so the claim is limited to
layout-integrity and RTL direction in the widget harness — consistent with the
limitations already stated in §7 of this document.

---

## 9. Addendum — Executions 02–05 close-out (2026-10-20)

Executions 02–05 changed no screen layout, colour, spacing or typography, so the
twelve captures in §1–§6 remain the visual evidence for the app. Two exceptions
are visual and are recorded here rather than left implicit.

### 9.1 The directional arrow now points the right way (reqs 8, 17)

This is the one *visible* defect fixed in this pass. Six screens chose the arrow
by hand:

```dart
icon: isArabic ? Icons.chevron_left : Icons.chevron_right   // before
icon: Icons.chevron_right                                   // after
```

Flutter mirrors every `arrow_*` / `chevron_*` icon inside an RTL subtree because
their `matchTextDirection` is true. A probe test confirmed this for the whole
family, so the manual condition was flipping an already-flipped icon and the
"continue" affordance pointed backwards in Arabic. The fix is a deletion, not a
new layout, so no new capture is required — but a reviewer comparing screenshots
before and after will see the arrow reverse, and that is intended.

The behaviour is now pinned by a widget test that asserts the rendered icon's
transform matrix has `-1.0` as its first element under an RTL `Directionality`.

### 9.2 Contact links

`help_support_screen.dart` builds the WhatsApp / phone / email targets through
`contact_channels.dart` instead of inline string surgery. The visible result is
identical when the stored number is already digits-only; it changes (correctly)
when the number contains `+` or spaces, which previously produced a link the OS
refused to open.

### 9.3 What is still not visually verified

Unchanged from §7: **no Android device or emulator exists in this container**, so
there is no on-hardware capture. The twelve images are from a release web build
rendered from the real widget tree against the live backend, at 390×844, 360×800
and 768×1024. Nothing in this addendum claims a device screenshot.
