import 'package:flutter/material.dart';

import 'package:speakup/config/theme/app_layout.dart';
import 'package:speakup/config/theme/app_radius.dart';
import 'package:speakup/config/theme/app_shadows.dart';
import 'package:speakup/config/theme/app_spacing.dart';
import 'package:speakup/config/theme/speakup_theme_extension.dart';

/// Elevated surface with SpeakUp shadow, radius, and responsive padding.
class AppCard extends StatelessWidget {
  const AppCard({required this.child, super.key, this.onTap, this.padding, this.margin});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final SpeakUpThemeTokens? tokens = Theme.of(context).extension<SpeakUpThemeTokens>();
    final Color bg = tokens?.cardBackground ?? Theme.of(context).colorScheme.surface;
    final Color borderColor = tokens?.border ?? Theme.of(context).colorScheme.outline;
    final double pad = AppLayout.isWide(context) ? AppSpacing.xl : AppSpacing.lg;

    final Widget inner = Padding(padding: padding ?? EdgeInsets.all(pad), child: child);

    final Widget decorated = DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor.withValues(alpha: 0.85)),
        boxShadow: AppShadows.card(context),
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(AppRadius.lg), child: inner),
    );

    if (onTap == null) {
      return Padding(padding: margin ?? EdgeInsets.zero, child: decorated);
    }

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(AppRadius.lg), child: decorated),
      ),
    );
  }
}
