import 'package:equatable/equatable.dart';

import 'package:speakup/features/card_draw/domain/entities/topic_card.dart';

enum CustomCardStatus { initial, loading, success, failure }

class CustomCardState extends Equatable {
  const CustomCardState({
    this.cards = const <TopicCard>[],
    this.status = CustomCardStatus.initial,
    this.errorMessage,
    this.pendingDeletion,
    this.categoryId,
  });

  final List<TopicCard> cards;
  final CustomCardStatus status;
  final String? errorMessage;
  final TopicCard? pendingDeletion;
  final String? categoryId;

  CustomCardState copyWith({
    List<TopicCard>? cards,
    CustomCardStatus? status,
    String? errorMessage,
    TopicCard? pendingDeletion,
    String? categoryId,
    bool clearErrorMessage = false,
    bool clearPendingDeletion = false,
  }) {
    return CustomCardState(
      cards: cards ?? this.cards,
      status: status ?? this.status,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      pendingDeletion: clearPendingDeletion ? null : (pendingDeletion ?? this.pendingDeletion),
      categoryId: categoryId ?? this.categoryId,
    );
  }

  @override
  List<Object?> get props => <Object?>[cards, status, errorMessage, pendingDeletion, categoryId];
}
