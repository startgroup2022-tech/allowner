import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../shared/help_support_screen.dart';

/// استعادة كلمة المرور (المتطلب 110).
///
/// الخدمة **غير مُنفَّذة على السيرفر**: كل مسارات `auth/forgot*` و
/// `auth/reset-password.php` تُرجع 404 (تم التحقق بالفحص المباشر). لذلك بدل
/// زر لا يعمل:
///   • تُعرض الشاشة بالحقول والتحقق من صحة البريد.
///   • يُخبَر المستخدم صراحةً أن الخدمة غير مُفعَّلة على السيرفر.
///   • يُتاح مسار الدعم الحقيقي (`HelpSupportScreen` يقرأ قنوات الاتصال من
///     `content/settings.php`).
///
/// إذا أُضيف الـ endpoint لاحقًا، تُستدعى `AuthService.requestPasswordReset`
/// تلقائيًا ويظهر نجاح حقيقي فقط عند رد السيرفر بنجاح.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _service = AuthService();
  bool _sending = false;
  String? _status;
  bool _unavailable = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(bool isArabic) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _sending = true;
      _status = null;
      _unavailable = false;
    });
    try {
      await _service.requestPasswordReset(_emailCtrl.text.trim());
      setState(() => _status = AppStrings.t(isArabic, 'reset_sent'));
    } on ApiException catch (e) {
      // 404 = الخدمة غير مُفعَّلة على السيرفر، وليست خطأً من المستخدم
      if (e.kind == ApiErrorKind.notFound) {
        setState(() {
          _unavailable = true;
          _status = AppStrings.t(isArabic, 'reset_unavailable');
        });
      } else {
        setState(() => _status = e.message);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
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
        title: Text(AppStrings.t(isArabic, 'reset_request_title')),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppDimens.pagePadding),
          children: [
            Text(
              AppStrings.t(isArabic, 'reset_request_body'),
              style: textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppDimens.lg),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText: AppStrings.t(isArabic, 'email'),
                  prefixIcon: const Icon(Icons.mail_outline_rounded),
                ),
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (value.isEmpty) {
                    return isArabic
                        ? 'هذا الحقل مطلوب'
                        : 'This field is required';
                  }
                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                    return isArabic
                        ? 'أدخل بريدًا صحيحًا'
                        : 'Enter a valid email';
                  }
                  return null;
                },
              ),
            ),
            if (_status != null) ...[
              const SizedBox(height: AppDimens.md),
              Container(
                padding: const EdgeInsets.all(AppDimens.md),
                decoration: BoxDecoration(
                  color: (_unavailable ? AppColors.warning : AppColors.success)
                      .withOpacity(0.10),
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _unavailable
                          ? Icons.info_outline_rounded
                          : Icons.check_circle_outline_rounded,
                      size: 18,
                      color:
                          _unavailable ? AppColors.warning : AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_status!,
                          style: textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppDimens.lg),
            SizedBox(
              height: AppDimens.buttonHeight,
              child: ElevatedButton(
                onPressed: _sending ? null : () => _submit(isArabic),
                child: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(AppStrings.t(isArabic, 'reset_send_link')),
              ),
            ),
            const SizedBox(height: AppDimens.md),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
              ),
              icon: const Icon(Icons.support_agent_rounded, size: 18),
              label: Text(AppStrings.t(isArabic, 'contact_support')),
            ),
          ],
        ),
      ),
    );
  }
}
