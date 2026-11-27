import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'screenshot_support.dart';

/// يثبت أن مقارن اللقطات ما زال يكشف الانحدار الحقيقي رغم تسامحه مع فروق
/// التنعيم. بلا هذا الاختبار قد يصبح التسامح بابًا يمرّ منه أي تغيير بصري.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('shot_cmp');
  });
  tearDown(() async {
    if (temp.existsSync()) await temp.delete(recursive: true);
  });

  Future<Uint8List> png(void Function(Canvas canvas) paint) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 200, 200),
      Paint()..color = const Color(0xFFFFFFFF),
    );
    paint(canvas);
    final image = await recorder.endRecording().toImage(200, 200);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  Future<Uri> writeGolden(Uint8List bytes) async {
    final file = File('${temp.path}/golden.png');
    await file.writeAsBytes(bytes);
    return file.uri;
  }

  test('الاختلاف الطفيف (تنعيم) يمرّ', () async {
    final golden = await png((canvas) {
      canvas.drawRect(
        const Rect.fromLTWH(20, 20, 160, 40),
        Paint()..color = const Color(0xFF123456),
      );
    });
    final uri = await writeGolden(golden);

    // نفس الشكل مع وردية أفتح قليلًا في حدود الحروف: فرق صغير في كل قناة.
    final drifted = await png((canvas) {
      canvas.drawRect(
        const Rect.fromLTWH(20, 20, 160, 40),
        Paint()..color = const Color(0xFF143458),
      );
    });

    final comparator = ScreenshotComparator();
    expect(await comparator.compare(drifted, uri), isTrue);
  });

  test('تغيّر عنصر حقيقي يُفشل المقارنة', () async {
    final golden = await png((canvas) {
      canvas.drawRect(
        const Rect.fromLTWH(20, 20, 160, 40),
        Paint()..color = const Color(0xFF123456),
      );
    });
    final uri = await writeGolden(golden);

    // مستطيل أسود كبير مكان مساحة بيضاء: انحدار تخطيط واضح.
    final changed = await png((canvas) {
      canvas.drawRect(
        const Rect.fromLTWH(20, 20, 160, 40),
        Paint()..color = const Color(0xFF123456),
      );
      canvas.drawRect(
        const Rect.fromLTWH(10, 100, 180, 90),
        Paint()..color = const Color(0xFF000000),
      );
    });

    final comparator = ScreenshotComparator();
    await expectLater(
      comparator.compare(changed, uri),
      throwsA(isA<FlutterError>()),
    );
  });

  test('اختلاف الأبعاد يُفشل دائمًا', () async {
    final golden = await png((canvas) {
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 200, 200),
        Paint()..color = const Color(0xFFFFFFFF),
      );
    });
    final uri = await writeGolden(golden);

    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawRect(
      const Rect.fromLTWH(0, 0, 100, 100),
      Paint()..color = const Color(0xFFFFFFFF),
    );
    final image = await recorder.endRecording().toImage(100, 100);
    final small = (await image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();

    final comparator = ScreenshotComparator();
    await expectLater(
      comparator.compare(small, uri),
      throwsA(isA<FlutterError>()),
    );
  });
}
