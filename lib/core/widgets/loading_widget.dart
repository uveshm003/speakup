import 'package:flutter/material.dart';

import 'package:speakup/config/theme/app_layout.dart';
import 'package:speakup/config/theme/app_spacing.dart';

/// Centered branded progress indicator for async surfaces.
class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool wide = AppLayout.isWide(context);
    final double scale = AppLayout.textScale(context);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                width: wide ? 40 : 32,
                height: wide ? 40 : 32,
                child: CircularProgressIndicator(strokeWidth: 3, color: theme.colorScheme.primary),
              ),
              if (message != null) ...<Widget>[
                SizedBox(height: wide ? AppSpacing.lg : AppSpacing.md),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppLayout.horizontalPadding(context)),
                  child: Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 14) * scale,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
