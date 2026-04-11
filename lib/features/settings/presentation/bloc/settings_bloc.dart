import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:speakup/core/services/db_management_service.dart';
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
    required HistoryBloc historyBloc,
    DbManagementService? dbManagementService,
  }) : _settingsRepository = settingsRepository,
       _sessionRepository = sessionRepository,
       _historyBloc = historyBloc,
       _dbService = dbManagementService,
       super(const SettingsState()) {
    on<SettingsLoadRequested>(_onLoad);
    on<DefaultTimerChanged>(_onDefaultTimer);
    on<SessionHistoryClearRequested>(_onClearHistory);
    on<DatabaseExportRequested>(_onExport);
    on<DatabaseRestoreRequested>(_onRestore);
    on<DatabaseDeleteRequested>(_onDeleteAll);
    add(const SettingsLoadRequested());
  }

  final SettingsRepository _settingsRepository;
  final SessionRepository _sessionRepository;
  final HistoryBloc _historyBloc;
  final DbManagementService? _dbService;

  Future<void> _onLoad(SettingsLoadRequested event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(status: SettingsStatus.loading, clearErrorMessage: true));
    final result = await _settingsRepository.getSettings();
    await result.fold(
      (failure) async {
        emit(state.copyWith(status: SettingsStatus.failure, errorMessage: failure.message ?? 'Could not load settings'));
      },
      (UserSettings s) async {
        emit(state.copyWith(status: SettingsStatus.success, settings: s));
      },
    );
  }

  Future<void> _save(UserSettings next, Emitter<SettingsState> emit, {VoidCallback? afterSuccess}) async {
    final result = await _settingsRepository.saveSettings(next);
    await result.fold(
      (failure) async {
        emit(state.copyWith(errorMessage: failure.message ?? 'Could not save'));
      },
      (_) async {
        emit(state.copyWith(settings: next, clearErrorMessage: true));
        afterSuccess?.call();
      },
    );
  }

  Future<void> _onDefaultTimer(DefaultTimerChanged event, Emitter<SettingsState> emit) async {
    await _save(state.settings.copyWith(defaultTimerSeconds: event.seconds), emit);
  }

  Future<void> _onClearHistory(SessionHistoryClearRequested event, Emitter<SettingsState> emit) async {
    final result = await _sessionRepository.clearAllSessions();
    await result.fold(
      (failure) async {
        emit(state.copyWith(errorMessage: failure.message ?? 'Could not clear history'));
      },
      (_) async {
        await _settingsRepository.updateStreak();
        _historyBloc.add(const HistoryLoadRequested());
        add(const SettingsLoadRequested());
      },
    );
  }

  Future<void> _onExport(DatabaseExportRequested event, Emitter<SettingsState> emit) async {
    if (_dbService == null) {
      emit(state.copyWith(dbActionStatus: DbActionStatus.failure, dbActionMessage: 'Export not available on this platform'));
      return;
    }
    emit(state.copyWith(dbActionStatus: DbActionStatus.loading, activeDbAction: DbAction.export, clearDbActionMessage: true));
    final result = await _dbService.exportAndShare();
    result.fold(
      (failure) => emit(
        state.copyWith(dbActionStatus: DbActionStatus.failure, clearActiveDbAction: true, dbActionMessage: failure.message ?? 'Export failed'),
      ),
      (_) => emit(state.copyWith(dbActionStatus: DbActionStatus.success, clearActiveDbAction: true, dbActionMessage: 'Data exported successfully')),
    );
  }

  Future<void> _onRestore(DatabaseRestoreRequested event, Emitter<SettingsState> emit) async {
    if (_dbService == null) {
      emit(state.copyWith(dbActionStatus: DbActionStatus.failure, dbActionMessage: 'Restore not available on this platform'));
      return;
    }
    emit(state.copyWith(dbActionStatus: DbActionStatus.loading, activeDbAction: DbAction.restore, clearDbActionMessage: true));
    final result = await _dbService.restoreFromFile(event.filePath);
    result.fold(
      (failure) => emit(
        state.copyWith(dbActionStatus: DbActionStatus.failure, clearActiveDbAction: true, dbActionMessage: failure.message ?? 'Restore failed'),
      ),
      (_) {
        _historyBloc.add(const HistoryLoadRequested());
        emit(state.copyWith(dbActionStatus: DbActionStatus.success, clearActiveDbAction: true, dbActionMessage: 'Data restored successfully'));
      },
    );
  }

  Future<void> _onDeleteAll(DatabaseDeleteRequested event, Emitter<SettingsState> emit) async {
    if (_dbService == null) {
      emit(state.copyWith(dbActionStatus: DbActionStatus.failure, dbActionMessage: 'Delete not available on this platform'));
      return;
    }
    emit(state.copyWith(dbActionStatus: DbActionStatus.loading, activeDbAction: DbAction.delete, clearDbActionMessage: true));
    final result = await _dbService.deleteAll();
    result.fold(
      (failure) => emit(
        state.copyWith(dbActionStatus: DbActionStatus.failure, clearActiveDbAction: true, dbActionMessage: failure.message ?? 'Delete failed'),
      ),
      (_) {
        _historyBloc.add(const HistoryLoadRequested());
        add(const SettingsLoadRequested());
        emit(state.copyWith(dbActionStatus: DbActionStatus.success, clearActiveDbAction: true, dbActionMessage: 'All data deleted'));
      },
    );
  }
}
