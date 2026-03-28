import 'package:flutter/material.dart';

enum ScreenSize { mobile, tablet, desktop }

/// Breakpoints: mobile &lt; 600, tablet 600–1024, desktop &gt; 1024.
abstract final class Responsive {
  Responsive._();

  static const double _mobileMax = 600;
  static const double _tabletMax = 1024;

  static ScreenSize of(BuildContext context) {
    final double w = MediaQuery.sizeOf(context).width;
    if (w < _mobileMax) {
      return ScreenSize.mobile;
    }
    if (w <= _tabletMax) {
      return ScreenSize.tablet;
    }
    return ScreenSize.desktop;
  }

  static bool isMobile(BuildContext context) {
    return of(context) == ScreenSize.mobile;
  }

  static bool isTablet(BuildContext context) {
    return of(context) == ScreenSize.tablet;
  }

  static bool isDesktop(BuildContext context) {
    return of(context) == ScreenSize.desktop;
  }
}
