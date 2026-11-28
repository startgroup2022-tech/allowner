import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../utils/app_strings.dart';
import '../utils/pricing_forms.dart';

/// حقل عنوان نموذج التسعير («العنوان» / “Title”).
class PricingTitleField extends StatelessWidget {
  const PricingTitleField({
    super.key,
    required this.controller,
    required this.isArabic,
  });

  final TextEditingController controller;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: AppStrings.t(isArabic, 'pricing_title_field'),
        prefixIcon: const Icon(Icons.title_rounded, size: 20),
      ),
    );
  }
}

/// حقل تاريخ نموذج التسعير («التاريخ» / “Date”) بمنتقي تاريخ مطابق لتصميم
/// التطبيق. يعرض التاريخ المختار ويحفظه كما هو عند التعديل.
class PricingDateField extends StatelessWidget {
  const PricingDateField({
    super.key,
    required this.date,
    required this.isArabic,
    required this.onPick,
  });

  final DateTime? date;
  final bool isArabic;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final value = date == null ? null : formatPricingDate(date!);
    return InkWell(
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      onTap: onPick,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: AppStrings.t(isArabic, 'pricing_date_field'),
          prefixIcon: const Icon(Icons.event_outlined, size: 20),
          suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
          errorText: date == null
              ? AppStrings.t(isArabic, 'pricing_date_required')
              : null,
        ),
        child: Text(
          value ?? AppStrings.t(isArabic, 'pricing_date_field'),
          style: TextStyle(
            color: value == null ? AppColors.textMuted : AppColors.ink,
          ),
        ),
      ),
    );
  }
}

/// بطاقة سجل تسعير محفوظ (عنوان، تاريخ، أسطر الأسعار).
class PricingRecordCard extends StatelessWidget {
  const PricingRecordCard({
    super.key,
    required this.title,
    required this.date,
    required this.lines,
    this.onTap,
  });

  final String title;
  final String date;
  final List<(String, String)> lines;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimens.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: textTheme.titleSmall),
                ),
                Text(date,
                    style: textTheme.bodySmall
                        ?.copyWith(color: AppColors.textMuted)),
              ],
            ),
            const SizedBox(height: AppDimens.xs),
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(line.$1,
                          style: textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary)),
                    ),
                    Text(line.$2,
                        style: textTheme.bodySmall
                            ?.copyWith(color: AppColors.goldDark)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
