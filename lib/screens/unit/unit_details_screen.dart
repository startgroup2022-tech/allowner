import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';
import '../../services/hotel_service.dart';
import '../../utils/safe_parse.dart';
import '../booking/booking_screen.dart';

class UnitDetailsScreen extends ConsumerStatefulWidget {
  final int unitId;
  const UnitDetailsScreen({super.key, required this.unitId});

  @override
  ConsumerState<UnitDetailsScreen> createState() => _UnitDetailsScreenState();
}

class _UnitDetailsScreenState extends ConsumerState<UnitDetailsScreen> {
  final HotelService _hotelService = HotelService();
  late Future<Map<String, dynamic>> _future;
  int _galleryIndex = 0;
  final PageController _galleryController = PageController();
  bool _bookingLoading = false;

  @override
  void initState() {
    super.initState();
    _future = _hotelService.getUnitDetail(widget.unitId);
  }

  @override
  void dispose() {
    _galleryController.dispose();
    super.dispose();
  }

  String _categoryIcon(String cat) {
    switch (cat) {
      case 'extra_bed':
        return '🛏️';
      case 'meal_plan':
        return '🍽️';
      default:
        return '✨';
    }
  }

  Future<void> _goToBooking(bool isArabic, Map<String, dynamic> unit) async {
    setState(() => _bookingLoading = true);
    try {
      final hotel = await _hotelService.getHotelDetail(unit['hotel_id'].toString());
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BookingScreen(
            hotel: hotel,
            unitId: unit['id'] as int,
            unitName: isArabic ? unit['name_ar']?.toString() : unit['name_en']?.toString(),
            unitPricePerNight: asDouble(unit['price_per_night']),
            unitImageUrl: (unit['images'] as List).isNotEmpty ? unit['images'][0].toString() : null,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _bookingLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 32),
                    const SizedBox(height: AppDimens.sm),
                    Text(AppStrings.t(isArabic, 'error_loading')),
                    const SizedBox(height: AppDimens.sm),
                    TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(AppStrings.t(isArabic, 'back'))),
                  ],
                ),
              ),
            );
          }

          final unit = snapshot.data!;
          final images = (unit['images'] as List).map((e) => e.toString()).toList();
          final addons = (unit['addons'] as List).cast<Map<String, dynamic>>();
          final name = isArabic ? unit['name_ar']?.toString() ?? '' : unit['name_en']?.toString() ?? '';
          final desc = isArabic ? unit['description_ar']?.toString() ?? '' : unit['description_en']?.toString() ?? '';
          final city = isArabic ? unit['city_ar']?.toString() ?? '' : unit['city_en']?.toString() ?? '';

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 300,
                    pinned: true,
                    elevation: 0,
                    backgroundColor: AppColors.surface,
                    automaticallyImplyLeading: false,
                    leading: Padding(
                      padding: const EdgeInsets.all(8),
                      child: _CircleIconButton(
                        icon: isArabic ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      collapseMode: CollapseMode.pin,
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          PageView.builder(
                            controller: _galleryController,
                            itemCount: images.length,
                            onPageChanged: (i) => setState(() => _galleryIndex = i),
                            itemBuilder: (context, i) => CachedNetworkImage(
                              imageUrl: images[i],
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: AppColors.surfaceMuted,
                                child: const Center(child: CircularProgressIndicator(color: AppColors.gold)),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: AppColors.surfaceMuted,
                                child: Icon(Icons.image_outlined, size: 64, color: AppColors.textMuted),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: 90,
                            child: DecoratedBox(decoration: BoxDecoration(gradient: AppColors.darkOverlayGradient)),
                          ),
                          if (images.length > 1)
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
                                    dotColor: Colors.white.withOpacity(0.6),
                                  ),
                                ),
                              ),
                            ),
                          if (images.length > 1)
                            Positioned(
                              top: 14,
                              right: isArabic ? null : 14,
                              left: isArabic ? 14 : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.45),
                                  borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                                ),
                                child: Text(
                                  '${_galleryIndex + 1}/${images.length}',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(AppDimens.radiusXl),
                          topRight: Radius.circular(AppDimens.radiusXl),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(
                        AppDimens.pagePadding, AppDimens.lg, AppDimens.pagePadding, 120,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${unit['hotel_name'] ?? ''}${city.isNotEmpty ? ' · $city' : ''}',
                                  style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimens.md),

                          Wrap(
                            spacing: AppDimens.sm,
                            runSpacing: AppDimens.sm,
                            children: [
                              if ((isArabic ? unit['unit_type_ar'] : unit['unit_type_en'])?.toString().isNotEmpty == true)
                                _InfoChip(icon: Icons.label_outline_rounded, label: (isArabic ? unit['unit_type_ar'] : unit['unit_type_en']).toString()),
                              _InfoChip(icon: Icons.people_outline_rounded, label: '${unit['capacity']} ${AppStrings.t(isArabic, "guests")}'),
                              _InfoChip(icon: Icons.bed_outlined, label: '${unit['bed_count'] ?? 1} ${AppStrings.t(isArabic, "bed_count")}'),
                              if (unit['price_per_week'] != null)
                                _InfoChip(icon: Icons.calendar_view_week_rounded, label: '${asDouble(unit['price_per_week']).toStringAsFixed(0)} ${AppStrings.t(isArabic, "sar")}/${isArabic ? "أسبوع" : "week"}'),
                              if (unit['price_per_month'] != null)
                                _InfoChip(icon: Icons.calendar_month_rounded, label: '${asDouble(unit['price_per_month']).toStringAsFixed(0)} ${AppStrings.t(isArabic, "sar")}/${isArabic ? "شهر" : "month"}'),
                            ],
                          ),

                          if (desc.isNotEmpty) ...[
                            const SizedBox(height: AppDimens.lg),
                            Text(isArabic ? 'عن الجناح' : 'About this suite', style: textTheme.titleMedium),
                            const SizedBox(height: AppDimens.sm),
                            Text(desc, style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted, height: 1.5)),
                          ],

                          if (addons.isNotEmpty) ...[
                            const SizedBox(height: AppDimens.lg),
                            Text(AppStrings.t(isArabic, 'unit_addons_title'), style: textTheme.titleMedium),
                            const SizedBox(height: AppDimens.sm),
                            ...addons.map((a) => Container(
                                  margin: const EdgeInsets.only(bottom: AppDimens.sm),
                                  padding: const EdgeInsets.all(AppDimens.md),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceMuted,
                                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(_categoryIcon(a['category']?.toString() ?? ''), style: const TextStyle(fontSize: 18)),
                                      const SizedBox(width: AppDimens.sm),
                                      Expanded(
                                        child: Text(
                                          isArabic ? (a['name_ar']?.toString() ?? '') : (a['name_en']?.toString() ?? ''),
                                          style: textTheme.bodyMedium,
                                        ),
                                      ),
                                      Text(
                                        '${asDouble(a['price']).toStringAsFixed(0)} ${AppStrings.t(isArabic, "sar")}',
                                        style: textTheme.bodyMedium?.copyWith(color: AppColors.goldDark, fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // شريط سعر وحجز ثابت بأسفل الشاشة
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    AppDimens.pagePadding, AppDimens.md, AppDimens.pagePadding,
                    AppDimens.md + MediaQuery.of(context).padding.bottom,
                  ),
                  decoration: BoxDecoration(color: AppColors.surface, boxShadow: AppColors.cardShadow),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  asDouble(unit['price_per_night']).toStringAsFixed(0),
                                  style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: AppColors.goldDark),
                                ),
                                const SizedBox(width: 4),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    '${AppStrings.t(isArabic, "sar")} / ${AppStrings.t(isArabic, "night")}',
                                    style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: AppDimens.buttonHeight,
                        child: ElevatedButton(
                          onPressed: _bookingLoading ? null : () => _goToBooking(isArabic, unit),
                          child: _bookingLoading
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, this.iconColor, required this.onTap});

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
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8)],
        ),
        child: Icon(icon, color: iconColor ?? AppColors.ink, size: 20),
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
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
