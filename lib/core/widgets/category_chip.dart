import 'package:flutter/material.dart';

import 'package:speakup/config/theme/app_layout.dart';
import 'package:speakup/config/theme/app_spacing.dart';

/// Filter-style chip with leading icon and selection state.
class CategoryChip extends StatelessWidget {
  const CategoryChip({required this.icon, required this.label, super.key, this.selected = false, this.onSelected});

  final IconData icon;
  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool wide = AppLayout.isWide(context);

    return FilterChip(
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
      avatar: Icon(icon, size: wide ? 20 : 18, color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
      label: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(fontSize: (13 * AppLayout.textScale(context)), fontWeight: FontWeight.w600, letterSpacing: 0.2),
      ),
      labelPadding: EdgeInsets.symmetric(horizontal: wide ? AppSpacing.sm : AppSpacing.xs),
      padding: EdgeInsets.symmetric(horizontal: wide ? AppSpacing.md : AppSpacing.sm, vertical: AppSpacing.xs),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
