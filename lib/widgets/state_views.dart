import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../utils/app_strings.dart';

/// حالة تحميل موحّدة (Skeleton/Spinner) — تُستخدم في كل الشاشات حتى لا تتكرر
/// نسخ مختلفة من مؤشر التحميل.
class LoadingView extends StatelessWidget {
  final double height;
  const LoadingView({super.key, this.height = 160});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
              strokeWidth: 2.4, color: AppColors.gold),
        ),
      ),
    );
  }
}

/// حالة خطأ موحّدة مع زر إعادة المحاولة. تُميّز بين أخطاء الشبكة التي يمكن
/// إعادة المحاولة فيها، وأخطاء الجلسة المنتهية التي تحتاج تسجيل دخول.
class ErrorView extends StatelessWidget {
  final String message;
  final bool isArabic;
  final VoidCallback? onRetry;
  final bool compact;

  const ErrorView({
    super.key,
    required this.message,
    required this.isArabic,
    this.onRetry,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? AppDimens.md : AppDimens.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: compact ? 30 : 40, color: AppColors.textMuted),
            const SizedBox(height: AppDimens.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style:
                  textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppDimens.sm),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(AppStrings.t(isArabic, 'retry')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// حالة فراغ موحّدة (لا نتائج / لا بيانات) مع إجراء اختياري.
class EmptyView extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  const EmptyView({
    super.key,
    this.icon = Icons.search_off_rounded,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? AppDimens.md : AppDimens.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 52 : 68,
              height: compact ? 52 : 68,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppDimens.radiusLg),
              ),
              child: Icon(icon,
                  size: compact ? 24 : 30, color: AppColors.textMuted),
            ),
            const SizedBox(height: AppDimens.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppDimens.sm),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// صورة شبكية موحّدة: تحميل، خطأ، وصورة بديلة واضحة.
///
/// ملاحظة مهمة: السيرفر يعيد أحيانًا رابط الصورة فارغًا أو مسارًا غير صالح،
/// لذلك لا نمرّر رابطًا فارغًا إلى CachedNetworkImage (يرمي استثناء) بل نعرض
/// العنصر البديل مباشرة.
class AppNetworkImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final child = _buildImage();
    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }

  Widget _buildImage() {
    if (url.trim().isEmpty) return _fallback();

    return CachedNetworkImage(
      imageUrl: url.trim(),
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (context, _) => Container(
        width: width,
        height: height,
        color: AppColors.surfaceMuted,
        alignment: Alignment.center,
        child: const SizedBox(
          width: 20,
          height: 20,
          child:
              CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
        ),
      ),
      errorWidget: (context, _, __) => _fallback(),
    );
  }

  Widget _fallback() => Container(
        width: width,
        height: height,
        color: AppColors.surfaceMuted,
        alignment: Alignment.center,
        child: Icon(
          Icons.image_outlined,
          color: AppColors.textMuted,
          size: (height ?? 40) < 60 ? 22 : 34,
        ),
      );
}
