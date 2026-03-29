import 'package:flutter/material.dart';

import 'package:speakup/config/theme/app_layout.dart';
import 'package:speakup/config/theme/speakup_theme_extension.dart';

/// Opinionated [Scaffold] with SpeakUp background and responsive body padding.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.body,
    super.key,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.extendBody = false,
    this.resizeToAvoidBottomInset,
    this.fabLocation = FloatingActionButtonLocation.endFloat,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool extendBody;
  final bool? resizeToAvoidBottomInset;
  final FloatingActionButtonLocation fabLocation;

  @override
  Widget build(BuildContext context) {
    final SpeakUpThemeTokens? tokens = Theme.of(context).extension<SpeakUpThemeTokens>();
    final Color bg = tokens?.pageBackground ?? Theme.of(context).colorScheme.surfaceContainerLowest;

    final Widget paddedBody = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final EdgeInsets padding = AppLayout.pagePadding(context);
        return Padding(
          padding: padding,
          child: MediaQuery.withClampedTextScaling(minScaleFactor: 0.85, maxScaleFactor: AppLayout.isWide(context) ? 1.15 : 1.1, child: body),
        );
      },
    );

    return Scaffold(
      backgroundColor: bg,
      appBar: appBar,
      extendBody: extendBody,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: fabLocation,
      bottomNavigationBar: bottomNavigationBar != null ? _BottomBarShadow(child: bottomNavigationBar!) : null,
      body: paddedBody,
    );
  }
}

class _BottomBarShadow extends StatelessWidget {
  const _BottomBarShadow({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(elevation: 0, color: Theme.of(context).colorScheme.surface, child: child);
  }
}
