import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';
import '../../services/owner_service.dart';
import '../../services/api_client.dart';
import '../../utils/safe_parse.dart';

class OwnerMarketplaceScreen extends ConsumerStatefulWidget {
  const OwnerMarketplaceScreen({super.key});

  @override
  ConsumerState<OwnerMarketplaceScreen> createState() => _OwnerMarketplaceScreenState();
}

class _OwnerMarketplaceScreenState extends ConsumerState<OwnerMarketplaceScreen> {
  final _service = OwnerService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getMarketplaceListings();
  }

  void _reload() => setState(() => _future = _service.getMarketplaceListings());

  Future<void> _openNewListingSheet(bool isArabic) async {
    List<Map<String, dynamic>> units = [];
    String? loadError;
    try {
      units = await _service.getUnits();
    } on ApiException catch (e) {
      loadError = e.message;
    } catch (e) {
      loadError = e.toString();
    }
    if (!mounted) return;

    if (loadError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loadError)));
      return;
    }
    if (units.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.t(isArabic, 'no_units_available'))));
      return;
    }

    final priceCtrl = TextEditingController(
      text: units.first['price_per_night'] != null ? asDouble(units.first['price_per_night']).toStringAsFixed(0) : '',
    );
    final descCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    int? selectedUnitId = units.first['id'] as int;
    bool submitting = false;

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
                  Text(AppStrings.t(isArabic, 'add_listing'), style: Theme.of(ctx).textTheme.titleMedium),
                  const SizedBox(height: AppDimens.sm),
                  Text(AppStrings.t(isArabic, 'nightly_rental_hint'),
                      style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                  const SizedBox(height: AppDimens.md),
                  DropdownButtonFormField<int>(
                    value: selectedUnitId,
                    decoration: InputDecoration(labelText: AppStrings.t(isArabic, 'select_unit')),
                    items: units
                        .map((u) => DropdownMenuItem<int>(
                              value: u['id'] as int,
                              child: Text('${u['hotel_name']} — ${u['name_ar']}', overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (v) {
                      setSheetState(() {
                        selectedUnitId = v;
                        // تعبئة السعر تلقائياً من بيانات الوحدة الحقيقية (نفس السعر المعروض للزبائن)
                        final unit = units.firstWhere((u) => u['id'] == v);
                        final unitPrice = unit['price_per_night'] != null ? asDouble(unit['price_per_night']).toStringAsFixed(0) : null;
                        if (unitPrice != null) priceCtrl.text = unitPrice;
                      });
                    },
                  ),
                  const SizedBox(height: AppDimens.md),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: AppStrings.t(isArabic, 'price_per_night'),
                      helperText: AppStrings.t(isArabic, 'price_prefilled_hint'),
                    ),
                  ),
                  const SizedBox(height: AppDimens.md),
                  TextField(
                    controller: contactCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(labelText: AppStrings.t(isArabic, 'contact_number')),
                  ),
                  const SizedBox(height: AppDimens.md),
                  TextField(controller: descCtrl, maxLines: 3, decoration: InputDecoration(labelText: AppStrings.t(isArabic, 'extra_note'))),
                  const SizedBox(height: AppDimens.lg),
                  SizedBox(
                    width: double.infinity,
                    height: AppDimens.buttonHeight,
                    child: ElevatedButton(
                      onPressed: submitting
                          ? null
                          : () async {
                              final price = double.tryParse(priceCtrl.text.trim());
                              if (selectedUnitId == null || price == null || price <= 0) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(content: Text(AppStrings.t(isArabic, 'fill_required_fields'))));
                                return;
                              }
                              setSheetState(() => submitting = true);
                              try {
                                await _service.createListing(
                                  unitId: selectedUnitId!,
                                  price: price,
                                  description: descCtrl.text.trim(),
                                  contactPhone: contactCtrl.text.trim(),
                                );
                                if (ctx.mounted) Navigator.of(ctx).pop();
                                _reload();
                              } on ApiException catch (e) {
                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                              } finally {
                                setSheetState(() => submitting = false);
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

  Future<void> _expressInterest(bool isArabic, int listingId) async {
    try {
      await _service.expressInterest(listingId);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.t(isArabic, 'interest_sent'))));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
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
        title: Text(AppStrings.t(isArabic, 'units_marketplace')),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              AppStrings.t(isArabic, 'units_marketplace_subtitle'),
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.gold,
        onPressed: () => _openNewListingSheet(isArabic),
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

              final listings = snapshot.data ?? [];
              if (listings.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppDimens.xl),
                      child: Center(child: Text(AppStrings.t(isArabic, 'no_listings'))),
                    ),
                  ],
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(AppDimens.pagePadding),
                itemCount: listings.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppDimens.md,
                  crossAxisSpacing: AppDimens.md,
                  childAspectRatio: 0.72,
                ),
                itemBuilder: (context, index) {
                  final l = listings[index];
                  final isMine = l['is_mine'] == true;
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
                        AspectRatio(
                          aspectRatio: 1.5,
                          child: l['image_url'] != null
                              ? Image.network(l['image_url'].toString(), fit: BoxFit.cover)
                              : Container(color: AppColors.surfaceMuted, child: const Icon(Icons.storefront_outlined, color: AppColors.textMuted)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(AppDimens.sm),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l['title'].toString(), style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              if (l['hotel_name'] != null)
                                Text(l['hotel_name'].toString(),
                                    style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                              if (l['unit_capacity'] != null)
                                Text('👤 ${l['unit_capacity']} ${AppStrings.t(isArabic, 'guests')}',
                                    style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted, fontSize: 11)),
                              if (l['price'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '${asDouble(l['price']).toStringAsFixed(0)} ${AppStrings.t(isArabic, 'sar')} / ${AppStrings.t(isArabic, 'night')}',
                                    style: textTheme.bodySmall?.copyWith(color: AppColors.success, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              const SizedBox(height: 4),
                              if (!isMine)
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 6)),
                                    onPressed: () => _expressInterest(isArabic, l['id'] as int),
                                    child: Text(AppStrings.t(isArabic, 'im_interested'), style: const TextStyle(fontSize: 11)),
                                  ),
                                )
                              else
                                Text('${l['interest_count']} ${isArabic ? "مهتم" : "interested"}',
                                    style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted, fontSize: 11)),
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
    );
  }
}
