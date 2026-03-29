import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

abstract class AppColorsNew {
  // ---------------------------------------------------------------------------
  // Primary (Focus) — Deep forest green for deep-focus & high-priority actions
  // ---------------------------------------------------------------------------
  static const Color primary = Color(0xFF00352C);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF024E41);
  static const Color onPrimaryContainer = Color(0xFFFFFFFF);

  // ---------------------------------------------------------------------------
  // Secondary (Momentum) — Warm gold ONLY for streaks, achievements & rewards
  // ---------------------------------------------------------------------------
  static const Color secondary = Color(0xFF735C00);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFF5E0A2); // light gold tint
  static const Color onSecondaryContainer = Color(0xFF241A00);

  // ---------------------------------------------------------------------------
  // Tertiary (Depth) — Deep blue for secondary paths & instructional metadata
  // ---------------------------------------------------------------------------
  static const Color tertiary = Color(0xFF002183);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFDDE1FF);
  static const Color onTertiaryContainer = Color(0xFF00105C);

  // ---------------------------------------------------------------------------
  // Error
  // ---------------------------------------------------------------------------
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF410002);

  // ---------------------------------------------------------------------------
  // Surface Hierarchy — Treat as physical layers (no borders, only tone shifts)
  //
  //   surfaceContainerLowest  (#ffffff)   → Layer 2: Cards — "pop" against page
  //   surface                 (#fbf9f5)   → Base layer
  //   surfaceContainerLow     (#f5f3ef)   → Subtle differentiation
  //   surfaceContainer        (#efeeea)   → Layer 1: Main content areas
  //   surfaceContainerHigh    (#eae8e4)   → Slightly more recessed
  //   surfaceContainerHighest (#e4e2de)   → Hover / active state backgrounds
  // ---------------------------------------------------------------------------
  static const Color surface = Color(0xFFFBF9F5);
  static const Color onSurface = Color(0xFF1B1C1A); // never pure black
  static const Color surfaceVariant = Color(0xFFDEE5E0);
  static const Color onSurfaceVariant = Color(0xFF424842);

  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF5F3EF);
  static const Color surfaceContainer = Color(0xFFEFEEEA);
  static const Color surfaceContainerHigh = Color(0xFFEAE8E4);
  static const Color surfaceContainerHighest = Color(0xFFE4E2DE);

  // ---------------------------------------------------------------------------
  // Outline — The "Ghost Border" fallback (use at 15% opacity)
  // ---------------------------------------------------------------------------
  static const Color outline = Color(0xFF72796F);
  static const Color outlineVariant = Color(0xFFBFC8C8); // at 15% = ghost border

  // ---------------------------------------------------------------------------
  // Inverse & Scrim
  // ---------------------------------------------------------------------------
  static const Color inverseSurface = Color(0xFF2F3130);
  static const Color onInverseSurface = Color(0xFFF1F1EC);
  static const Color inversePrimary = Color(0xFF62DBC4);
  static const Color scrim = Color(0xFF000000);
  static const Color shadow = Color(0xFF1B1C1A); // tinted, not pure black

  // ---------------------------------------------------------------------------
  // Glassmorphism helpers — use these for bottom nav / sticky headers
  //   surface at 80% opacity + 20px backdrop-blur
  // ---------------------------------------------------------------------------
  static const Color glassBackground = Color(0xCCFBF9F5); // surface @ 80%

  // ---------------------------------------------------------------------------
  // Gradient helpers — "Jewel-like" CTA buttons
  // ---------------------------------------------------------------------------
  static const LinearGradient primaryButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryContainer],
  );

  // ---------------------------------------------------------------------------
  // Ambient shadow spec — blur:24, spread:-4, opacity:6%
  // ---------------------------------------------------------------------------
  static List<BoxShadow> get ambientShadow => [BoxShadow(color: shadow.withOpacity(0.06), blurRadius: 24, spreadRadius: -4)];
}

// =============================================================================
// APP THEME — The Curated Orator
// =============================================================================

class AppThemeNew {
  AppThemeNew._();

  // ---------------------------------------------------------------------------
  // Typography
  //   Headlines → Newsreader (editorial serif)
  //   UI / Body  → Inter (clean sans-serif)
  //
  // Add to pubspec.yaml:
  //   google_fonts: ^6.x.x
  // ---------------------------------------------------------------------------

  static TextTheme _buildTextTheme() {
    // Newsreader for display / headline — authority & grace
    final serif = GoogleFonts.newsreader;
    // Inter for titles, body, labels — functional clarity
    final sans = GoogleFonts.inter;

    return TextTheme(
      // --- Display (serif) ---
      displayLarge: serif(fontSize: 57, fontWeight: FontWeight.w400, letterSpacing: -0.25, color: AppColorsNew.onSurface),
      displayMedium: serif(fontSize: 45, fontWeight: FontWeight.w400, color: AppColorsNew.onSurface),
      displaySmall: serif(fontSize: 36, fontWeight: FontWeight.w400, color: AppColorsNew.onSurface),

      // --- Headline (serif) ---
      headlineLarge: serif(fontSize: 32, fontWeight: FontWeight.w600, color: AppColorsNew.onSurface),
      headlineMedium: serif(fontSize: 28, fontWeight: FontWeight.w500, color: AppColorsNew.onSurface),
      headlineSmall: serif(fontSize: 24, fontWeight: FontWeight.w500, color: AppColorsNew.onSurface),

      // --- Title (sans) ---
      titleLarge: sans(fontSize: 22, fontWeight: FontWeight.w500, color: AppColorsNew.onSurface),
      titleMedium: sans(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.15, color: AppColorsNew.onSurface),
      titleSmall: sans(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1, color: AppColorsNew.onSurface),

      // --- Body (sans) ---
      bodyLarge: sans(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5, color: AppColorsNew.onSurface),
      bodyMedium: sans(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25, color: AppColorsNew.onSurface),
      bodySmall: sans(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4, color: AppColorsNew.onSurfaceVariant),

      // --- Label (sans) ---
      labelLarge: sans(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1, color: AppColorsNew.onSurface),
      labelMedium: sans(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: AppColorsNew.onSurface),
      labelSmall: sans(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: AppColorsNew.onSurfaceVariant),
    );
  }

  // ---------------------------------------------------------------------------
  // ColorScheme
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Main ThemeData
  // ---------------------------------------------------------------------------

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
}

abstract class AppSpacingNew {
  /// 0.5rem — tight cluster spacing
  static const double xs = 8.0;

  /// 1rem — standard tight cluster
  static const double sm = 16.0;

  /// 2rem — screen perimeter minimum padding
  static const double md = 32.0;

  /// 2.75rem — list item gap (scale 8)
  static const double lg = 44.0;

  /// 3.5rem — sectional break (scale 10)
  static const double xl = 56.0;
}
