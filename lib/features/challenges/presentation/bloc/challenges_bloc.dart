import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:speakup/features/card_draw/domain/entities/topic_card.dart';
import 'package:speakup/features/card_draw/domain/repositories/card_repository.dart';
import 'package:speakup/features/challenges/domain/built_in_challenges.dart';
import 'package:speakup/features/challenges/domain/entities/challenge_def.dart';
import 'package:speakup/features/challenges/domain/entities/challenge_progress.dart';
import 'package:speakup/features/challenges/domain/repositories/challenge_repository.dart';

import 'challenges_event.dart';
import 'challenges_state.dart';

class ChallengesBloc extends Bloc<ChallengesEvent, ChallengesState> {
  ChallengesBloc({required ChallengeRepository challengeRepository, required CardRepository cardRepository})
    : _repo = challengeRepository,
      _cardRepo = cardRepository,
      super(const ChallengesState()) {
    on<ChallengesLoadRequested>(_onLoad);
    on<ChallengeEnrolRequested>(_onEnrol);
    on<ChallengeDayCompleted>(_onDayComplete);
    on<ChallengeAbandoned>(_onAbandon);
    add(const ChallengesLoadRequested());
  }

  final ChallengeRepository _repo;
  final CardRepository _cardRepo;

  Future<void> _onLoad(ChallengesLoadRequested event, Emitter<ChallengesState> emit) async {
    emit(state.copyWith(status: ChallengesStatus.loading, clearError: true));
    final result = await _repo.getAllProgress();
    result.fold(
      (failure) => emit(state.copyWith(status: ChallengesStatus.failure, errorMessage: failure.message ?? 'Could not load challenges')),
      (Map<String, ChallengeProgress> progress) => emit(state.copyWith(status: ChallengesStatus.success, progress: progress)),
    );
  }

  Future<void> _onEnrol(ChallengeEnrolRequested event, Emitter<ChallengesState> emit) async {
    final ChallengeDef def = kBuiltInChallenges.firstWhere(
      (ChallengeDef c) => c.id == event.challengeId,
      orElse: () => throw Exception('Challenge not found'),
    );

    final cardResult = def.category != null ? await _cardRepo.getByCategory(def.category!) : await _cardRepo.getAll();

    final Map<String, String> dailyPrompts = <String, String>{};

    cardResult.fold(
      (failure) {}, // Fallback: enrol with empty map if cards fail to load
      (List<TopicCard> cards) {
        if (cards.isNotEmpty) {
          final Random rnd = Random();
          final List<TopicCard> shuffled = List<TopicCard>.from(cards)..shuffle(rnd);
          for (int i = 0; i < def.durationDays; i++) {
            dailyPrompts[i.toString()] = shuffled[i % shuffled.length].cardId;
          }
        }
      },
    );

    final result = await _repo.enrol(event.challengeId, dailyPromptIds: dailyPrompts);
    result.fold((failure) => emit(state.copyWith(errorMessage: failure.message ?? 'Could not enrol')), (_) => add(const ChallengesLoadRequested()));
  }

  Future<void> _onDayComplete(ChallengeDayCompleted event, Emitter<ChallengesState> emit) async {
    final result = await _repo.markDayComplete(event.challengeId, event.day, event.totalDays);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message ?? 'Could not save progress')),
      (_) => add(const ChallengesLoadRequested()),
    );
  }

  Future<void> _onAbandon(ChallengeAbandoned event, Emitter<ChallengesState> emit) async {
    final result = await _repo.abandon(event.challengeId);
    result.fold((failure) => emit(state.copyWith(errorMessage: failure.message ?? 'Could not abandon')), (_) => add(const ChallengesLoadRequested()));
  }
}
