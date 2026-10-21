import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';
import '../../widgets/app_logo.dart';

/// المتطلبات 3 و4 و5: تعريف التطبيق والعبارة التعريفية.
///
/// نصّ الصفحة مأخوذ حرفيًا من مستند المتطلبات (صفحة «تعريف تطبيق All Owners»)
/// ولا يعتمد على محتوى لوحة التحكم لأن نص `about_us` الحالي على السيرفر ما زال
/// نصًا مؤقتًا («سيتم تحديث نص من نحن من لوحة تحكم الأدمن»). عند تحديث السيرفر
/// للنص المعتمد يمكن تحويل هذه الصفحة إلى `ContentPageScreen`.
class AppAboutScreen extends ConsumerWidget {
  const AppAboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(AppStrings.t(isArabic, 'app_description_title')),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppDimens.pagePadding),
          children: [
            Center(child: const AppLogo(width: 200, full: true)),
            const SizedBox(height: AppDimens.lg),
            Text(
              AppStrings.t(isArabic, 'app_tagline_full'),
              textAlign: TextAlign.center,
              style: textTheme.titleSmall?.copyWith(color: AppColors.goldDark),
            ),
            const SizedBox(height: AppDimens.lg),
            Text(
              AppStrings.t(isArabic, 'app_description_intro'),
              style: textTheme.bodyLarge?.copyWith(height: 1.9),
            ),
            const SizedBox(height: AppDimens.md),
            Text(
              AppStrings.t(isArabic, 'app_description_body'),
              style: textTheme.bodyMedium?.copyWith(height: 1.9),
            ),
            const SizedBox(height: AppDimens.lg),
            Container(
              padding: const EdgeInsets.all(AppDimens.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppDimens.radiusLg),
              ),
              child: Text(
                AppStrings.t(isArabic, 'app_description_closing'),
                style:
                    textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
