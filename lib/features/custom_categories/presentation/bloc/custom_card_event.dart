import 'package:equatable/equatable.dart';

import 'package:speakup/features/card_draw/domain/entities/topic_card.dart';

sealed class CustomCardEvent extends Equatable {
  const CustomCardEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

final class CardsLoadRequested extends CustomCardEvent {
  const CardsLoadRequested(this.categoryId);

  final String categoryId;

  @override
  List<Object?> get props => <Object?>[categoryId];
}

final class CardCreateRequested extends CustomCardEvent {
  const CardCreateRequested(this.card);

  final TopicCard card;

  @override
  List<Object?> get props => <Object?>[card];
}

final class CardUpdateRequested extends CustomCardEvent {
  const CardUpdateRequested(this.card);

  final TopicCard card;

  @override
  List<Object?> get props => <Object?>[card];
}

final class CardDeleteRequested extends CustomCardEvent {
  const CardDeleteRequested(this.cardId);

  final String cardId;

  @override
  List<Object?> get props => <Object?>[cardId];
}

final class CardDeleteUndoRequested extends CustomCardEvent {
  const CardDeleteUndoRequested();
}

final class CardDeleteCommitted extends CustomCardEvent {
  const CardDeleteCommitted();
}
