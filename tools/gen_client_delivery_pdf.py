#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""يبني نسخة PDF من ملف تسليم العميل.

كل لقطة في صفحة بمقاسها: عرض ثابت 108مم وارتفاع بقدر الصورة، فلا فراغات ولا
تصغير. ثم تُدمج الصفحات النصية (غلاف/محتويات/مقدمة كل واجهة/ملاحظات) بنفس
الترتيب وتُنظَّف بيانات الملف الوصفية.
"""

import os
import subprocess
import sys
from html import escape
from urllib.parse import quote

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import client_delivery_data as D  # noqa: E402

ROOT = D.ROOT
OUT = os.path.join(ROOT, 'docs/CLIENT_DELIVERY_BOOK_AR.pdf')
WORK = '/tmp/delivery_pages'
FONTS = os.path.join(ROOT, 'test/screenshot_assets/fonts')

IMG_W_MM = 108.0
CAPTION_MM = 24.0

FONT_FACES = """
@font-face { font-family: 'PlexAr'; font-weight: 400;
  src: url('file://%(f)s/IBMPlexSansArabic-Regular.ttf'); }
@font-face { font-family: 'PlexAr'; font-weight: 600;
  src: url('file://%(f)s/IBMPlexSansArabic-SemiBold.ttf'); }
@font-face { font-family: 'PlexAr'; font-weight: 700;
  src: url('file://%(f)s/IBMPlexSansArabic-Bold.ttf'); }
""" % {'f': FONTS}

BASE_CSS = """
* { box-sizing: border-box; }
body { font-family: 'PlexAr', sans-serif; direction: rtl; color: #01122E;
  margin: 0; font-size: 11pt; line-height: 1.55; }
h1, h2, h3 { margin: 0; }
.gold { color: #B3872A; }
.grey { color: #555D6B; }
ul { margin: 0; padding-inline-start: 6mm; }
li { margin-bottom: 2.6mm; }
"""

A4_CSS = FONT_FACES + BASE_CSS + """
@page { size: A4; margin: 16mm 14mm 14mm; }
.cover { text-align: center; padding-top: 78mm; }
.cover h1 { font-size: 44pt; letter-spacing: -0.5pt; margin-bottom: 8mm; }
.cover .sub { font-size: 17pt; margin-bottom: 20mm; }
.cover .meta { line-height: 2; }
.cover .note { margin: 20mm auto 0; max-width: 132mm; font-size: 10pt; }
h2 { font-size: 21pt; margin-bottom: 4mm; }
h3 { font-size: 12.5pt; margin: 8mm 0 3.5mm; }
.lead { font-size: 11.5pt; margin: 0 0 6mm; }
.toc-row { display: flex; justify-content: space-between; border-bottom: 1px
  solid #EDEDED; padding: 3.2mm 0; font-size: 11.5pt; }
.toc-row span:last-child { font-size: 10pt; }
.num { font-size: 12pt; margin-bottom: 3mm; }
.note-title { font-weight: 700; font-size: 12.5pt; margin: 7mm 0 1.5mm; }
"""


def shot_css(height_mm):
    return FONT_FACES + BASE_CSS + f"""
@page {{ size: {IMG_W_MM + 12:.1f}mm {height_mm:.1f}mm; margin: 0; }}
body {{ text-align: center; }}
.cap {{ padding: 6mm 6mm 0; font-weight: 700; color: #B3872A;
  font-size: 11pt; }}
.lang {{ color: #555D6B; font-size: 8.5pt; margin-top: 1.2mm; }}
img {{ width: {IMG_W_MM}mm; margin: 4mm auto 0; display: block;
  border: 1px solid #E8E8E8; }}
"""


def print_pdf(html, pdf):
    path = f'{pdf}.html'
    with open(path, 'w', encoding='utf-8') as fh:
        fh.write(html)
    subprocess.run([
        'chromium', '--headless', '--no-sandbox', '--disable-gpu',
        '--allow-file-access-from-files', '--no-pdf-header-footer',
        '--virtual-time-budget=10000', f'--print-to-pdf={pdf}',
        f'file://{path}',
    ], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def page(html_body, css):
    return ('<!doctype html><html lang="ar" dir="rtl"><head><meta charset='
            f'"utf-8"><title>{D.TITLE}</title><style>{css}</style></head>'
            f'<body>{html_body}</body></html>')


def cover_html(total):
    return page(
        f'<div class="cover"><h1>{D.TITLE}</h1>'
        f'<div class="sub gold">{D.SUBTITLE}</div>'
        f'<div class="meta grey">{total} شاشة موزّعة على '
        f'{len(D.SECTIONS)} واجهات<br>{D.YEAR}</div>'
        f'<div class="note grey">{D.NOTE}</div></div>', A4_CSS)


def toc_html(rows):
    body = ['<h2>المحتويات</h2>']
    for i, section in enumerate(D.SECTIONS, 1):
        count = D.screen_count(rows, section['folder'])
        body.append(f'<div class="toc-row"><span>{i}. '
                    f'{escape(section["title"])}</span>'
                    f'<span class="grey">{count} شاشة</span></div>')
    body.append(f'<div class="toc-row"><span>{len(D.SECTIONS) + 1}. '
                f'{D.ACTIVATION_TITLE}</span>'
                '<span class="grey">صفحة واحدة</span></div>')
    return page(''.join(body), A4_CSS)


def section_html(index, section, count):
    body = [f'<div class="num gold">{index}</div>',
            f'<h2>{escape(section["title"])}</h2>',
            f'<p class="lead grey">{escape(section["intro"])}</p>',
            '<h3 class="gold">ما تم إنجازه</h3><ul>']
    body += [f'<li>{escape(p)}</li>' for p in section['points']]
    body.append(f'</ul><p class="lead grey" style="margin-top:8mm">وفيما يلي '
                f'{count} شاشة من هذه الواجهة.</p>')
    return page(''.join(body), A4_CSS)


def shot_html(row):
    height = IMG_W_MM * row['ratio'] + CAPTION_MM
    return page(
        f'<div class="cap">{escape(row["title"] + row["cont"])}</div>'
        f'<div class="lang">{escape(D.LANG_AR.get(row["lang"], ""))}</div>'
        f'<img src="file://{quote(row["path"])}">',
        shot_css(height))


def notes_html(index):
    body = [f'<div class="num gold">{index}</div>',
            f'<h2>{D.ACTIVATION_TITLE}</h2>',
            f'<p class="lead grey">{escape(D.ACTIVATION_LEAD)}</p>']
    for title, text in D.ACTIVATION_NOTES:
        body.append(f'<div class="note-title">{escape(title)}</div>'
                    f'<div>{escape(text)}</div>')
    return page(''.join(body), A4_CSS)


def build():
    import pikepdf

    os.makedirs(WORK, exist_ok=True)
    rows = D.shots()
    pages = []

    def emit(html, name):
        pdf = os.path.join(WORK, f'{name}.pdf')
        print_pdf(html, pdf)
        pages.append(pdf)

    emit(cover_html(D.screen_count(rows)), '00-cover')
    emit(toc_html(rows), '01-toc')
    for i, section in enumerate(D.SECTIONS, 1):
        group = D.section_shots(rows, section['folder'])
        if not group:
            continue
        emit(section_html(i, section, len(group)), f'section-{i}')
        for j, row in enumerate(group):
            emit(shot_html(row), f'shot-{i:02d}-{j:03d}')
    emit(notes_html(len(D.SECTIONS) + 1), 'notes')

    with pikepdf.new() as merged:
        for pdf in pages:
            with pikepdf.open(pdf) as src:
                merged.pages.extend(src.pages)
        for key in ('/Producer', '/Creator', '/Subject', '/Keywords',
                    '/CreationDate', '/ModDate'):
            if key in merged.docinfo:
                del merged.docinfo[key]
        merged.docinfo['/Title'] = D.TITLE
        merged.docinfo['/Author'] = 'All Owners'
        merged.save(OUT)

    print('wrote', OUT, 'screens:', len(rows), 'pages:', len(pages),
          'size MB:', round(os.path.getsize(OUT) / 1048576, 1))


if __name__ == '__main__':
    build()
