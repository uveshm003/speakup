import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Plus Jakarta Sans + Inter. Use via [Theme.of(context).textTheme] after wiring in [AppTheme].
///
/// NOTE: Inter is bundled locally as `Inter-400/500/600/700.ttf` and registered
/// under the family name `Inter` in pubspec.yaml. We use `TextStyle(fontFamily:'Inter')`
/// directly to avoid GoogleFonts trying to look up `Inter-Regular.ttf` etc. at runtime.
abstract final class AppTextStyles {
  AppTextStyles._();

  static TextTheme lightTextTheme() {
    return _build(textPrimary: AppColors.textPrimary, textSecondary: AppColors.textSecondary, textMuted: AppColors.textMuted);
  }

  static TextTheme darkTextTheme() {
    return _build(textPrimary: AppColorsDark.textPrimary, textSecondary: AppColorsDark.textSecondary, textMuted: AppColorsDark.textMuted);
  }

  static TextTheme _build({required Color textPrimary, required Color textSecondary, required Color textMuted}) {
    // Use GoogleFonts.plusJakartaSans() only — Plus Jakarta Sans files are also
    // bundled locally. Inter is referenced via TextStyle(fontFamily:'Inter') because
    // our asset files are named Inter-400.ttf … not Inter-Regular.ttf.
    return TextTheme(
      displayLarge: _pjs(32, FontWeight.w700, 1.15, textPrimary),
      displayMedium: _pjs(26, FontWeight.w700, 1.20, textPrimary),
      headlineLarge: _pjs(22, FontWeight.w600, 1.25, textPrimary),
      headlineMedium: _pjs(18, FontWeight.w600, 1.30, textPrimary),
      titleLarge: _inter(16, FontWeight.w600, 1.35, textPrimary),
      titleMedium: _inter(15, FontWeight.w500, 1.40, textPrimary),
      bodyLarge: _inter(16, FontWeight.w400, 1.50, textPrimary),
      bodyMedium: _inter(14, FontWeight.w400, 1.45, textSecondary),
      bodySmall: _inter(13, FontWeight.w400, 1.45, textMuted),
      labelLarge: _inter(13, FontWeight.w600, 1.20, textPrimary, letterSpacing: 0.6),
      labelMedium: _inter(12, FontWeight.w500, 1.30, textSecondary),
      labelSmall: _inter(11, FontWeight.w500, 1.30, textMuted),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  static TextStyle _inter(double size, FontWeight weight, double height, Color color, {double letterSpacing = 0}) {
    return TextStyle(fontFamily: 'Inter', fontSize: size, fontWeight: weight, height: height, color: color, letterSpacing: letterSpacing);
  }

  static TextStyle _pjs(double size, FontWeight weight, double height, Color color) {
    return TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: size, fontWeight: weight, height: height, color: color);
  }
}
