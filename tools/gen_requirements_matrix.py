#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""يولّد مصفوفة التتبّع الكاملة (148 متطلبًا) من مصدرين:

1. `docs/AllOwners_Requirements_Inventory.md` — الأوصاف العربية الرسمية.
2. `tools/matrix_data.py` — بيانات التحليل (التنفيذ/الحالة/الملفات/الاعتماد/
   الدليل/المتبقي/معيار القبول) لكل متطلب.

لا يخترع أي نص. لتصحيح حالة متطلب: عدّل `tools/matrix_data.py` ثم شغّل هذا
الملف. لا تُحرّر المصفوفة المولَّدة يدويًا — كان ذلك سبب تناقض التقارير.
"""
import os
import re
import sys
from collections import Counter

_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(_ROOT, 'tools'))

from matrix_data import ENTRIES  # noqa: E402

INVENTORY = os.path.join(_ROOT, "docs/AllOwners_Requirements_Inventory.md")
OUTPUT = os.path.join(_ROOT, "docs/ALL_OWNERS_REQUIREMENTS_MATRIX.md")

STATUS_ORDER = (
    'VERIFIED PASS',
    'INTEGRATION VERIFIED',
    'IMPLEMENTED UNTESTED',
    'PARTIAL',
    'NOT IMPLEMENTED',
    'BACKEND BLOCKED',
    'OWNER DECISION REQUIRED',
)


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


def main():
    items, _ = load_inventory()
    assert len(items) == 148, f'expected 148 got {len(items)}'
    missing = [n for n in range(1, 149) if n not in items]
    assert not missing, f'missing {missing}'
    assert len(ENTRIES) == 148, f'ENTRIES expected 148 got {len(ENTRIES)}'
    no_meta = [n for n in range(1, 149) if n not in ENTRIES]
    assert not no_meta, f'no analysis data for {no_meta}'

    rows = []
    for i in range(1, 149):
        text, section = items[i]
        ex, status, files, api, ev, out, acc = ENTRIES[i]
        assert status in STATUS_ORDER, f'{i}: unknown status {status!r}'
        rows.append((i, text, section, ex, status, files, api, ev, out, acc))

    ex_counts = Counter(r[3] for r in rows)
    st_counts = Counter(r[4] for r in rows)

    lines = []
    lines.append('# All Owners — مصفوفة تتبّع المتطلبات الكاملة (148 متطلبًا)\n')
    lines.append('**الفرع:** `feature/allowners-new-version-exec01`  ')
    lines.append('**المصدر:** `docs/AllOwners_Requirements_Inventory.md` (الحصر الرسمي المُقدَّم من المالك، 148 متطلبًا)  ')
    lines.append('**المستند الأصلي:** `docs/AllOwners_Original_Under_3MB.docx` (51 صفحة)  ')
    lines.append('**مُولَّد آليًا:** `python3 tools/gen_requirements_matrix.py` من `tools/matrix_data.py` — لا تُحرّره يدويًا.  ')
    lines.append('**نطاق التنفيذ 01:** الرئيسية، البحث، اكتشاف الفنادق، تجربة الوحدة، نظام التصميم، المرافق\n')
    lines.append('> كل وصف عربي في هذا الملف مأخوذ حرفيًا من ملف الحصر الرسمي. لا توجد أوصاف مُختلقة.  ')
    lines.append('> «VERIFIED PASS» تعني: الكود موجود + مربوط بـ API حيّ + مُتحقَّق منه (اختبار وحدات أو استجابة API فعلية).  ')
    lines.append('> «INTEGRATION VERIFIED» تعني: مسار الخدمة وعقد الـ API مُثبتان باختبار تكامل حيّ ضد all-owner.online، لكن العرض البصري على جهاز لم يُتحقق منه بعد.  ')
    lines.append('> «IMPLEMENTED UNTESTED» تعني: الكود مكتمل ومربوط لكن لم يُختبر على جهاز حقيقي.  ')
    lines.append('> «PARTIAL» تعني: جانب التطبيق مكتمل ومُختبَر، والمتبقي عمل سيرفر/مزوّد دفع.  ')
    lines.append('> «BACKEND BLOCKED» تعني: يحتاج تعديل PHP/قاعدة البيانات على السيرفر (خارج نطاق التطبيق).\n')
    lines.append('## ملخّص\n')
    lines.append('| المقياس | القيمة |')
    lines.append('|---|---|')
    lines.append(f'| إجمالي المتطلبات | {len(rows)} |')
    for ex in (1, 2, 3, 4, 5):
        lines.append(f'| مُعيَّن للتنفيذ 0{ex} | {ex_counts.get(ex, 0)} |')
    lines.append(f'| الإجمالي المُتحقَّق | {sum(ex_counts.values())} |')
    lines.append('')
    lines.append('| الحالة | العدد |')
    lines.append('|---|---|')
    for st in STATUS_ORDER:
        lines.append(f'| {st} | {st_counts.get(st, 0)} |')
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

    open(OUTPUT, 'w', encoding='utf-8').write('\n'.join(lines) + '\n')
    print('wrote', len(rows), 'rows ->', OUTPUT)
    print('exec counts:', dict(sorted(ex_counts.items())))
    print('status counts:', dict(st_counts))


if __name__ == '__main__':
    main()
