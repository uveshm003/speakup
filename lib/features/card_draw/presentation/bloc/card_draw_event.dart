import 'package:equatable/equatable.dart';

import 'package:speakup/features/card_draw/domain/entities/difficulty.dart';

sealed class CardDrawEvent extends Equatable {
  const CardDrawEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Initial draw or filter change — [category] is built-in name or `custom:<id>`.
final class CardDrawRequested extends CardDrawEvent {
  const CardDrawRequested({this.category, this.difficulty});

  final String? category;
  final Difficulty? difficulty;

  @override
  List<Object?> get props => <Object?>[category, difficulty];
}

/// Re-draw using the same filters as the last successful draw.
final class CardRedrawRequested extends CardDrawEvent {
  const CardRedrawRequested();
}

final class CardFavoriteToggled extends CardDrawEvent {
  const CardFavoriteToggled(this.cardId);

  final String cardId;

  @override
  List<Object?> get props => <Object?>[cardId];
}

/// Syncs flip / entrance animation phase from the UI (optional).
final class CardDrawFlipPhaseChanged extends CardDrawEvent {
  const CardDrawFlipPhaseChanged(this.isAnimating);

  final bool isAnimating;

  @override
  List<Object?> get props => <Object?>[isAnimating];
}
