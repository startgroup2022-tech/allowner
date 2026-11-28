import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api_client.dart';
import '../../services/hotel_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';
import '../../utils/session_provider.dart';
import '../home/main_navigation_screen.dart';
import '../shared/help_support_screen.dart';

/// حذف الحساب من داخل التطبيق (سياسة Google Play لطلب حذف الحساب).
///
/// الحذف يُنفَّذ على السيرفر عبر `POST /user/delete-account.php`؛ لا يُمسح أي
/// شيء محليًا قبل ردّ النجاح. إن كان المسار غير مُنفَّذ (404) تُعرض حالة
/// «غير مُفعَّلة» مع مسار بديل (الموقع/الدعم) ولا يُدَّعى نجاح وهمي.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  /// صفحة طلب الحذف على الموقع — تُستخدم لمن لا يستطيع فتح التطبيق.
  static const String webDeletionUrl =
      'https://all-owner.online/delete-account';

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _wordCtrl = TextEditingController();
  final _service = HotelService();

  bool _acknowledged = false;
  String? _reason;
  bool _submitting = false;
  bool _deleted = false;
  String? _error;
  bool _unavailable = false;
  int _upcomingBookings = 0;
  bool _checkingBookings = true;

  @override
  void initState() {
    super.initState();
    _loadUpcomingBookings();
  }

  @override
  void dispose() {
    _wordCtrl.dispose();
    super.dispose();
  }

  /// الحجوزات القادمة تمنع الحذف: لا يصح إغلاق حساب له إقامة لم تنتهِ.
  /// أي فشل في الجلب لا يمنع الحذف — يبقى التحقق النهائي على السيرفر.
  Future<void> _loadUpcomingBookings() async {
    try {
      final bookings = await _service.myBookings();
      final now = DateTime.now();
      final active = bookings.where((b) {
        final status = b['status']?.toString() ?? '';
        if (!['pending', 'confirmed', 'checked_in'].contains(status)) {
          return false;
        }
        final out = DateTime.tryParse(b['check_out']?.toString() ?? '');
        return out == null ||
            !out.isBefore(DateTime(now.year, now.month, now.day));
      }).length;
      if (mounted) setState(() => _upcomingBookings = active);
    } catch (_) {
      if (mounted) setState(() => _upcomingBookings = 0);
    } finally {
      if (mounted) setState(() => _checkingBookings = false);
    }
  }

  bool _wordMatches(bool isArabic) =>
      _wordCtrl.text.trim() == AppStrings.t(isArabic, 'delete_account_word');

  Future<void> _submit(bool isArabic) async {
    if (!_acknowledged) {
      setState(
          () => _error = AppStrings.t(isArabic, 'delete_account_need_ack'));
      return;
    }
    if (!_wordMatches(isArabic)) {
      setState(
          () => _error = AppStrings.t(isArabic, 'delete_account_need_word'));
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
      _unavailable = false;
    });
    try {
      await ref.read(sessionProvider.notifier).deleteAccount(reason: _reason);
      if (mounted) setState(() => _deleted = true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.kind == ApiErrorKind.notFound) {
          _unavailable = true;
          _error = AppStrings.t(isArabic, 'delete_account_unavailable');
        } else {
          _error = e.message.isEmpty
              ? AppStrings.t(isArabic, 'delete_account_failed')
              : e.message;
        }
      });
    } catch (_) {
      if (mounted) {
        setState(
            () => _error = AppStrings.t(isArabic, 'delete_account_failed'));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _openWebDeletion(bool isArabic) async {
    final ok = await launchUrl(
      Uri.parse(DeleteAccountScreen.webDeletionUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppStrings.t(isArabic, 'delete_account_web_failed'))),
      );
    }
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      (route) => false,
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
        title: Text(AppStrings.t(isArabic, 'delete_account')),
      ),
      body: SafeArea(
        child: _deleted
            ? _doneView(isArabic, textTheme)
            : ListView(
                padding: const EdgeInsets.all(AppDimens.pagePadding),
                children: [
                  _warningCard(isArabic, textTheme),
                  const SizedBox(height: AppDimens.md),
                  _infoCard(isArabic, textTheme),
                  if (_upcomingBookings > 0) ...[
                    const SizedBox(height: AppDimens.md),
                    _notice(
                      icon: Icons.event_busy_rounded,
                      color: AppColors.danger,
                      text: AppStrings.t(
                          isArabic, 'delete_account_bookings_warning'),
                      textTheme: textTheme,
                    ),
                  ],
                  const SizedBox(height: AppDimens.lg),
                  Text(
                    AppStrings.t(isArabic, 'delete_account_reason'),
                    style: textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppDimens.sm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final key in const [
                        'delete_account_reason_no_longer',
                        'delete_account_reason_privacy',
                        'delete_account_reason_other',
                      ])
                        ChoiceChip(
                          label: Text(AppStrings.t(isArabic, key)),
                          selected: _reason == key,
                          onSelected: (v) =>
                              setState(() => _reason = v ? key : null),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.lg),
                  CheckboxListTile(
                    value: _acknowledged,
                    onChanged: (v) =>
                        setState(() => _acknowledged = v ?? false),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(
                      AppStrings.t(isArabic, 'delete_account_ack'),
                      style: textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: AppDimens.sm),
                  TextField(
                    controller: _wordCtrl,
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText:
                          AppStrings.t(isArabic, 'delete_account_type_confirm'),
                      prefixIcon: const Icon(Icons.keyboard_rounded),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppDimens.md),
                    _notice(
                      icon: _unavailable
                          ? Icons.info_outline_rounded
                          : Icons.error_outline_rounded,
                      color:
                          _unavailable ? AppColors.warning : AppColors.danger,
                      text: _error!,
                      textTheme: textTheme,
                    ),
                  ],
                  const SizedBox(height: AppDimens.lg),
                  SizedBox(
                    height: AppDimens.buttonHeight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _submitting ||
                              _checkingBookings ||
                              _upcomingBookings > 0 ||
                              !_acknowledged ||
                              !_wordMatches(isArabic)
                          ? null
                          : () => _submit(isArabic),
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              AppStrings.t(isArabic, 'delete_account_submit')),
                    ),
                  ),
                  const SizedBox(height: AppDimens.md),
                  OutlinedButton.icon(
                    onPressed: () => _openWebDeletion(isArabic),
                    icon: const Icon(Icons.public_rounded, size: 18),
                    label: Text(AppStrings.t(isArabic, 'delete_account_web')),
                  ),
                  const SizedBox(height: AppDimens.sm),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const HelpSupportScreen()),
                    ),
                    icon: const Icon(Icons.support_agent_rounded, size: 18),
                    label: Text(AppStrings.t(isArabic, 'contact_support')),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _warningCard(bool isArabic, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.md),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.danger, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppStrings.t(isArabic, 'delete_account_intro'),
              style: textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textPrimary, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(bool isArabic, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bullet(
              Icons.delete_outline_rounded,
              AppColors.danger,
              AppStrings.t(isArabic, 'delete_account_what_is_deleted'),
              textTheme),
          const SizedBox(height: 10),
          _bullet(Icons.inventory_2_outlined, AppColors.textSecondary,
              AppStrings.t(isArabic, 'delete_account_what_is_kept'), textTheme),
        ],
      ),
    );
  }

  Widget _bullet(IconData icon, Color color, String text, TextTheme textTheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary, height: 1.5)),
        ),
      ],
    );
  }

  Widget _notice({
    required IconData icon,
    required Color color,
    required String text,
    required TextTheme textTheme,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary, height: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _doneView(bool isArabic, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.pagePadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded,
              size: 72, color: AppColors.success),
          const SizedBox(height: AppDimens.lg),
          Text(AppStrings.t(isArabic, 'delete_account_done_title'),
              style: textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: AppDimens.sm),
          Text(
            AppStrings.t(isArabic, 'delete_account_done_body'),
            style: textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary, height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimens.xl),
          SizedBox(
            width: double.infinity,
            height: AppDimens.buttonHeight,
            child: ElevatedButton(
              onPressed: _goHome,
              child: Text(AppStrings.t(isArabic, 'home')),
            ),
          ),
        ],
      ),
    );
  }
}
