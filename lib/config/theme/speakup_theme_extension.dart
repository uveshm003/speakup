import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Extra tokens available via `Theme.of(context).extension<SpeakUpThemeTokens>()`.
@immutable
class SpeakUpThemeTokens extends ThemeExtension<SpeakUpThemeTokens> {
  const SpeakUpThemeTokens({
    required this.difficultyBeginner,
    required this.difficultyIntermediate,
    required this.difficultyAdvanced,
    required this.cardBackground,
    required this.pageBackground,
    required this.border,
    required this.borderStrong,
  });

  final Color difficultyBeginner;
  final Color difficultyIntermediate;
  final Color difficultyAdvanced;
  final Color cardBackground;
  final Color pageBackground;
  final Color border;
  final Color borderStrong;

  static const SpeakUpThemeTokens light = SpeakUpThemeTokens(
    difficultyBeginner: AppColors.beginner,
    difficultyIntermediate: AppColors.intermediate,
    difficultyAdvanced: AppColors.advanced,
    cardBackground: AppColors.cardBackground,
    pageBackground: AppColors.background,
    border: AppColors.border,
    borderStrong: AppColors.borderStrong,
  );

  static const SpeakUpThemeTokens dark = SpeakUpThemeTokens(
    difficultyBeginner: AppColorsDark.beginner,
    difficultyIntermediate: AppColorsDark.intermediate,
    difficultyAdvanced: AppColorsDark.advanced,
    cardBackground: AppColorsDark.cardBackground,
    pageBackground: AppColorsDark.background,
    border: AppColorsDark.border,
    borderStrong: AppColorsDark.borderStrong,
  );

  @override
  SpeakUpThemeTokens copyWith({
    Color? difficultyBeginner,
    Color? difficultyIntermediate,
    Color? difficultyAdvanced,
    Color? cardBackground,
    Color? pageBackground,
    Color? border,
    Color? borderStrong,
  }) {
    return SpeakUpThemeTokens(
      difficultyBeginner: difficultyBeginner ?? this.difficultyBeginner,
      difficultyIntermediate: difficultyIntermediate ?? this.difficultyIntermediate,
      difficultyAdvanced: difficultyAdvanced ?? this.difficultyAdvanced,
      cardBackground: cardBackground ?? this.cardBackground,
      pageBackground: pageBackground ?? this.pageBackground,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
    );
  }

  @override
  SpeakUpThemeTokens lerp(ThemeExtension<SpeakUpThemeTokens>? other, double t) {
    if (other is! SpeakUpThemeTokens) {
      return this;
    }
    return SpeakUpThemeTokens(
      difficultyBeginner:
          Color.lerp(difficultyBeginner, other.difficultyBeginner, t)!,
      difficultyIntermediate:
          Color.lerp(difficultyIntermediate, other.difficultyIntermediate, t)!,
      difficultyAdvanced:
          Color.lerp(difficultyAdvanced, other.difficultyAdvanced, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      pageBackground: Color.lerp(pageBackground, other.pageBackground, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
    );
  }
}
