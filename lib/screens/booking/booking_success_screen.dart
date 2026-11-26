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

/// صفوف صفحة نجاح الحجز. دالة نقية حتى يمكن اختبار ما يُعرض فعلًا (المتطلبات
/// 33 و46 و146، والمتطلبات 3 و4 و5 من المستند 06): كل صف يُضاف فقط عند وجود
/// بياناته الحقيقية، ولا يُختلق بديل.
///
/// - الحقل الأول صار «رقم الضيافة» (المتطلب 3) ويعرض **رقم الوحدة الفعلي**
///   (المتطلب 4) الذي وصل من استجابة الحجز أو من الوحدة المختارة. إن لم يصل رقم
///   وحدة حقيقي نعرض رقم الحجز الحقيقي بدل اختلاق رقم.
/// - لا تُعرض طريقة الدفع إطلاقًا (المتطلب 5) مع بقاء تسجيلها في السيرفر.
List<(String, String)> buildBookingSuccessRows({
  required bool isArabic,
  required String hotelName,
  String? city,
  String? address,
  String? unitName,
  String? unitNumber,
  String? bookingRef,
  DateTime? checkIn,
  DateTime? checkOut,
  int? nights,
  int? guests,
  String? guestName,
  String? guestPhone,
  String? guestIdNumber,
  String? status,
  double? total,
}) {
  String d(DateTime? value) => value == null
      ? '-'
      : '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  String t(String key) => AppStrings.t(isArabic, key);

  final actualUnitNumber = (unitNumber ?? '').trim();
  final stayReference = actualUnitNumber.isNotEmpty
      ? actualUnitNumber
      : (bookingRef ?? '').trim().isNotEmpty
          ? bookingRef!.trim()
          : '-';

  final rows = <(String, String)>[
    (t('stay_reference'), stayReference),
    (t('hotel'), hotelName),
    // المتطلب 46: بيانات وصول الضيف للوحدة — من بيانات الفندق الحقيقية فقط،
    // وتُخفى كليًا إن لم تُرجع.
    if ((city ?? '').trim().isNotEmpty) (t('city_label'), city!.trim()),
    if ((address ?? '').trim().isNotEmpty)
      (t('address_label'), address!.trim()),
    if ((unitName ?? '').trim().isNotEmpty) (t('unit_label'), unitName!.trim()),
    (
      t('stay_dates'),
      '${d(checkIn)}  →  ${d(checkOut)}'
          '${nights != null ? '  ($nights ${t('nights')})' : ''}'
    ),
    if (guests != null) (t('guests'), '$guests'),
    if ((guestName ?? '').trim().isNotEmpty)
      (
        t('customer_label'),
        '$guestName${(guestPhone ?? '').trim().isNotEmpty ? '\n$guestPhone' : ''}'
      ),
    // المتطلب 146: رقم الهوية/الجواز جزء من بيانات التأكيد التي يعتمد عليها
    // بريد التأكيد — يُعرض للضيف للتأكد من صحته قبل إرسال البريد.
    if ((guestIdNumber ?? '').trim().isNotEmpty)
      (t('guest_id_number'), guestIdNumber!.trim()),
    if ((status ?? '').trim().isNotEmpty)
      (t('booking_status_label'), t('status_$status')),
    if (total != null)
      (t('total_price'), '${total.toStringAsFixed(0)} ${t('sar')}'),
  ];
  return rows;
}

/// صفحة نجاح الحجز — تعرض بيانات الحجز الفعلية (رقم الوحدة كمرجع ضيافة،
/// التواريخ، الوحدة، العميل، الحالة، المبلغ). لا تُعرض طريقة الدفع (المتطلب 5
/// من المستند 06) مع بقاء تسجيلها في السيرفر.
class BookingSuccessScreen extends ConsumerWidget {
  final HotelModel hotel;
  final String? bookingRef;

  /// رقم الوحدة الفعلي (المتطلب 4 من المستند 06) — من استجابة الحجز أو الوحدة
  /// المختارة، ولا يُختلق إن لم يصل.
  final String? unitNumber;
  final double? total;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int? nights;
  final int? guests;
  final String? unitName;
  final String? guestName;
  final String? guestPhone;
  final String? guestIdNumber;
  final String? status;

  const BookingSuccessScreen({
    super.key,
    required this.hotel,
    this.bookingRef,
    this.unitNumber,
    this.total,
    this.checkIn,
    this.checkOut,
    this.nights,
    this.guests,
    this.unitName,
    this.guestName,
    this.guestPhone,
    this.guestIdNumber,
    this.status,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final textTheme = Theme.of(context).textTheme;
    final role = ref.watch(sessionProvider).user?.role;
    final ownerSide =
        role == 'booking_agent' || role == 'owner' || role == 'unit_manager';

    final rows = buildBookingSuccessRows(
      isArabic: isArabic,
      hotelName: hotel.name,
      city: hotel.city(isArabic),
      address: hotel.address,
      unitName: unitName,
      unitNumber: unitNumber,
      bookingRef: bookingRef,
      checkIn: checkIn,
      checkOut: checkOut,
      nights: nights,
      guests: guests,
      guestName: guestName,
      guestPhone: guestPhone,
      guestIdNumber: guestIdNumber,
      status: status,
      total: total,
    );

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
                decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded,
                    color: AppColors.success, size: 52),
              ),
              const SizedBox(height: AppDimens.lg),
              Text(AppStrings.t(isArabic, 'booking_success'),
                  textAlign: TextAlign.center, style: textTheme.headlineMedium),
              const SizedBox(height: AppDimens.sm),
              Text(AppStrings.t(isArabic, 'booking_success_desc'),
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppDimens.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimens.md),
                decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd)),
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
                              style: textTheme.titleSmall?.copyWith(
                                  color: i == 0 ? AppColors.goldDark : null),
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
                    // نفتح الرئيسية ثم نعرض ضيافاتي / حجوزات الوكيل
                    final nav = Navigator.of(context);
                    nav.pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (_) => ownerSide
                              ? const OwnerNavigationScreen()
                              : const MainNavigationScreen(initialIndex: 2)),
                      (route) => false,
                    );
                    if (ownerSide) {
                      nav.push(MaterialPageRoute(
                          builder: (_) => const OwnerBookingsScreen()));
                    }
                  },
                  // المتطلب 6 من المستند 06: إجراء الضيف «عرض تفاصيل ضيافتي»،
                  // ويبقى «عرض تفاصيل الحجز» لمصطلح الوكيل/المالك.
                  child: Text(AppStrings.t(
                      isArabic,
                      ownerSide
                          ? 'view_booking_details'
                          : 'view_stay_details')),
                ),
              ),
              const SizedBox(height: AppDimens.sm),
              SizedBox(
                width: double.infinity,
                height: AppDimens.buttonHeight,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (_) => ownerSide
                              ? const OwnerNavigationScreen()
                              : const MainNavigationScreen()),
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
