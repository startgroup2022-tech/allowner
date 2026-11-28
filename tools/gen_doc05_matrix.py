#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""يولّد مصفوفة المستند 05 المستقلة (148 متطلبًا) — صف واحد لكل متطلب.

المصادر:
  1. `docs/AllOwners_Requirements_Inventory.md` — النص العربي الرسمي.
  2. `tools/matrix_data.py` — بيانات التحليل (الحالة/الملفات/الاعتماد/الدليل).

المخرج: `docs/MATRIX_DOCUMENT_05.md`

مستقل عن `ALL_OWNERS_REQUIREMENTS_MATRIX.md` (الذي يعرض تفاصيل مطوّلة): هذا
الملف جدول تتبّع كثيف + تدقيق الإسناد إلى المستند الأصلي.
"""
import os
import re
import sys
from collections import Counter, OrderedDict

_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(_ROOT, 'tools'))

from matrix_data import ENTRIES  # noqa: E402

INVENTORY = os.path.join(_ROOT, 'docs/AllOwners_Requirements_Inventory.md')
OUTPUT = os.path.join(_ROOT, 'docs/MATRIX_DOCUMENT_05.md')

STATUS_ORDER = (
    'VERIFIED PASS',
    'INTEGRATION VERIFIED',
    'FLUTTER COMPLETE — BACKEND PENDING',
    'IMPLEMENTED UNTESTED',
    'PARTIAL',
    'NOT IMPLEMENTED',
    'BACKEND BLOCKED',
    'OWNER DECISION REQUIRED',
)

EVIDENCE_DIR = 'docs/evidence/final-acceptance'


def load_inventory():
    items, sections = {}, []
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


def screenshots_for(number):
    """لقطات الأدلة المُسمّاة بهذا المتطلب، إن وُجدت."""
    found = []
    for root, _dirs, files in os.walk(os.path.join(_ROOT, EVIDENCE_DIR)):
        for name in files:
            if not name.endswith('.png'):
                continue
            m = re.match(r'DOC05-REQ-(\d+)(?:-(\d+))?-', name)
            if not m:
                continue
            low, high = int(m.group(1)), int(m.group(2) or m.group(1))
            if low <= number <= high:
                found.append(os.path.relpath(os.path.join(root, name), _ROOT))
    return sorted(found)


def main():
    items, sections = load_inventory()
    assert len(items) == 148, f'expected 148 inventory rows, got {len(items)}'
    assert len(ENTRIES) == 148, f'expected 148 analysis rows, got {len(ENTRIES)}'

    rows = []
    for i in range(1, 149):
        text, section = items[i]
        group, status, files, api, evidence, remaining, acceptance = ENTRIES[i]
        assert status in STATUS_ORDER, f'{i}: unknown status {status!r}'
        shots = screenshots_for(i)
        rows.append(
            {
                'n': i,
                'text': text,
                'section': section,
                'group': group,
                'status': status,
                'files': files,
                'api': api,
                'evidence': evidence,
                'remaining': remaining,
                'acceptance': acceptance,
                'shots': shots,
            }
        )

    status_counts = Counter(r['status'] for r in rows)
    group_counts = Counter(r['group'] for r in rows)

    # تدقيق الإسناد: نص الحصر لا يحمل رقم صفحة، فكل المتطلبات بلا إسناد صفحة.
    without_page = [r['n'] for r in rows]
    # المتطلبات التي لا تذكر أدلتها اختبارًا ولا لقطة.
    without_test_or_shot = [
        r['n']
        for r in rows
        if 'اختبار' not in r['evidence'] and not r['shots']
    ]
    without_shot = [r['n'] for r in rows if not r['shots']]

    lines = []
    add = lines.append
    add('# All Owners — مصفوفة المستند 05 (148 متطلبًا)\n')
    add('**الفرع:** `feature/allowners-new-version-exec01`  ')
    add('**المستند:** التعديلات التطبيق-5 (`docs/AllOwners_Original_Under_3MB.docx`، 51 صفحة)  ')
    add('**النص الرسمي:** `docs/AllOwners_Requirements_Inventory.md`  ')
    add('**مُولَّد آليًا:** `python3 tools/gen_doc05_matrix.py` من `tools/matrix_data.py` — لا تُحرّره يدويًا.  ')
    add('**المصفوفة التفصيلية:** `docs/ALL_OWNERS_REQUIREMENTS_MATRIX.md` (نفس المصدر، شرح أطول لكل متطلب).\n')
    add('> هذا الملف مصفوفة تتبّع مستقلة للمستند 05 وحده. متطلبات المستند 06 لها ')
    add('> ملف مستقل: `docs/MATRIX_DOCUMENT_06.md`، فلا تُخلط المجموعتان في عدّ واحد.\n')

    add('## 1. الملخّص\n')
    add('| المقياس | القيمة |')
    add('|---|---|')
    add(f'| إجمالي متطلبات المستند 05 | {len(rows)} |')
    for g in (1, 2, 3, 4, 5):
        add(f'| مجموعة التنفيذ 0{g} | {group_counts.get(g, 0)} |')
    add(f'| متطلبات لها لقطة شاشة | {len(rows) - len(without_shot)} |')
    add(f'| متطلبات بلا لقطة شاشة | {len(without_shot)} |')
    add('')
    add('| الحالة | العدد |')
    add('|---|---|')
    for st in STATUS_ORDER:
        if status_counts.get(st):
            add(f'| {st} | {status_counts[st]} |')
    add('')

    add('## 2. المصفوفة\n')
    add('| # | المتطلب | القسم | المجموعة | الحالة | اعتماد الـ API | دليل (اختبار/لقطة) |')
    add('|---|---|---|---|---|---|---|')
    for r in rows:
        evidence = r['evidence']
        if len(evidence) > 180:
            evidence = evidence[:177] + '…'
        evidence = evidence.replace('|', '\\|')
        shots = r['shots']
        shot_note = f' — لقطة: `{os.path.basename(shots[0])}`' if shots else ''
        api = (r['api'] or '—').replace('|', '\\|')
        add(
            f"| {r['n']} | {r['text'].replace('|', chr(92) + '|')} | {r['section']} | "
            f"{r['group']} | {r['status']} | {api} | {evidence}{shot_note} |"
        )
    add('')

    add('## 3. تدقيق الإسناد إلى المستند الأصلي\n')
    add('### 3.1 متطلبات بلا إسناد صفحة\n')
    add(
        'الحصر الرسمي (`AllOwners_Requirements_Inventory.md`) يذكر النصوص كاملة '
        'لكنه **لا يذكر رقم الصفحة** لكل متطلب، والمستند الأصلي مُقدَّم كملف '
        '`.docx` غير مُفهرَس صفحة بصفحة في هذا المستودع. لذلك كل المتطلبات '
        f'({len(without_page)}) بلا إسناد صفحة، ولا نُدّعي غير ذلك.'
    )
    add('')
    add('### 3.2 متطلبات لا تذكر أدلتها اختبارًا ولا لقطة شاشة\n')
    if without_test_or_shot:
        add('| # | المتطلب | الحالة |')
        add('|---|---|---|')
        for n in without_test_or_shot:
            r = rows[n - 1]
            add(f"| {n} | {r['text']} | {r['status']} |")
    else:
        add('لا يوجد: كل متطلب يذكر اختبارًا أو له لقطة شاشة.')
    add('')
    add('### 3.3 متطلبات محجوبة على السيرفر\n')
    blocked = [r for r in rows if r['status'] == 'BACKEND BLOCKED']
    if blocked:
        add('| # | المتطلب | المتبقي |')
        add('|---|---|---|')
        for r in blocked:
            add(
                f"| {r['n']} | {r['text']} | {r['remaining'].replace('|', chr(92) + '|')} |"
            )
    else:
        add('لا يوجد.')
    add('')
    add('## 4. كيف تُعاد هذه النتائج\n')
    add('```bash')
    add('python3 tools/gen_doc05_matrix.py     # هذا الملف')
    add('python3 tools/gen_doc06_matrix.py     # مصفوفة المستند 06')
    add('python3 tools/gen_requirements_matrix.py  # المصفوفة التفصيلية')
    add('```')
    add('')

    open(OUTPUT, 'w', encoding='utf-8').write('\n'.join(lines) + '\n')
    print('wrote', OUTPUT, 'rows:', len(rows))
    print('status:', dict(status_counts))
    print('without screenshot:', len(without_shot))


if __name__ == '__main__':
    main()
