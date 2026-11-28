import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'image_diff.dart';
import 'screenshot_support.dart';

/// سياسة المقارن: المساواة البكسلية هي البوابة، والتسامح وضع تشخيص صريح.
///
/// هذا الملف يثبت **السياسة**، و`test/screenshot_visual_regression_test.dart`
/// يثبت أن أنواع التغيير البصري الحقيقية تُرفض على لقطات فعلية من التطبيق.
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

  Future<Uint8List> driftVersion() => png((canvas) {
        canvas.drawRect(
          const Rect.fromLTWH(20, 20, 160, 40),
          Paint()..color = const Color(0xFF143458),
        );
      });

  Future<Uint8List> baseVersion() => png((canvas) {
        canvas.drawRect(
          const Rect.fromLTWH(20, 20, 160, 40),
          Paint()..color = const Color(0xFF123456),
        );
      });

  test('الوضع الافتراضي صارم: فرق طفيف يُرفض', () async {
    final uri = await writeGolden(await baseVersion());
    final comparator = ScreenshotComparator();

    await expectLater(
      comparator.compare(await driftVersion(), uri),
      throwsA(isA<FlutterError>()),
    );
  });

  test('الوضع الافتراضي صارم: المطابق تمامًا يمرّ', () async {
    final golden = await baseVersion();
    final uri = await writeGolden(golden);
    final comparator = ScreenshotComparator();

    expect(await comparator.compare(golden, uri), isTrue);
  });

  test('وضع التشخيص يقبل الانحراف الصغير فقط', () async {
    expect(
      await ScreenshotComparator.verdict(
        await driftVersion(),
        await baseVersion(),
        tolerant: true,
      ),
      DiffVerdict.driftAccepted,
    );
    expect(
      await ScreenshotComparator.verdict(
        await driftVersion(),
        await baseVersion(),
      ),
      DiffVerdict.rejected,
    );
  });

  test('اختلاف الأبعاد يُرفض في الوضعين', () async {
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawRect(
      const Rect.fromLTWH(0, 0, 100, 100),
      Paint()..color = const Color(0xFFFFFFFF),
    );
    final image = await recorder.endRecording().toImage(100, 100);
    final small = (await image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();

    expect(
      await ScreenshotComparator.verdict(small, await baseVersion(),
          tolerant: true),
      DiffVerdict.rejected,
    );
  });

  test('العتبات معلنة وصغيرة بما يكفي لكشف تغيير موضعي', () {
    // مربّع 24×24 = 576 بكسل. 0.5% = أقل من 3 بكسلات: حرف واحد يكفي.
    expect(kRasterDriftLimits.maxBlockInkFlip, lessThanOrEqualTo(0.5));
    expect(kRasterDriftLimits.maxBlockMean, lessThanOrEqualTo(12));
    expect(kRasterDriftLimits.maxDiffPercent, lessThanOrEqualTo(1.5));
    expect(kSolidInkLuminance, lessThan(kInkLuminance));
    expect(kInkLuminance, lessThan(kSolidBackgroundLuminance));
  });
}
