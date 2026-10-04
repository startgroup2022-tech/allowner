import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';
import '../../services/owner_service.dart';
import '../../services/api_client.dart';

/// طلب نظافة من المالك للفندق — بيوصل لإدارة الفندق فورًا (إشعار + إيميل)
/// وتقدر إدارة الفندق تؤكده بسعر وملاحظة، أو تتمّه، أو ترفضه.
class OwnerCleaningScreen extends ConsumerStatefulWidget {
  const OwnerCleaningScreen({super.key});

  @override
  ConsumerState<OwnerCleaningScreen> createState() => _OwnerCleaningScreenState();
}

class _OwnerCleaningScreenState extends ConsumerState<OwnerCleaningScreen> {
  final _service = OwnerService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getOwnerHotelRequests(type: 'cleaning');
  }

  void _reload() => setState(() => _future = _service.getOwnerHotelRequests(type: 'cleaning'));

  Color _statusColor(String status) {
    switch (status) {
      case 'done':
        return AppColors.success;
      case 'confirmed':
        return AppColors.secondary;
      case 'rejected':
      case 'cancelled':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }

  Future<void> _cancelRequest(bool isArabic, int id) async {
    try {
      await _service.cancelOwnerHotelRequest(id);
      _reload();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _openNewRequestSheet(bool isArabic) async {
    List<Map<String, dynamic>> units;
    try {
      units = await _service.getUnits();
    } catch (_) {
      units = const [];
    }
    if (!mounted) return;

    int? selectedUnitId = units.isNotEmpty ? units.first['id'] as int : null;
    int? selectedHotelId = units.isNotEmpty ? units.first['hotel_id'] as int : null;
    final descCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppDimens.pagePadding,
            right: AppDimens.pagePadding,
            top: AppDimens.pagePadding,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppDimens.pagePadding,
          ),
          child: StatefulBuilder(
            builder: (ctx, setSheetState) => SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.t(isArabic, 'new_cleaning_request'), style: Theme.of(ctx).textTheme.titleMedium),
                  const SizedBox(height: AppDimens.md),
                  if (units.isNotEmpty)
                    DropdownButtonFormField<int>(
                      value: selectedUnitId,
                      decoration: InputDecoration(labelText: AppStrings.t(isArabic, 'select_unit')),
                      items: units
                          .map((u) => DropdownMenuItem<int>(
                                value: u['id'] as int,
                                child: Text(isArabic ? (u['name_ar']?.toString() ?? '') : (u['name_en']?.toString() ?? '')),
                              ))
                          .toList(),
                      onChanged: (v) {
                        final unit = units.firstWhere((u) => u['id'] == v);
                        setSheetState(() {
                          selectedUnitId = v;
                          selectedHotelId = unit['hotel_id'] as int;
                        });
                      },
                    )
                  else
                    Text(AppStrings.t(isArabic, 'no_units_yet'), style: TextStyle(color: AppColors.textMuted)),
                  const SizedBox(height: AppDimens.md),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(labelText: AppStrings.t(isArabic, 'description')),
                  ),
                  const SizedBox(height: AppDimens.lg),
                  SizedBox(
                    width: double.infinity,
                    height: AppDimens.buttonHeight,
                    child: ElevatedButton(
                      onPressed: (selectedUnitId == null || selectedHotelId == null)
                          ? null
                          : () async {
                              try {
                                await _service.createOwnerHotelRequest(
                                  type: 'cleaning',
                                  hotelId: selectedHotelId!,
                                  unitId: selectedUnitId!,
                                  description: descCtrl.text.trim(),
                                );
                                if (ctx.mounted) Navigator.of(ctx).pop();
                                _reload();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(AppStrings.t(isArabic, 'request_sent'))),
                                  );
                                }
                              } on ApiException catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                                }
                              }
                            },
                      child: Text(AppStrings.t(isArabic, 'submit')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
        title: Text(AppStrings.t(isArabic, 'housekeeping')),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.gold,
        onPressed: () => _openNewRequestSheet(isArabic),
        child: const Icon(Icons.add, color: AppColors.textOnGold),
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
                      child: Center(child: Text(AppStrings.t(isArabic, 'no_cleaning_requests'))),
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
                  final price = r['price'];
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
                              child: Text(
                                '${r['hotel_name'] ?? ''}${(isArabic ? r['unit_name_ar'] : r['unit_name_en']) != null ? ' — ${isArabic ? r['unit_name_ar'] : r['unit_name_en']}' : ''}',
                                style: textTheme.titleSmall,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _statusColor(status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                              ),
                              child: Text(
                                AppStrings.t(isArabic, 'status_$status'),
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor(status)),
                              ),
                            ),
                          ],
                        ),
                        if ((r['description'] ?? '').toString().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(r['description'].toString(), style: textTheme.bodyMedium),
                        ],
                        if ((r['hotel_note'] ?? '').toString().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('${AppStrings.t(isArabic, 'hotel_note')}: ${r['hotel_note']}',
                              style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                        ],
                        if (price != null) ...[
                          const SizedBox(height: 4),
                          Text('${AppStrings.t(isArabic, 'price')}: $price ${AppStrings.t(isArabic, 'sar')}',
                              style: textTheme.bodySmall?.copyWith(color: AppColors.goldDark, fontWeight: FontWeight.w600)),
                        ],
                        if (r['can_cancel'] == true) ...[
                          const SizedBox(height: AppDimens.sm),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
                              onPressed: () => _cancelRequest(isArabic, r['id'] as int),
                              child: Text(AppStrings.t(isArabic, 'cancel_request')),
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
