import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';
import '../../services/owner_service.dart';
import '../../utils/safe_parse.dart';

class OwnerCommissionScreen extends ConsumerStatefulWidget {
  const OwnerCommissionScreen({super.key});

  @override
  ConsumerState<OwnerCommissionScreen> createState() => _OwnerCommissionScreenState();
}

class _OwnerCommissionScreenState extends ConsumerState<OwnerCommissionScreen> {
  final _service = OwnerService();
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getMyCommission();
  }

  void _reload() => setState(() => _future = _service.getMyCommission());

  String _statusLabel(bool isArabic, String status) {
    switch (status) {
      case 'paid':
        return isArabic ? 'مدفوعة' : 'Paid';
      case 'unpaid':
        return isArabic ? 'غير مدفوعة' : 'Unpaid';
      default:
        return isArabic ? 'قيد الاحتساب' : 'Pending';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
        return AppColors.success;
      case 'unpaid':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
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
        title: Text(AppStrings.t(isArabic, 'my_commission')),
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
              final items = (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
              final commissionType = data['commission_type']?.toString() ?? 'percentage';
              final rateLabel = commissionType == 'fixed'
                  ? '${asDouble(data['commission_fixed']).toStringAsFixed(0)} ${AppStrings.t(isArabic, "sar")} / ${isArabic ? "لكل حجز" : "per booking"}'
                  : '${asDouble(data['commission_rate']).toStringAsFixed(1)}%';

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppDimens.pagePadding),
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDimens.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.textMuted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${AppStrings.t(isArabic, "commission_setting")}: $rateLabel  ·  ${AppStrings.t(isArabic, "set_by_admin_only")}',
                            style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimens.md),
                  Row(
                    children: [
                      Expanded(child: _StatCard(label: AppStrings.t(isArabic, 'total_bookings'), value: '${data['total_bookings'] ?? 0}')),
                      const SizedBox(width: AppDimens.sm),
                      Expanded(child: _StatCard(label: AppStrings.t(isArabic, 'total_commission'), value: money(data['total_commission'], isArabic), gold: true)),
                    ],
                  ),
                  const SizedBox(height: AppDimens.sm),
                  Row(
                    children: [
                      Expanded(child: _StatCard(label: AppStrings.t(isArabic, 'paid'), value: money(data['paid'], isArabic))),
                      const SizedBox(width: AppDimens.sm),
                      Expanded(child: _StatCard(label: AppStrings.t(isArabic, 'unpaid'), value: money(data['unpaid'], isArabic))),
                    ],
                  ),
                  const SizedBox(height: AppDimens.lg),
                  Text(AppStrings.t(isArabic, 'commission_history'), style: textTheme.titleMedium),
                  const SizedBox(height: AppDimens.sm),
                  if (items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppDimens.xl),
                      child: Center(child: Text(AppStrings.t(isArabic, 'no_bookings'))),
                    )
                  else
                    ...items.map((r) => Container(
                          margin: const EdgeInsets.only(bottom: AppDimens.sm),
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
                                    child: Text('#${r['booking_ref']}', style: textTheme.titleSmall),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _statusColor(r['status'].toString()).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                                    ),
                                    child: Text(
                                      _statusLabel(isArabic, r['status'].toString()),
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor(r['status'].toString())),
                                    ),
                                  ),
                                ],
                              ),
                              Text(r['hotel_name']?.toString() ?? '', style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                              if ((r['guest_name'] ?? '').toString().isNotEmpty)
                                Text('${AppStrings.t(isArabic, 'customer_name')}: ${r['guest_name']}', style: textTheme.bodySmall),
                              if ((r['booking_status'] ?? '').toString().isNotEmpty)
                                Text('${AppStrings.t(isArabic, 'booking_status_label')}: ${AppStrings.t(isArabic, 'status_${r['booking_status']}')}', style: textTheme.bodySmall),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${isArabic ? "قيمة الحجز" : "Booking total"}: ${money(r['booking_total'], isArabic)}',
                                    style: textTheme.bodySmall,
                                  ),
                                  Text(
                                    money(r['amount'], isArabic),
                                    style: textTheme.titleSmall?.copyWith(color: AppColors.goldDark, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
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

String money(dynamic value, bool isArabic) {
  final v = asDouble(value);
  return '${v.toStringAsFixed(0)} ${isArabic ? "ر.س" : "SAR"}';
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final bool gold;
  const _StatCard({required this.label, required this.value, this.gold = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: gold ? AppColors.goldDark : AppColors.ink),
          ),
        ],
      ),
    );
  }
}
