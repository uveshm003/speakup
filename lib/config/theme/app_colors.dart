import 'package:flutter/material.dart';

/// Light appearance tokens.
abstract final class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF5C4EFA);
  static const Color primaryLight = Color(0xFFEEF0FF);
  static const Color primaryDark = Color(0xFF3B2ECC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF6F7FB);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF0F0F1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderStrong = Color(0xFFD1D5DB);
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color beginner = Color(0xFF22C55E);
  static const Color intermediate = Color(0xFFF59E0B);
  static const Color advanced = Color(0xFFEF4444);
}

/// Dark appearance tokens (rich, non-harsh; base #0F0F1A).
abstract final class AppColorsDark {
  AppColorsDark._();

  static const Color primary = Color(0xFF7C6DFF);
  static const Color primaryLight = Color(0xFF2A2848);
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color surface = Color(0xFF16161F);
  static const Color background = Color(0xFF0F0F1A);
  static const Color cardBackground = Color(0xFF1C1C26);
  static const Color textPrimary = Color(0xFFF4F4F8);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textMuted = Color(0xFF71717A);
  static const Color border = Color(0xFF2E2E38);
  static const Color borderStrong = Color(0xFF3F3F4D);
  static const Color success = Color(0xFF34D399);
  static const Color successLight = Color(0xFF14532D);
  static const Color warning = Color(0xFFFBBF24);
  static const Color warningLight = Color(0xFF78350F);
  static const Color error = Color(0xFFF87171);
  static const Color errorLight = Color(0xFF7F1D1D);
  static const Color beginner = Color(0xFF22C55E);
  static const Color intermediate = Color(0xFFF59E0B);
  static const Color advanced = Color(0xFFEF4444);
}
