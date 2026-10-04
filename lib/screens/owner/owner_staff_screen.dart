import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';
import '../../services/owner_service.dart';
import '../../services/api_client.dart';

class OwnerStaffScreen extends ConsumerStatefulWidget {
  const OwnerStaffScreen({super.key});

  @override
  ConsumerState<OwnerStaffScreen> createState() => _OwnerStaffScreenState();
}

class _OwnerStaffScreenState extends ConsumerState<OwnerStaffScreen> {
  final _service = OwnerService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getStaff();
  }

  void _reload() => setState(() => _future = _service.getStaff());

  String _roleLabel(bool isArabic, String role) {
    switch (role) {
      case 'unit_manager':
        return AppStrings.t(isArabic, 'role_unit_manager');
      case 'hotel_manager':
        return AppStrings.t(isArabic, 'role_hotel_manager');
      case 'booking_agent':
        return AppStrings.t(isArabic, 'role_booking_agent');
      default:
        return role;
    }
  }

  Future<void> _toggleStatus(Map<String, dynamic> staff) async {
    try {
      await _service.toggleStaffStatus(staff['id'] as int);
      _reload();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _openResetPasswordSheet(bool isArabic, Map<String, dynamic> staff) async {
    final pwCtrl = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppDimens.pagePadding,
            right: AppDimens.pagePadding,
            top: AppDimens.pagePadding,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppDimens.pagePadding,
          ),
          child: StatefulBuilder(
            builder: (ctx, setSheetState) => SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${AppStrings.t(isArabic, 'reset_password')} — ${staff['full_name']}',
                      style: Theme.of(ctx).textTheme.titleMedium),
                  const SizedBox(height: AppDimens.md),
                  TextField(
                    controller: pwCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: AppStrings.t(isArabic, 'password'),
                      helperText: AppStrings.t(isArabic, 'password_hint_min6'),
                    ),
                  ),
                  const SizedBox(height: AppDimens.lg),
                  SizedBox(
                    width: double.infinity,
                    height: AppDimens.buttonHeight,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (pwCtrl.text.trim().length < 6) return;
                        try {
                          await _service.resetStaffPassword(staff['id'] as int, pwCtrl.text.trim());
                          if (ctx.mounted) Navigator.of(ctx).pop();
                          if (mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text(AppStrings.t(isArabic, 'save'))));
                          }
                        } on ApiException catch (e) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                        }
                      },
                      child: Text(AppStrings.t(isArabic, 'save')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openAddManagerSheet(bool isArabic) async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final pwCtrl = TextEditingController();
    String? errorText;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppDimens.pagePadding,
            right: AppDimens.pagePadding,
            top: AppDimens.pagePadding,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppDimens.pagePadding,
          ),
          child: StatefulBuilder(
            builder: (ctx, setSheetState) => SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.t(isArabic, 'add_unit_manager'), style: Theme.of(ctx).textTheme.titleMedium),
                  const SizedBox(height: AppDimens.md),
                  TextField(controller: nameCtrl, decoration: InputDecoration(labelText: AppStrings.t(isArabic, 'full_name'))),
                  const SizedBox(height: AppDimens.md),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(labelText: AppStrings.t(isArabic, 'email')),
                  ),
                  const SizedBox(height: AppDimens.md),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(labelText: AppStrings.t(isArabic, 'phone')),
                  ),
                  const SizedBox(height: AppDimens.md),
                  TextField(
                    controller: pwCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: AppStrings.t(isArabic, 'password'),
                      helperText: AppStrings.t(isArabic, 'password_hint_min6'),
                    ),
                  ),
                  const SizedBox(height: AppDimens.md),
                  Container(
                    padding: const EdgeInsets.all(AppDimens.sm),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            AppStrings.t(isArabic, 'staff_permissions_note'),
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: AppDimens.sm),
                    Text(errorText!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                  ],
                  const SizedBox(height: AppDimens.lg),
                  SizedBox(
                    width: double.infinity,
                    height: AppDimens.buttonHeight,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameCtrl.text.trim().isEmpty ||
                            emailCtrl.text.trim().isEmpty ||
                            pwCtrl.text.trim().length < 6) {
                          setSheetState(() => errorText = AppStrings.t(isArabic, 'password_hint_min6'));
                          return;
                        }
                        try {
                          await _service.createUnitManager(
                            fullName: nameCtrl.text.trim(),
                            email: emailCtrl.text.trim(),
                            phone: phoneCtrl.text.trim(),
                            password: pwCtrl.text.trim(),
                          );
                          if (ctx.mounted) Navigator.of(ctx).pop();
                          _reload();
                        } on ApiException catch (e) {
                          setSheetState(() => errorText = e.message);
                        }
                      },
                      child: Text(AppStrings.t(isArabic, 'save')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
        title: Text(AppStrings.t(isArabic, 'staff')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.gold,
        onPressed: () => _openAddManagerSheet(isArabic),
        icon: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.textOnGold),
        label: Text(AppStrings.t(isArabic, 'add_unit_manager'),
            style: const TextStyle(color: AppColors.textOnGold)),
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

              final staff = snapshot.data ?? [];

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppDimens.pagePadding),
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDimens.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                    ),
                    child: Text(
                      AppStrings.t(isArabic, 'staff_desc'),
                      style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: AppDimens.md),
                  if (staff.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppDimens.xl),
                      child: Center(child: Text(AppStrings.t(isArabic, 'no_staff_yet'))),
                    )
                  else
                    ...staff.map((s) {
                      final isActive = (s['status'] ?? 'active') == 'active';
                      return Container(
                        margin: const EdgeInsets.only(bottom: AppDimens.md),
                        padding: const EdgeInsets.all(AppDimens.md),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(s['full_name']?.toString() ?? '', style: textTheme.titleSmall),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (isActive ? AppColors.success : AppColors.danger).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                                  ),
                                  child: Text(
                                    AppStrings.t(isArabic, isActive ? 'active' : 'suspended'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isActive ? AppColors.success : AppColors.danger,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(_roleLabel(isArabic, s['role']?.toString() ?? ''),
                                style: textTheme.bodySmall?.copyWith(color: AppColors.goldDark)),
                            if ((s['email'] ?? '').toString().isNotEmpty)
                              Text(s['email'].toString(), style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                            if ((s['phone'] ?? '').toString().isNotEmpty)
                              Text(s['phone'].toString(), style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                            const SizedBox(height: AppDimens.sm),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _toggleStatus(s),
                                    child: Text(AppStrings.t(isArabic, isActive ? 'suspend' : 'activate')),
                                  ),
                                ),
                                const SizedBox(width: AppDimens.sm),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _openResetPasswordSheet(isArabic, s),
                                    child: Text(AppStrings.t(isArabic, 'reset_password')),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
