import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/app_strings.dart';
import '../../utils/locale_provider.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingPage {
  final IconData icon;
  final String titleKey;
  final String descKey;
  final Color iconColor;

  _OnboardingPage({
    required this.icon,
    required this.titleKey,
    required this.descKey,
    required this.iconColor,
  });
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      icon: Icons.apartment_rounded,
      titleKey: 'onboard_title_1',
      descKey: 'onboard_desc_1',
      iconColor: AppColors.ink,
    ),
    _OnboardingPage(
      icon: Icons.business_center_rounded,
      titleKey: 'onboard_title_2',
      descKey: 'onboard_desc_2',
      iconColor: AppColors.secondary,
    ),
    _OnboardingPage(
      icon: Icons.travel_explore_rounded,
      titleKey: 'onboard_title_3',
      descKey: 'onboard_desc_3',
      iconColor: AppColors.goldDark,
    ),
  ];

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.pagePadding, vertical: 8),
                child: TextButton(
                  onPressed: _goToLogin,
                  child: Text(AppStrings.t(isArabic, 'skip')),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimens.pagePadding),
                    child: Center(
                     child: SingleChildScrollView(
                      child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            color: page.iconColor.withOpacity(0.07),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(page.icon, size: 70, color: page.iconColor),
                        ),
                        const SizedBox(height: AppDimens.xxl),
                        Text(
                          AppStrings.t(isArabic, page.titleKey),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: AppDimens.md),
                        Text(
                          AppStrings.t(isArabic, page.descKey),
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: AppColors.textSecondary, height: 1.6),
                        ),
                      ],
                    ),
                    ),
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? AppColors.gold : AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppDimens.xl),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.pagePadding),
              child: SizedBox(
                width: double.infinity,
                height: AppDimens.buttonHeight,
                child: ElevatedButton(
                  onPressed: () {
                    if (isLast) {
                      _goToLogin();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Text(isLast
                      ? AppStrings.t(isArabic, 'get_started')
                      : AppStrings.t(isArabic, 'next')),
                ),
              ),
            ),
            const SizedBox(height: AppDimens.lg),
          ],
        ),
      ),
    );
  }
}
