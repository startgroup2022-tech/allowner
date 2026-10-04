import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';
import '../../services/hotel_staff_service.dart';
import '../../services/api_client.dart';

class HotelDashboardScreen extends ConsumerStatefulWidget {
  const HotelDashboardScreen({super.key});

  @override
  ConsumerState<HotelDashboardScreen> createState() => _HotelDashboardScreenState();
}

class _HotelDashboardScreenState extends ConsumerState<HotelDashboardScreen> {
  final _service = HotelStaffService();
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getDashboard();
  }

  void _reload() => setState(() => _future = _service.getDashboard());

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
                    Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 32),
                    const SizedBox(height: AppDimens.sm),
                    Text(AppStrings.t(isArabic, 'error_loading'), textAlign: TextAlign.center),
                    const SizedBox(height: AppDimens.sm),
                    Center(child: OutlinedButton(onPressed: _reload, child: Text(AppStrings.t(isArabic, 'retry')))),
                  ],
                );
              }

              final data = snapshot.data ?? {};
              final hotels = (data['hotels'] as List?) ?? [];
              final pending = (data['pending'] as Map?) ?? {};
              final openRequests = ((pending['cleaning'] ?? 0) as num) +
                  ((pending['extra_bed'] ?? 0) as num) +
                  ((pending['maintenance'] ?? 0) as num) +
                  ((pending['meal'] ?? 0) as num);
              final cards = <(String, dynamic, IconData, Color)>[
                (AppStrings.t(isArabic, 'arrivals_today'), data['arrivals_today'] ?? 0, Icons.login_rounded, AppColors.success),
                (AppStrings.t(isArabic, 'departures_today'), data['departures_today'] ?? 0, Icons.logout_rounded, AppColors.secondary),
                (AppStrings.t(isArabic, 'in_house_now'), data['in_house'] ?? 0, Icons.event_available_rounded, AppColors.ink),
                (AppStrings.t(isArabic, 'open_requests'), openRequests, Icons.pending_actions_rounded, AppColors.warning),
              ];

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppDimens.pagePadding),
                children: [
                  if (hotels.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppDimens.md),
                      child: Text(hotels.map((h) => h['name']).join(' • '), style: textTheme.titleMedium),
                    ),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: AppDimens.md,
                    mainAxisSpacing: AppDimens.md,
                    childAspectRatio: 1.3,
                    children: cards
                        .map((c) => Container(
                              padding: const EdgeInsets.all(AppDimens.md),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(c.$3, color: c.$4),
                                  const Spacer(),
                                  Text('${c.$2}', style: textTheme.headlineSmall),
                                  Text(c.$1, style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                                ],
                              ),
                            ))
                        .toList(),
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
