import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';
import '../../utils/session_provider.dart';
import '../../services/owner_service.dart';
import '../../utils/role_menus.dart';
import '../../utils/role_permissions.dart';
import '../../utils/safe_parse.dart';
import 'owner_bookings_screen.dart';
import 'owner_maintenance_screen.dart';
import 'owner_revenue_screen.dart';
import 'owner_documents_screen.dart';
import 'owner_decisions_screen.dart';
import 'owner_community_screen.dart';
import 'owner_marketplace_screen.dart';
import 'owner_messages_screen.dart';
import 'owner_meal_requests_screen.dart';
import 'owner_cleaning_screen.dart';
import 'owner_extra_bed_screen.dart';
import 'owner_clients_screen.dart';
import 'owner_commission_screen.dart';
import 'owner_bank_screen.dart';
import 'owner_service_prices_screen.dart';
import 'owner_wallet_screen.dart';
import 'owner_subscription_screen.dart';
import '../search/search_screen.dart';

class OwnerHomeScreen extends ConsumerStatefulWidget {
  const OwnerHomeScreen({super.key});

  @override
  ConsumerState<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends ConsumerState<OwnerHomeScreen> {
  final _service = OwnerService();
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadStats();
  }

  bool get _isAgent => ref.read(sessionProvider).user?.role == 'booking_agent';

  // الوكيل يشوف أرقامه هو (حجوزاته وعمولاته)، والمالك يشوف أرقام وحداته
  Future<Map<String, dynamic>> _loadStats() =>
      _isAgent ? _service.getMyCommission() : _service.getDashboard();

  void _reload() => setState(() {
        _future = _loadStats();
      });

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final textTheme = Theme.of(context).textTheme;
    final user = ref.watch(sessionProvider).user;

    // القوائم معرّفة كبيانات نقية في `utils/role_menus.dart` (المتطلبات
    // 100–107) حتى يمكن اختبار ترتيبها ووجود عناصرها. هنا نربط كل وجهة بشاشتها.
    void open(MenuTarget target) {
      Widget screen;
      switch (target) {
        case MenuTarget.ownerClients:
          screen = const OwnerClientsScreen();
        case MenuTarget.newBooking:
          screen = const SearchScreen(initialQuery: '');
        case MenuTarget.ownerBookings:
          screen = const OwnerBookingsScreen();
        case MenuTarget.commission:
          screen = const OwnerCommissionScreen();
        case MenuTarget.messages:
          screen = const OwnerMessagesScreen();
        case MenuTarget.mealRequests:
          screen = const OwnerMealRequestsScreen();
        case MenuTarget.cleaningRequests:
          screen = const OwnerCleaningScreen();
        case MenuTarget.extraBedRequests:
          screen = const OwnerExtraBedScreen();
        case MenuTarget.maintenance:
          screen = const OwnerMaintenanceScreen();
        case MenuTarget.revenueReports:
          screen = const OwnerRevenueScreen();
        case MenuTarget.servicePrices:
          screen = const OwnerServicePricesScreen();
        case MenuTarget.bankAccount:
          screen = const OwnerBankScreen();
        case MenuTarget.contracts:
          screen = const OwnerDocumentsScreen();
        case MenuTarget.voting:
          screen = const OwnerDecisionsScreen();
        case MenuTarget.community:
          screen = const OwnerCommunityScreen();
        case MenuTarget.marketplace:
          screen = const OwnerMarketplaceScreen();
        case MenuTarget.wallet:
          screen = const OwnerWalletScreen();
        case MenuTarget.subscription:
          screen = const OwnerSubscriptionScreen();
      }
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    }

    // القائمة تأتي من طبقة الصلاحيات (المتطلب 74): موظف الوحدة لا يرى المحفظة
    // ولا الإيرادات ولا الحساب البنكي — الوجهة الممنوعة لا تظهر أصلًا.
    final links = RolePermissions(user?.role).menu;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _reload(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppDimens.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.t(isArabic, 'hello'),
                    style: textTheme.bodyMedium
                        ?.copyWith(color: AppColors.textSecondary)),
                Text(user?.fullName ?? '', style: textTheme.headlineMedium),
                const SizedBox(height: AppDimens.lg),
                FutureBuilder<Map<String, dynamic>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppDimens.xl),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasError) {
                      return _ErrorRetry(isArabic: isArabic, onRetry: _reload);
                    }
                    final stats = snapshot.data ?? {};
                    if (user?.role == 'booking_agent') {
                      String sar(dynamic v) =>
                          '${asDouble(v).toStringAsFixed(0)} ${AppStrings.t(isArabic, 'sar')}';
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _MetricCard(
                                  icon: Icons.calendar_month_rounded,
                                  label:
                                      AppStrings.t(isArabic, 'owner_bookings'),
                                  value:
                                      asInt(stats['total_bookings']).toString(),
                                ),
                              ),
                              const SizedBox(width: AppDimens.md),
                              Expanded(
                                child: _MetricCard(
                                  icon: Icons.account_balance_wallet_rounded,
                                  label: AppStrings.t(
                                      isArabic, 'total_commission'),
                                  value: sar(stats['total_commission']),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimens.md),
                          Row(
                            children: [
                              Expanded(
                                child: _MetricCard(
                                  icon: Icons.check_circle_outline_rounded,
                                  label:
                                      AppStrings.t(isArabic, 'commission_paid'),
                                  value: sar(stats['paid']),
                                ),
                              ),
                              const SizedBox(width: AppDimens.md),
                              Expanded(
                                child: _MetricCard(
                                  icon: Icons.hourglass_top_rounded,
                                  label: AppStrings.t(
                                      isArabic, 'commission_remaining'),
                                  value: sar(stats['unpaid']),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }
                    final units = asInt(stats['units_count']).toString();
                    // السيرفر يعيد `revenue` كنص رقمي أحيانًا، و`is num` كان
                    // يُظهر الصفر دائمًا في تلك الحالة.
                    final revenue =
                        asDouble(stats['revenue']).toStringAsFixed(0);
                    final pending = asInt(stats['pending_bookings']).toString();

                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                icon: Icons.apartment_rounded,
                                label: AppStrings.t(isArabic, 'nav_units'),
                                value: units,
                              ),
                            ),
                            const SizedBox(width: AppDimens.md),
                            Expanded(
                              child: _MetricCard(
                                icon: Icons.account_balance_wallet_rounded,
                                label: AppStrings.t(isArabic, 'nav_revenue'),
                                value:
                                    '$revenue ${AppStrings.t(isArabic, 'sar')}',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimens.md),
                        Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                icon: Icons.hourglass_top_rounded,
                                label:
                                    AppStrings.t(isArabic, 'pending_bookings'),
                                value: pending,
                              ),
                            ),
                            const SizedBox(width: AppDimens.md),
                            Expanded(
                              child: _MetricCard(
                                icon: Icons.calendar_month_rounded,
                                label: AppStrings.t(isArabic, 'owner_bookings'),
                                value:
                                    (stats['bookings_count'] ?? 0).toString(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppDimens.xl),
                Text(AppStrings.t(isArabic, 'quick_links'),
                    style: textTheme.titleMedium),
                const SizedBox(height: AppDimens.md),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppDimens.md,
                  crossAxisSpacing: AppDimens.md,
                  childAspectRatio: 1.5,
                  children: links.map((link) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                      onTap: () => open(link.target),
                      child: Container(
                        padding: const EdgeInsets.all(AppDimens.md),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusLg),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(link.icon,
                                color: AppColors.goldDark, size: 24),
                            Text(
                              AppStrings.t(isArabic, link.labelKey),
                              style: textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricCard(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.goldDark, size: 22),
          const SizedBox(height: AppDimens.sm),
          Text(value,
              style: Theme.of(context).textTheme.titleMedium,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final bool isArabic;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.isArabic, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.lg),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 32),
          const SizedBox(height: AppDimens.sm),
          Text(AppStrings.t(isArabic, 'error_loading'),
              textAlign: TextAlign.center),
          const SizedBox(height: AppDimens.sm),
          OutlinedButton(
              onPressed: onRetry, child: Text(AppStrings.t(isArabic, 'retry'))),
        ],
      ),
    );
  }
}
