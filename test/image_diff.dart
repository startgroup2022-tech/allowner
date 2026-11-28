/// تحليل فروق الصور لبوابة لقطات الشاشة.
///
/// لا يعتمد على أي حزمة خارجية: يفكّ ترميز PNG عبر `dart:ui` (متاح في
/// `flutter_test`) ويقيس أربع إشارات مستقلة، لأن أي عتبة كلية واحدة يمكن أن
/// تُخفي تغييرًا صغيرًا مهمًا (نص، أيقونة، زر، لون، إزاحة):
///
///   • `diffPercent`   — نسبة البكسلات التي تغيّرت بوضوح.
///   • `meanDelta`     — متوسط فرق القناة على كل الصورة.
///   • `maxBlockMean`  — أعلى متوسط فرق في مربّع 24×24. يكشف تغييرًا موضعيًا
///                        صغيرًا (حرف واحد، أيقونة) لا تُظهره النسب الكلية.
///   • `maxBlockInkFlip` — أكبر نسبة بكسلات انتقلت بين «حبر صلب» و«خلفية
///                        صلبة» داخل مربّع. هذا هو الكاشف الحقيقي للنص والأيقونة
///                        والزر: تنعيم الحروف يُحرّك الحدّ بمقدار أقل من بكسل
///                        فلا يعبر من حبر صلب إلى خلفية صلبة، بينما حرف مُبدَّل
///                        أو أيقونة محذوفة يعبرها فورًا.
///   • `strongPercent` — نسبة البكسلات ذات الفرق الكبير (≥64).
library;

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

/// نتيجة مقارنة صورتين بنفس الأبعاد.
class RgbaDiff {
  const RgbaDiff({
    required this.width,
    required this.height,
    required this.diffPercent,
    required this.meanDelta,
    required this.maxBlockMean,
    required this.maxBlockInkFlip,
    required this.strongPercent,
    required this.worstBlock,
  });

  final int width;
  final int height;

  /// نسبة البكسلات التي تجاوز فرقها 16/255.
  final double diffPercent;

  /// متوسط أعلى فرق قناة على كل البكسلات.
  final double meanDelta;

  /// أعلى متوسط فرق داخل مربّع 24×24.
  final double maxBlockMean;

  /// أعلى نسبة (من مساحة المربّع 24×24) لبكسلات انتقلت بين حبر صلب وخلفية
  /// صلبة. يكشف النص/الأيقونة/الزر المفقود حتى لو كان التغيّر الكلي ضئيلًا.
  final double maxBlockInkFlip;

  /// نسبة البكسلات ذات الفرق ≥64.
  final double strongPercent;

  /// موقع أسوأ مربّع (س، ص) لتشخيص الفشل.
  final (int, int) worstBlock;

  bool get isIdentical =>
      diffPercent == 0 && meanDelta == 0 && maxBlockInkFlip == 0;

  @override
  String toString() =>
      'diff=${diffPercent.toStringAsFixed(3)}% mean=${meanDelta.toStringAsFixed(2)} '
      'worstBlockMean=${maxBlockMean.toStringAsFixed(1)} '
      'worstBlockInkFlip=${maxBlockInkFlip.toStringAsFixed(2)}% '
      'strong=${strongPercent.toStringAsFixed(3)}% at $worstBlock';
}

/// حدود قبول «انحراف محرّك الرسم» فقط — ليست حدود قبول تغيير تصميم.
///
/// أي تغيير في النص أو الأيقونة أو الزر أو اللون أو الموضع يخرق واحدًا منها
/// على الأقل (مُثبت في `test/screenshot_comparator_test.dart`).
class RasterDriftLimits {
  const RasterDriftLimits({
    this.maxDiffPercent = 1.5,
    this.maxMeanDelta = 6.0,
    this.maxBlockMean = 12.0,
    this.maxBlockInkFlip = 0.5,
    this.maxStrongPercent = 1.0,
  });

  final double maxDiffPercent;
  final double maxMeanDelta;
  final double maxBlockMean;
  final double maxBlockInkFlip;
  final double maxStrongPercent;

  bool accepts(RgbaDiff diff) =>
      diff.diffPercent <= maxDiffPercent &&
      diff.meanDelta <= maxMeanDelta &&
      diff.maxBlockMean <= maxBlockMean &&
      diff.maxBlockInkFlip <= maxBlockInkFlip &&
      diff.strongPercent <= maxStrongPercent;
}

/// الحدود المستخدمة فعليًا في المقارن.
const RasterDriftLimits kRasterDriftLimits = RasterDriftLimits();

const int kDiffBlockSize = 24;

/// بكسل «حبر»: أي لون أغمق من هذا الحد (نص/أيقونة/حد).
const int kInkLuminance = 200;

/// «حبر صلب»: أغمق من هذا الحد بكثير، فلا يتأثر بتنعيم الحروف.
const int kSolidInkLuminance = 180;

/// «خلفية صلبة»: أفتح من هذا الحد بكثير.
const int kSolidBackgroundLuminance = 230;

/// عتبة «تغيّر واضح» لعدّ البكسلات.
const int kVisibleDelta = 16;

/// عتبة «تغيّر كبير».
const int kStrongDelta = 64;

/// يفكّ PNG إلى (عرض، ارتفاع، RGBA).
Future<(int, int, Uint8List)?> decodePng(Uint8List png) async {
  try {
    final codec = await ui.instantiateImageCodec(png);
    final frame = await codec.getNextFrame();
    final data =
        await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (data == null) return null;
    return (frame.image.width, frame.image.height, data.buffer.asUint8List());
  } catch (_) {
    return null;
  }
}

/// يُعيد ترميز RGBA إلى PNG (للاختبارات التي تُعدّل صورة حقيقية).
Future<Uint8List?> encodePng(Uint8List rgba, int width, int height) async {
  try {
    final completer = Completer<Uint8List?>();
    ui.decodeImageFromPixels(rgba, width, height, ui.PixelFormat.rgba8888,
        (image) async {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      completer.complete(data?.buffer.asUint8List());
    });
    return await completer.future;
  } catch (_) {
    return null;
  }
}

/// يقارن RGBA صورتين بنفس الأبعاد. يُرجع null إن اختلفت الأبعاد.
RgbaDiff? analyzeRgba(
  Uint8List a,
  Uint8List b,
  int width,
  int height, {
  int blockSize = kDiffBlockSize,
}) {
  if (a.length != b.length) return null;
  final pixels = width * height;
  if (a.length < pixels * 4) return null;

  var differing = 0;
  var strong = 0;
  var deltaSum = 0;

  final blocksX = (width + blockSize - 1) ~/ blockSize;
  final blocksY = (height + blockSize - 1) ~/ blockSize;
  final blockDeltaSum = List<int>.filled(blocksX * blocksY, 0);
  final blockPixels = List<int>.filled(blocksX * blocksY, 0);
  final blockInkFlip = List<int>.filled(blocksX * blocksY, 0);

  for (var y = 0; y < height; y++) {
    final rowBlock = (y ~/ blockSize) * blocksX;
    for (var x = 0; x < width; x++) {
      final i = (y * width + x) * 4;
      final dr = (a[i] - b[i]).abs();
      final dg = (a[i + 1] - b[i + 1]).abs();
      final db = (a[i + 2] - b[i + 2]).abs();
      final delta = dr > dg ? (dr > db ? dr : db) : (dg > db ? dg : db);

      deltaSum += delta;
      if (delta > kVisibleDelta) differing++;
      if (delta >= kStrongDelta) strong++;

      final block = rowBlock + (x ~/ blockSize);
      blockDeltaSum[block] += delta;
      blockPixels[block] += 1;

      final lumA = (a[i] * 299 + a[i + 1] * 587 + a[i + 2] * 114) ~/ 1000;
      final lumB = (b[i] * 299 + b[i + 1] * 587 + b[i + 2] * 114) ~/ 1000;
      final inkToBackground =
          lumA < kSolidInkLuminance && lumB > kSolidBackgroundLuminance;
      final backgroundToInk =
          lumB < kSolidInkLuminance && lumA > kSolidBackgroundLuminance;
      if (inkToBackground || backgroundToInk) blockInkFlip[block] += 1;
    }
  }

  var maxBlockMean = 0.0;
  var maxInkFlip = 0.0;
  var worst = (0, 0);
  for (var by = 0; by < blocksY; by++) {
    for (var bx = 0; bx < blocksX; bx++) {
      final index = by * blocksX + bx;
      final count = blockPixels[index];
      if (count == 0) continue;
      final mean = blockDeltaSum[index] / count;
      if (mean > maxBlockMean) {
        maxBlockMean = mean;
        worst = (bx, by);
      }
      final inkFlip = blockInkFlip[index] * 100 / count;
      if (inkFlip > maxInkFlip) maxInkFlip = inkFlip;
    }
  }

  return RgbaDiff(
    width: width,
    height: height,
    diffPercent: differing * 100 / pixels,
    meanDelta: deltaSum / pixels,
    maxBlockMean: maxBlockMean,
    maxBlockInkFlip: maxInkFlip,
    strongPercent: strong * 100 / pixels,
    worstBlock: worst,
  );
}

/// يكشف ما إذا كان الفرق انحراف رسم فقط. `null` يعني أبعادًا مختلفة = رفض.
bool isRasterDriftOnly(RgbaDiff? diff) =>
    diff != null && kRasterDriftLimits.accepts(diff);
