import 'package:flutter/material.dart';

import 'app_spacing.dart';

/// Responsive helpers for wide layouts (tablets / desktop web).
abstract final class AppLayout {
  AppLayout._();

  static bool isWide(BuildContext context) {
    return MediaQuery.sizeOf(context).width > AppSpacing.wideBreakpoint;
  }

  /// Extra horizontal inset on large screens.
  static double horizontalPadding(BuildContext context) {
    return isWide(context) ? AppSpacing.xxxl + AppSpacing.md : AppSpacing.lg;
  }

  /// Slight type ramp-up on wide viewports.
  static double textScale(BuildContext context) {
    return isWide(context) ? 1.05 : 1.0;
  }

  static EdgeInsets pagePadding(BuildContext context) {
    final h = horizontalPadding(context);
    final v = isWide(context) ? AppSpacing.xxl : AppSpacing.lg;
    return EdgeInsets.symmetric(horizontal: h, vertical: v);
  }
}
