import 'package:bloc/bloc.dart';

import 'package:speakup/features/practice/domain/entities/practice_session.dart';
import 'package:speakup/features/practice/domain/repositories/session_repository.dart';
import 'package:speakup/features/practice/presentation/models/practice_route_args.dart';
import 'package:speakup/features/settings/domain/repositories/settings_repository.dart';

import 'session_end_event.dart';
import 'session_end_state.dart';

class SessionEndBloc extends Bloc<SessionEndEvent, SessionEndState> {
  SessionEndBloc({required SessionRepository sessionRepository, required SettingsRepository settingsRepository, required SessionEndRouteArgs args})
    : _sessionRepository = sessionRepository,
      _settingsRepository = settingsRepository,
      _args = args,
      super(SessionEndState(card: args.card, elapsedSeconds: args.elapsedSeconds, wasCompleted: args.wasCompleted)) {
    on<SessionEndLoadRequested>(_onLoad);
    add(const SessionEndLoadRequested());
  }

  final SessionRepository _sessionRepository;
  final SettingsRepository _settingsRepository;
  final SessionEndRouteArgs _args;

  Future<void> _onLoad(SessionEndLoadRequested event, Emitter<SessionEndState> emit) async {
    emit(state.copyWith(status: SessionEndStatus.loading));

    final settingsBefore = await _settingsRepository.getSettings();
    final int streakBefore = settingsBefore.fold((_) => 0, (s) => s.currentStreak);

    final PracticeSession session = PracticeSession(
      sessionId: _sessionId(),
      cardId: _args.card.cardId,
      cardTitle: _args.card.title,
      category: _args.card.category,
      durationSeconds: _args.elapsedSeconds,
      wasCompleted: _args.wasCompleted,
      completedAt: DateTime.now(),
    );

    final saveResult = await _sessionRepository.saveSession(session);
    await saveResult.fold(
      (failure) async {
        emit(state.copyWith(status: SessionEndStatus.failure, errorMessage: failure.message ?? 'Could not save session'));
      },
      (_) async {
        await _settingsRepository.updateStreak();
        final settingsAfter = await _settingsRepository.getSettings();
        final int streak = settingsAfter.fold((_) => streakBefore, (s) => s.currentStreak);
        final bool increased = streak > streakBefore;

        final sessionsResult = await _sessionRepository.getAllSessions();
        final int weekCount = sessionsResult.fold(
          (_) => 0,
          (list) => _sessionsThisWeekCount(list.map((PracticeSession e) => e.completedAt).toList()),
        );

        emit(
          SessionEndState(
            status: SessionEndStatus.success,
            card: _args.card,
            elapsedSeconds: _args.elapsedSeconds,
            wasCompleted: _args.wasCompleted,
            streak: streak,
            streakIncreased: increased,
            weekSessionsCount: weekCount,
          ),
        );
      },
    );
  }

  String _sessionId() => 's_${DateTime.now().microsecondsSinceEpoch}_${_args.card.cardId}';

  static int _sessionsThisWeekCount(List<DateTime> completedAts) {
    final DateTime now = DateTime.now();
    final DateTime startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - DateTime.monday));
    int n = 0;
    for (final DateTime t in completedAts) {
      if (!t.isBefore(startOfWeek)) {
        n++;
      }
    }
    return n;
  }
}
