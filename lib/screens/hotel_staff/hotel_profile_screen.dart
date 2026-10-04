import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';
import '../../utils/session_provider.dart';
import '../../widgets/editable_avatar.dart';
import '../shared/help_support_screen.dart';
import '../home/main_navigation_screen.dart';

class HotelProfileScreen extends ConsumerWidget {
  const HotelProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final user = ref.watch(sessionProvider).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(AppStrings.t(isArabic, 'nav_profile')),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppDimens.pagePadding),
          children: [
            EditableAvatar(avatarUrl: user?.avatarUrl, radius: 34),
            const SizedBox(height: AppDimens.md),
            Text(user?.fullName ?? '', style: Theme.of(context).textTheme.titleLarge),
            Text(user?.email ?? '', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: AppDimens.xl),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpSupportScreen())),
              icon: const Icon(Icons.help_outline_rounded),
              label: Text(AppStrings.t(isArabic, 'help_support')),
            ),
            const SizedBox(height: AppDimens.md),
            OutlinedButton.icon(
              onPressed: () {
                ref.read(localeProvider.notifier).toggleLocale();
              },
              icon: const Icon(Icons.language_rounded),
              label: Text(isArabic ? 'English' : 'العربية'),
            ),
            const SizedBox(height: AppDimens.md),
            SizedBox(
              width: double.infinity,
              height: AppDimens.buttonHeight,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
                icon: const Icon(Icons.logout_rounded),
                label: Text(AppStrings.t(isArabic, 'logout')),
                onPressed: () async {
                  await ref.read(sessionProvider.notifier).logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
