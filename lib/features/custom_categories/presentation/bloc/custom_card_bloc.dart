import 'dart:async';

import 'package:bloc/bloc.dart';

import 'package:speakup/features/card_draw/domain/entities/topic_card.dart';
import 'package:speakup/features/card_draw/domain/repositories/card_repository.dart';

import 'custom_card_event.dart';
import 'custom_card_state.dart';

class CustomCardBloc extends Bloc<CustomCardEvent, CustomCardState> {
  CustomCardBloc({required CardRepository cardRepository})
      : _cardRepository = cardRepository,
        super(const CustomCardState()) {
    on<CardsLoadRequested>(_onLoad);
    on<CardCreateRequested>(_onCreate);
    on<CardUpdateRequested>(_onUpdate);
    on<CardDeleteRequested>(_onDelete);
    on<CardDeleteUndoRequested>(_onDeleteUndo);
    on<CardDeleteCommitted>(_onDeleteCommitted);
  }

  final CardRepository _cardRepository;
  Timer? _deleteTimer;

  Future<void> _reload(Emitter<CustomCardState> emit) async {
    final String? id = state.categoryId;
    if (id == null) {
      return;
    }
    final result = await _cardRepository.getByCustomCategoryId(id);
    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            status: CustomCardStatus.failure,
            errorMessage: failure.message ?? 'Could not load cards',
          ),
        );
      },
      (List<TopicCard> list) async {
        emit(
          state.copyWith(
            status: CustomCardStatus.success,
            cards: list,
            clearErrorMessage: true,
          ),
        );
      },
    );
  }

  Future<void> _onLoad(
    CardsLoadRequested event,
    Emitter<CustomCardState> emit,
  ) async {
    emit(
      state.copyWith(
        status: CustomCardStatus.loading,
        categoryId: event.categoryId,
        clearErrorMessage: true,
      ),
    );
    final result = await _cardRepository.getByCustomCategoryId(event.categoryId);
    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            status: CustomCardStatus.failure,
            errorMessage: failure.message ?? 'Could not load cards',
          ),
        );
      },
      (List<TopicCard> list) async {
        emit(
          state.copyWith(
            status: CustomCardStatus.success,
            cards: list,
            categoryId: event.categoryId,
          ),
        );
      },
    );
  }

  Future<void> _onCreate(
    CardCreateRequested event,
    Emitter<CustomCardState> emit,
  ) async {
    final result = await _cardRepository.addCustomCard(event.card);
    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            errorMessage: failure.message ?? 'Could not save card',
          ),
        );
      },
      (_) async {
        await _reload(emit);
      },
    );
  }

  Future<void> _onUpdate(
    CardUpdateRequested event,
    Emitter<CustomCardState> emit,
  ) async {
    final result = await _cardRepository.updateCustomCard(event.card);
    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            errorMessage: failure.message ?? 'Could not update card',
          ),
        );
      },
      (_) async {
        await _reload(emit);
      },
    );
  }

  Future<void> _onDelete(
    CardDeleteRequested event,
    Emitter<CustomCardState> emit,
  ) async {
    final int idx =
        state.cards.indexWhere((TopicCard c) => c.cardId == event.cardId);
    if (idx < 0) {
      return;
    }
    final TopicCard card = state.cards[idx];
    _deleteTimer?.cancel();
    final List<TopicCard> next = state.cards
        .where((TopicCard c) => c.cardId != event.cardId)
        .toList();
    emit(
      state.copyWith(
        cards: next,
        pendingDeletion: card,
        clearErrorMessage: true,
      ),
    );
    _deleteTimer = Timer(const Duration(seconds: 5), () {
      add(const CardDeleteCommitted());
    });
  }

  void _onDeleteUndo(
    CardDeleteUndoRequested event,
    Emitter<CustomCardState> emit,
  ) {
    _deleteTimer?.cancel();
    _deleteTimer = null;
    final TopicCard? card = state.pendingDeletion;
    if (card == null) {
      return;
    }
    final List<TopicCard> next = List<TopicCard>.from(state.cards)..add(card);
    next.sort(
      (TopicCard a, TopicCard b) => b.createdAt.compareTo(a.createdAt),
    );
    emit(
      state.copyWith(
        cards: next,
        clearPendingDeletion: true,
      ),
    );
  }

  Future<void> _onDeleteCommitted(
    CardDeleteCommitted event,
    Emitter<CustomCardState> emit,
  ) async {
    _deleteTimer?.cancel();
    _deleteTimer = null;
    final TopicCard? card = state.pendingDeletion;
    if (card == null) {
      return;
    }
    final result = await _cardRepository.deleteCustomCard(card.cardId);
    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            errorMessage: failure.message ?? 'Could not delete card',
            clearPendingDeletion: true,
          ),
        );
        await _reload(emit);
      },
      (_) async {
        emit(state.copyWith(clearPendingDeletion: true));
      },
    );
  }

  @override
  Future<void> close() {
    _deleteTimer?.cancel();
    return super.close();
  }
}
