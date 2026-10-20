import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';
import '../../utils/subscription.dart';
import '../../utils/payment_security.dart';
import '../../utils/safe_parse.dart';
import '../../utils/session_provider.dart';
import '../../services/owner_service.dart';
import '../../services/api_client.dart';
import '../../widgets/state_views.dart';

/// صفحة الاشتراك السنوي للمالك (المتطلبات 121–125).
///
///   • 121: الاشتراك سنوي وللمالك فقط.
///   • 122: المالك غير المشترك يستعرض دون عمليات.
///   • 123: منع إضافة الوحدات والطلبات حتى الاشتراك.
///   • 124: صفحة تفعيل/دفع الاشتراك في «حسابي».
///   • 125: عرض شروط الاشتراك ونسبة العمولة.
///
/// لا يوجد endpoint للاشتراك ولا لدفع الاشتراك؛ نقرأ الإعلان من
/// `content/settings.php`. إن لم تُعلن الحالة تظهر «غير معلنة» ويبقى المالك في
/// وضع الاستعراض فقط، ولا نُخترع مبلغًا ولا نُفعّل اشتراكًا وهميًا.
class OwnerSubscriptionScreen extends ConsumerStatefulWidget {
  const OwnerSubscriptionScreen({super.key});

  @override
  ConsumerState<OwnerSubscriptionScreen> createState() =>
      _OwnerSubscriptionScreenState();
}

class _OwnerSubscriptionScreenState
    extends ConsumerState<OwnerSubscriptionScreen> {
  final _service = OwnerService();
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getSubscription();
  }

  void _reload() => setState(() => _future = _service.getSubscription());

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(AppStrings.t(isArabic, 'subscription_title')),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _reload(),
          child: FutureBuilder<Map<String, dynamic>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingView(height: 200);
              }
              if (snapshot.hasError) {
                final err = snapshot.error;
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppDimens.xl),
                  children: [
                    ErrorView(
                      message: err is ApiException
                          ? err.message
                          : AppStrings.t(isArabic, 'error_loading'),
                      isArabic: isArabic,
                      onRetry: _reload,
                    ),
                  ],
                );
              }

              final settings = asMap(snapshot.data);
              final state = SubscriptionState.fromMap(settings);
              final statusKey = subscriptionStatusKey(state);

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppDimens.pagePadding),
                children: [
                  _statusCard(isArabic, textTheme, state, statusKey),
                  const SizedBox(height: AppDimens.lg),
                  _facts(isArabic, textTheme, state),
                  const SizedBox(height: AppDimens.lg),
                  _terms(isArabic, textTheme),
                  const SizedBox(height: AppDimens.xl),
                  _payButton(isArabic, state, settings),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _statusCard(bool isArabic, TextTheme textTheme,
      SubscriptionState state, String statusKey) {
    final active = state.active == true;
    final color = state.active == null
        ? AppColors.warning
        : (active ? AppColors.success : AppColors.danger);
    return Container(
      padding: const EdgeInsets.all(AppDimens.lg),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(
            state.active == null
                ? Icons.help_outline_rounded
                : (active ? Icons.verified_rounded : Icons.gpp_maybe_outlined),
            color: color,
          ),
          const SizedBox(width: AppDimens.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.t(isArabic, statusKey),
                    style: textTheme.titleMedium?.copyWith(color: color)),
                if (state.isBrowseOnly) ...[
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.t(isArabic, 'subscription_browse_only'),
                    style: textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _facts(bool isArabic, TextTheme textTheme, SubscriptionState state) {
    Widget row(String labelKey, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppStrings.t(isArabic, labelKey),
                  style: textTheme.bodyMedium),
              Flexible(
                child: Text(value,
                    textAlign: TextAlign.end,
                    style: textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );

    final fee = state.annualFee == null
        ? AppStrings.t(isArabic, 'subscription_fee_unknown')
        : '${state.annualFee!.toStringAsFixed(0)} ${state.currency}';
    final percent = state.commissionPercent == null
        ? AppStrings.t(isArabic, 'commission_percent_unknown')
        : '${state.commissionPercent!.toStringAsFixed(0)}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row('subscription_fee', fee),
        row('commission_percent_label', percent),
        if (state.expiresAt != null)
          row('subscription_expires_at', state.expiresAt!),
      ],
    );
  }

  Widget _terms(bool isArabic, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined,
                  size: 16, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(AppStrings.t(isArabic, 'subscription_terms'),
                  style: textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: AppDimens.sm),
          Text(
            AppStrings.t(isArabic, 'subscription_terms_body'),
            style:
                textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  /// المتطلب 124: يُفعَّل زر الدفع فقط عندما تُعلن الإدارة **معًا** رسمًا
  /// معروفًا ورابط صفحة دفع مستضافة صالحًا (https). أي نقص يُبقي الزر معطّلًا
  /// مع سبب صريح — لا زر يوهم بالدفع ولا مبلغ مُخترع.
  Widget _payButton(
      bool isArabic, SubscriptionState state, Map<String, dynamic> settings) {
    final checkout = resolveSubscriptionCheckout(settings);
    final feeKnown = canPaySubscription(state);
    final canPay = feeKnown && checkout != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: AppDimens.buttonHeight,
          child: ElevatedButton(
            onPressed: canPay ? () => _openCheckout(isArabic, checkout) : null,
            child: Text(AppStrings.t(isArabic, 'activate_subscription')),
          ),
        ),
        const SizedBox(height: AppDimens.sm),
        Text(
          canPay
              ? AppStrings.t(isArabic, 'subscription_checkout_ready')
              : (feeKnown
                  ? AppStrings.t(isArabic, 'subscription_checkout_not_declared')
                  : AppStrings.t(isArabic, 'subscription_fee_unknown')),
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }

  /// يفتح صفحة الدفع المستضافة عند المزوّد ويُمرّر معرّف المالك فقط.
  Future<void> _openCheckout(
      bool isArabic, HostedCheckoutConfig checkout) async {
    final ownerId = ref.read(sessionProvider).user?.id;
    if (ownerId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.t(isArabic, 'session_expired'))));
      }
      return;
    }
    final uri = buildSubscriptionCheckoutUri(checkout, ownerId: ownerId);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.t(isArabic, 'error_loading'))));
      }
    }
  }
}
