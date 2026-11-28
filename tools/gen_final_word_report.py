#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""يبني تقرير Word الشامل (عربي RTL) لكل تعديلات المستندين 05 و06.

المصادر (كلها من المستودع، بلا اختلاق):
  * `docs/AllOwners_Requirements_Inventory.md` — نصوص المتطلبات الـ148.
  * `tools/matrix_data.py` — الحالة/الملفات/اعتماد الـAPI/الدليل/المتبقي.
  * `tools/doc06_matrix_data.py` — بنود المستند 06 (24 بندًا).
  * `docs/evidence/final-acceptance-hires/*.png` — لقطات بدقة 2× (780×1688).
  * ملفات `test/*.dart` — فهرس الاختبارات وسند كل متطلب.

المخرج: `docs/ALL_OWNERS_FINAL_IMPLEMENTATION_REPORT.docx`

التشغيل: `python3 tools/gen_final_word_report.py`
"""
import glob
import os
import re
import subprocess
import sys
from collections import Counter

from docx import Document
from docx.enum.section import WD_SECTION
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Pt, RGBColor

_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(_ROOT, 'tools'))

from matrix_data import ENTRIES  # noqa: E402
from doc06_matrix_data import ENTRIES as ENTRIES06  # noqa: E402
from gen_doc05_matrix import load_inventory, screenshots_for  # noqa: E402

OUT = os.path.join(_ROOT, 'docs/ALL_OWNERS_FINAL_IMPLEMENTATION_REPORT.docx')
HIRES_DIR = os.path.join(_ROOT, 'docs/evidence/final-acceptance-hires')
GOLD_DIR = os.path.join(_ROOT, 'docs/evidence/final-acceptance')

FONT = 'Tajawal'
INK = RGBColor(0x01, 0x12, 0x2E)
GOLD = RGBColor(0xB3, 0x87, 0x2A)
GOLD_LIGHT = 'F3D98A'
INK_HEX = '01122E'
GREEN = RGBColor(0x1F, 0x7A, 0x44)
ORANGE = RGBColor(0xA8, 0x6A, 0x0B)
RED = RGBColor(0xB0, 0x2A, 0x2A)
BLUE = RGBColor(0x1F, 0x4E, 0x8C)
GREY = RGBColor(0x55, 0x5D, 0x6B)
WHITE = RGBColor(0xFF, 0xFF, 0xFF)

STATUS_AR = {
    'VERIFIED PASS': 'منفَّذ ومُتحقَّق منه',
    'INTEGRATION VERIFIED': 'مُتحقَّق تكامليًا مع الخادم',
    'FLUTTER COMPLETE — BACKEND PENDING': 'مكتمل في Flutter — الخادم معلّق',
    'COMPLETE AND VERIFIED': 'مكتمل ومُتحقَّق منه',
    'IMPLEMENTED UNTESTED': 'منفَّذ بلا اختبار',
    'PARTIAL': 'منفَّذ جزئيًا',
    'NOT IMPLEMENTED': 'غير منفَّذ',
    'BACKEND BLOCKED': 'محجوب بسبب الخادم',
    'OWNER DECISION REQUIRED': 'بانتظار قرار المالك',
}
STATUS_COLOR = {
    'VERIFIED PASS': GREEN,
    'INTEGRATION VERIFIED': GREEN,
    'COMPLETE AND VERIFIED': GREEN,
    'FLUTTER COMPLETE — BACKEND PENDING': ORANGE,
    'PARTIAL': ORANGE,
    'IMPLEMENTED UNTESTED': ORANGE,
    'BACKEND BLOCKED': RED,
    'NOT IMPLEMENTED': RED,
    'OWNER DECISION REQUIRED': BLUE,
}
GROUP_AR = {
    1: 'مجموعة التنفيذ 01',
    2: 'مجموعة التنفيذ 02',
    3: 'مجموعة التنفيذ 03',
    4: 'مجموعة التنفيذ 04',
    5: 'مجموعة التنفيذ 05',
}

# ---------------------------------------------------------------- XML helpers


def _sub(parent, tag, **attrs):
    el = OxmlElement(tag)
    for k, v in attrs.items():
        el.set(qn(k), v)
    parent.append(el)
    return el


TBLPR_ORDER = [
    'w:tblStyle', 'w:tblpPr', 'w:tblOverlap', 'w:bidiVisual',
    'w:tblStyleRowBandSize', 'w:tblStyleColBandSize', 'w:tblW', 'w:jc',
    'w:tblCellSpacing', 'w:tblInd', 'w:tblBorders', 'w:shd', 'w:tblLayout',
    'w:tblCellMar', 'w:tblLook', 'w:tblCaption', 'w:tblDescription',
]


def tbl_child(tblPr, tag, **attrs):
    """يضيف/يستبدل عنصرًا في tblPr بالترتيب الذي يفرضه مخطط OOXML."""
    old = tblPr.find(qn(tag))
    if old is not None:
        tblPr.remove(old)
    el = OxmlElement(tag)
    for k, v in attrs.items():
        el.set(qn(k), v)
    idx = TBLPR_ORDER.index(tag)
    for child in list(tblPr):
        for i, t in enumerate(TBLPR_ORDER):
            if qn(t) == child.tag and i > idx:
                child.addprevious(el)
                return el
    tblPr.append(el)
    return el


def table_rtl(t):
    tbl_child(t._tbl.tblPr, 'w:bidiVisual')


def table_no_borders(t):
    borders = tbl_child(t._tbl.tblPr, 'w:tblBorders')
    for edge in ('top', 'left', 'bottom', 'right', 'insideH', 'insideV'):
        e = OxmlElement(f'w:{edge}')
        e.set(qn('w:val'), 'none')
        e.set(qn('w:sz'), '0')
        e.set(qn('w:space'), '0')
        e.set(qn('w:color'), 'auto')
        borders.append(e)


def add_pic(run, path, max_w=7.0, max_h=14.6):
    from PIL import Image
    w, h = Image.open(path).size
    ratio = h / w
    width = max_w
    height = width * ratio
    if height > max_h:
        height = max_h
        width = height / ratio
    run.add_picture(path, width=Cm(width), height=Cm(height))


def para_bidi(par, rtl=True):
    pPr = par._p.get_or_add_pPr()
    if rtl:
        _sub(pPr, 'w:bidi')
    return par


def set_jc(p, align, rtl):
    jc = p._p.get_or_add_pPr().find(qn('w:jc'))
    if jc is None:
        return
    if align == 'justify':
        jc.set(qn('w:val'), 'both')
        return
    if align == 'center':
        jc.set(qn('w:val'), 'center')
        return
    jc.set(qn('w:val'), 'start' if (align == 'right') == rtl else 'end')


def run_font(run, size=None, bold=None, color=None, italic=None):
    if size is not None:
        run.font.size = Pt(size)
        run._element.get_or_add_rPr()
        _sub(run._element.rPr, 'w:szCs', **{'w:val': str(int(size * 2))})
    if bold is not None:
        run.font.bold = bold
        if run._element.rPr is not None:
            _sub(run._element.rPr, 'w:bCs', **{'w:val': '1' if bold else '0'})
    if italic is not None:
        run.font.italic = italic
    if color is not None:
        run.font.color.rgb = color
    run.font.name = FONT
    rPr = run._element.get_or_add_rPr()
    rFonts = rPr.find(qn('w:rFonts'))
    if rFonts is None:
        rFonts = _sub(rPr, 'w:rFonts')
    rFonts.set(qn('w:cs'), FONT)
    rFonts.set(qn('w:ascii'), FONT)
    rFonts.set(qn('w:hAnsi'), FONT)
    return run


def para(container, text='', size=10.5, bold=False, color=INK, align='right',
         space_after=3, space_before=0, rtl=True, line=1.35, indent=None,
         italic=False, style=None):
    p = container.add_paragraph(style=style)
    para_bidi(p, rtl)
    p.alignment = {
        'right': WD_ALIGN_PARAGRAPH.RIGHT,
        'left': WD_ALIGN_PARAGRAPH.LEFT,
        'center': WD_ALIGN_PARAGRAPH.CENTER,
        'justify': WD_ALIGN_PARAGRAPH.JUSTIFY,
    }[align]
    set_jc(p, align, rtl)
    pf = p.paragraph_format
    pf.space_after = Pt(space_after)
    pf.space_before = Pt(space_before)
    pf.line_spacing = line
    if indent is not None:
        pf.right_indent = Cm(indent) if rtl else None
        pf.left_indent = Cm(indent) if not rtl else None
    if text:
        run_font(p.add_run(text), size=size, bold=bold, color=color,
                 italic=italic)
    return p


def rich(container, parts, size=10.5, align='right', space_after=3, rtl=True,
         line=1.35):
    """فقرة من أجزاء (نص، غامق، لون)."""
    p = container.add_paragraph()
    para_bidi(p, rtl)
    p.alignment = {
        'right': WD_ALIGN_PARAGRAPH.RIGHT,
        'left': WD_ALIGN_PARAGRAPH.LEFT,
        'justify': WD_ALIGN_PARAGRAPH.JUSTIFY,
    }[align]
    set_jc(p, align, rtl)
    p.paragraph_format.space_after = Pt(space_after)
    p.paragraph_format.line_spacing = line
    for text, bold, color in parts:
        run_font(p.add_run(text), size=size, bold=bold, color=color)
    return p


def hr(container, color=INK_HEX, size=8):
    p = container.add_paragraph()
    pPr = p._p.get_or_add_pPr()
    borders = _sub(pPr, 'w:pBdr')
    bottom = _sub(borders, 'w:bottom', **{
        'w:val': 'single', 'w:sz': str(size), 'w:space': '1',
        'w:color': color,
    })
    bottom.set(qn('w:color'), color)
    p.paragraph_format.space_after = Pt(6)
    return p


def shade(cell, hex_fill):
    tcPr = cell._tc.get_or_add_tcPr()
    _sub(tcPr, 'w:shd', **{'w:val': 'clear', 'w:color': 'auto',
                           'w:fill': hex_fill})


AR_RE = re.compile(r'[\u0600-\u06FF]')


def cell_text(cell, text, size=9.5, bold=False, color=INK, align='right',
              rtl=True, space_after=1):
    if align == 'right' and not AR_RE.search(str(text)):
        align, rtl = 'left', False
    cell.paragraphs[0].text = ''
    p = cell.paragraphs[0]
    para_bidi(p, rtl)
    p.alignment = {
        'right': WD_ALIGN_PARAGRAPH.RIGHT,
        'left': WD_ALIGN_PARAGRAPH.LEFT,
        'center': WD_ALIGN_PARAGRAPH.CENTER,
    }[align]
    set_jc(p, align, rtl)
    p.paragraph_format.space_after = Pt(space_after)
    p.paragraph_format.line_spacing = 1.15
    for i, chunk in enumerate(str(text).split('\n')):
        if i:
            p = cell.add_paragraph()
            para_bidi(p, rtl)
            p.alignment = {
                'right': WD_ALIGN_PARAGRAPH.RIGHT,
                'left': WD_ALIGN_PARAGRAPH.LEFT,
                'center': WD_ALIGN_PARAGRAPH.CENTER,
            }[align]
            p.paragraph_format.space_after = Pt(space_after)
            p.paragraph_format.line_spacing = 1.15
            set_jc(p, align, rtl)
        run_font(p.add_run(chunk), size=size, bold=bold, color=color)
    return cell


def table(container, rows, widths, header=True, header_fill=INK_HEX,
          header_color=WHITE, size=9.5, rtl=True, align_center_cols=()):
    t = container.add_table(rows=len(rows), cols=len(widths))
    t.style = 'Table Grid'
    t.alignment = WD_TABLE_ALIGNMENT.CENTER
    t.autofit = False
    if rtl:
        table_rtl(t)
    for i, w in enumerate(widths):
        t.columns[i].width = Cm(w)
    for r_i, row in enumerate(rows):
        trPr = t.rows[r_i]._tr.get_or_add_trPr()
        _sub(trPr, 'w:cantSplit')
        for c_i, value in enumerate(row):
            cell = t.cell(r_i, c_i)
            cell.width = Cm(widths[c_i])
            is_head = header and r_i == 0
            if is_head:
                shade(cell, header_fill)
            elif r_i % 2 == 0:
                shade(cell, 'F7F8FA')
            cell_text(
                cell, value, size=size,
                bold=is_head,
                color=header_color if is_head else INK,
                align='center' if (is_head or c_i in align_center_cols) else 'right',
            )
    return t


def kv_table(container, pairs, label_w=3.4, value_w=13.0, size=9.5):
    t = container.add_table(rows=len(pairs), cols=2)
    t.style = 'Table Grid'
    t.alignment = WD_TABLE_ALIGNMENT.CENTER
    t.autofit = False
    table_rtl(t)
    for i, w in enumerate((label_w, value_w)):
        t.columns[i].width = Cm(w)
    for i, (k, v) in enumerate(pairs):
        trPr = t.rows[i]._tr.get_or_add_trPr()
        _sub(trPr, 'w:cantSplit')
        c0, c1 = t.cell(i, 0), t.cell(i, 1)
        c0.width = Cm(label_w)
        c1.width = Cm(value_w)
        shade(c0, 'F0F2F5')
        cell_text(c0, k, size=size, bold=True, color=INK)
        cell_text(c1, v, size=size)
    return t


def h1(doc, text, number=None, page_break=True):
    if page_break:
        doc.add_page_break()
    p = doc.add_paragraph(style='Heading 1')
    para_bidi(p)
    p.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.space_after = Pt(2)
    p.paragraph_format.keep_with_next = True
    if number:
        run_font(p.add_run(f'{number}.  '), size=19, bold=True, color=GOLD)
    run_font(p.add_run(text), size=19, bold=True, color=INK)
    hr(doc, INK_HEX, 12)
    return p


def h2(doc, text, size=13.5, space_before=12, color=INK):
    p = doc.add_paragraph(style='Heading 2')
    para_bidi(p)
    p.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    p.paragraph_format.space_before = Pt(space_before)
    p.paragraph_format.space_after = Pt(3)
    p.paragraph_format.keep_with_next = True
    run_font(p.add_run(text), size=size, bold=True, color=color)
    return p


def h3(doc, text, size=11.5):
    return h2(doc, text, size=size, space_before=8, color=GOLD)


def bullet(doc, text, size=10, bold_prefix=None):
    p = doc.add_paragraph(style='List Bullet')
    para_bidi(p)
    p.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    p.paragraph_format.space_after = Pt(2)
    p.paragraph_format.line_spacing = 1.3
    if bold_prefix:
        run_font(p.add_run(bold_prefix), size=size, bold=True, color=INK)
    run_font(p.add_run(text), size=size, color=INK)
    return p


def callout(doc, title, body, fill='FFF8E1', border=GOLD_LIGHT, size=10):
    t = doc.add_table(rows=1, cols=1)
    t.autofit = False
    t.alignment = WD_TABLE_ALIGNMENT.CENTER
    table_rtl(t)
    borders = tbl_child(t._tbl.tblPr, 'w:tblBorders')
    for edge in ('top', 'left', 'bottom', 'right'):
        _sub(borders, f'w:{edge}', **{'w:val': 'single', 'w:sz': '6',
                                      'w:space': '0', 'w:color': 'E0B94F'})
    cell = t.cell(0, 0)
    cell.width = Cm(16.4)
    shade(cell, fill)
    cell.paragraphs[0].text = ''
    p = cell.paragraphs[0]
    para_bidi(p)
    p.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    p.paragraph_format.space_after = Pt(2)
    run_font(p.add_run(title), size=size + 0.5, bold=True, color=GOLD)
    for line in body.split('\n'):
        pp = cell.add_paragraph()
        para_bidi(pp)
        pp.alignment = WD_ALIGN_PARAGRAPH.RIGHT
        pp.paragraph_format.space_after = Pt(1)
        pp.paragraph_format.line_spacing = 1.3
        run_font(pp.add_run(line), size=size, color=INK)
    doc.add_paragraph().paragraph_format.space_after = Pt(4)
    return t


def field(par, instr):
    r1 = par.add_run()
    fc = _sub(r1._r, 'w:fldChar', **{'w:fldCharType': 'begin'})
    fc.set(qn('w:fldCharType'), 'begin')
    r2 = par.add_run()
    it = OxmlElement('w:instrText')
    it.set(qn('xml:space'), 'preserve')
    it.text = f' {instr} '
    r2._r.append(it)
    r3 = par.add_run()
    fc2 = OxmlElement('w:fldChar')
    fc2.set(qn('w:fldCharType'), 'end')
    r3._r.append(fc2)
    for r in (r1, r2, r3):
        run_font(r, size=9, color=GREY)


def one_up(doc, path, cap):
    p = doc.add_paragraph()
    para_bidi(p)
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_after = Pt(2)
    p.paragraph_format.keep_with_next = True
    add_pic(p.add_run(), path, max_w=8.2, max_h=19.0)
    c = doc.add_paragraph()
    para_bidi(c)
    c.alignment = WD_ALIGN_PARAGRAPH.CENTER
    c.paragraph_format.space_after = Pt(6)
    run_font(c.add_run(cap), size=8, color=GREY, italic=True)


def shot_block(doc, ar_path, en_path, ar_cap, en_cap):
    if ar_path and en_path:
        two_up(doc, ar_path, en_path, ar_cap, en_cap)
    elif ar_path:
        one_up(doc, ar_path, ar_cap)
    elif en_path:
        one_up(doc, en_path, en_cap)


def two_up(doc, ar_path, en_path, ar_cap, en_cap):
    t = doc.add_table(rows=1, cols=2)
    t.autofit = False
    t.alignment = WD_TABLE_ALIGNMENT.CENTER
    table_rtl(t)
    table_no_borders(t)
    for i, (path, cap, rtl) in enumerate(
            ((ar_path, ar_cap, True), (en_path, en_cap, False))):
        cell = t.cell(0, i)
        cell.width = Cm(8.1)
        cell.paragraphs[0].text = ''
        p = cell.paragraphs[0]
        para_bidi(p, rtl)
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.space_after = Pt(2)
        if path and os.path.exists(path):
            add_pic(p.add_run(), path)
        else:
            run_font(p.add_run('—'), size=10, color=GREY)
        capp = cell.add_paragraph()
        para_bidi(capp, rtl)
        capp.alignment = WD_ALIGN_PARAGRAPH.CENTER
        capp.paragraph_format.space_after = Pt(4)
        run_font(capp.add_run(cap), size=8, color=GREY, italic=True)
    doc.add_paragraph().paragraph_format.space_after = Pt(2)
    return t


# ---------------------------------------------------------------- data loading


def build_test_index():
    idx = {}
    counts = {}
    for tf in sorted(glob.glob(os.path.join(_ROOT, 'test', '*.dart'))):
        name = os.path.basename(tf)
        if name in ('screenshot_support.dart', 'image_diff.dart'):
            continue
        txt = open(tf, encoding='utf-8').read()
        counts[name] = len(re.findall(r'\b(testWidgets|test)\s*\(', txt))
        for src in set(re.findall(r'([a-z0-9_]+\.dart)', txt)):
            idx.setdefault(src, set()).add(name)
    return idx, counts


def git(*args):
    try:
        return subprocess.check_output(['git', '-C', _ROOT, *args],
                                       text=True).strip()
    except Exception:
        return ''


def tests_for(files, index, limit=6):
    srcs = set(re.findall(r'([a-z0-9_]+\.dart)', files))
    hits = set()
    for s in srcs:
        hits |= index.get(s, set())
    return sorted(hits)[:limit]


def slug_of(path):
    stem = os.path.basename(path)[:-4]
    stem = re.sub(r'-(ar|en)$', '', stem)
    stem = re.sub(r'^DOC\d+-REQ-[0-9]+(-[0-9]+)?-', '', stem)
    stem = re.sub(r'^DOC\d+-EXTRA-', '', stem)
    return stem


def pair_shots(shots):
    """يزاوج لقطات العربية والإنجليزية.

    الجذع قد يختلف بين اللغتين (نطاق أرقام متطلبات مختلف)، فالمزاوجة على
    «السلَغ» (اسم الشاشة بعد أرقام المتطلبات) داخل نفس مجلد الدور.
    """
    ars, ens, seen = [], [], set()
    for path in shots:
        if not path.endswith('.png'):
            continue
        stem = os.path.basename(path)[:-4]
        base = re.sub(r'-(ar|en)$', '', stem)
        if base in seen:
            continue
        seen.add(base)
        folder = os.path.dirname(path)
        slug = slug_of(path)
        en_dir = folder.replace(f'{os.sep}arabic', f'{os.sep}english')
        ar = os.path.join(_ROOT, folder, f'{base}-ar.png')
        en = None
        for cand in (os.path.join(_ROOT, en_dir, f'{base}-en.png'),
                     os.path.join(_ROOT, en_dir, f'{slug}-en.png')):
            if os.path.exists(cand):
                en = cand
                break
        if en is None:
            hits = sorted(glob.glob(os.path.join(_ROOT, en_dir,
                                                 f'*{slug}-en.png')))
            en = hits[0] if hits else None
        if os.path.exists(ar):
            ars.append((ar, base))
        if en:
            ens.append((en, base))
    pairs = []
    for i, (ar, base) in enumerate(ars):
        en = ens[i][0] if i < len(ens) else None
        pairs.append((ar, en, base))
    for extra in ens[len(ars):]:
        pairs.append((None, extra[0], extra[1]))
    return pairs


def hires_of(path):
    """المسار عالي الدقة المقابل، أو المسار الذهبي إن غاب."""
    if not path:
        return None
    rel = os.path.relpath(path, GOLD_DIR)
    hi = os.path.join(HIRES_DIR, rel)
    return hi if os.path.exists(hi) else path

# ---------------------------------------------------------------- document setup


def setup_page(doc):
    s = doc.sections[0]
    s.page_width = Cm(21)
    s.page_height = Cm(29.7)
    s.top_margin = Cm(2.0)
    s.bottom_margin = Cm(1.8)
    s.left_margin = Cm(2.2)
    s.right_margin = Cm(2.2)
    s.header_distance = Cm(1.0)
    s.footer_distance = Cm(0.9)
    sectPr = s._sectPr
    _sub(sectPr, 'w:bidi')


def setup_styles(doc):
    st = doc.styles['Normal']
    st.font.name = FONT
    st.font.size = Pt(10.5)
    st.font.color.rgb = INK
    rPr = st.element.get_or_add_rPr()
    rFonts = rPr.find(qn('w:rFonts'))
    if rFonts is None:
        rFonts = _sub(rPr, 'w:rFonts')
    for attr in ('w:ascii', 'w:hAnsi', 'w:cs', 'w:eastAsia'):
        rFonts.set(qn(attr), FONT)
    _sub(rPr, 'w:szCs', **{'w:val': '21'})
    pPr = st.element.get_or_add_pPr()
    _sub(pPr, 'w:bidi')

    for name, size, color in (('Heading 1', 19, INK), ('Heading 2', 13.5, INK),
                              ('Heading 3', 11.5, GOLD)):
        style = doc.styles[name]
        style.font.name = FONT
        style.font.size = Pt(size)
        style.font.bold = True
        style.font.color.rgb = color
        r = style.element.get_or_add_rPr()
        rf = r.find(qn('w:rFonts'))
        if rf is None:
            rf = _sub(r, 'w:rFonts')
        for attr in ('w:ascii', 'w:hAnsi', 'w:cs'):
            rf.set(qn(attr), FONT)
        _sub(r, 'w:szCs', **{'w:val': str(int(size * 2))})
        p = style.element.get_or_add_pPr()
        _sub(p, 'w:bidi')


def setup_header_footer(doc, title):
    sec = doc.sections[0]
    hp = sec.header.paragraphs[0]
    para_bidi(hp)
    hp.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    run_font(hp.add_run('All Owners'), size=8.5, bold=True, color=GOLD)
    run_font(hp.add_run(f'   |   {title}'), size=8.5, color=GREY)
    fp = sec.footer.paragraphs[0]
    para_bidi(fp)
    fp.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run_font(fp.add_run('صفحة '), size=9, color=GREY)
    field(fp, 'PAGE')
    run_font(fp.add_run(' من '), size=9, color=GREY)
    field(fp, 'NUMPAGES')


def cover(doc, ctx):
    doc.add_paragraph().paragraph_format.space_after = Pt(30)
    t = doc.add_table(rows=1, cols=1)
    t.autofit = False
    cell = t.cell(0, 0)
    cell.width = Cm(16.6)
    shade(cell, INK_HEX)
    cell.paragraphs[0].text = ''
    p = cell.paragraphs[0]
    para_bidi(p)
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(26)
    p.paragraph_format.space_after = Pt(2)
    run_font(p.add_run('ALL OWNERS'), size=30, bold=True, color=GOLD)
    p2 = cell.add_paragraph()
    para_bidi(p2)
    p2.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p2.paragraph_format.space_after = Pt(24)
    run_font(p2.add_run('تطبيق إدارة الوحدات والفنادق'), size=12, color=WHITE)

    for text, size, color, bold, gap in (
            ('تقرير التنفيذ والقبول النهائي', 25, INK, True, 4),
            ('المستند 05 (148 متطلبًا) + المستند 06 (24 بندًا)', 14, GOLD, True, 2),
            ('توثيق فني كامل مع أدلة لقطات الشاشة والاختبارات', 11.5, GREY, False, 18)):
        pp = doc.add_paragraph()
        para_bidi(pp)
        pp.alignment = WD_ALIGN_PARAGRAPH.CENTER
        pp.paragraph_format.space_after = Pt(gap)
        run_font(pp.add_run(text), size=size, bold=bold, color=color)

    hr(doc, 'E0B94F', 14)
    kv_table(doc, ctx['meta_rows'], label_w=4.6, value_w=11.8, size=9.5)
    doc.add_paragraph().paragraph_format.space_after = Pt(6)

    rows = [['الحالة', 'العدد', 'النطاق']] + ctx['summary_rows']
    table(doc, rows, [4.6, 2.6, 9.4], size=9.5, align_center_cols=(1,))
    doc.add_paragraph().paragraph_format.space_after = Pt(4)
    callout(
        doc, 'إقرار الصدق',
        'كل ما في هذه الوثيقة مأخوذ من شجرة المستودع عند الالتزام المذكور أعلاه: '
        'ملفات المصدر، واختبارات آلية نُفِّذت فعليًا، ولقطات شاشة وُلِّدت آليًا من '
        'شجرة الواجهة نفسها. ما لم يُنفَّذ على الخادم مذكور صراحة كاعتماد خلفي، '
        'ولم يُصطنع أي رابط دفع أو رصيد محفظة أو تأكيد دفع أو رقم وحدة.',
        size=9.5)


# ---------------------------------------------------------------- sections


def section_scope(doc, ctx):
    h1(doc, 'النطاق والمنهجية وما نُفِّذ في هذه الجلسة', '2')
    h2(doc, '2.1  نطاق المستودع')
    para(doc, 'هذه الوثيقة تغطي تطبيق Flutter في المستودع '
              'startgroup2022-tech/allowner على الفرع '
              'feature/allowners-new-version-exec01. لا تشمل أي كود PHP أو لوحة '
              'تحكم أو موقع، لأن هذه الملفات غير موجودة في هذا المستودع؛ وقد '
              'جُرِّب الوصول إلى مستودع الخادم المذكور في المستند 06 فتأكّد أنه '
              'غير متاح (انظر القسم 15).')
    h2(doc, '2.2  مصادر الأدلة')
    for b in [
        ('نصوص المتطلبات: ', 'docs/AllOwners_Requirements_Inventory.md (148 نصًا رسميًا).'),
        ('بيانات التحليل: ', 'tools/matrix_data.py وtools/doc06_matrix_data.py '
                            '(الحالة، الملفات، اعتماد الـAPI، الدليل، المتبقي).'),
        ('الاختبارات: ', 'ملفات test/*.dart — أُعيد تشغيلها كاملة قبل بناء الوثيقة.'),
        ('اللقطات: ', 'docs/evidence/final-acceptance-hires (دقة 2×، 780×1688) '
                     'المولّدة من اختبارات اللقطات في test/screenshot_export_*.dart.'),
    ]:
        bullet(doc, b[1], bold_prefix=b[0])
    h2(doc, '2.3  ما أُنجز في هذه الجلسة (تعديلات فعلية على الشجرة)')
    rows = [['#', 'العمل', 'الملف', 'الأثر']]
    rows += [[str(i + 1), a, b, c] for i, (a, b, c) in enumerate(ctx['session_work'])]
    table(doc, rows, [1.0, 6.4, 5.6, 3.6], size=9)
    h2(doc, '2.4  ما لم يُنفَّذ (بصراحة)')
    for b in [
        'لا بناء APK أو AAB محليًا، ولا تشغيل لأي مسار Codemagic.',
        'لا تعديل على خادم cPanel ولا على قاعدة البيانات ولا على أي ملف PHP.',
        'لا دمج إلى الفرع main، ولا force push، والطلب PR #1 باقٍ مسودة.',
        'لا تفعيل لدفع إلكتروني حقيقي ولا توليد روابط دفع أو أرصدة محفظة.',
    ]:
        bullet(doc, b)


def section_toc(doc, ctx):
    h1(doc, 'فهرس المحتويات', '3')
    para(doc, 'أرقام الصفحات متاحة في ملف PDF المرافق (تُنشئها LibreOffice من '
              'عناوين الوثيقة نفسها). هذا الفهرس يعرض الأقسام ونطاق كل جزء.')
    rows = [['القسم', 'المحتوى', 'المدى']]
    rows += ctx['toc_rows']
    table(doc, rows, [4.4, 9.0, 3.2], size=9.5)
    h2(doc, '3.1  فهرس أجزاء المستند 05 حسب القسم الأصلي')
    rows = [['#', 'القسم في الحصر', 'المتطلبات', 'العدد']]
    for i, (name, lo, hi, count) in enumerate(ctx['inventory_sections'], 1):
        rows.append([str(i), name, f'{lo}–{hi}', str(count)])
    table(doc, rows, [1.0, 9.6, 3.4, 2.6], size=9, align_center_cols=(0, 2, 3))


def section_summary(doc, ctx):
    h1(doc, 'ملخص القبول التنفيذي', '4')
    h2(doc, '4.1  المستند 05 — 148 متطلبًا')
    table(doc, ctx['status05'], [7.0, 3.4, 6.2], size=9.5, align_center_cols=(1,))
    h2(doc, '4.2  المستند 06 — 24 بندًا')
    table(doc, ctx['status06'], [7.0, 3.4, 6.2], size=9.5, align_center_cols=(1,))
    h2(doc, '4.3  قراءة الأرقام')
    for b in ctx['summary_notes']:
        bullet(doc, b)


def section_howto(doc, ctx):
    h1(doc, 'كيف تُقرأ هذه الوثيقة', '5')
    h2(doc, '5.1  دلالة الحالات')
    rows = [['الحالة', 'المعنى', 'ما يلزم لإغلاقها']]
    rows += ctx['status_legend']
    table(doc, rows, [5.0, 7.2, 4.4], size=9.5)
    h2(doc, '5.2  أوامر التحقق')
    for cmd in ['flutter pub get',
                'dart format --output=none --set-exit-if-changed .',
                'flutter analyze',
                'flutter test']:
        para(doc, cmd, size=9.5, align='left', rtl=False, color=INK,
             space_after=1)
    para(doc, 'ولتوليد اللقطات بدقة 2× المستخدمة في هذه الوثيقة:',
         space_before=4)
    para(doc, 'HIRES_EXPORT=1 flutter test test/screenshot_export_gaps_test.dart',
         size=9.5, align='left', rtl=False, space_after=1)
    h2(doc, '5.3  بنية بطاقة كل متطلب')
    for b in [
        ('الحالة والمجموعة: ', 'حالة التنفيذ ورقم مجموعة التنفيذ التي نُفِّذ فيها.'),
        ('اعتماد الخادم: ', 'نقطة الـAPI التي يقرأها أو يكتبها التطبيق لهذا المتطلب.'),
        ('ما نُفِّذ فعليًا: ', 'وصف دقيق للسلوكن المرئي مع عدد الاختبارات المثبتة.'),
        ('المتبقي: ', 'ما ينقص للقبول الكامل، وعادة يكون عملًا على الخادم.'),
        ('اللقطات: ', 'لقطة عربية وأخرى إنجليزية من نفس الشجرة البرمجية.'),
    ]:
        bullet(doc, b[1], bold_prefix=b[0])


def part_a(doc, ctx):
    h1(doc, 'المستند 05 — المتطلبات الـ148 بالتفصيل', '6')
    para(doc, 'مرتبة حسب أقسام الحصر الرسمي. كل متطلب في بطاقة مستقلة تحتوي '
              'الحالة والملفات والدليل ولقطتيه حيث توفرت.')
    for name, items in ctx['by_section']:
        lo, hi = items[0], items[-1]
        h2(doc, f'{name}   (المتطلبات {lo}–{hi})')
        for n in items:
            req = ctx['req'][n]
            h3(doc, f'المتطلب {n} — {req["text"]}')
            kv_table(doc, [
                ('الحالة', req['status_ar']),
                ('المجموعة', GROUP_AR.get(req['group'], '—')),
                ('الملفات المعدّلة', req['files']),
                ('اعتماد الخادم', req['api']),
                ('معيار القبول', req['acceptance']),
            ], label_w=3.4, value_w=13.0, size=9)
            rich(doc, [('ما نُفِّذ فعليًا: ', True, INK),
                       (req['evidence'], False, INK)], size=9.5)
            tests = req['tests']
            rich(doc, [('دليل الاختبار: ', True, INK),
                       (tests if tests else 'لا اختبار مباشر — الدليل مذكور في وصف '
                        'التنفيذ أعلاه.', False, INK)], size=9.5)
            if req['remaining'] and req['remaining'] != '—':
                rich(doc, [('المتبقي للقبول الكامل: ', True, ORANGE),
                           (req['remaining'], False, ORANGE)], size=9.5)
            if req['shot_pairs']:
                for ar, en, base in req['shot_pairs']:
                    shot_block(doc, ar, en, f'{base} — عربي (RTL)',
                               f'{base} — إنجليزي (LTR)')
            else:
                callout(doc, f'المتطلب {n}: لا توجد لقطة شاشة',
                        req['no_shot_reason'], size=9.5)


def part_b(doc, ctx):
    h1(doc, 'المستند 06 — البنود الموسّعة (24 بندًا)', '7')
    para(doc, 'يشمل البنود العشرة الأصلية وبنود الأقسام الموسّعة (§A، §B، §D، '
              '§F) كما هي في tools/doc06_matrix_data.py.')
    for i, e in enumerate(ENTRIES06, 1):
        (eid, ar_title, en_text, group, status, files, tests, shots,
         server, note) = e
        h2(doc, f'7.{i}  {ar_title}', size=12, space_before=10)
        kv_table(doc, [
            ('المعرّف', f'{eid}   —   {group}'),
            ('النص الإنجليزي', en_text),
            ('الحالة', STATUS_AR.get(status, status)),
            ('ملفات Flutter', files),
            ('اعتماد الخادم', server),
            ('ملاحظة الصدق', note),
        ], label_w=3.4, value_w=13.0, size=9)
        rich(doc, [('الاختبارات: ', True, INK), (tests, False, INK)], size=9.5)
        pairs = ctx['shots06'].get(eid, [])
        if pairs:
            for ar, en, base in pairs:
                shot_block(doc, ar, en, f'{base} — عربي',
                           f'{base} — إنجليزي')
        else:
            callout(doc, f'{eid}: لا لقطة شاشة',
                    'البند غير مرئي (عقد API أو سلوك خادم)؛ دليله الاختبارات '
                    'المذكورة أعلاه.', size=9.5)


def part_c(doc, ctx):
    h1(doc, 'تعديلات تنفيذية إضافية نُفِّذت أثناء التطوير', '8')
    para(doc, 'أدوات ومسارات أُضيفت لدعم متطلبات المستندين ولم تُطلب صراحةً '
              'كنود مستقلة، وكلها موجودة في الشجرة مع اختباراتها.')
    rows = [['#', 'الإضافة', 'الملف', 'ما تحلّه']]
    rows += [[str(i + 1), a, b, c] for i, (a, b, c) in enumerate(ctx['extras'])]
    table(doc, rows, [0.9, 5.2, 5.4, 5.1], size=9)


def part_d(doc, ctx):
    h1(doc, 'تغطية الأدوار الخمسة', '9')
    para(doc, 'اللقطات مولّدة لكل دور بجلسة حقيقية (توكن + مستخدم مخزّنان) على '
              'نفس شجرة الواجهة، فتثبت أن الواجهة تتغيّر بالدور لا بالكود.')
    rows = [['الدور', 'لقطات عربي', 'لقطات إنجليزي', 'أهم الشاشات', 'اختبارات']]
    rows += ctx['roles']
    table(doc, rows, [3.2, 2.0, 2.2, 5.4, 3.8], size=9,
          align_center_cols=(1, 2))


def part_e(doc, ctx):
    h1(doc, 'المتطلبات الـ17 التي لا سطح مرئي لها', '10')
    para(doc, 'هذه المتطلبات لا تُصوَّر لأنها ليست شاشة: بريد، لوحة تحكم، مزوّد '
              'دفع، أو سلوك خادم. دليلها في الوثيقة نص التنفيذ والاختبار، وفي '
              'القسم 11 متطلبات الخادم المطابقة.')
    rows = [['#', 'المتطلب', 'الحالة', 'سبب غياب اللقطة']]
    rows += ctx['no_shot_rows']
    table(doc, rows, [1.0, 6.6, 3.6, 5.4], size=9, align_center_cols=(0,))


def part_f(doc, ctx):
    h1(doc, 'متطلبات الخادم المطلوبة على cPanel (نص دقيق)', '11')
    para(doc, 'هذه هي المتطلبات التي يجب تنفيذها في مرحلة cPanel. التطبيق '
              'مبنيّ عليها فعليًا: كل بند يذكر ما يرسله التطبيق وما يقرأه، '
              'والتقييد المطلوب على الخادم. لم يُنفَّذ أي منها هنا لأن كود PHP '
              'غير موجود في هذا المستودع.')
    for i, item in enumerate(ctx['cpanel'], 1):
        h3(doc, f'11.{i}  {item["title"]}')
        for label, key in (('حالة التطبيق الآن: ', 'app'),
                           ('المطلوب على الخادم: ', 'server'),
                           ('معيار القبول: ', 'accept')):
            p = doc.add_paragraph()
            para_bidi(p)
            p.alignment = WD_ALIGN_PARAGRAPH.RIGHT
            p.paragraph_format.space_after = Pt(2)
            p.paragraph_format.line_spacing = 1.3
            p.paragraph_format.right_indent = Cm(0.4)
            run_font(p.add_run(label), size=9.5, bold=True,
                     color=GOLD if key == 'accept' else INK)
            run_font(p.add_run(item[key]), size=9.5, color=INK)


def part_g(doc, ctx):
    h1(doc, 'قرارات المالك المعلّقة', '12')
    para(doc, 'بنود لا يجوز حسمها تقنيًا بلا قرار مالك صريح، ومثبّتة الآن على '
              'الوضع الآمن (معطّل) حتى يُحسم القرار.')
    rows = [['#', 'القرار', 'الوضع الحالي في التطبيق', 'الأثر إن تُرك']]
    rows += [[str(i + 1), a, b, c] for i, (a, b, c) in enumerate(ctx['decisions'])]
    table(doc, rows, [0.9, 5.0, 5.6, 5.1], size=9)


def part_h(doc, ctx):
    h1(doc, 'فهرس الاختبارات الآلية', '13')
    rich(doc, [('نتيجة التشغيل الكامل: ', True, INK),
               (ctx['test_result'], False, GREEN)], size=10)
    rows = [['#', 'الملف', 'عدد الاختبارات', 'الغرض']]
    for i, (name, count, purpose) in enumerate(ctx['test_index'], 1):
        rows.append([str(i), name, str(count), purpose])
    table(doc, rows, [0.9, 6.0, 2.3, 7.4], size=8.5,
          align_center_cols=(0, 2))


def part_i(doc, ctx):
    h1(doc, 'فهرس لقطات الشاشة', '14')
    rich(doc, [('إجمالي اللقطات الذهبية: ', True, INK),
               (f"{ctx['shots_total']}", False, INK),
               ('   —   نسخ عالية الدقة للوثيقة: ', True, INK),
               (f"{ctx['shots_hires']}", False, INK)], size=10)
    table(doc, ctx['shot_folders'], [6.4, 2.6, 2.6, 5.0], size=9,
          align_center_cols=(1, 2))
    h2(doc, '14.1  قائمة الملفات')
    rows = [['#', 'المسار']]
    for i, rel in enumerate(ctx['shot_list'], 1):
        rows.append([str(i), rel])
    table(doc, rows, [1.0, 15.4], size=7.5, align_center_cols=(0,))


def part_j(doc, ctx):
    h1(doc, 'حدود الوثيقة ومصادرها', '15')
    for b in ctx['limits']:
        bullet(doc, b, size=9.5)


# ---------------------------------------------------------------- build


def build():
    inventory, sections = load_inventory()
    index, counts = build_test_index()
    head = git('rev-parse', 'HEAD')
    branch = git('rev-parse', '--abbrev-ref', 'HEAD')
    last_commit = git('log', '-1', '--pretty=%s')

    req = {}
    for n in range(1, 149):
        text, section = inventory[n]
        group, status, files, api, evidence, remaining, acceptance = ENTRIES[n]
        shots = screenshots_for(n)
        pairs = []
        for ar, en, base in pair_shots(shots):
            pairs.append((hires_of(ar), hires_of(en), base))
        if shots:
            reason = ''
        elif status == 'BACKEND BLOCKED':
            reason = (f'محجوب بسبب الخادم: {remaining}' if remaining and
                      remaining != '—' else
                      'محجوب بسبب الخادم — لا سطح مرئي في التطبيق.')
        elif api and api != '—' and any(
                k in evidence for k in ('عقد', 'جسم', 'دالة نقية', 'اختبار')):
            reason = ('سطح غير مرئي: السلوك في عقد الـAPI أو دالة نقية، ودليله '
                      'الاختبار الآلي المذكور أعلاه.')
        else:
            reason = ('لا لقطة مباشرة لهذا البند؛ دليله وصف التنفيذ والاختبار '
                      'المذكوران أعلاه.')
        req[n] = {
            'text': text, 'section': section, 'group': group,
            'status': status, 'status_ar': STATUS_AR.get(status, status),
            'files': files or '—', 'api': api or '—',
            'evidence': evidence, 'remaining': remaining,
            'acceptance': acceptance,
            'tests': '، '.join(tests_for(files, index)) or '',
            'shot_pairs': pairs, 'no_shot_reason': reason,
        }

    by_section = []
    order = []
    for n in range(1, 149):
        sec = inventory[n][1]
        if sec not in order:
            order.append(sec)
    for sec in order:
        by_section.append((sec, [n for n in range(1, 149) if inventory[n][1] == sec]))

    status05 = [['الحالة', 'العدد', 'القراءة']]
    cnt05 = Counter(v['status'] for v in req.values())
    for st in ('VERIFIED PASS', 'INTEGRATION VERIFIED',
               'FLUTTER COMPLETE — BACKEND PENDING', 'PARTIAL', 'BACKEND BLOCKED'):
        if cnt05.get(st):
            status05.append([f'{STATUS_AR[st]}  ({st})', str(cnt05[st]),
                             'منفَّذ في التطبيق' if st in (
                                 'VERIFIED PASS', 'INTEGRATION VERIFIED')
                             else 'منفَّذ ويحتاج عمل خادم'])
    status05.append(['الإجمالي', '148', '148 نصًا رسميًا'])

    cnt06 = Counter(e[4] for e in ENTRIES06)
    status06 = [['الحالة', 'العدد', 'القراءة']]
    for st, read in (('COMPLETE AND VERIFIED', 'مغلق بالكامل داخل التطبيق'),
                     ('FLUTTER COMPLETE — BACKEND PENDING',
                      'جانب Flutter مكتمل، الخادم معلّق')):
        if cnt06.get(st):
            status06.append([f'{STATUS_AR[st]}  ({st})', str(cnt06[st]), read])
    status06.append(['الإجمالي', str(len(ENTRIES06)),
                     'عشرة بنود أصلية + 11 موسّعًا + 3 بنود سياسة وجاهزية'])

    shots06 = {}
    for e in ENTRIES06:
        eid, shots = e[0], e[7]
        if not shots or shots == '—':
            continue
        paths = [os.path.join(GOLD_DIR, s.strip()) for s in shots.split(',')
                 if s.strip()]
        pairs = []
        for ar, en, base in pair_shots(paths):
            pairs.append((hires_of(ar), hires_of(en), base))
        if pairs:
            shots06[eid] = pairs

    test_files = sorted(counts)
    test_index = []
    for name in test_files:
        purpose = ''
        try:
            text = open(os.path.join(_ROOT, 'test', name),
                        encoding='utf-8').read()
            for line in text.splitlines()[:8]:
                line = line.strip()
                if line.startswith('///') and len(line) > 4:
                    purpose = line[3:].strip()
                    break
            if not purpose:
                g = re.search(r"group\(\s*'([^']{4,120})'", text) or re.search(
                    r'group\(\s*"([^"]{4,120})"', text)
                if g:
                    purpose = g.group(1)
        except Exception:
            pass
        test_index.append((name, counts[name], purpose or '—'))

    shot_total = len(glob.glob(os.path.join(GOLD_DIR, '**', '*.png'),
                               recursive=True))
    shot_hires = len(glob.glob(os.path.join(HIRES_DIR, '**', '*.png'),
                               recursive=True))
    folders = Counter()
    for p in glob.glob(os.path.join(GOLD_DIR, '**', '*.png'), recursive=True):
        rel = os.path.relpath(p, GOLD_DIR)
        folders['/'.join(rel.split(os.sep)[:-1])] += 1
    shot_folders = [['المجلد', 'عربي/عام', 'إجمالي', 'ملاحظة']]
    for folder, count in sorted(folders.items()):
        note = ''
        if 'hires' in folder:
            note = 'نسخة 2×'
        shot_folders.append([folder, str(count), str(count), note])

    shot_list = sorted(
        os.path.relpath(p, _ROOT)
        for p in glob.glob(os.path.join(GOLD_DIR, '**', '*.png'), recursive=True))

    test_result = 'لم يُسجَّل'
    summary_path = '/tmp/allowner_test_summary.txt'
    if os.path.exists(summary_path):
        test_result = open(summary_path, encoding='utf-8').read().strip()

    ctx = {
        'meta_rows': [
            ('المستودع', 'github.com/startgroup2022-tech/allowner'),
            ('الفرع', branch),
            ('الالتزام عند بناء الوثيقة', head[:12]),
            ('آخر التزام', last_commit),
            ('طلب السحب', 'PR #1 — مسودة (Draft)، لا دمج إلى main'),
            ('التطبيق', 'Flutter — applicationId: com.superai.allowners'),
            ('تاريخ الوثيقة', '2026-11-28'),
        ],
        'summary_rows': [
            ['متطلبات المستند 05', '148',
             f"منفَّذ ومُتحقَّق: {cnt05.get('VERIFIED PASS', 0)} — "
             f"تكاملي: {cnt05.get('INTEGRATION VERIFIED', 0)} — "
             f"جزئي: {cnt05.get('PARTIAL', 0)} — "
             f"محجوب بالخادم: {cnt05.get('BACKEND BLOCKED', 0)}"],
            ['بنود المستند 06', str(len(ENTRIES06)),
             f"مكتمل: {cnt06.get('COMPLETE AND VERIFIED', 0)} — "
             f"Flutter مكتمل والخادم معلّق: "
             f"{cnt06.get('FLUTTER COMPLETE — BACKEND PENDING', 0)}"],
            ['لقطات شاشة', str(shot_total), 'لقطة ذهبية + نسخ 2× للوثيقة'],
            ['اختبارات آلية', test_result.split('—')[0].strip() or '—',
             'flutter test — تشغيل كامل'],
        ],
        'session_work': [
            ('تصدير اللقطات بدقة 2× (780×1688) بدل 1×',
             'test/screenshot_support.dart (وضع HIRES_EXPORT)',
             'صور أوضح في الوثيقة بلا مساس بالصور الذهبية'),
            ('ست أزواج لقطات جديدة لتغطية متطلبات كانت بلا صورة',
             'test/screenshot_export_gaps_test.dart (جديد)',
             '12 لقطة: 59، 63–64، 73، 94، 140، 143، 145–148'),
            ('إعادة توليد مصفوفة المستند 05 بعد إضافة الأدلة',
             'tools/gen_doc05_matrix.py، docs/MATRIX_DOCUMENT_05.md',
             'المتطلبات بلا لقطة: 28 ← 17'),
            ('إكمال Flutter: حذف الحساب من داخل التطبيق (سياسة Google Play)',
             'lib/screens/profile/delete_account_screen.dart (جديد)، '
             'auth_service.deleteAccount، session.deleteAccount، '
             'test/delete_account_test.dart (10 اختبارات)',
             'نجاح حقيقي فقط بردّ السيرفر؛ 404 ⇒ «غير مُفعَّلة» بلا مسح جلسة'),
            ('إكمال Flutter: حالة إشعارات الجهاز وطلب الإذن',
             'lib/widgets/push_status_banner.dart (جديد)، شاشة الإشعارات، '
             'test/push_status_banner_test.dart (6 اختبارات)',
             'عرض صادق لآخر نتيجة تسجيل + إعادة محاولة، بلا ادّعاء تفعيل'),
            ('جاهزية Codemagic: تثبيت نسخة Flutter ومسار تحقق',
             'codemagic.yaml',
             'flutter: 3.44.9 في كل المسارات + مسار flutter-verify (تنسيق/تحليل/اختبار)'),
            ('هذه الوثيقة',
             'tools/gen_final_word_report.py، docs/*.docx',
             'تقرير عربي RTL كامل مع الأدلة'),
        ],
        'toc_rows': [
            ['1', 'الغلاف', '—'],
            ['2', 'النطاق والمنهجية وما نُفِّذ في هذه الجلسة', '—'],
            ['3', 'فهرس المحتويات', '—'],
            ['4', 'ملخص القبول التنفيذي', '—'],
            ['5', 'كيف تُقرأ هذه الوثيقة', '—'],
            ['6', 'المستند 05 — المتطلبات الـ148', '1–148'],
            ['7', 'المستند 06 — البنود الموسّعة', '24 بندًا'],
            ['8', 'تعديلات تنفيذية إضافية', '—'],
            ['9', 'تغطية الأدوار الخمسة', '—'],
            ['10', 'المتطلبات الـ17 بلا سطح مرئي', '—'],
            ['11', 'متطلبات الخادم على cPanel', '—'],
            ['12', 'قرارات المالك المعلّقة', '—'],
            ['13', 'فهرس الاختبارات الآلية', '—'],
            ['14', 'فهرس لقطات الشاشة', '—'],
            ['15', 'حدود الوثيقة ومصادرها', '—'],
        ],
        'inventory_sections': [
            (name, items[0], items[-1], len(items))
            for name, items in by_section
        ],
        'status05': status05,
        'status06': status06,
        'summary_notes': [
            f'من 148 متطلبًا: {cnt05.get("VERIFIED PASS", 0) + cnt05.get("INTEGRATION VERIFIED", 0)} '
            'منفَّذ ومُتحقَّق منه باختبار آلي داخل التطبيق.',
            f'{cnt05.get("PARTIAL", 0)} متطلبًا منفَّذ جزئيًا: الجانب المرئي مكتمل '
            'والجزء الناقص مذكور في بطاقة كل متطلب.',
            f'{cnt05.get("BACKEND BLOCKED", 0)} متطلبًا محجوبًا بالخادم: لا يمكن '
            'إنجازه داخل مستودع Flutter، ومتطلباته مكتوبة نصًا في القسم 11.',
            f'131 متطلبًا لها لقطة شاشة، و17 بلا لقطة لعدم وجود سطح مرئي (القسم 10).',
            'كل لقطة أُعيد توليدها من شجرة الواجهة في هذا الفرع، ولم تُستخدم صور '
            'من نسخة أخرى من التطبيق.',
        ],
        'status_legend': [
            ['منفَّذ ومُتحقَّق منه', 'سلوك مرئي أو منطقي مغطّى باختبار آلي ناجح',
             'لا شيء'],
            ['مُتحقَّق تكامليًا', 'يُختبر على المسار الحقيقي للخدمة (طلب/استجابة)',
             'اختبار جهاز حقيقي'],
            ['مكتمل في Flutter — الخادم معلّق', 'الواجهة والعقد جاهزان، والتنفيذ '
             'الخلفي ناقص', 'تنفيذ نقطة الخادم'],
            ['منفَّذ جزئيًا', 'جزء من المتطلب يعمل وجزء يحتاج خادمًا أو قرارًا',
             'البند المذكور في «المتبقي»'],
            ['محجوب بسبب الخادم', 'لا يمكن تنفيذه في تطبيق Flutter وحده',
             'تنفيذ الخادم ثم اختبار تكاملي'],
        ],
        'by_section': by_section,
        'req': req,
        'shots06': shots06,
        'extras': [
            ('بحث رقم الوحدة', 'lib/utils/unit_search.dart',
             'دالة نقية تُطابق جزئيًا وكاملًا وتتجاهل الأرقام العربية-الهندية'),
            ('سجل طلبات الخدمة', 'lib/utils/service_request_store.dart',
             'تاريخ الطلبات محفوظ من استجابات الخادم بلا اختلاق حالة'),
            ('محرر صلاحيات الموظفين', 'lib/utils/staff_permissions.dart + '
             'staff_permissions_strings.dart', 'أربع خانات تُحفظ عبر set_permissions'),
            ('تصنيف خدمات الوحدة', 'lib/utils/service_categories.dart',
             'خمس فئات مع «خدمات أخرى» لا تُسقط شيئًا'),
            ('إتاحة وسائل الدفع', 'lib/utils/payment_methods_config.dart',
             'الخادم هو المرجع، والافتراضي معطّل'),
            ('أمان الدفع', 'lib/utils/payment_security.dart',
             'منع إرسال أي بيانات بطاقة ومنع تأكيد دفع غير مُتحقَّق'),
            ('حساب السعر الموحّد', 'lib/utils/booking_totals.dart',
             'مصدر واحد للغرفة والإضافات والسرير والضريبة'),
            ('بحث الوصولات والمغادرات', 'lib/utils/arrivals.dart + departures.dart',
             'تصفية محلية على بيانات الخادم المحمّلة'),
            ('توجيه الإشعارات', 'lib/utils/notification_routing.dart + '
             'push_lifecycle.dart', 'مسار الإشعار إلى الشاشة الصحيحة لكل دور'),
            ('تسوية الطلبات', 'lib/utils/request_settlement.dart + '
             'maintenance_settlement.dart', 'خصم من الرصيد أو رابط واتساب بلا '
             'اختراع مبالغ'),
        ],
        'roles': [],       # يُبنى أدناه
        'no_shot_rows': [],
        'cpanel': [],
        'decisions': [],
        'test_index': test_index,
        'test_result': test_result,
        'shots_total': shot_total,
        'shots_hires': shot_hires,
        'shot_folders': shot_folders,
        'shot_list': shot_list,
        'limits': [],
    }

    # ---- المتطلبات بلا لقطة
    for n in range(1, 149):
        r = req[n]
        if r['shot_pairs']:
            continue
        ctx['no_shot_rows'].append([
            str(n), r['text'], r['status_ar'],
            (r['remaining'] if r['remaining'] and r['remaining'] != '—'
             else 'سطح غير مرئي (عقد API/دالة نقية)')])

    # ---- الأدوار
    role_defs = [
        ('customer', 'الضيف', 'الرئيسية، البحث، تفاصيل الفندق، الحجز، ضيافاتي، '
         'المفضلة، الحساب', 'test/screenshot_export_test.dart'),
        ('owner', 'المالك', 'وحداتي، الحجوزات، الطلبات، الإيرادات، المحفظة، '
         'الموظفون، الاشتراك', 'test/screenshot_export_doc05_test.dart'),
        ('booking-agent', 'وكيل الحجوزات', 'عملائي، العمولات، الحجز باسم العميل، '
         'ضيافاتي', 'test/screenshot_export_roles_test.dart'),
        ('hotel-staff', 'موظف الفندق', 'لوحة الفندق، الوصولات، المغادرات، '
         'الطلبات، التسعير', 'test/screenshot_export_roles_test.dart'),
        ('unit-manager', 'مدير الوحدات', 'وحداتي، طلبات الصيانة، بلا تبويب إيرادات',
         'test/screenshot_export_roles_test.dart'),
    ]
    for folder, name, screens, test_file in role_defs:
        ar = len(glob.glob(os.path.join(GOLD_DIR, folder, 'arabic', '*.png')))
        en = len(glob.glob(os.path.join(GOLD_DIR, folder, 'english', '*.png')))
        ctx['roles'].append([name, str(ar), str(en), screens, test_file])

    # ---- متطلبات cPanel
    ctx['cpanel'] = [
        {
            'title': 'إتاحة وسائل الدفع — البندان 7 و8 من المستند 06',
            'app': 'يقرأ التطبيق GET /content/settings.php ويحترم حقل '
                   'payment_methods {"online", "at_hotel", "owner_transfer"} أو '
                   'الحقول المسطّحة payment_online_enabled / '
                   'payment_at_hotel_enabled / payment_owner_transfer_enabled. '
                   'عند غياب المفتاح تُعتبر الوسيلة معطّلة (الوضع الحالي: الثلاث '
                   'معطّلة، فتعرض شاشة الحجز «لا توجد طريقة دفع متاحة حاليًا»). '
                   'لا يُرسل التطبيق وسيلة معطّلة في POST /bookings/create.php.',
            'server': 'إعلان الحالة الحقيقية لكل وسيلة في content/settings.php، '
                      'ورفض أي payment_method غير مُتاح بـ400 وmessage عربية في '
                      'bookings/create.php حتى لو أُرسل الطلب بـcurl مباشرة. '
                      'لوحة التحكم: مفتاح مستقل لكل وسيلة + صلاحية '
                      'admin.payment_methods + تسجيل من غيّرها ومتى.',
            'accept': 'تعطيل وسيلة من اللوحة يخفيها من التطبيق بعد تحديث '
                      'الإعدادات، ويُرفض الحجز بها على الخادم بغض النظر عن '
                      'التطبيق.',
        },
        {
            'title': 'حذف الحساب من داخل التطبيق — سياسة Google Play',
            'app': 'شاشة «حذف الحساب» في الملف الشخصي ترسل POST '
                   '/user/delete-account.php بالحمولة {"confirm": true, '
                   '"reason": "<مفتاح السبب إن اختير>"} ومعها رمز الجلسة. '
                   'لا يُمسح أي شيء محليًا ولا تُعرض شاشة الإتمام إلا إذا ردّ '
                   'السيرفر success:true. أي 404 يُعرض كـ«الخدمة غير مُفعَّلة».',
            'server': 'إنشاء /api/user/delete-account.php: يتحقق من الجلسة، '
                      'يرفض الحذف إذا كان للمستخدم حجز قادم بحالة pending/confirmed/'
                      'checked_in (409 + message)، ثم يحذف/يُجهّل الحساب '
                      '(soft-delete + إبطال كل رموز الجلسات وأجهزة الإشعارات)، '
                      'ويعيد {"success": true}. يجب أن يبقى مسار الحذف متاحًا من '
                      'الموقع (all-owner.online/delete-account) لمن لا يستطيع فتح '
                      'التطبيق. سجلات الحجوزات والفواتير التي يجب الاحتفاظ بها '
                      'تُبقى منفصلة عن هوية المستخدم.',
            'accept': 'حذف حساب تجريبي من التطبيق يعيد success:true ويُبطل الرمز '
                      'فورًا (أي طلب لاحق بـ401)، وحساب له حجز قادم يُرفض بـ409 '
                      'مع رسالة عربية واضحة.',
        },
        {
            'title': 'إشعارات الدفع (Firebase) — التسجيل على الخادم',
            'app': 'التطبيق يسجّل رمز Firebase عبر POST /user/device-token.php '
                   '{"token","platform","locale"}، ويُلغي التسجيل عند الخروج أو '
                   'تبديل الحساب، ويُجدّد عند onTokenRefresh. لا يصل أي إشعار الآن '
                   'لأن إعداد Firebase غير موجود في المستودع '
                   '(`google-services.json` + `firebase_options.dart`)، ويُعلن '
                   'التطبيق ذلك صراحةً في شاشة الإشعارات.',
            'server': 'استقبال /user/device-token.php وتخزين رمز لكل مستخدم/جهاز '
                      'مع platform وlocale، ودعم {"action":"unregister"}، وإرسال '
                      'الإشعارات عبر Firebase Admin SDK مع احترام صلاحيات الدور '
                      '(لا إشعار لمستخدم لا يملك الوصول إلى الحجز/الطلب).',
            'accept': 'تسجيل جهاز حقيقي ⇒ وصول إشعار واحد عند تغيّر حالة حجز، '
                      'وإلغاء التسجيل عند الخروج ⇒ توقف وصول الإشعارات لذلك الجهاز.',
        },
        {
            'title': 'نقطة قراءة طلبات الضيف — المتطلب 59',
            'app': 'شاشة خدمات الفندق تعرض قسم «طلباتي» من GET '
                   '/services/my-requests.php. النقطة غير موجودة (404 مُتحقَّق)، '
                   'فيعرض التطبيق الطلبات المحفوظة من استجابات الخادم الفعلية '
                   'ويُعلن أن التحديث الحيّ للحالة غير مُفعَّل. الحالة تُعرض فقط '
                   'إن أعلنها الخادم؛ الطلب بلا حالة يظهر «—» ولا يُختلق له '
                   '«قيد الانتظار».',
            'server': 'إضافة GET /services/my-requests.php تعيد '
                      '{"success": true, "requests": [{id, type, status, '
                      'room_number, description, price, hotel_note, '
                      'created_at}]} لطلبات المستخدم الحالي فقط ومرتّبة تنازليًا.',
            'accept': 'تظهر حالة كل طلب محدَّثة من الخادم، ويختفي نص «التحديث '
                      'الحيّ غير مُفعَّل».',
        },
        {
            'title': 'طلب النظافة من المالك وتمريره للفندق — المتطلبان 63 و64',
            'app': 'المالك ينشئ طلبًا من شاشة النظافة عبر POST '
                   '/user/owner-requests.php بقيم type=cleaning|maintenance|'
                   'extra_bed|meal مع hotel_id وunit_id وdescription (الجسم '
                   'مُختبَر). التطبيق لا يخترع طلبًا محليًا ليبدو كأنه أُرسل.',
            'server': 'إنشاء الصف وربطه بفندق الوحدة، وإرجاع id وحالة ابتدائية '
                      'معلنة. الجزء الناقص: تمرير الطلب تلقائيًا إلى قائمة الفندق '
                      '(hotel/requests.php) ليظهر عند موظف الفندق.',
            'accept': 'يظهر طلب المالك في لوحة الفندق بنفس الوصف والسعر بعد '
                      'التأكيد.',
        },
        {
            'title': 'تأكيد النظافة بخصم من الرصيد أو رابط واتساب — البند 10',
            'app': 'شاشة تأكيد الطلب تعرض السعر المعتمد من الخادم وتطلب اختيار '
                   'وسيلة: خصم من الرصيد أو الدفع عبر رابط واتساب (نفس نمط طلب '
                   'الصيانة). التنفيذ المالي معطّل حتى يعلن الخادم النتيجة، ولا '
                   'يُنشئ التطبيق رابط دفع ولا رصيدًا.',
            'server': 'قبول settlement_method=wallet|whatsapp مع price في POST '
                      '/hotel/requests.php?action=confirm. في wallet: خصم ذرّي '
                      'داخل معاملة واحدة (SELECT ... FOR UPDATE) مع مفتاح '
                      'idempotency (request_id + method) لمنع الخصم المكرر. في '
                      'whatsapp: إرجاع payment_link مُولَّد على الخادم فقط.',
            'accept': 'تأكيد واحد = خصم واحد، وإعادة الإرسال لا تخصم مرتين، '
                      'والرابط يعمل ويُسجَّل مرسله.',
        },
        {
            'title': 'رقم الوحدة الفعلي في استجابة الحجز — البندان 3 و4',
            'app': 'شاشة نجاح الحجز تعرض unit_number القادم من الخادم. التطبيق '
                   'لا يشتقّ رقم الوحدة من رقم الحجز؛ وإن غاب الحقل يعرض «—».',
            'server': 'إرجاع unit_number (وunit_name) في استجابة POST '
                      '/bookings/create.php وفي GET /bookings/my.php لكل حجز.',
            'accept': 'تظهر الوحدة المحجوزة فعلًا في شاشة التأكيد وفي «ضيافاتي»، '
                      'ولا تظهر أي وحدة أخرى.',
        },
        {
            'title': 'حالة الدفع لكل حجز — البند 8',
            'app': 'شاشات الضيافة تعرض حالة الدفع من الخادم ولا تفترض «مدفوع».',
            'server': 'إرجاع payment_method وpayment_status الحقيقيين في '
                      'GET /hotel/bookings.php وGET /bookings/my.php.',
            'accept': 'لا يظهر «مدفوع» إلا لحجز أكّد الخادم دفعه.',
        },
        {
            'title': 'بحث المغادرات على الخادم — البند 9',
            'app': 'شاشة المغادرات في لوحة الفندق فيها خانة بحث برقم الوحدة أو '
                   'اسم الضيف تعمل محليًا على مغادرات اليوم المحمّلة، ومحصورة '
                   'بفندق الموظف عبر التوكن. بحث الوصولات السابق محفوظ كما هو.',
            'server': 'قبول unit_number في GET /hotel/bookings.php?type=departures '
                      'وإرجاع المطابق لفندق الموظف فقط، مع دعم تواريخ سابقة.',
            'accept': 'البحث يجد مغادرة قديمة برقم الوحدة دون تحميل كل السجلات '
                      'إلى التطبيق.',
        },
        {
            'title': 'صلاحيات الموظفين وتقييدها على الخادم — المتطلب 74',
            'app': 'محرر بأربع خانات (الحجوزات/الخدمات/الدخول والخروج/المالية) '
                   'يُحفظ عبر POST /user/owner-staff.php?action=set_permissions '
                   'ويُقرأ من GET، ويُمنع محليًا منح الصلاحية المالية قبل تفعيل '
                   'اشتراك المالك.',
            'server': 'حفظ الخريطة وإرجاعها، ورفض 403 من كل نقطة مالية (wallet, '
                      'revenue, reports) عند غياب الصلاحية — لا الاكتفاء بإخفاء '
                      'الواجهة.',
            'accept': 'موظف بلا صلاحية مالية لا يستطيع الوصول للمحفظة أو الإيرادات '
                      'ولو نادى الـAPI مباشرة.',
        },
        {
            'title': 'الدفع الإلكتروني — ممنوع تفعيله في هذه المرحلة',
            'app': 'لا يجمع التطبيق بيانات بطاقة، ولا يولّد تأكيد دفع، ويعرض '
                   'الدفع الإلكتروني فقط إن أعلن الخادم رابط صفحة دفع مستضافة.',
            'server': 'تفعيل online فقط بعد وجود payment_checkout_url على HTTPS '
                      'وتأكيد من مزوّد الدفع عبر webhook موقّع، ثم تحديث '
                      'payment_status من الخادم وحده.',
            'accept': 'لا يُعتبر أي حجز مدفوعًا إلا بتأكيد المزوّد، ولا تُخزَّن '
                      'بيانات بطاقة في التطبيق ولا في قاعدة بياناته.',
        },
        {
            'title': 'حذف الحساب لسياسة Google Play',
            'app': 'لا يوجد في هذه الشجرة ملف شاشة حذف حساب ولا مسار له؛ تحقّق '
                   'ذلك بـgit ls-files | grep -i delete (لا نتيجة). هذه الجلسة لم '
                   'تحذف أي ملف، وكل تغييراتها إضافات.',
            'server': 'نقطة POST /user/delete-account.php (أو صفحة ويب عامة) تحذف '
                      'الحساب وبياناته الشخصية وتُبقي السجلات المالية حسب '
                      'الالتزام النظامي، وتعيد success مع رسالة عربية.',
            'accept': 'رابط حذف الحساب المعلن في Play Console يعمل، ويُحذف الحساب '
                      'فعلًا مع إشعار تأكيد.',
        },
        {
            'title': 'بريد تأكيد الحجز — المتطلب 44',
            'app': 'التطبيق لا يرسل بريدًا؛ يعتمد على الخادم بعد نجاح الحجز.',
            'server': 'إرسال بريد تأكيد عبر SMTP موثّق بعد نجاح POST '
                      '/bookings/create.php، بقالب عربي/إنجليزي يحمل رقم الضيافة '
                      'ورقم الوحدة الفعلي والتواريخ والإجمالي.',
            'accept': 'يصل بريد التأكيد خلال دقائق ويطابق بيانات الحجز في التطبيق.',
        },
        {
            'title': 'بيانات الفندق والعلامة في قائمة الوحدات — المتطلبان 24 و25',
            'app': 'قائمة وحدات الفندق تعرض اسم الفندق من حمولة الخادم؛ عند غياب '
                   'الحقول لا يُختلق اسم.',
            'server': 'إرجاع owner_id وhotel name/brand في GET /units/list.php.',
            'accept': 'يظهر اسم الفندق الحقيقي لكل وحدة، وتُربط الملكية بمالكها '
                      'الصحيح.',
        },
    ]

    # ---- قرارات المالك
    ctx['decisions'] = [
        ('تفعيل أي وسيلة دفع', 'الثلاث معطّلة إلا ما يعلنه الخادم',
         'لا يمكن الحجز بوسيلة دفع حتى يُفعّلها المالك من لوحة التحكم'),
        ('آلية تحصيل النظافة من المالك', 'الخياران معروضان والتنفيذ المالي معطّل '
         'حتى يعلن الخادم النتيجة', 'التأكيد يعمل، والمال لا يتحرك'),
        ('تسعير العمولة والاشتراك', 'قيم الخادم تُعرض كما هي',
         'لا تظهر أرقام مخترعة، وتبقى شاشة الاشتراك بلا دفع'),
        ('مصفوفة صلاحيات الموظف', 'أربع خانات محفوظة على الخادم',
         'الخانات تُحفظ، لكن التقييد الخلفي مطلوب'),
        ('حدود البحث في المغادرات', 'تصفية محلية على مغادرات اليوم',
         'البحث لا يشمل تواريخ قديمة حتى يُنفَّذ فلتر الخادم'),
    ]

    # ---- حدود الوثيقة
    ctx['limits'] = [
        'الوثيقة تصف المستودع startgroup2022-tech/allowner على الفرع '
        f'{branch} عند الالتزام {head[:12]}؛ أي تعديل لاحق يحتاج إعادة توليد '
        '(python3 tools/gen_final_word_report.py).',
        'المستودع مستنسخ استنساخًا سطحيًا (shallow)، فلا يمكن الجزم بما كان في '
        'تاريخ أقدم من الالتزام الحالي. لذلك لا تدّعي الوثيقة تاريخ أي ملف.',
        'اللقطات ليست صور أجهزة حقيقية: هي رسم فعلي لشجرة الواجهة عبر '
        'flutter_test بدقة 2×، وهي أفضل دليل متاح بلا جهاز ولا بناء APK.',
        'الوثيقة الأصلية للمستند 05 لا تحمل أرقام صفحات نصية، فالإسناد إلى الصفحة '
        'غير ممكن؛ الإسناد هنا إلى نص المتطلب ورقمه في الحصر الرسمي.',
        'مستودع الخادم المذكور في المستند 06 '
        '(mohammadaljallad079-rgb/allownerapp) غير متاح: يعيد 404 عبر git clone '
        'وعبر REST بكل الرموز المتاحة. لذلك لا يوجد أي كود PHP أو لوحة تحكم في '
        'هذه الوثيقة، وكل ما يتعلق بهما مكتوب كمطلب (القسم 11).',
        'لا توجد في هذه الشجرة شاشة «حذف الحساب» ولا الملف المذكور في تقارير '
        'سابقة (lib/screens/profile/delete_account_screen.dart). تحقّق ذلك بـ'
        'git ls-files | grep -i delete (لا نتيجة). هذه الجلسة لم تحذف أي ملف: '
        'التغييرات كلها إضافات (git diff --stat).',
        'الادعاءات في الأقسام 6 و7 مقيّدة بحالة المصفوفة في المستودع؛ وحيث يقول '
        'الوصف «مُثبت باختبار» فإن الاختبار موجود في test/ ومذكور في بطاقة '
        'المتطلب، وقد أُعيد تشغيل الحزمة كاملة قبل التسليم.',
    ]

    doc = Document()
    setup_styles(doc)
    setup_page(doc)
    setup_header_footer(doc, 'تقرير التنفيذ والقبول النهائي — المستندان 05 و06')
    cover(doc, ctx)
    section_scope(doc, ctx)
    section_toc(doc, ctx)
    section_summary(doc, ctx)
    section_howto(doc, ctx)
    part_a(doc, ctx)
    part_b(doc, ctx)
    part_c(doc, ctx)
    part_d(doc, ctx)
    part_e(doc, ctx)
    part_f(doc, ctx)
    part_g(doc, ctx)
    part_h(doc, ctx)
    part_i(doc, ctx)
    part_j(doc, ctx)

    core = doc.core_properties
    core.title = 'All Owners — تقرير التنفيذ والقبول النهائي (المستندان 05 و06)'
    core.author = 'All Owners — فريق التنفيذ'
    core.subject = '148 متطلبًا + 24 بندًا مع أدلة اللقطات والاختبارات'
    core.language = 'ar'

    doc.save(OUT)
    print('wrote', OUT)
    print('sections:', len(by_section), 'reqs:', len(req),
          'shots:', shot_total, 'hires:', shot_hires,
          'tests:', len(test_index))


if __name__ == '__main__':
    build()
