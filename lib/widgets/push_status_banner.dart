import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../utils/app_strings.dart';

/// شريط حالة إشعارات الجهاز.
///
/// يعرض آخر نتيجة تسجيل رمز فعليًا (من [NotificationService.register]) ويسمح
/// بإعادة المحاولة. لا يدّعي التفعيل إن لم يُسجّل الرمز على الخادم: سبب الفشل
/// يظهر كما أعاده المزوّد أو الخادم.
class PushStatusBanner extends StatefulWidget {
  const PushStatusBanner({
    super.key,
    required this.isArabic,
    this.service,
    this.initialReason,
  });

  final bool isArabic;
  final NotificationService? service;

  /// آخر سبب معروف من الجلسة (مثل `push_provider_not_configured`).
  final String? initialReason;

  @override
  State<PushStatusBanner> createState() => _PushStatusBannerState();
}

class _PushStatusBannerState extends State<PushStatusBanner> {
  late String? _reason = widget.initialReason;
  bool _busy = false;

  late final NotificationService _service =
      widget.service ?? NotificationService();

  bool get _registered => _reason == null && _requested;

  bool _requested = false;

  Future<void> _enable() async {
    setState(() => _busy = true);
    PushRegistrationResult result;
    try {
      result = await _service.register(locale: widget.isArabic ? 'ar' : 'en');
    } catch (_) {
      result = const PushRegistrationResult(
          registered: false, reason: 'push_register_failed');
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _requested = true;
      _reason = result.registered ? null : result.reason;
    });
  }

  String _message() {
    if (_registered) {
      return AppStrings.t(widget.isArabic, 'push_enabled_on_device');
    }
    if (!_requested && _reason == null) {
      return AppStrings.t(widget.isArabic, 'push_not_requested');
    }
    final reason = _reason ?? '';
    if (reason == 'push_provider_not_configured') {
      return AppStrings.t(widget.isArabic, 'push_not_configured');
    }
    if (reason.startsWith('permission_')) {
      return AppStrings.t(widget.isArabic, 'push_permission_denied');
    }
    if (reason == 'no_device_token') {
      return AppStrings.t(widget.isArabic, 'push_no_token');
    }
    final base = AppStrings.t(widget.isArabic, 'push_register_failed');
    return reason.isEmpty ? base : '$base ($reason)';
  }

  Color get _tint {
    if (_registered) return AppColors.success;
    if (!_requested && _reason == null) return AppColors.textSecondary;
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppDimens.pagePadding, AppDimens.md, AppDimens.pagePadding, 0),
      padding: const EdgeInsets.all(AppDimens.md),
      decoration: BoxDecoration(
        color: _tint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: _tint.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _registered
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_off_outlined,
                size: 18,
                color: _tint,
              ),
              const SizedBox(width: 8),
              Text(AppStrings.t(widget.isArabic, 'push_status_title'),
                  style: textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _message(),
            style: textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary, height: 1.5),
          ),
          if (!_registered) ...[
            const SizedBox(height: 4),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: _busy ? null : _enable,
                child: _busy
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        AppStrings.t(widget.isArabic,
                            _requested ? 'push_retry' : 'push_enable'),
                        style: const TextStyle(fontSize: 12),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
