import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

sealed class ThemeBlocEvent extends Equatable {
  const ThemeBlocEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

final class ThemeLoadRequested extends ThemeBlocEvent {
  const ThemeLoadRequested();
}

final class ThemeModeChanged extends ThemeBlocEvent {
  const ThemeModeChanged(this.mode);

  final ThemeMode mode;

  @override
  List<Object?> get props => <Object?>[mode];
}

/// Internal: platform brightness changed while using [ThemeMode.system].
final class ThemePlatformBrightnessChanged extends ThemeBlocEvent {
  const ThemePlatformBrightnessChanged();
}
