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

abstract class AppColorsNew {
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

  static const Color tertiary = Color(0xFF002183);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFDDE1FF);
  static const Color onTertiaryContainer = Color(0xFF00105C);

  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF410002);
  static const Color surface = Color(0xFFFBF9F5);
  static const Color onSurface = Color(0xFF1B1C1A); // never pure black
  static const Color surfaceVariant = Color(0xFFDEE5E0);
  static const Color onSurfaceVariant = Color(0xFF424842);

  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF5F3EF);
  static const Color surfaceContainer = Color(0xFFEFEEEA);
  static const Color surfaceContainerHigh = Color(0xFFEAE8E4);
  static const Color surfaceContainerHighest = Color(0xFFE4E2DE);

  static const Color outline = Color(0xFF72796F);
  static const Color outlineVariant = Color(0xFFBFC8C8); // at 15% = ghost border

  static const Color inverseSurface = Color(0xFF2F3130);
  static const Color onInverseSurface = Color(0xFFF1F1EC);
  static const Color inversePrimary = Color(0xFF62DBC4);
  static const Color scrim = Color(0xFF000000);
  static const Color shadow = Color(0xFF1B1C1A);

  static const Color glassBackground = Color(0xCCFBF9F5); // surface @ 80%

  static const LinearGradient primaryButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryContainer],
  );

  static List<BoxShadow> get ambientShadow => [BoxShadow(color: shadow.withOpacity(0.06), blurRadius: 24, spreadRadius: -4)];
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
