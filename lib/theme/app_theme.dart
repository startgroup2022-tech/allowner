import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  /// [fontFamilyOverride] يُستخدم في توليد لقطات الاختبار فقط: بيئة الاختبار
  /// تعمل بلا شبكة ولا تستطيع `google_fonts` تنزيل خطوطها، فنمرّر عائلة خط
  /// محمّلة محليًا. القيمة الافتراضية `null` تُبقي السلوك الإنتاجي كما هو.
  static TextTheme _textTheme(bool isArabic, Color baseColor,
      {String? fontFamilyOverride}) {
    TextStyle fontFunction({
      double? fontSize,
      FontWeight? fontWeight,
      Color? color,
      double? height,
    }) {
      if (fontFamilyOverride != null) {
        return TextStyle(
          fontFamily: fontFamilyOverride,
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
        );
      }
      final googleFont =
          isArabic ? GoogleFonts.ibmPlexSansArabic : GoogleFonts.inter;
      return googleFont(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height);
    }

    return TextTheme(
      displayLarge: fontFunction(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: baseColor,
          height: 1.3),
      displayMedium: fontFunction(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: baseColor,
          height: 1.3),
      headlineLarge: fontFunction(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: baseColor,
          height: 1.35),
      headlineMedium: fontFunction(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: baseColor,
          height: 1.35),
      headlineSmall: fontFunction(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: baseColor,
          height: 1.4),
      titleLarge: fontFunction(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: baseColor,
          height: 1.4),
      titleMedium: fontFunction(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: baseColor,
          height: 1.4),
      titleSmall: fontFunction(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: baseColor,
          height: 1.4),
      bodyLarge: fontFunction(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: baseColor,
          height: 1.6),
      bodyMedium: fontFunction(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: baseColor,
          height: 1.6),
      bodySmall: fontFunction(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: baseColor,
          height: 1.5),
      labelLarge: fontFunction(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: baseColor,
          height: 1.2),
      labelMedium: fontFunction(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: baseColor,
          height: 1.2),
      labelSmall: fontFunction(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: baseColor,
          height: 1.2),
    );
  }

  static ThemeData light({bool isArabic = true, String? fontFamilyOverride}) {
    final textTheme = _textTheme(isArabic, AppColors.textPrimary,
        fontFamilyOverride: fontFamilyOverride);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: fontFamilyOverride ??
          (isArabic
              ? GoogleFonts.ibmPlexSansArabic().fontFamily
              : GoogleFonts.inter().fontFamily),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.ink,
        primary: AppColors.primary,
        secondary: AppColors.gold,
        tertiary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.danger,
        brightness: Brightness.light,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.titleMedium?.copyWith(color: Colors.white),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.ink, width: 1.3),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.titleMedium,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.goldDark,
          textStyle: textTheme.titleMedium,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceMuted,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.2),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceMuted,
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: BorderSide.none,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.ink,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showUnselectedLabels: true,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.cardBorder,
        thickness: 1,
        space: 1,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.ink,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.gold,
        labelStyle: textTheme.titleSmall,
        unselectedLabelStyle: textTheme.titleSmall,
      ),
    );
  }
}
