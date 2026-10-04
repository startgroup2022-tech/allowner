import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';
import '../../services/owner_service.dart';
import 'owner_add_unit_screen.dart';

class OwnerUnitsScreen extends ConsumerStatefulWidget {
  const OwnerUnitsScreen({super.key});

  @override
  ConsumerState<OwnerUnitsScreen> createState() => _OwnerUnitsScreenState();
}

class _OwnerUnitsScreenState extends ConsumerState<OwnerUnitsScreen> {
  final _service = OwnerService();
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getUnitsFull();
  }

  void _reload() => setState(() => _future = _service.getUnitsFull());

  Future<void> _openAddUnit(bool isArabic, List<Map<String, dynamic>> hotels) async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => OwnerAddUnitScreen(hotels: hotels)),
    );
    if (added == true) {
      _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.t(isArabic, 'unit_added_success'))));
      }
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
        title: Text(AppStrings.t(isArabic, 'nav_units')),
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
                  children: [_ErrorBox(isArabic: isArabic, onRetry: _reload)],
                );
              }
              final data = snapshot.data ?? {};
              final units = (data['units'] as List?)?.cast<Map<String, dynamic>>() ?? [];
              final hotels = (data['hotels'] as List?)?.cast<Map<String, dynamic>>() ?? [];
              final canCreate = data['can_create'] == true;

              if (units.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppDimens.xl),
                      child: Column(
                        children: [
                          Text(AppStrings.t(isArabic, 'no_units'), textAlign: TextAlign.center),
                          if (canCreate) ...[
                            const SizedBox(height: AppDimens.md),
                            if (hotels.isEmpty)
                              Text(AppStrings.t(isArabic, 'no_hotel_linked'),
                                  textAlign: TextAlign.center, style: const TextStyle(color: AppColors.warning))
                            else
                              ElevatedButton.icon(
                                onPressed: () => _openAddUnit(isArabic, hotels),
                                icon: const Icon(Icons.add),
                                label: Text(AppStrings.t(isArabic, 'add_unit')),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(AppDimens.pagePadding),
                itemCount: units.length,
                separatorBuilder: (context, index) => const SizedBox(height: AppDimens.md),
                itemBuilder: (context, index) {
                  final unit = units[index];
                  final active = unit['is_active'] == 1 || unit['is_active'] == true;
                  final name = isArabic ? (unit['name_ar'] ?? '') : (unit['name_en'] ?? unit['name_ar'] ?? '');
                  final hotel = unit['hotel_name'] ?? '';
                  final price = (unit['price_per_night'] is num) ? (unit['price_per_night'] as num).toStringAsFixed(0) : '0';
                  final images = (unit['images'] as List?)?.cast<String>() ?? const <String>[];
                  final coverImage = (unit['cover_image'] as String?)?.isNotEmpty == true
                      ? unit['cover_image'] as String
                      : (images.isNotEmpty ? images.first : null);

                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (coverImage != null)
                          Image.network(coverImage, height: 130, width: double.infinity, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(height: 130, color: AppColors.surfaceMuted)),
                        Padding(
                          padding: const EdgeInsets.all(AppDimens.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(name, style: textTheme.titleSmall)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (active ? AppColors.success : AppColors.textMuted).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                                    ),
                                    child: Text(
                                      AppStrings.t(isArabic, active ? 'occupied' : 'vacant'),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: active ? AppColors.success : AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(hotel.toString(), style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                              const Divider(height: AppDimens.lg),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(AppStrings.t(isArabic, 'monthly_revenue'),
                                      style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                                  Text('$price ${AppStrings.t(isArabic, 'sar')}',
                                      style: textTheme.titleSmall?.copyWith(color: AppColors.goldDark)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
      floatingActionButton: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          final data = snapshot.data!;
          final canCreate = data['can_create'] == true;
          final hotels = (data['hotels'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          final units = (data['units'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          // الزر العائم يظهر بس لو فيه صلاحية إضافة ولو القائمة مش فاضية أصلاً (لو فاضية، الزر موجود جوا الصفحة نفسها)
          if (!canCreate || units.isEmpty) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            backgroundColor: AppColors.gold,
            onPressed: () => _openAddUnit(isArabic, hotels),
            icon: const Icon(Icons.add, color: AppColors.textOnGold),
            label: Text(AppStrings.t(isArabic, 'add_unit'), style: const TextStyle(color: AppColors.textOnGold)),
          );
        },
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final bool isArabic;
  final VoidCallback onRetry;
  const _ErrorBox({required this.isArabic, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.xl),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 32),
          const SizedBox(height: AppDimens.sm),
          Text(AppStrings.t(isArabic, 'error_loading'), textAlign: TextAlign.center),
          const SizedBox(height: AppDimens.sm),
          OutlinedButton(onPressed: onRetry, child: Text(AppStrings.t(isArabic, 'retry'))),
        ],
      ),
    );
  }
}
