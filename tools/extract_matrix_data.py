"""يستخرج بيانات المتطلبات الـ148 من المصفوفة الملتزمة إلى وحدة بيانات صريحة.

يُشغَّل مرة واحدة عند إعادة الهيكلة: النتيجة `tools/matrix_data.py` تصبح المصدر
الوحيد الذي يقرأه `gen_requirements_matrix.py`.
"""
import re

SRC = 'docs/ALL_OWNERS_REQUIREMENTS_MATRIX.md'
DST = 'tools/matrix_data.py'

txt = open(SRC, encoding='utf-8').read()
blocks = re.split(r'^### ', txt, flags=re.M)[1:]

rows = {}
for b in blocks:
    m = re.match(r'(\d+)\.\s', b)
    if not m:
        continue
    i = int(m.group(1))

    def g(k):
        mm = re.search(r'\*\*' + k + r':\*\*\s*(.*)', b)
        return mm.group(1).strip() if mm else ''

    ex = int(re.search(r'Execution 0(\d)', g('التنفيذ')).group(1))
    rows[i] = (ex, g('الحالة'), g('ملفات Flutter'), g('اعتماد الـ API'),
               g('الدليل'), g('المتبقي'), g('معيار القبول'))

assert len(rows) == 148, len(rows)


def q(s):
    return "'" + s.replace("\\", "\\\\").replace("'", "\\'") + "'"


lines = [
    '# -*- coding: utf-8 -*-',
    '"""بيانات المتطلبات الـ148 — مصدر وحيد يولّد المصفوفة.',
    '',
    'مُستخرَجة من المصفوفة المعتمدة. عدّل هذا الملف لا المصفوفة مباشرة، ثم شغّل',
    '`python3 tools/gen_requirements_matrix.py` لإعادة التوليد.',
    '"""',
    '',
    'ENTRIES = {',
]
for i in range(1, 149):
    ex, st, fl, api, ev, out, acc = rows[i]
    lines.append(f'    {i}: ({ex}, {q(st)}, {q(fl)}, {q(api)}, {q(ev)}, {q(out)}, {q(acc)}),')
lines.append('}')
lines.append('')

open(DST, 'w', encoding='utf-8').write('\n'.join(lines))
print('wrote', DST, len(rows), 'entries')
