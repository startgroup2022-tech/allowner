import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';
import '../../utils/session_provider.dart';
import '../../widgets/editable_avatar.dart';
import '../shared/help_support_screen.dart';
import '../shared/content_page_screen.dart';
import '../owner/owner_notifications_screen.dart';
import '../auth/login_screen.dart';
import '../home/main_navigation_screen.dart';
import '../services/hotel_services_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final textTheme = Theme.of(context).textTheme;
    final session = ref.watch(sessionProvider);
    final user = session.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.pagePadding),
          child: Column(
            children: [
              const SizedBox(height: AppDimens.md),
              user != null
                  ? EditableAvatar(avatarUrl: user.avatarUrl, radius: 44)
                  : CircleAvatar(
                      radius: 44,
                      backgroundColor: AppColors.surfaceMuted,
                      child: const Icon(Icons.person_rounded, color: AppColors.textMuted, size: 46),
                    ),
              const SizedBox(height: AppDimens.md),
              if (user != null) ...[
                Text(user.fullName, style: textTheme.headlineSmall),
                Text(user.phone?.isNotEmpty == true ? user.phone! : user.email,
                    style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    textDirection: TextDirection.ltr),
              ] else ...[
                Text(isArabic ? 'غير مسجّل الدخول' : 'Not logged in', style: textTheme.headlineSmall),
                const SizedBox(height: AppDimens.sm),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  child: Text(AppStrings.t(isArabic, 'login')),
                ),
              ],
              const SizedBox(height: AppDimens.xl),

              _MenuSection(items: [
                _MenuItem(
                  icon: Icons.room_service_outlined,
                  label: AppStrings.t(isArabic, 'available_services'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HotelServicesScreen()),
                  ),
                ),
                _MenuItem(
                  icon: Icons.notifications_outlined,
                  label: AppStrings.t(isArabic, 'notifications'),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OwnerNotificationsScreen())),
                ),
                _MenuItem(
                  icon: Icons.language_rounded,
                  label: AppStrings.t(isArabic, 'language'),
                  trailing: Text(isArabic ? 'العربية' : 'English',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  onTap: () => ref.read(localeProvider.notifier).toggleLocale(),
                ),
              ]),
              const SizedBox(height: AppDimens.md),

              _MenuSection(items: [
                _MenuItem(
                  icon: Icons.help_outline_rounded,
                  label: AppStrings.t(isArabic, 'help_support'),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpSupportScreen())),
                ),
                _MenuItem(
                  icon: Icons.info_outline_rounded,
                  label: AppStrings.t(isArabic, 'about_us'),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ContentPageScreen(contentKey: 'about_us', titleKey: 'about_us'),
                  )),
                ),
              ]),
              const SizedBox(height: AppDimens.md),

              if (user != null)
                _MenuSection(items: [
                  _MenuItem(
                    icon: Icons.logout_rounded,
                    label: AppStrings.t(isArabic, 'logout'),
                    iconColor: AppColors.danger,
                    textColor: AppColors.danger,
                    onTap: () async {
                      await ref.read(sessionProvider.notifier).logout();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                          (route) => false,
                        );
                      }
                    },
                  ),
                ]),
              const SizedBox(height: AppDimens.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final Color? iconColor;
  final Color? textColor;
  final VoidCallback onTap;

  _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.iconColor,
    this.textColor,
  });
}

class _MenuSection extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          return Column(
            children: [
              InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimens.md, vertical: 14),
                  child: Row(
                    children: [
                      Icon(item.icon, size: 22, color: item.iconColor ?? AppColors.textSecondary),
                      const SizedBox(width: AppDimens.md),
                      Expanded(
                        child: Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: item.textColor ?? AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (item.trailing != null) item.trailing!,
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
              if (index != items.length - 1)
                const Divider(height: 1, indent: AppDimens.md, endIndent: AppDimens.md),
            ],
          );
        }),
      ),
    );
  }
}