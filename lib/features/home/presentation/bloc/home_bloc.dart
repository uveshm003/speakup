import 'package:bloc/bloc.dart';

import 'package:speakup/features/card_draw/domain/entities/topic_card.dart';
import 'package:speakup/features/card_draw/domain/repositories/card_repository.dart';
import 'package:speakup/features/home/domain/built_in_categories.dart';
import 'package:speakup/features/practice/domain/entities/practice_session.dart';
import 'package:speakup/features/practice/domain/repositories/session_repository.dart';
import 'package:speakup/features/settings/domain/repositories/settings_repository.dart';

import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({
    required CardRepository cardRepository,
    required SessionRepository sessionRepository,
    required SettingsRepository settingsRepository,
  })  : _cardRepository = cardRepository,
        _sessionRepository = sessionRepository,
        _settingsRepository = settingsRepository,
        super(const HomeState()) {
    on<HomeLoadRequested>(_onLoadRequested);
    on<HomeQuickDrawRequested>(_onQuickDrawRequested);
    on<HomeQuickDrawNavigationConsumed>(_onQuickDrawConsumed);
  }

  final CardRepository _cardRepository;
  final SessionRepository _sessionRepository;
  final SettingsRepository _settingsRepository;

  Future<void> _onLoadRequested(
    HomeLoadRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(
      state.copyWith(
        status: HomeLoadStatus.loading,
        clearErrorMessage: true,
      ),
    );

    await _settingsRepository.updateStreak();

    final sessionsEither = await _sessionRepository.getAllSessions();
    final cardsEither = await _cardRepository.getAll();
    final settingsEither = await _settingsRepository.getSettings();

    String? failureMessage;
    sessionsEither.fold((l) => failureMessage ??= l.message, (_) {});
    cardsEither.fold((l) => failureMessage ??= l.message, (_) {});
    settingsEither.fold((l) => failureMessage ??= l.message, (_) {});

    if (failureMessage != null) {
      emit(
        state.copyWith(
          status: HomeLoadStatus.failure,
          errorMessage: failureMessage,
        ),
      );
      return;
    }

    final List<PracticeSession> sessions =
        sessionsEither.fold((l) => throw StateError(''), (r) => r);
    final List<TopicCard> cards =
        cardsEither.fold((l) => throw StateError(''), (r) => r);
    final settings =
        settingsEither.fold((l) => throw StateError(''), (r) => r);
    sessions.sort(
      (PracticeSession a, PracticeSession b) =>
          b.completedAt.compareTo(a.completedAt),
    );

    final DateTime now = DateTime.now();
    final DateTime startOfDay = DateTime(now.year, now.month, now.day);
    final DateTime endOfDay = startOfDay.add(const Duration(days: 1));
    final int todayCount = sessions
        .where(
          (PracticeSession s) =>
              !s.completedAt.isBefore(startOfDay) &&
              s.completedAt.isBefore(endOfDay),
        )
        .length;

    final Set<String> seen = <String>{};
    final List<String> recentCategories = <String>[];
    for (final PracticeSession s in sessions) {
      if (seen.add(s.category)) {
        recentCategories.add(s.category);
      }
      if (recentCategories.length >= 3) {
        break;
      }
    }

    final Map<String, int> counts = <String, int>{};
    for (final BuiltInCategoryDef def in kBuiltInBrowseCategories) {
      counts[def.name] = cards
          .where(
            (TopicCard c) => !c.isCustom && c.category == def.name,
          )
          .length;
    }

    final int customCount = cards.where((TopicCard c) => c.isCustom).length;

    final List<HomeRecentSession> recent = sessions
        .take(3)
        .map(
          (PracticeSession s) => HomeRecentSession(
            sessionId: s.sessionId,
            cardId: s.cardId,
            cardTitle: s.cardTitle,
            completedAt: s.completedAt,
            durationSeconds: s.durationSeconds,
          ),
        )
        .toList();

    emit(
      state.copyWith(
        status: HomeLoadStatus.success,
        streak: settings.currentStreak,
        lastSessionDate: settings.lastSessionDate,
        recentCategories: recentCategories,
        todaySessionCount: todayCount,
        categoryCardCounts: counts,
        customCardsCount: customCount,
        recentSessions: recent,
        clearErrorMessage: true,
      ),
    );
  }

  void _onQuickDrawRequested(
    HomeQuickDrawRequested event,
    Emitter<HomeState> emit,
  ) {
    if (state.status != HomeLoadStatus.success) {
      return;
    }
    emit(state.copyWith(pendingQuickDrawNavigation: true));
  }

  void _onQuickDrawConsumed(
    HomeQuickDrawNavigationConsumed event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(pendingQuickDrawNavigation: false));
  }
}
