import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/city_model.dart';
import '../models/hotel_model.dart';
import '../models/owner_hotel_summary.dart';
import '../models/unit_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../utils/amenity_icons.dart';
import '../utils/app_strings.dart';
import 'state_views.dart';

/// عرض السعر الموحّد: الرقم + العملة + المدة. يتعامل مع السعر الصفري
/// (يعني السيرفر ما فيه سعر مسجّل) بعرض "السعر عند الطلب" بدل "0 ريال".
class PriceText extends StatelessWidget {
  final double amount;
  final bool isArabic;
  final bool perNight;
  final double fontSize;
  final bool onDark;

  const PriceText({
    super.key,
    required this.amount,
    required this.isArabic,
    this.perNight = true,
    this.fontSize = 15,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    if (amount <= 0) {
      return Text(
        AppStrings.t(isArabic, 'price_on_request'),
        style: TextStyle(
          fontSize: fontSize - 2,
          fontWeight: FontWeight.w600,
          color: onDark ? Colors.white70 : AppColors.textMuted,
        ),
      );
    }

    final color = onDark ? Colors.white : AppColors.goldDark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          _formatAmount(amount),
          style: TextStyle(
              fontSize: fontSize, fontWeight: FontWeight.w800, color: color),
        ),
        const SizedBox(width: 3),
        Text(
          AppStrings.t(isArabic, 'sar'),
          style: TextStyle(
            fontSize: fontSize - 3,
            fontWeight: FontWeight.w600,
            color: onDark ? Colors.white70 : AppColors.textMuted,
          ),
        ),
        if (perNight)
          Text(
            ' ${AppStrings.t(isArabic, 'per_night')}',
            style: TextStyle(
              fontSize: fontSize - 4,
              color: onDark ? Colors.white60 : AppColors.textMuted,
            ),
          ),
      ],
    );
  }

  static String _formatAmount(double amount) {
    if (amount == amount.roundToDouble()) return amount.toInt().toString();
    return amount.toStringAsFixed(2);
  }
}

/// شارة صغيرة (إلغاء مجاني، إفطار مشمول...) — موحّدة في كل الشاشات.
class AppBadge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const AppBadge(
      {super.key, required this.text, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
                fontSize: 10.5, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

/// بطاقة فندق أفقية — تُستخدم في نتائج البحث وقائمة الفنادق.
class HotelCard extends StatelessWidget {
  final HotelModel hotel;
  final bool isArabic;
  final VoidCallback onTap;

  const HotelCard({
    super.key,
    required this.hotel,
    required this.isArabic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: hotel.name,
      child: InkWell(
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
              AppNetworkImage(
                url: hotel.imageUrl,
                width: 104,
                height: 104,
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
              const SizedBox(width: AppDimens.sm),
              Expanded(
                child: SizedBox(
                  height: 104,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hotel.name,
                        style: textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (hotel.type(isArabic).isNotEmpty)
                        Text(
                          hotel.type(isArabic),
                          style: textTheme.bodySmall
                              ?.copyWith(color: AppColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              hotel.city(isArabic),
                              style: textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (hotel.stars > 0)
                        Row(
                          children: List.generate(
                            hotel.stars.clamp(0, 5),
                            (_) => const Icon(Icons.star_rounded,
                                size: 13, color: AppColors.goldDark),
                          ),
                        ),
                      const Spacer(),
                      Align(
                        alignment: isArabic
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: PriceText(
                          amount: hotel.pricePerNight,
                          isArabic: isArabic,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// بطاقة وحدة عمودية — تُستخدم في الشرائح الأفقية بالصفحة الرئيسية.
class UnitCard extends StatelessWidget {
  final UnitModel unit;
  final bool isArabic;
  final VoidCallback onTap;
  final double width;

  const UnitCard({
    super.key,
    required this.unit,
    required this.isArabic,
    required this.onTap,
    this.width = 224,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final unitType = unit.unitType(isArabic);

    return Semantics(
      button: true,
      label: unit.name(isArabic),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        child: Container(
          width: width,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppNetworkImage(
                url: unit.coverImage,
                height: 124,
                width: double.infinity,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppDimens.radiusLg),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppDimens.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unit.name(isArabic),
                      style: textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (unitType.isNotEmpty)
                      Text(
                        unitType,
                        style: textTheme.labelSmall
                            ?.copyWith(color: AppColors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            unit.hotelName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall
                                ?.copyWith(color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _MiniChip(
                          icon: Icons.people_outline_rounded,
                          label: '${unit.capacity}',
                        ),
                        const SizedBox(width: 6),
                        _MiniChip(
                          icon: Icons.bed_outlined,
                          label: '${unit.bedCount}',
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Align(
                            alignment: isArabic
                                ? AlignmentDirectional.centerStart
                                : AlignmentDirectional.centerEnd,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: PriceText(
                                amount: unit.pricePerNight,
                                isArabic: isArabic,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// بطاقة وحدة أفقية — تُستخدم في قائمة نتائج البحث.
class UnitListCard extends StatelessWidget {
  final UnitModel unit;
  final bool isArabic;
  final VoidCallback onTap;

  const UnitListCard({
    super.key,
    required this.unit,
    required this.isArabic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final unitType = unit.unitType(isArabic);

    return Semantics(
      button: true,
      label: unit.name(isArabic),
      child: InkWell(
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
              AppNetworkImage(
                url: unit.coverImage,
                width: 106,
                height: 106,
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
              const SizedBox(width: AppDimens.sm),
              Expanded(
                child: SizedBox(
                  height: 106,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        unit.name(isArabic),
                        style: textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (unitType.isNotEmpty)
                        Text(
                          unitType,
                          style: textTheme.bodySmall
                              ?.copyWith(color: AppColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              unit.hotelName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textMuted),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _MiniChip(
                            icon: Icons.people_outline_rounded,
                            label: '${unit.capacity}',
                          ),
                          const SizedBox(width: 6),
                          _MiniChip(
                            icon: Icons.bed_outlined,
                            label: '${unit.bedCount}',
                          ),
                        ],
                      ),
                      const Spacer(),
                      Align(
                        alignment: isArabic
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: PriceText(
                          amount: unit.pricePerNight,
                          isArabic: isArabic,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MiniChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.secondary),
          const SizedBox(width: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة تصنيف إقامة — تُبنى من `categories/list.php` (لا تصنيفات ثابتة).
class CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final bool isArabic;
  final bool selected;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.category,
    required this.isArabic,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorFromHex(category.colorHex) ?? AppColors.ink;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      child: SizedBox(
        width: 78,
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: color.withValues(alpha: selected ? 0.18 : 0.08),
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                border: selected ? Border.all(color: color, width: 1.4) : null,
              ),
              child:
                  Icon(_iconForKey(category.iconKey), color: color, size: 26),
            ),
            const SizedBox(height: 6),
            Text(
              category.displayName(isArabic),
              style: Theme.of(context).textTheme.labelSmall,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  static IconData _iconForKey(String key) {
    switch (key.toLowerCase()) {
      case 'hotels':
        return Icons.king_bed_outlined;
      case 'apartments':
        return Icons.apartment_rounded;
      case 'resorts':
        return Icons.beach_access_rounded;
      case 'chalets':
        return Icons.cabin_outlined;
      case 'properties':
        return Icons.villa_outlined;
      default:
        return Icons.home_work_outlined;
    }
  }

  static Color? _colorFromHex(String hex) {
    final cleaned = hex.replaceAll('#', '').trim();
    if (cleaned.length != 6) return null;
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return null;
    return Color(0xFF000000 | value);
  }
}

/// بطاقة وجهة (مدينة) — صورة + اسم، تُبنى من `cities/list.php`.
class DestinationCard extends StatelessWidget {
  final CityModel city;
  final bool isArabic;
  final VoidCallback onTap;

  const DestinationCard({
    super.key,
    required this.city,
    required this.isArabic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: city.name(isArabic),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        child: SizedBox(
          width: 140,
          height: 168,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AppNetworkImage(url: city.imageUrl, fit: BoxFit.cover),
                const DecoratedBox(
                  decoration:
                      BoxDecoration(gradient: AppColors.darkOverlayGradient),
                ),
                Positioned(
                  left: AppDimens.sm,
                  right: AppDimens.sm,
                  bottom: AppDimens.sm,
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          city.name(isArabic),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// بطاقة فندق يحتوي على وحدات ملاك — تُستخدم في قسم «فنادق بوحدات ملاك».
///
/// تُظهر: صورة الفندق، الاسم، المدينة، التقييم (إن وُجد)، وعدد الوحدات المتاحة
/// للحجز. كل القيم من بيانات الـ API الفعلية — لا أرقام مكتوبة في الواجهة.
class OwnerHotelCard extends StatelessWidget {
  final OwnerHotelSummary summary;
  final bool isArabic;
  final VoidCallback onTap;

  const OwnerHotelCard({
    super.key,
    required this.summary,
    required this.isArabic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: summary.name,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        child: Container(
          width: 220,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            border: Border.all(color: AppColors.cardBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AppNetworkImage(
                    url: summary.imageUrl,
                    width: 220,
                    height: 118,
                    borderRadius: BorderRadius.zero,
                  ),
                  if (summary.rating > 0)
                    Positioned(
                      top: AppDimens.sm,
                      left: isArabic ? AppDimens.sm : null,
                      right: isArabic ? null : AppDimens.sm,
                      child: _RatingPill(
                        rating: summary.rating,
                        reviews: summary.reviewsCount,
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(AppDimens.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.name,
                      style: textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            summary.city(isArabic),
                            style: textTheme.bodySmall
                                ?.copyWith(color: AppColors.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.meeting_room_outlined,
                            size: 13, color: AppColors.goldDark),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            '${summary.unitCount} ${AppStrings.t(isArabic, 'units_available_count')}',
                            style: textTheme.bodySmall
                                ?.copyWith(color: AppColors.goldDark),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: isArabic
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: PriceText(
                        amount: summary.minPrice,
                        isArabic: isArabic,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// شارة تقييم صغيرة تُعرض فوق صورة البطاقة.
class _RatingPill extends StatelessWidget {
  final double rating;
  final int reviews;

  const _RatingPill({required this.rating, this.reviews = 0});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 13, color: AppColors.gold),
          const SizedBox(width: 2),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// بلاطة مرفق (أيقونة + نص) — تُستخدم في تفاصيل الفندق والوحدة.
class AmenityTile extends StatelessWidget {
  final String iconKey;
  final String nameEn;
  final String nameAr;
  final String label;

  const AmenityTile({
    super.key,
    required this.label,
    this.iconKey = '',
    this.nameEn = '',
    this.nameAr = '',
  });

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
          Icon(
            AmenityIcons.resolve(
                iconKey: iconKey, nameEn: nameEn, nameAr: nameAr),
            size: 18,
            color: AppColors.goldDark,
          ),
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
