#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""نسخة Word من ملف تسليم العميل (نفس محتوى نسخة PDF)."""

import os
import sys

from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.shared import Cm, Pt

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import client_delivery_data as D  # noqa: E402
import gen_final_word_report as R  # noqa: E402

OUT = os.path.join(D.ROOT, 'docs/CLIENT_DELIVERY_BOOK_AR.docx')


def text_at(doc, text, size=11, bold=False, color=None, align='right',
            space_after=4, space_before=0, line=1.35):
    p = doc.add_paragraph()
    R.para_bidi(p)
    p.alignment = {'right': WD_ALIGN_PARAGRAPH.RIGHT,
                   'center': WD_ALIGN_PARAGRAPH.CENTER,
                   'justify': WD_ALIGN_PARAGRAPH.JUSTIFY}[align]
    p.paragraph_format.space_before = Pt(space_before)
    p.paragraph_format.space_after = Pt(space_after)
    p.paragraph_format.line_spacing = line
    R.run_font(p.add_run(text), size=size, bold=bold,
               color=color if color is not None else R.INK)
    return p


def build():
    rows = D.shots()
    doc = Document()
    R.setup_page(doc)
    R.setup_styles(doc)
    sec = doc.sections[0]
    sec.top_margin = Cm(1.6)
    sec.bottom_margin = Cm(1.4)
    sec.left_margin = Cm(1.8)
    sec.right_margin = Cm(1.8)

    header = sec.header.paragraphs[0]
    R.para_bidi(header)
    header.alignment = WD_ALIGN_PARAGRAPH.CENTER
    R.run_font(header.add_run(D.TITLE), size=8.5, color=R.GREY)
    footer = sec.footer.paragraphs[0]
    R.para_bidi(footer)
    footer.alignment = WD_ALIGN_PARAGRAPH.CENTER
    R.field(footer, 'PAGE')

    doc.add_paragraph().paragraph_format.space_after = Pt(140)
    text_at(doc, D.TITLE, 40, bold=True, align='center', space_after=12)
    text_at(doc, D.SUBTITLE, 17, color=R.GOLD, align='center', space_after=36)
    text_at(doc, f'{D.screen_count(rows)} شاشة موزّعة على '
                 f'{len(D.SECTIONS)} واجهات',
            12, color=R.GREY, align='center', space_after=6)
    text_at(doc, D.YEAR, 12, color=R.GREY, align='center', space_after=56)
    text_at(doc, D.NOTE, 10.5, color=R.GREY, align='center')

    doc.add_page_break()
    text_at(doc, 'المحتويات', 20, bold=True, align='right', space_after=8)
    for i, section in enumerate(D.SECTIONS, 1):
        count = D.screen_count(rows, section['folder'])
        row = doc.add_table(rows=1, cols=2)
        R.table_no_borders(row)
        for cell, width in ((row.cell(0, 0), 12.0), (row.cell(0, 1), 4.4)):
            cell.width = Cm(width)
        R.cell_text(row.cell(0, 0), f'{i}. {section["title"]}', size=10.5,
                    bold=True, align='right')
        R.cell_text(row.cell(0, 1), f'{count} شاشة', size=10,
                    color=R.GREY, align='left')
    row = doc.add_table(rows=1, cols=2)
    R.table_no_borders(row)
    for cell, width in ((row.cell(0, 0), 12.0), (row.cell(0, 1), 4.4)):
        cell.width = Cm(width)
    R.cell_text(row.cell(0, 0), f'{len(D.SECTIONS) + 1}. {D.ACTIVATION_TITLE}',
                size=10.5, bold=True, align='right')
    R.cell_text(row.cell(0, 1), 'صفحة واحدة', size=10, color=R.GREY,
                align='left')

    for i, section in enumerate(D.SECTIONS, 1):
        group = D.section_shots(rows, section['folder'])
        if not group:
            continue
        doc.add_page_break()
        text_at(doc, str(i), 12, color=R.GOLD, align='right', space_after=2)
        text_at(doc, section['title'], 24, bold=True, align='right',
                space_after=6)
        text_at(doc, section['intro'], 11.5, color=R.GREY, align='justify',
                space_after=12, line=1.4)
        text_at(doc, 'ما تم إنجازه', 13, bold=True, color=R.GOLD,
                align='right', space_after=6, space_before=6)
        for point in section['points']:
            p = doc.add_paragraph(style='List Bullet')
            R.para_bidi(p)
            p.alignment = WD_ALIGN_PARAGRAPH.RIGHT
            p.paragraph_format.space_after = Pt(5)
            p.paragraph_format.line_spacing = 1.4
            R.run_font(p.add_run(point), size=10.5, color=R.INK)
        text_at(doc, f'وفيما يلي {D.screen_count(rows, section["folder"])} '
                     'شاشة من هذه الواجهة.', 10,
                color=R.GREY, space_before=10)

        for row_data in group:
            doc.add_page_break()
            text_at(doc, row_data['title'] + row_data['cont'], 12.5,
                    bold=True, color=R.GOLD, align='center', space_after=2)
            text_at(doc, D.LANG_AR.get(row_data['lang'], ''), 9,
                    color=R.GREY, align='center', space_after=6)
            pic = doc.add_paragraph()
            R.para_bidi(pic)
            pic.alignment = WD_ALIGN_PARAGRAPH.CENTER
            pic.paragraph_format.space_after = Pt(0)
            R.add_pic(pic.add_run(), row_data['path'], max_w=17.4, max_h=23.4)

    doc.add_page_break()
    text_at(doc, str(len(D.SECTIONS) + 1), 12, color=R.GOLD, align='right',
            space_after=2)
    text_at(doc, D.ACTIVATION_TITLE, 22, bold=True, align='right',
            space_after=8)
    text_at(doc, D.ACTIVATION_LEAD, 11, color=R.GREY, align='justify',
            space_after=14, line=1.4)
    for title, body in D.ACTIVATION_NOTES:
        text_at(doc, title, 12.5, bold=True, align='right', space_after=2,
                space_before=8)
        text_at(doc, body, 10.5, align='justify', space_after=4, line=1.45)

    cp = doc.core_properties
    cp.author = 'All Owners'
    cp.last_modified_by = 'All Owners'
    cp.title = D.TITLE
    cp.subject = ''
    cp.comments = ''
    cp.keywords = ''
    cp.category = ''

    doc.save(OUT)
    print('wrote', OUT, 'screens:', len(rows))


if __name__ == '__main__':
    build()
