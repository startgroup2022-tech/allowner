import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';

class FiltersSheet extends ConsumerStatefulWidget {
  final double? initialMinPrice;
  final double? initialMaxPrice;
  final int? initialMinCapacity;

  const FiltersSheet({
    super.key,
    this.initialMinPrice,
    this.initialMaxPrice,
    this.initialMinCapacity,
  });

  @override
  ConsumerState<FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends ConsumerState<FiltersSheet> {
  static const double _maxPriceLimit = 3000;

  late RangeValues _priceRange;
  late int _minCapacity;

  @override
  void initState() {
    super.initState();
    _priceRange = RangeValues(
      (widget.initialMinPrice ?? 0).clamp(0, _maxPriceLimit),
      (widget.initialMaxPrice ?? _maxPriceLimit).clamp(0, _maxPriceLimit),
    );
    _minCapacity = widget.initialMinCapacity ?? 0;
  }

  void _reset() {
    setState(() {
      _priceRange = const RangeValues(0, _maxPriceLimit);
      _minCapacity = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppDimens.radiusXl)),
      ),
      padding: const EdgeInsets.all(AppDimens.pagePadding),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: AppDimens.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppStrings.t(isArabic, 'filters'),
                    style: textTheme.headlineSmall),
                TextButton(
                  onPressed: _reset,
                  child: Text(AppStrings.t(isArabic, 'reset')),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.md),
            Text(AppStrings.t(isArabic, 'price_range'),
                style: textTheme.titleSmall),
            RangeSlider(
              values: _priceRange,
              min: 0,
              max: _maxPriceLimit,
              divisions: 30,
              activeColor: AppColors.gold,
              inactiveColor: AppColors.surfaceMuted,
              labels: RangeLabels(
                  '${_priceRange.start.toInt()}', '${_priceRange.end.toInt()}'),
              onChanged: (values) => setState(() => _priceRange = values),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    '${_priceRange.start.toInt()} ${AppStrings.t(isArabic, "sar")}',
                    style: textTheme.bodySmall),
                Text(
                    '${_priceRange.end.toInt()} ${AppStrings.t(isArabic, "sar")}',
                    style: textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: AppDimens.md),
            Text(AppStrings.t(isArabic, 'guests'), style: textTheme.titleSmall),
            const SizedBox(height: AppDimens.sm),
            Wrap(
              spacing: AppDimens.sm,
              children: [0, 1, 2, 3, 4, 6, 8].map((n) {
                final selected = _minCapacity == n;
                final label = n == 0 ? AppStrings.t(isArabic, 'any') : '$n+';
                return InkWell(
                  onTap: () => setState(() => _minCapacity = n),
                  borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.ink : AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color:
                            selected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppDimens.xl),
            SizedBox(
              width: double.infinity,
              height: AppDimens.buttonHeight,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop({
                  'min_price': _priceRange.start > 0 ? _priceRange.start : null,
                  'max_price':
                      _priceRange.end < _maxPriceLimit ? _priceRange.end : null,
                  'min_capacity': _minCapacity > 0 ? _minCapacity : null,
                }),
                child: Text(AppStrings.t(isArabic, 'apply_filters')),
              ),
            ),
            const SizedBox(height: AppDimens.lg),
          ],
        ),
      ),
    );
  }
}
