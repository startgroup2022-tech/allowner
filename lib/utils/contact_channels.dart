/// بناء قنوات التواصل مع الدعم (المتطلب 8).
///
/// بيانات الاتصال تأتي حقيقية من `content/settings.php` (هاتف/واتساب/بريد)،
/// وهذه الدوال النقية تحوّلها إلى روابط قابلة للفتح. الغرض من فصلها هو إثبات
/// الرابط الناتج باختبار بدل الاعتماد على زر لا يمكن التحقق من مخرجاته.
library;

class ContactChannels {
  ContactChannels._();

  /// يُبقي الأرقام وعلامة + فقط — الأرقام تُكتب أحيانًا بمسافات أو شرطات.
  static String digitsOnly(String value) =>
      value.replaceAll(RegExp(r'[^0-9+]'), '');

  /// رابط محادثة واتساب. `wa.me` لا يقبل علامة + ولا مسافات.
  static String? whatsappUri(String? phone) {
    final digits = digitsOnly(phone ?? '').replaceAll('+', '');
    if (digits.isEmpty) return null;
    return 'https://wa.me/$digits';
  }

  /// رابط اتصال هاتفي.
  static String? telUri(String? phone) {
    final digits = digitsOnly(phone ?? '');
    if (digits.isEmpty) return null;
    return 'tel:$digits';
  }

  /// رابط بريد إلكتروني، مع ترميز الموضوع حتى يعمل مع العناوين العربية.
  static String? mailUri(String? email, {String? subject}) {
    final address = (email ?? '').trim();
    if (address.isEmpty || !address.contains('@')) return null;
    if (subject == null || subject.trim().isEmpty) return 'mailto:$address';
    return 'mailto:$address?subject=${Uri.encodeComponent(subject.trim())}';
  }
}
