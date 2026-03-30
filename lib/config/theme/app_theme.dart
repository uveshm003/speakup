import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';
import 'speakup_theme_extension.dart';

class AppTheme {
  AppTheme._();

  static TextTheme _buildTextTheme() {
    final serif = GoogleFonts.newsreader;

    final sans = GoogleFonts.inter;

    return TextTheme(
      displayLarge: serif(fontSize: 57, fontWeight: FontWeight.w400, letterSpacing: -0.25, color: AppColorsNew.onSurface),
      displayMedium: serif(fontSize: 45, fontWeight: FontWeight.w400, color: AppColorsNew.onSurface),
      displaySmall: serif(fontSize: 36, fontWeight: FontWeight.w400, color: AppColorsNew.onSurface),

      headlineLarge: serif(fontSize: 32, fontWeight: FontWeight.w600, color: AppColorsNew.onSurface),
      headlineMedium: serif(fontSize: 28, fontWeight: FontWeight.w500, color: AppColorsNew.onSurface),
      headlineSmall: serif(fontSize: 24, fontWeight: FontWeight.w500, color: AppColorsNew.onSurface),

      titleLarge: sans(fontSize: 22, fontWeight: FontWeight.w500, color: AppColorsNew.onSurface),
      titleMedium: sans(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.15, color: AppColorsNew.onSurface),
      titleSmall: sans(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1, color: AppColorsNew.onSurface),

      bodyLarge: sans(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5, color: AppColorsNew.onSurface),
      bodyMedium: sans(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25, color: AppColorsNew.onSurface),
      bodySmall: sans(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4, color: AppColorsNew.onSurfaceVariant),

      labelLarge: sans(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1, color: AppColorsNew.onSurface),
      labelMedium: sans(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: AppColorsNew.onSurface),
      labelSmall: sans(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: AppColorsNew.onSurfaceVariant),
    );
  }

  static const ColorScheme _colorScheme = ColorScheme(
    brightness: Brightness.light,

    // Primary
    primary: AppColorsNew.primary,
    onPrimary: AppColorsNew.onPrimary,
    primaryContainer: AppColorsNew.primaryContainer,
    onPrimaryContainer: AppColorsNew.onPrimaryContainer,

    // Secondary
    secondary: AppColorsNew.secondary,
    onSecondary: AppColorsNew.onSecondary,
    secondaryContainer: AppColorsNew.secondaryContainer,
    onSecondaryContainer: AppColorsNew.onSecondaryContainer,

    // Tertiary
    tertiary: AppColorsNew.tertiary,
    onTertiary: AppColorsNew.onTertiary,
    tertiaryContainer: AppColorsNew.tertiaryContainer,
    onTertiaryContainer: AppColorsNew.onTertiaryContainer,

    // Error
    error: AppColorsNew.error,
    onError: AppColorsNew.onError,
    errorContainer: AppColorsNew.errorContainer,
    onErrorContainer: AppColorsNew.onErrorContainer,

    // Surface
    surface: AppColorsNew.surface,
    onSurface: AppColorsNew.onSurface,
    surfaceContainerLowest: AppColorsNew.surfaceContainerLowest,
    surfaceContainerLow: AppColorsNew.surfaceContainerLow,
    surfaceContainer: AppColorsNew.surfaceContainer,
    surfaceContainerHigh: AppColorsNew.surfaceContainerHigh,
    surfaceContainerHighest: AppColorsNew.surfaceContainerHighest,

    // Outline
    outline: AppColorsNew.outline,
    outlineVariant: AppColorsNew.outlineVariant,

    // Inverse
    inverseSurface: AppColorsNew.inverseSurface,
    onInverseSurface: AppColorsNew.onInverseSurface,
    inversePrimary: AppColorsNew.inversePrimary,

    // Scrim & Shadow
    scrim: AppColorsNew.scrim,
    shadow: AppColorsNew.shadow,
  );

  static ThemeData get light {
    final textTheme = _buildTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: _colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColorsNew.surface,

      // ── AppBar ────────────────────────────────────────────────────────────
      // Glass-morphism sticky header: surface@80% + blur in your widget layer.
      // ThemeData sets the opaque fallback; apply BackdropFilter in the widget.
      appBarTheme: AppBarTheme(
        backgroundColor: AppColorsNew.surface,
        foregroundColor: AppColorsNew.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
      ),

      // ── Elevated Button (Primary CTA with gradient) ───────────────────────
      // Use a custom widget (GradientButton) to apply the jewel gradient.
      // This theme covers the default fallback.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsNew.primary,
          foregroundColor: AppColorsNew.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24), // xl = 1.5rem
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: textTheme.labelLarge,
          elevation: 0,
        ),
      ),

      // ── Filled Button ────────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColorsNew.primary,
          foregroundColor: AppColorsNew.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: textTheme.labelLarge,
          elevation: 0,
        ),
      ),

      // ── Outlined Button (Secondary) ───────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColorsNew.secondaryContainer,
          foregroundColor: AppColorsNew.onSecondaryContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // ── Text Button (Tertiary — ghost style) ─────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColorsNew.primary,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),

      // ── FAB (Record / Speak action) ───────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColorsNew.primary,
        foregroundColor: AppColorsNew.onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: CircleBorder(),
      ),

      // ── Cards ─────────────────────────────────────────────────────────────
      // surfaceContainerLowest (#fff) on surfaceContainerLow (#f5f3ef) = lift.
      // No borders. No shadows — only tonal layering.
      cardTheme: CardThemeData(
        color: AppColorsNew.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 8),
      ),

      // ── Input Decoration ─────────────────────────────────────────────────
      // Minimalist underline or soft-box; primary outline on focus.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsNew.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColorsNew.primary, width: 2),
        ),
        // Focused fill shifts to surfaceContainerLowest
        focusColor: AppColorsNew.surfaceContainerLowest,
        hintStyle: GoogleFonts.inter(color: AppColorsNew.onSurfaceVariant, fontSize: 14, fontWeight: FontWeight.w400),
        labelStyle: GoogleFonts.inter(color: AppColorsNew.onSurfaceVariant, fontSize: 14),
        floatingLabelStyle: GoogleFonts.inter(color: AppColorsNew.primary, fontSize: 12, fontWeight: FontWeight.w500),
      ),

      // ── Bottom Navigation Bar (glassmorphism backing) ─────────────────────
      // Apply BackdropFilter in your widget; this sets colours & indicator.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColorsNew.glassBackground,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColorsNew.primaryContainer.withOpacity(0.3),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final active = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize: 12,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? AppColorsNew.primary : AppColorsNew.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final active = states.contains(WidgetState.selected);
          return IconThemeData(color: active ? AppColorsNew.primary : AppColorsNew.onSurfaceVariant, size: 24);
        }),
        elevation: 0,
      ),

      // ── Bottom Sheet ─────────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColorsNew.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),

      // ── Chip ─────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColorsNew.surfaceContainerLow,
        selectedColor: AppColorsNew.primaryContainer,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        side: BorderSide.none,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // ── Divider ──────────────────────────────────────────────────────────
      // The "No-Line" rule: dividers should be invisible.
      // Use surface-level shifts in your layouts instead.
      dividerTheme: const DividerThemeData(color: Colors.transparent, space: 0, thickness: 0),

      // ── Dialog ───────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColorsNew.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: GoogleFonts.newsreader(fontSize: 24, fontWeight: FontWeight.w500, color: AppColorsNew.onSurface),
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: AppColorsNew.onSurfaceVariant),
      ),

      // ── Snack Bar ────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColorsNew.inverseSurface,
        contentTextStyle: GoogleFonts.inter(color: AppColorsNew.onInverseSurface, fontSize: 14),
        actionTextColor: AppColorsNew.inversePrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      // ── List Tile ────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        titleTextStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: AppColorsNew.onSurface),
        subtitleTextStyle: GoogleFonts.inter(fontSize: 13, color: AppColorsNew.onSurfaceVariant),
        tileColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // ── Switch ───────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColorsNew.onPrimary : AppColorsNew.outline,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColorsNew.primary : AppColorsNew.surfaceContainerHighest,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // ── Progress Indicator ───────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColorsNew.primary,
        linearTrackColor: AppColorsNew.surfaceContainerHigh,
        circularTrackColor: AppColorsNew.surfaceContainerHigh,
      ),

      // ── Icon ─────────────────────────────────────────────────────────────
      iconTheme: const IconThemeData(color: AppColorsNew.onSurfaceVariant, size: 24),
      primaryIconTheme: const IconThemeData(color: AppColorsNew.primary, size: 24),

      // ── Page Transitions ─────────────────────────────────────────────────
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(), TargetPlatform.iOS: CupertinoPageTransitionsBuilder()},
      ),
    );
  }

  static ThemeData get dark {
    final ColorScheme scheme = ColorScheme.fromSeed(seedColor: AppColorsDark.primary, brightness: Brightness.dark).copyWith(
      surface: AppColorsDark.surface,
      onSurface: AppColorsDark.textPrimary,
      primary: AppColorsDark.primary,
      onPrimary: const Color(0xFF0F0F1A),
      primaryContainer: AppColorsDark.primaryLight,
      onPrimaryContainer: AppColorsDark.textPrimary,
      secondary: AppColorsDark.primaryDark,
      onSecondary: Colors.white,
      error: AppColorsDark.error,
      onError: const Color(0xFF0F0F1A),
      outline: AppColorsDark.border,
      outlineVariant: AppColorsDark.borderStrong,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColorsDark.background,
      canvasColor: AppColorsDark.background,
      textTheme: AppTextStyles.darkTextTheme(),
      extensions: const <ThemeExtension<dynamic>>[SpeakUpThemeTokens.dark],
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: AppColorsDark.surface,
        foregroundColor: AppColorsDark.textPrimary,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColorsDark.textPrimary, size: 22),
        titleTextStyle: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w600, color: AppColorsDark.textPrimary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColorsDark.surface,
        elevation: 0,
        selectedItemColor: AppColorsDark.primary,
        unselectedItemColor: AppColorsDark.textMuted,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
        showUnselectedLabels: true,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColorsDark.cardBackground,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsDark.cardBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        hintStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w400, color: AppColorsDark.textMuted),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColorsDark.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColorsDark.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColorsDark.error, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          backgroundColor: AppColorsDark.primary,
          foregroundColor: const Color(0xFF0F0F1A),
          disabledBackgroundColor: AppColorsDark.borderStrong,
          disabledForegroundColor: AppColorsDark.textMuted,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColorsDark.primary,
          splashFactory: NoSplash.splashFactory,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        color: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return AppColorsDark.primaryLight;
          }
          return AppColorsDark.surface.withValues(alpha: 0.001);
        }),
        side: const BorderSide(color: AppColorsDark.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColorsDark.textPrimary),
        secondaryLabelStyle: GoogleFonts.inter(fontSize: 12, color: AppColorsDark.textSecondary),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        showCheckmark: false,
        brightness: Brightness.dark,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF2A2A32),
        contentTextStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        insetPadding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
      ),
      dividerTheme: const DividerThemeData(color: AppColorsDark.border, thickness: 1),
    );
  }
}
