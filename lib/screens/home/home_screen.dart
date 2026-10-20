import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/category_model.dart';
import '../../models/city_model.dart';
import '../../models/hotel_model.dart';
import '../../models/owner_hotel_summary.dart';
import '../../models/unit_model.dart';
import '../../services/api_client.dart';
import '../../services/catalog_service.dart';
import '../../services/hotel_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';
import '../../utils/session_provider.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/cards.dart';
import '../../widgets/state_views.dart';
import '../hotel/hotel_details_screen.dart';
import '../owner/owner_notifications_screen.dart';
import '../search/search_screen.dart';
import '../unit/unit_details_screen.dart';

/// الصفحة الرئيسية الجديدة.
///
/// كل قسم فيها يقرأ بياناته من الـ API:
/// - التصنيفات من `categories/list.php` (وليس قائمة ثابتة في الكود).
/// - الوجهات من `cities/list.php` (وليس 4 مدن مكتوبة يدويًا).
/// - الفنادق المميزة من `hotels/list.php?featured=1`.
/// - أحدث الوحدات من `units/browse.php?sort=newest`.
/// - وحدات الملاك من `units/browse.php?owner_only=1`.
///
/// كل قسم يحمل حالته الخاصة (تحميل / خطأ / فراغ) حتى لا يُعطّل قسمٌ واحد
/// الصفحة كاملة عند فشل أحد الطلبات.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final HotelService _hotelService = HotelService();
  final CatalogService _catalogService = CatalogService();

  late Future<List<CategoryModel>> _categoriesFuture;
  late Future<List<CityModel>> _citiesFuture;
  late Future<List<HotelModel>> _featuredHotelsFuture;
  late Future<List<UnitModel>> _recentUnitsFuture;
  late Future<List<OwnerHotelSummary>> _ownerHotelsFuture;

  /// المدينة المختارة لقسم «فنادق بوحدات ملاك» (المتطلب 23).
  /// `null` = كل المدن.
  String? _ownerCity;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  void _loadAll() {
    _categoriesFuture = _catalogService.listCategories();
    _citiesFuture = _catalogService.listCities();
    _featuredHotelsFuture = _hotelService.featuredHotels();
    _recentUnitsFuture = _hotelService.browseUnits(sort: 'newest', limit: 12);
    _ownerHotelsFuture = _loadOwnerHotels();
  }

  /// قسم «فنادق بوحدات ملاك»: نجلب وحدات المالك والفنادق معًا ثم نبني ملخّصات
  /// فندقية حقيقية (المتطلب 21–22). الطلبان بالتوازي لتقليل زمن التحميل.
  ///
  /// نستخدم `.then` بدل `as List` لتفادي أي تحويل غير آمن (المتطلب 13).
  Future<List<OwnerHotelSummary>> _loadOwnerHotels() {
    List<UnitModel> units = const [];
    List<HotelModel> hotels = const [];
    return Future.wait([
      _hotelService
          .browseUnits(
            ownerOnly: true,
            city: _ownerCity,
            sort: 'newest',
            limit: 40,
          )
          .then((value) => units = value),
      _hotelService
          .listHotels(city: _ownerCity)
          .then((value) => hotels = value),
    ]).then((_) => OwnerHotelSummary.build(units, hotels));
  }

  /// اختيار مدينة قسم وحدات الملاك (المتطلب 23) — يعيد التحميل مُفلترًا.
  void _selectOwnerCity(String? city) {
    if (_ownerCity == city) return;
    setState(() {
      _ownerCity = city;
      _ownerHotelsFuture = _loadOwnerHotels();
    });
  }

  Future<void> _refresh() async {
    setState(_loadAll);
    await Future.wait([
      _categoriesFuture.catchError((_) => const <CategoryModel>[]),
      _citiesFuture.catchError((_) => const <CityModel>[]),
      _featuredHotelsFuture.catchError((_) => const <HotelModel>[]),
      _recentUnitsFuture.catchError((_) => const <UnitModel>[]),
      _ownerHotelsFuture.catchError((_) => const <OwnerHotelSummary>[]),
    ]);
  }

  void _openSearch(
      {String? query,
      int? categoryId,
      String? categoryName,
      String? city,
      int tab = 0}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchScreen(
          initialQuery: query,
          initialCategoryId: categoryId,
          initialCategoryName: categoryName,
          initialCity: city,
          initialTab: tab,
        ),
      ),
    );
  }

  void _openUnit(UnitModel unit) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => UnitDetailsScreen(unitId: unit.id)),
    );
  }

  void _openHotel(HotelModel hotel) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => HotelDetailsScreen(hotel: hotel)),
    );
  }

  /// فتح فندق من قسم «فنادق بوحدات ملاك». عند توفر بيانات الفندق نفتح صفحة
  /// التفاصيل مباشرة؛ وإلا نفتح البحث مُقيّدًا باسم الفندق (بحث بالاسم يعمل
  /// محليًا على بيانات الـ API).
  void _openOwnerHotel(OwnerHotelSummary summary) {
    final hotel = summary.hotel;
    if (hotel != null) {
      _openHotel(hotel);
    } else {
      _openSearch(query: summary.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final textTheme = Theme.of(context).textTheme;
    final userName = ref.watch(sessionProvider).user?.fullName.split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.gold,
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _Header(
                  isArabic: isArabic,
                  userName: userName,
                  onNotifications: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const OwnerNotificationsScreen()),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimens.pagePadding,
                    AppDimens.md,
                    AppDimens.pagePadding,
                    0,
                  ),
                  child: _SearchEntry(
                    isArabic: isArabic,
                    onTap: () => _openSearch(),
                  ),
                ),
              ),
              // ترتيب الأقسام المعتمد من المالك (يحسم المتطلب 27):
              // البحث → الوجهات → الأنواع → فنادق بوحدات ملاك → أحدث الوحدات.
              // الفنادق المميزة لم تُطلب كقسم مستقل في المستند الأصلي، فتُعرض
              // فقط كبديل داخل قسم «فنادق بوحدات ملاك» عند عدم وجود وحدات ملاك.
              ..._buildDestinations(isArabic, textTheme),
              ..._buildCategories(isArabic, textTheme),
              ..._buildOwnerUnits(isArabic, textTheme),
              ..._buildRecentUnits(isArabic, textTheme),
              const SliverToBoxAdapter(child: SizedBox(height: AppDimens.xxl)),
            ],
          ),
        ),
      ),
    );
  }

  // ===== التصنيفات (من قاعدة البيانات) =====
  List<Widget> _buildCategories(bool isArabic, TextTheme textTheme) {
    return [
      SliverToBoxAdapter(
        child: _SectionHeader(
          title: AppStrings.t(isArabic, 'browse_by_category'),
          isArabic: isArabic,
        ),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 104,
          child: FutureBuilder<List<CategoryModel>>(
            future: _categoriesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingView(height: 104);
              }
              final categories = snapshot.data ?? const <CategoryModel>[];
              if (categories.isEmpty) {
                return EmptyView(
                  compact: true,
                  icon: Icons.category_outlined,
                  message: AppStrings.t(isArabic, 'no_results'),
                  actionLabel: AppStrings.t(isArabic, 'retry'),
                  onAction: () => setState(() {
                    _categoriesFuture = _catalogService.listCategories();
                  }),
                );
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.pagePadding),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      left: isArabic ? 0 : AppDimens.md,
                      right: isArabic ? AppDimens.md : 0,
                    ),
                    child: CategoryCard(
                      category: category,
                      isArabic: isArabic,
                      onTap: () => _openSearch(
                        categoryId: category.id,
                        categoryName: category.name(isArabic),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: AppDimens.md)),
    ];
  }

  // ===== الوجهات (من cities/list.php) =====
  List<Widget> _buildDestinations(bool isArabic, TextTheme textTheme) {
    return [
      SliverToBoxAdapter(
        child: _SectionHeader(
          title: AppStrings.t(isArabic, 'featured_destinations'),
          isArabic: isArabic,
        ),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 172,
          child: FutureBuilder<List<CityModel>>(
            future: _citiesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingView(height: 172);
              }
              if (snapshot.hasError) {
                return ErrorView(
                  compact: true,
                  isArabic: isArabic,
                  message: _errorMessage(snapshot.error),
                  onRetry: () => setState(() {
                    _citiesFuture = _catalogService.listCities();
                  }),
                );
              }
              final cities = snapshot.data ?? const <CityModel>[];
              if (cities.isEmpty) {
                return EmptyView(
                  compact: true,
                  icon: Icons.location_city_outlined,
                  message: AppStrings.t(isArabic, 'no_results'),
                );
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.pagePadding),
                itemCount: cities.length,
                itemBuilder: (context, index) {
                  final city = cities[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      left: isArabic ? 0 : AppDimens.md,
                      right: isArabic ? AppDimens.md : 0,
                    ),
                    child: DestinationCard(
                      city: city,
                      isArabic: isArabic,
                      onTap: () => _openSearch(
                        // نُمرّر الاسم المُعرَّب/الإنجليزي حسب اللغة الحالية حتى
                        // يظهر في شريحة الفلتر بنفس لغة الواجهة (الـ API يقبل
                        // الاسمين بنفس النتيجة).
                        city: city.name(isArabic),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: AppDimens.md)),
    ];
  }

  // ===== فنادق بوحدات ملاك (من وحدات المالك + بيانات الفنادق) =====
  List<Widget> _buildOwnerUnits(bool isArabic, TextTheme textTheme) {
    return [
      SliverToBoxAdapter(
        child: FutureBuilder<List<OwnerHotelSummary>>(
          future: _ownerHotelsFuture,
          builder: (context, snapshot) {
            // عند غياب وحدات الملاك نعرض الفنادق المميزة، ويطابق العنوان المحتوى.
            final useFeatured =
                snapshot.connectionState == ConnectionState.done &&
                    !snapshot.hasError &&
                    (snapshot.data ?? const <OwnerHotelSummary>[]).isEmpty;
            return _SectionHeader(
              title: AppStrings.t(isArabic,
                  useFeatured ? 'featured_hotels' : 'hotels_with_owner_units'),
              isArabic: isArabic,
              onSeeAll: () => _openSearch(tab: 0),
            );
          },
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: AppDimens.sm)),
      // اختيار المدينة لوحدات الملاك (المتطلب 23): «يظهر له وحدات الملاك في
      // المدينة المختارة». المدن من `cities/list.php` — لا قائمة ثابتة.
      SliverToBoxAdapter(
        child: SizedBox(
          height: 40,
          child: FutureBuilder<List<CityModel>>(
            future: _citiesFuture,
            builder: (context, snapshot) {
              final cities = snapshot.data ?? const <CityModel>[];
              if (cities.isEmpty) return const SizedBox.shrink();
              return ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.pagePadding),
                children: [
                  _OwnerCityChip(
                    label: AppStrings.t(isArabic, 'all_cities'),
                    selected: _ownerCity == null,
                    onTap: () => _selectOwnerCity(null),
                  ),
                  for (final city in cities)
                    _OwnerCityChip(
                      label: city.name(isArabic),
                      selected: _ownerCity == city.name(isArabic),
                      onTap: () => _selectOwnerCity(city.name(isArabic)),
                    ),
                ],
              );
            },
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: AppDimens.sm)),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 238,
          child: FutureBuilder<List<OwnerHotelSummary>>(
            future: _ownerHotelsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingView(height: 238);
              }
              if (snapshot.hasError) {
                return ErrorView(
                  compact: true,
                  isArabic: isArabic,
                  message: _errorMessage(snapshot.error),
                  onRetry: () => setState(() {
                    _ownerHotelsFuture = _loadOwnerHotels();
                  }),
                );
              }
              final summaries = snapshot.data ?? const <OwnerHotelSummary>[];
              // لا توجد وحدات ملاك: نعرض الفنادق المميزة بدلًا من فراغ كامل.
              if (summaries.isEmpty) {
                return FutureBuilder<List<HotelModel>>(
                  future: _featuredHotelsFuture,
                  builder: (context, featuredSnapshot) {
                    final hotels =
                        featuredSnapshot.data ?? const <HotelModel>[];
                    if (featuredSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const LoadingView(height: 238);
                    }
                    if (hotels.isEmpty) {
                      return EmptyView(
                        compact: true,
                        icon: Icons.villa_outlined,
                        message: AppStrings.t(isArabic, 'no_units'),
                      );
                    }
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.pagePadding),
                      itemCount: hotels.length,
                      itemBuilder: (context, index) {
                        final hotel = hotels[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            left: isArabic ? 0 : AppDimens.md,
                            right: isArabic ? AppDimens.md : 0,
                          ),
                          child: HotelCard(
                            hotel: hotel,
                            isArabic: isArabic,
                            onTap: () => _openHotel(hotel),
                          ),
                        );
                      },
                    );
                  },
                );
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.pagePadding),
                itemCount: summaries.length,
                itemBuilder: (context, index) {
                  final summary = summaries[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      left: isArabic ? 0 : AppDimens.md,
                      right: isArabic ? AppDimens.md : 0,
                    ),
                    child: OwnerHotelCard(
                      summary: summary,
                      isArabic: isArabic,
                      onTap: () => _openOwnerHotel(summary),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: AppDimens.md)),
    ];
  }

  // ===== أحدث الوحدات =====
  List<Widget> _buildRecentUnits(bool isArabic, TextTheme textTheme) {
    return [
      SliverToBoxAdapter(
        child: _SectionHeader(
          title: AppStrings.t(isArabic, 'recently_added_units'),
          isArabic: isArabic,
          onSeeAll: () => _openSearch(tab: 1),
        ),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 250,
          child: FutureBuilder<List<UnitModel>>(
            future: _recentUnitsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingView(height: 250);
              }
              if (snapshot.hasError) {
                return ErrorView(
                  compact: true,
                  isArabic: isArabic,
                  message: _errorMessage(snapshot.error),
                  onRetry: () => setState(() {
                    _recentUnitsFuture =
                        _hotelService.browseUnits(sort: 'newest', limit: 12);
                  }),
                );
              }
              final units = snapshot.data ?? const <UnitModel>[];
              if (units.isEmpty) {
                return EmptyView(
                  compact: true,
                  icon: Icons.king_bed_outlined,
                  message: AppStrings.t(isArabic, 'no_units'),
                );
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.pagePadding),
                itemCount: units.length,
                itemBuilder: (context, index) {
                  final unit = units[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      left: isArabic ? 0 : AppDimens.md,
                      right: isArabic ? AppDimens.md : 0,
                    ),
                    child: UnitCard(
                      unit: unit,
                      isArabic: isArabic,
                      onTap: () => _openUnit(unit),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    ];
  }

  /// رسائل الخطأ تأتي من [ApiException] وتُترجم إلى نص مناسب للعرض.
  String _errorMessage(Object? error) {
    if (error is ApiException) return error.message;
    return AppStrings.t(
        ref.read(localeProvider).languageCode == 'ar', 'load_failed_title');
  }
}

class _Header extends StatelessWidget {
  final bool isArabic;
  final String? userName;
  final VoidCallback onNotifications;

  const _Header({
    required this.isArabic,
    required this.userName,
    required this.onNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.pagePadding,
        AppDimens.md,
        AppDimens.pagePadding,
        0,
      ),
      child: Row(
        children: [
          const AppLogo(width: 68),
          const SizedBox(width: AppDimens.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName != null
                      ? '${AppStrings.t(isArabic, 'hello')}, $userName'
                      : AppStrings.t(isArabic, 'hello_guest'),
                  style: textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  AppStrings.t(isArabic, 'where_to'),
                  style: textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: AppStrings.t(isArabic, 'notifications'),
            child: IconButton(
              onPressed: onNotifications,
              icon: const Icon(Icons.notifications_outlined),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surfaceMuted,
                shape: const CircleBorder(),
                minimumSize: const Size(44, 44),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchEntry extends StatelessWidget {
  final bool isArabic;
  final VoidCallback onTap;

  const _SearchEntry({required this.isArabic, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: AppStrings.t(isArabic, 'search_city_or_hotel'),
      child: InkWell(
        onTap: onTap,
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
                  AppStrings.t(isArabic, 'search_city_or_hotel'),
                  style: textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  gradient: AppColors.goldGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.tune_rounded,
                    size: 16, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isArabic;
  final VoidCallback? onSeeAll;

  const _SectionHeader(
      {required this.title, required this.isArabic, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.pagePadding,
        AppDimens.sm,
        AppDimens.pagePadding,
        AppDimens.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: Text(AppStrings.t(isArabic, 'see_all')),
            ),
        ],
      ),
    );
  }
}

/// شريحة اختيار مدينة لقسم «فنادق بوحدات ملاك» (المتطلب 23).
class _OwnerCityChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OwnerCityChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: AppDimens.sm),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
