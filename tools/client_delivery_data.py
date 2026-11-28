#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""بيانات ومكوّنات ملف تسليم العميل المشترك بين نسختَي Word وPDF."""

import glob
import os
import re

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GOLD = os.path.join(ROOT, 'docs/evidence/final-acceptance')
HIRES = os.path.join(ROOT, 'docs/evidence/final-acceptance-hires')
SLICE_DIR = '/tmp/delivery_slices'

TITLE = 'ملف الإنجاز'
SUBTITLE = 'عرض شامل لما تم تنفيذه وتسليمه'
YEAR = '2026'
NOTE = ('وثيقة مُعدّة للعميل — تُعرض فيها وظائف المشروع ومخرجاته '
        'ومراحله المنجزة.')

SECTIONS = [
    {
        'folder': 'customer',
        'title': 'واجهة الضيف',
        'intro': 'رحلة الضيف كاملة: من البحث عن الفندق حتى تأكيد الضيافة '
                 'ومتابعتها داخل التطبيق.',
        'points': [
            'بحث الفنادق والوحدات بالمدينة والتاريخ، مع نتائج واضحة وحالات '
            '«لا نتائج» و«تعذّر التحميل».',
            'صفحة تفاصيل الفندق: صور الوحدات، الأسعار، المرافق، وبحث داخلي '
            'برقم الوحدة يعمل بالكتابة الجزئية أو الكاملة ويقبل الأرقام العربية.',
            'حجز كامل: التواريخ، عدد الضيوف، بيانات الضيف، السرير الإضافي، '
            'الوجبات، والسعر النهائي مفصّلًا قبل التأكيد.',
            'تأكيد الحجز بمرجع ضيافة موحّد وإظهار رقم الوحدة الفعلي الذي تم حجزه.',
            '«ضيافاتي»: قائمة الحجوزات القادمة والسابقة مع صفحة تفاصيل لكل ضيافة.',
            'المفضلة، الملف الشخصي، الصورة الشخصية، تبديل اللغة، واستعادة '
            'كلمة المرور.',
            'طلبات الخدمة (تنظيف، صيانة، وجبات) ومتابعة حالة كل طلب.',
            'حذف الحساب من داخل التطبيق، مع بديل عبر الموقع لمن لا يستطيع '
            'فتح التطبيق.',
        ],
    },
    {
        'folder': 'owner',
        'title': 'واجهة المالك',
        'intro': 'لوحة إدارة كاملة تمكّن المالك من متابعة الوحدات والحجوزات '
                 'والطلبات والإيرادات والموظفين.',
        'points': [
            'وحداتي: إضافة وتعديل الوحدات والأسعار وخدمات الوحدة وتصنيفاتها.',
            'الحجوزات: متابعة الحجوزات وتفاصيلها وإضافاتها وإجراءاتها.',
            'الطلبات: صيانة وتنظيف ووجبات، مع الموافقة على السعر وتسوية '
            'الدفع (خصم من الرصيد أو رابط دفع عبر واتساب).',
            'الإيرادات والمحفظة والمستحقات وإيراد كل وحدة بشكل منفصل.',
            'إدارة الموظفين وصلاحياتهم، وتقييد الوصول المالي بصلاحية صريحة.',
            'الاشتراك والتجديد، الحساب البنكي، وتحويل العمولة.',
            'الإشعارات داخل التطبيق، مع عرض صادق لحالة تفعيل الإشعارات على '
            'الجهاز وزر إعادة المحاولة.',
        ],
    },
    {
        'folder': 'booking-agent',
        'title': 'واجهة وكيل الحجوزات',
        'intro': 'أدوات الوكيل لإدارة عملائه وحجوزاته وعمولاته.',
        'points': [
            'قائمة العملاء وإنشاء حجز باسم العميل.',
            'متابعة العمولات وطلب تحويلها.',
            'الوصول إلى «ضيافاتي» بالحجوزات التي أنشأها الوكيل.',
        ],
    },
    {
        'folder': 'hotel-staff',
        'title': 'واجهة موظف الفندق',
        'intro': 'لوحة التشغيل اليومية للفندق: الوصول والمغادرة والطلبات '
                 'والتسعير.',
        'points': [
            'لوحة الفندق مع بطاقات قابلة للنقر لكل قسم.',
            'الوصولات مع بحث فوري بالاسم أو رقم الوحدة.',
            'المغادرات مع بحث برقم الغرفة أو الوحدة يعرض بيانات الضيف '
            'وموعد المغادرة.',
            'الحجوزات وتسجيل الدخول والخروج.',
            'أسعار الفندق والوحدات والوجبات.',
            'طلبات الفندق، وتأكيد طلب التنظيف مع عرض السعر المعتمد وخيارَي '
            'الدفع: خصم من الرصيد أو رابط دفع عبر واتساب.',
        ],
    },
    {
        'folder': 'owner-employee',
        'title': 'واجهة موظف المالك',
        'intro': 'واجهة مخصّصة لموظف المالك تعمل بصلاحيات محددة يمنحها المالك.',
        'points': [
            'تنقّل مبني على الصلاحيات الممنوحة فقط.',
            'إخفاء الأقسام المالية عن الموظف غير المصرّح له.',
            'تنفيذ الطلبات المسموح بها دون تجاوز حدّه.',
        ],
    },
]

ACTIVATION_TITLE = 'ملاحظات التفعيل والتشغيل'
ACTIVATION_LEAD = ('هذه ملاحظات تشغيلية بلغة واضحة، تبين ما يعمل اليوم وما '
                   'يحتاج قرارًا أو تفعيلًا من مزوّد الخدمة.')
ACTIVATION_NOTES = [
    ('تسجيل الدخول والحجوزات',
     'تعمل ضمن خدمة الحجوزات المشغّلة لحسابكم. أي حجز يظهر في التطبيق هو حجز '
     'حقيقي مسجّل لدى الخدمة، ولا يُنشئ التطبيق حجزًا وهميًا.'),
    ('وسائل الدفع',
     'وسيلتا «الدفع عند الوصول» و«التحويل إلى المالك» معطّلتان افتراضيًا، '
     'وتُفعّلان بقرار المشغّل من إعدادات الخدمة فقط. التطبيق يعرض الوسائل '
     'المفعّلة فعلًا ولا يقبل وسيلة معطّلة.'),
    ('الإشعارات',
     'تصل الإشعارات بعد تفعيل خدمة الإشعارات لحسابكم؛ وإلى أن يتم ذلك يعرض '
     'التطبيق حالة الإشعارات على الجهاز بصدق مع زر إعادة المحاولة، بدل '
     'الادّعاء بأنها تعمل.'),
    ('حذف الحساب',
     'الشاشة جاهزة داخل التطبيق، ويكتمل الحذف عند تفعيل خدمة الحذف من مزوّد '
     'الخدمة؛ ويبقى مسار الحذف عبر الموقع متاحًا كبديل دائم.'),
    ('روابط الدفع',
     'روابط الدفع في تسوية الطلبات تُنشأ من مزوّد الخدمة. التطبيق لا يصنع '
     'رابطًا ولا مبلغًا من عنده، ولا يؤكد دفعًا لم يصل.'),
]

SLUG_AR = {
    'home-section-order': 'ترتيب أقسام الرئيسية',
    'booking-extra-bed-hotel': 'السرير الإضافي — حجز فندق',
    'booking-extra-bed-summary': 'ملخص السعر مع السرير الإضافي',
    'booking-extra-bed-unit': 'السرير الإضافي — حجز وحدة',
    'arrivals-empty': 'الوصولات — لا نتائج',
    'arrivals-search': 'بحث الوصولات',
    'about-app': 'عن التطبيق',
    'agent-clients': 'عملاء الوكيل',
    'agent-commission': 'عمولة الوكيل',
    'agent-home': 'الرئيسية — وكيل الحجوزات',
    'agent-menu': 'قائمة وكيل الحجوزات',
    'arrivals': 'الوصولات',
    'availability-warning': 'تنبيه تاريخ غير متاح',
    'avatar-options': 'خيارات الصورة الشخصية',
    'booking': 'شاشة الحجز',
    'booking-final-price': 'السعر النهائي للحجز',
    'booking-guest-fields': 'بيانات الضيف في الحجز',
    'booking-hotel-units': 'وحدات الفندق في الحجز',
    'booking-meal-addons': 'إضافات الوجبات في الحجز',
    'booking-payment-methods': 'وسائل الدفع في الحجز',
    'booking-success': 'تأكيد الحجز',
    'booking-success-access': 'الدخول إلى الحجز بعد التأكيد',
    'commission-transfer-sheet': 'تحويل العمولة',
    'delete-account-blocked': 'حذف الحساب — موقوف لحجز قادم',
    'delete-account-done': 'حذف الحساب — تم',
    'delete-account-form': 'حذف الحساب',
    'departures-search': 'بحث المغادرات',
    'edit-booking-sheet': 'تعديل الحجز',
    'employee-navigation': 'تنقّل موظف المالك',
    'employee-staff-navigation': 'تنقّل الموظفين',
    'staff-navigation': 'قائمة الموظفين',
    'owner-nav': 'تنقّل المالك',
    'owner-navigation': 'لوحة تنقّل المالك',
    'main-navigation': 'التنقّل الرئيسي',
    'extra-bed': 'السرير الإضافي',
    'favorites-empty': 'المفضلة — فارغة',
    'help-support': 'المساعدة والدعم',
    'home': 'الرئيسية',
    'home-logo': 'الرئيسية — الشعار',
    'home-sections': 'أقسام الرئيسية',
    'hotel-bookings': 'حجوزات الفندق',
    'hotel-checkin-out': 'تسجيل الدخول والخروج',
    'hotel-dashboard': 'لوحة إدارة الفندق',
    'hotel-details': 'تفاصيل الفندق',
    'hotel-prices': 'أسعار الفندق',
    'hotel-request-actions': 'إجراءات طلبات الفندق',
    'hotel-service-prices': 'أسعار خدمات الفندق',
    'hotel-unit-search': 'البحث برقم الوحدة',
    'housekeeping-payment-options': 'خيارات دفع طلب التنظيف',
    'maintenance-settlement': 'تسوية طلب الصيانة',
    'meal-pricing': 'تسعير الوجبات',
    'meal-request': 'طلب وجبة',
    'my-bookings': 'ضيافاتي',
    'my-bookings-actions': 'إجراءات ضيافاتي',
    'my-requests': 'طلباتي',
    'onboarding': 'شاشات التعريف',
    'owner-bank': 'الحساب البنكي للمالك',
    'owner-booking-addons': 'إضافات الحجز',
    'owner-booking-details': 'تفاصيل الحجز',
    'owner-bookings': 'حجوزات المالك',
    'owner-cleaning': 'طلبات التنظيف',
    'owner-cleaning-new': 'طلب تنظيف جديد',
    'owner-extra-bed': 'السرير الإضافي — المالك',
    'owner-extra-bed-request': 'طلب سرير إضافي',
    'owner-home': 'الرئيسية — المالك',
    'owner-maintenance': 'طلبات الصيانة',
    'owner-meal-new': 'طلب وجبة جديد',
    'owner-meal-requests': 'طلبات الوجبات',
    'owner-notification-body': 'نص الإشعار',
    'owner-notifications': 'الإشعارات',
    'owner-request-to-hotel': 'طلب موجّه إلى الفندق',
    'owner-revenue': 'الإيرادات',
    'owner-service-prices': 'أسعار الخدمات',
    'owner-staff': 'الموظفون',
    'owner-subscription': 'الاشتراك',
    'owner-transfer': 'التحويل إلى المالك',
    'owner-unit-revenue': 'إيراد الوحدة',
    'owner-units': 'وحداتي',
    'owner-wallet': 'المحفظة',
    'payouts': 'المستحقات',
    'profile': 'الملف الشخصي',
    'profile-delete-entry': 'حذف الحساب من الملف الشخصي',
    'requests-cleaning': 'طلبات التنظيف — الفندق',
    'requests-meal': 'طلبات الوجبات — الفندق',
    'reset-password': 'استعادة كلمة المرور',
    'search-city': 'البحث بحسب المدينة',
    'search-empty': 'البحث — لا نتائج',
    'search-error': 'البحث — تعذّر التحميل',
    'search-results': 'نتائج البحث',
    'service-request': 'طلب خدمة',
    'staff-permissions-sheet': 'صلاحيات الموظف',
    'stay-details-sheet': 'عرض تفاصيل ضيافتي',
    'subscription': 'الاشتراك',
    'unit-details': 'تفاصيل الوحدة',
    'unit-pricing': 'تسعير الوحدة',
    'unit-service-categories': 'تصنيفات خدمات الوحدة',
    'wallet-balance': 'رصيد المحفظة',
}

LANG_AR = {'arabic': 'واجهة عربية', 'english': 'واجهة إنجليزية'}

ID_PREFIX = re.compile(r'^(?:DOC\d+-(?:REQ|EXTRA|POLICY)-)+')
REQ_TOKEN = re.compile(r'^(?:[A-Z]-\d{3}|\d+(?:-\d+)?)-')

MAX_RATIO = 4.5  # أطول من ذلك يُقسَّم نصفين حتى يبقى مقروءًا


def _slug(name):
    stem = re.sub(r'-(ar|en)$', '', name[:-4])
    stem = ID_PREFIX.sub('', stem)
    while True:
        cleaned = REQ_TOKEN.sub('', stem)
        if cleaned == stem:
            break
        stem = cleaned
    return stem


def _slice(path, ratio):
    """يقسّم الصورة الطويلة إلى نصفين متتاليين بمقاس صفحة معقول."""
    os.makedirs(SLICE_DIR, exist_ok=True)
    stem = os.path.splitext(os.path.basename(path))[0]
    with Image.open(path) as im:
        width, height = im.size
        overlap = int(height * 0.012)
        half = height // 2
        boxes = [(0, 0, width, half + overlap),
                 (0, half - overlap, width, height)]
        out = []
        for i, box in enumerate(boxes, 1):
            dest = os.path.join(SLICE_DIR, f'{stem}-part{i}.png')
            im.crop(box).save(dest)
            out.append(dest)
    return out


def shots():
    rows = []
    for path in glob.glob(os.path.join(GOLD, '**', '*.png'), recursive=True):
        rel = os.path.relpath(path, GOLD)
        hires = os.path.join(HIRES, rel)
        parts = rel.split(os.sep)
        lang = parts[1] if len(parts) > 2 else ''
        slug = _slug(parts[-1])
        src = hires if os.path.exists(hires) else path
        with Image.open(src) as im:
            ratio = im.size[1] / im.size[0]
        if ratio > MAX_RATIO:
            files = _slice(src, ratio)
            for i, part in enumerate(files):
                with Image.open(part) as im:
                    r = im.size[1] / im.size[0]
                rows.append({
                    'folder': parts[0], 'lang': lang, 'slug': slug,
                    'title': SLUG_AR.get(slug, slug.replace('-', ' ').title()),
                    'path': part, 'ratio': r,
                    'cont': ' (تكملة)' if i else '',
                })
        else:
            rows.append({
                'folder': parts[0], 'lang': lang, 'slug': slug,
                'title': SLUG_AR.get(slug, slug.replace('-', ' ').title()),
                'path': src, 'ratio': ratio, 'cont': '',
            })
    order = [s['folder'] for s in SECTIONS]
    rows.sort(key=lambda r: (order.index(r['folder'])
                             if r['folder'] in order else 99,
                             r['folder'], 0 if r['lang'] == 'arabic' else 1,
                             r['slug'], r['cont'], r['path']))
    return rows


def section_shots(rows, folder):
    return [r for r in rows if r['folder'] == folder]


def screen_count(rows, folder=None):
    pool = rows if folder is None else section_shots(rows, folder)
    return len([r for r in pool if not r['cont']])
