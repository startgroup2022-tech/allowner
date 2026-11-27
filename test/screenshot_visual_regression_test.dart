import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'image_diff.dart';
import 'screenshot_support.dart';

/// بوابة اللقطات: إثبات أن المقارن **لا** يسمح بتغيير بصري حقيقي، وأن
/// التسامح (وضع التشخيص فقط) لا يخفي تغييرًا صغيرًا.
///
/// الاختبارات تعمل على لقطة حقيقية من `docs/evidence` (رسم فعلي لشاشة إنتاج)
/// بعد تعديل منطقة صغيرة منها — لا صور مصطنعة بالكامل — إضافة إلى ضجيج
/// صناعي يُحاكي انحراف محرّك الرسم.
const String _evidenceDir = 'docs/evidence/final-acceptance';

/// لقطة عربية حقيقية فيها نص وأيقونات.
const String _realShot =
    '$_evidenceDir/customer/arabic/DOC06-REQ-006-my-bookings-ar.png';

/// لقطة شاشة حجز فيها زر إجراء كبير مُعبّأ.
const String _buttonShot =
    '$_evidenceDir/customer/arabic/DOC05-REQ-031-034-booking-ar.png';

class _Image {
  _Image(this.width, this.height, this.rgba);

  final int width;
  final int height;
  final Uint8List rgba;

  int get pixelCount => width * height;

  void setPixel(int x, int y, int r, int g, int b) {
    final i = (y * width + x) * 4;
    rgba[i] = r;
    rgba[i + 1] = g;
    rgba[i + 2] = b;
    rgba[i + 3] = 255;
  }

  (int, int, int) pixel(int x, int y) {
    final i = (y * width + x) * 4;
    return (rgba[i], rgba[i + 1], rgba[i + 2]);
  }

  _Image clone() => _Image(width, height, Uint8List.fromList(rgba));

  /// يحوّل منطقة إلى اللون المحدّد (يحاكي زرًّا محذوفًا أو لونًا خاطئًا).
  void fill(int x, int y, int w, int h, int r, int g, int b) {
    for (var yy = y; yy < y + h && yy < height; yy++) {
      for (var xx = x; xx < x + w && xx < width; xx++) {
        setPixel(xx, yy, r, g, b);
      }
    }
  }

  /// ينسخ منطقة من مكانها إلى مكان آخر (يحاكي عنصرًا تحرّك).
  void moveRegion(int x, int y, int w, int h, int dx, int dy) {
    final snapshot = <List<(int, int, int)>>[];
    for (var yy = 0; yy < h; yy++) {
      final row = <(int, int, int)>[];
      for (var xx = 0; xx < w; xx++) {
        row.add(pixel(x + xx, y + yy));
      }
      snapshot.add(row);
    }
    for (var yy = 0; yy < h; yy++) {
      for (var xx = 0; xx < w; xx++) {
        final p = snapshot[yy][xx];
        final tx = x + xx + dx;
        final ty = y + yy + dy;
        if (tx < 0 || ty < 0 || tx >= width || ty >= height) continue;
        setPixel(tx, ty, p.$1, p.$2, p.$3);
      }
    }
  }

  /// يبحث عن نافذة [w]×[h] بها أكبر قدر من الحبر بين الصفوف [yFrom..yTo]،
  /// كي لا يعتمد الاختبار على إحداثيات مخمّنة: يجد عنصرًا حقيقيًا في الصورة.
  (int, int) findInkWindow(int w, int h, int yFrom, int yTo) {
    var best = 0;
    var at = (0, yFrom);
    for (var y = yFrom; y + h <= yTo && y + h <= height; y += 4) {
      for (var x = 0; x + w <= width; x += 4) {
        var ink = 0;
        for (var yy = y; yy < y + h; yy += 2) {
          for (var xx = x; xx < x + w; xx += 2) {
            final p = pixel(xx, yy);
            final lum = (p.$1 * 299 + p.$2 * 587 + p.$3 * 114) ~/ 1000;
            if (lum < kInkLuminance) ink++;
          }
        }
        if (ink > best) {
          best = ink;
          at = (x, y);
        }
      }
    }
    return at;
  }

  /// يحذف كل «الحبر» (النص/الأيقونة) في منطقة: يحاكي اختفاء نص أو أيقونة.
  void eraseInk(int x, int y, int w, int h, int bg) {
    for (var yy = y; yy < y + h && yy < height; yy++) {
      for (var xx = x; xx < x + w && xx < width; xx++) {
        final p = pixel(xx, yy);
        final lum = (p.$1 * 299 + p.$2 * 587 + p.$3 * 114) ~/ 1000;
        if (lum < kInkLuminance) setPixel(xx, yy, bg, bg, bg);
      }
    }
  }

  /// ضجيج منخفض الشدّة على كل البكسلات: يحاكي اختلاف تنعيم الحروف بين
  /// إصداري محرّك رسم.
  void addNoise(int amplitude, int seed) {
    final random = Random(seed);
    for (var i = 0; i < rgba.length; i += 4) {
      for (var c = 0; c < 3; c++) {
        final jitter = random.nextInt(amplitude * 2 + 1) - amplitude;
        rgba[i + c] = (rgba[i + c] + jitter).clamp(0, 255);
      }
    }
  }
}

Future<_Image?> _load(String path) async {
  final file = File(path);
  if (!file.existsSync()) return null;
  final decoded = await decodePng(await file.readAsBytes());
  if (decoded == null) return null;
  return _Image(decoded.$1, decoded.$2, decoded.$3);
}

Future<Uint8List?> _png(_Image image) =>
    encodePng(image.rgba, image.width, image.height);

/// يقارن نسخة معدّلة بالنسخة الأصلية ويعيد الحكم.
Future<DiffVerdict> _judge(_Image original, _Image changed,
    {bool tolerant = true}) async {
  final a = await _png(changed);
  final b = await _png(original);
  expect(a, isNotNull);
  expect(b, isNotNull);
  return ScreenshotComparator.verdict(a!, b!, tolerant: tolerant);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Image shot;
  late _Image withButton;

  setUpAll(() async {
    final loaded = await _load(_realShot);
    expect(loaded, isNotNull, reason: 'لقطة مرجعية مفقودة: $_realShot');
    shot = loaded!;
    final button = await _load(_buttonShot);
    expect(button, isNotNull, reason: 'لقطة مرجعية مفقودة: $_buttonShot');
    withButton = button!;
  });

  group('الوضع الصارم (الافتراضي)', () {
    test('أي فرق بكسل واحد يُرفض', () async {
      final changed = shot.clone();
      final (r, g, b) = changed.pixel(10, 10);
      changed.setPixel(10, 10, (r + 1).clamp(0, 255), g, b);

      expect(
          await _judge(shot, changed, tolerant: false), DiffVerdict.rejected);
    });

    test('الصورة نفسها مطابقة', () async {
      expect(await _judge(shot, shot.clone(), tolerant: false),
          DiffVerdict.identical);
    });
  });

  group('انحراف محرّك الرسم (وضع التشخيص)', () {
    test('ضجيج منخفض الشدّة على كل الصورة يُقبل', () async {
      final noisy = shot.clone()..addNoise(4, 7);

      final diff = analyzeRgba(noisy.rgba, shot.rgba, shot.width, shot.height)!;
      expect(isRasterDriftOnly(diff), isTrue, reason: '$diff');
      expect(await _judge(shot, noisy), DiffVerdict.driftAccepted);
    });
  });

  group('تغييرات بصرية حقيقية تُرفض حتى مع التسامح', () {
    test('نص مُبدَّل: إزالة حبر عنوان حقيقي', () async {
      // نجد سطر عنوان حقيقيًا في أعلى الشاشة بدل تخمين إحداثيات.
      final (x, y) = shot.findInkWindow(150, 22, 0, shot.height ~/ 3);
      final changed = shot.clone()..eraseInk(x, y, 150, 22, 255);

      final diff =
          analyzeRgba(changed.rgba, shot.rgba, shot.width, shot.height)!;
      expect(diff.maxBlockInkFlip, greaterThan(0.5), reason: '$diff');
      expect(await _judge(shot, changed), DiffVerdict.rejected);
    });

    test('أيقونة مفقودة: مسح مربّع أيقونة حقيقي', () async {
      final (x, y) = shot.findInkWindow(24, 24, 0, shot.height ~/ 3);
      final changed = shot.clone()..eraseInk(x, y, 24, 24, 255);

      expect(await _judge(shot, changed), DiffVerdict.rejected);
    });

    test('زر مفقود: تحويل زر حقيقي إلى خلفية الصفحة', () async {
      final (x, y) = withButton.findInkWindow(
          200, 40, withButton.height ~/ 2, withButton.height);
      final changed = withButton.clone()..fill(x, y, 200, 40, 255, 255, 255);

      expect(await _judge(withButton, changed), DiffVerdict.rejected);
    });

    test('لون خاطئ: تغيير لون شريط علوي', () async {
      final changed = shot.clone()..fill(0, 0, shot.width, 40, 200, 30, 30);

      expect(await _judge(shot, changed), DiffVerdict.rejected);
    });

    test('عنصر تحرّك: إزاحة كتلة نصية 6 بكسل', () async {
      final (x, y) =
          shot.findInkWindow(160, 20, shot.height ~/ 4, shot.height ~/ 2);
      final changed = shot.clone()..moveRegion(x, y, 160, 20, 0, 6);

      expect(await _judge(shot, changed), DiffVerdict.rejected);
    });

    test('حرف واحد داخل كلمة يُرفض', () async {
      // تغيير بكسلات حبر قليلة جدًا في سطر نصي (أصغر من 0.01% من الصورة).
      final (wx, wy) = shot.findInkWindow(150, 22, 0, shot.height ~/ 3);
      final changed = shot.clone();
      var painted = 0;
      for (var y = wy; y < wy + 22 && painted < 40; y++) {
        for (var x = wx; x < wx + 150 && painted < 40; x++) {
          final (r, g, b) = changed.pixel(x, y);
          final lum = (r * 299 + g * 587 + b * 114) ~/ 1000;
          if (lum < kInkLuminance) {
            // حبر اختفى: كما لو استُبدل حرف بمسافة.
            changed.setPixel(x, y, 255, 255, 255);
            painted++;
          }
        }
      }
      expect(painted, greaterThan(0));

      final diff =
          analyzeRgba(changed.rgba, shot.rgba, shot.width, shot.height)!;
      // التغيير أصغر من أي عتبة كلية تقليدية…
      expect(diff.diffPercent, lessThan(0.05), reason: '$diff');
      // …ومع ذلك يُكشف محليًا.
      expect(await _judge(shot, changed), DiffVerdict.rejected);
    });
  });

  group('حدود التحليل', () {
    test('أبعاد مختلفة تُرفض', () async {
      final small = _Image(shot.width ~/ 2, shot.height ~/ 2,
          Uint8List(shot.width * shot.height));
      final a = await _png(small);
      final b = await _png(shot);
      expect(await ScreenshotComparator.verdict(a!, b!), DiffVerdict.rejected);
    });

    test('الصورة المرجعية الحقيقية موجودة في مسار الأدلة', () {
      expect(File(_realShot).existsSync(), isTrue);
    });
  });
}
