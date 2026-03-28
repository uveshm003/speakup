import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

sealed class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

final class SettingsLoadRequested extends SettingsEvent {
  const SettingsLoadRequested();
}

final class AppearanceThemeModeChanged extends SettingsEvent {
  const AppearanceThemeModeChanged(this.mode);

  final ThemeMode mode;

  @override
  List<Object?> get props => <Object?>[mode];
}

final class DefaultTimerChanged extends SettingsEvent {
  const DefaultTimerChanged(this.seconds);

  final int seconds;

  @override
  List<Object?> get props => <Object?>[seconds];
}

final class TextScaleChanged extends SettingsEvent {
  const TextScaleChanged(this.scale);

  final double scale;

  @override
  List<Object?> get props => <Object?>[scale];
}

final class OnboardingResetRequested extends SettingsEvent {
  const OnboardingResetRequested();
}

final class SessionHistoryClearRequested extends SettingsEvent {
  const SessionHistoryClearRequested();
}
