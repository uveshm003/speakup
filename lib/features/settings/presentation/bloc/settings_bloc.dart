import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';

import 'package:speakup/config/router/router_refresh.dart';
import 'package:speakup/config/theme/bloc/theme_bloc.dart';
import 'package:speakup/config/theme/bloc/theme_event.dart' as theme_ev;
import 'package:speakup/features/history/presentation/bloc/history_bloc.dart';
import 'package:speakup/features/history/presentation/bloc/history_event.dart';
import 'package:speakup/features/practice/domain/repositories/session_repository.dart';
import 'package:speakup/features/settings/domain/entities/user_settings.dart';
import 'package:speakup/features/settings/domain/repositories/settings_repository.dart';

import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({
    required SettingsRepository settingsRepository,
    required SessionRepository sessionRepository,
    required ThemeBloc themeBloc,
    required HistoryBloc historyBloc,
  })  : _settingsRepository = settingsRepository,
        _sessionRepository = sessionRepository,
        _themeBloc = themeBloc,
        _historyBloc = historyBloc,
        super(const SettingsState()) {
    on<SettingsLoadRequested>(_onLoad);
    on<AppearanceThemeModeChanged>(_onThemeMode);
    on<DefaultTimerChanged>(_onDefaultTimer);
    on<TextScaleChanged>(_onTextScale);
    on<OnboardingResetRequested>(_onOnboardingReset);
    on<SessionHistoryClearRequested>(_onClearHistory);
    add(const SettingsLoadRequested());
  }

  final SettingsRepository _settingsRepository;
  final SessionRepository _sessionRepository;
  final ThemeBloc _themeBloc;
  final HistoryBloc _historyBloc;

  Future<void> _onLoad(
    SettingsLoadRequested event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(status: SettingsStatus.loading, clearErrorMessage: true));
    final result = await _settingsRepository.getSettings();
    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            status: SettingsStatus.failure,
            errorMessage: failure.message ?? 'Could not load settings',
          ),
        );
      },
      (UserSettings s) async {
        emit(state.copyWith(status: SettingsStatus.success, settings: s));
      },
    );
  }

  Future<void> _save(
    UserSettings next,
    Emitter<SettingsState> emit, {
    VoidCallback? afterSuccess,
  }) async {
    final result = await _settingsRepository.saveSettings(next);
    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            errorMessage: failure.message ?? 'Could not save',
          ),
        );
      },
      (_) async {
        emit(state.copyWith(settings: next, clearErrorMessage: true));
        afterSuccess?.call();
      },
    );
  }

  Future<void> _onThemeMode(
    AppearanceThemeModeChanged event,
    Emitter<SettingsState> emit,
  ) async {
    final String raw = switch (event.mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    };
    _themeBloc.add(theme_ev.ThemeModeChanged(event.mode));
    await _save(state.settings.copyWith(themeModeRaw: raw), emit);
  }

  Future<void> _onDefaultTimer(
    DefaultTimerChanged event,
    Emitter<SettingsState> emit,
  ) async {
    await _save(
      state.settings.copyWith(defaultTimerSeconds: event.seconds),
      emit,
    );
  }

  Future<void> _onTextScale(
    TextScaleChanged event,
    Emitter<SettingsState> emit,
  ) async {
    await _save(state.settings.copyWith(textSizeScale: event.scale), emit);
  }

  Future<void> _onOnboardingReset(
    OnboardingResetRequested event,
    Emitter<SettingsState> emit,
  ) async {
    await _save(
      state.settings.copyWith(hasSeenOnboarding: false),
      emit,
      afterSuccess: notifyAppRouterRefresh,
    );
  }

  Future<void> _onClearHistory(
    SessionHistoryClearRequested event,
    Emitter<SettingsState> emit,
  ) async {
    final result = await _sessionRepository.clearAllSessions();
    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            errorMessage: failure.message ?? 'Could not clear history',
          ),
        );
      },
      (_) async {
        await _settingsRepository.updateStreak();
        _historyBloc.add(const HistoryLoadRequested());
        add(const SettingsLoadRequested());
      },
    );
  }
}
