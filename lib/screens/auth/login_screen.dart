import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';
import '../../utils/session_provider.dart';
import '../home/main_navigation_screen.dart';
import '../owner/owner_navigation_screen.dart';
import '../hotel_staff/hotel_staff_navigation_screen.dart';
import '../../widgets/app_logo.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final notifier = ref.read(sessionProvider.notifier);
    final ok = await notifier.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (ok) {
      final user = ref.read(sessionProvider).user!;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => user.isHotelStaff
              ? const HotelStaffNavigationScreen()
              : user.isOwnerSide
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

  void _continueAsGuest() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.pagePadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppDimens.xl),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: AppDimens.lg, horizontal: AppDimens.md),
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                  ),
                  child: const Center(child: AppLogo(width: 220, full: true)),
                ),
                const SizedBox(height: AppDimens.xl),
                Text(
                  AppStrings.t(isArabic, 'welcome_back'),
                  textAlign: TextAlign.center,
                  style: textTheme.headlineLarge,
                ),
                const SizedBox(height: AppDimens.sm),
                Text(
                  AppStrings.t(isArabic, 'login_subtitle'),
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppDimens.xl),

                Text(isArabic ? 'البريد الإلكتروني' : 'Email', style: textTheme.titleSmall),
                const SizedBox(height: AppDimens.sm),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    hintText: 'name@example.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
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
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return isArabic ? 'هذا الحقل مطلوب' : 'This field is required';
                    }
                    return null;
                  },
                ),
                Align(
                  alignment: isArabic ? Alignment.centerLeft : Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: Text(AppStrings.t(isArabic, 'forgot_password')),
                  ),
                ),
                const SizedBox(height: AppDimens.md),

                SizedBox(
                  height: AppDimens.buttonHeight,
                  child: ElevatedButton(
                    onPressed: session.isLoading ? null : _login,
                    child: session.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                          )
                        : Text(AppStrings.t(isArabic, 'login')),
                  ),
                ),
                const SizedBox(height: AppDimens.md),

                SizedBox(
                  height: AppDimens.buttonHeight,
                  child: OutlinedButton(
                    onPressed: session.isLoading ? null : _continueAsGuest,
                    child: Text(AppStrings.t(isArabic, 'continue_as_guest')),
                  ),
                ),
                const SizedBox(height: AppDimens.xl),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(AppStrings.t(isArabic, 'no_account'),
                        style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
                      },
                      child: Text(AppStrings.t(isArabic, 'create_account')),
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
