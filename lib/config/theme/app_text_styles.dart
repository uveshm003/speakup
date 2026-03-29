import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Plus Jakarta Sans + Inter. Use via [Theme.of(context).textTheme] after wiring in [AppTheme].
abstract final class AppTextStyles {
  AppTextStyles._();

  static TextTheme lightTextTheme() {
    return _build(textPrimary: AppColors.textPrimary, textSecondary: AppColors.textSecondary, textMuted: AppColors.textMuted);
  }

  static TextTheme darkTextTheme() {
    return _build(textPrimary: AppColorsDark.textPrimary, textSecondary: AppColorsDark.textSecondary, textMuted: AppColorsDark.textMuted);
  }

  static TextTheme _build({required Color textPrimary, required Color textSecondary, required Color textMuted}) {
    return TextTheme(
      displayLarge: GoogleFonts.plusJakartaSans(fontSize: 32, fontWeight: FontWeight.w700, height: 1.15, color: textPrimary),
      displayMedium: GoogleFonts.plusJakartaSans(fontSize: 26, fontWeight: FontWeight.w700, height: 1.2, color: textPrimary),
      headlineLarge: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w600, height: 1.25, color: textPrimary),
      headlineMedium: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w600, height: 1.3, color: textPrimary),
      titleLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, height: 1.35, color: textPrimary),
      titleMedium: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, height: 1.4, color: textPrimary),
      bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5, color: textPrimary),
      bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, height: 1.45, color: textSecondary),
      bodySmall: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, height: 1.45, color: textMuted),
      labelLarge: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, height: 1.2, letterSpacing: 0.6, color: textPrimary),
      labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, height: 1.3, color: textSecondary),
    );
  }
}
