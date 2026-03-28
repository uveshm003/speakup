import 'package:equatable/equatable.dart';

import 'package:speakup/features/card_draw/domain/entities/topic_card.dart';

sealed class FavoritesEvent extends Equatable {
  const FavoritesEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

final class FavoritesLoadRequested extends FavoritesEvent {
  const FavoritesLoadRequested();
}

final class FavoriteRemoved extends FavoritesEvent {
  const FavoriteRemoved(this.cardId);

  final String cardId;

  @override
  List<Object?> get props => <Object?>[cardId];
}

/// Optional: used when UI wants the bloc to react to "draw this favorite" flows.
final class FavoriteDrawRequested extends FavoritesEvent {
  const FavoriteDrawRequested(this.card);

  final TopicCard card;

  @override
  List<Object?> get props => <Object?>[card];
}
