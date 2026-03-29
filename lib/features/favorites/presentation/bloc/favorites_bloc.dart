import 'package:bloc/bloc.dart';

import 'package:speakup/features/card_draw/domain/entities/topic_card.dart';
import 'package:speakup/features/card_draw/domain/repositories/card_repository.dart';

import 'favorites_event.dart';
import 'favorites_state.dart';

class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  FavoritesBloc({required CardRepository cardRepository}) : _cardRepository = cardRepository, super(const FavoritesState()) {
    on<FavoritesLoadRequested>(_onLoad);
    on<FavoriteRemoved>(_onRemove);
    on<FavoriteDrawRequested>(_onDrawRequested);
    add(const FavoritesLoadRequested());
  }

  final CardRepository _cardRepository;

  Future<void> _onLoad(FavoritesLoadRequested event, Emitter<FavoritesState> emit) async {
    emit(state.copyWith(status: FavoritesStatus.loading, clearErrorMessage: true));
    final result = await _cardRepository.getFavorites();
    await result.fold(
      (failure) async {
        emit(state.copyWith(status: FavoritesStatus.failure, errorMessage: failure.message ?? 'Could not load favorites'));
      },
      (List<TopicCard> list) async {
        emit(state.copyWith(status: FavoritesStatus.success, cards: list));
      },
    );
  }

  Future<void> _onRemove(FavoriteRemoved event, Emitter<FavoritesState> emit) async {
    final result = await _cardRepository.toggleFavorite(event.cardId);
    await result.fold(
      (failure) async {
        emit(state.copyWith(errorMessage: failure.message ?? 'Could not update favorite'));
      },
      (_) async {
        add(const FavoritesLoadRequested());
      },
    );
  }

  void _onDrawRequested(FavoriteDrawRequested event, Emitter<FavoritesState> emit) {
    // Navigation is handled in the UI; this hook exists for analytics/tests.
  }
}
