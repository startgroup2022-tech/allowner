#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""يولّد مصفوفة المستند 06 المستقلة.

المصدر: `tools/doc06_matrix_data.py`
المخرج: `docs/MATRIX_DOCUMENT_06.md`

يتحقق قبل الكتابة من:
  • أن كل حالة من الحالات الثلاث المعتمدة؛
  • أن كل ملف Flutter مذكور موجود فعلًا؛
  • أن كل اختبار مذكور موجود فعلًا؛
  • أن كل لقطة مذكورة موجودة فعلًا.

بهذا لا تتحوّل المصفوفة إلى ادّعاء: أي مسار خاطئ يُوقف التوليد.
"""
import os
import re
import sys
from collections import Counter

_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(_ROOT, 'tools'))

from doc06_matrix_data import ENTRIES, NO_ORIGINAL_TEXT  # noqa: E402

OUTPUT = os.path.join(_ROOT, 'docs/MATRIX_DOCUMENT_06.md')
EVIDENCE = os.path.join(_ROOT, 'docs/evidence/final-acceptance')

ALLOWED = (
    'COMPLETE AND VERIFIED',
    'FLUTTER COMPLETE — BACKEND PENDING',
    'INCOMPLETE',
)

PATH_RE = re.compile(r'`?(lib/[A-Za-z0-9_./*\-]+|test/[A-Za-z0-9_.\-]+\.dart)`?')


def missing_paths(text):
    missing = []
    for raw in PATH_RE.findall(text):
        path = raw.strip('`').rstrip('.')
        if path.endswith('*'):
            directory = os.path.join(_ROOT, os.path.dirname(path))
            if not os.path.isdir(directory):
                missing.append(path)
            continue
        if not os.path.exists(os.path.join(_ROOT, path)):
            missing.append(path)
    return missing


def missing_shots(text):
    missing = []
    for shot in [s.strip() for s in text.split(',')]:
        if not shot or shot == '—':
            continue
        if not os.path.exists(os.path.join(EVIDENCE, shot)):
            missing.append(shot)
    return missing


def main():
    problems = []
    for entry in ENTRIES:
        ident, _ar, _en, _group, status, files, tests, shots, _backend, _note = entry
        if status not in ALLOWED:
            problems.append(f'{ident}: status {status!r} not allowed')
        for path in missing_paths(files) + missing_paths(tests):
            problems.append(f'{ident}: missing path {path}')
        for shot in missing_shots(shots):
            problems.append(f'{ident}: missing screenshot {shot}')
    if problems:
        for p in problems:
            print('ERROR', p)
        raise SystemExit(1)

    status_counts = Counter(e[4] for e in ENTRIES)
    group_counts = Counter(e[3] for e in ENTRIES)

    lines = []
    add = lines.append
    add('# All Owners — مصفوفة المستند 06\n')
    add('**الفرع:** `feature/allowners-new-version-exec01`  ')
    add('**المستند:** Modification Document 06 (المتطلبات 1–17 + الأقسام §A، §B، §D، §F)  ')
    add('**مُولَّد آليًا:** `python3 tools/gen_doc06_matrix.py` من `tools/doc06_matrix_data.py` — لا تُحرّره يدويًا.  ')
    add('**التفاصيل الكاملة:** `docs/DOCUMENT_06_GROUP_01.md`، `docs/DOCUMENT_06_GROUP_02.md`، ')
    add('`docs/DOCUMENT_06_FINAL_ACCEPTANCE.md`  ')
    add('**عقد الـ API:** `docs/API_HANDOVER_AUTHORITATIVE.md`\n')
    add('> كل صف يتحقق منه المولّد: الملفات والاختبارات واللقطات المذكورة يجب أن ')
    add('> تكون موجودة فعلًا، وإلا يفشل التوليد. متطلبات المستند 05 في ملف مستقل ')
    add('> (`docs/MATRIX_DOCUMENT_05.md`).\n')

    add('## 1. الملخّص\n')
    add('| المقياس | القيمة |')
    add('|---|---|')
    add(f'| إجمالي بنود المستند 06 | {len(ENTRIES)} |')
    for group, count in sorted(group_counts.items()):
        add(f'| {group} | {count} |')
    add('')
    add('| الحالة | العدد |')
    add('|---|---|')
    for status in ALLOWED:
        if status_counts.get(status):
            add(f'| {status} | {status_counts[status]} |')
    add('')

    add('## 2. المصفوفة\n')
    add('| # | المتطلب | المجموعة | الحالة | اختبار | لقطة |')
    add('|---|---|---|---|---|---|')
    for ident, ar, _en, group, status, _files, tests, shots, _backend, _note in ENTRIES:
        first_test = tests.split(',')[0].strip()
        first_shot = shots.split(',')[0].strip() if shots.strip() != '—' else '—'
        add(f'| {ident} | {ar} | {group} | {status} | {first_test} | {first_shot} |')
    add('')

    add('## 3. التفاصيل\n')
    for ident, ar, en, group, status, files, tests, shots, backend, note in ENTRIES:
        add(f'### {ident} — {ar}\n')
        add(f'- **English:** {en}')
        add(f'- **المجموعة:** {group}')
        add(f'- **الحالة:** {status}')
        add(f'- **ملفات Flutter:** {files}')
        add(f'- **الاختبارات:** {tests}')
        add(f'- **اللقطات:** {shots}')
        add(f'- **اعتماد السيرفر:** {backend}')
        add(f'- **ملاحظة:** {note}')
        add('')

    add('## 4. تدقيق الإسناد إلى المستند الأصلي\n')
    add('ملف المستند 06 الأصلي **ليس في هذا المستودع** (المستودع يحتوي المستند 05 فقط: ')
    add('`docs/AllOwners_Original_Under_3MB.docx`). لذلك النصوص العربية/الإنجليزية ')
    add('أعلاه مأخوذة من موجز المالك ومن التقارير السابقة، وليست نقلًا حرفيًا عن ')
    add('صفحات المستند 06.\n')
    add('البنود التي تنقصها إشارة إلى نص/صفحة أصلية:\n')
    for item in NO_ORIGINAL_TEXT:
        add(f'- {item}')
    add('')
    add('لإغلاق هذا النقص: إرفاق ملف المستند 06 الأصلي في `docs/` ثم إعادة التوليد ')
    add('مع إضافة رقم الصفحة لكل بند في `tools/doc06_matrix_data.py`.\n')

    add('## 5. إعادة التوليد\n')
    add('```bash')
    add('python3 tools/gen_doc06_matrix.py')
    add('python3 tools/gen_doc05_matrix.py')
    add('```')
    add('')

    open(OUTPUT, 'w', encoding='utf-8').write('\n'.join(lines) + '\n')
    print('wrote', OUTPUT, 'rows:', len(ENTRIES))
    print('status:', dict(status_counts))


if __name__ == '__main__':
    main()
