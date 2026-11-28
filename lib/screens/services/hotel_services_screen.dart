import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_client.dart';
import '../../services/hotel_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';
import '../../utils/service_request_store.dart';
import 'meal_request_screen.dart';
import 'service_request_screen.dart';

/// نتيجة تحميل «طلباتي»: الطلبات المعروفة، وهل الحالة الحيّة متاحة من السيرفر.
class ServiceRequestsView {
  const ServiceRequestsView(this.records, {this.liveUnavailable = false});

  final List<ServiceRequestRecord> records;
  final bool liveUnavailable;
}

class HotelServicesScreen extends ConsumerStatefulWidget {
  const HotelServicesScreen({super.key});

  @override
  ConsumerState<HotelServicesScreen> createState() =>
      _HotelServicesScreenState();
}

class _HotelServicesScreenState extends ConsumerState<HotelServicesScreen> {
  final _service = HotelService();
  late Future<ServiceRequestsView> _requestsFuture;

  @override
  void initState() {
    super.initState();
    _requestsFuture = _loadRequests();
  }

  /// السيرفر هو المرجع حين تُعلن نقطة القراءة. إن غابت (404) أو تعذّر الوصول
  /// نعرض ما حُفظ محليًا من استجابات السيرفر الفعلية، ونقول ذلك صراحة.
  Future<ServiceRequestsView> _loadRequests() async {
    final local = await const ServiceRequestStore().load();
    List<ServiceRequestRecord> remote = const [];
    var liveUnavailable = false;
    try {
      final rows = await _service.myServiceRequests();
      remote = rows.map(ServiceRequestRecord.fromRemoteRow).toList();
    } on ApiException {
      liveUnavailable = true;
    }
    return ServiceRequestsView(
      mergeServiceRequests(local, remote),
      liveUnavailable: liveUnavailable,
    );
  }

  Future<void> _openService(WidgetBuilder builder) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: builder));
    if (!mounted) return;
    setState(() => _requestsFuture = _loadRequests());
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final textTheme = Theme.of(context).textTheme;

    final services = [
      (
        icon: Icons.build_outlined,
        title: AppStrings.t(isArabic, 'maintenance'),
        desc: AppStrings.t(isArabic, 'maintenance_desc'),
        builder: (BuildContext context) => ServiceRequestScreen(
              icon: Icons.build_outlined,
              title: AppStrings.t(isArabic, 'maintenance'),
              description: AppStrings.t(isArabic, 'maintenance_desc'),
              serviceType: 'maintenance',
            ),
      ),
      (
        icon: Icons.cleaning_services_outlined,
        title: AppStrings.t(isArabic, 'housekeeping'),
        desc: AppStrings.t(isArabic, 'housekeeping_desc'),
        builder: (BuildContext context) => ServiceRequestScreen(
              icon: Icons.cleaning_services_outlined,
              title: AppStrings.t(isArabic, 'housekeeping'),
              description: AppStrings.t(isArabic, 'housekeeping_desc'),
              serviceType: 'housekeeping',
            ),
      ),
      (
        icon: Icons.restaurant_outlined,
        title: AppStrings.t(isArabic, 'order_meal'),
        desc: AppStrings.t(isArabic, 'order_meal_desc'),
        builder: (BuildContext context) => const MealRequestScreen(),
      ),
      (
        icon: Icons.event_busy_outlined,
        title: AppStrings.t(isArabic, 'cancellation_request'),
        desc: AppStrings.t(isArabic, 'cancellation_request_desc'),
        builder: (BuildContext context) => ServiceRequestScreen(
              icon: Icons.event_busy_outlined,
              title: AppStrings.t(isArabic, 'cancellation_request'),
              description: AppStrings.t(isArabic, 'cancellation_request_desc'),
              serviceType: 'cancellation',
            ),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(AppStrings.t(isArabic, 'hotel_services')),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppDimens.pagePadding),
          children: [
            for (final service in services) ...[
              InkWell(
                borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                onTap: () => _openService(service.builder),
                child: Container(
                  padding: const EdgeInsets.all(AppDimens.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusMd),
                        ),
                        child: Icon(service.icon,
                            color: AppColors.goldDark, size: 24),
                      ),
                      const SizedBox(width: AppDimens.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(service.title, style: textTheme.titleSmall),
                            const SizedBox(height: 2),
                            Text(
                              service.desc,
                              style: textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.md),
            ],
            const SizedBox(height: AppDimens.sm),
            _MyRequestsSection(
              future: _requestsFuture,
              isArabic: isArabic,
            ),
          ],
        ),
      ),
    );
  }
}

/// المتطلب 59: حالة طلبات الخدمات للضيف.
///
/// تعرض الحالة التي أعادها السيرفر فقط؛ الطلب الذي لم يُعلن السيرفر حالته تظهر
/// أمامه «—» بدل اختلاق «قيد الانتظار».
class _MyRequestsSection extends StatelessWidget {
  const _MyRequestsSection({required this.future, required this.isArabic});

  final Future<ServiceRequestsView> future;
  final bool isArabic;

  String _typeLabel(String type) {
    final key = switch (type) {
      'housekeeping' => 'housekeeping',
      'cancellation' => 'cancellation_request',
      _ => 'maintenance',
    };
    return AppStrings.t(isArabic, key);
  }

  String _statusLabel(String? status) {
    if (status == null || status.isEmpty) {
      return AppStrings.t(isArabic, 'status_unknown');
    }
    final key = 'status_$status';
    final label = AppStrings.t(isArabic, key);
    return label == key ? status : label;
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'done':
      case 'completed':
        return AppColors.success;
      case 'rejected':
      case 'cancelled':
        return AppColors.danger;
      case 'confirmed':
      case 'in_progress':
        return AppColors.goldDark;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return FutureBuilder<ServiceRequestsView>(
      future: future,
      builder: (context, snapshot) {
        final view = snapshot.data;
        final records = view?.records ?? const <ServiceRequestRecord>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.t(isArabic, 'my_service_requests'),
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: AppDimens.sm),
            if (view == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppDimens.md),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (records.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimens.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Text(
                  AppStrings.t(isArabic, 'no_service_requests'),
                  style:
                      textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
              )
            else ...[
              for (final record in records)
                Container(
                  margin: const EdgeInsets.only(bottom: AppDimens.sm),
                  padding: const EdgeInsets.all(AppDimens.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record.id == null
                                  ? _typeLabel(record.type)
                                  : '${_typeLabel(record.type)} · #${record.id}',
                              style: textTheme.titleSmall,
                            ),
                            if (record.roomNumber != null)
                              Text(
                                '${AppStrings.t(isArabic, 'room_number')}: ${record.roomNumber}',
                                style: textTheme.bodySmall
                                    ?.copyWith(color: AppColors.textMuted),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(record.status)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _statusLabel(record.status),
                          style: textTheme.labelSmall?.copyWith(
                              color: _statusColor(record.status),
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              if (view.liveUnavailable)
                Text(
                  AppStrings.t(isArabic, 'service_requests_local_only'),
                  style:
                      textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
            ],
          ],
        );
      },
    );
  }
}
