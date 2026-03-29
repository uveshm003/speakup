import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:speakup/config/theme/bloc/theme_bloc.dart';
import 'package:speakup/config/theme/bloc/theme_event.dart';

/// Dispatches [ThemePlatformBrightnessChanged] when system brightness changes
/// (used while [ThemeMode.system] is active so the tree can rebuild).
class ThemeBrightnessObserver extends StatefulWidget {
  const ThemeBrightnessObserver({super.key, required this.child});

  final Widget child;

  @override
  State<ThemeBrightnessObserver> createState() => _ThemeBrightnessObserverState();
}

class _ThemeBrightnessObserverState extends State<ThemeBrightnessObserver> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    final ThemeBloc bloc = context.read<ThemeBloc>();
    if (bloc.state.mode == ThemeMode.system) {
      bloc.add(const ThemePlatformBrightnessChanged());
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
