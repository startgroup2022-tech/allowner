import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';
import '../../services/hotel_service.dart';
import '../../utils/safe_parse.dart';
import '../unit/unit_details_screen.dart';
import 'filters_sheet.dart';

class SearchScreen extends ConsumerStatefulWidget {
  /// نص بحث ابتدائي (مثلاً اسم مدينة أو جناح) يُطبّق فور فتح الشاشة
  final String? initialQuery;

  const SearchScreen({super.key, this.initialQuery});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final HotelService _hotelService = HotelService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _units = [];
  bool _isLoading = true;
  String? _error;
  String _sort = 'newest';
  double? _minPrice;
  double? _maxPrice;
  int? _minCapacity;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      _searchController.text = widget.initialQuery!.trim();
    }
    _loadUnits();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUnits() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final units = await _hotelService.browseUnits(
        search: _searchController.text.trim(),
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        minCapacity: _minCapacity,
        sort: _sort,
        limit: 50,
      );
      if (!mounted) return;
      setState(() {
        _units = units;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FiltersSheet(),
    );
    if (result != null) {
      setState(() {
        _minPrice = result['min_price'] as double?;
        _maxPrice = result['max_price'] as double?;
        _minCapacity = result['min_capacity'] as int?;
      });
      _loadUnits();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final textTheme = Theme.of(context).textTheme;
    final units = _units;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppDimens.pagePadding),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppDimens.md),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onSubmitted: (_) => _loadUnits(),
                        decoration: InputDecoration(
                          hintText: AppStrings.t(isArabic, 'search_destination'),
                          filled: false,
                          border: InputBorder.none,
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimens.sm),
                  InkWell(
                    onTap: _openFilters,
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                      ),
                      child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.pagePadding),
              child: Row(
                children: [
                  Text('${units.length} ${AppStrings.t(isArabic, "results_found")}',
                      style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                  const Spacer(),
                  DropdownButton<String>(
                    value: _sort,
                    underline: const SizedBox.shrink(),
                    style: textTheme.bodyMedium?.copyWith(color: AppColors.ink),
                    items: [
                      DropdownMenuItem(value: 'newest', child: Text(AppStrings.t(isArabic, 'sort_newest'))),
                      DropdownMenuItem(value: 'price_asc', child: Text(AppStrings.t(isArabic, 'sort_price_asc'))),
                      DropdownMenuItem(value: 'capacity', child: Text(AppStrings.t(isArabic, 'sort_capacity'))),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _sort = v);
                      _loadUnits();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.sm),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.gold),
                    )
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_error!, style: textTheme.bodyMedium, textAlign: TextAlign.center),
                              const SizedBox(height: 8),
                              TextButton(onPressed: _loadUnits, child: Text(isArabic ? 'إعادة المحاولة' : 'Retry')),
                            ],
                          ),
                        )
                      : units.isEmpty
                          ? Center(
                              child: Text(
                                AppStrings.t(isArabic, 'no_results'),
                                style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: AppDimens.pagePadding),
                              itemCount: units.length,
                              itemBuilder: (context, index) {
                                final unit = units[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: AppDimens.md),
                                  child: _SearchResultCard(
                                    unit: unit,
                                    isArabic: isArabic,
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => UnitDetailsScreen(unitId: unit['id'] as int),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final Map<String, dynamic> unit;
  final bool isArabic;
  final VoidCallback onTap;

  const _SearchResultCard({required this.unit, required this.isArabic, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final name = isArabic ? (unit['name_ar']?.toString() ?? '') : (unit['name_en']?.toString() ?? '');
    final hotelName = unit['hotel_name']?.toString() ?? '';
    final price = asInt(unit['price_per_night']);
    final capacity = unit['capacity'] ?? 1;
    final bedCount = unit['bed_count'] ?? 1;
    final unitType = isArabic ? unit['unit_type_ar']?.toString() : unit['unit_type_en']?.toString();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppDimens.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 100,
              height: 100,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
              child: CachedNetworkImage(
                imageUrl: unit['cover_image']?.toString() ?? '',
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                  ),
                ),
                errorWidget: (context, url, error) =>
                    Icon(Icons.image_outlined, color: AppColors.textMuted),
              ),
            ),
            const SizedBox(width: AppDimens.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (unitType != null && unitType.isNotEmpty)
                    Text(unitType, style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(hotelName,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.people_outline_rounded, size: 12, color: AppColors.secondary),
                            Text(' $capacity',
                                style: const TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.secondary)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.bed_outlined, size: 12, color: AppColors.secondary),
                            Text(' $bedCount',
                                style: const TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.secondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Align(
                    alignment: isArabic ? Alignment.centerLeft : Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$price ${AppStrings.t(isArabic, "sar")}',
                            style: textTheme.titleSmall?.copyWith(color: AppColors.goldDark)),
                        Text(AppStrings.t(isArabic, 'per_night'),
                            style: textTheme.labelSmall?.copyWith(color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
