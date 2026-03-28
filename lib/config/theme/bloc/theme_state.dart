import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class ThemeBlocState extends Equatable {
  const ThemeBlocState({
    this.mode = ThemeMode.system,
    this.brightnessEpoch = 0,
  });

  final ThemeMode mode;

  /// Bumps when platform brightness changes under [ThemeMode.system] to rebuild UI.
  final int brightnessEpoch;

  ThemeBlocState copyWith({
    ThemeMode? mode,
    int? brightnessEpoch,
  }) {
    return ThemeBlocState(
      mode: mode ?? this.mode,
      brightnessEpoch: brightnessEpoch ?? this.brightnessEpoch,
    );
  }

  @override
  List<Object?> get props => <Object?>[mode, brightnessEpoch];
}
