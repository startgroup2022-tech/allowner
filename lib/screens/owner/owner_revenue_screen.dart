import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';
import '../../services/owner_service.dart';
import '../../utils/safe_parse.dart';

class OwnerRevenueScreen extends ConsumerStatefulWidget {
  const OwnerRevenueScreen({super.key});

  @override
  ConsumerState<OwnerRevenueScreen> createState() => _OwnerRevenueScreenState();
}

class _OwnerRevenueScreenState extends ConsumerState<OwnerRevenueScreen> {
  final _service = OwnerService();
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getRevenue();
  }

  void _reload() => setState(() => _future = _service.getRevenue());

  String _monthLabel(String ym, bool isArabic) {
    final parts = ym.split('-');
    if (parts.length != 2) return ym;
    final monthsAr = ['', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    final monthsEn = ['', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final m = int.tryParse(parts[1]) ?? 1;
    return isArabic ? monthsAr[m] : monthsEn[m];
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(AppStrings.t(isArabic, 'nav_revenue')),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _reload(),
          child: FutureBuilder<Map<String, dynamic>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppDimens.xl),
                  children: [
                    Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 32),
                    const SizedBox(height: AppDimens.sm),
                    Text(AppStrings.t(isArabic, 'error_loading'), textAlign: TextAlign.center),
                    const SizedBox(height: AppDimens.sm),
                    Center(child: OutlinedButton(onPressed: _reload, child: Text(AppStrings.t(isArabic, 'retry')))),
                  ],
                );
              }

              final data = snapshot.data ?? {};
              final totalRevenue = (data['total_revenue'] is num) ? (data['total_revenue'] as num).toStringAsFixed(0) : '0';
              final monthly = (data['monthly'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
              final byUnit = (data['by_unit'] as List?)?.cast<Map<String, dynamic>>() ?? const [];

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppDimens.pagePadding),
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDimens.lg),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppStrings.t(isArabic, 'total_revenue_month'),
                            style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        Text('$totalRevenue ${AppStrings.t(isArabic, 'sar')}',
                            style: textTheme.headlineMedium?.copyWith(color: AppColors.goldDark)),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimens.xl),

                  Text(AppStrings.t(isArabic, 'revenue_history'), style: textTheme.titleMedium),
                  const SizedBox(height: AppDimens.md),
                  if (monthly.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppDimens.md),
                      child: Text(AppStrings.t(isArabic, 'no_data'), style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                    )
                  else
                    ...monthly.map((m) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_monthLabel(m['ym'].toString(), isArabic), style: textTheme.bodyMedium),
                              Text('${asDouble(m['total']).toStringAsFixed(0)} ${AppStrings.t(isArabic, 'sar')}',
                                  style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        )),

                  const SizedBox(height: AppDimens.xl),
                  Text(AppStrings.t(isArabic, 'by_unit'), style: textTheme.titleMedium),
                  const SizedBox(height: AppDimens.md),
                  if (byUnit.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppDimens.md),
                      child: Text(AppStrings.t(isArabic, 'no_data'), style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                    )
                  else
                    ...byUnit.map((u) => Container(
                          margin: const EdgeInsets.only(bottom: AppDimens.sm),
                          padding: const EdgeInsets.all(AppDimens.md),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  isArabic ? (u['name_ar'] ?? '') : (u['name_en'] ?? u['name_ar'] ?? ''),
                                  style: textTheme.bodyMedium,
                                ),
                              ),
                              Text('${asDouble(u['revenue']).toStringAsFixed(0)} ${AppStrings.t(isArabic, 'sar')}',
                                  style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColors.goldDark)),
                            ],
                          ),
                        )),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
