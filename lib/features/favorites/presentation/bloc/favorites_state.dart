import 'package:equatable/equatable.dart';

import 'package:speakup/features/card_draw/domain/entities/topic_card.dart';

enum FavoritesStatus { initial, loading, success, failure }

class FavoritesState extends Equatable {
  const FavoritesState({this.status = FavoritesStatus.initial, this.cards = const <TopicCard>[], this.errorMessage});

  final FavoritesStatus status;
  final List<TopicCard> cards;
  final String? errorMessage;

  FavoritesState copyWith({FavoritesStatus? status, List<TopicCard>? cards, String? errorMessage, bool clearErrorMessage = false}) {
    return FavoritesState(
      status: status ?? this.status,
      cards: cards ?? this.cards,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => <Object?>[status, cards, errorMessage];
}
