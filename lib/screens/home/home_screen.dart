import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';
import '../../utils/session_provider.dart';
import '../../services/hotel_service.dart';
import '../../widgets/app_logo.dart';
import '../../utils/safe_parse.dart';
import '../owner/owner_notifications_screen.dart';
import '../search/search_screen.dart';
import '../unit/unit_details_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final HotelService _hotelService = HotelService();
  List<Map<String, dynamic>> _units = [];
  List<Map<String, dynamic>> _ownerUnits = [];
  bool _isLoading = true;
  bool _isLoadingOwnerUnits = true;
  String? _error;
  String _sort = 'newest';

  static const _mainCities = ['مكة المكرمة', 'المدينة المنورة', 'الرياض', 'جدة'];

  @override
  void initState() {
    super.initState();
    _loadUnits();
    _loadOwnerUnits();
  }

  Future<void> _loadOwnerUnits() async {
    try {
      final units = await _hotelService.browseUnits(ownerOnly: true, sort: 'newest', limit: 10);
      if (!mounted) return;
      setState(() {
        _ownerUnits = units;
        _isLoadingOwnerUnits = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingOwnerUnits = false);
    }
  }

  Future<void> _loadUnits() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final units = await _hotelService.browseUnits(sort: _sort, limit: 12);
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

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final textTheme = Theme.of(context).textTheme;
    final userName = ref.watch(sessionProvider).user?.fullName.split(' ').first;
    final units = _units;

    final categories = [
      {'icon': Icons.king_bed_outlined, 'key': 'hotels', 'color': AppColors.ink},
      {'icon': Icons.apartment_rounded, 'key': 'apartments', 'color': AppColors.secondary},
      {'icon': Icons.beach_access_rounded, 'key': 'resorts', 'color': AppColors.goldDark},
      {'icon': Icons.cabin_outlined, 'key': 'chalets', 'color': AppColors.success},
      {'icon': Icons.villa_outlined, 'key': 'properties', 'color': AppColors.primary},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ===== Header =====
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppDimens.pagePadding, AppDimens.md, AppDimens.pagePadding, 0),
                child: Row(
                  children: [
                    const AppLogo(width: 72),
                    const SizedBox(width: AppDimens.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName != null
                                ? '${AppStrings.t(isArabic, 'hello')}, $userName 👋'
                                : '${AppStrings.t(isArabic, 'hello_guest')} 👋',
                            style: textTheme.titleMedium,
                          ),
                          Text(
                            AppStrings.t(isArabic, 'where_to'),
                            style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const OwnerNotificationsScreen()),
                      ),
                      icon: const Icon(Icons.notifications_outlined),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surfaceMuted,
                        shape: const CircleBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ===== Search bar =====
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppDimens.pagePadding),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                  child: Container(
                    padding: const EdgeInsets.all(AppDimens.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                      border: Border.all(color: AppColors.cardBorder),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, color: AppColors.textMuted),
                        const SizedBox(width: AppDimens.sm),
                        Expanded(
                          child: Text(
                            AppStrings.t(isArabic, 'search_destination'),
                            style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            gradient: AppColors.goldGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.tune_rounded, size: 16, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ===== المدن الرئيسية =====
            SliverToBoxAdapter(
              child: SizedBox(
                height: 36,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppDimens.pagePadding),
                  itemCount: _mainCities.length,
                  itemBuilder: (context, index) {
                    final city = _mainCities[index];
                    return Padding(
                      padding: const EdgeInsets.only(left: AppDimens.sm),
                      child: _SortChip(
                        label: city,
                        selected: false,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => SearchScreen(initialQuery: city)),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppDimens.md)),

            // ===== Categories =====
            SliverToBoxAdapter(
              child: SizedBox(
                height: 96,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppDimens.pagePadding),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    return Padding(
                      padding: const EdgeInsets.only(left: AppDimens.md),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SearchScreen(
                                initialQuery: AppStrings.t(isArabic, cat['key'] as String),
                              ),
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: (cat['color'] as Color).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                              ),
                              child: Icon(cat['icon'] as IconData, color: cat['color'] as Color),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              AppStrings.t(isArabic, cat['key'] as String),
                              style: textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppDimens.md)),

            // ===== فنادق بوحدات ملاك =====
            if (_isLoadingOwnerUnits || _ownerUnits.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimens.pagePadding),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppStrings.t(isArabic, 'hotels_with_owner_units'), style: textTheme.headlineSmall),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SearchScreen(initialQuery: '')),
                        ),
                        child: Text(AppStrings.t(isArabic, 'see_all')),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppDimens.sm)),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 260,
                  child: _isLoadingOwnerUnits
                      ? const Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.gold),
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: AppDimens.pagePadding),
                          itemCount: _ownerUnits.length,
                          itemBuilder: (context, index) {
                            final unit = _ownerUnits[index];
                            return Padding(
                              padding: const EdgeInsets.only(left: AppDimens.md),
                              child: _UnitCard(
                                unit: unit,
                                isArabic: isArabic,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => UnitDetailsScreen(unitId: unit['id'] as int)),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppDimens.md)),
            ],

            // ===== أحدث الأجنحة =====
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.pagePadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppStrings.t(isArabic, 'newest_suites'), style: textTheme.headlineSmall),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SearchScreen()),
                      ),
                      child: Text(AppStrings.t(isArabic, 'see_all')),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.pagePadding),
                child: Row(
                  children: [
                    _SortChip(
                      label: AppStrings.t(isArabic, 'sort_newest'),
                      selected: _sort == 'newest',
                      onTap: () {
                        setState(() => _sort = 'newest');
                        _loadUnits();
                      },
                    ),
                    const SizedBox(width: AppDimens.sm),
                    _SortChip(
                      label: AppStrings.t(isArabic, 'sort_price_asc'),
                      selected: _sort == 'price_asc',
                      onTap: () {
                        setState(() => _sort = 'price_asc');
                        _loadUnits();
                      },
                    ),
                    const SizedBox(width: AppDimens.sm),
                    _SortChip(
                      label: AppStrings.t(isArabic, 'sort_capacity'),
                      selected: _sort == 'capacity',
                      onTap: () {
                        setState(() => _sort = 'capacity');
                        _loadUnits();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppDimens.sm)),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 260,
                child: _isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.gold),
                        ),
                      )
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_error!, style: textTheme.bodySmall, textAlign: TextAlign.center),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: _loadUnits,
                                  child: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
                                ),
                              ],
                            ),
                          )
                        : units.isEmpty
                            ? Center(
                                child: Text(
                                  AppStrings.t(isArabic, 'no_units'),
                                  style: textTheme.bodySmall,
                                ),
                              )
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: AppDimens.pagePadding),
                                itemCount: units.length,
                                itemBuilder: (context, index) {
                                  final unit = units[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(left: AppDimens.md),
                                    child: _UnitCard(
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
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppDimens.xxl)),
          ],
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SortChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusFull),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.gold.withOpacity(0.15) : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppDimens.radiusFull),
          border: Border.all(color: selected ? AppColors.gold : Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.goldDark : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _UnitCard extends StatelessWidget {
  final Map<String, dynamic> unit;
  final bool isArabic;
  final VoidCallback onTap;

  const _UnitCard({required this.unit, required this.isArabic, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final name = isArabic ? (unit['name_ar']?.toString() ?? '') : (unit['name_en']?.toString() ?? '');
    final hotelName = unit['hotel_name']?.toString() ?? '';
    final price = asInt(unit['price_per_night']);
    final capacity = unit['capacity'] ?? 1;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimens.radiusLg)),
              child: CachedNetworkImage(
                imageUrl: unit['cover_image']?.toString() ?? '',
                height: 130,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 130,
                  color: AppColors.surfaceMuted,
                  child: const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 130,
                  color: AppColors.surfaceMuted,
                  child: Icon(Icons.image_outlined, color: AppColors.textMuted, size: 36),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimens.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
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
                  const SizedBox(height: 6),
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
                      const Spacer(),
                      Text(
                        '$price ${AppStrings.t(isArabic, "sar")}',
                        style: textTheme.titleSmall?.copyWith(color: AppColors.goldDark),
                      ),
                      Text(AppStrings.t(isArabic, 'per_night'),
                          style: textTheme.labelSmall?.copyWith(color: AppColors.textMuted)),
                    ],
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
