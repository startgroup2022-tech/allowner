import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';
import '../../services/owner_service.dart';
import '../../services/api_client.dart';

class OwnerMealRequestsScreen extends ConsumerStatefulWidget {
  const OwnerMealRequestsScreen({super.key});

  @override
  ConsumerState<OwnerMealRequestsScreen> createState() => _OwnerMealRequestsScreenState();
}

class _OwnerMealRequestsScreenState extends ConsumerState<OwnerMealRequestsScreen> {
  final _service = OwnerService();
  late Future<List<Map<String, dynamic>>> _future;
  int? _updatingId;

  static const _statusFlow = ['pending', 'preparing', 'delivered'];

  @override
  void initState() {
    super.initState();
    _future = _service.getMealRequests();
  }

  void _reload() => setState(() => _future = _service.getMealRequests());

  Color _statusColor(String status) {
    switch (status) {
      case 'delivered':
        return AppColors.success;
      case 'preparing':
        return AppColors.secondary;
      case 'cancelled':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }

  String _mealIcon(String type) {
    switch (type) {
      case 'breakfast':
        return '🍳';
      case 'lunch':
        return '🍲';
      default:
        return '🍽️';
    }
  }

  Future<void> _advanceStatus(bool isArabic, int id, String currentStatus) async {
    final idx = _statusFlow.indexOf(currentStatus);
    if (idx == -1 || idx >= _statusFlow.length - 1) return;
    final nextStatus = _statusFlow[idx + 1];

    setState(() => _updatingId = id);
    try {
      await _service.updateMealRequestStatus(requestId: id, status: nextStatus);
      _reload();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _updatingId = null);
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
        title: Text(AppStrings.t(isArabic, 'meal_requests')),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _reload(),
          child: FutureBuilder<List<Map<String, dynamic>>>(
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

              final requests = snapshot.data ?? [];
              if (requests.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppDimens.xl),
                      child: Center(child: Text(AppStrings.t(isArabic, 'no_meal_requests'))),
                    ),
                  ],
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(AppDimens.pagePadding),
                itemCount: requests.length,
                separatorBuilder: (context, index) => const SizedBox(height: AppDimens.md),
                itemBuilder: (context, index) {
                  final r = requests[index];
                  final status = (r['status'] ?? 'pending').toString();
                  final mealType = (r['meal_type'] ?? '').toString();
                  final canAdvance = _statusFlow.contains(status) && status != 'delivered';

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
                        Row(
                          children: [
                            Expanded(
                              child: Text('${_mealIcon(mealType)} ${AppStrings.t(isArabic, 'meal_$mealType')}',
                                  style: textTheme.titleSmall),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _statusColor(status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                              ),
                              child: Text(
                                AppStrings.t(isArabic, 'meal_status_$status'),
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor(status)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${r['hotel_name'] ?? ''} — ${AppStrings.t(isArabic, 'room')} ${r['room_number'] ?? ''}',
                          style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                        ),
                        if (r['guest_name'] != null)
                          Text(r['guest_name'].toString(), style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                        if ((r['notes'] ?? '').toString().isNotEmpty) ...[
                          const SizedBox(height: AppDimens.sm),
                          Text(r['notes'].toString(), style: textTheme.bodyMedium),
                        ],
                        if (canAdvance) ...[
                          const SizedBox(height: AppDimens.sm),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton(
                              onPressed: _updatingId == r['id'] ? null : () => _advanceStatus(isArabic, r['id'] as int, status),
                              child: Text(AppStrings.t(
                                  isArabic, status == 'pending' ? 'mark_preparing' : 'mark_delivered')),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
