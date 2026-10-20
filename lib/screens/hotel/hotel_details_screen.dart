import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../models/amenity_model.dart';
import '../../models/hotel_model.dart';
import '../../models/unit_model.dart';
import '../../services/api_client.dart';
import '../../services/hotel_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';
import '../../utils/session_provider.dart';
import '../../widgets/cards.dart';
import '../../widgets/state_views.dart';
import '../booking/booking_screen.dart';
import '../unit/unit_details_screen.dart';

/// تفاصيل الفندق.
///
/// إصلاحات عن النسخة السابقة:
/// 1. الوصف كان نصًا مُصاغًا آليًا من اسم الفندق والمدينة (بيانات غير حقيقية).
///    الآن نعرض `description_ar/en` الحقيقي من الـ API، وإذا كان فارغًا نعرض
///    حالة "لا يوجد وصف".
/// 2. كانت هناك تقييمات ضيوف مكتوبة يدويًا (أسماء وتعليقات وهمية) وزر "عرض كل
///    التقييمات" لا يفعل شيئًا. أُزيلت بالكامل — لا توجد تقييمات في الـ API.
/// 3. زر "عرض على الخريطة" كان بلا وظيفة. الآن يفتح رابط خريطة حقيقي إذا كان
///    للفندق إحداثيات أو عنوان، وإلا يُخفى الزر.
/// 4. معرض الصور كان يعرض صورة واحدة مكرّرة عند فشل التحميل.
/// 5. المرافق تُبنى من `amenities` المرتبطة بالفندق فعليًا مع أيقونة من
///    `icon` القادم من قاعدة البيانات.
class HotelDetailsScreen extends ConsumerStatefulWidget {
  final HotelModel hotel;

  const HotelDetailsScreen({super.key, required this.hotel});

  @override
  ConsumerState<HotelDetailsScreen> createState() => _HotelDetailsScreenState();
}

class _HotelDetailsScreenState extends ConsumerState<HotelDetailsScreen> {
  final HotelService _hotelService = HotelService();
  final PageController _galleryController = PageController();

  late HotelModel _hotel;
  late Future<HotelDetail> _detailFuture;
  bool _showFullDescription = false;
  int _galleryIndex = 0;
  bool _favoriteBusy = false;

  @override
  void initState() {
    super.initState();
    _hotel = widget.hotel;
    _detailFuture = _hotelService.getHotelDetail(_hotel.id);
  }

  void _reload() {
    setState(() => _detailFuture = _hotelService.getHotelDetail(_hotel.id));
  }

  Future<void> _toggleFavorite() async {
    if (_favoriteBusy) return;
    final isArabic = ref.read(localeProvider).languageCode == 'ar';

    if (!ref.read(sessionProvider).isLoggedIn) {
      _showSnack(
          isArabic ? 'الرجاء تسجيل الدخول أولاً' : 'Please log in first');
      return;
    }

    setState(() => _favoriteBusy = true);
    final previous = _hotel.isFavorite;
    setState(() => _hotel = _hotel.copyWith(isFavorite: !previous));

    try {
      final favorited = await _hotelService.toggleFavorite(_hotel.id);
      if (!mounted) return;
      setState(() => _hotel = _hotel.copyWith(isFavorite: favorited));
    } catch (e) {
      if (!mounted) return;
      setState(() => _hotel = _hotel.copyWith(isFavorite: previous));
      _showSnack(e is ApiException ? e.message : e.toString());
    } finally {
      if (mounted) setState(() => _favoriteBusy = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _galleryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<HotelDetail>(
        future: _detailFuture,
        builder: (context, snapshot) {
          // نعرض ما لدينا من قائمة الفنادق فورًا، ونُثري الشاشة عند وصول التفصيل
          final detail = snapshot.data;
          final hotel = detail?.hotel ?? _hotel;
          final amenities = detail?.amenities ?? const <Map<String, dynamic>>[];
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          final error = snapshot.hasError ? snapshot.error : null;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildGallery(context, hotel, isArabic),
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(AppDimens.radiusXl),
                      topRight: Radius.circular(AppDimens.radiusXl),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    AppDimens.pagePadding,
                    AppDimens.lg,
                    AppDimens.pagePadding,
                    AppDimens.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleBlock(context, hotel, isArabic),
                      const SizedBox(height: AppDimens.lg),
                      _buildBadges(context, hotel, isArabic),
                      const SizedBox(height: AppDimens.lg),
                      const Divider(),
                      const SizedBox(height: AppDimens.lg),
                      _buildDescription(context, hotel, isArabic),
                      const SizedBox(height: AppDimens.lg),
                      const Divider(),
                      const SizedBox(height: AppDimens.lg),
                      Text(AppStrings.t(isArabic, 'available_units'),
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: AppDimens.md),
                      _buildUnits(context, hotel, isArabic, isLoading, error),
                      const SizedBox(height: AppDimens.lg),
                      const Divider(),
                      const SizedBox(height: AppDimens.lg),
                      Text(AppStrings.t(isArabic, 'amenities'),
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: AppDimens.md),
                      _buildAmenities(
                          context, amenities, isArabic, isLoading, error),
                      const SizedBox(height: AppDimens.lg),
                      const Divider(),
                      const SizedBox(height: AppDimens.lg),
                      _buildLocation(context, hotel, isArabic),
                      const SizedBox(height: AppDimens.xxl),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildBottomBar(context, isArabic),
    );
  }

  // ===== معرض الصور =====
  Widget _buildGallery(BuildContext context, HotelModel hotel, bool isArabic) {
    final images = hotel.galleryUrls.isNotEmpty
        ? hotel.galleryUrls
        : (hotel.imageUrl.isNotEmpty ? [hotel.imageUrl] : const <String>[]);

    return SliverAppBar(
      expandedHeight: 290,
      pinned: true,
      stretch: true,
      elevation: 0,
      backgroundColor: AppColors.surface,
      automaticallyImplyLeading: false,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: _CircleIconButton(
          icon:
              isArabic ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
          onTap: () => Navigator.of(context).pop(),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: _CircleIconButton(
            icon: _hotel.isFavorite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            iconColor: _hotel.isFavorite ? AppColors.danger : AppColors.ink,
            onTap: _toggleFavorite,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (images.isEmpty)
              const AppNetworkImage(url: '', fit: BoxFit.cover)
            else
              PageView.builder(
                controller: _galleryController,
                itemCount: images.length,
                onPageChanged: (i) => setState(() => _galleryIndex = i),
                itemBuilder: (context, i) => AppNetworkImage(
                  url: images[i],
                  fit: BoxFit.cover,
                ),
              ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 90,
              child: DecoratedBox(
                decoration:
                    BoxDecoration(gradient: AppColors.darkOverlayGradient),
              ),
            ),
            if (images.length > 1) ...[
              Positioned(
                bottom: 14,
                left: 0,
                right: 0,
                child: Center(
                  child: SmoothPageIndicator(
                    controller: _galleryController,
                    count: images.length,
                    effect: WormEffect(
                      dotHeight: 7,
                      dotWidth: 7,
                      spacing: 6,
                      activeDotColor: AppColors.gold,
                      dotColor: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 14,
                right: isArabic ? null : 14,
                left: isArabic ? 14 : null,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                  ),
                  child: Text(
                    '${_galleryIndex + 1}/${images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTitleBlock(
      BuildContext context, HotelModel hotel, bool isArabic) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(hotel.name, style: textTheme.headlineMedium),
        const SizedBox(height: 6),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 4,
          children: [
            if (hotel.stars > 0)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  hotel.stars.clamp(0, 5),
                  (_) => const Icon(Icons.star_rounded,
                      size: 14, color: AppColors.goldDark),
                ),
              ),
            const Icon(Icons.location_on_outlined,
                size: 14, color: AppColors.textMuted),
            Text(
              [hotel.city(isArabic), hotel.type(isArabic)]
                  .where((v) => v.isNotEmpty)
                  .join(' · '),
              style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
            // لا نعرض عدد التقييمات لأن الـ API لا يوفّر تقييمات حقيقية بعد
            // (كل القيم صفر حاليًا) — عرضها سيكون معلومات مضلّلة.
            if (hotel.rating > 0)
              AppBadge(
                text: hotel.rating.toStringAsFixed(1),
                color: AppColors.secondary,
                icon: Icons.star_rounded,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildBadges(BuildContext context, HotelModel hotel, bool isArabic) {
    return Wrap(
      spacing: AppDimens.sm,
      runSpacing: AppDimens.sm,
      children: [
        if (hotel.freeCancellation)
          AppBadge(
            text: AppStrings.t(isArabic, 'free_cancellation'),
            color: AppColors.success,
            icon: Icons.event_available_rounded,
          ),
        if (hotel.breakfastIncluded)
          AppBadge(
            text: AppStrings.t(isArabic, 'breakfast_included'),
            color: AppColors.secondary,
            icon: Icons.free_breakfast_outlined,
          ),
      ],
    );
  }

  Widget _buildDescription(
      BuildContext context, HotelModel hotel, bool isArabic) {
    final textTheme = Theme.of(context).textTheme;
    final description = hotel.description(isArabic);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.t(isArabic, 'about_property'),
            style: textTheme.titleMedium),
        const SizedBox(height: AppDimens.sm),
        if (description.isEmpty)
          Text(
            AppStrings.t(isArabic, 'no_description'),
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          )
        else ...[
          Text(
            description,
            maxLines: _showFullDescription ? null : 4,
            overflow: _showFullDescription
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
            style: textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary, height: 1.7),
          ),
          if (description.length > 140)
            GestureDetector(
              onTap: () =>
                  setState(() => _showFullDescription = !_showFullDescription),
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _showFullDescription
                      ? AppStrings.t(isArabic, 'show_less')
                      : AppStrings.t(isArabic, 'show_more'),
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.goldDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildUnits(
    BuildContext context,
    HotelModel hotel,
    bool isArabic,
    bool isLoading,
    Object? error,
  ) {
    return FutureBuilder<HotelDetail>(
      future: _detailFuture,
      builder: (context, snapshot) {
        if (isLoading) return const LoadingView(height: 120);
        if (error != null) {
          return ErrorView(
            compact: true,
            isArabic: isArabic,
            message: error is ApiException ? error.message : error.toString(),
            onRetry: _reload,
          );
        }
        // الوحدات تُجلب بشكل منفصل حتى لا يعتمد عرضها على نجاح طلب التفصيل
        return _UnitsList(
          hotelId: hotel.id,
          hotel: hotel,
          isArabic: isArabic,
          service: _hotelService,
        );
      },
    );
  }

  Widget _buildAmenities(
    BuildContext context,
    List<Map<String, dynamic>> amenities,
    bool isArabic,
    bool isLoading,
    Object? error,
  ) {
    if (isLoading) return const LoadingView(height: 90);
    if (error != null) {
      return ErrorView(
        compact: true,
        isArabic: isArabic,
        message: error is ApiException ? error.message : error.toString(),
        onRetry: _reload,
      );
    }
    if (amenities.isEmpty) {
      return Text(
        AppStrings.t(isArabic, 'no_amenities'),
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: AppColors.textMuted),
      );
    }

    final width = MediaQuery.sizeOf(context).width;
    final tileWidth = (width - (AppDimens.pagePadding * 2) - AppDimens.md) / 2;

    return Wrap(
      spacing: AppDimens.md,
      runSpacing: AppDimens.md,
      children: amenities.map((a) {
        final amenity = AmenityModel.fromJson(a);
        return SizedBox(
          width: tileWidth,
          child: AmenityTile(
            label: amenity.name(isArabic),
            iconKey: amenity.iconKey,
            nameEn: amenity.nameEn,
            nameAr: amenity.nameAr,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLocation(BuildContext context, HotelModel hotel, bool isArabic) {
    final textTheme = Theme.of(context).textTheme;
    final address = hotel.address ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.t(isArabic, 'location'), style: textTheme.titleMedium),
        const SizedBox(height: AppDimens.sm),
        Container(
          padding: const EdgeInsets.all(AppDimens.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                ),
                child:
                    const Icon(Icons.map_outlined, color: AppColors.goldDark),
              ),
              const SizedBox(width: AppDimens.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hotel.city(isArabic), style: textTheme.titleSmall),
                    if (address.isNotEmpty)
                      Text(
                        address,
                        style: textTheme.bodySmall
                            ?.copyWith(color: AppColors.textMuted),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, bool isArabic) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.pagePadding,
        vertical: AppDimens.md,
      ),
      decoration: BoxDecoration(
          color: AppColors.surface, boxShadow: AppColors.cardShadow),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppStrings.t(isArabic, 'per_night'),
                    style: textTheme.bodySmall
                        ?.copyWith(color: AppColors.textMuted),
                  ),
                  PriceText(
                    amount: _hotel.pricePerNight,
                    isArabic: isArabic,
                    perNight: false,
                    fontSize: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimens.md),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => BookingScreen(hotel: _hotel)),
                ),
                child: Text(AppStrings.t(isArabic, 'book_now')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// قائمة وحدات الفندق — widget مستقل يجلب وحداته ويحمّل حالته الخاصة.
class _UnitsList extends StatefulWidget {
  final String hotelId;
  final HotelModel hotel;
  final bool isArabic;
  final HotelService service;

  const _UnitsList({
    required this.hotelId,
    required this.hotel,
    required this.isArabic,
    required this.service,
  });

  @override
  State<_UnitsList> createState() => _UnitsListState();
}

class _UnitsListState extends State<_UnitsList> {
  late Future<List<UnitModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.getUnits(widget.hotelId);
  }

  @override
  void didUpdateWidget(covariant _UnitsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hotelId != widget.hotelId) {
      _future = widget.service.getUnits(widget.hotelId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return FutureBuilder<List<UnitModel>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingView(height: 120);
        }
        if (snapshot.hasError) {
          return ErrorView(
            compact: true,
            isArabic: widget.isArabic,
            message: snapshot.error is ApiException
                ? (snapshot.error as ApiException).message
                : snapshot.error.toString(),
            onRetry: () => setState(() {
              _future = widget.service.getUnits(widget.hotelId);
            }),
          );
        }
        final units = snapshot.data ?? const <UnitModel>[];
        if (units.isEmpty) {
          return EmptyView(
            compact: true,
            icon: Icons.king_bed_outlined,
            message: AppStrings.t(widget.isArabic, 'no_units'),
          );
        }
        return Column(
          children: units.map((unit) {
            return Container(
              margin: const EdgeInsets.only(bottom: AppDimens.sm),
              padding: const EdgeInsets.all(AppDimens.sm),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  AppNetworkImage(
                    url: unit.coverImage,
                    width: 60,
                    height: 60,
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  ),
                  const SizedBox(width: AppDimens.sm),
                  Expanded(
                    child: InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => UnitDetailsScreen(unitId: unit.id),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            unit.name(widget.isArabic),
                            style: textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          PriceText(
                            amount: unit.pricePerNight,
                            isArabic: widget.isArabic,
                            fontSize: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimens.sm),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BookingScreen(
                          hotel: widget.hotel,
                          unitId: unit.id,
                          unitName: unit.name(widget.isArabic),
                          unitPricePerNight: unit.pricePerNight,
                          unitImageUrl: unit.coverImage,
                          ownerBank: unit.ownerBank,
                          unitAvailability: unit.availability,
                        ),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    child: Text(
                      AppStrings.t(widget.isArabic, 'book_now'),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.iconColor = AppColors.ink,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, size: 20, color: iconColor),
        ),
      ),
    );
  }
}
