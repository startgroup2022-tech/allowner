import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';
import '../../services/hotel_staff_service.dart';
import '../../services/api_client.dart';

class HotelPricesScreen extends ConsumerStatefulWidget {
  const HotelPricesScreen({super.key});

  @override
  ConsumerState<HotelPricesScreen> createState() => _HotelPricesScreenState();
}

class _HotelPricesScreenState extends ConsumerState<HotelPricesScreen> {
  final _service = HotelStaffService();
  late Future<Map<String, dynamic>> _future;
  final _types = const ['cleaning', 'maintenance', 'meal', 'extra_bed'];

  @override
  void initState() {
    super.initState();
    _future = _service.getPrices();
  }

  void _reload() => setState(() => _future = _service.getPrices());

  Future<void> _deletePrice(int id) async {
    try {
      await _service.deletePrice(id);
      _reload();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _openPriceSheet(bool isArabic, List<Map<String, dynamic>> hotels, List<Map<String, dynamic>> units,
      {Map<String, dynamic>? existing}) async {
    int? hotelId = existing?['hotel_id'] as int? ?? (hotels.isNotEmpty ? hotels.first['id'] as int : null);
    int? unitId = existing?['unit_id'] as int?;
    String type = existing?['service_type']?.toString() ?? _types.first;
    final priceCtrl = TextEditingController(text: existing?['price']?.toString() ?? '');
    final titleArCtrl = TextEditingController(text: existing?['title_ar']?.toString() ?? '');
    final titleEnCtrl = TextEditingController(text: existing?['title_en']?.toString() ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
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
                Text(AppStrings.t(isArabic, existing != null ? 'edit_price' : 'add_price'), style: Theme.of(ctx).textTheme.titleMedium),
                const SizedBox(height: AppDimens.md),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: InputDecoration(labelText: AppStrings.t(isArabic, 'service_type')),
                  items: _types.map((t) => DropdownMenuItem(value: t, child: Text(AppStrings.t(isArabic, 'req_type_$t')))).toList(),
                  onChanged: (v) => setSheetState(() => type = v ?? type),
                ),
                const SizedBox(height: AppDimens.md),
                if (hotels.length > 1)
                  DropdownButtonFormField<int>(
                    value: hotelId,
                    decoration: InputDecoration(labelText: AppStrings.t(isArabic, 'select_hotel')),
                    items: hotels.map((h) => DropdownMenuItem<int>(value: h['id'] as int, child: Text(h['name']?.toString() ?? ''))).toList(),
                    onChanged: (v) => setSheetState(() => hotelId = v),
                  ),
                const SizedBox(height: AppDimens.md),
                DropdownButtonFormField<int?>(
                  value: unitId,
                  decoration: InputDecoration(labelText: AppStrings.t(isArabic, 'unit_optional')),
                  items: [
                    DropdownMenuItem<int?>(value: null, child: Text(AppStrings.t(isArabic, 'all_units'))),
                    ...units
                        .where((u) => hotelId == null || u['hotel_id'] == hotelId)
                        .map((u) => DropdownMenuItem<int?>(
                              value: u['id'] as int,
                              child: Text(isArabic ? (u['name_ar']?.toString() ?? '') : (u['name_en']?.toString() ?? '')),
                            )),
                  ],
                  onChanged: (v) => setSheetState(() => unitId = v),
                ),
                const SizedBox(height: AppDimens.md),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: AppStrings.t(isArabic, 'price')),
                ),
                const SizedBox(height: AppDimens.md),
                TextField(controller: titleArCtrl, decoration: const InputDecoration(labelText: 'الاسم (عربي، اختياري)')),
                const SizedBox(height: AppDimens.sm),
                TextField(controller: titleEnCtrl, decoration: const InputDecoration(labelText: 'Name (English, optional)')),
                const SizedBox(height: AppDimens.lg),
                SizedBox(
                  width: double.infinity,
                  height: AppDimens.buttonHeight,
                  child: ElevatedButton(
                    onPressed: () async {
                      final price = double.tryParse(priceCtrl.text.trim());
                      if (price == null || hotelId == null) return;
                      try {
                        await _service.savePrice(
                          id: existing?['id'] as int?,
                          hotelId: hotelId!,
                          unitId: unitId,
                          serviceType: type,
                          titleAr: titleArCtrl.text.trim().isNotEmpty ? titleArCtrl.text.trim() : null,
                          titleEn: titleEnCtrl.text.trim().isNotEmpty ? titleEnCtrl.text.trim() : null,
                          price: price,
                        );
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        _reload();
                      } on ApiException catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                      }
                    },
                    child: Text(AppStrings.t(isArabic, 'save_changes')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
        title: Text(AppStrings.t(isArabic, 'service_prices')),
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
                  children: [Center(child: Text(AppStrings.t(isArabic, 'error_loading')))],
                );
              }
              final data = snapshot.data ?? {};
              final prices = (data['prices'] as List?)?.cast<Map<String, dynamic>>() ?? [];
              final hotels = (data['hotels'] as List?)?.cast<Map<String, dynamic>>() ?? [];
              final units = (data['units'] as List?)?.cast<Map<String, dynamic>>() ?? [];

              return Stack(
                children: [
                  if (prices.isEmpty)
                    ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [Padding(padding: const EdgeInsets.all(AppDimens.xl), child: Center(child: Text(AppStrings.t(isArabic, 'no_prices_yet'))))],
                    )
                  else
                    ListView.separated(
                      padding: const EdgeInsets.fromLTRB(AppDimens.pagePadding, AppDimens.pagePadding, AppDimens.pagePadding, 90),
                      itemCount: prices.length,
                      separatorBuilder: (context, index) => const SizedBox(height: AppDimens.sm),
                      itemBuilder: (context, index) {
                        final p = prices[index];
                        final unitName = isArabic ? p['unit_name_ar'] : p['unit_name_en'];
                        return Container(
                          padding: const EdgeInsets.all(AppDimens.md),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(isArabic ? p['title_ar']?.toString() ?? '' : p['title_en']?.toString() ?? '', style: textTheme.titleSmall),
                                    Text(
                                      '${AppStrings.t(isArabic, 'req_type_${p['service_type']}')}${unitName != null ? ' · $unitName' : ' · ${AppStrings.t(isArabic, 'all_units')}'}',
                                      style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              Text('${p['price']} ${AppStrings.t(isArabic, 'sar')}',
                                  style: textTheme.titleSmall?.copyWith(color: AppColors.goldDark)),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () => _openPriceSheet(isArabic, hotels, units, existing: p),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.danger),
                                onPressed: () => _deletePrice(p['id'] as int),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  Positioned(
                    right: isArabic ? null : AppDimens.pagePadding,
                    left: isArabic ? AppDimens.pagePadding : null,
                    bottom: AppDimens.pagePadding,
                    child: FloatingActionButton(
                      backgroundColor: AppColors.gold,
                      onPressed: () => _openPriceSheet(isArabic, hotels, units),
                      child: const Icon(Icons.add, color: AppColors.textOnGold),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
