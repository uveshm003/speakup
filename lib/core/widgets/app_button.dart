import 'package:flutter/material.dart';

import 'package:speakup/config/theme/app_layout.dart';
import 'package:speakup/config/theme/app_radius.dart';
import 'package:speakup/config/theme/app_spacing.dart';

enum AppButtonVariant { primary, secondary, ghost }

/// Primary / secondary / ghost actions with loading and full-width options.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    super.key,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.fullWidth = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool fullWidth;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool wide = AppLayout.isWide(context);
    final double hPad = wide ? AppSpacing.xl : AppSpacing.lg;

    final VoidCallback? effectiveOnPressed =
        isLoading ? null : onPressed;

    final Widget content = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (isLoading) ...<Widget>[
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: variant == AppButtonVariant.primary
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.primary,
            ),
          ),
          SizedBox(width: wide ? AppSpacing.sm : AppSpacing.xs),
        ] else if (icon != null) ...<Widget>[
          IconTheme.merge(
            data: IconThemeData(
              size: 20,
              color: variant == AppButtonVariant.primary
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.primary,
            ),
            child: icon!,
          ),
          SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );

    final Widget button = switch (variant) {
      AppButtonVariant.primary => ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            minimumSize: fullWidth ? const Size(double.infinity, 48) : null,
            padding: EdgeInsets.symmetric(horizontal: hPad),
          ),
          child: content,
        ),
      AppButtonVariant.secondary => OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: fullWidth ? const Size(double.infinity, 48) : null,
            padding: EdgeInsets.symmetric(horizontal: hPad),
            side: BorderSide(color: theme.colorScheme.primary, width: 1.5),
            foregroundColor: theme.colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
          ),
          child: DefaultTextStyle.merge(
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
            child: content,
          ),
        ),
      AppButtonVariant.ghost => TextButton(
          onPressed: effectiveOnPressed,
          style: TextButton.styleFrom(
            minimumSize: fullWidth ? const Size(double.infinity, 48) : null,
            padding: EdgeInsets.symmetric(horizontal: hPad),
          ),
          child: DefaultTextStyle.merge(
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
            child: content,
          ),
        ),
    };

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (fullWidth) {
          return SizedBox(width: constraints.maxWidth, child: button);
        }
        return button;
      },
    );
  }
}
