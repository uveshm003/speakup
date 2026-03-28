import 'package:equatable/equatable.dart';

import 'package:speakup/features/card_draw/domain/entities/difficulty.dart';
import 'package:speakup/features/card_draw/domain/entities/topic_card.dart';

enum CardDrawStatus {
  initial,
  loading,
  success,
  failure,
  empty,
}

class CardDrawState extends Equatable {
  const CardDrawState({
    this.status = CardDrawStatus.initial,
    this.currentCard,
    this.isAnimating = false,
    this.isFavorite = false,
    this.drawCount = 0,
    this.errorMessage,
    this.filterCategory,
    this.filterDifficulty,
  });

  final CardDrawStatus status;
  final TopicCard? currentCard;
  final bool isAnimating;
  final bool isFavorite;
  final int drawCount;
  final String? errorMessage;
  final String? filterCategory;
  final Difficulty? filterDifficulty;

  CardDrawState copyWith({
    CardDrawStatus? status,
    TopicCard? currentCard,
    bool? isAnimating,
    bool? isFavorite,
    int? drawCount,
    String? errorMessage,
    String? filterCategory,
    Difficulty? filterDifficulty,
    bool clearCard = false,
    bool clearErrorMessage = false,
  }) {
    return CardDrawState(
      status: status ?? this.status,
      currentCard: clearCard ? null : (currentCard ?? this.currentCard),
      isAnimating: isAnimating ?? this.isAnimating,
      isFavorite: isFavorite ?? this.isFavorite,
      drawCount: drawCount ?? this.drawCount,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      filterCategory: filterCategory ?? this.filterCategory,
      filterDifficulty: filterDifficulty ?? this.filterDifficulty,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        currentCard,
        isAnimating,
        isFavorite,
        drawCount,
        errorMessage,
        filterCategory,
        filterDifficulty,
      ];
}
