import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';
import 'meal_request_screen.dart';
import 'service_request_screen.dart';

class HotelServicesScreen extends ConsumerWidget {
  const HotelServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final textTheme = Theme.of(context).textTheme;

    final services = [
      (
        icon: Icons.build_outlined,
        title: AppStrings.t(isArabic, 'maintenance'),
        desc: AppStrings.t(isArabic, 'maintenance_desc'),
        builder: (BuildContext context) => ServiceRequestScreen(
          icon: Icons.build_outlined,
          title: AppStrings.t(isArabic, 'maintenance'),
          description: AppStrings.t(isArabic, 'maintenance_desc'),
          serviceType: 'maintenance',
        ),
      ),
      (
        icon: Icons.cleaning_services_outlined,
        title: AppStrings.t(isArabic, 'housekeeping'),
        desc: AppStrings.t(isArabic, 'housekeeping_desc'),
        builder: (BuildContext context) => ServiceRequestScreen(
          icon: Icons.cleaning_services_outlined,
          title: AppStrings.t(isArabic, 'housekeeping'),
          description: AppStrings.t(isArabic, 'housekeeping_desc'),
          serviceType: 'housekeeping',
        ),
      ),
      (
        icon: Icons.restaurant_outlined,
        title: AppStrings.t(isArabic, 'order_meal'),
        desc: AppStrings.t(isArabic, 'order_meal_desc'),
        builder: (BuildContext context) => const MealRequestScreen(),
      ),
      (
        icon: Icons.event_busy_outlined,
        title: AppStrings.t(isArabic, 'cancellation_request'),
        desc: AppStrings.t(isArabic, 'cancellation_request_desc'),
        builder: (BuildContext context) => ServiceRequestScreen(
          icon: Icons.event_busy_outlined,
          title: AppStrings.t(isArabic, 'cancellation_request'),
          description: AppStrings.t(isArabic, 'cancellation_request_desc'),
          serviceType: 'cancellation',
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(AppStrings.t(isArabic, 'hotel_services')),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(AppDimens.pagePadding),
          itemCount: services.length,
          separatorBuilder: (context, index) => const SizedBox(height: AppDimens.md),
          itemBuilder: (context, index) {
            final service = services[index];
            return InkWell(
              borderRadius: BorderRadius.circular(AppDimens.radiusLg),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: service.builder),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(AppDimens.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                      ),
                      child: Icon(service.icon, color: AppColors.goldDark, size: 24),
                    ),
                    const SizedBox(width: AppDimens.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(service.title, style: textTheme.titleSmall),
                          const SizedBox(height: 2),
                          Text(
                            service.desc,
                            style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isArabic ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}