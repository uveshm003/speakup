import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';

import 'package:speakup/features/settings/domain/repositories/settings_repository.dart';

import 'theme_event.dart';
import 'theme_state.dart';

/// Drives [MaterialApp.themeMode]. System brightness is observed via
/// [ThemeBrightnessObserver] (WidgetsBinding), which dispatches
/// [ThemePlatformBrightnessChanged] while [ThemeMode.system] is active.
class ThemeBloc extends Bloc<ThemeBlocEvent, ThemeBlocState> {
  ThemeBloc({required SettingsRepository settingsRepository})
      : _settingsRepository = settingsRepository,
        super(const ThemeBlocState()) {
    on<ThemeLoadRequested>(_onLoad);
    on<ThemeModeChanged>(_onModeChanged);
    on<ThemePlatformBrightnessChanged>(_onPlatformBrightness);
    add(const ThemeLoadRequested());
  }

  final SettingsRepository _settingsRepository;

  Future<void> _onLoad(
    ThemeLoadRequested event,
    Emitter<ThemeBlocState> emit,
  ) async {
    final result = await _settingsRepository.getSettings();
    result.fold(
      (_) {},
      (settings) {
        emit(state.copyWith(mode: _modeFromRaw(settings.themeModeRaw)));
      },
    );
  }

  void _onModeChanged(
    ThemeModeChanged event,
    Emitter<ThemeBlocState> emit,
  ) {
    emit(state.copyWith(mode: event.mode));
  }

  void _onPlatformBrightness(
    ThemePlatformBrightnessChanged event,
    Emitter<ThemeBlocState> emit,
  ) {
    emit(state.copyWith(brightnessEpoch: state.brightnessEpoch + 1));
  }

  static ThemeMode _modeFromRaw(String raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
