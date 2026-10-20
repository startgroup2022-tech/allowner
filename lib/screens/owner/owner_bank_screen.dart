import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_client.dart';
import '../../services/owner_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';

/// تسجيل بيانات الحساب البنكي للمالك (المتطلب 118).
///
/// هذه البيانات هي نفسها التي يعرضها الضيف في شاشة الحجز عند اختيار
/// «تحويل مباشر لحساب المالك» (`owner_bank` في `units/detail.php`)، لذلك
/// تسجيلها هنا يُصلح المتطلبين 118 و120 معًا.
class OwnerBankScreen extends ConsumerStatefulWidget {
  const OwnerBankScreen({super.key});

  @override
  ConsumerState<OwnerBankScreen> createState() => _OwnerBankScreenState();
}

class _OwnerBankScreenState extends ConsumerState<OwnerBankScreen> {
  final _service = OwnerService();
  final _bankCtrl = TextEditingController();
  final _accountNameCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  final _ibanCtrl = TextEditingController();

  late Future<Map<String, dynamic>> _future;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _bankCtrl.dispose();
    _accountNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _ibanCtrl.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _load() async {
    final data = await _service.getOwnerBank();
    // نملأ الحقول بالبيانات الحالية إن وُجدت حتى يعدّلها المالك بدل كتابتها من جديد.
    _bankCtrl.text = (data['bank_name'] ?? '').toString();
    _accountNameCtrl.text =
        (data['account_name'] ?? data['holder_name'] ?? '').toString();
    _accountNumberCtrl.text = (data['account_number'] ?? '').toString();
    _ibanCtrl.text = (data['iban'] ?? '').toString();
    return data;
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _save(bool isArabic) async {
    final bankName = _bankCtrl.text.trim();
    final accountName = _accountNameCtrl.text.trim();
    final accountNumber = _accountNumberCtrl.text.trim();

    if (bankName.isEmpty || accountName.isEmpty || accountNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t(isArabic, 'bank_fields_required'))),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _service.saveOwnerBank(
        bankName: bankName,
        accountName: accountName,
        accountNumber: accountNumber,
        iban: _ibanCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t(isArabic, 'bank_saved'))),
      );
      _reload();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
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
        title: Text(AppStrings.t(isArabic, 'owner_bank_title')),
      ),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(AppDimens.xl),
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.danger, size: 32),
                  const SizedBox(height: AppDimens.sm),
                  Text(
                    snapshot.error is ApiException
                        ? (snapshot.error as ApiException).message
                        : AppStrings.t(isArabic, 'error_loading'),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimens.sm),
                  Center(
                    child: OutlinedButton(
                      onPressed: _reload,
                      child: Text(AppStrings.t(isArabic, 'retry')),
                    ),
                  ),
                ],
              );
            }

            return ListView(
              padding: const EdgeInsets.all(AppDimens.pagePadding),
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimens.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 18, color: AppColors.textMuted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppStrings.t(isArabic, 'owner_bank_help'),
                          style: textTheme.bodySmall
                              ?.copyWith(color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimens.lg),
                TextField(
                  controller: _bankCtrl,
                  decoration: InputDecoration(
                      labelText: AppStrings.t(isArabic, 'owner_bank_name')),
                ),
                const SizedBox(height: AppDimens.md),
                TextField(
                  controller: _accountNameCtrl,
                  decoration: InputDecoration(
                      labelText:
                          AppStrings.t(isArabic, 'owner_bank_account_name')),
                ),
                const SizedBox(height: AppDimens.md),
                TextField(
                  controller: _accountNumberCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      labelText:
                          AppStrings.t(isArabic, 'owner_bank_account_number')),
                ),
                const SizedBox(height: AppDimens.md),
                TextField(
                  controller: _ibanCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: AppStrings.t(isArabic, 'owner_bank_iban'),
                    hintText: 'SA00 0000 0000 0000 0000 0000',
                  ),
                ),
                const SizedBox(height: AppDimens.xl),
                SizedBox(
                  height: AppDimens.buttonHeight,
                  child: ElevatedButton(
                    onPressed: _saving ? null : () => _save(isArabic),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(AppStrings.t(isArabic, 'save')),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
