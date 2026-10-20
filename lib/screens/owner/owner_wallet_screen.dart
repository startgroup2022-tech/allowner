import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';
import '../../utils/owner_wallet.dart';
import '../../utils/safe_parse.dart';
import '../../services/api_client.dart';
import '../../services/owner_service.dart';
import '../../widgets/state_views.dart';

/// محفظة المالك: الرصيد والعمولة والمصروفات والقابل للتحويل وكشف الحساب
/// (المتطلبات 132–143).
///
/// لا يوجد endpoint للمحفظة على السيرفر بعد، لذلك تعرض الشاشة حالتين صادقتين:
///   • إن أعاد السيرفر أرقامًا حقيقية (عند تفعيل `/user/owner-wallet.php`)
///     تُعرض كما هي مع كشف الحساب.
///   • إن أعاد 404 تظهر حالة «المحفظة غير مُفعَّلة على السيرفر بعد» مع إعادة
///     المحاولة — ولا تُعرض أصفار مضلِّلة ولا رصيد مُخترع.
class OwnerWalletScreen extends ConsumerStatefulWidget {
  const OwnerWalletScreen({super.key});

  @override
  ConsumerState<OwnerWalletScreen> createState() => _OwnerWalletScreenState();
}

class _OwnerWalletScreenState extends ConsumerState<OwnerWalletScreen> {
  final _service = OwnerService();
  late Future<Map<String, dynamic>> _future;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _future = _service.getOwnerWallet();
  }

  void _reload() => setState(() => _future = _service.getOwnerWallet());

  Future<void> _openTransferSheet(bool isArabic, WalletBalance balance) async {
    final ctrl = TextEditingController(
      text: balance.computedWithdrawable?.toStringAsFixed(0) ?? '',
    );
    String? error;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppDimens.radiusXl)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: AppDimens.pagePadding,
            right: AppDimens.pagePadding,
            top: AppDimens.lg,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppDimens.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.t(isArabic, 'request_transfer'),
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: AppDimens.sm),
              Text(
                AppStrings.t(isArabic, 'transfer_requires_server'),
                style: Theme.of(ctx)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: AppDimens.md),
              TextField(
                controller: ctrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: AppStrings.t(isArabic, 'transfer_amount'),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: AppDimens.sm),
                Text(error!,
                    style:
                        const TextStyle(color: AppColors.danger, fontSize: 12)),
              ],
              const SizedBox(height: AppDimens.lg),
              SizedBox(
                width: double.infinity,
                height: AppDimens.buttonHeight,
                child: ElevatedButton(
                  onPressed: _submitting
                      ? null
                      : () async {
                          final amount = double.tryParse(ctrl.text.trim());
                          if (!isValidTransferAmount(amount, balance)) {
                            setSheet(() => error = AppStrings.t(
                                isArabic, 'transfer_invalid_amount'));
                            return;
                          }
                          setSheet(() {
                            error = null;
                            _submitting = true;
                          });
                          try {
                            await _service.requestTransfer(
                              buildTransferRequestPayload(amount: amount!),
                            );
                            if (ctx.mounted) Navigator.of(ctx).pop();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(AppStrings.t(
                                        isArabic, 'transfer_requested'))),
                              );
                            }
                          } on ApiException catch (e) {
                            setSheet(() {
                              _submitting = false;
                              error = e.message;
                            });
                          }
                        },
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(AppStrings.t(isArabic, 'request_transfer')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
        title: Text(AppStrings.t(isArabic, 'wallet_title')),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _reload(),
          child: FutureBuilder<Map<String, dynamic>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingView(height: 240);
              }

              if (snapshot.hasError) {
                final err = snapshot.error;
                final notFound =
                    err is ApiException && err.kind == ApiErrorKind.notFound;
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppDimens.xl),
                  children: [
                    EmptyView(
                      icon: notFound
                          ? Icons.account_balance_wallet_outlined
                          : Icons.cloud_off_rounded,
                      message: notFound
                          ? AppStrings.t(isArabic, 'wallet_unavailable')
                          : (err is ApiException
                              ? err.message
                              : AppStrings.t(isArabic, 'error_loading')),
                      actionLabel: AppStrings.t(isArabic, 'retry'),
                      onAction: _reload,
                    ),
                  ],
                );
              }

              final balance = WalletBalance.fromMap(asMap(snapshot.data));
              final ledger = asMapList(snapshot.data?['ledger'])
                  .map(WalletLedgerEntry.fromMap)
                  .toList();

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppDimens.pagePadding),
                children: [
                  if (!balance.hasAnyValue)
                    EmptyView(
                      icon: Icons.account_balance_wallet_outlined,
                      message: AppStrings.t(isArabic, 'wallet_unavailable'),
                      actionLabel: AppStrings.t(isArabic, 'retry'),
                      onAction: _reload,
                    )
                  else ...[
                    _balanceCard(isArabic, textTheme, balance),
                    const SizedBox(height: AppDimens.lg),
                    if (balance.canRequestTransfer)
                      SizedBox(
                        height: AppDimens.buttonHeight,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _openTransferSheet(isArabic, balance),
                          icon: const Icon(Icons.swap_horiz_rounded),
                          label:
                              Text(AppStrings.t(isArabic, 'request_transfer')),
                        ),
                      ),
                    const SizedBox(height: AppDimens.md),
                    _notes(isArabic, textTheme),
                    const SizedBox(height: AppDimens.xl),
                    Text(AppStrings.t(isArabic, 'wallet_ledger'),
                        style: textTheme.titleMedium),
                    const SizedBox(height: AppDimens.md),
                    if (ledger.isEmpty)
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: AppDimens.md),
                        child: Text(
                          AppStrings.t(isArabic, 'wallet_no_ledger'),
                          style: textTheme.bodySmall
                              ?.copyWith(color: AppColors.textMuted),
                        ),
                      )
                    else
                      ...ledger.map((e) => _ledgerRow(isArabic, textTheme, e)),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _balanceCard(
      bool isArabic, TextTheme textTheme, WalletBalance balance) {
    Widget row(String labelKey, double? value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(AppStrings.t(isArabic, labelKey),
                    style: textTheme.bodyMedium),
              ),
              const SizedBox(width: AppDimens.sm),
              Flexible(
                child: Text(
                  value == null
                      ? AppStrings.t(isArabic, 'no_data')
                      : '${value.toStringAsFixed(0)} ${AppStrings.t(isArabic, 'sar')}',
                  textAlign: TextAlign.end,
                  style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: value == null
                          ? AppColors.textMuted
                          : AppColors.textPrimary),
                ),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(AppDimens.lg),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          row('wallet_balance', balance.total),
          row('wallet_commission', balance.commission),
          row('wallet_expenses', balance.expenses),
          row('wallet_reserved', balance.reserved),
          const Divider(height: AppDimens.lg),
          Row(
            children: [
              Expanded(
                child: Text(AppStrings.t(isArabic, 'wallet_withdrawable'),
                    style: textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: AppDimens.sm),
              Flexible(
                child: Text(
                  '${(balance.computedWithdrawable ?? 0).toStringAsFixed(0)} ${AppStrings.t(isArabic, 'sar')}',
                  textAlign: TextAlign.end,
                  style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.goldDark, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _notes(bool isArabic, TextTheme textTheme) {
    const keys = [
      'commission_rate_note',
      'settlement_after_stay',
      'payout_weekly_note',
      'transfer_requires_server',
    ];
    return Container(
      padding: const EdgeInsets.all(AppDimens.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final k in keys)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 15, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      AppStrings.t(isArabic, k),
                      style: textTheme.bodySmall
                          ?.copyWith(color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _ledgerRow(
      bool isArabic, TextTheme textTheme, WalletLedgerEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.sm),
      padding: const EdgeInsets.all(AppDimens.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.t(isArabic, entry.typeKey),
                    style: textTheme.bodyMedium),
                if (entry.date != null)
                  Text(entry.date!,
                      style: textTheme.bodySmall
                          ?.copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          Flexible(
            child: Text(
              '${entry.amount.toStringAsFixed(0)} ${AppStrings.t(isArabic, 'sar')}',
              textAlign: TextAlign.end,
              style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color:
                      entry.amount < 0 ? AppColors.danger : AppColors.goldDark),
            ),
          ),
        ],
      ),
    );
  }
}
