import 'package:flutter/material.dart';

import 'package:speakup/config/theme/app_layout.dart';
import 'package:speakup/config/theme/app_spacing.dart';

/// Section heading with optional trailing action (text button, icon, etc.).
class SectionTitle extends StatelessWidget {
  const SectionTitle({required this.title, super.key, this.trailing, this.subtitle});

  final String title;
  final Widget? trailing;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool wide = AppLayout.isWide(context);
    final double scale = AppLayout.textScale(context);

    final TextStyle titleStyle = theme.textTheme.headlineMedium!.copyWith(fontSize: (theme.textTheme.headlineMedium?.fontSize ?? 18) * scale);

    final Widget titleRow = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: titleStyle),
              if (subtitle != null) ...<Widget>[
                SizedBox(height: wide ? AppSpacing.xs : AppSpacing.xs / 2),
                Text(subtitle!, style: theme.textTheme.bodyMedium?.copyWith(fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 14) * scale)),
              ],
            ],
          ),
        ),
        if (trailing != null) ...<Widget>[SizedBox(width: AppSpacing.md), trailing!],
      ],
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        return Padding(
          padding: EdgeInsets.only(bottom: wide ? AppSpacing.md : AppSpacing.sm),
          child: titleRow,
        );
      },
    );
  }
}
