import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_client.dart';
import '../../services/owner_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';
import '../../utils/safe_parse.dart';
import '../../widgets/state_views.dart';

/// المتطلب 68: عرض أسعار خدمات الفندق للمالك (قراءة فقط).
///
/// كان المالك لا يرى الأسعار التي يضبطها الفندق للنظافة والصيانة والوجبات
/// والسرير الإضافي. هذه الشاشة تعرض نفس بيانات `/hotel/prices.php` دون أي
/// إمكانية تعديل، لأن التسعير صلاحية إدارة الفندق.
class OwnerServicePricesScreen extends ConsumerStatefulWidget {
  const OwnerServicePricesScreen({super.key});

  @override
  ConsumerState<OwnerServicePricesScreen> createState() =>
      _OwnerServicePricesScreenState();
}

class _OwnerServicePricesScreenState
    extends ConsumerState<OwnerServicePricesScreen> {
  final _service = OwnerService();
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getOwnerServicePrices();
  }

  void _reload() => setState(() => _future = _service.getOwnerServicePrices());

  /// اسم الوحدة المرتبطة بالسعر — يُعرض «كل الوحدات» عندما يكون السعر عامًا.
  String _unitLabel(bool isArabic, Map<String, dynamic> price,
      List<Map<String, dynamic>> units) {
    final unitId = price['unit_id'];
    if (unitId == null) return AppStrings.t(isArabic, 'all_units');
    final unit = units.firstWhere(
      (u) => u['id'] == unitId,
      orElse: () => const {},
    );
    final name = isArabic ? unit['name_ar'] : unit['name_en'];
    return (name ?? unit['name'] ?? unitId).toString();
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
        title: Text(AppStrings.t(isArabic, 'service_prices')),
      ),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingView();
            }
            if (snapshot.hasError) {
              return ErrorView(
                isArabic: isArabic,
                message: snapshot.error is ApiException
                    ? (snapshot.error as ApiException).message
                    : AppStrings.t(isArabic, 'error_loading'),
                onRetry: _reload,
              );
            }

            final prices = asMapList(snapshot.data?['prices']);
            final units = asMapList(snapshot.data?['units']);
            if (prices.isEmpty) {
              return EmptyView(
                message: AppStrings.t(isArabic, 'no_service_prices'),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView.builder(
                padding: const EdgeInsets.all(AppDimens.pagePadding),
                itemCount: prices.length,
                itemBuilder: (context, index) {
                  final p = prices[index];
                  final type = p['service_type']?.toString() ?? '';
                  final title = (isArabic ? p['title_ar'] : p['title_en'])
                          ?.toString()
                          .trim() ??
                      '';
                  final price = asDouble(p['price']);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppDimens.md),
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
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.gold.withOpacity(0.12),
                              borderRadius:
                                  BorderRadius.circular(AppDimens.radiusMd),
                            ),
                            child: const Icon(Icons.sell_outlined,
                                size: 20, color: AppColors.goldDark),
                          ),
                          const SizedBox(width: AppDimens.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.t(isArabic, 'req_type_$type'),
                                  style: textTheme.titleSmall,
                                ),
                                if (title.isNotEmpty)
                                  Text(title,
                                      style: textTheme.bodySmall?.copyWith(
                                          color: AppColors.textSecondary)),
                                Text(
                                  _unitLabel(isArabic, p, units),
                                  style: textTheme.labelSmall
                                      ?.copyWith(color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${price.toStringAsFixed(0)} ${AppStrings.t(isArabic, 'sar')}',
                            style: textTheme.titleSmall
                                ?.copyWith(color: AppColors.goldDark),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
