import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';
import '../../services/hotel_staff_service.dart';
import '../../utils/safe_parse.dart';
import 'hotel_arrivals_screen.dart';
import 'hotel_bookings_screen.dart';
import 'hotel_departures_screen.dart';
import 'hotel_requests_screen.dart';
import 'hotel_meal_pricing_screen.dart';
import 'hotel_unit_pricing_screen.dart';

class HotelDashboardScreen extends ConsumerStatefulWidget {
  const HotelDashboardScreen({super.key});

  @override
  ConsumerState<HotelDashboardScreen> createState() =>
      _HotelDashboardScreenState();
}

class _HotelDashboardScreenState extends ConsumerState<HotelDashboardScreen> {
  final _service = HotelStaffService();
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getDashboard();
  }

  void _reload() => setState(() {
        _future = _service.getDashboard();
      });

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(AppStrings.t(isArabic, 'hotel_dashboard')),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _reload(),
          child: FutureBuilder<Map<String, dynamic>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppDimens.xl),
                  children: [
                    Icon(Icons.error_outline_rounded,
                        color: AppColors.danger, size: 32),
                    const SizedBox(height: AppDimens.sm),
                    Text(AppStrings.t(isArabic, 'error_loading'),
                        textAlign: TextAlign.center),
                    const SizedBox(height: AppDimens.sm),
                    Center(
                        child: OutlinedButton(
                            onPressed: _reload,
                            child: Text(AppStrings.t(isArabic, 'retry')))),
                  ],
                );
              }

              final data = snapshot.data ?? {};
              final hotels = asMapList(data['hotels']);
              final pending = asMap(data['pending']);
              final openRequests = asInt(pending['cleaning']) +
                  asInt(pending['extra_bed']) +
                  asInt(pending['maintenance']) +
                  asInt(pending['meal']);
              final cards = <(String, dynamic, IconData, Color, VoidCallback?)>[
                (
                  AppStrings.t(isArabic, 'arrivals_today'),
                  data['arrivals_today'] ?? 0,
                  Icons.login_rounded,
                  AppColors.success,
                  // المتطلبان 80 و81: الوصولات مفتوحة وفيها بحث برقم الوحدة.
                  () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const HotelArrivalsScreen()))
                ),
                (
                  AppStrings.t(isArabic, 'departures_today'),
                  data['departures_today'] ?? 0,
                  Icons.logout_rounded,
                  AppColors.secondary,
                  // المتطلب 9 من المستند 06: شاشة المغادرات مع بحث برقم الوحدة.
                  () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const HotelDeparturesScreen()))
                ),
                (
                  AppStrings.t(isArabic, 'in_house_now'),
                  data['in_house'] ?? 0,
                  Icons.event_available_rounded,
                  AppColors.ink,
                  // المتطلب 80: البطاقة تفتح قائمة حجوزات الفندق النشطة.
                  () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const HotelBookingsScreen()))
                ),
                (
                  AppStrings.t(isArabic, 'open_requests'),
                  openRequests,
                  Icons.pending_actions_rounded,
                  AppColors.warning,
                  // المتطلب 80: البطاقة تفتح طلبات الخدمة المفتوحة.
                  () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const HotelRequestsScreen()))
                ),
              ];

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppDimens.pagePadding),
                children: [
                  if (hotels.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppDimens.md),
                      child: Text(hotels.map((h) => h['name']).join(' • '),
                          style: textTheme.titleMedium),
                    ),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: AppDimens.md,
                    mainAxisSpacing: AppDimens.md,
                    // 1.3 كان يضغط خلية العمود على العروض الضيقة (360px) فتفيض
                    // التسمية 2px؛ 1.15 يمنح ارتفاعًا كافيًا مع بقاء الشبكة مدمجة.
                    childAspectRatio: 1.15,
                    children: cards
                        .map((c) => InkWell(
                              borderRadius:
                                  BorderRadius.circular(AppDimens.radiusLg),
                              onTap: c.$5,
                              child: Container(
                                padding: const EdgeInsets.all(AppDimens.md),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius:
                                      BorderRadius.circular(AppDimens.radiusLg),
                                  border:
                                      Border.all(color: AppColors.cardBorder),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(c.$3, color: c.$4),
                                    const Spacer(),
                                    Text('${c.$2}',
                                        style: textTheme.headlineSmall),
                                    Text(c.$1,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: textTheme.bodySmall?.copyWith(
                                            color: AppColors.textMuted)),
                                  ],
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  // المتطلبات 13–16 من المستند 06: نماذج تسعير الوحدات والوجبات.
                  const SizedBox(height: AppDimens.md),
                  Text(AppStrings.t(isArabic, 'service_prices'),
                      style: textTheme.titleMedium),
                  const SizedBox(height: AppDimens.sm),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const HotelUnitPricingScreen())),
                          icon: const Icon(Icons.home_work_outlined, size: 18),
                          label: Text(
                              AppStrings.t(isArabic, 'unit_pricing_title'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      const SizedBox(width: AppDimens.sm),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const HotelMealPricingScreen())),
                          icon: const Icon(Icons.restaurant_outlined, size: 18),
                          label: Text(
                              AppStrings.t(isArabic, 'meal_pricing_title'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
