import 'package:flutter/material.dart';

import 'package:speakup/config/theme/app_colors.dart';
import 'package:speakup/config/theme/app_layout.dart';
import 'package:speakup/config/theme/app_radius.dart';
import 'package:speakup/config/theme/app_spacing.dart';
import 'package:speakup/config/theme/speakup_theme_extension.dart';

enum SpeakUpDifficulty { beginner, intermediate, advanced }

/// Compact pill for level labels (Beginner / Intermediate / Advanced).
class DifficultyBadge extends StatelessWidget {
  const DifficultyBadge({
    required this.difficulty,
    super.key,
    this.compact = false,
  });

  final SpeakUpDifficulty difficulty;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    final SpeakUpThemeTokens? ext = Theme.of(context).extension<SpeakUpThemeTokens>();

    final ({Color fg, Color bg, String label}) spec = switch (difficulty) {
      SpeakUpDifficulty.beginner => (
          fg: ext?.difficultyBeginner ?? AppColors.beginner,
          bg: brightness == Brightness.light
              ? AppColors.successLight
              : AppColorsDark.successLight,
          label: 'Beginner',
        ),
      SpeakUpDifficulty.intermediate => (
          fg: ext?.difficultyIntermediate ?? AppColors.intermediate,
          bg: brightness == Brightness.light
              ? AppColors.warningLight
              : AppColorsDark.warningLight,
          label: 'Intermediate',
        ),
      SpeakUpDifficulty.advanced => (
          fg: ext?.difficultyAdvanced ?? AppColors.advanced,
          bg: brightness == Brightness.light
              ? AppColors.errorLight
              : AppColorsDark.errorLight,
          label: 'Advanced',
        ),
    };

    final TextStyle style = Theme.of(context).textTheme.labelMedium!.copyWith(
          color: spec.fg,
          fontWeight: FontWeight.w700,
          letterSpacing: compact ? 0.2 : 0.4,
          fontSize: (compact ? 11.0 : 12.0) * AppLayout.textScale(context),
        );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: compact ? AppSpacing.xs : AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: spec.bg.withValues(alpha: brightness == Brightness.dark ? 0.55 : 1),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: spec.fg.withValues(alpha: 0.25)),
      ),
      child: Text(
        spec.label.toUpperCase(),
        style: style,
      ),
    );
  }
}
