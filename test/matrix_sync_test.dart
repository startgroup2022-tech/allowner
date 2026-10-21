import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// حارس ضد انحراف المصفوفة عن مصدر بياناتها.
///
/// `docs/ALL_OWNERS_REQUIREMENTS_MATRIX.md` مُولَّد من `tools/matrix_data.py`.
/// حدث سابقًا أن حُرِّرت المصفوفة يدويًا بلا تحديث المُولِّد، فتناقضت التقارير
/// (59/57/25/4 في الملف مقابل 53/47/42/3 عند إعادة التوليد). هذا الاختبار يفشل
/// فورًا عند تكرار ذلك، فيبقى الملف والمُولِّد مصدر حقيقة واحدًا.
void main() {
  final matrixFile = File('docs/ALL_OWNERS_REQUIREMENTS_MATRIX.md');
  final dataFile = File('tools/matrix_data.py');

  Map<int, String> parseMatrix(String text) {
    final out = <int, String>{};
    final blockRe = RegExp(r'^### (\d+)\.\s', multiLine: true);
    for (final m in blockRe.allMatches(text)) {
      final id = int.parse(m.group(1)!);
      final rest = text.substring(m.end);
      final next = blockRe.firstMatch(rest);
      final block = next == null ? rest : rest.substring(0, next.start);
      final st = RegExp(r'\*\*الحالة:\*\*\s*(.+)').firstMatch(block);
      if (st != null) out[id] = st.group(1)!.trim();
    }
    return out;
  }

  Map<int, String> parseData(String text) {
    final out = <int, String>{};
    final re = RegExp(r"^\s*(\d+):\s*\(\d+,\s*'([^']*)'", multiLine: true);
    for (final m in re.allMatches(text)) {
      out[int.parse(m.group(1)!)] = m.group(2)!;
    }
    return out;
  }

  test('المصفوفة تُطابق tools/matrix_data.py بالكامل', () {
    expect(matrixFile.existsSync(), isTrue,
        reason: 'docs/ALL_OWNERS_REQUIREMENTS_MATRIX.md مفقود');
    expect(dataFile.existsSync(), isTrue, reason: 'tools/matrix_data.py مفقود');

    final matrix = parseMatrix(matrixFile.readAsStringSync());
    final data = parseData(dataFile.readAsStringSync());

    expect(data.length, 148, reason: 'يجب أن يحمل المُولِّد 148 متطلبًا');
    expect(matrix.length, 148, reason: 'يجب أن تحمل المصفوفة 148 متطلبًا');

    final drifted = <int>[];
    for (final id in data.keys) {
      if (matrix[id] != data[id]) {
        drifted.add(id);
      }
    }
    expect(
      drifted,
      isEmpty,
      reason: 'حالات متطلبات تختلف بين المصفوفة والمُولِّد: $drifted — '
          'شغّل `python3 tools/gen_requirements_matrix.py` بدل التحرير اليدوي',
    );
  });

  test('لا توجد حالة غير معروفة في المصفوفة', () {
    const known = {
      'VERIFIED PASS',
      'INTEGRATION VERIFIED',
      'IMPLEMENTED UNTESTED',
      'PARTIAL',
      'NOT IMPLEMENTED',
      'BACKEND BLOCKED',
      'OWNER DECISION REQUIRED',
    };
    final matrix = parseMatrix(matrixFile.readAsStringSync());
    final unknown = {
      for (final e in matrix.entries)
        if (!known.contains(e.value)) e.key: e.value,
    };
    expect(unknown, isEmpty, reason: 'حالات غير معروفة: $unknown');
  });
}
