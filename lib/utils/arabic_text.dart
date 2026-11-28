/// تطبيع النص العربي للمقارنة والبحث.
///
/// العربية تُكتب بأشكال متعددة لنفس الكلمة: «مكة» و«مكه»، «الرياض» و«الريآض»،
/// مع أو بدون تشكيل أو تطويل. تطبيع واحد مشترك يمنع اختلاف نتائج البحث عن
/// نتائج ترتيب الوجهات — وهو ما كان يحدث حين كان كل ملف يطبّع بطريقته.
library;

/// يُرجع نصًا مُطبّعًا (حروف صغيرة، بلا تشكيل/تطويل، بألف وهاء وياء موحّدة)،
/// أو null إن كان المدخل فارغًا أو null.
String? normalizeArabic(String? value) {
  if (value == null) return null;
  var text = value.trim().toLowerCase();
  if (text.isEmpty) return null;
  text = text
      .replaceAll(RegExp(r'[\u064B-\u0652\u0670\u0640]'), '') // تشكيل + تطويل
      .replaceAll(RegExp('[أإآٱ]'), 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي')
      .replaceAll('ؤ', 'و')
      .replaceAll('ئ', 'ي');
  return text;
}
