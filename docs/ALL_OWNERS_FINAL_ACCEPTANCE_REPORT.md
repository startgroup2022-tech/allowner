# All Owners — تقرير القبول النهائي (المستندان 05 و06)

**الفرع:** `feature/allowners-new-version-exec01` · **PR:** #1 (Draft، مفتوح)
**تاريخ التنفيذ:** 2026-11-26 · **Flutter 3.47.7 / Dart 3.13.5**
**آخر دفعة:** المستند 06 §A–§L بعد إغلاق المجموعتين 01 و02.

## 1. الإجماليات المطلوبة

| # | المطلوب | القيمة |
|---|---|---|
| 1 | إجمالي المتطلبات المراجَعة | **148** (المستند 05) + **17** (المستند 06، المجموعتان 01–02) + **31** بندًا (§A–§L) = **196** |
| 2 | متطلبات مكتملة كليًا (END-TO-END) | **103** من المستند 05 + **17** من المستند 06 (المجموعتان 01–02) + **20** بندًا من §A–§L |
| 3 | متطلبات Flutter مكتملة وتنتظر الخادم | **28** (Doc 05) + بنود D-2، F-4، G-1، H-2، K-1، C-1 |
| 4 | متطلبات خلفية معلّقة | **13** محجوبة كليًا (BACKEND BLOCKED) + **28** تنتظر عقد خادم |
| 5 | متطلبات غير مكتملة | **0** بمعنى «لم يُعمل بها شيء»؛ المتبقي محجوب تقنيًا لا مهمَل |
| 6 | بنود بصرية تم التحقق منها | **11** بندًا (2. المراجعة البصرية) + **1** بانتظار ملف شعار (متطلب 6) |
| 7 | قرارات مالك مفتوحة | **6**: C1 نموذج الدفع، C2 الرياض، C3 نطاق العمولة، C4 مرسل رابط واتساب، C5 اعتماديات Firebase، C6 كلمة المرور المنسية |

**دقة التصنيف:** لم يُوسم أي متطلب مالي أو موقع أو أدمن بأنه END-TO-END، لأن
ملفات PHP ولوحة الأدمن غير موجودة في هذا المستودع.

## 2. ما أُنجز في هذه الدفعة (§A–§L)

### §A الرئيسية والتنقل
- `lib/utils/home_sections.dart`: `kHomeSectionOrder` و`kFeaturedCityOrder` في
  مكان واحد؛ الشاشة تبني الأقسام بالتكرار على هذا الترتيب، والاختبار يقيس
  مواضع العناصر فعليًا (`dy`) للتأكد أن «اكتشف حسب النوع» آخرًا.
- ترتيب المدن: مكة → المدينة → جدة → الرياض (الرياض تبقى: قرار C2).
- القائمة السفلية: الرئيسية/البحث/**ضيافاتي**/المفضلة/حسابي — مطابقة، ولا تغيير
  في الأيقونات (لا يوجد طلب استبدال أيقونة في المستند).

### §B الحجز
- `computeExtraBedCharge(quantity, nights)`: العدد × سعر الليلة × الليالي،
  مع `extraBedChargeFormula` لعرض «2 × 100 × 3 = 600».
- منتقي عدد الأسرّة (1–4) داخل شاشة الحجز، ويُصفَّر عند إيقاف الخيار.
- `booking_payload`: `extra_bed_qty` يُرسل فقط عند `extra_bed=true` وبعدد > 1.
- `isDaySelectable` + `selectableDayPredicate`: لا يمكن اختيار يوم خارج كل
  فترات الإتاحة المُعلنة، والإرسال يُوقف مع رسالة واضحة.
- كشف الحساب الكامل (سعر الوحدة + الإضافات + السرير + الضريبة) ما زال من دالة
  واحدة `computeBookingTotals` المستخدمة في مكاني الحجز.

### §D الإشعارات
- `lib/utils/notification_routing.dart`: 10 أنواع أحداث، التوجيه إلى 6 وجهات،
  نصوص عربي/إنجليزي (نص الخادم أولًا ثم مفاتيح التطبيق)، كشف تكرار بمفتاح
  الرسالة/الكيان، واستخراج معرّف الكيان.
- `lib/services/notification_service.dart`: `PushProvider` قابل للتبديل،
  `UnavailablePushProvider` افتراضيًا (لا يدّعي عملًا غير موجود)، طلب إذن،
  تسجيل رمز عبر `/user/device-token.php`، تجديد، وإلغاء تسجيل عند الخروج.
- **لا إشعارات حقيقية**: تحتاج Firebase + خادم إرسال (§7 في BACKEND_MASTER،
  وقرار C5 قبل تعديل `pubspec.yaml`).

### §F لوحة إدارة الفندق
- البطاقات الأربع كلها قابلة للنقر: الوصولات، المغادرات، النزلاء الحاليون،
  الطلبات المفتوحة.
- `hotel_arrivals_screen.dart` + `utils/arrivals.dart`: بيانات الضيف والوحدة
  والتواريخ والجوال، بحث برقم الوحدة (جزئي/كامل، أرقام عربية-هندية، مسح)،
  حالة فراغ، وتأكيد دخول يستخدم `check_in` القائم.

## 3. نتائج الاختبار (آخر تشغيل كامل)

```
flutter pub get                                   OK (pubspec.lock غير متغيّر)
dart format --output=none --set-exit-if-changed .  EXIT 0
flutter analyze                                    0 error / 0 warning (141 info)
flutter test                                       495 نجح · 17 متجاوَز · 0 فاشل
```

المتجاوزة (17) هي اختبارات تكامل حيّة تعمل فقط بـ `RUN_LIVE_TESTS=1` ضد
`all-owner.online`، ولم تُشغَّل هنا لأنها تلمس خادم الإنتاج:
`test/integration/*` (أربع مجموعات) وبعض اختبارات الـ API الحيّة المعلَّمة.

اختبارات هذه الدفعة: `test/document06_final_test.dart` (19)،
`test/hotel_staff_screens_render_test.dart` (+4 = 22)،
`test/screens_render_test.dart` (+1 = 13). لا اختبار قديم حُذف أو خُفِّف؛
اختبارات الرئيسية الثلاثة عُدِّلت لتمرير الشاشة إلى القسم الأخير (سلوك جديد
مقصود) بدل تغيير التوقّع.

## 4. الملفات المعدّلة في هذه الدفعة

```
lib/screens/booking/booking_screen.dart        (عدد الأسرّة، الإتاحة، سطر الشرح)
lib/screens/home/home_screen.dart              (ترتيب الأقسام)
lib/screens/hotel_staff/hotel_dashboard_screen.dart (البطاقات الأربع)
lib/screens/hotel_staff/hotel_arrivals_screen.dart  (جديد)
lib/services/hotel_service.dart                (extraBedQty)
lib/services/notification_service.dart         (جديد)
lib/utils/arrivals.dart                        (جديد)
lib/utils/availability.dart                    (isDaySelectable)
lib/utils/booking_payload.dart                 (extra_bed_qty)
lib/utils/city_ordering.dart                   (يقرأ من home_sections)
lib/utils/home_sections.dart                   (جديد)
lib/utils/notification_routing.dart            (جديد)
lib/utils/app_strings.dart                     (13 مفتاحًا ar/en)
test/document06_final_test.dart                (جديد)
test/hotel_staff_screens_render_test.dart      (+4)
test/screens_render_test.dart                  (+1)
tools/gen_final_matrix.py                      (جديد)
docs/ALL_OWNERS_FINAL_REQUIREMENTS_MATRIX.md   (جديد)
docs/ALL_OWNERS_FINAL_BACKEND_MASTER.md        (جديد)
docs/ALL_OWNERS_FINAL_VISUAL_REVIEW.md         (جديد)
docs/ALL_OWNERS_FINAL_ACCEPTANCE_REPORT.md     (هذا الملف)
```

## 5. الحماية المفروضة (تحقق آلي)

| القيد | التحقق |
|---|---|
| معرّف التطبيق `com.superai.allowners` | لا تغيير في `android/app/build.gradle` |
| توقيع Android | لا تغيير في `android/` (0 ملف) |
| `codemagic.yaml` | لا تغيير |
| `pubspec.yaml` / `pubspec.lock` | لا تغيير، لا اعتمادية مضافة أو مُخفَّضة |
| بناء APK/AAB محليًا | لم يُنفَّذ |
| تشغيل Codemagic | لم يُشغَّل |
| cPanel / الإنتاج | لم يُلمس |
| main | لم يُدمج، ولا force push |
| PR #1 | مفتوح، Draft |
| حذف الحساب (Google Play) | لم يُمسّ (شاشته وخدمته كما هي) |
| تعديلات المستند 05 والمجموعتين 01/02 | محفوظة: 495 اختبارًا تمر |

## 6. المتبقي قبل النشر — بالترتيب

1. **قرارات المالك الستة** (§9 في BACKEND_MASTER). بلا C1 وC3 لا يمكن تصميم
   جداول المالية، وبلا C5 لا إشعارات.
2. **تنفيذ خادم الدفع** (§4): `payment-settings.php` قراءة/كتابة + رفض الوسائل
   المعطّلة داخل `bookings/create.php` + تسجيل تدقيق.
3. **منع الحجز المزدوج على الخادم** (§1): `units/availability.php` +
   معاملة `FOR UPDATE` في `bookings/create.php` وإرجاع 409.
4. **تسوية الطلبات** (§5): `settlement` + منع التسوية المزدوجة 409.
5. **التسعير** (§6): `hotel/unit-pricing.php` و`hotel/meal-pricing.php`
   بالعقد المعروض، مع تحقق من الجداول المقترحة على قاعدة cPanel.
6. **الإشعارات** (§7): Firebase + `user/device-token.php` + `push/send.php`،
   ثم اختبار ثلاث حالات على جهاز حقيقي (أمامي/خلفي/مغلق).
7. **الأدمن والموقع** (§8): حذف «سعر الليلة»، وسائل الدفع، ١٦ قسمًا، طلبات
   الصيانة، اشتراك المالك، صفحة حذف الحساب.
8. **بعد ذلك فقط**: بناء Codemagic، اختبار المتجر، ثم الإنتاج — بقرار المالك.

## 7. ملاحظة صدق ختامية

كل ما وُسم END-TO-END مُثبت باختبار آلي داخل هذا المستودع. كل ما يعتمد على
خادم أو لوحة أو مزوّد دفع وُسم صراحةً بما ينقصه، ولم يُدَّع أي إشعار أو دفع أو
مزامنة موقع أنها تعمل. أي لقطة شاشة «بعد التعديل» تحتاج جهازًا أو بناء
Codemagic، ولم تُلتقط هنا.
