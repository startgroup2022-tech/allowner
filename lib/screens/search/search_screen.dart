import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/category_model.dart';
import '../../models/hotel_model.dart';
import '../../models/unit_model.dart';
import '../../services/api_client.dart';
import '../../services/catalog_service.dart';
import '../../services/hotel_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';
import '../../utils/safe_parse.dart';
import '../../widgets/cards.dart';
import '../../widgets/state_views.dart';
import '../hotel/hotel_details_screen.dart';
import '../unit/unit_details_screen.dart';
import 'filters_sheet.dart';

/// شاشة البحث — تبويبان: الفنادق والوحدات.
///
/// إصلاحات جوهرية عن النسخة السابقة:
/// 1. كانت تبحث في الوحدات فقط، ولا يمكن الوصول للفنادق من البحث إطلاقًا.
/// 2. تمرير نص البحث إلى `units/browse.php?q=` يبحث في اسم الفندق واسم الوحدة
///    معًا (تم التحقق من الـ API)، فالبحث عن "فيرمونت" أو "مكة" يرجع نتائج حقيقية.
/// 3. البحث النصي في الفنادق يُرشّح محليًا لأن `hotels/list.php` لا يدعم `q`.
/// 4. لا نكرّر الطلب: عند تغيير الترتيب أو الفلاتر نعيد الطلب مرة واحدة فقط،
///    وعند التصفية بالتبويب لا نعيد الطلب (نستخدم نفس النتائج المخزّنة).
/// 5. تُحفظ حالة البحث (النص، التصنيف، الترتيب، الفلاتر) عند التنقّل للتفاصيل.
class SearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery;
  final int? initialCategoryId;
  final String? initialCategoryName;
  final String? initialCity;
  final int initialTab;

  const SearchScreen({
    super.key,
    this.initialQuery,
    this.initialCategoryId,
    this.initialCategoryName,
    this.initialCity,
    this.initialTab = 0,
  });

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  final HotelService _hotelService = HotelService();
  final CatalogService _catalogService = CatalogService();
  final TextEditingController _searchController = TextEditingController();
  late final TabController _tabController;

  Timer? _debounce;

  List<HotelModel> _hotels = [];
  List<UnitModel> _units = [];
  List<CategoryModel> _categories = [];

  bool _isLoading = true;
  String? _error;

  String _sort = 'newest';
  int? _categoryId;
  String? _categoryName;
  String? _city;
  double? _minPrice;
  double? _maxPrice;
  int? _minCapacity;

  /// رقم الطلب الأخير — يمنع وصول نتائج طلب قديم بعد طلب أحدث (race condition).
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
    _city = widget.initialCity;
    _categoryId = widget.initialCategoryId;
    _categoryName = widget.initialCategoryName;
    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      _searchController.text = widget.initialQuery!.trim();
    }
    _loadCategories();
    _loadResults();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _catalogService.listCategories();
      if (!mounted) return;
      setState(() => _categories = categories);
    } catch (_) {
      // التصنيفات اختيارية — لا نُفشل الشاشة إذا لم تُحمّل
    }
  }

  /// يبني كل معايير البحث الحالية ويجلب النتائج من الـ API.
  Future<void> _loadResults() async {
    final requestId = ++_requestId;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final query = _searchController.text.trim();

    try {
      // الطلبان مستقلان — نُنفّذهما بالتوازي بدل التسلسل لنصف زمن الانتظار.
      // نُسند النتائج داخل `then` لتجنّب `as List` غير الآمن.
      late final List<HotelModel> hotels;
      late final List<UnitModel> units;
      await Future.wait([
        _hotelService
            .searchHotels(
              query: query,
              city: _city,
              categoryName: _categoryName,
            )
            .then((value) => hotels = value),
        _hotelService
            .browseUnits(
              search: query,
              city: _city,
              minPrice: _minPrice,
              maxPrice: _maxPrice,
              minCapacity: _minCapacity,
              sort: _sort,
              limit: 60,
            )
            .then((value) => units = value),
      ]);

      // `units/browse.php` لا يدعم تصفية بالتصنيف (يتجاهل category/type)،
      // والتصنيف يصف نوع المنشأة لا نوع الغرفة. لذلك عند اختيار تصنيف نُقيّد
      // الوحدات بفنادق ذلك التصنيف عبر `hotel_id` — تصفية ببيانات حقيقية.
      var filteredUnits = units;
      if (_categoryName != null) {
        final allowedHotelIds =
            hotels.map((h) => asIntOrNull(h.id)).whereType<int>().toSet();
        filteredUnits =
            units.where((u) => allowedHotelIds.contains(u.hotelId)).toList();
      }

      // تجاهل نتيجة طلب قديم
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _hotels = hotels;
        _units = filteredUnits;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _error = e is ApiException ? e.message : e.toString();
        _isLoading = false;
      });
    }
  }

  void _onQueryChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), _loadResults);
  }

  void _clearQuery() {
    _searchController.clear();
    _debounce?.cancel();
    _loadResults();
  }

  void _selectCategory(CategoryModel? category) {
    setState(() {
      _categoryId = category?.id;
      _categoryName =
          category?.name(ref.read(localeProvider).languageCode == 'ar');
    });
    _loadResults();
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FiltersSheet(
        initialMinPrice: _minPrice,
        initialMaxPrice: _maxPrice,
        initialMinCapacity: _minCapacity,
      ),
    );
    if (result == null) return;
    setState(() {
      _minPrice = asDoubleOrNull(result['min_price']);
      _maxPrice = asDoubleOrNull(result['max_price']);
      _minCapacity = asIntOrNull(result['min_capacity']);
    });
    _loadResults();
  }

  void _openUnit(UnitModel unit) {
    Navigator.of(context)
        .push(MaterialPageRoute(
            builder: (_) => UnitDetailsScreen(unitId: unit.id)))
        // الحالة محفوظة في الـ State، لكن نعيد التحميل عند الرجوع لتعكس أي تغيير
        .then((_) {
      if (mounted) _loadResults();
    });
  }

  void _openHotel(HotelModel hotel) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => HotelDetailsScreen(hotel: hotel)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(AppStrings.t(isArabic, 'search_results')),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text:
                  '${AppStrings.t(isArabic, 'search_hotels_tab')} (${_hotels.length})',
            ),
            Tab(
              text:
                  '${AppStrings.t(isArabic, 'search_units_tab')} (${_units.length})',
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.pagePadding,
                AppDimens.sm,
                AppDimens.pagePadding,
                AppDimens.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onChanged: _onQueryChanged,
                      onSubmitted: (_) {
                        _debounce?.cancel();
                        _loadResults();
                      },
                      decoration: InputDecoration(
                        hintText:
                            AppStrings.t(isArabic, 'search_city_or_hotel'),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppColors.textMuted),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: AppStrings.t(isArabic, 'clear_search'),
                                icon: const Icon(Icons.close_rounded, size: 18),
                                onPressed: _clearQuery,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimens.sm),
                  Semantics(
                    button: true,
                    label: AppStrings.t(isArabic, 'filters'),
                    child: InkWell(
                      onTap: _openFilters,
                      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.ink,
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusMd),
                        ),
                        child: const Icon(Icons.tune_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildActiveFilterChips(isArabic),
            _buildCategoryRow(isArabic),
            _buildSortRow(isArabic, textTheme),
            Expanded(
              child: _isLoading
                  ? const LoadingView(height: double.infinity)
                  : _error != null
                      ? ErrorView(
                          isArabic: isArabic,
                          message: _error!,
                          onRetry: _loadResults,
                        )
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildHotelsList(isArabic),
                            _buildUnitsList(isArabic),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  /// شريط تصنيفات قابل للاختيار — يُبنى من `categories/list.php`.
  /// يظهر فقط إذا وصلت التصنيفات من السيرفر.
  Widget _buildCategoryRow(bool isArabic) {
    if (_categories.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.pagePadding),
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: AppDimens.sm),
            child: _SelectableChip(
              label: AppStrings.t(isArabic, 'all_categories'),
              selected: _categoryId == null,
              onTap: () => _selectCategory(null),
            ),
          ),
          ..._categories.map(
            (category) => Padding(
              padding: const EdgeInsetsDirectional.only(end: AppDimens.sm),
              child: _SelectableChip(
                label: category.name(isArabic),
                selected: _categoryId == category.id,
                onTap: () => _selectCategory(category),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterChips(bool isArabic) {
    final hasFilters = _city != null ||
        _categoryName != null ||
        _minPrice != null ||
        _maxPrice != null ||
        _minCapacity != null;
    if (!hasFilters) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.pagePadding),
        children: [
          if (_city != null)
            _FilterChip(
              label: _city!,
              onRemove: () {
                setState(() => _city = null);
                _loadResults();
              },
            ),
          if (_categoryName != null)
            _FilterChip(
              label: _categoryName!,
              onRemove: () => _selectCategory(null),
            ),
          if (_minCapacity != null)
            _FilterChip(
              label: '${_minCapacity!}+ ${AppStrings.t(isArabic, 'guests')}',
              onRemove: () {
                setState(() => _minCapacity = null);
                _loadResults();
              },
            ),
          if (_minPrice != null || _maxPrice != null)
            _FilterChip(
              label:
                  '${_minPrice?.toInt() ?? 0} - ${_maxPrice?.toInt() ?? '∞'} '
                  '${AppStrings.t(isArabic, 'sar')}',
              onRemove: () {
                setState(() {
                  _minPrice = null;
                  _maxPrice = null;
                });
                _loadResults();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSortRow(bool isArabic, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.pagePadding,
        vertical: AppDimens.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_units.length + _hotels.length} '
              '${AppStrings.t(isArabic, 'results_found')}',
              style:
                  textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          DropdownButton<String>(
            value: _sort,
            underline: const SizedBox.shrink(),
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            style: textTheme.bodySmall?.copyWith(color: AppColors.ink),
            items: [
              DropdownMenuItem(
                  value: 'newest',
                  child: Text(AppStrings.t(isArabic, 'sort_newest'))),
              DropdownMenuItem(
                  value: 'price_asc',
                  child: Text(AppStrings.t(isArabic, 'sort_price_asc'))),
              DropdownMenuItem(
                  value: 'capacity',
                  child: Text(AppStrings.t(isArabic, 'sort_capacity'))),
            ],
            onChanged: (value) {
              if (value == null || value == _sort) return;
              setState(() => _sort = value);
              _loadResults();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHotelsList(bool isArabic) {
    if (_hotels.isEmpty) {
      return EmptyView(
        icon: Icons.hotel_outlined,
        message: AppStrings.t(isArabic, 'no_results'),
        actionLabel: AppStrings.t(isArabic, 'clear_search'),
        onAction: _clearQuery,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.pagePadding,
        0,
        AppDimens.pagePadding,
        AppDimens.xxl,
      ),
      itemCount: _hotels.length,
      itemBuilder: (context, index) {
        final hotel = _hotels[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimens.md),
          child: HotelCard(
            hotel: hotel,
            isArabic: isArabic,
            onTap: () => _openHotel(hotel),
          ),
        );
      },
    );
  }

  Widget _buildUnitsList(bool isArabic) {
    if (_units.isEmpty) {
      return EmptyView(
        icon: Icons.search_off_rounded,
        message: AppStrings.t(isArabic, 'no_results'),
        actionLabel: AppStrings.t(isArabic, 'clear_search'),
        onAction: _clearQuery,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.pagePadding,
        0,
        AppDimens.pagePadding,
        AppDimens.xxl,
      ),
      itemCount: _units.length,
      itemBuilder: (context, index) {
        final unit = _units[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimens.md),
          child: UnitListCard(
            unit: unit,
            isArabic: isArabic,
            onTap: () => _openUnit(unit),
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _FilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: AppDimens.sm),
      child: Chip(
        label: Text(label),
        backgroundColor: AppColors.gold.withValues(alpha: 0.12),
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.goldDark,
        ),
        deleteIcon: const Icon(Icons.close_rounded, size: 15),
        onDeleted: onRemove,
        side: BorderSide.none,
      ),
    );
  }
}

/// شريحة اختيار (تصنيف) — حالة مُحدَّدة/غير مُحدَّدة.
class _SelectableChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SelectableChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusFull),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.gold.withValues(alpha: 0.15)
              : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppDimens.radiusFull),
          border:
              Border.all(color: selected ? AppColors.gold : Colors.transparent),
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
