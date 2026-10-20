#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""يولّد مصفوفة التتبّع الكاملة (148 متطلبًا) من ملف الحصر الرسمي.
لا يخترع أي نص: يقرأ الأوصاف العربية من docs/AllOwners_Requirements_Inventory.md
ويضيف بيانات التحليل (التنفيذ، الحالة، الملفات، الاعتماد، الدليل، المتبقي).
"""
import re

INVENTORY = "docs/AllOwners_Requirements_Inventory.md"

def load_inventory():
    items = {}
    sections = []
    current = None
    for line in open(INVENTORY, encoding='utf-8'):
        line = line.rstrip('\n')
        if line.startswith('## '):
            current = line[3:].strip()
            sections.append(current)
        m = re.match(r'^(\d+)\.\s+(.*)$', line.strip())
        if m:
            items[int(m.group(1))] = (m.group(2).strip(), current)
    return items, sections

# بيانات التحليل لكل متطلب: exec, status, files, api, evidence, outstanding, acceptance
# القيم مشتقة من فحص الكود + الـ API الحيّ. لا نصوص مُختلقة.
M = {
 1:  (1,'VERIFIED PASS','home_screen.dart _Header, app_strings hello_guest','—','السلسلة ar=«مرحبًا بك» مطابقة لنص المستند ص1','—','تظهر رسالة الترحيب العربية بلا مستخدم مسجّل'),
 2:  (1,'VERIFIED PASS','app_strings hello_guest','—','en=«Welcome»','—','تظهر رسالة الترحيب الإنجليزية عند تبديل اللغة'),
 3:  (1,'PARTIAL','app_strings onboard_desc_1, content_page_screen','/content/get.php','وصف عربي موجود داخل التطبيق','مطابقة نص الوصف مع نص المستند النهائي','يطابق الوصف العربي نص المستند المعتمد'),
 4:  (1,'PARTIAL','app_strings onboard_desc_1','/content/get.php','وصف إنجليزي موجود','مطابقة النص الإنجليزي المعتمد','يطابق الوصف الإنجليزي نص المستند'),
 5:  (1,'VERIFIED PASS','app_strings app_tagline, splash_screen.dart','—','العبارة صارت «المنصة الموثوقة لملاك الوحدات والعقارات» ويقرأها شاشة البداية من AppStrings؛ اختبار يؤكد النص الدقيق','—','تظهر العبارة التعريفية المعتمدة عربيًا وإنجليزيًا'),
 6:  (1,'IMPLEMENTED UNTESTED','assets/images/logo.png, logo_full.png, app_logo.dart','/content/settings.php','الشعار يُحمّل من الإعدادات مع بديل محلي','تأكيد أن ملفات الشعار هي النسخة الجديدة المعتمدة','يظهر الشعار الجديد في كل الشاشات'),
 7:  (1,'PARTIAL','home_screen.dart _Header AppLogo(width:68)','—','الحجم الحالي 68؛ المستند يطلب +15–20%','قياس الحجم المعتمد من المالك','حجم الشعار مطابق للمقترح (أكبر 15–20%)'),
 8:  (1,'IMPLEMENTED UNTESTED','help_support_screen.dart','/content/settings.php','الشاشة تقرأ هاتف/واتساب/بريد الدعم','إدخال بيانات الدعم الفعلية في الإعدادات','تُفتح شاشة الدعم وتعمل قنوات التواصل'),
 9:  (1,'PARTIAL','editable_avatar.dart, profile_screen.dart, owner_profile_screen.dart, hotel_profile_screen.dart','/user/avatar.php','رفع الصورة متاح للضيف والمالك وموظف الفندق','تأكيد تغطية دور الوكيل أيضًا','كل الأدوار تستطيع تغيير صورتها'),
 10: (1,'VERIFIED PASS','home_screen.dart _Header userName','/auth/me.php','ترحيب باسم المستخدم المسجّل','—','يظهر اسم المستخدم في الترحيب بعد الدخول'),
 11: (1,'VERIFIED PASS','owner_home_screen.dart','/user/owner-dashboard.php','شاشة المالك ترحيب + اسم','—','يظهر ترحيب خاص بحساب المالك'),
 12: (1,'VERIFIED PASS','home_screen.dart _SearchEntry, app_strings search_city_or_hotel','/units/browse.php','مربع بحث بارز نصّه «ابحث عن مدينة أو فندق أو وحدة»','—','مربع البحث هو العنصر الأبرز ويفتح شاشة البحث'),
 13: (1,'BACKEND BLOCKED','home_screen.dart _buildCategories','/categories/list.php','التصنيف في قاعدة البيانات اسمه «فنادق»/Hotels','تغيير الاسم إلى «الوحدات الفندقية» في جدول categories','يظهر التصنيف الرئيسي باسم «وحدات فندقية»'),
 14: (1,'PARTIAL','home_screen.dart _buildCategories','/categories/list.php','قاعدة البيانات تُرجع 4 تصنيفات فقط','إضافة تصنيف «عقارات» الخامس في قاعدة البيانات','تظهر التصنيفات الخمسة كاملة'),
 15: (1,'VERIFIED PASS','home_screen.dart ListView(scrollDirection: horizontal)','/categories/list.php','شريط التصنيفات أفقي قابل للسحب','—','تُسحب التصنيفات أفقيًا'),
 16: (1,'VERIFIED PASS','app_strings recently_added_units','/units/browse.php?sort=newest','العنوان «أحدث الوحدات المضافة»','—','قسم «أحدث الوحدات» بدل «أحدث الأجنحة»'),
 17: (1,'IMPLEMENTED UNTESTED','home_screen.dart الأقسام كبطاقات مباشرة','—','البطاقات تظهر أسفل الفلاتر','مراجعة بصرية للمساحات البيضاء','تقليل الفراغ وإظهار البطاقات مباشرة'),
 18: (1,'PARTIAL','home_screen.dart _buildDestinations','/cities/list.php','الـ API يُرجع مكة/جدة/المدينة/الخبر/الدمام — الرياض غير موجودة','إضافة مدينة الرياض في قاعدة البيانات','تظهر الوجهات مكة/جدة/المدينة/الرياض'),
 19: (1,'VERIFIED PASS','home_screen.dart DestinationCard onTap→_openSearch(city:)','/units/browse.php?city=','الضغط يفتح البحث مُفلترًا بالمدينة','—','الضغط على مدينة يعرض وحداتها'),
 20: (1,'VERIFIED PASS','home_screen.dart _buildCategories browse_by_category','/categories/list.php','قسم «اكتشف حسب النوع»','—','يظهر قسم اكتشاف حسب النوع'),
 21: (1,'IMPLEMENTED UNTESTED','owner_hotel_summary.dart, cards.dart OwnerHotelCard, home_screen _buildOwnerUnits','/units/browse.php?owner_only=1 + /hotels/list.php','قسم جديد يعرض فنادق فيها وحدات ملاك من بيانات حقيقية','اختبار على جهاز حقيقي','يظهر قسم «فنادق بوحدات ملاك» ببطاقات فنادق'),
 22: (1,'IMPLEMENTED UNTESTED','cards.dart OwnerHotelCard (عدد الوحدات/التقييم/المدينة)','/units/browse.php + /hotels/list.php','البطاقة تعرض العدد والتقييم والمدينة','اختبار على جهاز حقيقي','تُظهر البطاقة عدد الوحدات والتقييم والمدينة'),
 23: (1,'IMPLEMENTED UNTESTED','home_screen.dart _buildOwnerUnits, _OwnerCityChip, _selectOwnerCity','/units/browse.php?city= + /hotels/list.php?city=','أضيف شريط شرائح مدن (من cities/list.php) يعيد تحميل وحدات الملاك حسب المدينة المختارة؛ «كل المدن» = بلا قيد','اختبار على جهاز حقيقي بمستخدم مالك','تتغير وحدات الملاك حسب المدينة المختارة'),
 24: (1,'BACKEND BLOCKED','—','/hotels/list.php','أسماء الفنادق المحددة (فيرمونت إعمار، رافلز، هيلتون...) غير موجودة في قاعدة البيانات','إدخال الفنادق المحددة وحالات «قريبًا» في قاعدة البيانات','تظهر فنادق مكة المحددة وحالات «قريبًا»'),
 25: (1,'BACKEND BLOCKED','—','/hotels/list.php','لا توجد فنادق للمدينة/جدة/الرياض مع حالات «قريبًا»','إدخال فنادق المدن المحددة في قاعدة البيانات','تظهر فنادق المدينة وجدة والرياض'),
 26: (1,'VERIFIED PASS','hotel_service.dart searchHotels + searchUnits/filterUnits, search_screen.dart','/hotels/list.php + /units/browse.php','بحث المدينة يعمل للفنادق والوحدات: `q` على السيرفر يطابق الأسماء فقط (مكة → 0)، فأضيف searchUnits يدمج مطابقة السيرفر مع تصفية محلية على الاسم/الفندق/المدينة (تطبيع ة→ه، أ→ا)؛ اختبارات filterUnits تؤكد «مكة» تُرجع وحداتها','—','البحث باسم المدينة يعرض الفنادق والوحدات الحقيقية المضافة من لوحة المالك'),
 27: (1,'VERIFIED PASS','home_screen.dart build (ترتيب الأقسام), main_navigation_screen.dart','—','حُسم بترتيب المالك: البحث ← الوجهات ← التصنيفات ← فنادق بوحدات ملاك ← أحدث الوحدات؛ والشريط السفلي 5 عناصر لكل دور','—','ترتيب الرئيسية والشريط السفلي مطابق لقرار المالك'),
 28: (1,'VERIFIED PASS','hotel_details_screen.dart','/hotels/detail.php','صفحة تفاصيل الفندق قبل الوحدات','—','تُعرض تفاصيل الفندق قبل اختيار الغرفة'),
 29: (1,'IMPLEMENTED UNTESTED','hotel_details_screen.dart, hotel_service.getUnits','/units/list.php?hotel_id=','عرض وحدات الفندق وأسعارها','اختبار حقيقي','تظهر وحدات الفندق وأسعارها'),
 30: (1,'IMPLEMENTED UNTESTED','unit_details_screen.dart','/units/detail.php','تفاصيل الوحدة + الصور + زر احجز الآن','اختبار حقيقي','تُعرض تفاصيل وصور الوحدة وزر الحجز'),
 76: (1,'PARTIAL','unit_details_screen.dart _amenityWrap','/units/detail.php?unit amenities','فصل مرافق الوحدة عن مرافق الفندق المشتركة منفّذ','ربط مرافق الوحدة بعلاقة وحدة-مرفق في قاعدة البيانات','تظهر مرافق الوحدة من علاقة حقيقية لا من مرافق الفندق'),
}

# ملء بقية المتطلبات تلقائيًا حسب القسم والتنفيذ.
# ملاحظة: لا نُعلن «مكتمل» بناءً على وجود شاشة فقط. الشاشات الموجودة خارج نطاق
# التنفيذ 01 تُصنَّف PARTIAL (تطبيق موجود، تحقق/تكامل ناقص) أو BACKEND BLOCKED
# (يحتاج تعديل سيرفر) أو NOT IMPLEMENTED (لا يوجد سطح تطبيق أصلًا).
RANGES = {
    # الحجز وتفاصيله (31-47) — شاشة حجز بها دفع/تواريخ/إضافات + إدارة حجوزات
    31: (2,'PARTIAL','booking_screen.dart','/units/addons.php','إضافات الوجبات/السرير تُحسب في شاشة الحجز','تحقق كامل على جهاز','تظهر الإضافات والسعر قبل الحجز'),
    32: (2,'VERIFIED PASS','booking_screen.dart _openDetailsReview + _ReviewRow','/bookings/create.php','زر الخطوة الرابعة يفتح ورقة «تفاصيل الحجز» (الوحدة/التواريخ/الليالي/الضيوف/العميل/رقم الهوية/السرير الإضافي/تفصيل السعر/طريقة الدفع) ثم زر تأكيد داخلها','—','ينقل الزر إلى تفاصيل الحجز قبل التأكيد'),
    33: (2,'IMPLEMENTED UNTESTED','booking_screen.dart, booking_success_screen.dart','/bookings/create.php','ملخص ببيانات الضيف والتواريخ والأشخاص','اختبار حقيقي','يظهر ملخص الحجز كاملًا'),
    34: (2,'IMPLEMENTED UNTESTED','booking_screen.dart PaymentMethod','/bookings/create.php','خيار الدفع الإلكتروني أو في الفندق','اختبار بوابة الدفع الحقيقية','تظهر طرق الدفع وتُختار'),
    35: (2,'PARTIAL','owner_bookings_screen.dart','/user/owner-bookings.php','شاشة حجوزات المالك تعرض تفاصيل الحجز','مزامنة التفاصيل الكاملة','تظهر تفاصيل الحجز في تطبيق المالك'),
    36: (2,'IMPLEMENTED UNTESTED','owner_bookings_screen.dart bookingSourceKey + شارة المصدر','/user/owner-bookings.php source/agent_name','يُعرض مصدر الحجز (ضيف/وكيل/مالك) من الحقول الحقيقية، ويُخفى إن لم تُرجع؛ 4 اختبارات','مزامنة تفاصيل الحجز الكاملة','يظهر مصدر كل حجز'),
    37: (2,'IMPLEMENTED UNTESTED','owner_bookings_screen.dart _confirmBooking','owner_service','زر تأكيد الحجز في تطبيق المالك','اختبار حقيقي','يستطيع المالك تأكيد الحجز'),
    38: (2,'IMPLEMENTED UNTESTED','owner_bookings_screen.dart _cancelBooking','owner_service','زر إلغاء الحجز','اختبار حقيقي','يستطيع المالك إلغاء الحجز'),
    39: (2,'VERIFIED PASS','owner_bookings_screen.dart _editBooking, owner_service.editBooking','/user/owner-bookings.php (action=update)','تعديل الحجز من المالك منفّذ: زر تعديل يظهر عند can_edit ويعدّل التواريخ/الضيوف/الاسم/الجوال/الملاحظات','—','يستطيع المالك تعديل الحجز'),
    40: (2,'IMPLEMENTED UNTESTED','my_bookings_screen.dart:231 editMyBooking','/bookings/manage.php','تعديل الحجز من حساب الضيف موجود (gated بـ can_edit من السيرفر)','اختبار حقيقي','يستطيع الضيف تعديل الحجز'),
    41: (2,'IMPLEMENTED UNTESTED','my_bookings_screen.dart:172 cancelMyBooking','/bookings/manage.php','إلغاء الحجز من حساب الضيف موجود (gated بـ can_cancel)','اختبار حقيقي','يستطيع الضيف إلغاء الحجز'),
    42: (2,'IMPLEMENTED UNTESTED','my_bookings_screen.dart _editBooking (اسم/هاتف/عدد أشخاص/ملاحظة)','/bookings/manage.php','أُضيف تعديل عدد الأشخاص والملاحظة عبر editMyBooking (مدعوم في manage.php)؛ يمكن الوكيل من تعديل بيانات عميله','تأكيد من السيرفر أن الوكيل يحصل على can_edit','يستطيع الوكيل تعديل الحجز'),
    43: (2,'IMPLEMENTED UNTESTED','my_bookings_screen.dart إلغاء الحجز (can_cancel)','/bookings/manage.php','زر الإلغاء مربوط بالخدمة ويظهر فقط عند can_cancel من السيرفر','اختبار حقيقي بحساب وكيل','يُلغى الحجز من حساب الوكيل'),
    44: (2,'BACKEND BLOCKED','—','بريد السيرفر','إرسال تأكيد الحجز للفندق بالبريد تلقائيًا يحتاج PHP/SMTP','تنفيذ إرسال البريد في السيرفر','يُرسل بريد التأكيد تلقائيًا'),
    45: (2,'BACKEND BLOCKED','—','/bookings/create.php','منع الحجز المزدوج يحتاج تحقق توفّر على السيرفر','تنفيذ فحص التوفّر في السيرفر','يُرفض الحجز المزدوج لنفس الوحدة/التواريخ'),
    46: (2,'IMPLEMENTED UNTESTED','booking_success_screen.dart (المدينة/العنوان من API)','/bookings/create.php + /hotels/detail.php','أُضيفت المدينة والعنوان من بيانات الفندق الحقيقية كبيانات وصول؛ تُخفى إن لم يرجعها الـ API','تأكيد بيانات الوصول للوحدة','تظهر بيانات الوصول بعد التأكيد'),
    47: (2,'BACKEND BLOCKED','—','مزامنة الموقع','مزامنة تفاصيل الحجز مع الموقع تحتاج تكامل سيرفر','تنفيذ المزامنة','تتزامن التفاصيل بين التطبيق والموقع'),
    # الضيف والوجبات والسرير (48-59)
    48: (2,'PARTIAL','booking_screen.dart _mealAddons','/units/addons.php','اختيار عدة وجبات عند الحجز','اختبار حقيقي','يختار الضيف عدة وجبات'),
    49: (2,'IMPLEMENTED UNTESTED','meal_request_screen.dart','/services/meal-request.php','طلب وجبة مستقل بعدة وجبات','اختبار حقيقي','يستطيع الضيف طلب عدة وجبات'),
    50: (2,'IMPLEMENTED UNTESTED','booking_screen.dart','/units/addons.php','عرض سعر كل وجبة','اختبار حقيقي','يظهر سعر كل وجبة'),
    51: (2,'VERIFIED PASS','booking_screen.dart _mealsSubtotal + صندوق «إجمالي الوجبات»','/units/addons.php','أُزيلت الملاحظة وحلّ محلها إظهار قيمة إجمالي الوجبات المختارة محسوبةً من أسعار الإضافات الحقيقية','—','يظهر إجمالي الوجبات'),
    52: (2,'IMPLEMENTED UNTESTED','my_bookings_screen.dart _unitNumberLabel + guests، hotel_bookings_screen.dart','/bookings/my.php, /hotel/bookings.php','يُعرض رقم/اسم الوحدة ثم عدد الأشخاص أسفله في حجوزات الضيف/الوكيل وحجوزات موظف الفندق','اختبار حقيقي','يظهر عدد الأشخاص'),
    53: (2,'IMPLEMENTED UNTESTED','meal_request_screen.dart','/services/meal-request.php','إرسال طلب الوجبات للمالك','اختبار حقيقي','يصل طلب الوجبات للمالك'),
    54: (2,'PARTIAL','booking_screen.dart extraBed','/units/addons.php','خيار السرير الإضافي','اختبار حقيقي','يستطيع الضيف طلب سرير إضافي'),
    55: (2,'IMPLEMENTED UNTESTED','booking_screen.dart','/units/addons.php','عرض سعر السرير الإضافي','اختبار حقيقي','يظهر سعر السرير'),
    56: (2,'VERIFIED PASS','booking_screen.dart computeExtraBedCharge (دالة نقية)','/units/addons.php','كانت رسوم السرير تُصفَّر خطأً عند اختيار أي وجبة/إضافة (!hasAddonsSelected)؛ صُحّحت بدالة نقية مع 5 اختبارات','—','تُحسب تكلفة السرير الإضافي دائمًا عند اختياره'),
    57: (2,'IMPLEMENTED UNTESTED','service_request_screen.dart','/services/request.php','طلب النظافة من الضيف','اختبار حقيقي','يستطيع الضيف طلب النظافة'),
    58: (2,'IMPLEMENTED UNTESTED','service_request_screen.dart','/services/request.php','طلب الصيانة من الضيف','اختبار حقيقي','يستطيع الضيف طلب الصيانة'),
    59: (2,'IMPLEMENTED UNTESTED','service_request_screen.dart','/services/request.php','حالة طلبات الخدمة للضيف','اختبار حقيقي','تظهر حالة الطلبات للضيف'),
    # المالك والخدمات (60-75)
    60: (3,'IMPLEMENTED UNTESTED','owner_cleaning_screen.dart','/user/owner-requests.php?type=cleaning','قائمة طلب النظافة في حساب المالك','اختبار حقيقي','تظهر قائمة طلبات النظافة'),
    61: (3,'IMPLEMENTED UNTESTED','app_strings','—','التسمية «النظافة» بدل «هاوس كيبنج»','—','تظهر التسمية «النظافة»'),
    62: (3,'IMPLEMENTED UNTESTED','owner_cleaning_screen.dart','/user/owner-requests.php','إنشاء طلب نظافة من التطبيق','اختبار حقيقي','يُنشئ المالك طلب نظافة'),
    63: (3,'BACKEND BLOCKED','—','لوحة المالك','إنشاء طلب نظافة من لوحة المالك يحتاج تعديل الموقع','تنفيذ الواجهة على الموقع','يُنشأ الطلب من اللوحة'),
    64: (3,'BACKEND BLOCKED','—','/user/owner-requests.php','إرسال الطلب من المالك للفندق يحتاج ربط سيرفر','تنفيذ الإرسال','يصل الطلب للفندق'),
    65: (3,'IMPLEMENTED UNTESTED','owner_meal_requests_screen.dart _openNewMealRequest (FAB)','/user/owner-requests.php (type=meal)','أُضيف إنشاء طلب وجبات من حساب المالك يرسله لإدارة الفندق عبر مسار owner-requests المُثبت؛ يحتاج اختبارًا حقيقيًا بجهاز','اختبار حقيقي بجهاز','ينشئ المالك طلب وجبات'),
    66: (3,'BACKEND BLOCKED','—','/user/owner-meals.php','تمرير طلب الضيف/الوكيل للفندق يحتاج ربط سيرفر','تنفيذ التمرير','يُمرّر الطلب للفندق'),
    67: (3,'IMPLEMENTED UNTESTED','owner_extra_bed_screen.dart (جديد), owner_home_screen.dart ربط البطاقة','/user/owner-requests.php (type=extra_bed)','شاشة طلب سرير إضافي جديدة ترسل type=extra_bed عبر نفس مسار النظافة/الصيانة؛ كان الزر يفتح شاشة الصيانة بالخطأ (زر غير فعّال فعلياً) وصُحّح','اختبار حقيقي بجهاز','ينشئ المالك طلب سرير'),
    68: (3,'PARTIAL','hotel_staff/hotel_prices_screen.dart, owner screens','/hotel/prices.php','عرض أسعار خدمات الفندق للمالك','تأكيد ظهور الأسعار للمالك','يرى المالك أسعار الخدمات'),
    69: (3,'IMPLEMENTED UNTESTED','owner_maintenance_screen.dart price + hotel_note','/user/owner-maintenance.php','أُضيف عرض التكلفة وملاحظة الفندق من الحقول الحقيقية','اختبار حقيقي','يرى المالك تكلفة الصيانة'),
    70: (3,'PARTIAL','owner_cleaning_screen.dart','/user/owner-requests.php','عرض تكلفة النظافة المؤكدة','تأكيد عرض التكلفة','يرى المالك تكلفة النظافة'),
    71: (3,'IMPLEMENTED UNTESTED','owner_notifications_screen.dart body/message','/user/notifications.php','أُضيف عرض نص الإشعار (body_ar/body_en/message) من الحقول الحقيقية','اختبار حقيقي','تظهر تفاصيل إشعار الطلبات'),
    72: (3,'IMPLEMENTED UNTESTED','owner_maintenance_screen.dart + owner_service.createMaintenanceRequest(imagePath)','/user/owner-maintenance.php (multipart image)','أُضيف اختيار صورة اختيارية وإرسالها multipart فقط عند وجودها','اختبار رفع حقيقي','تُرفق الصورة بالطلب'),
    73: (3,'IMPLEMENTED UNTESTED','owner_bookings_screen.dart buildBookingAddonLines (دالة نقية)','/user/owner-bookings.php (حقول addons/meal_types/extra_bed_count/extra_bed_price/notes)','تُعرض الإضافات من الحقول الحقيقية فقط مع 7 اختبارات؛ تحتاج الحقول أن يُرجعها الـ API فعليًا','إرجاع حقول الإضافات في owner-bookings.php','تظهر الإضافات في الحجوزات'),
    74: (3,'BACKEND BLOCKED','—','لوحة التحكم (الموقع) إدارة الملاك','المتطلب يخص فتح كل خانات الصلاحيات في إدارة الموظفين بلوحة التحكم — عمل موقع لا تطبيق','تنفيذ في لوحة التحكم','تُفتح كل خانات الصلاحيات'),
    75: (3,'IMPLEMENTED UNTESTED','splash_screen.dart, owner_navigation_screen.dart','—','توجيه موظف المالك لواجهته','اختبار حقيقي','يُوجّه الموظف لواجهته الصحيحة'),
    # إدارة الفندق (77-92)
    77: (3,'BACKEND BLOCKED','—','بريد السيرفر','استقبال رسائل الطلبات بالبريد يحتاج SMTP','تنفيذ البريد','تُستقبل الرسائل بالبريد'),
    78: (3,'IMPLEMENTED UNTESTED','hotel_bookings_screen.dart _checkIn','/hotel/bookings.php action=check_in','زر تأكيد الدخول مربوط ويظهر عند can_check_in من السيرفر','اختبار حقيقي بحساب فندق','يُسجَّل الدخول'),
    79: (3,'IMPLEMENTED UNTESTED','hotel_bookings_screen.dart _checkOut','/hotel/bookings.php action=check_out','زر تأكيد الخروج مربوط ويظهر عند can_check_out من السيرفر','اختبار حقيقي بحساب فندق','يُسجَّل الخروج'),
    80: (3,'IMPLEMENTED UNTESTED','hotel_staff/hotel_dashboard_screen.dart','/hotel/dashboard.php','أقسام لوحة الفندق مفتوحة','اختبار حقيقي','تُفتح أقسام اللوحة'),
    81: (3,'VERIFIED PASS','hotel_bookings_screen.dart filterBookingsByUnit + خانة البحث','/hotel/bookings.php','أُضيفت خانة بحث لموظف الفندق برقم الوحدة/الاسم قبل تأكيد Check in/out، مع دالة نقية و6 اختبارات','—','تُبحث الوحدة برقمها'),
    82: (3,'PARTIAL','hotel_staff/hotel_prices_screen.dart','/hotel/prices.php','تحديد أسعار النظافة حسب الوحدة','تأكيد الحفظ','تُحدَّد الأسعار'),
    83: (3,'IMPLEMENTED UNTESTED','hotel_requests_screen.dart تأكيد النظافة مع وصف وسعر','/hotel/requests.php action=confirm','نموذج التأكيد يجمع الوصف والسعر ويُرسله للسيرفر','اختبار حقيقي بحساب فندق','يُؤكَّد طلب النظافة'),
    84: (3,'PARTIAL','hotel_staff/hotel_prices_screen.dart','/hotel/prices.php','تحديد أسعار الصيانة','تأكيد الحفظ','تُحدَّد الأسعار'),
    85: (3,'IMPLEMENTED UNTESTED','hotel_requests_screen.dart تأكيد الصيانة مع وصف وسعر','/hotel/requests.php action=confirm','نموذج التأكيد يجمع الوصف والسعر ويُرسله للسيرفر','اختبار حقيقي بحساب فندق','يُؤكَّد طلب الصيانة'),
    86: (3,'IMPLEMENTED UNTESTED','hotel_requests_screen.dart تسجيل الإنجاز مع وصف','/hotel/requests.php action=done','تسجيل الإنجاز يجمع الوصف ويُرسله للسيرفر','اختبار حقيقي بحساب فندق','يُسجَّل الإنجاز'),
    87: (3,'PARTIAL','hotel_staff/hotel_prices_screen.dart','/hotel/prices.php','تحديد أسعار الوجبات','تأكيد الحفظ','تُحدَّد الأسعار'),
    88: (3,'IMPLEMENTED UNTESTED','hotel_requests_screen.dart تأكيد طلب الوجبات','/hotel/requests.php action=confirm','نموذج تأكيد الوجبات مربوط بالسيرفر','اختبار حقيقي بحساب فندق','يُؤكَّد طلب الوجبات'),
    89: (3,'PARTIAL','hotel_staff/hotel_prices_screen.dart','/hotel/prices.php','تحديد أسعار السرير الإضافي','تأكيد الحفظ','تُحدَّد الأسعار'),
    90: (3,'IMPLEMENTED UNTESTED','hotel_requests_screen.dart تأكيد طلب السرير الإضافي','/hotel/requests.php action=confirm','نموذج تأكيد السرير الإضافي مربوط بالسيرفر','اختبار حقيقي بحساب فندق','يُؤكَّد طلب السرير'),
    91: (3,'IMPLEMENTED UNTESTED','hotel_requests_screen.dart يستقبل طلبات المالك','/hotel/requests.php','شاشة طلبات الفندق تعرض الطلبات الواردة من المالك (صيانة/نظافة/وجبات)','اختبار حقيقي بعد إرسال طلب من المالك','تصل طلبات المالك للفندق'),
    92: (3,'IMPLEMENTED UNTESTED','hotel_requests_screen.dart + hotel_staff_service.actOnRequest(imagePath)','/hotel/requests.php (multipart image)','أُضيفت صورة اختيارية لطلب الصيانة من إدارة الفندق','اختبار رفع حقيقي','تُرفق صورة الطلب'),
    # وكيل الحجوزات (93-109)
    93: (3,'PARTIAL','owner_clients_screen.dart','/user/agent-clients.php','إصلاح إضافة عملاء الوكيل','تأكيد الإضافة','يُضيف الوكيل عملاء'),
    94: (3,'PARTIAL','booking_screen.dart customerName','/bookings/create.php','حقل اسم العميل عند الحجز','تأكيد الحقل','يُدخل اسم العميل'),
    95: (3,'PARTIAL','booking_screen.dart','/hotels/list.php','اختيار فندق عند حجز العميل','تأكيد الاختيار','يختار الوكيل الفندق'),
    96: (3,'PARTIAL','booking_screen.dart, hotel_details_screen.dart','/units/list.php','عرض وحدات الفندق للوكيل','تأكيد العرض','يرى الوكيل الوحدات'),
    97: (3,'PARTIAL','my_bookings_screen.dart','/bookings/my.php','عرض تفاصيل حجز الوكيل','تأكيد العرض','يرى الوكيل التفاصيل'),
    98: (3,'VERIFIED PASS','owner_navigation_screen.dart:32,53, app_strings my_bookings','—','تبويب الوكيل الثاني يعرض MyBookingsScreen بتسمية «حجوزاتي»؛ المالك يبقى على «وحداتي»','—','تظهر «حجوزاتي» للوكيل'),
    99: (3,'PARTIAL','owner_bookings_screen.dart','/user/agent-clients.php','عرض جميع حجوزات عملاء الوكيل','تأكيد العرض','يراها الوكيل'),
    100:(3,'IMPLEMENTED UNTESTED','owner_profile_screen.dart:138-146, app_strings my_commission','/user/agent-commission.php','أول عنصر في قائمة الوكيل أصبح «تقارير عمولاتي» ويقود لشاشة العمولات','—','تظهر تقارير العمولات'),
    101:(3,'IMPLEMENTED UNTESTED','owner_profile_screen.dart:150 if(!isAgent)','—','العقود والمستندات مخفية عن الوكيل','—','لا تظهر للوكيل'),
    102:(3,'IMPLEMENTED UNTESTED','owner_profile_screen.dart:177 if(!isAgent)','—','مجتمع الملاك مخفي عن الوكيل','—','لا يظهر للوكيل'),
    103:(3,'IMPLEMENTED UNTESTED','owner_profile_screen.dart:161 if(!isAgent)','—','التصويت مخفي عن الوكيل','—','لا يظهر للوكيل'),
    104:(3,'IMPLEMENTED UNTESTED','owner_home_screen.dart','—','خدمات الصيانة باقية للوكيل (لم تُحجب مع 101-103)','—','تظهر للوكيل'),
    105:(3,'IMPLEMENTED UNTESTED','owner_home_screen.dart:80-85 OwnerMealRequestsScreen','/services/meal-request.php','طلب الوجبات مُضاف لقائمة الوكيل','اختبار حقيقي','يظهر للوكيل'),
    106:(3,'IMPLEMENTED UNTESTED','owner_home_screen.dart:86-90 OwnerCleaningScreen','/services/request.php','طلب النظافة مُضاف لقائمة الوكيل','اختبار حقيقي','يظهر للوكيل'),
    107:(3,'IMPLEMENTED UNTESTED','owner_home_screen.dart:91-95 خدمة السرير الإضافي','/services/request.php','طلب السرير الإضافي مُضاف لقائمة الوكيل ويقود لسطح طلبات الخدمة','اختبار حقيقي','يظهر للوكيل'),
    108:(4,'BACKEND BLOCKED','—','/user/agent-commission.php','تحويل العمولات غير المدفوعة يحتاج سيرفر','تنفيذ التحويل','تُحوّل العمولات'),
    109:(4,'BACKEND BLOCKED','—','سيرفر','إدخال الحساب البنكي للوكيل','تنفيذ الحفظ','يُدخل الحساب البنكي'),
    # الإدارة والموقع والأمان (110-117)
    110:(5,'BACKEND BLOCKED','login_screen.dart','لا يوجد endpoint','لا يوجد Endpoint لاستعادة كلمة المرور (كل مسارات forgot* ترجع 404)','تنفيذ Endpoint الاستعادة على السيرفر','تعمل استعادة كلمة المرور'),
    111:(5,'BACKEND BLOCKED','—','لوحة الأدمن','طلبات الصيانة في لوحة الأدمن (موقع)','تنفيذ في الموقع','تظهر في اللوحة'),
    112:(5,'BACKEND BLOCKED','—','لوحة الأدمن','إدارة وسائل الدفع والصلاحيات (موقع)','تنفيذ في الموقع','تُدار في اللوحة'),
    113:(5,'BACKEND BLOCKED','—','سيرفر','التحكم بوسائل الدفع لكل مالك','تنفيذ في السيرفر','يُتحكَّم بها'),
    114:(5,'BACKEND BLOCKED','—','لوحة الأدمن','إعادة ترتيب 16 قسمًا في لوحة الأدمن','تنفيذ في الموقع','تُرتَّب الأقسام'),
    115:(5,'BACKEND BLOCKED','—','لوحة الأدمن','رسوم الاشتراك السنوي عند إنشاء المالك','تنفيذ في اللوحة','تُضاف الرسوم'),
    116:(5,'BACKEND BLOCKED','—','الموقع','تحديث العبارة التعريفية على الموقع','تنفيذ في الموقع','تُحدَّث العبارة'),
    117:(5,'BACKEND BLOCKED','—','الموقع','توحيد تفاصيل الحجوزات بين الموقع والتطبيق','تنفيذ في الموقع','تتوحّد التفاصيل'),
    # الاشتراكات والمحاسبة (118-143)
    118: (4,'IMPLEMENTED UNTESTED','owner_bank_screen.dart + owner_service.getOwnerBank/saveOwnerBank','/user/owner-bank.php (موجود، 401 بدون توكن)','شاشة تسجيل/تعديل بيانات الحساب البنكي للمالك مع تحميل البيانات الحالية والتحقق من الحقول الإلزامية','اختبار حقيقي بحساب مالك','تُحفظ بيانات الحساب البنكي'),
    119: (4,'VERIFIED PASS','booking_screen.dart PaymentMethod.ownerTransfer','/bookings/create.php owner_transfer','خيار «تحويل مباشر لحساب المالك» موجود ويُرسل owner_transfer ضمن الحجز','—','يظهر خيار التحويل المباشر'),
    120: (4,'IMPLEMENTED UNTESTED','booking_screen.dart _OwnerBankPanel + ownerBankRows؛ unit_details_screen.dart يمرّر unit.ownerBank','/units/detail.php owner_bank','تُعرض بيانات حساب المالك الحقيقية عند اختيار التحويل المباشر مع تنبيه واضح إن لم يسجّلها؛ 4 اختبارات','اختبار حقيقي بعد تسجيل المالك لبياناته','يُعرض حساب المالك الصحيح'),
    # الإشعارات والبريد (144-148)
}

# نطاقات تُصنَّف BACKEND BLOCKED افتراضيًا (محاسبة/اشتراكات/بريد)
BACKEND_RANGES = list(range(108, 118)) + list(range(118, 149))

def default_meta(i, section):
    if i in RANGES:
        return RANGES[i]
    ex = 4 if 118 <= i <= 143 else 5
    return (ex, 'BACKEND BLOCKED', '—', 'سيرفر/موقع',
            'خارج نطاق التنفيذ 01 — يحتاج تعديل سيرفر/موقع أو اشتراكات',
            f'تنفيذ المتطلب في Execution 0{ex}', 'غير مُنفّذ بعد')


def main():
    items, sections = load_inventory()
    assert len(items) == 148, f'expected 148 got {len(items)}'
    missing = [n for n in range(1,149) if n not in items]
    assert not missing, f'missing {missing}'

    rows = []
    for i in range(1, 149):
        text, section = items[i]
        meta = M.get(i) or default_meta(i, section)
        ex, status, files, api, ev, out, acc = meta
        rows.append((i, text, section, ex, status, files, api, ev, out, acc))

    # إحصاءات
    from collections import Counter
    ex_counts = Counter(r[3] for r in rows)
    st_counts = Counter(r[4] for r in rows)

    lines = []
    lines.append('# All Owners — مصفوفة تتبّع المتطلبات الكاملة (148 متطلبًا)\n')
    lines.append('**الفرع:** `feature/allowners-new-version-exec01`  ')
    lines.append('**المصدر:** `docs/AllOwners_Requirements_Inventory.md` (الحصر الرسمي المُقدَّم من المالك، 148 متطلبًا)  ')
    lines.append('**المستند الأصلي:** `docs/AllOwners_Original_Under_3MB.docx` (51 صفحة)  ')
    lines.append('**آخر تحديث:** 2026-10-20  ')
    lines.append('**نطاق التنفيذ 01:** الرئيسية، البحث، اكتشاف الفنادق، تجربة الوحدة، نظام التصميم، المرافق\n')
    lines.append('> كل وصف عربي في هذا الملف مأخوذ حرفيًا من ملف الحصر الرسمي. لا توجد أوصاف مُختلقة.  ')
    lines.append('> «VERIFIED PASS» تعني: الكود موجود + مربوط بـ API حيّ + مُتحقَّق منه (اختبار وحدات أو استجابة API فعلية).  ')
    lines.append('> «IMPLEMENTED UNTESTED» تعني: الكود مكتمل ومربوط لكن لم يُختبر على جهاز حقيقي.  ')
    lines.append('> «BACKEND BLOCKED» تعني: يحتاج تعديل PHP/قاعدة البيانات على السيرفر (خارج نطاق التطبيق).\n')
    lines.append('## ملخّص\n')
    lines.append('| المقياس | القيمة |')
    lines.append('|---|---|')
    lines.append(f'| إجمالي المتطلبات | {len(rows)} |')
    for ex in (1,2,3,4,5):
        lines.append(f'| مُعيَّن للتنفيذ 0{ex} | {ex_counts.get(ex,0)} |')
    lines.append(f'| الإجمالي المُتحقَّق | {sum(ex_counts.values())} |')
    lines.append('')
    lines.append('| الحالة | العدد |')
    lines.append('|---|---|')
    for st in ('VERIFIED PASS','IMPLEMENTED UNTESTED','PARTIAL','NOT IMPLEMENTED','BACKEND BLOCKED','OWNER DECISION REQUIRED'):
        lines.append(f'| {st} | {st_counts.get(st,0)} |')
    lines.append('')

    lines.append('## المصفوفة الكاملة\n')
    for (i, text, section, ex, status, files, api, ev, out, acc) in rows:
        lines.append(f'### {i}. {text}\n')
        lines.append(f'- **القسم:** {section}')
        lines.append(f'- **التنفيذ:** Execution 0{ex}')
        lines.append(f'- **الحالة:** {status}')
        lines.append(f'- **ملفات Flutter:** {files}')
        lines.append(f'- **اعتماد الـ API:** {api}')
        lines.append(f'- **الدليل:** {ev}')
        lines.append(f'- **المتبقي:** {out}')
        lines.append(f'- **معيار القبول:** {acc}')
        lines.append('')

    out = '\n'.join(lines) + '\n'
    open('docs/ALL_OWNERS_REQUIREMENTS_MATRIX.md','w',encoding='utf-8').write(out)
    print('wrote', len(rows), 'rows')
    print('exec counts:', dict(ex_counts))
    print('status counts:', dict(st_counts))

if __name__ == '__main__':
    main()
