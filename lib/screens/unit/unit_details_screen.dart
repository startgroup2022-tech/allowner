import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../models/amenity_model.dart';
import '../../models/unit_model.dart';
import '../../services/api_client.dart';
import '../../services/hotel_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';
import '../../widgets/cards.dart';
import '../../widgets/state_views.dart';
import '../booking/booking_screen.dart';

/// تفاصيل الوحدة.
///
/// إصلاحات عن النسخة السابقة:
/// 1. كانت تُنهار إذا كان `images` مفقودًا أو `addons` غير قائمة
///    (`(unit['images'] as List)` و `(unit['addons'] as List)`).
/// 2. كانت تُمرّر `unit['hotel_id'].toString()` بدون التحقق، وإذا كان
///    `hotel_id` صفرًا/مفقودًا يفشل الانتقال للحجز برسالة غامضة.
/// 3. كانت تُمرّر `HotelDetail` (نتيجة الـ service الجديدة) بدل `HotelModel`.
/// 4. لا تعرض فترات الإتاحة الحقيقية القادمة من `units/detail.php`.
class UnitDetailsScreen extends ConsumerStatefulWidget {
  final int unitId;

  const UnitDetailsScreen({super.key, required this.unitId});

  @override
  ConsumerState<UnitDetailsScreen> createState() => _UnitDetailsScreenState();
}

class _UnitDetailsScreenState extends ConsumerState<UnitDetailsScreen> {
  final HotelService _hotelService = HotelService();

  /// مرافق الفندق الأب المشتركة. تُجلب منفصلة عن الوحدة لأن الـ API يربط
  /// المرافق بالفندق فقط (`units/detail.php` لا يعيد أي حقل مرافق). عند تعذّر
  /// الجلب تبقى فارغة — لا نخترع مرافق ولا نُفشل الشاشة بسببها.
  List<Map<String, dynamic>> _hotelAmenities = const [];
  final PageController _galleryController = PageController();

  late Future<UnitModel> _future;
  int _galleryIndex = 0;
  bool _bookingLoading = false;

  @override
  void initState() {
    super.initState();
    _future = _hotelService.getUnitDetail(widget.unitId);
    _future.then(_loadHotelAmenities);
  }

  @override
  void dispose() {
    _galleryController.dispose();
    super.dispose();
  }

  /// يجلب مرافق الفندق الأب بعد وصول الوحدة (نحتاج `hotelId` منها).
  /// فشل هذا الجلب لا يؤثر على عرض الوحدة نفسها.
  Future<void> _loadHotelAmenities(UnitModel unit) async {
    if (unit.hotelId <= 0) return;
    try {
      final amenities =
          await _hotelService.getHotelAmenities(unit.hotelId.toString());
      if (!mounted) return;
      setState(() => _hotelAmenities = amenities);
    } catch (_) {
      // مرافق الفندق اختيارية: تجاهل الخطأ وأبقِ القسم مخفيًا.
    }
  }

  void _reload() {
    setState(() {
      _hotelAmenities = const [];
      _future = _hotelService.getUnitDetail(widget.unitId);
    });
    _future.then(_loadHotelAmenities);
  }

  /// ينتقل إلى الحجز: يجلب الفندق الأب أولًا (لأن الحجز يحتاجه)، ويعرض خطأ
  /// واضحًا إذا تعذّر ذلك بدل الفشل الصامت.
  Future<void> _goToBooking(bool isArabic, UnitModel unit) async {
    if (_bookingLoading) return;

    if (unit.hotelId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'هذه الوحدة غير مرتبطة بفندق، تعذّر إتمام الحجز'
                : 'This unit is not linked to a hotel, booking is unavailable',
          ),
        ),
      );
      return;
    }

    setState(() => _bookingLoading = true);
    try {
      final detail =
          await _hotelService.getHotelDetail(unit.hotelId.toString());
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BookingScreen(
            hotel: detail.hotel,
            unitId: unit.id,
            unitName: unit.name(isArabic),
            unitPricePerNight: unit.pricePerNight,
            unitImageUrl: unit.coverImage.isNotEmpty
                ? unit.coverImage
                : (unit.images.isNotEmpty ? unit.images.first : null),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : e.toString())),
      );
    } finally {
      if (mounted) setState(() => _bookingLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<UnitModel>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2.4, color: AppColors.gold),
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            final error = snapshot.error;
            return SafeArea(
              child: Column(
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        isArabic
                            ? Icons.arrow_forward_rounded
                            : Icons.arrow_back_rounded,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ErrorView(
                      isArabic: isArabic,
                      message: error is ApiException
                          ? error.message
                          : AppStrings.t(isArabic, 'load_failed_title'),
                      onRetry: _reload,
                    ),
                  ),
                ],
              ),
            );
          }

          final unit = snapshot.data!;
          return _buildContent(context, unit, isArabic);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, UnitModel unit, bool isArabic) {
    final textTheme = Theme.of(context).textTheme;
    final images = unit.images;

    return Stack(
      children: [
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 290,
              pinned: true,
              elevation: 0,
              backgroundColor: AppColors.surface,
              automaticallyImplyLeading: false,
              leading: Padding(
                padding: const EdgeInsets.all(8),
                child: _CircleIconButton(
                  icon: isArabic
                      ? Icons.arrow_forward_rounded
                      : Icons.arrow_back_rounded,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
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
                        itemBuilder: (context, i) =>
                            AppNetworkImage(url: images[i], fit: BoxFit.cover),
                      ),
                    const Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 90,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                            gradient: AppColors.darkOverlayGradient),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius:
                                BorderRadius.circular(AppDimens.radiusFull),
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
            ),
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
                  140,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unit.name(isArabic),
                      style: textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 16, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            [
                              if (unit.hotelName.isNotEmpty) unit.hotelName,
                              if (unit.city(isArabic).isNotEmpty)
                                unit.city(isArabic),
                            ].join(' · '),
                            style: textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textMuted),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimens.md),
                    _buildInfoChips(context, unit, isArabic),
                    if (unit.description(isArabic).isNotEmpty) ...[
                      const SizedBox(height: AppDimens.lg),
                      Text(AppStrings.t(isArabic, 'about_unit'),
                          style: textTheme.titleMedium),
                      const SizedBox(height: AppDimens.sm),
                      Text(
                        unit.description(isArabic),
                        style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary, height: 1.7),
                      ),
                    ],
                    if (unit.addons.isNotEmpty) ...[
                      const SizedBox(height: AppDimens.lg),
                      Text(AppStrings.t(isArabic, 'unit_addons_title'),
                          style: textTheme.titleMedium),
                      const SizedBox(height: AppDimens.sm),
                      ...unit.addons.map((addon) => Container(
                            margin: const EdgeInsets.only(bottom: AppDimens.sm),
                            padding: const EdgeInsets.all(AppDimens.md),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius:
                                  BorderRadius.circular(AppDimens.radiusMd),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  addon.category == 'extra_bed'
                                      ? Icons.bed_outlined
                                      : Icons.restaurant_outlined,
                                  size: 18,
                                  color: AppColors.goldDark,
                                ),
                                const SizedBox(width: AppDimens.sm),
                                Expanded(
                                  child: Text(addon.name(isArabic),
                                      style: textTheme.bodyMedium),
                                ),
                                Text(
                                  '${addon.price.toStringAsFixed(0)} ${AppStrings.t(isArabic, 'sar')}',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: AppColors.goldDark,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                    const SizedBox(height: AppDimens.lg),
                    const Divider(),
                    const SizedBox(height: AppDimens.lg),
                    _buildAvailability(context, unit, isArabic),
                    const SizedBox(height: AppDimens.lg),
                    const Divider(),
                    const SizedBox(height: AppDimens.lg),
                    _buildFacilities(context, unit, isArabic),
                  ],
                ),
              ),
            ),
          ],
        ),
        _buildBottomBar(context, unit, isArabic),
      ],
    );
  }

  Widget _buildInfoChips(BuildContext context, UnitModel unit, bool isArabic) {
    final unitType = unit.unitType(isArabic);
    return Wrap(
      spacing: AppDimens.sm,
      runSpacing: AppDimens.sm,
      children: [
        if (unitType.isNotEmpty)
          _InfoChip(icon: Icons.label_outline_rounded, label: unitType),
        _InfoChip(
          icon: Icons.people_outline_rounded,
          label: '${unit.capacity} ${AppStrings.t(isArabic, 'guests')}',
        ),
        _InfoChip(
          icon: Icons.bed_outlined,
          label: '${unit.bedCount} ${AppStrings.t(isArabic, 'beds_label')}',
        ),
        if (unit.unitNumber != null && unit.unitNumber!.isNotEmpty)
          _InfoChip(
            icon: Icons.tag_rounded,
            label:
                '${AppStrings.t(isArabic, 'unit_number_label')} ${unit.unitNumber}',
          ),
        if (unit.pricePerWeek != null && unit.pricePerWeek! > 0)
          _InfoChip(
            icon: Icons.calendar_view_week_rounded,
            label: '${unit.pricePerWeek!.toStringAsFixed(0)} '
                '${AppStrings.t(isArabic, 'sar')} / ${AppStrings.t(isArabic, 'price_per_week_short')}',
          ),
        if (unit.pricePerMonth != null && unit.pricePerMonth! > 0)
          _InfoChip(
            icon: Icons.calendar_month_rounded,
            label: '${unit.pricePerMonth!.toStringAsFixed(0)} '
                '${AppStrings.t(isArabic, 'sar')} / ${AppStrings.t(isArabic, 'price_per_month_short')}',
          ),
      ],
    );
  }

  /// فترات الإتاحة الحقيقية من `units/detail.php` ← `availability`.
  Widget _buildAvailability(
      BuildContext context, UnitModel unit, bool isArabic) {
    final textTheme = Theme.of(context).textTheme;
    final periods = unit.availability.where((p) => p.isValid).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.t(isArabic, 'availability_period'),
            style: textTheme.titleMedium),
        const SizedBox(height: AppDimens.sm),
        if (periods.isEmpty)
          Text(
            AppStrings.t(isArabic, 'no_availability_info'),
            style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          )
        else
          ...periods.map((period) => Padding(
                padding: const EdgeInsets.only(bottom: AppDimens.sm),
                child: Row(
                  children: [
                    const Icon(Icons.event_available_rounded,
                        size: 16, color: AppColors.success),
                    const SizedBox(width: AppDimens.sm),
                    Expanded(
                      child: Text(
                        '${_formatDate(period.from!)} → ${_formatDate(period.to!)}',
                        style: textTheme.bodyMedium,
                        textDirection: TextDirection.ltr,
                      ),
                    ),
                  ],
                ),
              )),
      ],
    );
  }

  /// مرافق الوحدة ثم مرافق الفندق المشتركة، في قسمين واضحين.
  ///
  /// الـ API الحالي لا يعيد أي حقل مرافق للوحدة (`units/detail.php`)، لذلك
  /// قسم الوحدة يشرح الوضع بدل أن يبدو معطّلًا. مرافق الفندق تُعرض كمرافق
  /// مشتركة موسومة بوضوح حتى لا يظن الضيف أنها خاصة بالوحدة.
  Widget _buildFacilities(BuildContext context, UnitModel unit, bool isArabic) {
    final textTheme = Theme.of(context).textTheme;
    final unitFacilities = unit.facilities;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.t(isArabic, 'unit_facilities'),
            style: textTheme.titleMedium),
        const SizedBox(height: AppDimens.sm),
        if (unitFacilities.isEmpty)
          Text(
            AppStrings.t(isArabic, 'unit_facilities_empty_note'),
            style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          )
        else
          _amenityWrap(unitFacilities, isArabic),
        if (_hotelAmenities.isNotEmpty) ...[
          const SizedBox(height: AppDimens.lg),
          Row(
            children: [
              const Icon(Icons.apartment_rounded,
                  size: 18, color: AppColors.textSecondary),
              const SizedBox(width: AppDimens.sm),
              Expanded(
                child: Text(
                  AppStrings.t(isArabic, 'hotel_shared_facilities'),
                  style: textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            AppStrings.t(isArabic, 'hotel_shared_facilities_note'),
            style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppDimens.sm),
          _amenityWrap(_hotelAmenities, isArabic),
        ],
      ],
    );
  }

  Widget _amenityWrap(List<Map<String, dynamic>> items, bool isArabic) {
    return Wrap(
      spacing: AppDimens.md,
      runSpacing: AppDimens.md,
      children: items.map((item) {
        final amenity = AmenityModel.fromJson(item);
        return AmenityTile(
          label: amenity.name(isArabic),
          iconKey: amenity.iconKey,
          nameEn: amenity.nameEn,
          nameAr: amenity.nameAr,
        );
      }).toList(),
    );
  }

  Widget _buildBottomBar(BuildContext context, UnitModel unit, bool isArabic) {
    final textTheme = Theme.of(context).textTheme;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          AppDimens.pagePadding,
          AppDimens.md,
          AppDimens.pagePadding,
          AppDimens.md + MediaQuery.paddingOf(context).bottom,
        ),
        decoration: BoxDecoration(
            color: AppColors.surface, boxShadow: AppColors.cardShadow),
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
                    amount: unit.pricePerNight,
                    isArabic: isArabic,
                    perNight: false,
                    fontSize: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimens.md),
            SizedBox(
              height: AppDimens.buttonHeight,
              child: ElevatedButton(
                onPressed:
                    _bookingLoading ? null : () => _goToBooking(isArabic, unit),
                child: _bookingLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(AppStrings.t(isArabic, 'book_now')),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusFull),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.15), blurRadius: 8)
          ],
        ),
        child: Icon(icon, color: AppColors.ink, size: 20),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text(label,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
