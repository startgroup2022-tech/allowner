import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';
import '../../utils/session_provider.dart';
import '../../models/hotel_model.dart';
import '../home/main_navigation_screen.dart';
import '../owner/owner_navigation_screen.dart';
import '../owner/owner_bookings_screen.dart';

/// صفحة نجاح الحجز — تعرض بيانات الحجز الفعلية (رقم الحجز، التواريخ، الوحدة، العميل، الحالة، المبلغ)
class BookingSuccessScreen extends ConsumerWidget {
  final HotelModel hotel;
  final String? bookingRef;
  final double? total;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int? nights;
  final int? guests;
  final String? unitName;
  final String? guestName;
  final String? guestPhone;
  final String? status;
  final String? paymentMethod;

  const BookingSuccessScreen({
    super.key,
    required this.hotel,
    this.bookingRef,
    this.total,
    this.checkIn,
    this.checkOut,
    this.nights,
    this.guests,
    this.unitName,
    this.guestName,
    this.guestPhone,
    this.status,
    this.paymentMethod,
  });

  String _d(DateTime? d) => d == null
      ? '-'
      : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final textTheme = Theme.of(context).textTheme;
    final role = ref.watch(sessionProvider).user?.role;
    final ownerSide = role == 'booking_agent' || role == 'owner' || role == 'unit_manager';

    final rows = <(String, String)>[
      (AppStrings.t(isArabic, 'booking_reference'), bookingRef ?? '-'),
      (AppStrings.t(isArabic, 'hotel'), hotel.name),
      if (unitName != null && unitName!.isNotEmpty) (AppStrings.t(isArabic, 'unit_label'), unitName!),
      (AppStrings.t(isArabic, 'stay_dates'), '${_d(checkIn)}  →  ${_d(checkOut)}${nights != null ? '  (${nights} ${AppStrings.t(isArabic, 'nights')})' : ''}'),
      if (guests != null) (AppStrings.t(isArabic, 'guests'), '$guests'),
      if (guestName != null && guestName!.isNotEmpty)
        (AppStrings.t(isArabic, 'customer_label'), '$guestName${guestPhone != null && guestPhone!.isNotEmpty ? '\n$guestPhone' : ''}'),
      if (paymentMethod != null) (AppStrings.t(isArabic, 'payment_method_label'), AppStrings.t(isArabic, 'pay_method_$paymentMethod')),
      if (status != null) (AppStrings.t(isArabic, 'booking_status_label'), AppStrings.t(isArabic, 'status_$status')),
      if (total != null) (AppStrings.t(isArabic, 'total_price'), '${total!.toStringAsFixed(0)} ${AppStrings.t(isArabic, 'sar')}'),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.pagePadding),
          child: Column(
            children: [
              const SizedBox(height: AppDimens.xl),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: AppColors.success, size: 52),
              ),
              const SizedBox(height: AppDimens.lg),
              Text(AppStrings.t(isArabic, 'booking_success'), textAlign: TextAlign.center, style: textTheme.headlineMedium),
              const SizedBox(height: AppDimens.sm),
              Text(AppStrings.t(isArabic, 'booking_success_desc'),
                  textAlign: TextAlign.center, style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppDimens.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimens.md),
                decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(AppDimens.radiusMd)),
                child: Column(
                  children: [
                    for (int i = 0; i < rows.length; i++) ...[
                      if (i != 0) const Divider(height: 18),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(rows[i].$1, style: textTheme.bodySmall),
                          const SizedBox(width: AppDimens.md),
                          Expanded(
                            child: Text(
                              rows[i].$2,
                              textAlign: TextAlign.end,
                              style: textTheme.titleSmall?.copyWith(color: i == 0 ? AppColors.goldDark : null),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.xl),
              SizedBox(
                width: double.infinity,
                height: AppDimens.buttonHeight,
                child: ElevatedButton(
                  onPressed: () {
                    // نفتح الرئيسية ثم نعرض حجوزاتي / حجوزات الوكيل
                    final nav = Navigator.of(context);
                    nav.pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => ownerSide ? const OwnerNavigationScreen() : const MainNavigationScreen(initialIndex: 2)),
                      (route) => false,
                    );
                    if (ownerSide) {
                      nav.push(MaterialPageRoute(builder: (_) => const OwnerBookingsScreen()));
                    }
                  },
                  child: Text(AppStrings.t(isArabic, 'view_booking_details')),
                ),
              ),
              const SizedBox(height: AppDimens.sm),
              SizedBox(
                width: double.infinity,
                height: AppDimens.buttonHeight,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => ownerSide ? const OwnerNavigationScreen() : const MainNavigationScreen()),
                      (route) => false,
                    );
                  },
                  child: Text(AppStrings.t(isArabic, 'home')),
                ),
              ),
              const SizedBox(height: AppDimens.lg),
            ],
          ),
        ),
      ),
    );
  }
}
