import 'dart:async';

import 'package:bloc/bloc.dart';

import 'package:speakup/features/practice/domain/entities/practice_session.dart';
import 'package:speakup/features/practice/domain/repositories/session_repository.dart';
import 'package:speakup/features/settings/domain/repositories/settings_repository.dart';

import 'history_event.dart';
import 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  HistoryBloc({
    required SessionRepository sessionRepository,
    required SettingsRepository settingsRepository,
  })  : _sessionRepository = sessionRepository,
        _settingsRepository = settingsRepository,
        super(const HistoryState()) {
    on<HistoryLoadRequested>(_onLoad);
    on<HistoryFilterChanged>(_onFilter);
    on<SessionDeleted>(_onSessionDelete);
    on<SessionDeleteUndoRequested>(_onDeleteUndo);
    on<SessionDeleteCommitted>(_onDeleteCommitted);
    add(const HistoryLoadRequested());
  }

  final SessionRepository _sessionRepository;
  final SettingsRepository _settingsRepository;
  Timer? _deleteTimer;

  Future<void> _onLoad(
    HistoryLoadRequested event,
    Emitter<HistoryState> emit,
  ) async {
    emit(state.copyWith(status: HistoryStatus.loading, clearErrorMessage: true));
    final sessionsResult = await _sessionRepository.getAllSessions();
    final settingsResult = await _settingsRepository.getSettings();
    await sessionsResult.fold(
      (failure) async {
        emit(
          state.copyWith(
            status: HistoryStatus.failure,
            errorMessage: failure.message ?? 'Could not load history',
          ),
        );
      },
      (List<PracticeSession> sessions) async {
        final int streak = settingsResult.fold(
          (_) => 0,
          (s) => s.currentStreak,
        );
        final int totalMin = _totalMinutes(sessions);
        emit(
          HistoryState(
            status: HistoryStatus.success,
            allSessions: sessions,
            filterRange: state.filterRange,
            currentStreak: streak,
            totalSessions: sessions.length,
            totalPracticeMinutes: totalMin,
          ),
        );
      },
    );
  }

  void _onFilter(
    HistoryFilterChanged event,
    Emitter<HistoryState> emit,
  ) {
    if (event.range == null) {
      emit(state.copyWith(clearFilterRange: true));
    } else {
      emit(state.copyWith(filterRange: event.range));
    }
  }

  Future<void> _onSessionDelete(
    SessionDeleted event,
    Emitter<HistoryState> emit,
  ) async {
    final int idx =
        state.allSessions.indexWhere((PracticeSession s) => s.sessionId == event.sessionId);
    if (idx < 0) {
      return;
    }
    final PracticeSession removed = state.allSessions[idx];
    _deleteTimer?.cancel();
    final List<PracticeSession> next = List<PracticeSession>.from(state.allSessions)
      ..removeAt(idx);
    emit(
      state.copyWith(
        allSessions: next,
        totalSessions: next.length,
        totalPracticeMinutes: _totalMinutes(next),
        pendingDeletion: removed,
        clearErrorMessage: true,
      ),
    );
    _deleteTimer = Timer(const Duration(seconds: 5), () {
      add(const SessionDeleteCommitted());
    });
  }

  void _onDeleteUndo(
    SessionDeleteUndoRequested event,
    Emitter<HistoryState> emit,
  ) {
    _deleteTimer?.cancel();
    _deleteTimer = null;
    final PracticeSession? s = state.pendingDeletion;
    if (s == null) {
      return;
    }
    final List<PracticeSession> next = List<PracticeSession>.from(state.allSessions)..add(s);
    next.sort(
      (PracticeSession a, PracticeSession b) =>
          b.completedAt.compareTo(a.completedAt),
    );
    emit(
      state.copyWith(
        allSessions: next,
        totalSessions: next.length,
        totalPracticeMinutes: _totalMinutes(next),
        clearPendingDeletion: true,
      ),
    );
  }

  Future<void> _onDeleteCommitted(
    SessionDeleteCommitted event,
    Emitter<HistoryState> emit,
  ) async {
    _deleteTimer?.cancel();
    _deleteTimer = null;
    final PracticeSession? s = state.pendingDeletion;
    if (s == null) {
      return;
    }
    final result = await _sessionRepository.deleteSession(s.sessionId);
    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            errorMessage: failure.message ?? 'Could not delete session',
            clearPendingDeletion: true,
          ),
        );
        add(const HistoryLoadRequested());
      },
      (_) async {
        emit(state.copyWith(clearPendingDeletion: true));
        await _settingsRepository.updateStreak();
        add(const HistoryLoadRequested());
      },
    );
  }

  static int _totalMinutes(List<PracticeSession> sessions) {
    final int sec = sessions.fold<int>(
      0,
      (int a, PracticeSession s) => a + s.durationSeconds,
    );
    return (sec / 60).round();
  }

  @override
  Future<void> close() {
    _deleteTimer?.cancel();
    return super.close();
  }
}
