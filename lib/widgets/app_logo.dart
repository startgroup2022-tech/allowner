import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/app_settings_provider.dart';

/// شعار التطبيق.
/// - [full] = true: الشعار الكامل (الأيقونة + الاسم) — يُجلب من لوحة التحكم (قابل للتغيير
///   من الإدارة بدون إعادة نشر التطبيق) ويرجع للنسخة المحلية وقت التحميل أو لو انقطع الاتصال.
///   الشعار الكامل نصّه أبيض، فيُعرض دائمًا فوق خلفية داكنة.
/// - [full] = false: أيقونة الشعار الذهبية فقط (تناسب الخلفيات الفاتحة مثل رأس الصفحة الرئيسية).
class AppLogo extends ConsumerWidget {
  final double width;
  final bool full;

  const AppLogo({super.key, required this.width, this.full = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!full) {
      return Image.asset('assets/images/logo.png', width: width, fit: BoxFit.contain);
    }

    final localFallback = Image.asset('assets/images/logo_full.png', width: width, fit: BoxFit.contain);
    final settings = ref.watch(appSettingsProvider);

    return settings.when(
      data: (data) {
        final url = data['logo_url']?.toString();
        if (url == null || url.isEmpty) return localFallback;
        return CachedNetworkImage(
          imageUrl: url,
          width: width,
          fit: BoxFit.contain,
          placeholder: (context, _) => localFallback,
          errorWidget: (context, _, __) => localFallback,
        );
      },
      loading: () => localFallback,
      error: (_, __) => localFallback,
    );
  }
}
