import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/content_service.dart';

/// إعدادات التطبيق العامة (الشعار وبيانات التواصل) — تُجلب من لوحة تحكم السي بانل
/// حتى تقدر الإدارة تغيّر الشعار أو بيانات التواصل بدون إعادة نشر التطبيق.
final appSettingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    return await ContentService().getSettings();
  } catch (_) {
    return {};
  }
});
