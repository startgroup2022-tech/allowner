import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';
import '../../utils/session_provider.dart';
import '../home/main_navigation_screen.dart';
import '../owner/owner_navigation_screen.dart';

enum _SignupRole { guest, owner }

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  _SignupRole _selectedRole = _SignupRole.guest;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final notifier = ref.read(sessionProvider.notifier);
    final ok = await notifier.register(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole == _SignupRole.owner ? 'owner' : 'guest',
    );

    if (!mounted) return;

    if (ok) {
      final user = ref.read(sessionProvider).user!;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => user.isOwnerSide
              ? const OwnerNavigationScreen()
              : const MainNavigationScreen(),
        ),
        (route) => false,
      );
    } else {
      final error = ref.read(sessionProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'حدث خطأ غير متوقع')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final textTheme = Theme.of(context).textTheme;
    final session = ref.watch(sessionProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(AppStrings.t(isArabic, 'create_account'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.pagePadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppDimens.md),
                Text(AppStrings.t(isArabic, 'full_name'), style: textTheme.titleSmall),
                const SizedBox(height: AppDimens.sm),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline_rounded)),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? (isArabic ? 'هذا الحقل مطلوب' : 'This field is required')
                      : null,
                ),
                const SizedBox(height: AppDimens.md),

                Text(AppStrings.t(isArabic, 'phone_number'), style: textTheme.titleSmall),
                const SizedBox(height: AppDimens.sm),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    hintText: '05xxxxxxxx',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: AppDimens.md),

                Text(AppStrings.t(isArabic, 'email'), style: textTheme.titleSmall),
                const SizedBox(height: AppDimens.sm),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.email_outlined)),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return isArabic ? 'هذا الحقل مطلوب' : 'This field is required';
                    }
                    if (!v.contains('@')) {
                      return isArabic ? 'بريد إلكتروني غير صحيح' : 'Invalid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppDimens.md),

                Text(AppStrings.t(isArabic, 'password'), style: textTheme.titleSmall),
                const SizedBox(height: AppDimens.sm),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.lock_outline_rounded)),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return isArabic ? 'هذا الحقل مطلوب' : 'This field is required';
                    }
                    if (v.length < 6) {
                      return isArabic ? 'كلمة المرور 6 أحرف على الأقل' : 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppDimens.md),

                Text(AppStrings.t(isArabic, 'account_type'), style: textTheme.titleSmall),
                const SizedBox(height: AppDimens.sm),
                Row(
                  children: [
                    Expanded(
                      child: _RoleOption(
                        icon: Icons.luggage_outlined,
                        label: AppStrings.t(isArabic, 'role_guest'),
                        isSelected: _selectedRole == _SignupRole.guest,
                        onTap: () => setState(() => _selectedRole = _SignupRole.guest),
                      ),
                    ),
                    const SizedBox(width: AppDimens.sm),
                    Expanded(
                      child: _RoleOption(
                        icon: Icons.apartment_outlined,
                        label: AppStrings.t(isArabic, 'role_owner'),
                        isSelected: _selectedRole == _SignupRole.owner,
                        onTap: () => setState(() => _selectedRole = _SignupRole.owner),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.xl),

                SizedBox(
                  height: AppDimens.buttonHeight,
                  child: ElevatedButton(
                    onPressed: session.isLoading ? null : _register,
                    child: session.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                          )
                        : Text(AppStrings.t(isArabic, 'create_account')),
                  ),
                ),
                const SizedBox(height: AppDimens.lg),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(AppStrings.t(isArabic, 'have_account'),
                        style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(AppStrings.t(isArabic, 'login')),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppDimens.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold.withOpacity(0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(
            color: isSelected ? AppColors.goldDark : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: isSelected ? AppColors.goldDark : AppColors.textSecondary),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? AppColors.goldDark : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
