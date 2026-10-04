import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';
import '../../services/owner_service.dart';

class OwnerNotificationsScreen extends ConsumerStatefulWidget {
  const OwnerNotificationsScreen({super.key});

  @override
  ConsumerState<OwnerNotificationsScreen> createState() => _OwnerNotificationsScreenState();
}

class _OwnerNotificationsScreenState extends ConsumerState<OwnerNotificationsScreen> {
  final _service = OwnerService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getNotifications();
  }

  void _reload() => setState(() => _future = _service.getNotifications());

  IconData _iconFor(String type) {
    switch (type) {
      case 'booking':
        return Icons.calendar_month_outlined;
      case 'maintenance':
        return Icons.build_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(AppStrings.t(isArabic, 'notifications')),
        actions: [
          TextButton(
            onPressed: () async {
              await _service.markAllNotificationsRead();
              _reload();
            },
            child: Text(AppStrings.t(isArabic, 'mark_all_read')),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _reload(),
          child: FutureBuilder<List<Map<String, dynamic>>>(
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

              final notifications = snapshot.data ?? [];
              if (notifications.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppDimens.xl),
                      child: Center(child: Text(AppStrings.t(isArabic, 'no_notifications'))),
                    ),
                  ],
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(AppDimens.pagePadding),
                itemCount: notifications.length,
                separatorBuilder: (context, index) => const SizedBox(height: AppDimens.sm),
                itemBuilder: (context, index) {
                  final n = notifications[index];
                  final isRead = n['is_read'] == 1 || n['is_read'] == true;
                  final title = isArabic ? (n['title_ar'] ?? '') : (n['title_en'] ?? n['title_ar'] ?? '');
                  return Container(
                    padding: const EdgeInsets.all(AppDimens.md),
                    decoration: BoxDecoration(
                      color: isRead ? AppColors.surface : AppColors.gold.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.gold.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                          ),
                          child: Icon(_iconFor((n['type'] ?? 'general').toString()), color: AppColors.goldDark, size: 20),
                        ),
                        const SizedBox(width: AppDimens.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title.toString(), style: textTheme.bodyMedium),
                              const SizedBox(height: 2),
                              Text((n['created_at'] ?? '').toString(),
                                  style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
