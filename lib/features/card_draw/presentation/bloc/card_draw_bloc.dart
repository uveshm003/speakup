import 'dart:math';

import 'package:bloc/bloc.dart';

import 'package:speakup/features/card_draw/domain/entities/difficulty.dart';
import 'package:speakup/features/card_draw/domain/entities/topic_card.dart';
import 'package:speakup/features/card_draw/domain/repositories/card_repository.dart';

import 'card_draw_event.dart';
import 'card_draw_state.dart';

class CardDrawBloc extends Bloc<CardDrawEvent, CardDrawState> {
  CardDrawBloc({required CardRepository cardRepository})
      : _cardRepository = cardRepository,
        super(const CardDrawState()) {
    on<CardDrawRequested>(_onDrawRequested);
    on<CardRedrawRequested>(_onRedrawRequested);
    on<CardFavoriteToggled>(_onFavoriteToggled);
    on<CardDrawFlipPhaseChanged>(_onFlipPhaseChanged);
  }

  final CardRepository _cardRepository;
  final Random _random = Random();

  String? _category;
  Difficulty? _difficulty;

  Future<void> _onDrawRequested(
    CardDrawRequested event,
    Emitter<CardDrawState> emit,
  ) async {
    _category = event.category;
    _difficulty = event.difficulty;
    await _draw(emit);
  }

  Future<void> _onRedrawRequested(
    CardRedrawRequested event,
    Emitter<CardDrawState> emit,
  ) async {
    await _draw(emit);
  }

  Future<void> _draw(Emitter<CardDrawState> emit) async {
    emit(
      state.copyWith(
        status: CardDrawStatus.loading,
        clearErrorMessage: true,
      ),
    );

    final result = await _cardRepository.getAll();
    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            status: CardDrawStatus.failure,
            errorMessage: failure.message ?? 'Could not load cards',
            filterCategory: _category,
            filterDifficulty: _difficulty,
          ),
        );
      },
      (List<TopicCard> all) async {
        final TopicCard? picked = _pickRandom(all, _category, _difficulty);
        if (picked == null) {
          emit(
            state.copyWith(
              status: CardDrawStatus.empty,
              clearCard: true,
              errorMessage: 'No cards match these filters',
              filterCategory: _category,
              filterDifficulty: _difficulty,
            ),
          );
          return;
        }
        emit(
          CardDrawState(
            status: CardDrawStatus.success,
            currentCard: picked,
            isAnimating: false,
            isFavorite: picked.isFavorite,
            drawCount: state.drawCount + 1,
            filterCategory: _category,
            filterDifficulty: _difficulty,
          ),
        );
      },
    );
  }

  TopicCard? _pickRandom(
    List<TopicCard> all,
    String? categoryFilter,
    Difficulty? difficultyFilter,
  ) {
    List<TopicCard> pool = List<TopicCard>.from(all);
    if (categoryFilter != null && categoryFilter.isNotEmpty) {
      if (categoryFilter.startsWith('custom:')) {
        final String id = categoryFilter.substring('custom:'.length);
        pool = pool
            .where((TopicCard c) => c.customCategoryId == id)
            .toList();
      } else {
        pool = pool
            .where(
              (TopicCard c) =>
                  !c.isCustom && c.category == categoryFilter,
            )
            .toList();
      }
    }
    if (difficultyFilter != null) {
      pool =
          pool.where((TopicCard c) => c.difficulty == difficultyFilter).toList();
    }
    if (pool.isEmpty) {
      return null;
    }
    return pool[_random.nextInt(pool.length)];
  }

  Future<void> _onFavoriteToggled(
    CardFavoriteToggled event,
    Emitter<CardDrawState> emit,
  ) async {
    final TopicCard? current = state.currentCard;
    if (current == null || current.cardId != event.cardId) {
      return;
    }
    final result = await _cardRepository.toggleFavorite(event.cardId);
    result.fold(
      (_) {},
      (TopicCard updated) {
        emit(
          state.copyWith(
            currentCard: updated,
            isFavorite: updated.isFavorite,
          ),
        );
      },
    );
  }

  void _onFlipPhaseChanged(
    CardDrawFlipPhaseChanged event,
    Emitter<CardDrawState> emit,
  ) {
    emit(state.copyWith(isAnimating: event.isAnimating));
  }
}
