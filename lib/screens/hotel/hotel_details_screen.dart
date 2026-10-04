import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';
import '../../utils/session_provider.dart';
import '../../models/hotel_model.dart';
import '../../services/hotel_service.dart';
import '../../utils/safe_parse.dart';
import '../booking/booking_screen.dart';
import '../unit/unit_details_screen.dart';

class HotelDetailsScreen extends ConsumerStatefulWidget {
  final HotelModel hotel;
  const HotelDetailsScreen({super.key, required this.hotel});

  @override
  ConsumerState<HotelDetailsScreen> createState() => _HotelDetailsScreenState();
}

class _HotelDetailsScreenState extends ConsumerState<HotelDetailsScreen> {
  final HotelService _hotelService = HotelService();
  late bool _isFavorite;
  bool _showFullDescription = false;
  int _galleryIndex = 0;
  final PageController _galleryController = PageController();
  late Future<List<Map<String, dynamic>>> _unitsFuture;
  late Future<List<Map<String, dynamic>>> _amenitiesFuture;

  IconData _amenityIcon(Map<String, dynamic> amenity) {
    final raw = '${amenity['icon'] ?? ''} ${amenity['name_en'] ?? ''} ${amenity['name_ar'] ?? ''}'.toLowerCase();
    if (raw.contains('wifi') || raw.contains('واي')) return Icons.wifi_rounded;
    if (raw.contains('parking') || raw.contains('موقف')) return Icons.local_parking_outlined;
    if (raw.contains('pool') || raw.contains('مسبح')) return Icons.pool_outlined;
    if (raw.contains('fitness') || raw.contains('gym') || raw.contains('رياضي')) return Icons.fitness_center_outlined;
    if (raw.contains('ac_unit') || raw.contains('air conditioning') || raw.contains('مكيف')) return Icons.ac_unit_rounded;
    if (raw.contains('restaurant') || raw.contains('مطعم')) return Icons.restaurant_outlined;
    if (raw.contains('breakfast') || raw.contains('إفطار')) return Icons.free_breakfast_outlined;
    if (raw.contains('coffee') || raw.contains('قهوة')) return Icons.coffee_maker_outlined;
    if (raw.contains('smoke') || raw.contains('تدخين')) return Icons.smoke_free_outlined;
    if (raw.contains('accessible') || raw.contains('احتياجات')) return Icons.accessible_rounded;
    if (raw.contains('meeting') || raw.contains('اجتماع')) return Icons.meeting_room_outlined;
    if (raw.contains('car') || raw.contains('transport') || raw.contains('سيار') || raw.contains('نقل')) return Icons.directions_car_outlined;
    if (raw.contains('family') || raw.contains('عائل')) return Icons.family_restroom_outlined;
    if (raw.contains('pet') || raw.contains('حيوان')) return Icons.pets_outlined;
    if (raw.contains('room_service') || raw.contains('room service') || raw.contains('خدمة الغرف')) return Icons.room_service_outlined;
    return Icons.check_circle_outline_rounded;
  }

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.hotel.isFavorite;
    _unitsFuture = _hotelService.getUnits(widget.hotel.id);
    _amenitiesFuture = _hotelService.getHotelAmenities(widget.hotel.id);
  }

  Future<void> _toggleFavorite() async {
    if (!ref.read(sessionProvider).isLoggedIn) {
      final isArabic = ref.read(localeProvider).languageCode == 'ar';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isArabic ? 'الرجاء تسجيل الدخول أولاً' : 'Please log in first')),
      );
      return;
    }
    // تحديث فوري بالواجهة، ثم مزامنة مع السيرفر
    setState(() => _isFavorite = !_isFavorite);
    try {
      final favorited = await _hotelService.toggleFavorite(widget.hotel.id);
      if (mounted) setState(() => _isFavorite = favorited);
    } catch (_) {
      // بالفشل، رجّع الحالة الأصلية
      if (mounted) setState(() => _isFavorite = !_isFavorite);
    }
  }

  @override
  void dispose() {
    _galleryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final textTheme = Theme.of(context).textTheme;
    final hotel = widget.hotel;

    final images = hotel.galleryUrls.isNotEmpty ? hotel.galleryUrls : [hotel.imageUrl];


    final description = isArabic
        ? 'يقع ${hotel.name} في موقع متميز بـ${hotel.cityAr}، يوفر إقامة فاخرة مع خدمات متكاملة وإطلالات رائعة، مناسب للأعمال والعائلات. يضم العقار غرفاً مجهزة بالكامل وفريق استقبال يعمل على مدار الساعة لتلبية كل احتياجاتك خلال إقامتك.'
        : '${hotel.name} is ideally located in ${hotel.cityEn}, offering a luxurious stay with full amenities and great views, suitable for business and family travelers. The property features fully equipped rooms and a 24-hour front desk team dedicated to making your stay seamless.';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            stretch: true,
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
            actions: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: _CircleIconButton(
                  icon: _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  iconColor: _isFavorite ? AppColors.danger : AppColors.ink,
                  onTap: _toggleFavorite,
                ),
              ),
            ],
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
                        child: const Center(
                          child: CircularProgressIndicator(color: AppColors.gold),
                        ),
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
                    child: DecoratedBox(
                      decoration: BoxDecoration(gradient: AppColors.darkOverlayGradient),
                    ),
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
                AppDimens.pagePadding,
                AppDimens.lg,
                AppDimens.pagePadding,
                AppDimens.pagePadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text(hotel.name, style: textTheme.headlineMedium)),
                      const SizedBox(width: AppDimens.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 16, color: AppColors.secondary),
                            Text(' ${hotel.rating}',
                                style: const TextStyle(
                                    color: AppColors.secondary, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      ...List.generate(hotel.stars,
                          (i) => const Icon(Icons.star_rounded, size: 14, color: AppColors.goldDark)),
                      const SizedBox(width: 4),
                      Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                      Text('${hotel.city(isArabic)} · ${hotel.type(isArabic)}',
                          style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                      Text(' · ${hotel.reviewsCount} ${AppStrings.t(isArabic, 'reviews')}',
                          style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                    ],
                  ),
                  const SizedBox(height: AppDimens.lg),

                  Wrap(
                    spacing: AppDimens.sm,
                    runSpacing: AppDimens.sm,
                    children: [
                      if (hotel.freeCancellation)
                        _Badge(text: AppStrings.t(isArabic, 'free_cancellation'), color: AppColors.success),
                      if (hotel.breakfastIncluded)
                        _Badge(text: AppStrings.t(isArabic, 'breakfast_included'), color: AppColors.secondary),
                      _Badge(text: AppStrings.t(isArabic, 'pay_at_property'), color: AppColors.goldDark),
                    ],
                  ),
                  const SizedBox(height: AppDimens.lg),
                  const Divider(),
                  const SizedBox(height: AppDimens.lg),

                  Text(AppStrings.t(isArabic, 'about_property'), style: textTheme.titleMedium),
                  const SizedBox(height: AppDimens.sm),
                  Text(
                    description,
                    maxLines: _showFullDescription ? null : 3,
                    overflow: _showFullDescription ? TextOverflow.visible : TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.7),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _showFullDescription = !_showFullDescription),
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
                  const SizedBox(height: AppDimens.lg),
                  const Divider(),
                  const SizedBox(height: AppDimens.lg),

                  Text(AppStrings.t(isArabic, 'available_units'), style: textTheme.titleMedium),
                  const SizedBox(height: AppDimens.md),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _unitsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: AppDimens.md),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final units = snapshot.data ?? [];
                      if (units.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppDimens.sm),
                          child: Text(AppStrings.t(isArabic, 'no_units'),
                              style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                        );
                      }
                      return Column(
                        children: units.map((u) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: AppDimens.sm),
                            padding: const EdgeInsets.all(AppDimens.sm),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => UnitDetailsScreen(unitId: u['id'] as int)),
                                  ),
                                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                                    child: CachedNetworkImage(
                                      imageUrl: u['cover_image']?.toString() ?? '',
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                      errorWidget: (context, url, error) =>
                                          Container(width: 56, height: 56, color: AppColors.surfaceMuted, child: const Icon(Icons.hotel_outlined)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppDimens.sm),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => UnitDetailsScreen(unitId: u['id'] as int)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(isArabic ? (u['name_ar']?.toString() ?? '') : (u['name_en']?.toString() ?? ''),
                                            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                                        Text(
                                          '${asInt(u['price_per_night'])} ${AppStrings.t(isArabic, "sar")} / ${AppStrings.t(isArabic, "night")}',
                                          style: textTheme.bodySmall?.copyWith(color: AppColors.goldDark, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => BookingScreen(
                                          hotel: hotel,
                                          unitId: u['id'] as int,
                                          unitName: isArabic ? u['name_ar']?.toString() : u['name_en']?.toString(),
                                          unitPricePerNight: asDouble(u['price_per_night']),
                                          unitImageUrl: u['cover_image']?.toString(),
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14)),
                                  child: Text(AppStrings.t(isArabic, 'book_now'), style: const TextStyle(fontSize: 13)),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: AppDimens.lg),
                  const Divider(),
                  const SizedBox(height: AppDimens.lg),

                  Text(AppStrings.t(isArabic, 'amenities'), style: textTheme.titleMedium),
                  const SizedBox(height: AppDimens.md),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _amenitiesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: Padding(
                          padding: EdgeInsets.all(AppDimens.md),
                          child: CircularProgressIndicator(),
                        ));
                      }
                      final amenities = snapshot.data ?? const <Map<String, dynamic>>[];
                      if (amenities.isEmpty) {
                        return Text(isArabic ? 'لا توجد مرافق مضافة لهذا الفندق' : 'No amenities added for this hotel',
                            style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted));
                      }
                      return Wrap(
                        spacing: AppDimens.md,
                        runSpacing: AppDimens.md,
                        children: amenities.map((a) => SizedBox(
                          width: (MediaQuery.sizeOf(context).width - (AppDimens.pagePadding * 2) - AppDimens.md) / 2,
                          child: _AmenityTile(
                            icon: _amenityIcon(a),
                            label: (isArabic ? a['name_ar'] : a['name_en'])?.toString() ?? '',
                          ),
                        )).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: AppDimens.lg),
                  const Divider(),
                  const SizedBox(height: AppDimens.lg),

                  Text(AppStrings.t(isArabic, 'location'), style: textTheme.titleMedium),
                  const SizedBox(height: AppDimens.sm),
                  InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                    child: Container(
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
                              color: AppColors.gold.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                            ),
                            child: const Icon(Icons.map_outlined, color: AppColors.goldDark),
                          ),
                          const SizedBox(width: AppDimens.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(hotel.city(isArabic), style: textTheme.titleSmall),
                                const SizedBox(height: 2),
                                Text(AppStrings.t(isArabic, 'view_on_map'),
                                    style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                          Icon(
                            isArabic ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimens.lg),
                  const Divider(),
                  const SizedBox(height: AppDimens.lg),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppStrings.t(isArabic, 'guest_reviews'), style: textTheme.titleMedium),
                      TextButton(onPressed: () {}, child: Text(AppStrings.t(isArabic, 'see_all_reviews'))),
                    ],
                  ),
                  _ReviewItem(
                    name: isArabic ? 'محمد العتيبي' : 'Mohammed Alotaibi',
                    rating: 5,
                    comment: isArabic
                        ? 'إقامة رائعة، خدمة ممتازة وموقع مثالي.'
                        : 'Amazing stay, excellent service and perfect location.',
                  ),
                  const Divider(height: AppDimens.lg),
                  _ReviewItem(
                    name: isArabic ? 'سارة القحطاني' : 'Sarah Alqahtani',
                    rating: 4,
                    comment: isArabic
                        ? 'تجربة جيدة جداً، الغرف نظيفة والإفطار متنوع.'
                        : 'Very good experience, clean rooms and a varied breakfast.',
                  ),
                  const SizedBox(height: AppDimens.xxl + AppDimens.xl),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.pagePadding, vertical: AppDimens.md),
        decoration: BoxDecoration(color: AppColors.surface, boxShadow: AppColors.cardShadow),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(AppStrings.t(isArabic, 'per_night'),
                        style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                    Row(
                      children: [
                        Text('${hotel.pricePerNight.toInt()}',
                            style: textTheme.headlineSmall?.copyWith(color: AppColors.goldDark)),
                        const SizedBox(width: 4),
                        Text(AppStrings.t(isArabic, 'sar'),
                            style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimens.md),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => BookingScreen(hotel: hotel)),
                    );
                  },
                  child: Text(AppStrings.t(isArabic, 'book_now')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;
  const _CircleIconButton({required this.icon, required this.onTap, this.iconColor = AppColors.ink});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.92),
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

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _AmenityTile extends StatelessWidget {
  final IconData icon;
  final String label;
  const _AmenityTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.goldDark),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final String name;
  final int rating;
  final String comment;

  const _ReviewItem({required this.name, required this.rating, required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.surfaceMuted,
            child: const Icon(Icons.person_rounded, size: 18, color: AppColors.textMuted),
          ),
          const SizedBox(width: AppDimens.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleSmall),
                Row(
                  children: List.generate(
                      rating, (i) => const Icon(Icons.star_rounded, size: 12, color: AppColors.goldDark)),
                ),
                const SizedBox(height: 2),
                Text(comment,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}