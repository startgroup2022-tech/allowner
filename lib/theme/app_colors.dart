import 'package:flutter/material.dart';

/// ألوان هوية All Owners — خلفية فاتحة عصرية + لمسات ذهبية فندقية فخمة
/// مستوحاة من لوجو IA (أسود/ذهبي/فضي) لكن بخلفية بيضاء تسمح لكل فندق
/// بإظهار صوره وهويته الخاصة بوضوح.
class AppColors {
  AppColors._();

  // ===== الأساسية =====
  static const Color gold = Color(0xFFE0B94F); // ذهبي اللوجو الرسمي
  static const Color goldLight = Color(0xFFF3D98A);
  static const Color goldDark = Color(0xFFB3872A);

  static const Color ink = Color(0xFF01122E); // كحلي اللوجو الرسمي
  static const Color inkLight = Color(0xFF1C3A63);

  static const Color silver = Color(0xFFB8BCC4); // فضي اللوجو (تفاصيل ثانوية)

  // ===== الوظيفية =====
  static const Color primary = ink;
  static const Color accent = gold;
  static const Color secondary = Color(0xFF2B6CB0); // أزرق ثانوي (روابط، معلومات)

  static const Color success = Color(0xFF2E9E5B);
  static const Color warning = Color(0xFFE8A33D);
  static const Color danger = Color(0xFFD64545);
  static const Color info = secondary;

  // ===== خلفيات =====
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF2F2F3);
  static const Color cardBorder = Color(0xFFE7E7EA);

  // ===== نصوص =====
  static const Color textPrimary = ink;
  static const Color textSecondary = Color(0xFF6B6E76);
  static const Color textMuted = Color(0xFF9A9DA6);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnGold = ink;

  // ===== تدرجات =====
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldLight, gold, goldDark],
  );

  static const LinearGradient darkOverlayGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0xCC01122E)],
  );

  static const LinearGradient heroDarkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ink, inkLight],
  );

  // ===== ظلال =====
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: ink.withOpacity(0.05),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: ink.withOpacity(0.10),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> goldGlow = [
    BoxShadow(
      color: gold.withOpacity(0.25),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];
}
