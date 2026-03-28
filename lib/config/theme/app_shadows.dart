import 'package:flutter/material.dart';

/// Soft, agency-style elevation (avoid harsh Material defaults).
abstract final class AppShadows {
  AppShadows._();

  static List<BoxShadow> card(BuildContext context) {
    return <BoxShadow>[
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 24,
        offset: const Offset(0, 8),
        spreadRadius: 0,
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 6,
        offset: const Offset(0, 2),
        spreadRadius: 0,
      ),
    ];
  }

  static List<BoxShadow> button(BuildContext context) {
    return <BoxShadow>[
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.12),
        blurRadius: 16,
        offset: const Offset(0, 6),
        spreadRadius: -2,
      ),
    ];
  }

  static List<BoxShadow> overlayBar(BuildContext context) {
    return <BoxShadow>[
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.08),
        blurRadius: 32,
        offset: const Offset(0, -4),
        spreadRadius: 0,
      ),
    ];
  }
}
