import 'package:flutter/material.dart';

import 'package:speakup/config/theme/app_layout.dart';
import 'package:speakup/config/theme/app_spacing.dart';

/// Empty / zero-state block: optional custom illustration, icon fallback, copy, CTA.
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({required this.title, super.key, this.subtitle, this.illustration, this.icon, this.action, this.iconSize = 56});

  /// Custom artwork (e.g. [SvgPicture] from assets) — takes precedence over [icon].
  final Widget? illustration;

  /// Used when [illustration] is null.
  final IconData? icon;

  final String title;
  final String? subtitle;
  final Widget? action;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool wide = AppLayout.isWide(context);
    final double scale = AppLayout.textScale(context);
    final double maxW = wide ? 420 : double.infinity;

    final Widget visual =
        illustration ??
        (icon != null
            ? Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5), shape: BoxShape.circle),
                child: Icon(icon, size: iconSize * scale, color: theme.colorScheme.primary),
              )
            : const SizedBox.shrink());

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: Padding(
              padding: EdgeInsets.all(wide ? AppSpacing.xxl : AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  visual,
                  SizedBox(height: wide ? AppSpacing.xl : AppSpacing.lg),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(fontSize: (theme.textTheme.headlineMedium?.fontSize ?? 18) * scale),
                  ),
                  if (subtitle != null) ...<Widget>[
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      subtitle!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 14) * scale,
                      ),
                    ),
                  ],
                  if (action != null) ...<Widget>[SizedBox(height: wide ? AppSpacing.xl : AppSpacing.lg), action!],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
