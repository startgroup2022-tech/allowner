import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';
import '../../services/owner_service.dart';
import '../../services/api_client.dart';

class OwnerMaintenanceScreen extends ConsumerStatefulWidget {
  const OwnerMaintenanceScreen({super.key});

  @override
  ConsumerState<OwnerMaintenanceScreen> createState() => _OwnerMaintenanceScreenState();
}

class _OwnerMaintenanceScreenState extends ConsumerState<OwnerMaintenanceScreen> {
  final _service = OwnerService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getMaintenanceRequests();
  }

  void _reload() => setState(() => _future = _service.getMaintenanceRequests());

  Color _statusColor(String status) {
    switch (status) {
      case 'closed':
        return AppColors.success;
      case 'in_progress':
        return AppColors.secondary;
      default:
        return AppColors.warning;
    }
  }

  Future<void> _openNewRequestSheet(bool isArabic) async {
    List<Map<String, dynamic>> hotels;
    try {
      hotels = await _service.getHotels();
    } catch (_) {
      hotels = const [];
    }
    if (!mounted) return;

    int? selectedHotelId = hotels.isNotEmpty ? hotels.first['id'] as int : null;
    final titleCtrl = TextEditingController();
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
                  Text(AppStrings.t(isArabic, 'new_request'), style: Theme.of(ctx).textTheme.titleMedium),
                  const SizedBox(height: AppDimens.md),
                  if (hotels.isNotEmpty)
                    DropdownButtonFormField<int>(
                      value: selectedHotelId,
                      decoration: InputDecoration(labelText: AppStrings.t(isArabic, 'select_hotel')),
                      items: hotels
                          .map((h) => DropdownMenuItem<int>(value: h['id'] as int, child: Text(h['name'].toString())))
                          .toList(),
                      onChanged: (v) => setSheetState(() => selectedHotelId = v),
                    ),
                  const SizedBox(height: AppDimens.md),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(labelText: AppStrings.t(isArabic, 'request_title')),
                  ),
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
                      onPressed: (selectedHotelId == null || titleCtrl.text.trim().isEmpty)
                          ? null
                          : () async {
                              try {
                                await _service.createMaintenanceRequest(
                                  hotelId: selectedHotelId!,
                                  title: titleCtrl.text.trim(),
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
        title: Text(AppStrings.t(isArabic, 'maintenance_requests')),
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
                      child: Center(child: Text(AppStrings.t(isArabic, 'no_maintenance'))),
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
                  final status = (r['status'] ?? 'open').toString();
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
                            Expanded(child: Text(r['title'].toString(), style: textTheme.titleSmall)),
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
                        const SizedBox(height: 4),
                        Text('${r['hotel_name'] ?? ''}${r['unit_name'] != null ? ' — ${r['unit_name']}' : ''}',
                            style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                        if ((r['description'] ?? '').toString().isNotEmpty) ...[
                          const SizedBox(height: AppDimens.sm),
                          Text(r['description'].toString(), style: textTheme.bodyMedium),
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
